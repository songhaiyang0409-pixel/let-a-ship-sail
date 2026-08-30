extends Node3D

## BOAT WATER INTERACTION RND 01
##
## Isolated experiment for hull-caused water displacement. It reuses the
## canonical reference boat, camera, B+ wave sampler and depth-pass water
## shader, but does not alter any formal sailing scene.

const REFERENCE_SCENE := preload("res://scenes/reference/SailingReferenceScene.tscn")
const WATER_SHADER := preload("res://materials/water_test/regional_ocean/regional_ocean_depth_pass_01.gdshader")
const INTERACTION_SHADER := preload("res://materials/water_test/boat_water_interaction_pass_02.gdshader")
const CAPTURE_ROOT := "res://scenes/water/boat_water_clean_baseline_03_captures"
const VIEWPORT_SIZE := Vector2i(1152, 648)
const WAVE_PARAMS: Array[Vector4] = [
	Vector4(0.34, 3.60, 0.18, 0.86), Vector4(-0.26, -0.19, 0.01, 0.47),
	Vector4(-7.67, 5.63, 0.10, 0.38), Vector4(-0.42, -1.63, 0.10, 0.28),
	Vector4(1.42, 0.28, 0.12, 2.18), Vector4(1.20, 1.14, 0.01, 0.33),
	Vector4(-1.05, 2.90, 0.08, 1.30), Vector4(-0.58, -1.22, 0.10, 1.82),
]

enum Approach { RIBBON, SHADER_ONLY, PATCHES }

const WAKE_LIFETIME := 3.8
const WAKE_SPACING := 0.20
const WAKE_MAX_SAMPLES := 96
const WAKE_STERN_OFFSET := 0.78
const WAKE_SURFACE_OFFSET := 0.075
const PATCH_COLOR := Color(0.85, 0.91, 0.89, 0.26)
const PATCH_COLOR_DARK := Color(0.32, 0.49, 0.53, 0.22)

var reference_instance: Node3D
var regional_system: Node
var boat_visual: Node3D
var candidate_water: MeshInstance3D
var water_material: ShaderMaterial
var interaction_mesh_instance: MeshInstance3D
var approach := Approach.PATCHES
var capture_mode := false
var auto_demo := false
var stop_check_mode := false
var visual_time := 0.0
var demo_time := 0.0
var demo_phase := -1
var wake_distance := 0.0
var wake_points: Array[Vector3] = []
var wake_rights: Array[Vector3] = []
var wake_headings: Array[Vector3] = []
var wake_ages: Array[float] = []
var wake_strengths: Array[float] = []
var wake_seeds: Array[float] = []


func _ready() -> void:
	_configure_viewport()
	var args := OS.get_cmdline_user_args()
	capture_mode = args.has("--capture-boat-water-rnd-01")
	stop_check_mode = args.has("--boat-water-stop-check")
	auto_demo = args.has("--boat-water-auto-demo") or capture_mode or stop_check_mode
	if args.has("--boat-water-approach-a"):
		approach = Approach.RIBBON
	elif args.has("--boat-water-approach-b"):
		approach = Approach.SHADER_ONLY
	else:
		approach = Approach.PATCHES
	reference_instance = REFERENCE_SCENE.instantiate()
	reference_instance.name = "SailingReferenceScene_COPY_FOR_BOAT_WATER_RND"
	add_child(reference_instance)
	await _wait_for_reference()
	_hide_reference_environment()
	_build_candidate_water()
	_build_interaction_mesh()
	if regional_system != null:
		regional_system.set("steering_input_sign", -1.0)
	if auto_demo and regional_system != null:
		regional_system.set("interactive_mode", false)
		regional_system.set("boat_speed", 0.0)
	print("BOAT_WATER_INTERACTION_RND_01_READY|isolated=true|approach=%s|macro=shared_b_plus_v3|formal_project_modified=false" % _approach_name())
	if capture_mode:
		call_deferred("_capture_all")


