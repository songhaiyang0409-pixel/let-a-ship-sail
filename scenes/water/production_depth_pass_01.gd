extends Node3D

## OCEAN PRODUCTION DEPTH PASS 01
##
## Isolated comparison scene. The existing SailingReferenceScene owns the
## boat, camera, B+ wave sampler, regional route, and input. This wrapper only
## swaps the visible water in candidate mode and adds low-cost visual layers.

const REFERENCE_SCENE := preload("res://scenes/reference/SailingReferenceScene.tscn")
const DEPTH_SHADER := preload("res://materials/water_test/regional_ocean/regional_ocean_depth_pass_01.gdshader")
const CAPTURE_ROOT := "res://scenes/water/production_depth_pass_01_captures"
const VIEWPORT_SIZE := Vector2i(1152, 648)
const WAVE_PARAMS: Array[Vector4] = [
	Vector4(0.34, 3.60, 0.18, 0.86), Vector4(-0.26, -0.19, 0.01, 0.47),
	Vector4(-7.67, 5.63, 0.10, 0.38), Vector4(-0.42, -1.63, 0.10, 0.28),
	Vector4(1.42, 0.28, 0.12, 2.18), Vector4(1.20, 1.14, 0.01, 0.33),
	Vector4(-1.05, 2.90, 0.08, 1.30), Vector4(-0.58, -1.22, 0.10, 1.82),
]
const DEPTH_CAPTURE_DIR := "res://scenes/water/production_depth_pass_01_captures/candidate"
const BASELINE_CAPTURE_DIR := "res://scenes/water/production_depth_pass_01_captures/baseline"

var reference_instance: Node3D
var regional_system: Node
var boat_visual: Node3D
var candidate_water: MeshInstance3D
var candidate_material: ShaderMaterial
var wake_mesh_instance: MeshInstance3D
var bow_wave_root: Node3D
var visual_time := 0.0
var wake_points: Array[Vector3] = []
var wake_rights: Array[Vector3] = []
var wake_ages: Array[float] = []
var wake_strengths: Array[float] = []
var wake_distance_since_spawn := 0.0
var capture_mode := false
var baseline_mode := false

const WAKE_LIFETIME := 3.0
const WAKE_SPACING := 0.16
const WAKE_MAX_POINTS := 120
const WAKE_STERN_OFFSET := 0.78
const WAKE_COLOR := Color(0.82, 0.94, 0.91, 0.45)
const BOW_COLOR := Color(0.86, 0.96, 0.93, 0.24)


func _ready() -> void:
	_configure_viewport()
	var args := OS.get_cmdline_user_args()
	baseline_mode = args.has("--ocean-depth-baseline")
	capture_mode = args.has("--capture-ocean-depth-pass-01")
	reference_instance = REFERENCE_SCENE.instantiate()
	reference_instance.name = "SailingReferenceScene_COPY_FOR_OCEAN_DEPTH"
	add_child(reference_instance)
	await _wait_for_reference()
	_hide_reference_extras()
	if not baseline_mode:
		_build_candidate_water()
	_build_bow_response()
	_build_wake()
	_build_distant_coast()
	print("OCEAN_DEPTH_PASS_01_READY|isolated=true|mode=%s|macro=shared_b_plus_v3|boat_wave_follow=shared_regional_sampler|formal_project_modified=false" % ("baseline" if baseline_mode else "candidate"))
	if capture_mode:
		call_deferred("_capture_all")


func _process(delta: float) -> void:
	visual_time += delta
	if regional_system == null or boat_visual == null:
		return
	if not baseline_mode and candidate_material != null:
		_update_candidate_uniforms()
	_update_bow_response()
	_update_wake(delta)


func _configure_viewport() -> void:
	get_viewport().size = VIEWPORT_SIZE
	get_viewport().content_scale_size = VIEWPORT_SIZE


func _wait_for_reference() -> void:
	for _frame in range(20):
		await get_tree().process_frame
	regional_system = reference_instance.get_node_or_null("RegionalOceanSystem")
	if regional_system == null:
		push_error("OceanProductionDepthPass01 cannot find RegionalOceanSystem.")
		return
	boat_visual = regional_system.get("boat_visual") as Node3D
	if boat_visual == null:
		push_error("OceanProductionDepthPass01 cannot find reference boat visual.")


