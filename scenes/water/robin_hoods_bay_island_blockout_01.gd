extends Node3D

## Robin Hood's Bay Island Blockout 01.
##
## A deliberately low-cost, isolated presentation scene. The island is made
## from simple blockout volumes so the spatial idea can be judged before any
## final environment assets exist. No Sea Trial, Journey Test, controller,
## collision, wake, timer, or formal camera logic is instantiated.

const BOAT_SOURCE_SCRIPT := preload("res://visual_prototype_3d.gd")
const STYLIZED_WATER_SHADER := preload("res://materials/water_test/stylized_water_prototype_03.gdshader")
const CAPTURE_DIR := "res://scenes/water/robin_hoods_bay_island_blockout_01_captures"

const VIEWPORT_SIZE := Vector2i(1152, 648)
const BOAT_BASE_POSITION := Vector3(0.0, 0.28, 0.0)

# Reuses the Presentation Slice 01 water direction with one restrained
# presentation-local adjustment. The same values are used by Wave Follow.
const WAVE_TIME_FACTOR := 2.7
const WAVE_AMPLITUDE_SCALE := 0.70
const WAVE_LENGTH_SCALE := 3.8
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

const CAMERA_SHOTS := {
	"overview": {"position": Vector3(-4.20, 4.05, 11.50), "target": Vector3(0.0, 1.65, -17.80), "fov": 40.0},
	"approach": {"position": Vector3(-3.80, 3.10, 8.10), "target": Vector3(0.0, 1.75, -24.80), "fov": 42.0},
	"world_read": {"position": Vector3(-6.40, 5.15, 14.20), "target": Vector3(0.0, 2.05, -27.80), "fov": 40.0},
	"boat_to_island": {"position": Vector3(-3.10, 2.35, 8.80), "target": Vector3(0.0, 1.75, -27.0), "fov": 42.0},
	"island_silhouette": {"position": Vector3(-4.80, 4.00, -18.0), "target": Vector3(0.0, 2.10, -34.0), "fov": 38.0},
}

var camera: Camera3D
var boat_visual: Node3D
var water_material: ShaderMaterial
var visual_time := 0.0


func _ready() -> void:
	_configure_viewport()
	_build_environment()
	_build_water()
	_build_island_blockout()
	await _extract_boat_visual_only()
	_build_camera()
	_update_wave_follow()

	print("ROBIN_HOODS_BAY_BLOCKOUT_01_READY|boat_visual=%s|water_material=%s|isolated=true|hud=false" % [
		str(boat_visual != null), str(water_material != null),
	])
	if OS.get_cmdline_user_args().has("--capture-robin-hoods-bay-blockout-01"):
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
	print("ROBIN_HOODS_BAY_BLOCKOUT_01_VIEWPORT|size=%s|window=%s" % [str(get_viewport().size), str(window.size)])


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "RobinHoodsBayBlockout01Environment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.11, 0.34, 0.58, 1.0)
	sky_material.sky_horizon_color = Color(0.65, 0.81, 0.87, 1.0)
	sky_material.ground_bottom_color = Color(0.07, 0.18, 0.25, 1.0)
	sky_material.ground_horizon_color = Color(0.50, 0.68, 0.75, 1.0)
	sky_material.sun_angle_max = 12.0
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.59, 0.75, 0.86, 1.0)
	environment.ambient_light_energy = 0.80
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.55, 0.72, 0.79, 1.0)
	environment.fog_light_energy = 0.50
	environment.fog_density = 0.0055
	environment.fog_sky_affect = 0.20
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)

	var light := DirectionalLight3D.new()
	light.name = "RobinHoodsBayBlockout01Sun"
	light.rotation_degrees = Vector3(-48.0, -26.0, 0.0)
	light.light_color = Color(1.0, 0.93, 0.82, 1.0)
	light.light_energy = 1.08
	light.shadow_enabled = true
	add_child(light)


func _build_water() -> void:
	var water := MeshInstance3D.new()
	water.name = "StylizedWaterForIslandBlockout"
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