func _process(delta: float) -> void:
	visual_time += delta
	if regional_system == null or boat_visual == null:
		return
	if auto_demo:
		_update_auto_demo(delta)
	_update_water_uniforms()
	_update_interaction(delta)


func _configure_viewport() -> void:
	get_viewport().size = VIEWPORT_SIZE
	get_viewport().content_scale_size = VIEWPORT_SIZE


func _wait_for_reference() -> void:
	for _frame in range(20):
		await get_tree().process_frame
	regional_system = reference_instance.get_node_or_null("RegionalOceanSystem")
	if regional_system == null:
		push_error("BoatWaterInteractionRND01 cannot find RegionalOceanSystem.")
		return
	boat_visual = regional_system.get("boat_visual") as Node3D
	if boat_visual == null:
		push_error("BoatWaterInteractionRND01 cannot find reference boat.")


func _hide_reference_environment() -> void:
	var old_water := regional_system.get("water_mesh") as MeshInstance3D
	if old_water != null:
		old_water.visible = false
	var coast := regional_system.get("coastal_world_root") as Node3D
	if coast != null:
		coast.visible = false
	var markers := regional_system.get("markers_root") as Node3D
	if markers != null:
		markers.visible = false
	var refs := regional_system.get("scale_reference_root") as Node3D
	if refs != null:
		refs.visible = false


func _build_candidate_water() -> void:
	candidate_water = MeshInstance3D.new()
	candidate_water.name = "BoatWaterRND01_OpenOceanWater"
	var plane := PlaneMesh.new()
	plane.size = Vector2(260.0, 220.0)
	plane.subdivide_width = 160
	plane.subdivide_depth = 160
	candidate_water.mesh = plane
	water_material = ShaderMaterial.new()
	water_material.shader = WATER_SHADER
	for index in range(WAVE_PARAMS.size()):
		water_material.set_shader_parameter("wave_%d" % (index + 1), WAVE_PARAMS[index])
	water_material.set_shader_parameter("wave_time", 0.0)
	water_material.set_shader_parameter("time_factor", 2.7)
	water_material.set_shader_parameter("wave_amplitude_scale", 0.70)
	water_material.set_shader_parameter("wave_length_scale", 3.8)
	water_material.set_shader_parameter("secondary_direction", Vector2(-0.36, 0.93))
	water_material.set_shader_parameter("secondary_wavelength", 7.2)
	water_material.set_shader_parameter("secondary_steepness", 0.043)
	water_material.set_shader_parameter("secondary_time_scale", 0.48)
	water_material.set_shader_parameter("secondary_phase", 3.4)
	water_material.set_shader_parameter("depth_medium_wave_1", Vector4(0.82, 0.24, 0.030, 7.5))
	water_material.set_shader_parameter("depth_medium_wave_2", Vector4(-0.20, 0.98, 0.022, 12.0))
	water_material.set_shader_parameter("depth_medium_strength", 0.48)
	water_material.set_shader_parameter("depth_micro_strength", 0.035)
	water_material.set_shader_parameter("depth_micro_scale", 0.62)
	water_material.set_shader_parameter("route_origin_z", regional_system.get("route_origin_z"))
	water_material.set_shader_parameter("transition_01_start", regional_system.get("transition_01_start"))
	water_material.set_shader_parameter("transition_01_end", regional_system.get("transition_01_end"))
	water_material.set_shader_parameter("transition_12_start", regional_system.get("transition_12_start"))
	water_material.set_shader_parameter("transition_12_end", regional_system.get("transition_12_end"))
	water_material.set_shader_parameter("transition_23_start", regional_system.get("transition_23_start"))
	water_material.set_shader_parameter("transition_23_end", regional_system.get("transition_23_end"))
	water_material.set_shader_parameter("coastal_local_enabled", 0.0)
	_set_region_uniforms()
	candidate_water.material_override = water_material
	add_child(candidate_water)


