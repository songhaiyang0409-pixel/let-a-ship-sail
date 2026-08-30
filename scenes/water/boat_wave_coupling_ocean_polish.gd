extends Node3D

## BOAT WAVE COUPLING OCEAN POLISH — isolated visual R&D.
##
## The script samples the same deterministic base Gerstner function used by
## the test water shader. It drives only a duplicated boat visual, never the
## production controller, collision body, wake, timer, or voyage state.

const SOURCE_SCENE := preload("res://scenes/water/RobinHoodsBayIslandBlockout01.tscn")
const BASELINE_SHADER := preload("res://materials/water_test/stylized_ocean_rnd_01.gdshader")
const COUPLING_SHADER := preload("res://materials/water_test/boat_wave_coupling_ocean_polish.gdshader")
const CAPTURE_ROOT := "res://scenes/water/boat_wave_coupling_ocean_polish_captures"
const VIEWPORT_SIZE := Vector2i(1152, 648)

const BOAT_BASE_POSITION := Vector3(0.0, 0.28, 0.0)
const WAVE_TIME_FACTOR := 2.7
const WAVE_AMPLITUDE_SCALE := 0.70
const WAVE_LENGTH_SCALE := 3.8
const WAVE_PARAMS: Array[Vector4] = [
	Vector4(0.34, 3.60, 0.18, 0.86),
	Vector4(-0.26, -0.19, 0.01, 0.47),
	Vector4(-7.67, 5.63, 0.10, 0.38),
	Vector4(-0.42, -1.63, 0.10, 0.28),
	Vector4(1.42, 0.28, 0.12, 2.18),
	Vector4(1.20, 1.14, 0.01, 0.33),
	Vector4(-1.05, 2.90, 0.08, 1.30),
	Vector4(-0.58, -1.22, 0.10, 1.82),
]
const ACTIVE_WAVE_INDICES := [0, 4, 6, 7]

const CAMERA_SHOTS := {
	"overview": {"position": Vector3(-4.20, 4.05, 11.50), "target": Vector3(0.0, 1.65, -17.80), "fov": 40.0},
	"near_water": {"position": Vector3(-3.40, 1.25, 5.80), "target": Vector3(0.0, 0.45, -6.50), "fov": 44.0},
	"horizon": {"position": Vector3(-1.80, 5.65, 16.20), "target": Vector3(0.0, 0.80, -28.0), "fov": 34.0},
	"boat_side": {"position": Vector3(5.20, 2.70, 4.20), "target": Vector3(0.0, 0.60, -2.20), "fov": 42.0},
}

const CANDIDATES := [
	{"id": "b_plus_v1", "family": 0.0, "iteration": 1.0, "label": "B+ V1", "heave": 0.34, "tilt": 0.42, "roll": 0.30, "secondary_direction": Vector2(0.82, 0.28), "secondary_wavelength": 5.4, "secondary_steepness": 0.030, "secondary_time_scale": 0.70, "secondary_phase": 0.2, "secondary_displacement": 1.0, "contact": 0.025, "waterline": 0.0, "bow": 0.18},
	{"id": "b_plus_v2", "family": 0.0, "iteration": 2.0, "label": "B+ V2", "heave": 0.46, "tilt": 0.30, "roll": 0.22, "secondary_direction": Vector2(0.66, -0.75), "secondary_wavelength": 6.4, "secondary_steepness": 0.038, "secondary_time_scale": 0.58, "secondary_phase": 1.7, "secondary_displacement": 1.0, "contact": 0.050, "waterline": 0.030, "bow": 0.22},
	{"id": "b_plus_v3", "family": 0.0, "iteration": 3.0, "label": "B+ V3", "heave": 0.50, "tilt": 0.25, "roll": 0.18, "secondary_direction": Vector2(-0.36, 0.93), "secondary_wavelength": 7.2, "secondary_steepness": 0.043, "secondary_time_scale": 0.48, "secondary_phase": 3.4, "secondary_displacement": 1.0, "contact": 0.060, "waterline": 0.045, "bow": 0.24},
	{"id": "h3_plus_v1", "family": 1.0, "iteration": 11.0, "label": "H3+ V1", "heave": 0.30, "tilt": 0.34, "roll": 0.22, "secondary_direction": Vector2(0.74, -0.67), "secondary_wavelength": 6.8, "secondary_steepness": 0.026, "secondary_time_scale": 0.66, "secondary_phase": 0.8, "secondary_displacement": 1.0, "contact": 0.025, "waterline": 0.0, "bow": 0.14},
	{"id": "h3_plus_v2", "family": 1.0, "iteration": 12.0, "label": "H3+ V2", "heave": 0.40, "tilt": 0.25, "roll": 0.17, "secondary_direction": Vector2(-0.52, 0.85), "secondary_wavelength": 7.6, "secondary_steepness": 0.032, "secondary_time_scale": 0.54, "secondary_phase": 2.5, "secondary_displacement": 1.0, "contact": 0.040, "waterline": 0.025, "bow": 0.18},
	{"id": "h3_plus_v3", "family": 1.0, "iteration": 13.0, "label": "H3+ V3", "heave": 0.43, "tilt": 0.21, "roll": 0.14, "secondary_direction": Vector2(0.38, 0.92), "secondary_wavelength": 8.4, "secondary_steepness": 0.035, "secondary_time_scale": 0.44, "secondary_phase": 4.1, "secondary_displacement": 1.0, "contact": 0.050, "waterline": 0.032, "bow": 0.20},
]

