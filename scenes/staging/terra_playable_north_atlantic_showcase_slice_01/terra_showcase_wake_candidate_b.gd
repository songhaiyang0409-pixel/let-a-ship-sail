extends Node3D

## Candidate B: two dynamic divergent stern filaments. The lanes are generated
## from the current world-space travel history, never from static wake geometry.
const LIFETIME := 2.9
const SPACING := 0.34
const MAX_SAMPLES := 64
const STERN_OFFSET := 0.92
const SURFACE_OFFSET := 0.08
const WAVE_TIME_FACTOR := 2.7
const WAKE_TINT := Color(0.55, 0.70, 0.72, 1.0)

var host: Node
var ocean: Node
var mesh_instance: MeshInstance3D
var distance_accumulator := 0.0
var last_motion_position := Vector3.INF
var points: Array[Vector3] = []
var headings: Array[Vector3] = []
var ages: Array[float] = []
var strengths: Array[float] = []


func _ready() -> void:
	host = get_parent()
	ocean = host.get("ocean") as Node
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "WakeCandidateB_DivergentFilaments"
	mesh_instance.mesh = ArrayMesh.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = WAKE_TINT
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = true
	mesh_instance.material_override = material
	add_child(mesh_instance)
	var boat := ocean.get("boat_visual") as Node3D
	if boat != null:
		last_motion_position = boat.global_position


func _process(delta: float) -> void:
	if ocean == null or host == null or bool(host.get("qa_mode")):
		return
	for index in range(ages.size()):
		ages[index] += delta
	while not ages.is_empty() and ages[0] >= LIFETIME:
		points.pop_front()
		headings.pop_front()
		ages.pop_front()
		strengths.pop_front()
	var speed: float = absf(float(ocean.get("boat_speed")))
	var boat := ocean.get("boat_visual") as Node3D
	if boat != null:
		var motion_distance := boat.global_position.distance_to(last_motion_position) if last_motion_position != Vector3.INF else 0.0
		last_motion_position = boat.global_position
		if speed >= 0.12 and motion_distance >= 0.01:
			distance_accumulator += motion_distance
			while distance_accumulator >= SPACING:
				distance_accumulator -= SPACING
				_spawn(speed)
	_rebuild()


func _spawn(speed: float) -> void:
	var boat := ocean.get("boat_visual") as Node3D
	if boat == null:
		return
	var heading: Vector3 = ocean.call("_boat_forward")
	var point: Vector3 = boat.global_position - heading * STERN_OFFSET
	point.y = _water_y(point) + SURFACE_OFFSET
	points.append(point)
	headings.append(heading)
	ages.append(0.0)
	strengths.append(clampf(speed / 2.20, 0.0, 1.0))
	while points.size() > MAX_SAMPLES:
		points.pop_front()
		headings.pop_front()
		ages.pop_front()
		strengths.pop_front()


func _rebuild() -> void:
	var mesh := mesh_instance.mesh as ArrayMesh
	if mesh == null:
		return
	mesh.clear_surfaces()
	if points.size() < 2:
		return
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for side in [-1.0, 1.0]:
		var lane_start: int = vertices.size()
		for index in range(points.size()):
			var life: float = clampf(1.0 - ages[index] / LIFETIME, 0.0, 1.0)
			var age: float = 1.0 - life
			var heading: Vector3 = headings[index]
			var right: Vector3 = heading.cross(Vector3.UP).normalized()
			var spread: float = lerpf(0.12, 0.92, age) * (0.82 + strengths[index] * 0.25)
			var width: float = lerpf(0.028, 0.055, age)
			var center: Vector3 = points[index] + right * side * spread
			center.y = _water_y(center) + SURFACE_OFFSET
			var alpha: float = 0.105 * life * life * strengths[index]
			vertices.append(center - right * width)
			vertices.append(center + right * width)
			colors.append(Color(WAKE_TINT.r, WAKE_TINT.g, WAKE_TINT.b, alpha * 0.72))
			colors.append(Color(WAKE_TINT.r, WAKE_TINT.g, WAKE_TINT.b, alpha))
		for index in range(points.size() - 1):
			var base: int = lane_start + index * 2
			indices.append_array(PackedInt32Array([base, base + 1, base + 2, base + 1, base + 3, base + 2]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


func _water_y(point: Vector3) -> float:
	var water := ocean.get("water_mesh") as Node3D
	var local_point := point
	if water != null:
		local_point = water.to_local(point)
	var profile: Dictionary = ocean.call("_get_route_profile", point.z)
	var sample: Dictionary = ocean.call("_calculate_wave", Vector2(local_point.x, local_point.z), float(ocean.get("visual_time")) / WAVE_TIME_FACTOR, profile)
	return water.to_global(Vector3(0.0, float(sample["height"]), 0.0)).y if water != null else float(sample["height"])