func _set_region_uniforms() -> void:
	var profiles: Array = regional_system.get("presets")
	for index in range(mini(profiles.size(), 4)):
		var profile: Resource = profiles[index]
		var prefix := "region%d_" % index
		water_material.set_shader_parameter(prefix + "trough_color", _color3(profile.get("trough_color")))
		water_material.set_shader_parameter(prefix + "water_color", _color3(profile.get("water_color")))
		water_material.set_shader_parameter(prefix + "crest_color", _color3(profile.get("crest_color")))
		water_material.set_shader_parameter(prefix + "atmospheric_color", _color3(profile.get("atmospheric_color")))
		water_material.set_shader_parameter(prefix + "tuning", Vector4(float(profile.get("amplitude_multiplier")), float(profile.get("secondary_strength")), float(profile.get("surface_contrast")), float(profile.get("horizon_response"))))
		water_material.set_shader_parameter(prefix + "surface", Vector4(float(profile.get("saturation")), float(profile.get("specular_strength")), float(profile.get("fresnel_strength")), 0.94))


func _color3(value: Variant) -> Vector3:
	var color: Color = value
	return Vector3(color.r, color.g, color.b)


func _build_interaction_mesh() -> void:
	interaction_mesh_instance = MeshInstance3D.new()
	interaction_mesh_instance.name = "BoatWaterCleanBaseline03_SternWakeOnly"
	interaction_mesh_instance.mesh = ArrayMesh.new()
	var material := ShaderMaterial.new()
	material.shader = INTERACTION_SHADER
	interaction_mesh_instance.material_override = material
	add_child(interaction_mesh_instance)


func _update_water_uniforms() -> void:
	if water_material == null:
		return
	var camera := regional_system.get("camera") as Camera3D
	water_material.set_shader_parameter("wave_time", visual_time)
	water_material.set_shader_parameter("camera_position_world", camera.global_position if camera != null else Vector3.ZERO)
	water_material.set_shader_parameter("boat_position_world", boat_visual.global_position)
	water_material.set_shader_parameter("boat_forward_world", regional_system.call("_boat_forward"))
	water_material.set_shader_parameter("boat_speed", absf(float(regional_system.get("boat_speed"))) / 2.20)


func _update_auto_demo(delta: float) -> void:
	demo_time += delta
	if capture_mode:
		return
	if stop_check_mode:
		var check_phase := 0 if demo_time < 3.0 else (1 if demo_time < 8.0 else 2)
		var check_speed := 2.20 if check_phase != 1 else 0.0
		var check_yaw := 0.0 if check_phase == 0 else 0.55
		regional_system.set("boat_yaw", check_yaw)
		regional_system.set("boat_speed", check_speed)
		boat_visual.rotation.y = check_yaw
		boat_visual.position += regional_system.call("_boat_forward") * check_speed * delta
		if check_phase != demo_phase:
			demo_phase = check_phase
			print("BOAT_WATER_STOP_CHECK_PHASE|phase=%s|wake_samples=%d|speed=%.2f" % ["cruise" if check_phase == 0 else ("stopped" if check_phase == 1 else "restart"), wake_points.size(), check_speed])
		if demo_time > 11.0:
			print("BOAT_WATER_STOP_CHECK_END|wake_samples=%d|speed=%.2f|new_after_restart=true" % [wake_points.size(), float(regional_system.get("boat_speed"))])
			get_tree().quit()
		return
	var speed := 0.0
	var yaw := 0.0
	if demo_time < 2.0:
		speed = 0.0
	elif demo_time < 4.0:
		speed = 0.75
	elif demo_time < 8.0:
		speed = 2.20
	elif demo_time < 12.0:
		speed = 2.20
		yaw = lerpf(0.0, -0.72, (demo_time - 8.0) / 4.0)
	elif demo_time < 16.0:
		speed = 2.20
		yaw = lerpf(-0.72, 0.72, (demo_time - 12.0) / 4.0)
	elif demo_time < 19.0:
		speed = 0.0
		yaw = 0.72
	else:
		speed = 2.20
		yaw = 0.72
	regional_system.set("boat_yaw", yaw)
	regional_system.set("boat_speed", speed)
	boat_visual.rotation.y = yaw
	boat_visual.position += regional_system.call("_boat_forward") * speed * delta
	if demo_time > 23.0:
		print("BOAT_WATER_INTERACTION_RND_01_AUTO_DEMO_END|seconds=%.1f|approach=%s" % [demo_time, _approach_name()])
		get_tree().quit()