var source_instance: Node3D
var water_mesh: MeshInstance3D
var boat_visual: Node3D
var camera: Camera3D
var sun: DirectionalLight3D
var locked_baselines: Dictionary = {}
var coupling_material: ShaderMaterial
var bow_interaction: MeshInstance3D
var visual_time := 0.0
var current_profile: Dictionary = {}
var capture_mode := false
var boat_yaw := 0.0
var long_observation_active := false
var interactive_mode := false
var test_speed := 0.0
var test_stop_latched := false
var test_camera_target := Vector3.ZERO
var test_camera_initialized := false
var test_camera_look_target := 0.0
var test_camera_look_angle := 0.0
var test_camera_pitch_target := 0.0
var test_camera_pitch := 0.0

const TEST_FORWARD_SPEED := 1.15
const TEST_REVERSE_SPEED := 0.45
const TEST_ACCELERATION := 0.72
const TEST_BRAKE := 1.20
const TEST_TURN_RATE := 0.52
const TEST_CAMERA_SMOOTHING := 5.0
const TEST_CAMERA_LOOK_SENSITIVITY := 0.0045
const TEST_CAMERA_LOOK_VERTICAL_SENSITIVITY := 0.0030
const TEST_CAMERA_LOOK_VERTICAL_MIN := -0.17
const TEST_CAMERA_LOOK_VERTICAL_MAX := 0.35


func _ready() -> void:
	_configure_viewport()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	source_instance = SOURCE_SCENE.instantiate()
	source_instance.name = "RobinBlockout_SOURCE_COPY_ONLY"
	add_child(source_instance)
	# The source script has already built its visual copy. Stop its own update
	# loop before taking ownership of the duplicated water/boat visuals.
	source_instance.set_process(false)
	await _wait_for_source_nodes()
	_setup_coupling_material()
	_build_bow_interaction()
	var args := OS.get_cmdline_user_args()
	interactive_mode = args.has("--boat-wave-coupling-b-plus-v3") or args.has("--boat-wave-coupling-h3-plus-v3")
	if args.has("--boat-wave-coupling-h3-plus-v3"):
		_set_profile(CANDIDATES[5])
	else:
		_set_profile(CANDIDATES[2])
	print("BOAT_WAVE_COUPLING_OCEAN_POLISH_READY|isolated=true|production_logic=false|interactive=%s|profile=%s|formal_project_modified=false" % [str(interactive_mode), str(current_profile["label"])])
	if args.has("--capture-boat-wave-coupling"):
		capture_mode = true
		call_deferred("_capture_all")
	elif args.has("--observe-boat-wave-coupling"):
		call_deferred("_observe_long_duration")