func _hide_reference_extras() -> void:
	var root := regional_system
	if not baseline_mode:
		var original_water := root.get("water_mesh") as MeshInstance3D
		if original_water != null:
			original_water.visible = false
	var proxy := root.get("coastal_world_root") as Node3D
	if proxy != null:
		proxy.visible = false
	var markers := root.get("markers_root") as Node3D
	if markers != null:
		markers.visible = false
	var references := root.get("scale_reference_root") as Node3D
	if references != null:
		references.visible = false


func _build_candidate_water() -> void:
	candidate_water = MeshInstance3D.new()
	candidate_water.name = "OceanDepthPass01_CandidateWater"
	var plane := PlaneMesh.new()
	plane.size = Vector2(260.0, 220.0)
	plane.subdivide_width = 160
	plane.subdivide_depth = 160
	candidate_water.mesh = plane
	candidate_material = ShaderMaterial.new()
	candidate_material.shader = DEPTH_SHADER
	for index in range(WAVE_PARAMS.size()):
		candidate_material.set_shader_parameter("wave_%d" % (index + 1), WAVE_PARAMS[index])
	candidate_material.set_shader_parameter("wave_time", 0.0)
	candidate_material.set_shader_parameter("time_factor", 2.7)
	candidate_material.set_shader_parameter("wave_amplitude_scale", 0.70)
	candidate_material.set_shader_parameter("wave_length_scale", 3.8)
	candidate_material.set_shader_parameter("secondary_direction", Vector2(-0.36, 0.93))
	candidate_material.set_shader_parameter("secondary_wavelength", 7.2)
	candidate_material.set_shader_parameter("secondary_steepness", 0.043)
	candidate_material.set_shader_parameter("secondary_time_scale", 0.48)
	candidate_material.set_shader_parameter("secondary_phase", 3.4)
	candidate_material.set_shader_parameter("depth_medium_wave_1", Vector4(0.82, 0.24, 0.030, 7.5))
	candidate_material.set_shader_parameter("depth_medium_wave_2", Vector4(-0.20, 0.98, 0.022, 12.0))
	candidate_material.set_shader_parameter("depth_medium_strength", 0.48)
	candidate_material.set_shader_parameter("depth_micro_strength", 0.035)
	candidate_material.set_shader_parameter("depth_micro_scale", 0.62)
	candidate_material.set_shader_parameter("route_origin_z", regional_system.get("route_origin_z"))
	candidate_material.set_shader_parameter("transition_01_start", regional_system.get("transition_01_start"))
	candidate_material.set_shader_parameter("transition_01_end", regional_system.get("transition_01_end"))
	candidate_material.set_shader_parameter("transition_12_start", regional_system.get("transition_12_start"))
	candidate_material.set_shader_parameter("transition_12_end", regional_system.get("transition_12_end"))
	candidate_material.set_shader_parameter("transition_23_start", regional_system.get("transition_23_start"))
	candidate_material.set_shader_parameter("transition_23_end", regional_system.get("transition_23_end"))
	candidate_material.set_shader_parameter("coastal_local_enabled", 1.0)
	candidate_material.set_shader_parameter("coast_front_z", -24.0)
	candidate_material.set_shader_parameter("harbor_entry_z", -30.0)
	candidate_material.set_shader_parameter("harbor_back_z", -74.0)
	candidate_material.set_shader_parameter("harbor_half_width", 11.5)
	candidate_material.set_shader_parameter("harbor_wall_x", 16.0)
	_set_candidate_region_uniforms()
	candidate_water.material_override = candidate_material
	add_child(candidate_water)


func _set_candidate_region_uniforms() -> void:
	var profiles: Array = regional_system.get("presets")
	for index in range(mini(profiles.size(), 4)):
		var profile: Resource = profiles[index]
		var prefix := "region%d_" % index
		candidate_material.set_shader_parameter(prefix + "trough_color", _color3(profile.get("trough_color")))
		candidate_material.set_shader_parameter(prefix + "water_color", _color3(profile.get("water_color")))
		candidate_material.set_shader_parameter(prefix + "crest_color", _color3(profile.get("crest_color")))
		candidate_material.set_shader_parameter(prefix + "atmospheric_color", _color3(profile.get("atmospheric_color")))
		candidate_material.set_shader_parameter(prefix + "tuning", Vector4(float(profile.get("amplitude_multiplier")), float(profile.get("secondary_strength")), float(profile.get("surface_contrast")), float(profile.get("horizon_response"))))
		candidate_material.set_shader_parameter(prefix + "surface", Vector4(float(profile.get("saturation")), float(profile.get("specular_strength")), float(profile.get("fresnel_strength")), 0.94))