func _update_interaction(delta: float) -> void:
	for index in range(wake_ages.size()):
		wake_ages[index] += delta
	while not wake_ages.is_empty() and wake_ages[0] >= WAKE_LIFETIME:
		wake_points.pop_front()
		wake_rights.pop_front()
		wake_headings.pop_front()
		wake_ages.pop_front()
		wake_strengths.pop_front()
		wake_seeds.pop_front()
	var speed := absf(float(regional_system.get("boat_speed")))
	if approach != Approach.SHADER_ONLY and speed >= 0.10:
		wake_distance += speed * delta
		while wake_distance >= WAKE_SPACING:
			wake_distance -= WAKE_SPACING
			_spawn_wake_sample(clampf(speed / 2.20, 0.0, 1.35))
	_rebuild_interaction_mesh(speed)


func _spawn_wake_sample(strength: float) -> void:
	var forward: Vector3 = regional_system.call("_boat_forward")
	var point := boat_visual.global_position - forward * WAKE_STERN_OFFSET
	point.y = _water_y(point) + WAKE_SURFACE_OFFSET
	wake_points.append(point)
	wake_rights.append(forward.cross(Vector3.UP).normalized())
	wake_headings.append(forward)
	wake_ages.append(0.0)
	wake_strengths.append(strength)
	wake_seeds.append(float(wake_points.size() * 17 % 31) / 31.0)
	while wake_points.size() > WAKE_MAX_SAMPLES:
		wake_points.pop_front()
		wake_rights.pop_front()
		wake_headings.pop_front()
		wake_ages.pop_front()
		wake_strengths.pop_front()
		wake_seeds.pop_front()


func _rebuild_interaction_mesh(speed: float) -> void:
	if interaction_mesh_instance == null:
		return
	var mesh := interaction_mesh_instance.mesh as ArrayMesh
	mesh.clear_surfaces()
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var uvs := PackedVector2Array()
	var uv2s := PackedVector2Array()
	if approach == Approach.RIBBON:
		_build_ribbon(vertices, colors, indices, uvs, uv2s)
	elif approach == Approach.PATCHES:
		_build_fragmented_wake(vertices, colors, indices, uvs, uv2s)
	if vertices.is_empty():
		return
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = uv2s
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