func _process(delta: float) -> void:
	visual_time += delta
	if interactive_mode and not capture_mode and not long_observation_active:
		_update_interactive_navigation(delta)
	if coupling_material != null:
		coupling_material.set_shader_parameter("wave_time", visual_time)
		coupling_material.set_shader_parameter("camera_position_world", camera.global_position if camera != null else Vector3.ZERO)
	_update_boat_wave_follow(delta)
	if interactive_mode and not capture_mode and not long_observation_active:
		_update_interactive_camera(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not interactive_mode or capture_mode:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			if absf(test_speed) > 0.01 or test_stop_latched:
				test_stop_latched = true
			else:
				test_stop_latched = false
				test_speed = 0.0
		if event.keycode == KEY_BACKSPACE:
			_set_boat_pose(Vector3(0.0, 0.28, 0.0), 0.0, 0.0)
			test_speed = 0.0
			test_stop_latched = false


func _input(event: InputEvent) -> void:
	if not interactive_mode or capture_mode:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		test_camera_look_target = wrapf(
			test_camera_look_target - motion.relative.x * TEST_CAMERA_LOOK_SENSITIVITY,
			-PI,
			PI
		)
		test_camera_pitch_target = clampf(
			test_camera_pitch_target - motion.relative.y * TEST_CAMERA_LOOK_VERTICAL_SENSITIVITY,
			TEST_CAMERA_LOOK_VERTICAL_MIN,
			TEST_CAMERA_LOOK_VERTICAL_MAX
		)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		test_camera_look_target = 0.0
		test_camera_pitch_target = 0.0


func _update_interactive_navigation(delta: float) -> void:
	if boat_visual == null:
		return
	var steer := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		steer -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		steer += 1.0
	boat_yaw = wrapf(boat_yaw + steer * TEST_TURN_RATE * delta, -PI, PI)
	boat_visual.rotation.y = boat_yaw

	var forward_input := 0.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		forward_input += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		forward_input -= 1.0
	if test_stop_latched:
		forward_input = 0.0

	var target_speed := 0.0
	if forward_input > 0.0:
		target_speed = TEST_FORWARD_SPEED
	elif forward_input < 0.0:
		# S brakes first. Only after reaching zero does it permit reverse.
		target_speed = -TEST_REVERSE_SPEED if absf(test_speed) <= 0.01 else 0.0
	else:
		target_speed = 0.0
	var response := TEST_ACCELERATION if absf(target_speed) > absf(test_speed) else TEST_BRAKE
	if test_stop_latched:
		response = TEST_BRAKE
	test_speed = move_toward(test_speed, target_speed, response * delta)
	if absf(test_speed) < 0.008 and absf(target_speed) < 0.01:
		test_speed = 0.0
	var heading := Vector3(0.0, 0.0, -1.0).rotated(Vector3.UP, boat_yaw)
	boat_visual.position += heading * test_speed * delta
	boat_visual.set_meta("capture_speed", absf(test_speed) / TEST_FORWARD_SPEED)


func _update_interactive_camera(delta: float) -> void:
	if camera == null or boat_visual == null:
		return
	test_camera_look_angle = wrapf(lerp_angle(test_camera_look_angle, test_camera_look_target, clampf(delta * TEST_CAMERA_SMOOTHING, 0.0, 1.0)), -PI, PI)
	test_camera_pitch = lerpf(test_camera_pitch, test_camera_pitch_target, clampf(delta * TEST_CAMERA_SMOOTHING, 0.0, 1.0))
	var camera_offset := _rotate_camera_orbit(Vector3(-4.20, 4.05, 11.50), boat_yaw + test_camera_look_angle, test_camera_pitch)
	var target_offset := _rotate_camera_orbit(Vector3(0.0, 1.65, -17.80), boat_yaw + test_camera_look_angle, test_camera_pitch)
	var desired_position := boat_visual.position + camera_offset
	var desired_target := boat_visual.position + target_offset
	if not test_camera_initialized:
		camera.position = desired_position
		test_camera_target = desired_target
		test_camera_initialized = true
	else:
		camera.position = camera.position.lerp(desired_position, clampf(delta * TEST_CAMERA_SMOOTHING, 0.0, 1.0))
		test_camera_target = test_camera_target.lerp(desired_target, clampf(delta * TEST_CAMERA_SMOOTHING, 0.0, 1.0))
	camera.look_at(test_camera_target, Vector3.UP)


func _rotate_camera_orbit(value: Vector3, yaw: float, pitch: float) -> Vector3:
	var yawed := value.rotated(Vector3.UP, yaw)
	var right_axis := Vector3.RIGHT.rotated(Vector3.UP, yaw)
	return yawed.rotated(right_axis, pitch)


func _configure_viewport() -> void:
	var window := get_window()
	window.size = VIEWPORT_SIZE
	window.content_scale_size = VIEWPORT_SIZE
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED


func _wait_for_source_nodes() -> void:
	for _frame in range(12):
		await get_tree().process_frame
	water_mesh = source_instance.get_node_or_null("StylizedWaterForIslandBlockout") as MeshInstance3D
	boat_visual = source_instance.get_node_or_null("MainCabinSailboatVisual_COPY_ONLY") as Node3D
	camera = source_instance.get_node_or_null("RobinHoodsBayBlockout01Camera") as Camera3D
	sun = source_instance.get_node_or_null("RobinHoodsBayBlockout01Sun") as DirectionalLight3D
	if water_mesh == null or boat_visual == null or camera == null or sun == null:
		push_error("BoatWaveCouplingOceanPolish could not find source nodes.")
	boat_visual.position = BOAT_BASE_POSITION
	boat_visual.rotation = Vector3.ZERO


func _setup_coupling_material() -> void:
	if water_mesh == null:
		return
	_setup_locked_baselines()
	coupling_material = ShaderMaterial.new()
	coupling_material.shader = COUPLING_SHADER
	for index in range(WAVE_PARAMS.size()):
		coupling_material.set_shader_parameter("wave_%d" % (index + 1), WAVE_PARAMS[index])
	coupling_material.set_shader_parameter("time_factor", WAVE_TIME_FACTOR)
	coupling_material.set_shader_parameter("wave_amplitude_scale", WAVE_AMPLITUDE_SCALE)
	coupling_material.set_shader_parameter("wave_length_scale", WAVE_LENGTH_SCALE)
	coupling_material.set_shader_parameter("trough_color", Vector3(0.022, 0.115, 0.205))
	coupling_material.set_shader_parameter("water_color", Vector3(0.048, 0.245, 0.355))
	coupling_material.set_shader_parameter("crest_color", Vector3(0.145, 0.36, 0.415))
	coupling_material.set_shader_parameter("atmospheric_color", Vector3(0.205, 0.33, 0.39))
	coupling_material.set_shader_parameter("sky_tint", Vector3(0.48, 0.64, 0.69))
	coupling_material.set_shader_parameter("directional_light_direction_world", -sun.global_transform.basis.z)
	water_mesh.material_override = coupling_material


func _setup_locked_baselines() -> void:
	for mode in [2.0, 13.0]:
		var material := ShaderMaterial.new()
		material.shader = BASELINE_SHADER
		for index in range(WAVE_PARAMS.size()):
			material.set_shader_parameter("wave_%d" % (index + 1), WAVE_PARAMS[index])
		material.set_shader_parameter("time_factor", WAVE_TIME_FACTOR)
		material.set_shader_parameter("wave_amplitude_scale", WAVE_AMPLITUDE_SCALE)
		material.set_shader_parameter("wave_length_scale", WAVE_LENGTH_SCALE)
		material.set_shader_parameter("trough_color", Vector3(0.022, 0.115, 0.205))
		material.set_shader_parameter("water_color", Vector3(0.048, 0.245, 0.355))
		material.set_shader_parameter("crest_color", Vector3(0.145, 0.36, 0.415))
		material.set_shader_parameter("atmospheric_color", Vector3(0.205, 0.33, 0.39))
		material.set_shader_parameter("sky_tint", Vector3(0.48, 0.64, 0.69))
		material.set_shader_parameter("variant_mode", mode)
		locked_baselines[mode] = material


func _build_bow_interaction() -> void:
	bow_interaction = MeshInstance3D.new()
	bow_interaction.name = "BowInteraction_TEST_ONLY"
	var mesh := ArrayMesh.new()
	var vertices := PackedVector3Array([
		Vector3(0.0, 0.02, -1.90), Vector3(-0.62, 0.02, -0.72), Vector3(0.62, 0.02, -0.72),
		Vector3(-0.62, 0.021, -0.72), Vector3(-0.24, 0.021, 0.42), Vector3(0.24, 0.021, 0.42), Vector3(0.62, 0.021, -0.72),
	])
	var indices := PackedInt32Array([0, 1, 2, 3, 4, 5, 3, 5, 6])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	bow_interaction.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.62, 0.84, 0.82, 0.22)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test = false
	bow_interaction.material_override = material
	add_child(bow_interaction)


