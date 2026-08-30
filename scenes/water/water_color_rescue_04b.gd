extends Node3D

## WATER COLOR RESCUE 04B - Balanced color-only rescue.
##
## This scene instantiates the existing Robin blockout as an isolated copy,
## keeps its four active Gerstner waves and boat follow values unchanged, and
## replaces only the test water material. It does not instantiate formal game
## control, timer, collision, wake, Sea Trial, or Journey Test systems.

const SOURCE_SCENE := preload("res://scenes/water/RobinHoodsBayIslandBlockout01.tscn")
const COLOR_RESCUE_SHADER := preload("res://materials/water_test/stylized_water_color_rescue_04b.gdshader")
const CAPTURE_ROOT := "res://scenes/water/water_color_rescue_04b_captures"
const BEFORE_OVERVIEW := "res://scenes/water/water_beautification_04_captures/balanced/01_overview.png"
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
const WAVE_AMPLITUDE_SCALE := 0.55
const WAVE_LENGTH_SCALE := 4.60
const WAVE_TIME_FACTOR := 2.7

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
var sun: DirectionalLight3D
var visual_time := 0.0


func _ready() -> void:
	process_priority = 10
	_configure_viewport()
	source_instance = SOURCE_SCENE.instantiate()
	source_instance.name = "RobinHoodsBayBlockout_SOURCE_COPY_ONLY"
	add_child(source_instance)
	await _wait_for_source_nodes()
	_apply_color_rescue_material()
	print("WATER_COLOR_RESCUE_04B_READY|isolated=true|wave_amplitude=0.55|wave_length=4.60|active=wave_1,wave_5,wave_7,wave_8|hud=false")
	if OS.get_cmdline_user_args().has("--capture-water-color-rescue-04b"):
		call_deferred("_capture_all")


func _process(delta: float) -> void:
	visual_time += delta
	if water_material != null:
		water_material.set_shader_parameter("wave_time", visual_time)
		water_material.set_shader_parameter("camera_position_world", camera.global_position if camera != null else Vector3.ZERO)
		if sun != null:
			water_material.set_shader_parameter("directional_light_direction_world", -sun.global_transform.basis.z)
	_update_wave_follow()


func _configure_viewport() -> void:
	var window := get_window()
	window.size = VIEWPORT_SIZE
	window.content_scale_size = VIEWPORT_SIZE
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED


func _wait_for_source_nodes() -> void:
	for _frame in range(8):
		await get_tree().process_frame
	water_mesh = source_instance.get_node_or_null("StylizedWaterForIslandBlockout") as MeshInstance3D
	boat_visual = source_instance.get_node_or_null("MainCabinSailboatVisual_COPY_ONLY") as Node3D
	camera = source_instance.get_node_or_null("RobinHoodsBayBlockout01Camera") as Camera3D
	sun = source_instance.get_node_or_null("RobinHoodsBayBlockout01Sun") as DirectionalLight3D
	if water_mesh == null or boat_visual == null or camera == null or sun == null:
		push_error("WaterColorRescue04B could not find isolated source nodes.")


func _apply_color_rescue_material() -> void:
	if water_mesh == null:
		return
	water_material = ShaderMaterial.new()
	water_material.shader = COLOR_RESCUE_SHADER
	for index in range(WAVE_PARAMS.size()):
		water_material.set_shader_parameter("wave_%d" % (index + 1), WAVE_PARAMS[index])
	water_material.set_shader_parameter("wave_time", visual_time)
	water_material.set_shader_parameter("time_factor", WAVE_TIME_FACTOR)
	water_material.set_shader_parameter("wave_amplitude_scale", WAVE_AMPLITUDE_SCALE)
	water_material.set_shader_parameter("wave_length_scale", WAVE_LENGTH_SCALE)
	water_material.set_shader_parameter("trough_color", Vector3(0.060, 0.205, 0.300))
	water_material.set_shader_parameter("water_color", Vector3(0.085, 0.320, 0.430))
	water_material.set_shader_parameter("crest_color", Vector3(0.155, 0.400, 0.455))
	water_material.set_shader_parameter("atmospheric_water_color", Vector3(0.245, 0.405, 0.465))
	water_material.set_shader_parameter("sky_tint", Vector3(0.48, 0.64, 0.69))
	water_material.set_shader_parameter("crest_strength", 0.18)
	water_material.set_shader_parameter("directional_shading_strength", 0.16)
	water_material.set_shader_parameter("fresnel_strength", 0.065)
	water_material.set_shader_parameter("distance_color_strength", 0.16)
	water_material.set_shader_parameter("breakup_strength", 0.03)
	water_material.set_shader_parameter("camera_position_world", camera.global_position)
	water_material.set_shader_parameter("directional_light_direction_world", -sun.global_transform.basis.z)
	water_mesh.material_override = water_material


