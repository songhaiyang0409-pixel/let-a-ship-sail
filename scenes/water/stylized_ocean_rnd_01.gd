extends Node3D

## STYLIZED OCEAN R&D 01 — isolated visual comparison scene.
##
## It reuses only the Robin blockout's boat, island, sky, and camera-scale
## references. The source scene remains untouched. This scene has no formal
## sailing controller, timer, collision, wake, or voyage state.

const SOURCE_SCENE := preload("res://scenes/water/RobinHoodsBayIslandBlockout01.tscn")
const RND_SHADER := preload("res://materials/water_test/stylized_ocean_rnd_01.gdshader")
const CAPTURE_ROOT := "res://scenes/water/stylized_ocean_rnd_01_captures"
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
const WAVE_AMPLITUDE_SCALE := 0.70
const WAVE_LENGTH_SCALE := 3.8
const WAVE_TIME_FACTOR := 2.7

const CAMERA_SHOTS := {
	"overview": {"position": Vector3(-4.20, 4.05, 11.50), "target": Vector3(0.0, 1.65, -17.80), "fov": 40.0},
	"near_water": {"position": Vector3(-3.40, 1.25, 5.80), "target": Vector3(0.0, 0.45, -6.50), "fov": 44.0},
	"horizon": {"position": Vector3(-1.80, 5.65, 16.20), "target": Vector3(0.0, 0.80, -28.0), "fov": 34.0},
}

var source_instance: Node3D
var water_mesh: MeshInstance3D
var boat_visual: Node3D
var camera: Camera3D
var sun: DirectionalLight3D
var baseline_material: Material
var rnd_material: ShaderMaterial
var visual_time := 0.0
var active_mode := 0.0


func _ready() -> void:
	_configure_viewport()
	source_instance = SOURCE_SCENE.instantiate()
	source_instance.name = "RobinBlockout_SOURCE_COPY_ONLY"
	add_child(source_instance)
	await _wait_for_source_nodes()
	_setup_rnd_material()
	print("STYLIZED_OCEAN_RND_01_READY|isolated=true|source=RobinBlockout_COPY_ONLY|formal_project_modified=false")
	if OS.get_cmdline_user_args().has("--capture-stylized-ocean-rnd-01"):
		call_deferred("_capture_all_variants")


func _process(delta: float) -> void:
	visual_time += delta
	if rnd_material != null and active_mode != 0.0:
		_update_rnd_uniforms()


func _configure_viewport() -> void:
	var window := get_window()
	window.size = VIEWPORT_SIZE
	window.content_scale_size = VIEWPORT_SIZE
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED


func _wait_for_source_nodes() -> void:
	for _frame in range(10):
		await get_tree().process_frame
	water_mesh = source_instance.get_node_or_null("StylizedWaterForIslandBlockout") as MeshInstance3D
	boat_visual = source_instance.get_node_or_null("MainCabinSailboatVisual_COPY_ONLY") as Node3D
	camera = source_instance.get_node_or_null("RobinHoodsBayBlockout01Camera") as Camera3D
	sun = source_instance.get_node_or_null("RobinHoodsBayBlockout01Sun") as DirectionalLight3D
	if water_mesh == null or boat_visual == null or camera == null or sun == null:
		push_error("StylizedOceanRND01 could not find source nodes.")
	baseline_material = water_mesh.material_override if water_mesh != null else null


func _setup_rnd_material() -> void:
	if water_mesh == null:
		return
	rnd_material = ShaderMaterial.new()
	rnd_material.shader = RND_SHADER
	for index in range(WAVE_PARAMS.size()):
		rnd_material.set_shader_parameter("wave_%d" % (index + 1), WAVE_PARAMS[index])
	rnd_material.set_shader_parameter("time_factor", WAVE_TIME_FACTOR)
	rnd_material.set_shader_parameter("wave_amplitude_scale", WAVE_AMPLITUDE_SCALE)
	rnd_material.set_shader_parameter("wave_length_scale", WAVE_LENGTH_SCALE)
	rnd_material.set_shader_parameter("trough_color", Vector3(0.022, 0.115, 0.205))
	rnd_material.set_shader_parameter("water_color", Vector3(0.048, 0.245, 0.355))
	rnd_material.set_shader_parameter("crest_color", Vector3(0.145, 0.36, 0.415))
	rnd_material.set_shader_parameter("atmospheric_color", Vector3(0.205, 0.33, 0.39))
	rnd_material.set_shader_parameter("sky_tint", Vector3(0.48, 0.64, 0.69))
	rnd_material.set_shader_parameter("directional_light_direction_world", -sun.global_transform.basis.z)
	_update_rnd_uniforms()


