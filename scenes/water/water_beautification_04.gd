extends Node3D

## WATER BEAUTIFICATION 04 - isolated water material comparison.
##
## The child Robin blockout remains the source of the current boat visual,
## island blockout, camera framing, and wave-follow architecture. This test
## swaps only the test instance's water shader and synchronizes the same wave
## preset to the visual-only boat follow. No formal game scene is instanced.

const SOURCE_SCENE := preload("res://scenes/water/RobinHoodsBayIslandBlockout01.tscn")
const BEAUTIFIED_SHADER := preload("res://materials/water_test/stylized_water_beautification_04.gdshader")
const CAPTURE_ROOT := "res://scenes/water/water_beautification_04_captures"
const VIEWPORT_SIZE := Vector2i(1152, 648)
const BOAT_BASE_POSITION := Vector3(0.0, 0.28, 0.0)

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

const PRESETS := {
	"calm": {
		"amplitude": 0.40,
		"length": 5.00,
		"crest_strength": 0.16,
		"breakup": 0.012,
		"trough": Vector3(0.030, 0.125, 0.195),
		"water": Vector3(0.055, 0.255, 0.350),
		"crest": Vector3(0.165, 0.345, 0.385),
	},
	"balanced": {
		"amplitude": 0.55,
		"length": 4.60,
		"crest_strength": 0.24,
		"breakup": 0.018,
		"trough": Vector3(0.022, 0.105, 0.180),
		"water": Vector3(0.035, 0.245, 0.350),
		"crest": Vector3(0.160, 0.360, 0.400),
	},
	"lively": {
		"amplitude": 0.68,
		"length": 4.25,
		"crest_strength": 0.29,
		"breakup": 0.022,
		"trough": Vector3(0.018, 0.095, 0.170),
		"water": Vector3(0.030, 0.230, 0.340),
		"crest": Vector3(0.170, 0.375, 0.420),
	},
}

const CAMERA_SHOTS := {
	"overview": {"position": Vector3(-4.20, 4.05, 11.50), "target": Vector3(0.0, 1.65, -17.80), "fov": 40.0},
	"boat": {"position": Vector3(-2.90, 2.25, 6.60), "target": Vector3(0.0, 0.85, -1.20), "fov": 44.0},
	"world": {"position": Vector3(-6.40, 5.15, 14.20), "target": Vector3(0.0, 2.05, -27.80), "fov": 40.0},
	"low_angle": {"position": Vector3(-3.40, 1.25, 5.80), "target": Vector3(0.0, 0.45, -6.50), "fov": 44.0},
}

var source_instance: Node3D
var water_material: ShaderMaterial
var water_mesh: MeshInstance3D
var boat_visual: Node3D
var camera: Camera3D
var preset_name := "balanced"
var preset: Dictionary
var visual_time := 0.0


func _ready() -> void:
	process_priority = 10
	_configure_viewport()
	preset_name = _read_preset_name()
	preset = PRESETS[preset_name]
	source_instance = SOURCE_SCENE.instantiate()
	source_instance.name = "RobinHoodsBayBlockout_SOURCE_COPY_ONLY"
	add_child(source_instance)
	await _wait_for_source_nodes()
	_apply_preset()
	print("WATER_BEAUTIFICATION_04_READY|preset=%s|isolated=true|source=RobinHoodsBayIslandBlockout01|hud=false" % preset_name)
	if OS.get_cmdline_user_args().has("--capture-water-beautification-04"):
		call_deferred("_capture_preset")


func _process(delta: float) -> void:
	visual_time += delta
	if water_material != null:
		water_material.set_shader_parameter("wave_time", visual_time)
	_update_wave_follow()


func _configure_viewport() -> void:
	var window := get_window()
	window.size = VIEWPORT_SIZE
	window.content_scale_size = VIEWPORT_SIZE
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED


func _read_preset_name() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--water-preset="):
			var requested := argument.trim_prefix("--water-preset=").to_lower()
			if PRESETS.has(requested):
				return requested
	return "balanced"


func _wait_for_source_nodes() -> void:
	for _frame in range(8):
		await get_tree().process_frame
	water_mesh = source_instance.get_node_or_null("StylizedWaterForIslandBlockout") as MeshInstance3D
	boat_visual = source_instance.get_node_or_null("MainCabinSailboatVisual_COPY_ONLY") as Node3D
	camera = source_instance.get_node_or_null("RobinHoodsBayBlockout01Camera") as Camera3D
	if water_mesh == null or boat_visual == null or camera == null:
		push_error("WaterBeautification04 could not find isolated source nodes.")


