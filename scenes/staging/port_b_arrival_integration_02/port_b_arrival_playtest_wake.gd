extends Node3D

## Isolated Port B playtest wake, derived from Clean Baseline 03's historical
## stern approach. It follows the current boat and never changes navigation.

const WAKE_LIFETIME := 3.8
const WAKE_SPACING := 0.22
const WAKE_MAX_SAMPLES := 96
const WAKE_STERN_OFFSET := 0.92
const WAKE_SURFACE_OFFSET := 0.065
const WAVE_TIME_FACTOR := 2.7
const WAKE_COLOR := Color(0.82, 0.93, 0.91, 0.72)

var host: Node
var ocean: Node
var wake_mesh_instance: MeshInstance3D
var wake_distance := 0.0
var wake_points: Array[Vector3] = []
var wake_rights: Array[Vector3] = []
var wake_headings: Array[Vector3] = []
var wake_ages: Array[float] = []
var wake_strengths: Array[float] = []
var wake_seeds: Array[float] = []


func _ready() -> void:
    host = get_parent()
    ocean = host.get("ocean") as Node
    _build_wake()


func _process(delta: float) -> void:
    if ocean == null or host == null or bool(host.get("harness_mode")):
        return
    var boat := ocean.get("boat_visual") as Node3D
    if boat == null:
        return
    for index in range(wake_ages.size()):
        wake_ages[index] += delta
    while not wake_ages.is_empty() and wake_ages[0] >= WAKE_LIFETIME:
        wake_points.pop_front()
        wake_rights.pop_front()
        wake_headings.pop_front()
        wake_ages.pop_front()
        wake_strengths.pop_front()
        wake_seeds.pop_front()
    var speed := absf(float(ocean.get("boat_speed")))
    if speed >= 0.10:
        wake_distance += speed * delta
        while wake_distance >= WAKE_SPACING:
            wake_distance -= WAKE_SPACING
            _spawn_wake_sample(clampf(speed / 2.20, 0.0, 1.25))
    _rebuild_wake_mesh()


func _build_wake() -> void:
    wake_mesh_instance = MeshInstance3D.new()
    wake_mesh_instance.name = "CleanBaseline03_SternWakeOnly"
    wake_mesh_instance.mesh = ArrayMesh.new()
    var material := StandardMaterial3D.new()
    material.albedo_color = WAKE_COLOR
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.vertex_color_use_as_albedo = true
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.no_depth_test = false
    wake_mesh_instance.material_override = material
    add_child(wake_mesh_instance)


func _spawn_wake_sample(strength: float) -> void:
    var boat := ocean.get("boat_visual") as Node3D
    if boat == null:
        return
    var forward: Vector3 = ocean.call("_boat_forward")
    var point := boat.global_position - forward * WAKE_STERN_OFFSET
    point.y = _water_y(point) + WAKE_SURFACE_OFFSET
    wake_points.append(point)
    wake_rights.append(forward.cross(Vector3.UP).normalized())
    wake_headings.append(forward)
    wake_ages.append(0.0)
    wake_strengths.append(strength)
    wake_seeds.append(float((wake_points.size() * 17) % 31) / 31.0)
    while wake_points.size() > WAKE_MAX_SAMPLES:
        wake_points.pop_front()
        wake_rights.pop_front()
        wake_headings.pop_front()
        wake_ages.pop_front()
        wake_strengths.pop_front()
        wake_seeds.pop_front()


