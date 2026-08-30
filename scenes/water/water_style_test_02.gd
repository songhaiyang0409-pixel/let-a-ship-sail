extends Node3D

## Isolated Water Style Test 02.
##
## This scene is a visual benchmark only. It extracts a copy of the current
## boat mesh hierarchy at runtime, then frees the source visual-builder node.
## No boat controller, input, collision, wake, timer, or voyage state is kept.

const BOAT_SOURCE_SCRIPT := preload("res://visual_prototype_3d.gd")
const LESUSX_WATER_SHADER := preload("res://materials/water_test/lesusx_water_b1_style_test_02.gdshader")
const CAPTURE_DIR := "res://scenes/water/water_style_test_02_captures"

# These are copied from the current Sea Trial presentation scale. The test
# scene uses them as camera-relative values, without loading the camera script.
const BOAT_START_POSITION := Vector3(-0.28, 0.28, -0.18)
const DEFAULT_CAMERA_POSITION := Vector3(-2.75, 3.82, 9.70)
const DEFAULT_CAMERA_TARGET := Vector3(-0.32, 0.72, -5.75)
const DEFAULT_CAMERA_FOV := 38.0
const BOAT_CLOSE_POSITION := Vector3(-2.55, 2.45, 5.35)
const BOAT_CLOSE_TARGET := Vector3(-0.20, 0.78, -0.10)
const BOAT_CLOSE_FOV := 42.0

var camera: Camera3D
var boat_visual: Node3D
var water: MeshInstance3D
var water_material: ShaderMaterial


func _ready() -> void:
	_configure_benchmark_viewport()

	_build_environment()
	_build_water()
	_build_simple_island_placeholder()
	await _extract_boat_visual_only()
	_build_camera()

	print("WATER_STYLE_TEST_02_READY|boat_visual=%s|water_material=%s" % [
		str(boat_visual != null),
		str(water_material != null),
	])

	if OS.get_cmdline_user_args().has("--capture-water-style-test-02"):
		call_deferred("_capture_all_shots")


func _configure_benchmark_viewport() -> void:
	# The formal project is portrait. This isolated benchmark explicitly uses a
	# landscape capture size without changing project.godot.
	var window := get_window()
	window.size = Vector2i(1152, 648)
	window.content_scale_size = Vector2i(1152, 648)
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	print("WATER_STYLE_TEST_02_VIEWPORT|size=%s|window=%s" % [
		str(get_viewport().size),
		str(window.size),
	])


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WaterStyleTest02Environment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.48, 0.70, 0.86, 1.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.68, 0.80, 0.88, 1.0)
	environment.ambient_light_energy = 0.78
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)

	var light := DirectionalLight3D.new()
	light.name = "WaterStyleTest02Sun"
	light.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	light.light_color = Color(1.0, 0.94, 0.84, 1.0)
	light.light_energy = 1.15
	light.shadow_enabled = true
	add_child(light)


func _build_water() -> void:
	water = MeshInstance3D.new()
	water.name = "LesusX_B1_ReducedFurther_Water"
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(160.0, 160.0)
	water_mesh.subdivide_width = 160
	water_mesh.subdivide_depth = 160
	water.mesh = water_mesh

	water_material = ShaderMaterial.new()
	water_material.shader = LESUSX_WATER_SHADER
	_apply_b1_reduced_further_parameters()
	water.material_override = water_material
	add_child(water)