func _apply_preset() -> void:
	if water_mesh == null:
		return
	water_material = ShaderMaterial.new()
	water_material.shader = BEAUTIFIED_SHADER
	for index in range(WAVE_PARAMS.size()):
		water_material.set_shader_parameter("wave_%d" % (index + 1), WAVE_PARAMS[index])
	water_material.set_shader_parameter("wave_time", visual_time)
	water_material.set_shader_parameter("time_factor", 2.7)
	water_material.set_shader_parameter("wave_amplitude_scale", preset["amplitude"])
	water_material.set_shader_parameter("wave_length_scale", preset["length"])
	water_material.set_shader_parameter("trough_color", preset["trough"])
	water_material.set_shader_parameter("water_color", preset["water"])
	water_material.set_shader_parameter("crest_color", preset["crest"])
	water_material.set_shader_parameter("crest_strength", preset["crest_strength"])
	water_material.set_shader_parameter("broad_light_strength", 0.035)
	water_material.set_shader_parameter("surface_breakup_strength", preset["breakup"])
	water_material.set_shader_parameter("fresnel_strength", 0.035)
	water_mesh.material_override = water_material


func _update_wave_follow() -> void:
	if boat_visual == null:
		return
	var sample := Vector2(boat_visual.position.x, boat_visual.position.z)
	var wave := _calculate_wave(sample, visual_time / 2.7)
	boat_visual.position.y = BOAT_BASE_POSITION.y + float(wave["height"])
	var normal: Vector3 = wave["normal"]
	var forward := Vector3(0.0, 0.0, -1.0)
	var projected_forward := (forward - normal * forward.dot(normal)).normalized()
	if projected_forward.length_squared() < 0.0001:
		projected_forward = forward
	var right := projected_forward.cross(normal).normalized()
	boat_visual.basis = Basis(right, normal, -projected_forward).orthonormalized()


func _calculate_wave(pos: Vector2, time: float) -> Dictionary:
	var displacement := Vector3.ZERO
	var normal := Vector3(0.0, 1.0, 0.0)
	for index in ACTIVE_WAVE_INDICES:
		var wave := _calculate_gerstner_wave(WAVE_PARAMS[index], pos, time)
		displacement += wave["displacement"]
		normal += wave["normal"]
	return {"height": displacement.y, "normal": normal.normalized()}


func _calculate_gerstner_wave(params: Vector4, pos: Vector2, time: float) -> Dictionary:
	var steepness := params.z * (1.0 + 0.5 * sin(time + pos.length() * 0.1)) * float(preset["amplitude"])
	var wavelength := params.w * float(preset["length"])
	var k := TAU / wavelength
	var speed := sqrt(9.81 / k)
	var direction := Vector2(params.x, params.y).normalized()
	var phase := k * (direction.dot(pos) - speed * time)
	var amplitude := steepness / k
	var displacement := Vector3(
		direction.x * amplitude * cos(phase),
		amplitude * sin(phase),
		direction.y * amplitude * cos(phase)
	)
	var tangent := Vector3(
		1.0 - direction.x * direction.x * steepness * sin(phase),
		steepness * cos(phase),
		-direction.x * direction.y * steepness * sin(phase)
	)
	var binormal := Vector3(
		-direction.x * direction.y * steepness * sin(phase),
		steepness * cos(phase),
		1.0 - direction.y * direction.y * steepness * sin(phase)
	)
	return {"displacement": displacement, "normal": binormal.cross(tangent).normalized()}


func _set_camera_shot(shot_name: String) -> void:
	if camera == null:
		return
	var shot: Dictionary = CAMERA_SHOTS[shot_name]
	camera.position = shot["position"]
	camera.fov = shot["fov"]
	camera.look_at(shot["target"], Vector3.UP)


func _capture_preset() -> void:
	var output_dir := ProjectSettings.globalize_path(CAPTURE_ROOT.path_join(preset_name))
	DirAccess.make_dir_recursive_absolute(output_dir)
	var shots := [
		{"name": "overview", "file": "01_overview.png"},
		{"name": "boat", "file": "02_boat.png"},
		{"name": "world", "file": "03_world.png"},
		{"name": "low_angle", "file": "04_low_angle.png"},
	]
	for shot in shots:
		_set_camera_shot(String(shot["name"]))
		for _frame in range(24):
			await get_tree().process_frame
		var image := get_viewport().get_texture().get_image()
		var path := output_dir.path_join(String(shot["file"]))
		var error := image.save_png(path)
		if error != OK:
			push_error("Cannot save Water Beautification 04 screenshot: " + path)
		else:
			print("WATER_BEAUTIFICATION_04_SCREENSHOT=" + path)
	var sample_wave := _calculate_wave(Vector2.ZERO, visual_time / 2.7)
	print("WATER_BEAUTIFICATION_04_SAMPLE|preset=%s|boat_y=%.3f|wave_height=%.3f" % [preset_name, boat_visual.position.y, float(sample_wave["height"])])
	var draw_calls := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitives := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("WATER_BEAUTIFICATION_04_RENDER_INFO|preset=%s|draw_calls=%s|primitives=%s|gpu_ms_unavailable_in_runtime=true" % [preset_name, str(draw_calls), str(primitives)])
	get_tree().quit()
