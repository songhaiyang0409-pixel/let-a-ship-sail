extends Node3D

## Presentation Slice 01: an isolated visual handoff scene.
##
## This scene reuses only the current boat visual and the isolated geometric
## water shader. It does not instantiate Sea Trial, Journey Test, camera
## logic, boat control, collisions, wake, timer, or voyage state.

const BOAT_SOURCE_SCRIPT := preload("res://visual_prototype_3d.gd")
const STYLIZED_WATER_SHADER := preload("res://materials/water_test/stylized_water_prototype_03.gdshader")
const CAPTURE_DIR := "res://scenes/water/presentation_slice_01_captures"

const VIEWPORT_SIZE := Vector2i(1152, 648)
const BOAT_BASE_POSITION := Vector3(0.0, 0.28, 0.0)

# One light presentation pass over Prototype 03: longer, slightly varied
# waves and a slower crest emphasis. The shader remains texture-free.
const WAVE_TIME_FACTOR := 2.7
const WAVE_AMPLITUDE_SCALE := 0.75
const WAVE_LENGTH_SCALE := 3.6
const ACTIVE_WAVE_INDICES := [0, 4, 6, 7]
const WAVE_PARAMS: Array[Vector4] = [
	Vector4(0.34, 3.60, 0.18, 0.86),
	Vector4(-0.26, -0.19, 0.01, 0.47),
	Vector4(-7.67, 5.63, 0.1, 0.38),
	Vector4(-0.42, -1.63, 0.1, 0.28),
	Vector4(1.42, 0.28, 0.12, 2.18),
	Vector4(1.20, 1.14, 0.01, 0.33),
	Vector4(-1.05, 2.90, 0.08, 1.30),
	Vector4(-0.58, -1.22, 0.10, 1.82),
]

var camera: Camera3D
var boat_visual: Node3D
var water_material: ShaderMaterial
var visual_time := 0.0

const CAMERA_SHOTS := {
	"overview": {"position": Vector3(-3.55, 3.35, 10.60), "target": Vector3(-0.18, 0.82, -13.20), "fov": 40.0},
	"boat": {"position": Vector3(-2.65, 2.65, 6.05), "target": Vector3(-0.18, 0.82, -0.55), "fov": 42.0},
	"low_angle": {"position": Vector3(-2.40, 1.35, 6.90), "target": Vector3(-0.12, 0.52, -4.80), "fov": 42.0},
	"world_read": {"position": Vector3(-4.65, 3.80, 12.80), "target": Vector3(0.0, 1.05, -18.50), "fov": 41.0},
	"distance": {"position": Vector3(-1.80, 5.65, 16.20), "target": Vector3(0.0, 0.80, -22.0), "fov": 34.0},
}


func _ready() -> void:
	_configure_viewport()
	_build_environment()
	_build_water()
	_build_island_and_beacon()
	await _extract_boat_visual_only()
	_build_camera()
	_update_wave_follow()

	print("PRESENTATION_SLICE_01_READY|boat_visual=%s|water_material=%s|isolated=true|hud=false" % [
		str(boat_visual != null), str(water_material != null),
	])
	if OS.get_cmdline_user_args().has("--capture-presentation-slice-01"):
		call_deferred("_capture_all_shots")


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
	print("PRESENTATION_SLICE_01_VIEWPORT|size=%s|window=%s" % [str(get_viewport().size), str(window.size)])


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "PresentationSlice01Environment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.12, 0.40, 0.70, 1.0)
	sky_material.sky_horizon_color = Color(0.66, 0.82, 0.88, 1.0)
	sky_material.ground_bottom_color = Color(0.07, 0.20, 0.28, 1.0)
	sky_material.ground_horizon_color = Color(0.55, 0.72, 0.78, 1.0)
	sky_material.sun_angle_max = 12.0
	sky_material.sun_curve = 0.05
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.60, 0.76, 0.88, 1.0)
	environment.ambient_light_energy = 0.78
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.56, 0.74, 0.82, 1.0)
	environment.fog_light_energy = 0.55
	environment.fog_density = 0.006
	environment.fog_sky_affect = 0.22
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)

	var light := DirectionalLight3D.new()
	light.name = "PresentationSlice01Sun"
	light.rotation_degrees = Vector3(-50.0, -28.0, 0.0)
	light.light_color = Color(1.0, 0.93, 0.82, 1.0)
	light.light_energy = 1.08
	light.shadow_enabled = true
	add_child(light)


func _build_water() -> void:
	var water := MeshInstance3D.new()
	water.name = "StylizedWaterPresentation01"
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(190.0, 190.0)
	water_mesh.subdivide_width = 160
	water_mesh.subdivide_depth = 160
	water.mesh = water_mesh

	water_material = ShaderMaterial.new()
	water_material.shader = STYLIZED_WATER_SHADER
	for index in range(WAVE_PARAMS.size()):
		water_material.set_shader_parameter("wave_%d" % (index + 1), WAVE_PARAMS[index])
	water_material.set_shader_parameter("wave_time", 0.0)
	water_material.set_shader_parameter("time_factor", WAVE_TIME_FACTOR)
	water_material.set_shader_parameter("wave_amplitude_scale", WAVE_AMPLITUDE_SCALE)
	water_material.set_shader_parameter("wave_length_scale", WAVE_LENGTH_SCALE)
	water_material.set_shader_parameter("trough_color", Vector3(0.014, 0.085, 0.17))
	water_material.set_shader_parameter("water_color", Vector3(0.028, 0.23, 0.36))
	water_material.set_shader_parameter("crest_color", Vector3(0.15, 0.42, 0.50))
	water_material.set_shader_parameter("crest_strength", 0.58)
	water_material.set_shader_parameter("broad_light_strength", 0.08)
	water.material_override = water_material
	add_child(water)