func _set_profile(profile: Dictionary) -> void:
	current_profile = profile
	if coupling_material == null:
		return
	coupling_material.set_shader_parameter("style_family", float(profile["family"]))
	coupling_material.set_shader_parameter("iteration", float(profile["iteration"]))
	coupling_material.set_shader_parameter("secondary_direction", profile["secondary_direction"])
	coupling_material.set_shader_parameter("secondary_wavelength", float(profile["secondary_wavelength"]))
	coupling_material.set_shader_parameter("secondary_steepness", float(profile["secondary_steepness"]))
	coupling_material.set_shader_parameter("secondary_time_scale", float(profile["secondary_time_scale"]))
	coupling_material.set_shader_parameter("secondary_phase", float(profile["secondary_phase"]))
	coupling_material.set_shader_parameter("secondary_displacement_scale", float(profile["secondary_displacement"]))
	coupling_material.set_shader_parameter("contact_strength", float(profile["contact"]))
	coupling_material.set_shader_parameter("waterline_strength", float(profile["waterline"]))


func _update_boat_wave_follow(delta: float) -> void:
	if boat_visual == null or current_profile.is_empty():
		return
	var sample_position := Vector2(boat_visual.position.x, boat_visual.position.z)
	var wave := _calculate_wave(sample_position, visual_time / WAVE_TIME_FACTOR, current_profile)
	var target_y := BOAT_BASE_POSITION.y + float(wave["height"]) * float(current_profile["heave"])
	boat_visual.position.y = lerpf(boat_visual.position.y, target_y, clampf(delta * 8.0, 0.0, 1.0))

	var water_normal: Vector3 = wave["normal"]
	var heading := Vector3(0.0, 0.0, -1.0).rotated(Vector3.UP, boat_yaw)
	if heading.length_squared() < 0.0001:
		heading = Vector3(0.0, 0.0, -1.0)
	heading.y = 0.0
	heading = heading.normalized()
	var tilt_strength := float(current_profile["tilt"])
	var roll_strength := float(current_profile["roll"])
	var forward_slope := clampf(water_normal.dot(heading), -0.6, 0.6)
	var lateral := Vector3(-heading.z, 0.0, heading.x)
	var lateral_slope := clampf(water_normal.dot(lateral), -0.6, 0.6)
	var target_pitch := forward_slope * tilt_strength
	var target_roll := lateral_slope * roll_strength
	var target_basis := Basis(Vector3(0.0, 1.0, 0.0), boat_yaw)
	target_basis = target_basis.rotated(target_basis.x, target_pitch)
	target_basis = target_basis.rotated(target_basis.z, target_roll)
	boat_visual.basis = boat_visual.basis.slerp(target_basis, clampf(delta * 7.0, 0.0, 1.0))

	if bow_interaction != null:
		bow_interaction.position = Vector3(boat_visual.position.x, boat_visual.position.y - 0.015, boat_visual.position.z)
		bow_interaction.rotation.y = boat_visual.rotation.y
		var speed := _current_capture_speed()
		bow_interaction.scale = Vector3.ONE * clampf(speed, 0.0, 1.0)
		bow_interaction.visible = speed > 0.04
		coupling_material.set_shader_parameter("boat_position_world", boat_visual.global_position)
		coupling_material.set_shader_parameter("boat_forward_world", heading)
		coupling_material.set_shader_parameter("boat_speed", speed)