func _update_rnd_uniforms() -> void:
	rnd_material.set_shader_parameter("variant_mode", active_mode)
	rnd_material.set_shader_parameter("wave_time", visual_time)
	rnd_material.set_shader_parameter("camera_position_world", camera.global_position if camera != null else Vector3.ZERO)
	if sun != null:
		rnd_material.set_shader_parameter("directional_light_direction_world", -sun.global_transform.basis.z)


func _set_variant(mode: float) -> void:
	active_mode = mode
	if mode == 0.0:
		water_mesh.material_override = baseline_material
	else:
		water_mesh.material_override = rnd_material
		_update_rnd_uniforms()


func _set_boat_state(position: Vector3, yaw_degrees: float) -> void:
	if boat_visual == null:
		return
	boat_visual.position = position
	boat_visual.rotation = Vector3(0.0, deg_to_rad(yaw_degrees), 0.0)


func _set_camera_shot(shot_name: String) -> void:
	var shot: Dictionary = CAMERA_SHOTS[shot_name]
	camera.position = shot["position"]
	camera.fov = shot["fov"]
	camera.look_at(shot["target"], Vector3.UP)


func _capture_all_variants() -> void:
	var variants := [
		{"id": "baseline", "mode": 0.0},
		{"id": "variant_a", "mode": 1.0},
		{"id": "variant_b", "mode": 2.0},
		{"id": "variant_c", "mode": 3.0},
		{"id": "hybrid_v1", "mode": 11.0},
		{"id": "hybrid_v2", "mode": 12.0},
		{"id": "hybrid_v3", "mode": 13.0},
	]
	for variant in variants:
		await _capture_variant(String(variant["id"]), float(variant["mode"]))
	var draw_calls := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitives := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("STYLIZED_OCEAN_RND_01_RENDER_INFO|draw_calls=%s|primitives=%s|gpu_ms_unavailable_in_runtime=true" % [str(draw_calls), str(primitives)])
	get_tree().quit()


func _capture_variant(variant_id: String, mode: float) -> void:
	_set_variant(mode)
	var output_dir := ProjectSettings.globalize_path(CAPTURE_ROOT.path_join(variant_id))
	DirAccess.make_dir_recursive_absolute(output_dir)
	var views := [
		{"file": "01_idle.png", "boat": Vector3(0.0, 0.28, 0.0), "yaw": 0.0, "camera": "overview"},
		{"file": "02_open_water_cruising.png", "boat": Vector3(0.0, 0.28, -5.0), "yaw": 0.0, "camera": "overview"},
		{"file": "03_turning.png", "boat": Vector3(-2.0, 0.28, -4.0), "yaw": -28.0, "camera": "overview"},
		{"file": "04_near_water.png", "boat": Vector3(0.0, 0.28, -1.0), "yaw": 0.0, "camera": "near_water"},
		{"file": "05_horizon.png", "boat": Vector3(0.0, 0.28, -2.0), "yaw": 0.0, "camera": "horizon"},
	]
	for view in views:
		_set_boat_state(view["boat"], float(view["yaw"]))
		_set_camera_shot(String(view["camera"]))
		await _settle_frames(18)
		_save_capture(output_dir.path_join(String(view["file"])), "STYLIZED_OCEAN_RND_01_SCREENSHOT")

	# Fixed camera temporal sequence. The camera and boat pose stay constant;
	# only the actual running wave time advances between frames.
	_set_boat_state(BOAT_BASE_POSITION, 0.0)
	_set_camera_shot("overview")
	var temporal_dir := output_dir.path_join("temporal")
	DirAccess.make_dir_recursive_absolute(temporal_dir)
	for frame_index in range(3):
		await _settle_frames(45 if frame_index > 0 else 18)
		_save_capture(temporal_dir.path_join("%02d.png" % frame_index), "STYLIZED_OCEAN_RND_01_TEMPORAL")


func _settle_frames(frame_count: int) -> void:
	for _frame in range(frame_count):
		await get_tree().process_frame


func _save_capture(path: String, prefix: String) -> void:
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	if error != OK:
		push_error("Cannot save stylized ocean R&D capture: " + path)
	else:
		print(prefix + "=" + path)