func _build_island_blockout() -> void:
	var island_root := Node3D.new()
	island_root.name = "RobinHoodsBayIslandBlockout01_PLACEHOLDER"
	island_root.set_meta("asset_status", "PLACEHOLDER_BLOCKOUT_ONLY")
	add_child(island_root)

	var high_root := Node3D.new()
	high_root.name = "HighTerrace_LandmarkLayer"
	island_root.add_child(high_root)
	var middle_root := Node3D.new()
	middle_root.name = "MiddleSlope_SettlementLayer"
	island_root.add_child(middle_root)
	var shore_root := Node3D.new()
	shore_root.name = "LowerShore_DockLayer"
	island_root.add_child(shore_root)

	# Low-cost wedge masses make the climb read as a coastal slope instead of
	# four stacked cubes. They are still placeholder geometry and intentionally
	# avoid a detailed terrain asset.
	_add_slope_mass(shore_root, "LowerShore_SlopedBeach", Vector3(11.8, 1.6, 5.4), Vector3(0.0, -0.35, -34.2), 0.72, 1.25, Color(0.56, 0.40, 0.20, 1.0))
	_add_slope_mass(middle_root, "MiddleSlope_GreenMass", Vector3(9.2, 2.25, 4.0), Vector3(0.0, 0.35, -35.0), 1.20, 2.02, Color(0.16, 0.30, 0.27, 1.0))
	_add_slope_mass(high_root, "HighTerrace_WindwardRise", Vector3(5.8, 1.55, 2.5), Vector3(0.15, 1.55, -35.85), 0.78, 1.30, Color(0.22, 0.34, 0.27, 1.0))
	_add_slope_mass(high_root, "HighTerrace_CliffShadow", Vector3(3.0, 1.20, 1.7), Vector3(-1.25, 2.05, -36.35), 0.62, 1.02, Color(0.10, 0.22, 0.23, 1.0))

	# A small cluster of stepped buildings on the middle slope. The repeated
	# body/roof pair is enough to communicate a compact coastal settlement.
	_add_house(middle_root, "House_Middle_Left", Vector3(-2.45, 1.95, -33.30), Vector3(1.15, 0.78, 0.90), -5.0)
	_add_house(middle_root, "House_Middle_Center", Vector3(-0.90, 2.16, -34.15), Vector3(1.25, 0.86, 0.98), -3.0)
	_add_house(middle_root, "House_Middle_Right", Vector3(1.05, 2.05, -33.55), Vector3(1.20, 0.82, 0.92), -6.0)
	_add_house(middle_root, "House_Middle_Back", Vector3(2.20, 2.52, -35.30), Vector3(1.05, 0.78, 0.84), -9.0)
	_add_house(high_root, "House_High_Windward", Vector3(-1.35, 3.05, -36.10), Vector3(0.98, 0.72, 0.78), -4.0)

	# Dark, thin path blocks imply the vertical route from settlement to shore.
	_add_block(middle_root, "Path_To_Shore_A", Vector3(0.42, 0.08, 3.7), Vector3(-1.80, 1.22, -31.35), Vector3(-11.0, 0.0, 0.0), Color(0.26, 0.22, 0.17, 1.0))
	_add_block(middle_root, "Path_To_Shore_B", Vector3(0.38, 0.08, 2.8), Vector3(0.25, 1.54, -32.50), Vector3(-8.0, 0.0, 0.0), Color(0.26, 0.22, 0.17, 1.0))

	# Lower shore landing / dock impression. It is intentionally small and
	# functional-looking rather than a complete port asset.
	_add_block(shore_root, "Dock_Platform", Vector3(1.25, 0.18, 3.1), Vector3(0.40, 0.30, -29.95), Vector3(0.0, 0.0, 0.0), Color(0.34, 0.22, 0.13, 1.0))
	_add_block(shore_root, "Dock_End", Vector3(1.55, 0.20, 0.62), Vector3(0.40, 0.40, -28.55), Vector3(0.0, 0.0, 0.0), Color(0.43, 0.27, 0.14, 1.0))
	_add_block(shore_root, "Landing_Slope", Vector3(2.40, 0.16, 1.35), Vector3(-0.90, 0.36, -30.55), Vector3(-7.0, 0.0, 0.0), Color(0.48, 0.34, 0.19, 1.0))

	# One high landmark: a simple beacon with a warm cap, not a detailed
	# lighthouse asset.
	_add_cylinder(high_root, "HighBeacon_Tower", 0.24, 2.65, Vector3(0.95, 4.10, -36.00), Color(0.84, 0.77, 0.61, 1.0), 8)
	_add_cylinder(high_root, "HighBeacon_Cap", 0.34, 0.22, Vector3(0.95, 5.54, -36.00), Color(0.66, 0.25, 0.16, 1.0), 8)