func _calculate_wave(pos: Vector2, time: float, profile: Dictionary) -> Dictionary:
	var displacement := Vector3.ZERO
	var normal := Vector3(0.0, 1.0, 0.0)
	for index in ACTIVE_WAVE_INDICES:
		var result := _calculate_gerstner_wave(WAVE_PARAMS[index], pos, time, 0.0, WAVE_AMPLITUDE_SCALE, WAVE_LENGTH_SCALE)
		displacement += result["displacement"]
		normal += result["normal"]
	if float(profile["secondary_displacement"]) > 0.0:
		var secondary_params := Vector4(profile["secondary_direction"].x, profile["secondary_direction"].y, float(profile["secondary_steepness"]), float(profile["secondary_wavelength"]) / WAVE_LENGTH_SCALE)
		var secondary := _calculate_gerstner_wave(secondary_params, pos, time * float(profile["secondary_time_scale"]), float(profile["secondary_phase"]), 1.0, WAVE_LENGTH_SCALE)
		displacement += secondary["displacement"] * float(profile["secondary_displacement"])
		normal += secondary["normal"] * float(profile["secondary_displacement"]) * 0.55
	return {"height": displacement.y, "normal": normal.normalized(), "displacement": displacement}


func _calculate_gerstner_wave(params: Vector4, pos: Vector2, time: float, phase_offset: float, amplitude_scale: float, length_scale: float) -> Dictionary:
	var steepness := params.z * (1.0 + 0.5 * sin(time + pos.length() * 0.1)) * amplitude_scale
	var wavelength := params.w * length_scale
	var k := TAU / wavelength
	var speed := sqrt(9.81 / k)
	var direction := Vector2(params.x, params.y).normalized()
	var phase := k * (direction.dot(pos) - speed * time) + phase_offset
	var amplitude := steepness / k
	var displacement := Vector3(direction.x * amplitude * cos(phase), amplitude * sin(phase), direction.y * amplitude * cos(phase))
	var tangent := Vector3(1.0 - direction.x * direction.x * steepness * sin(phase), steepness * cos(phase), -direction.x * direction.y * steepness * sin(phase))
	var binormal := Vector3(-direction.x * direction.y * steepness * sin(phase), steepness * cos(phase), 1.0 - direction.y * direction.y * steepness * sin(phase))
	return {"displacement": displacement, "normal": binormal.cross(tangent).normalized()}


