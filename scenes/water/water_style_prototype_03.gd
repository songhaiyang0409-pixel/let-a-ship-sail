extends Node3D

## Isolated Stylized Water Prototype 03.
##
## LesusX is used only as the source of the Gerstner wave mathematics. This
## prototype deliberately does not load the LesusX material or its textures.
## It contains only visual water, a copied boat mesh hierarchy, a simple
## distant silhouette, and a Wave Follow Test. It has no controller, timer,
## collision, wake, voyage state, or Sea Trial dependency.

const BOAT_SOURCE_SCRIPT := preload("res://visual_prototype_3d.gd")
const STYLIZED_WATER_SHADER := preload("res://materials/water_test/stylized_water_prototype_03.gdshader")
const CAPTURE_DIR := "res://scenes/water/water_style_prototype_03_captures"

const VIEWPORT_SIZE := Vector2i(1152, 648)
const BOAT_BASE_POSITION := Vector3(0.0, 0.28, 0.0)
const WAVE_TIME_FACTOR := 2.5
const WAVE_AMPLITUDE_SCALE := 0.95
const WAVE_LENGTH_SCALE := 3.2

const DEFAULT_CAMERA_POSITION := Vector3(-2.75, 3.82, 9.70)
const DEFAULT_CAMERA_TARGET := Vector3(-0.32, 0.72, -5.75)
const DEFAULT_CAMERA_FOV := 38.0

const BOAT_CLOSE_POSITION := Vector3(-2.55, 2.45, 5.35)
const BOAT_CLOSE_TARGET := Vector3(-0.20, 0.78, -0.10)
const BOAT_CLOSE_FOV := 42.0

const WAVE_PARAMS: Array[Vector4] = [
	Vector4(0.3, 4.0, 0.2, 0.6),
	Vector4(-0.26, -0.19, 0.01, 0.47),
	Vector4(-7.67, 5.63, 0.1, 0.38),
	Vector4(-0.42, -1.63, 0.1, 0.28),
	Vector4(1.66, 0.07, 0.15, 1.81),
	Vector4(1.20, 1.14, 0.01, 0.33),
	Vector4(-1.6, 7.3, 0.11, 0.73),
	Vector4(-0.42, -1.63, 0.15, 1.52),
]
const ACTIVE_WAVE_INDICES := [0, 4, 6, 7] # LesusX long-wave layers only.

var camera: Camera3D
var boat_visual: Node3D
var water: MeshInstance3D
var water_material: ShaderMaterial
var visual_time := 0.0
var boat_wave_height := 0.0
var boat_wave_normal := Vector3.UP


func _ready() -> void:
	_configure_benchmark_viewport()
	_build_environment()
	_build_water()
	_build_simple_island_placeholder()
	await _extract_boat_visual_only()
	_build_camera()
	_update_wave_follow(0.0)

	print("WATER_STYLE_PROTOTYPE_03_READY|boat_visual=%s|water_material=%s|textures=false|forward_plus_expected=true" % [
		str(boat_visual != null),
		str(water_material != null),
	])

	if OS.get_cmdline_user_args().has("--capture-water-style-prototype-03"):
		call_deferred("_capture_all_shots")


func _process(delta: float) -> void:
	visual_time += delta
	if water_material != null:
		water_material.set_shader_parameter("wave_time", visual_time)
	_update_wave_follow(delta)


func _configure_benchmark_viewport() -> void:
	var window := get_window()
	window.size = VIEWPORT_SIZE
	window.content_scale_size = VIEWPORT_SIZE
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	print("WATER_STYLE_PROTOTYPE_03_VIEWPORT|size=%s|window=%s" % [str(get_viewport().size), str(window.size)])


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WaterStylePrototype03Environment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.30, 0.60, 0.80, 1.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.68, 0.82, 0.90, 1.0)
	environment.ambient_light_energy = 0.82
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)

	var light := DirectionalLight3D.new()
	light.name = "WaterStylePrototype03Sun"
	light.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	light.light_color = Color(1.0, 0.94, 0.84, 1.0)
	light.light_energy = 1.05
	light.shadow_enabled = true
	add_child(light)