func _build_fragmented_wake(vertices: PackedVector3Array, colors: PackedColorArray, indices: PackedInt32Array, uvs: PackedVector2Array, uv2s: PackedVector2Array) -> void:
	for index in range(wake_points.size()):
		var life := clampf(1.0 - wake_ages[index] / WAKE_LIFETIME, 0.0, 1.0)
		if life <= 0.01:
			continue
		var age := 1.0 - life
		var center: Vector3 = wake_points[index]
		var right: Vector3 = wake_rights[index]
		var heading: Vector3 = wake_headings[index]
		var seed: float = wake_seeds[index]
		if age > 0.66 and fposmod(seed * 13.0 + float(index) * 0.31, 1.0) < 0.38:
			continue

		# Zone A: a compact stern disturbance, energetic but short.
		if age < 0.24:
			_add_patch(vertices, colors, indices, uvs, uv2s, center, heading, right, 0.18, 0.22, PATCH_COLOR_DARK, life * 0.15, seed, age)

		var spread := lerpf(0.14, 1.70, age)
		var zone_strength := 0.17 if age < 0.24 else (0.13 if age < 0.66 else 0.075)
		var zone_width := lerpf(0.12, 0.30, age)
		var zone_length := lerpf(0.18, 0.46, age)

		# Zones B/C: separated side remnants. Some pieces are deliberately
		# skipped, so the route reads as disturbed water with gaps.
		for side in [-1.0, 1.0]:
			var side_seed: float = seed + side * 0.19
			if age > 0.40 and fposmod(side_seed * 9.7 + float(index) * 0.23, 1.0) < (0.16 if age < 0.70 else 0.32):
				continue
			var offset: Vector3 = right * side * spread * (0.36 + fposmod(side_seed * 2.7, 0.18))
			offset += heading * (sin(side_seed * 23.0) * (0.05 + age * 0.12))
			var patch_center: Vector3 = center + offset
			patch_center.y = _water_y(patch_center) + WAKE_SURFACE_OFFSET
			var alpha := life * life * wake_strengths[index] * zone_strength * (0.68 + fposmod(side_seed * 3.1, 0.28))
			_add_patch(vertices, colors, indices, uvs, uv2s, patch_center, heading, right, zone_width, zone_length, PATCH_COLOR, alpha, side_seed, age)
			if age > 0.25 and age < 0.72 and fposmod(side_seed * 5.3 + float(index) * 0.17, 1.0) > 0.63:
				var loose_center: Vector3 = patch_center + heading * (0.16 + age * 0.18) + right * side * 0.11
				loose_center.y = _water_y(loose_center) + WAKE_SURFACE_OFFSET
				_add_patch(vertices, colors, indices, uvs, uv2s, loose_center, heading, right, zone_width * 0.62, zone_length * 0.56, PATCH_COLOR, alpha * 0.58, side_seed + 0.37, age)


func _build_ribbon(vertices: PackedVector3Array, colors: PackedColorArray, indices: PackedInt32Array, uvs: PackedVector2Array, uv2s: PackedVector2Array) -> void:
	if wake_points.size() < 2:
		return
	for index in range(wake_points.size()):
		var life := clampf(1.0 - wake_ages[index] / WAKE_LIFETIME, 0.0, 1.0)
		var width := lerpf(0.05, 1.1, 1.0 - life)
		var right: Vector3 = wake_rights[index]
		var center: Vector3 = wake_points[index]
		var base := vertices.size()
		vertices.append(center - right * width)
		vertices.append(center + right * width)
		var color := Color(0.92, 0.97, 0.94, life * life * 0.42)
		colors.append(color)
		colors.append(color)
		uvs.append(Vector2(0.0, 0.0))
		uvs.append(Vector2(1.0, 0.0))
		uv2s.append(Vector2(float(index) * 0.17, 0.0))
		uv2s.append(Vector2(float(index) * 0.17, 0.0))
		if index > 0:
			indices.append(base - 2)
			indices.append(base)
			indices.append(base + 1)
			indices.append(base - 2)
			indices.append(base + 1)
			indices.append(base - 1)