func _color3(value: Variant) -> Vector3:
	var color: Color = value
	return Vector3(color.r, color.g, color.b)


func _update_candidate_uniforms() -> void:
	var speed := absf(float(regional_system.get("boat_speed"))) / 2.20
	candidate_material.set_shader_parameter("wave_time", visual_time)
	candidate_material.set_shader_parameter("camera_position_world", (regional_system.get("camera") as Camera3D).global_position)
	candidate_material.set_shader_parameter("boat_position_world", boat_visual.global_position)
	candidate_material.set_shader_parameter("boat_forward_world", regional_system.call("_boat_forward"))
	candidate_material.set_shader_parameter("boat_speed", speed)


func _build_distant_coast() -> void:
	var root := Node3D.new()
	root.name = "OceanDepthPass01_DistantCoast_PLACEHOLDER"
	root.set_meta("asset_status", "PLACEHOLDER_ONLY")
	add_child(root)
	var land_material := _make_unshaded_material(Color(0.16, 0.25, 0.25, 1.0))
	for item in [
		{"name": "CoastMass_L", "position": Vector3(-23.0, 1.8, -46.0), "size": Vector3(32.0, 3.6, 11.0)},
		{"name": "CoastMass_C", "position": Vector3(3.0, 2.8, -53.0), "size": Vector3(42.0, 5.6, 14.0)},
		{"name": "CoastMass_R", "position": Vector3(30.0, 1.6, -45.0), "size": Vector3(26.0, 3.2, 10.0)},
	]:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = String(item["name"])
		var mesh := BoxMesh.new()
		mesh.size = item["size"]
		mesh_instance.mesh = mesh
		mesh_instance.position = item["position"]
		mesh_instance.material_override = land_material
		root.add_child(mesh_instance)


func _make_unshaded_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.roughness = 1.0
	return material


func _build_bow_response() -> void:
	bow_wave_root = Node3D.new()
	bow_wave_root.name = "OceanDepthPass01_BowResponse"
	add_child(bow_wave_root)
	for side in [-1.0, 1.0]:
		var strip := MeshInstance3D.new()
		strip.name = "BowWave_%s" % ("L" if side < 0.0 else "R")
		var mesh := QuadMesh.new()
		mesh.size = Vector2(0.22, 1.15)
		strip.mesh = mesh
		strip.material_override = _make_alpha_material(BOW_COLOR)
		bow_wave_root.add_child(strip)


func _make_alpha_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _update_bow_response() -> void:
	if bow_wave_root == null or boat_visual == null:
		return
	var forward: Vector3 = regional_system.call("_boat_forward")
	var right := forward.cross(Vector3.UP).normalized()
	var speed := absf(float(regional_system.get("boat_speed"))) / 2.20
	var active := clampf(speed, 0.0, 1.0)
	for index in range(bow_wave_root.get_child_count()):
		var side := -1.0 if index == 0 else 1.0
		var strip := bow_wave_root.get_child(index) as MeshInstance3D
		strip.visible = active > 0.06
		strip.position = boat_visual.global_position + forward * 0.82 + right * side * (0.24 + active * 0.22)
		strip.position.y = 0.18
		strip.rotation.y = atan2(forward.x, forward.z)
		strip.rotation.x = -PI * 0.5
		strip.scale = Vector3(0.45 + active * 0.55, 0.45 + active * 0.80, 0.45 + active * 0.55)
		var material := strip.material_override as StandardMaterial3D
		material.albedo_color.a = BOW_COLOR.a * active * 0.75


func _build_wake() -> void:
	wake_mesh_instance = MeshInstance3D.new()
	wake_mesh_instance.name = "OceanDepthPass01_StructuredWake"
	wake_mesh_instance.mesh = ArrayMesh.new()
	var material := _make_alpha_material(WAKE_COLOR)
	material.vertex_color_use_as_albedo = true
	wake_mesh_instance.material_override = material
	add_child(wake_mesh_instance)