func _build_water() -> void:
	water = MeshInstance3D.new()
	water.name = "StylizedGeometricWaterPrototype03"
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(180.0, 180.0)
	water_mesh.subdivide_width = 160
	water_mesh.subdivide_depth = 160
	water.mesh = water_mesh

	water_material = ShaderMaterial.new()
	water_material.shader = STYLIZED_WATER_SHADER
	for index in range(WAVE_PARAMS.size()):
		water_material.set_shader_parameter("wave_%d" % (index + 1), WAVE_PARAMS[index])
	water_material.set_shader_parameter("wave_time", 0.0)
	water_material.set_shader_parameter("time_factor", WAVE_TIME_FACTOR)
	# Three intentionally restrained graphic layers. These are not LesusX
	# water-color uniforms and do not sample any texture.
	water_material.set_shader_parameter("trough_color", Vector3(0.018, 0.10, 0.19))
	water_material.set_shader_parameter("water_color", Vector3(0.028, 0.25, 0.40))
	water_material.set_shader_parameter("crest_color", Vector3(0.18, 0.47, 0.56))
	water_material.set_shader_parameter("wave_amplitude_scale", WAVE_AMPLITUDE_SCALE)
	water_material.set_shader_parameter("wave_length_scale", WAVE_LENGTH_SCALE)
	water_material.set_shader_parameter("crest_strength", 0.65)
	water_material.set_shader_parameter("broad_light_strength", 0.10)
	water.material_override = water_material
	add_child(water)


func _build_simple_island_placeholder() -> void:
	var root := Node3D.new()
	root.name = "SimpleDistantIsland_PLACEHOLDER_ONLY"
	root.set_meta("asset_status", "PLACEHOLDER_VISUAL_ONLY")
	add_child(root)

	var island_material := StandardMaterial3D.new()
	island_material.albedo_color = Color(0.12, 0.27, 0.25, 1.0)
	island_material.roughness = 1.0
	var island_mesh := SphereMesh.new()
	island_mesh.radius = 5.4
	island_mesh.height = 2.5
	island_mesh.radial_segments = 16
	island_mesh.rings = 8
	var island := MeshInstance3D.new()
	island.name = "LowPolyIslandMass_PLACEHOLDER"
	island.mesh = island_mesh
	island.material_override = island_material
	island.position = Vector3(0.0, 0.48, -34.0)
	island.scale = Vector3(1.45, 0.55, 0.72)
	root.add_child(island)

	var marker_material := StandardMaterial3D.new()
	marker_material.albedo_color = Color(0.24, 0.34, 0.29, 1.0)
	marker_material.roughness = 1.0
	var marker_mesh := CylinderMesh.new()
	marker_mesh.top_radius = 0.22
	marker_mesh.bottom_radius = 0.34
	marker_mesh.height = 1.7
	marker_mesh.radial_segments = 8
	var marker := MeshInstance3D.new()
	marker.name = "SimpleHighPoint_PLACEHOLDER"
	marker.mesh = marker_mesh
	marker.material_override = marker_material
	marker.position = Vector3(0.9, 2.0, -34.0)
	root.add_child(marker)


func _extract_boat_visual_only() -> void:
	var source := BOAT_SOURCE_SCRIPT.new()
	source.name = "TemporaryBoatVisualSource"
	source.visible = false
	add_child(source)
	await get_tree().process_frame

	var source_boat := source.get_node_or_null("MainCabinSailboatBlockoutV02")
	if source_boat == null:
		push_error("WaterStylePrototype03 could not extract the current boat visual.")
		source.free()
		return

	boat_visual = source_boat.duplicate()
	boat_visual.name = "MainCabinSailboatVisual_COPY_ONLY"
	source.free()
	boat_visual.position = BOAT_BASE_POSITION
	boat_visual.rotation = Vector3.ZERO
	add_child(boat_visual)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "WaterStylePrototype03Camera"
	camera.current = true
	camera.near = 0.05
	camera.far = 190.0
	add_child(camera)
	_set_camera_shot("overview")