func _build_island_and_beacon() -> void:
	var root := Node3D.new()
	root.name = "PresentationIslandAndBeacon_PLACEHOLDER"
	root.set_meta("asset_status", "PLACEHOLDER_PRESENTATION_ONLY")
	add_child(root)

	var island := MeshInstance3D.new()
	island.name = "GraphicIslandMass_PLACEHOLDER"
	var island_mesh := SphereMesh.new()
	island_mesh.radius = 5.6
	island_mesh.height = 2.8
	island_mesh.radial_segments = 16
	island_mesh.rings = 8
	island.mesh = island_mesh
	island.position = Vector3(0.0, 0.46, -34.0)
	island.scale = Vector3(1.65, 0.58, 0.84)
	island.material_override = _make_unshaded_material(Color(0.10, 0.25, 0.25, 1.0))
	root.add_child(island)

	var shore := MeshInstance3D.new()
	shore.name = "GraphicIslandShorePlane_PLACEHOLDER"
	var shore_mesh := CylinderMesh.new()
	shore_mesh.top_radius = 1.0
	shore_mesh.bottom_radius = 1.0
	shore_mesh.height = 0.20
	shore_mesh.radial_segments = 12
	shore.mesh = shore_mesh
	shore.position = Vector3(0.0, -0.10, -34.0)
	shore.scale = Vector3(5.8, 1.0, 2.7)
	shore.material_override = _make_unshaded_material(Color(0.58, 0.42, 0.20, 1.0))
	root.add_child(shore)

	var beacon := MeshInstance3D.new()
	beacon.name = "SimpleBeacon_PLACEHOLDER"
	var beacon_mesh := CylinderMesh.new()
	beacon_mesh.top_radius = 0.18
	beacon_mesh.bottom_radius = 0.28
	beacon_mesh.height = 2.5
	beacon_mesh.radial_segments = 8
	beacon.mesh = beacon_mesh
	beacon.position = Vector3(0.78, 2.05, -34.0)
	beacon.material_override = _make_unshaded_material(Color(0.86, 0.78, 0.60, 1.0))
	root.add_child(beacon)

	var beacon_cap := MeshInstance3D.new()
	beacon_cap.name = "SimpleBeaconCap_PLACEHOLDER"
	var cap_mesh := CylinderMesh.new()
	cap_mesh.top_radius = 0.28
	cap_mesh.bottom_radius = 0.28
	cap_mesh.height = 0.18
	cap_mesh.radial_segments = 8
	beacon_cap.mesh = cap_mesh
	beacon_cap.position = Vector3(0.78, 3.36, -34.0)
	beacon_cap.material_override = _make_unshaded_material(Color(0.72, 0.30, 0.20, 1.0))
	root.add_child(beacon_cap)


func _make_unshaded_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _extract_boat_visual_only() -> void:
	var source := BOAT_SOURCE_SCRIPT.new()
	source.name = "TemporaryBoatVisualSource"
	source.visible = false
	add_child(source)
	await get_tree().process_frame
	var source_boat := source.get_node_or_null("MainCabinSailboatBlockoutV02")
	if source_boat == null:
		push_error("PresentationSlice01 could not extract the current boat visual.")
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
	camera.name = "PresentationSlice01Camera"
	camera.current = true
	camera.near = 0.05
	camera.far = 210.0
	add_child(camera)
	_set_camera_shot("overview")


func _set_camera_shot(shot_name: String) -> void:
	var shot: Dictionary = CAMERA_SHOTS[shot_name]
	camera.position = shot["position"] - BOAT_BASE_POSITION
	camera.fov = shot["fov"]
	camera.look_at(shot["target"] - BOAT_BASE_POSITION, Vector3.UP)


func _update_wave_follow() -> void:
	if boat_visual == null:
		return
	var sample := Vector2(boat_visual.position.x, boat_visual.position.z)
	var wave := _calculate_wave(sample, visual_time / WAVE_TIME_FACTOR)
	var height: float = wave["height"]
	var normal: Vector3 = wave["normal"]
	boat_visual.position.y = BOAT_BASE_POSITION.y + height
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


func _capture_all_shots() -> void:
	var output_dir := ProjectSettings.globalize_path(CAPTURE_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var shots := [
		{"name": "overview", "file": "01_overview.png"},
		{"name": "boat", "file": "02_boat.png"},
		{"name": "low_angle", "file": "03_low_angle.png"},
		{"name": "world_read", "file": "04_world_read.png"},
		{"name": "distance", "file": "05_distance.png"},
	]
	for shot in shots:
		_set_camera_shot(String(shot["name"]))
		for _frame in range(18):
			await get_tree().process_frame
		var image := get_viewport().get_texture().get_image()
		var path := output_dir.path_join(String(shot["file"]))
		var error := image.save_png(path)
		if error != OK:
			push_error("Cannot save Presentation Slice 01 screenshot: " + path)
		else:
			print("PRESENTATION_SLICE_01_SCREENSHOT=" + path)
	var draw_calls := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitives := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("PRESENTATION_SLICE_01_RENDER_INFO|draw_calls=%s|primitives=%s|gpu_ms_unavailable_in_runtime=true" % [str(draw_calls), str(primitives)])
	get_tree().quit()