func _update_wave_follow() -> void:
	if boat_visual == null:
		return
	var sample := Vector2(boat_visual.position.x, boat_visual.position.z)
	var wave := _calculate_wave(sample, visual_time / WAVE_TIME_FACTOR)
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
	var steepness := params.z * (1.0 + 0.5 * sin(time + pos.length() * 0.1)) * WAVE_AMPLITUDE_SCALE
	var wavelength := params.w * WAVE_LENGTH_SCALE
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


func _capture_all() -> void:
	var output_dir := ProjectSettings.globalize_path(CAPTURE_ROOT)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var shots := [
		{"name": "overview", "file": "01_overview.png"},
		{"name": "boat", "file": "02_boat.png"},
		{"name": "world", "file": "03_world.png"},
		{"name": "low_angle", "file": "04_low_angle.png"},
	]
	var after_overview: Image
	for shot in shots:
		_set_camera_shot(String(shot["name"]))
		for _frame in range(24):
			await get_tree().process_frame
		var image := get_viewport().get_texture().get_image()
		if String(shot["name"]) == "overview":
			after_overview = image.duplicate()
		var path := output_dir.path_join(String(shot["file"]))
		var error := image.save_png(path)
		if error != OK:
			push_error("Cannot save Water Color Rescue 04B screenshot: " + path)
		else:
			print("WATER_COLOR_RESCUE_04B_SCREENSHOT=" + path)
	if after_overview != null:
		_create_before_after(after_overview, output_dir.path_join("00_before_after_overview.png"))
	var sample_wave := _calculate_wave(Vector2.ZERO, visual_time / WAVE_TIME_FACTOR)
	print("WATER_COLOR_RESCUE_04B_SAMPLE|boat_y=%.3f|wave_height=%.3f|amplitude=0.55|length=4.60" % [boat_visual.position.y, float(sample_wave["height"])])
	var draw_calls := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitives := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("WATER_COLOR_RESCUE_04B_RENDER_INFO|draw_calls=%s|primitives=%s|gpu_ms_unavailable_in_runtime=true" % [str(draw_calls), str(primitives)])
	get_tree().quit()


func _create_before_after(after_image: Image, output_path: String) -> void:
	var before_path := ProjectSettings.globalize_path(BEFORE_OVERVIEW)
	var before_image := Image.load_from_file(before_path)
	if before_image == null:
		push_error("Cannot load Balanced before image: " + before_path)
		return
	# Viewport captures and PNG imports can use different channel formats;
	# normalize both before blitting so the diagnostic comparison itself has no
	# image-format error.
	before_image.convert(Image.FORMAT_RGBA8)
	after_image.convert(Image.FORMAT_RGBA8)
	var comparison := Image.create(before_image.get_width() + after_image.get_width(), max(before_image.get_height(), after_image.get_height()), false, Image.FORMAT_RGBA8)
	comparison.blit_rect(before_image, Rect2i(Vector2i.ZERO, before_image.get_size()), Vector2i.ZERO)
	comparison.blit_rect(after_image, Rect2i(Vector2i.ZERO, after_image.get_size()), Vector2i(before_image.get_width(), 0))
	var error := comparison.save_png(output_path)
	if error != OK:
		push_error("Cannot save before/after comparison: " + output_path)
	else:
		print("WATER_COLOR_RESCUE_04B_BEFORE_AFTER=" + output_path)