func _set_camera_shot(shot_name: String) -> void:
	var position := DEFAULT_CAMERA_POSITION - BOAT_BASE_POSITION
	var target := DEFAULT_CAMERA_TARGET - BOAT_BASE_POSITION
	var fov := DEFAULT_CAMERA_FOV
	match shot_name:
		"boat":
			position = BOAT_CLOSE_POSITION - BOAT_BASE_POSITION
			target = BOAT_CLOSE_TARGET - BOAT_BASE_POSITION
			fov = BOAT_CLOSE_FOV
		"low_angle":
			position = Vector3(-2.10, 1.55, 6.80) - BOAT_BASE_POSITION
			target = Vector3(-0.12, 0.34, -2.60) - BOAT_BASE_POSITION
			fov = 40.0
	camera.position = position
	camera.fov = fov
	camera.look_at(target, Vector3.UP)


func _update_wave_follow(_delta: float) -> void:
	if boat_visual == null:
		return
	var sample_position := Vector2(boat_visual.position.x, boat_visual.position.z)
	var result := _calculate_wave(sample_position, visual_time / WAVE_TIME_FACTOR)
	boat_wave_height = result["height"]
	boat_wave_normal = result["normal"]

	# The root follows only the local water height. This is not buoyancy and it
	# does not alter any project boat logic; it is a visual synchronization test.
	boat_visual.position.y = BOAT_BASE_POSITION.y + boat_wave_height
	var forward := Vector3(0.0, 0.0, -1.0)
	var projected_forward := (forward - boat_wave_normal * forward.dot(boat_wave_normal)).normalized()
	if projected_forward.length_squared() < 0.0001:
		projected_forward = forward
	var right := projected_forward.cross(boat_wave_normal).normalized()
	boat_visual.basis = Basis(right, boat_wave_normal, -projected_forward).orthonormalized()


func _calculate_wave(pos: Vector2, time: float) -> Dictionary:
	var displacement := Vector3.ZERO
	var tangent := Vector3(1.0, 0.0, 0.0)
	var binormal := Vector3(0.0, 0.0, 1.0)
	var normal := Vector3(0.0, 1.0, 0.0)
	for index in ACTIVE_WAVE_INDICES:
		var params: Vector4 = WAVE_PARAMS[index]
		var result := _calculate_gerstner_wave(params, pos, time)
		displacement += result["displacement"]
		tangent += result["tangent"]
		binormal += result["binormal"]
		normal += result["normal"]
	return {
		"height": displacement.y,
		"displacement": displacement,
		"normal": normal.normalized(),
	}


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
	return {
		"displacement": displacement,
		"tangent": tangent,
		"binormal": binormal,
		"normal": binormal.cross(tangent).normalized(),
	}


func _capture_all_shots() -> void:
	var output_dir := ProjectSettings.globalize_path(CAPTURE_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var shots := [
		{"name": "overview", "file": "01_overview.png"},
		{"name": "boat", "file": "02_boat.png"},
		{"name": "low_angle", "file": "03_low_angle.png"},
	]
	for shot in shots:
		_set_camera_shot(String(shot["name"]))
		for _frame in range(18):
			await get_tree().process_frame
		var image := get_viewport().get_texture().get_image()
		var path := output_dir.path_join(String(shot["file"]))
		var error := image.save_png(path)
		if error != OK:
			push_error("Cannot save Water Style Prototype 03 screenshot: " + path)
		else:
			print("WATER_STYLE_PROTOTYPE_03_SCREENSHOT=" + path)

	var draw_calls := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitives := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("WATER_STYLE_PROTOTYPE_03_RENDER_INFO|fps=%s|draw_calls=%s|primitives=%s|gpu_ms_unavailable_in_runtime=%s" % [
		str(Engine.get_frames_per_second()),
		str(draw_calls),
		str(primitives),
		str(true),
	])
	get_tree().quit()