func _apply_b1_reduced_further_parameters() -> void:
	# Keep the original LesusX Gerstner wave vectors unchanged.
	var waves := [
		Vector4(0.3, 4.0, 0.2, 0.6),
		Vector4(-0.26, -0.19, 0.01, 0.47),
		Vector4(-7.67, 5.63, 0.1, 0.38),
		Vector4(-0.42, -1.63, 0.1, 0.28),
		Vector4(1.66, 0.07, 0.15, 1.81),
		Vector4(1.20, 1.14, 0.01, 0.33),
		Vector4(-1.6, 7.3, 0.11, 0.73),
		Vector4(-0.42, -1.63, 0.15, 1.52),
	]
	for i in range(waves.size()):
		water_material.set_shader_parameter("wave_%d" % (i + 1), waves[i])

	water_material.set_shader_parameter("time_factor", 2.5)
	water_material.set_shader_parameter("noise_zoom", 2.0)

	# B1 was normal=-0.35 / noise=0.45. This test reduces both by about 33%.
	water_material.set_shader_parameter("noise_amp", 0.30)
	water_material.set_shader_parameter("base_water_color", Vector3(0.0, 0.4407456, 0.87445015))
	water_material.set_shader_parameter("fresnel_water_color", Vector3(0.7045933, 0.85339314, 1.0))
	water_material.set_shader_parameter("deep_water_color", Color(0.0, 0.0, 0.0, 1.0))
	water_material.set_shader_parameter("shallow_water_color", Color(0.0, 0.8069659, 0.7007982, 1.0))
	water_material.set_shader_parameter("beers_law", 0.5)
	water_material.set_shader_parameter("depth_offset", -1.2)
	water_material.set_shader_parameter("near", 7.0)
	water_material.set_shader_parameter("far", 10000.0)

	# B1 further-reduced surface and foam settings.
	water_material.set_shader_parameter("edge_texture_scale", 3.5)
	water_material.set_shader_parameter("edge_texture_speed", 0.1)
	water_material.set_shader_parameter("edge_foam_intensity", 0.45)
	water_material.set_shader_parameter("peak_intensity", 0.28)
	water_material.set_shader_parameter("foam_intensity", 0.30)
	water_material.set_shader_parameter("foam_scale", 1.0)
	water_material.set_shader_parameter("metallic", 0.12)
	water_material.set_shader_parameter("roughness", 0.34)
	water_material.set_shader_parameter("uv_scale_text_a", 0.1)
	water_material.set_shader_parameter("uv_speed_text_a", Vector2(0.42, 0.3))
	water_material.set_shader_parameter("uv_scale_text_b", 0.6)
	water_material.set_shader_parameter("uv_speed_text_b", Vector2(0.15, 0.1))
	water_material.set_shader_parameter("normal_strength", -0.24)
	water_material.set_shader_parameter("uv_sampler_scale", 0.10)
	water_material.set_shader_parameter("blend_factor", 0.10)
	water_material.set_shader_parameter("perturbation_strength", 0.08)
	water_material.set_shader_parameter("perturbation_time", 0.3)
	# The further-reduced test removes caustics entirely; this also keeps the
	# isolated scene independent from the third-party Texture2DArray importer.
	water_material.set_shader_parameter("caustics_intensity", 0.0)
	water_material.set_shader_parameter("num_caustic_layers", 16.0)
	water_material.set_shader_parameter("caustic_distortion_strength", 0.001)

	# Use a low-frequency procedural mask for the already weak foam inputs.
	# This is a benchmark utility texture, not a new art asset.
	var foam_texture := _make_scalar_texture(881, 0.045)
	water_material.set_shader_parameter("edge_foam_texture", foam_texture)
	water_material.set_shader_parameter("foam_texture", foam_texture)

	water_material.set_shader_parameter("normalmap_a", _make_normal_texture(171, 0.023))
	water_material.set_shader_parameter("normalmap_b", _make_normal_texture(349, 0.032))
	water_material.set_shader_parameter("uv_sampler", _make_normal_texture(701, 0.055))


func _make_normal_texture(seed_value: int, frequency: float) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.seamless = true
	texture.seamless_blend_skirt = 0.7
	texture.as_normal_map = true
	texture.noise = noise
	return texture


func _make_scalar_texture(seed_value: int, frequency: float) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.seamless = true
	texture.seamless_blend_skirt = 0.7
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 1.0])
	ramp.colors = PackedColorArray([
		Color(0.0, 0.0, 0.0, 1.0),
		Color(0.12, 0.14, 0.14, 1.0),
	])
	texture.color_ramp = ramp
	texture.noise = noise
	return texture