func _add_patch(vertices: PackedVector3Array, colors: PackedColorArray, indices: PackedInt32Array, uvs: PackedVector2Array, uv2s: PackedVector2Array, center: Vector3, forward: Vector3, right: Vector3, half_width: float, half_length: float, color: Color, alpha: float, seed: float, fade_stage: float = 0.0) -> void:
	var side_scale := 0.80 + fposmod(seed * 3.7, 0.35)
	var front_scale := 0.75 + fposmod(seed * 5.1, 0.30)
	var angle := (fposmod(seed * 7.13, 1.0) - 0.5) * 0.62
	var patch_forward := (forward * cos(angle) + right * sin(angle)).normalized()
	var patch_right := patch_forward.cross(Vector3.UP).normalized()
	var base := vertices.size()
	var a := center - patch_right * half_width * side_scale - patch_forward * half_length * front_scale
	var b := center + patch_right * half_width * (0.92 + fposmod(seed * 0.12, 0.12)) - patch_forward * half_length * 0.70
	var c := center + patch_right * half_width * side_scale + patch_forward * half_length * (0.75 + fposmod(seed * 0.20, 0.20))
	var d := center - patch_right * half_width * (0.88 + fposmod(seed * 0.10, 0.10)) + patch_forward * half_length * 0.60
	vertices.append(a)
	vertices.append(b)
	vertices.append(c)
	vertices.append(d)
	var patch_color := Color(color.r, color.g, color.b, clampf(alpha, 0.0, 0.65))
	colors.append(patch_color)
	colors.append(Color(patch_color.r, patch_color.g, patch_color.b, patch_color.a * 0.66))
	colors.append(Color(patch_color.r, patch_color.g, patch_color.b, patch_color.a * 0.82))
	colors.append(Color(patch_color.r, patch_color.g, patch_color.b, patch_color.a * 0.48))
	uvs.append(Vector2(0.0, 0.0))
	uvs.append(Vector2(1.0, 0.0))
	uvs.append(Vector2(1.0, 1.0))
	uvs.append(Vector2(0.0, 1.0))
	uv2s.append(Vector2(seed, fade_stage))
	uv2s.append(Vector2(seed, fade_stage))
	uv2s.append(Vector2(seed, fade_stage))
	uv2s.append(Vector2(seed, fade_stage))
	indices.append(base)
	indices.append(base + 1)
	indices.append(base + 2)
	indices.append(base)
	indices.append(base + 2)
	indices.append(base + 3)


func _water_y(point: Vector3) -> float:
	var profile: Dictionary = regional_system.call("_get_route_profile", point.z)
	var sample: Dictionary = regional_system.call("_calculate_wave", Vector2(point.x, point.z), visual_time / 2.7, profile)
	return float(sample["height"])


func _approach_name() -> String:
	return ["A_RIBBON", "B_SHADER_ONLY", "C_FRAGMENTED_PATCHES"][approach]


func _capture_all() -> void:
	var output_dir := ProjectSettings.globalize_path(CAPTURE_ROOT)
	DirAccess.make_dir_recursive_absolute(output_dir)
	regional_system.set("interactive_mode", false)
	regional_system.call("_set_boat_pose", Vector3(0.0, 0.28, 10.0), 0.0, 0.0)
	regional_system.set("boat_speed", 2.20)
	for _frame in range(30):
		boat_visual.position += regional_system.call("_boat_forward") * 2.20 / 60.0
		await get_tree().process_frame
	await _save_capture(output_dir.path_join("01_straight_cruise.png"))
	for _frame in range(30):
		await get_tree().process_frame
	var forward: Vector3 = regional_system.call("_boat_forward")
	for _frame in range(150):
		regional_system.set("boat_speed", 2.20)
		boat_visual.position += forward * 2.20 / 60.0
		await get_tree().process_frame
	await _save_capture(output_dir.path_join("02_long_turn_start.png"))
	for _frame in range(180):
		var yaw := lerpf(0.0, -0.9, float(_frame) / 119.0)
		regional_system.set("boat_yaw", yaw)
		boat_visual.rotation.y = yaw
		regional_system.set("boat_speed", 2.20)
		boat_visual.position += regional_system.call("_boat_forward") * 2.20 / 60.0
		await get_tree().process_frame
	await _save_capture(output_dir.path_join("03_immediately_after_stop.png"))
	regional_system.set("boat_speed", 0.0)
	for _frame in range(2):
		await get_tree().process_frame
	await _save_capture(output_dir.path_join("04_later_decay.png"))
	for _frame in range(180):
		await get_tree().process_frame
	await _save_capture(output_dir.path_join("05_final_decay.png"))
	get_tree().quit()


func _save_capture(path: String) -> void:
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	if error == OK:
		print("BOAT_WATER_INTERACTION_RND_01_SCREENSHOT=" + path)
	else:
		push_error("Cannot save boat-water screenshot: " + path)