func _add_house(parent: Node3D, name: String, position: Vector3, body_size: Vector3, rotation_x: float) -> void:
	var root := Node3D.new()
	root.name = name
	root.position = position
	root.rotation_degrees.x = rotation_x
	parent.add_child(root)
	_add_block(root, "Body", body_size, Vector3.ZERO, Vector3.ZERO, Color(0.75, 0.61, 0.43, 1.0))
	var roof := MeshInstance3D.new()
	roof.name = "PitchedRoof"
	var roof_mesh := CylinderMesh.new()
	roof_mesh.top_radius = 0.0
	roof_mesh.bottom_radius = 0.52
	roof_mesh.height = 0.38
	roof_mesh.radial_segments = 4
	roof.mesh = roof_mesh
	roof.position.y = body_size.y * 0.5 + 0.20
	roof.scale = Vector3(body_size.x / 1.15, 1.0, body_size.z / 0.90)
	roof.material_override = _make_unshaded_material(Color(0.46, 0.19, 0.12, 1.0))
	root.add_child(roof)


func _add_block(parent: Node3D, name: String, size: Vector3, position: Vector3, rotation_degrees: Vector3, color: Color) -> MeshInstance3D:
	var block := MeshInstance3D.new()
	block.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	block.mesh = mesh
	block.position = position
	block.rotation_degrees = rotation_degrees
	block.material_override = _make_unshaded_material(color)
	parent.add_child(block)
	return block


func _add_slope_mass(parent: Node3D, name: String, size: Vector3, position: Vector3, front_top: float, back_top: float, color: Color) -> MeshInstance3D:
	# A four-sided prism with a lower front edge and higher rear edge. The
	# camera looks toward negative Z, so +Z is the shore-facing/front edge.
	var slope := MeshInstance3D.new()
	slope.name = name
	var half_width := size.x * 0.5
	var half_depth := size.z * 0.5
	var vertices := PackedVector3Array([
		Vector3(-half_width, 0.0, -half_depth),
		Vector3(half_width, 0.0, -half_depth),
		Vector3(half_width, 0.0, half_depth),
		Vector3(-half_width, 0.0, half_depth),
		Vector3(-half_width, back_top, -half_depth),
		Vector3(half_width, back_top, -half_depth),
		Vector3(half_width, front_top, half_depth),
		Vector3(-half_width, front_top, half_depth),
	])
	var indices := PackedInt32Array([
		0, 2, 1, 0, 3, 2,
		4, 5, 6, 4, 6, 7,
		0, 1, 5, 0, 5, 4,
		3, 6, 2, 3, 7, 6,
		0, 4, 7, 0, 7, 3,
		1, 2, 6, 1, 6, 5,
	])
	var array_mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	slope.mesh = array_mesh
	slope.position = position
	slope.material_override = _make_unshaded_material(color)
	parent.add_child(slope)
	return slope


func _add_cylinder(parent: Node3D, name: String, radius: float, height: float, position: Vector3, color: Color, segments: int) -> MeshInstance3D:
	var cylinder := MeshInstance3D.new()
	cylinder.name = name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	cylinder.mesh = mesh
	cylinder.position = position
	cylinder.material_override = _make_unshaded_material(color)
	parent.add_child(cylinder)
	return cylinder


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
		push_error("RobinHoodsBayIslandBlockout01 could not extract the current boat visual.")
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
	camera.name = "RobinHoodsBayBlockout01Camera"
	camera.current = true
	camera.near = 0.05
	camera.far = 220.0
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
		{"name": "approach", "file": "02_approach.png"},
		{"name": "world_read", "file": "03_world_read.png"},
		{"name": "boat_to_island", "file": "04_boat_to_island.png"},
		{"name": "island_silhouette", "file": "05_island_silhouette.png"},
	]
	for shot in shots:
		_set_camera_shot(String(shot["name"]))
		for _frame in range(18):
			await get_tree().process_frame
		var image := get_viewport().get_texture().get_image()
		var path := output_dir.path_join(String(shot["file"]))
		var error := image.save_png(path)
		if error != OK:
			push_error("Cannot save Robin Hood's Bay blockout screenshot: " + path)
		else:
			print("ROBIN_HOODS_BAY_BLOCKOUT_01_SCREENSHOT=" + path)
	var draw_calls := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitives := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("ROBIN_HOODS_BAY_BLOCKOUT_01_RENDER_INFO|draw_calls=%s|primitives=%s|gpu_ms_unavailable_in_runtime=true" % [str(draw_calls), str(primitives)])
	get_tree().quit()