func _set_boat_pose(position: Vector3, yaw_degrees: float, speed: float) -> void:
	boat_visual.position = position
	boat_yaw = deg_to_rad(yaw_degrees)
	boat_visual.rotation = Vector3(0.0, boat_yaw, 0.0)
	boat_visual.set_meta("capture_speed", speed)


func _current_capture_speed() -> float:
	return float(boat_visual.get_meta("capture_speed", 0.0)) if boat_visual != null else 0.0


func _set_camera_shot(shot_name: String) -> void:
	var shot: Dictionary = CAMERA_SHOTS[shot_name]
	camera.position = shot["position"]
	camera.fov = shot["fov"]
	camera.look_at(shot["target"], Vector3.UP)


func _apply_baseline(mode: float) -> void:
	water_mesh.material_override = locked_baselines.get(mode)
	var material := water_mesh.material_override as ShaderMaterial
	if material == null:
		return
	material.set_shader_parameter("wave_time", visual_time)
	material.set_shader_parameter("time_factor", WAVE_TIME_FACTOR)
	material.set_shader_parameter("wave_amplitude_scale", WAVE_AMPLITUDE_SCALE)
	material.set_shader_parameter("wave_length_scale", WAVE_LENGTH_SCALE)
	boat_visual.position = BOAT_BASE_POSITION
	boat_visual.rotation = Vector3.ZERO
	bow_interaction.visible = false