func _extract_boat_visual_only() -> void:
	# The current project stores the boat visual as a runtime-built hierarchy.
	# Build it once, duplicate only the boat node, then immediately free the
	# builder so no controller, camera, collision, wake, or voyage state remains.
	var source := BOAT_SOURCE_SCRIPT.new()
	source.name = "TemporaryBoatVisualSource"
	source.visible = false
	add_child(source)
	await get_tree().process_frame

	var source_boat := source.get_node_or_null("MainCabinSailboatBlockoutV02")
	if source_boat == null:
		push_error("WaterStyleTest02 could not extract the current boat visual.")
		source.free()
		return

	boat_visual = source_boat.duplicate()
	boat_visual.name = "MainCabinSailboatVisual_COPY_ONLY"
	source.free()
	boat_visual.position = Vector3.ZERO
	boat_visual.rotation = Vector3.ZERO
	add_child(boat_visual)


func _build_simple_island_placeholder() -> void:
	var island_root := Node3D.new()
	island_root.name = "SimpleIslandPlaceholder_ONLY"
	island_root.set_meta("asset_status", "PLACEHOLDER_VISUAL_ONLY")
	add_child(island_root)

	var island_material := StandardMaterial3D.new()
	island_material.albedo_color = Color(0.16, 0.30, 0.27, 1.0)
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
	island.position = Vector3(0.0, 0.65, -32.0)
	island.scale = Vector3(1.45, 0.55, 0.72)
	island_root.add_child(island)

	var marker_material := StandardMaterial3D.new()
	marker_material.albedo_color = Color(0.28, 0.36, 0.29, 1.0)
	marker_material.roughness = 1.0
	var marker_mesh := CylinderMesh.new()
	marker_mesh.top_radius = 0.22
	marker_mesh.bottom_radius = 0.34
	marker_mesh.height = 1.7
	marker_mesh.radial_segments = 8
	var marker := MeshInstance3D.new()
	marker.name = "SimpleDistantHighPoint_PLACEHOLDER"
	marker.mesh = marker_mesh
	marker.material_override = marker_material
	marker.position = Vector3(0.9, 2.15, -32.0)
	island_root.add_child(marker)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "WaterStyleTest02Camera"
	camera.current = true
	camera.near = 0.05
	camera.far = 180.0
	add_child(camera)
	_set_camera_shot("overview")


func _set_camera_shot(shot_name: String) -> void:
	var position := DEFAULT_CAMERA_POSITION - BOAT_START_POSITION
	var target := DEFAULT_CAMERA_TARGET - BOAT_START_POSITION
	var fov := DEFAULT_CAMERA_FOV
	match shot_name:
		"boat":
			position = BOAT_CLOSE_POSITION - BOAT_START_POSITION
			target = BOAT_CLOSE_TARGET - BOAT_START_POSITION
			fov = BOAT_CLOSE_FOV
		"low_angle":
			position = Vector3(-2.10, 1.55, 6.80) - BOAT_START_POSITION
			target = Vector3(-0.12, 0.34, -2.60) - BOAT_START_POSITION
			fov = 40.0
		"surface":
			position = Vector3(-1.35, 1.00, 3.35) - BOAT_START_POSITION
			target = Vector3(0.0, 0.15, -0.85) - BOAT_START_POSITION
			fov = 46.0
		"distance":
			position = Vector3(-1.55, 4.85, 11.80) - BOAT_START_POSITION
			target = Vector3(0.35, 0.58, -13.50) - BOAT_START_POSITION
			fov = 33.0
	camera.position = position
	camera.fov = fov
	camera.look_at(target, Vector3.UP)


func _capture_all_shots() -> void:
	var output_dir := ProjectSettings.globalize_path(CAPTURE_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var shots := [
		{"name": "overview", "file": "01_overview.png"},
		{"name": "boat", "file": "02_boat.png"},
		{"name": "low_angle", "file": "03_low_angle.png"},
		{"name": "surface", "file": "04_surface.png"},
		{"name": "distance", "file": "05_distance.png"},
	]
	for shot in shots:
		_set_camera_shot(String(shot["name"]))
		for frame in range(12):
			await get_tree().process_frame
		var image := get_viewport().get_texture().get_image()
		var path := output_dir.path_join(String(shot["file"]))
		var error := image.save_png(path)
		if error != OK:
			push_error("Cannot save Water Style Test 02 screenshot: " + path)
		else:
			print("WATER_STYLE_TEST_02_SCREENSHOT=" + path)
	get_tree().quit()