func _rebuild_wake_mesh() -> void:
    if wake_mesh_instance == null:
        return
    var mesh := wake_mesh_instance.mesh as ArrayMesh
    if mesh == null:
        return
    mesh.clear_surfaces()
    var vertices := PackedVector3Array()
    var colors := PackedColorArray()
    var indices := PackedInt32Array()
    var uvs := PackedVector2Array()
    for index in range(wake_points.size()):
        var life := clampf(1.0 - wake_ages[index] / WAKE_LIFETIME, 0.0, 1.0)
        if life <= 0.01:
            continue
        var age := 1.0 - life
        var seed: float = wake_seeds[index]
        if age > 0.52 and fposmod(seed * 17.0 + float(index) * 0.47, 1.0) < 0.30:
            continue
        var center: Vector3 = wake_points[index]
        var right: Vector3 = wake_rights[index]
        var heading: Vector3 = wake_headings[index]
        var spread := lerpf(0.04, 1.20, age)
        var half_width := lerpf(0.075, 0.20, age)
        var half_length := lerpf(0.16, 0.48, age)
        var side_strength := 0.22 if age < 0.22 else (0.16 if age < 0.68 else 0.095)
        for side in [-1.0, 1.0]:
            var side_seed: float = seed + side * 0.19
            if age > 0.34 and fposmod(side_seed * 9.7 + float(index) * 0.23, 1.0) < (0.12 if age < 0.70 else 0.28):
                continue
            var patch_center: Vector3 = center + right * side * spread
            patch_center += heading * sin(side_seed * 23.0) * (0.03 + age * 0.10)
            patch_center.y = _water_y(patch_center) + WAKE_SURFACE_OFFSET
            var alpha := life * life * wake_strengths[index] * side_strength
            _add_patch(vertices, colors, indices, uvs, patch_center, heading, right, half_width, half_length, alpha, side_seed, age)
    if vertices.is_empty():
        return
    var arrays: Array = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_COLOR] = colors
    arrays[Mesh.ARRAY_INDEX] = indices
    arrays[Mesh.ARRAY_TEX_UV] = uvs
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


func _add_patch(vertices: PackedVector3Array, colors: PackedColorArray, indices: PackedInt32Array, uvs: PackedVector2Array, center: Vector3, forward: Vector3, right: Vector3, half_width: float, half_length: float, alpha: float, seed: float, fade_stage: float) -> void:
    var patch_forward := (forward * cos((fposmod(seed * 7.13, 1.0) - 0.5) * 0.45) + right * sin((fposmod(seed * 7.13, 1.0) - 0.5) * 0.45)).normalized()
    var patch_right := patch_forward.cross(Vector3.UP).normalized()
    var width_scale := 0.82 + fposmod(seed * 3.7, 0.26)
    var length_scale := 0.78 + fposmod(seed * 5.1, 0.20)
    var base := vertices.size()
    vertices.append(center - patch_right * half_width * width_scale - patch_forward * half_length * length_scale)
    vertices.append(center + patch_right * half_width * 0.88 - patch_forward * half_length * 0.68)
    vertices.append(center + patch_right * half_width * width_scale + patch_forward * half_length * 0.78)
    vertices.append(center - patch_right * half_width * 0.84 + patch_forward * half_length * 0.54)
    var patch_color := Color(WAKE_COLOR.r, WAKE_COLOR.g, WAKE_COLOR.b, clampf(alpha, 0.0, 0.34))
    colors.append(patch_color)
    colors.append(Color(patch_color.r, patch_color.g, patch_color.b, patch_color.a * 0.66))
    colors.append(Color(patch_color.r, patch_color.g, patch_color.b, patch_color.a * 0.82))
    colors.append(Color(patch_color.r, patch_color.g, patch_color.b, patch_color.a * 0.48))
    uvs.append(Vector2(0.0, fade_stage))
    uvs.append(Vector2(1.0, fade_stage))
    uvs.append(Vector2(1.0, 1.0))
    uvs.append(Vector2(0.0, 1.0))
    indices.append(base)
    indices.append(base + 1)
    indices.append(base + 2)
    indices.append(base)
    indices.append(base + 2)
    indices.append(base + 3)


func _water_y(point: Vector3) -> float:
    var profile: Dictionary = ocean.call("_get_route_profile", point.z)
    var sample: Dictionary = ocean.call("_calculate_wave", Vector2(point.x, point.z), float(ocean.get("visual_time")) / WAVE_TIME_FACTOR, profile)
    return float(sample["height"])