func _apply_candidate(profile: Dictionary) -> void:
	water_mesh.material_override = coupling_material
	_set_profile(profile)
	bow_interaction.visible = false


func _save_capture(path: String, label: String) -> void:
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	if error != OK:
		push_error("Cannot save boat wave coupling capture: " + path)
	else:
		print(label + "=" + path)


func _settle_frames(frame_count: int) -> void:
	for _frame in range(frame_count):
		await get_tree().process_frame


func _capture_all() -> void:
	var root := ProjectSettings.globalize_path(CAPTURE_ROOT)
	DirAccess.make_dir_recursive_absolute(root)
	await _capture_baseline(root.path_join("baseline_b"), 2.0, "Variant B baseline")
	await _capture_baseline(root.path_join("baseline_h3"), 13.0, "Hybrid V3 baseline")
	for profile in CANDIDATES:
		await _capture_profile(profile, root.path_join(String(profile["id"])))
	await _capture_rejected_extreme(root.path_join("rejected_too_strong"))
	var draw_calls := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitives := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("BOAT_WAVE_COUPLING_RENDER_INFO|draw_calls=%s|primitives=%s|gpu_ms_unavailable_in_runtime=true" % [str(draw_calls), str(primitives)])
	get_tree().quit()


func _capture_baseline(output_dir: String, mode: float, label: String) -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	_apply_baseline(mode)
	var views := [
		{"file": "01_idle.png", "pose": Vector3(0.0, 0.28, 0.0), "yaw": 0.0, "speed": 0.0, "camera": "overview"},
		{"file": "02_cruising.png", "pose": Vector3(0.0, 0.28, -5.0), "yaw": 0.0, "speed": 1.0, "camera": "overview"},
		{"file": "03_turning.png", "pose": Vector3(-2.0, 0.28, -4.0), "yaw": -28.0, "speed": 0.8, "camera": "overview"},
		{"file": "04_near_water.png", "pose": Vector3(0.0, 0.28, -1.0), "yaw": 0.0, "speed": 0.6, "camera": "near_water"},
		{"file": "05_horizon.png", "pose": Vector3(0.0, 0.28, -2.0), "yaw": 0.0, "speed": 0.8, "camera": "horizon"},
		{"file": "06_boat_side.png", "pose": Vector3(0.0, 0.28, -1.0), "yaw": 90.0, "speed": 0.6, "camera": "boat_side"},
	]
	for view in views:
		_set_boat_pose(view["pose"], float(view["yaw"]), float(view["speed"]))
		_set_camera_shot(String(view["camera"]))
		await _settle_frames(24)
		_save_capture(output_dir.path_join(String(view["file"])), "BOAT_WAVE_COUPLING_BASELINE_%s" % label)
	await _capture_temporal(output_dir.path_join("temporal"), label)