func _update_wake(delta: float) -> void:
	for index in range(wake_ages.size()):
		wake_ages[index] += delta
	while not wake_ages.is_empty() and wake_ages[0] >= WAKE_LIFETIME:
		wake_points.pop_front()
		wake_rights.pop_front()
		wake_ages.pop_front()
		wake_strengths.pop_front()
	var speed := absf(float(regional_system.get("boat_speed")))
	if speed >= 0.10:
		wake_distance_since_spawn += speed * delta
		while wake_distance_since_spawn >= WAKE_SPACING:
			wake_distance_since_spawn -= WAKE_SPACING
			_spawn_wake_segment(clampf(speed / 2.20, 0.0, 1.0))
	_rebuild_wake_mesh()


func _spawn_wake_segment(strength: float) -> void:
	var forward: Vector3 = regional_system.call("_boat_forward")
	var point := boat_visual.global_position - forward * WAKE_STERN_OFFSET
	point.y = 0.12
	var right := forward.cross(Vector3.UP).normalized()
	wake_points.append(point)
	wake_rights.append(right)
	wake_ages.append(0.0)
	wake_strengths.append(strength)
	while wake_points.size() > WAKE_MAX_POINTS:
		wake_points.pop_front()
		wake_rights.pop_front()
		wake_ages.pop_front()
		wake_strengths.pop_front()


func _rebuild_wake_mesh() -> void:
	if wake_mesh_instance == null or not wake_mesh_instance.mesh is ArrayMesh:
		return
	var mesh := wake_mesh_instance.mesh as ArrayMesh
	mesh.clear_surfaces()
	if wake_points.size() < 2:
		return
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for index in range(wake_points.size()):
		var life := clampf(1.0 - wake_ages[index] / WAKE_LIFETIME, 0.0, 1.0)
		var age := 1.0 - life
		var width := lerpf(0.045, 1.15, age) * (0.72 + wake_strengths[index] * 0.28)
		var right: Vector3 = wake_rights[index].normalized()
		var center: Vector3 = wake_points[index]
		vertices.append(center - right * width)
		vertices.append(center + right * width)
		var alpha := WAKE_COLOR.a * wake_strengths[index] * life * life
		var color := Color(WAKE_COLOR.r, WAKE_COLOR.g, WAKE_COLOR.b, alpha)
		colors.append(color)
		colors.append(color)
	for index in range(wake_points.size() - 1):
		var base := index * 2
		indices.append(base)
		indices.append(base + 2)
		indices.append(base + 3)
		indices.append(base)
		indices.append(base + 3)
		indices.append(base + 1)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


func _capture_all() -> void:
	var output_dir := ProjectSettings.globalize_path(BASELINE_CAPTURE_DIR if baseline_mode else DEPTH_CAPTURE_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var shots := [
		{"name": "01_overview", "camera": "overview", "position": Vector3(0.0, 0.28, 10.0), "yaw": 0.0},
		{"name": "02_boat", "camera": "boat", "position": Vector3(0.0, 0.28, 10.0), "yaw": 0.0},
		{"name": "03_low_angle", "camera": "low_angle", "position": Vector3(0.0, 0.28, 10.0), "yaw": 0.0},
		{"name": "04_world", "camera": "overview", "position": Vector3(0.0, 0.28, -34.0), "yaw": 0.0},
	]
	for shot in shots:
		regional_system.call("_set_boat_pose", shot["position"], shot["yaw"], 0.0)
		regional_system.call("_set_camera_view", shot["camera"])
		regional_system.set("boat_speed", 0.0)
		_clear_wake()
		for _frame in range(20):
			await get_tree().process_frame
		var path := output_dir.path_join(String(shot["name"]) + ".png")
		var image := get_viewport().get_texture().get_image()
		var error := image.save_png(path)
		if error == OK:
			print("OCEAN_DEPTH_PASS_01_SCREENSHOT=" + path)
		else:
			push_error("Cannot save ocean depth screenshot: " + path)
	get_tree().quit()


func _clear_wake() -> void:
	wake_points.clear()
	wake_rights.clear()
	wake_ages.clear()
	wake_strengths.clear()
	wake_distance_since_spawn = 0.0
	_rebuild_wake_mesh()