func _capture_profile(profile: Dictionary, output_dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	_apply_candidate(profile)
	var views := [
		{"file": "01_idle.png", "pose": Vector3(0.0, 0.28, 0.0), "yaw": 0.0, "speed": 0.0, "camera": "overview"},
		{"file": "02_cruising.png", "pose": Vector3(0.0, 0.28, -5.0), "yaw": 0.0, "speed": 1.0, "camera": "overview"},
		{"file": "03_turning.png", "pose": Vector3(-2.0, 0.28, -4.0), "yaw": -28.0, "speed": 0.8, "camera": "overview"},
		{"file": "04_near_water.png", "pose": Vector3(0.0, 0.28, -1.0), "yaw": 0.0, "speed": 0.6, "camera": "near_water"},
		{"file": "05_horizon.png", "pose": Vector3(0.0, 0.28, -2.0), "yaw": 0.0, "speed": 0.8, "camera": "horizon"},
		{"file": "06_boat_side.png", "pose": Vector3(0.0, 0.28, -1.0), "yaw": 90.0, "speed": 0.6, "camera": "boat_side"},
	]
	for view in views:
		_set_boat_pose(view["pose"], float(view["yaw"]), float(view["speed"]))
		_set_camera_shot(String(view["camera"]))
		await _settle_frames(24)
		_save_capture(output_dir.path_join(String(view["file"])), "BOAT_WAVE_COUPLING_%s" % profile["label"])
	await _capture_temporal(output_dir.path_join("temporal"), String(profile["label"]))


func _capture_temporal(output_dir: String, label: String) -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	_set_boat_pose(Vector3(0.0, 0.28, -1.0), 0.0, 0.85)
	_set_camera_shot("near_water")
	for frame_index in range(6):
		await _settle_frames(18 if frame_index == 0 else 54)
		_save_capture(output_dir.path_join("%02d.png" % frame_index), "BOAT_WAVE_COUPLING_TEMPORAL_%s" % label)


func _capture_rejected_extreme(output_dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	var extreme := {"id": "rejected", "family": 0.0, "iteration": 2.0, "label": "REJECTED_TOO_STRONG", "heave": 1.65, "tilt": 1.35, "roll": 1.20, "secondary_direction": Vector2(0.82, 0.28), "secondary_wavelength": 3.3, "secondary_steepness": 0.16, "secondary_time_scale": 1.10, "secondary_phase": 0.0, "secondary_displacement": 1.0, "contact": 0.24, "waterline": 0.30, "bow": 1.0}
	_apply_candidate(extreme)
	_set_boat_pose(Vector3(0.0, 0.28, -1.0), 0.0, 1.0)
	_set_camera_shot("near_water")
	await _settle_frames(24)
	_save_capture(output_dir.path_join("REJECTED_TOO_STRONG_boat.png"), "BOAT_WAVE_COUPLING_REJECTED")
	await _capture_temporal(output_dir.path_join("temporal"), "REJECTED_TOO_STRONG")


func _observe_long_duration() -> void:
	_apply_candidate(CANDIDATES[2])
	_set_boat_pose(Vector3(0.0, 0.28, -1.0), 0.0, 0.85)
	_set_camera_shot("overview")
	long_observation_active = true
	print("BOAT_WAVE_COUPLING_LONG_OBSERVATION_BEGIN|seconds=60|profile=B+ V3")
	var last_report := -1
	var elapsed := 0.0
	while elapsed < 60.0:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		# This is a visual observation path, not gameplay. The explicit phases
		# make stationary, slow/normal straight sailing, slow turning, repeated
		# changes, and parallel/across-wave headings observable in one run.
		var observation_speed := 0.0
		if elapsed >= 10.0 and elapsed < 22.0:
			observation_speed = 0.22 # slow straight
		elif elapsed >= 22.0 and elapsed < 34.0:
			observation_speed = 0.46 # normal straight
		elif elapsed >= 34.0 and elapsed < 46.0:
			observation_speed = 0.30 # slow turn
		elif elapsed >= 46.0:
			observation_speed = 0.38 # repeated heading changes
		boat_visual.position += Vector3(sin(elapsed * 0.11) * 0.025, 0.0, -observation_speed * get_process_delta_time())
		if elapsed > 34.0 and elapsed < 46.0:
			boat_yaw = lerpf(0.0, deg_to_rad(-28.0), (elapsed - 34.0) / 12.0)
		elif elapsed >= 46.0:
			# Alternate between a mostly parallel and an across-wave heading.
			boat_yaw = deg_to_rad(36.0 * sin((elapsed - 46.0) * 0.70))
		boat_visual.rotation.y = boat_yaw
		var second := int(elapsed)
		if second % 5 == 0 and second != last_report:
			last_report = second
			var sample := _calculate_wave(Vector2(boat_visual.position.x, boat_visual.position.z), visual_time / WAVE_TIME_FACTOR, CANDIDATES[2])
			print("BOAT_WAVE_COUPLING_LONG_SAMPLE|t=%d|height=%.3f|normal=%s" % [second, float(sample["height"]), str(sample["normal"])])
	print("BOAT_WAVE_COUPLING_LONG_OBSERVATION_END|seconds=60")
	long_observation_active = false
	get_tree().quit()
