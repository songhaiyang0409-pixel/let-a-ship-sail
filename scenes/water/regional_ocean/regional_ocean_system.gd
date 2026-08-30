extends Node3D

## REGIONAL OCEAN SYSTEM — isolated B+ V3 development route.
##
## One shared shader and one water mesh are used for four RegionalOceanPreset
## resources. This scene owns only a duplicated boat visual and its test
## camera; it never instantiates production sailing logic.

const SOURCE_SCENE := preload("res://scenes/water/RobinHoodsBayIslandBlockout01.tscn")
const OCEAN_SHADER := preload("res://materials/water_test/regional_ocean/regional_ocean_b_plus_v3.gdshader")
const HARBOR_CALM := preload("res://scenes/water/regional_ocean/HarborCalm.tres")
const NORTH_ATLANTIC := preload("res://scenes/water/regional_ocean/NorthAtlanticFaroe.tres")
const OPEN_OCEAN := preload("res://scenes/water/regional_ocean/OpenOcean.tres")
const SHALLOW_BAY := preload("res://scenes/water/regional_ocean/ShallowBay.tres")

const CAPTURE_ROOT := "res://scenes/water/regional_ocean_captures"
const COASTAL_CAPTURE_ROOT := "res://scenes/water/regional_ocean_captures/coastal_water"
const VIEWPORT_SIZE := Vector2i(1152, 648)
const BOAT_BASE_POSITION := Vector3(0.0, 0.28, 10.0)
const COASTAL_BOAT_START := Vector3(0.0, 0.28, 70.0)

# The coastal branch is an isolated route experiment. The proxy shoreline is
# deliberately simple; it exists to make the water conditions legible, not to
# stand in for final island art.
const COAST_FRONT_Z := -24.0
const COAST_HARBOR_ENTRY_Z := -30.0
const COAST_HARBOR_BACK_Z := -74.0
const COAST_HARBOR_HALF_WIDTH := 11.5
const COAST_HARBOR_WALL_X := 16.0
const COAST_HARBOR_WALL_HALF_WIDTH := 4.0
const COAST_HARBOR_BACK_HALF_WIDTH := 22.0
const COASTAL_OBSERVATION_FORWARD_SPEED := 5.0
const COASTAL_OBSERVATION_INBOUND_END_Z := -69.0
const COASTAL_OBSERVATION_OUTBOUND_END_Z := 10.0

# These are the locked B+ V3 structural wave values. Regional presets do not
# replace the wave function; they only apply restrained local multipliers.
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

# Route distance is measured forward from z=10. Transitions are deliberately
# broad so the boat and the water do not jump when crossing a zone.
const ROUTE_ORIGIN_Z := 10.0
const TRANSITION_01_START := 32.0
const TRANSITION_01_END := 48.0
const TRANSITION_12_START := 70.0
const TRANSITION_12_END := 86.0
const TRANSITION_23_START := 112.0
const TRANSITION_23_END := 128.0

const TEST_FORWARD_SPEED := 2.20
const TEST_REVERSE_SPEED := 0.55
const TEST_ACCELERATION := 1.10
const TEST_BRAKE := 1.55
const TEST_TURN_RATE := 0.48
const TEST_CAMERA_SMOOTHING := 5.0
const TEST_CAMERA_LOOK_SENSITIVITY := 0.0045
const TEST_CAMERA_LOOK_VERTICAL_SENSITIVITY := 0.0030
const TEST_CAMERA_LOOK_VERTICAL_MIN := -0.17
const TEST_CAMERA_LOOK_VERTICAL_MAX := 0.35

var source_instance: Node3D
var water_mesh: MeshInstance3D
var water_material: ShaderMaterial
var boat_visual: Node3D
var camera: Camera3D
var markers_root: Node3D
var coastal_world_root: Node3D
var visual_time := 0.0
var boat_yaw := 0.0
var boat_speed := 0.0
var stop_latched := false
var interactive_mode := false
var capture_mode := false
var observe_mode := false
var camera_target := Vector3.ZERO
var camera_initialized := false
var camera_look_target := 0.0
var camera_look_angle := 0.0
var camera_pitch_target := 0.0
var camera_pitch := 0.0
var forced_region := -1.0
var active_profile_override: Dictionary = {}
var current_zone := "Harbor Calm"
var last_reported_route_distance := -1.0
var coastal_test_mode := false
var canonical_reference_mode := false
var coastal_capture_mode := false
var coastal_observe_mode := false
var coastal_observation_phase := 0
var coastal_observation_elapsed := 0.0
var scale_reference_root: Node3D
var steering_input_sign := 1.0
var last_steering_probe := 99.0
var route_origin_z := ROUTE_ORIGIN_Z
var transition_01_start := TRANSITION_01_START
var transition_01_end := TRANSITION_01_END
var transition_12_start := TRANSITION_12_START
var transition_12_end := TRANSITION_12_END
var transition_23_start := TRANSITION_23_START
var transition_23_end := TRANSITION_23_END

var presets: Array[Resource] = []


func _ready() -> void:
	_configure_viewport()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var args := OS.get_cmdline_user_args()
	canonical_reference_mode = args.has("--sailing-reference")
	# Reset 03 restores the approved rear-view steering read only for its
	# isolated slice. Existing default behavior remains unchanged.
	var left_right_test_profile := args.has("--island-world-read-reset-03") or args.has("--ocean-depth-pass-01") or args.has("--ocean-depth-baseline")
	steering_input_sign = -1.0 if left_right_test_profile else 1.0
	coastal_test_mode = args.has("--coastal-water-test") or canonical_reference_mode
	coastal_capture_mode = args.has("--capture-coastal-water")
	coastal_observe_mode = args.has("--observe-coastal-water")
	interactive_mode = args.has("--regional-ocean-test") or coastal_test_mode
	capture_mode = args.has("--capture-regional-ocean")
	observe_mode = args.has("--observe-regional-ocean") or coastal_observe_mode
	if coastal_test_mode:
		_configure_coastal_route()
	else:
		presets = [HARBOR_CALM, NORTH_ATLANTIC, OPEN_OCEAN, SHALLOW_BAY]
	_build_source_copy()
	await _wait_for_source_copy()
	_build_water()
	if coastal_test_mode:
		_build_coastal_proxy_world()
		if canonical_reference_mode:
			_build_scale_references()
	_build_camera()
	_build_route_markers(args.has("--regional-ocean-markers"))
	_set_boat_pose(COASTAL_BOAT_START if coastal_test_mode else BOAT_BASE_POSITION, 0.0, 0.0)
	print("REGIONAL_OCEAN_SYSTEM_READY|isolated=true|shader=one_shared_b_plus_v3|presets=4|coastal=%s|interactive=%s|formal_project_modified=false" % [str(coastal_test_mode), str(interactive_mode)])
	if steering_input_sign < 0.0:
		print("REGIONAL_OCEAN_STEERING_PROFILE|mode=island_world_read_reset_03|A=left|D=right")
	if coastal_capture_mode:
		call_deferred("_capture_coastal_route")
	elif capture_mode:
		call_deferred("_capture_all")
	elif observe_mode:
		call_deferred("_observe_route")


func _process(delta: float) -> void:
	visual_time += delta
	if boat_visual == null:
		return
	if interactive_mode and not capture_mode and not observe_mode:
		_update_navigation(delta)
	_update_boat_wave_follow(delta)
	if not capture_mode:
		_update_camera(delta)
	if water_material != null:
		water_material.set_shader_parameter("wave_time", visual_time)
		water_material.set_shader_parameter("camera_position_world", camera.global_position if camera != null else Vector3.ZERO)
		water_material.set_shader_parameter("boat_position_world", boat_visual.global_position if boat_visual != null else Vector3.ZERO)
		water_material.set_shader_parameter("boat_forward_world", _boat_forward())
		water_material.set_shader_parameter("boat_speed", absf(boat_speed) / TEST_FORWARD_SPEED)
	if observe_mode and not capture_mode and not coastal_capture_mode:
		_update_observation_route(delta)
	_update_local_water_uniforms()
	_update_route_report()


func _build_source_copy() -> void:
	source_instance = SOURCE_SCENE.instantiate()
	source_instance.name = "RegionalOcean_SOURCE_COPY_ONLY"
	add_child(source_instance)
	source_instance.set_process(false)
	var source_water := source_instance.get_node_or_null("StylizedWaterForIslandBlockout") as Node3D
	if source_water != null:
		source_water.visible = false
	var source_island := source_instance.get_node_or_null("RobinHoodsBayIslandBlockout01_PLACEHOLDER") as Node3D
	if source_island != null:
		source_island.visible = false
	var source_camera := source_instance.get_node_or_null("RobinHoodsBayBlockout01Camera") as Camera3D
	if source_camera != null:
		source_camera.current = false
	var source_sun := source_instance.get_node_or_null("RobinHoodsBayBlockout01Sun") as DirectionalLight3D
	if source_sun != null:
		source_sun.light_energy = 1.08


func _wait_for_source_copy() -> void:
	for _frame in range(16):
		await get_tree().process_frame
	boat_visual = source_instance.get_node_or_null("MainCabinSailboatVisual_COPY_ONLY") as Node3D
	if boat_visual == null:
		push_error("RegionalOceanSystem could not find the duplicated boat visual.")


func _configure_coastal_route() -> void:
	# Reorder the same four resources for a geographically legible route:
	# exposed northern water -> open ocean -> shallow coast -> sheltered harbor.
	presets = [NORTH_ATLANTIC, OPEN_OCEAN, SHALLOW_BAY, HARBOR_CALM]
	# The existing shader measures distance as -z - route_origin_z. A negative
	# origin makes the new start at z=70 read as route distance zero while
	# leaving the old non-coastal route numerically unchanged.
	route_origin_z = -70.0
	transition_01_start = 58.0
	transition_01_end = 82.0
	transition_12_start = 94.0
	transition_12_end = 116.0
	transition_23_start = 126.0
	transition_23_end = 148.0
	current_zone = "North Atlantic / Faroe"


func _build_water() -> void:
	water_mesh = MeshInstance3D.new()
	water_mesh.name = "RegionalOcean_SHARED_WATER_MESH"
	var plane := PlaneMesh.new()
	plane.size = Vector2(260.0, 220.0)
	plane.subdivide_width = 190
	plane.subdivide_depth = 190
	water_mesh.mesh = plane
	water_material = ShaderMaterial.new()
	water_material.shader = OCEAN_SHADER
	for index in range(WAVE_PARAMS.size()):
		water_material.set_shader_parameter("wave_%d" % (index + 1), WAVE_PARAMS[index])
	water_material.set_shader_parameter("wave_time", 0.0)
	water_material.set_shader_parameter("time_factor", WAVE_TIME_FACTOR)
	water_material.set_shader_parameter("wave_amplitude_scale", WAVE_AMPLITUDE_SCALE)
	water_material.set_shader_parameter("wave_length_scale", WAVE_LENGTH_SCALE)
	water_material.set_shader_parameter("secondary_direction", Vector2(-0.36, 0.93))
	water_material.set_shader_parameter("secondary_wavelength", 7.2)
	water_material.set_shader_parameter("secondary_steepness", 0.043)
	water_material.set_shader_parameter("secondary_time_scale", 0.48)
	water_material.set_shader_parameter("secondary_phase", 3.4)
	water_material.set_shader_parameter("route_origin_z", route_origin_z)
	water_material.set_shader_parameter("transition_01_start", transition_01_start)
	water_material.set_shader_parameter("transition_01_end", transition_01_end)
	water_material.set_shader_parameter("transition_12_start", transition_12_start)
	water_material.set_shader_parameter("transition_12_end", transition_12_end)
	water_material.set_shader_parameter("transition_23_start", transition_23_start)
	water_material.set_shader_parameter("transition_23_end", transition_23_end)
	water_material.set_shader_parameter("coastal_local_enabled", coastal_test_mode)
	water_material.set_shader_parameter("coast_front_z", COAST_FRONT_Z)
	water_material.set_shader_parameter("harbor_entry_z", COAST_HARBOR_ENTRY_Z)
	water_material.set_shader_parameter("harbor_back_z", COAST_HARBOR_BACK_Z)
	water_material.set_shader_parameter("harbor_half_width", COAST_HARBOR_HALF_WIDTH)
	water_material.set_shader_parameter("harbor_wall_x", COAST_HARBOR_WALL_X)
	_set_all_region_uniforms()
	water_mesh.material_override = water_material
	add_child(water_mesh)


func _update_local_water_uniforms() -> void:
	if water_material == null:
		return
	water_material.set_shader_parameter("coastal_local_enabled", coastal_test_mode)
	water_material.set_shader_parameter("boat_position_world", boat_visual.global_position if boat_visual != null else Vector3.ZERO)
	water_material.set_shader_parameter("boat_forward_world", _boat_forward())
	water_material.set_shader_parameter("boat_speed", absf(boat_speed) / TEST_FORWARD_SPEED)


func _build_coastal_proxy_world() -> void:
	coastal_world_root = Node3D.new()
	coastal_world_root.name = "CoastalWaterProxyWorld_PLACEHOLDER"
	coastal_world_root.set_meta("asset_status", "PLACEHOLDER_COASTLINE_ONLY")
	coastal_world_root.set_meta("purpose", "regional_water_behavior_test")
	add_child(coastal_world_root)

	var land_color := _make_proxy_material(Color(0.20, 0.29, 0.26, 1.0))
	var land_shadow := _make_proxy_material(Color(0.12, 0.21, 0.22, 1.0))
	var sand_color := _make_proxy_material(Color(0.48, 0.39, 0.25, 1.0))
	var pier_color := _make_proxy_material(Color(0.31, 0.23, 0.16, 1.0))

	# Two outer headlands leave a central opening. They are broad, low proxy
	# masses so the water/land boundary reads without pretending to be final art.
	_add_proxy_slope("OuterHeadland_L", Vector3(44.0, 2.5, 28.0), Vector3(-34.0, 0.0, -28.0), 0.35, 2.15, land_color)
	_add_proxy_slope("OuterHeadland_R", Vector3(44.0, 2.5, 28.0), Vector3(34.0, 0.0, -28.0), 0.35, 2.15, land_color)
	_add_proxy_slope("HeadlandSlope_L", Vector3(28.0, 2.0, 18.0), Vector3(-30.0, 2.15, -38.0), 0.45, 1.65, land_shadow)
	_add_proxy_slope("HeadlandSlope_R", Vector3(28.0, 2.0, 18.0), Vector3(30.0, 2.15, -38.0), 0.45, 1.65, land_shadow)

	# Narrow harbor walls create a readable sheltered corridor from the opening
	# toward the back land. The channel itself remains open for the boat.
	_add_proxy_box("HarborWall_L", Vector3(8.0, 3.2, 46.0), Vector3(-16.0, 1.55, -51.0), land_color)
	_add_proxy_box("HarborWall_R", Vector3(8.0, 3.2, 46.0), Vector3(16.0, 1.55, -51.0), land_color)
	_add_proxy_box("HarborBackLand", Vector3(44.0, 3.0, 10.0), Vector3(0.0, 1.45, -78.0), land_shadow)

	# A single low pier is enough to give the sheltered water a scale cue.
	_add_proxy_box("HarborPier_L", Vector3(1.3, 0.35, 14.0), Vector3(-7.5, 0.28, -49.0), pier_color)
	_add_proxy_box("HarborPier_R", Vector3(1.3, 0.35, 14.0), Vector3(7.5, 0.28, -57.0), pier_color)

	# Muted shoreline strips are intentionally sparse: they make contact feel
	# designed while the shader handles the continuous local water response.
	_add_proxy_box("OuterShoreStrip_L", Vector3(44.0, 0.12, 2.2), Vector3(-34.0, 0.10, -24.8), sand_color)
	_add_proxy_box("OuterShoreStrip_R", Vector3(44.0, 0.12, 2.2), Vector3(34.0, 0.10, -24.8), sand_color)
	_add_proxy_box("HarborShoreStrip_L", Vector3(1.4, 0.12, 44.0), Vector3(-11.6, 0.11, -51.0), sand_color)
	_add_proxy_box("HarborShoreStrip_R", Vector3(1.4, 0.12, 44.0), Vector3(11.6, 0.11, -51.0), sand_color)

	# One simple high marker provides a near-shore depth cue without turning
	# this into an island-art pass.
	_add_proxy_cylinder("CoastalBeacon", 0.35, 4.0, Vector3(-27.0, 4.0, -39.0), sand_color)
	_add_proxy_cylinder("CoastalBeaconCap", 0.50, 0.35, Vector3(-27.0, 6.18, -39.0), pier_color)


func _build_scale_references() -> void:
	scale_reference_root = Node3D.new()
	scale_reference_root.name = "SailingReferenceScaleReferences"
	scale_reference_root.set_meta("asset_status", "DEVELOPMENT_REFERENCE_ONLY")
	scale_reference_root.set_meta("world_scale", "1 Godot unit approximately 1 meter")
	add_child(scale_reference_root)

	var cube_material := _make_proxy_material(Color(0.78, 0.68, 0.34, 1.0))
	var marker_material := _make_proxy_material(Color(0.52, 0.66, 0.70, 1.0))
	var guide_material := _make_proxy_material(Color(0.86, 0.54, 0.28, 1.0))
	_add_scale_box("OneMeterCube_REFERENCE", Vector3.ONE, Vector3(12.0, 0.5, 64.0), cube_material)
	_add_scale_box("HumanHeight_1m80_REFERENCE", Vector3(0.16, 1.8, 0.16), Vector3(14.0, 0.9, 64.0), marker_material)
	_add_scale_box("Height_3m_REFERENCE", Vector3(0.16, 3.0, 0.16), Vector3(16.0, 1.5, 64.0), marker_material)
	_add_scale_box("Height_10m_REFERENCE", Vector3(0.16, 10.0, 0.16), Vector3(18.0, 5.0, 64.0), marker_material)
	_add_scale_box("PlayerBoatHullLength_6m_GUIDE", Vector3(6.0, 0.08, 0.08), Vector3(15.0, 0.04, 60.0), guide_material)


func _add_scale_box(node_name: String, size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.material_override = material
	scale_reference_root.add_child(mesh_instance)
	return mesh_instance


func _add_proxy_box(node_name: String, size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.material_override = material
	coastal_world_root.add_child(mesh_instance)
	return mesh_instance


func _add_proxy_slope(node_name: String, size: Vector3, position: Vector3, front_top: float, back_top: float, material: Material) -> MeshInstance3D:
	var slope := MeshInstance3D.new()
	slope.name = node_name
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
	slope.material_override = material
	coastal_world_root.add_child(slope)
	return slope


func _add_proxy_cylinder(node_name: String, radius: float, height: float, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.material_override = material
	coastal_world_root.add_child(mesh_instance)
	return mesh_instance


func _make_proxy_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.roughness = 1.0
	return material


func _set_all_region_uniforms() -> void:
	for index in range(presets.size()):
		_set_region_uniforms(index, _profile_dict(presets[index]))


func _set_region_uniforms(index: int, profile: Dictionary) -> void:
	if water_material == null:
		return
	var prefix := "region%d_" % index
	water_material.set_shader_parameter(prefix + "trough_color", _color3(profile["trough_color"]))
	water_material.set_shader_parameter(prefix + "water_color", _color3(profile["water_color"]))
	water_material.set_shader_parameter(prefix + "crest_color", _color3(profile["crest_color"]))
	water_material.set_shader_parameter(prefix + "atmospheric_color", _color3(profile["atmospheric_color"]))
	water_material.set_shader_parameter(prefix + "tuning", Vector4(
		float(profile["amplitude_multiplier"]),
		float(profile["secondary_strength"]),
		float(profile["surface_contrast"]),
		float(profile["horizon_response"]),
	))
	water_material.set_shader_parameter(prefix + "surface", Vector4(
		float(profile["saturation"]),
		float(profile["specular_strength"]),
		float(profile["fresnel_strength"]),
		0.91,
	))


func _color3(value: Variant) -> Vector3:
	var color: Color = value
	return Vector3(color.r, color.g, color.b)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "RegionalOceanTestCamera"
	camera.current = true
	camera.near = 0.05
	camera.far = 260.0
	camera.fov = 40.0
	add_child(camera)
	_update_camera(0.0)


func _build_route_markers(show_markers: bool) -> void:
	markers_root = Node3D.new()
	markers_root.name = "RegionalOceanRouteMarkers_TEST_ONLY"
	markers_root.visible = show_markers
	add_child(markers_root)
	for item in [
		{"name": "HarborCalm_to_NorthAtlantic", "z": -30.0, "color": Color(0.75, 0.66, 0.38)},
		{"name": "NorthAtlantic_to_OpenOcean", "z": -70.0, "color": Color(0.36, 0.52, 0.60)},
		{"name": "OpenOcean_to_ShallowBay", "z": -110.0, "color": Color(0.50, 0.68, 0.62)},
	]:
		for side in [-1.0, 1.0]:
			var marker := MeshInstance3D.new()
			marker.name = String(item["name"]) + ("_L" if side < 0.0 else "_R")
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.045
			mesh.bottom_radius = 0.07
			mesh.height = 0.75
			marker.mesh = mesh
			marker.position = Vector3(7.0 * side, 0.38, float(item["z"]))
			var material := StandardMaterial3D.new()
			material.albedo_color = item["color"]
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			marker.material_override = material
			markers_root.add_child(marker)


func _update_navigation(delta: float) -> void:
	if boat_visual == null:
		return
	var previous_position := boat_visual.position
	var steer := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		steer -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		steer += 1.0
	if steering_input_sign < 0.0 and absf(steer - last_steering_probe) > 0.1:
		print("RESET_03_INPUT_PROBE|steer_input=%+.0f|yaw_sign=%+.0f|meaning=%s" % [steer, steering_input_sign, "A_left_D_right" if steering_input_sign < 0.0 else "default"])
		last_steering_probe = steer
	boat_yaw = wrapf(boat_yaw + steer * steering_input_sign * TEST_TURN_RATE * delta, -PI, PI)
	boat_visual.rotation.y = boat_yaw
	var propulsion := 0.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		propulsion += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		propulsion -= 1.0
	if stop_latched:
		propulsion = 0.0
	var target_speed := 0.0
	if propulsion > 0.0:
		target_speed = TEST_FORWARD_SPEED
	elif propulsion < 0.0:
		target_speed = -TEST_REVERSE_SPEED if absf(boat_speed) <= 0.01 else 0.0
	var response := TEST_ACCELERATION if absf(target_speed) > absf(boat_speed) else TEST_BRAKE
	boat_speed = move_toward(boat_speed, target_speed, response * delta)
	if absf(boat_speed) < 0.008 and absf(target_speed) < 0.01:
		boat_speed = 0.0
	boat_visual.position += _boat_forward() * boat_speed * delta
	if coastal_test_mode and _coastal_position_is_land(boat_visual.position):
		boat_visual.position = previous_position
		print("COASTAL_PROXY_CONTACT|position=%s|speed=%.2f" % [str(boat_visual.position), boat_speed])


func _update_observation_route(delta: float) -> void:
	if coastal_test_mode:
		_update_coastal_observation(delta)
		return
	# Automated visual pass: drive straight through all four zones so the
	# transition log and boat response can be checked without keyboard input.
	boat_yaw = 0.0
	boat_speed = TEST_FORWARD_SPEED
	boat_visual.rotation.y = boat_yaw
	boat_visual.position += _boat_forward() * boat_speed * delta
	if boat_visual.position.z < -140.0:
		boat_speed = 0.0
		print("REGIONAL_OCEAN_OBSERVATION_END|route_distance=%.2f|zone=%s" % [_route_distance(), current_zone])
		get_tree().quit()


func _update_coastal_observation(delta: float) -> void:
	# This is an evidence run, not a gameplay shortcut: it moves the same boat
	# through the same world-space route and then drives back out of the harbor.
	coastal_observation_elapsed += delta
	boat_yaw = 0.0 if coastal_observation_phase == 0 else PI
	boat_speed = COASTAL_OBSERVATION_FORWARD_SPEED
	boat_visual.rotation.y = boat_yaw
	boat_visual.position += _boat_forward() * boat_speed * delta
	if coastal_observation_phase == 0 and boat_visual.position.z <= COASTAL_OBSERVATION_INBOUND_END_Z:
		coastal_observation_phase = 1
		print("COASTAL_OBSERVATION_TURNAROUND|inside_harbor=true|z=%.2f|route_distance=%.2f" % [boat_visual.position.z, _route_distance()])
	elif coastal_observation_phase == 1 and boat_visual.position.z >= COASTAL_OBSERVATION_OUTBOUND_END_Z:
		boat_speed = 0.0
		print("COASTAL_OBSERVATION_END|seconds=%.1f|route_distance=%.2f|zone=%s|returned_to_open_water=true" % [coastal_observation_elapsed, _route_distance(), current_zone])
		get_tree().quit()


func _boat_forward() -> Vector3:
	return Vector3(0.0, 0.0, -1.0).rotated(Vector3.UP, boat_yaw).normalized()


func _get_route_profile(position_z: float) -> Dictionary:
	if not active_profile_override.is_empty():
		return active_profile_override
	var distance: float = maxf(-position_z - route_origin_z, 0.0)
	var t01 := smoothstep(transition_01_start, transition_01_end, distance)
	var t12 := smoothstep(transition_12_start, transition_12_end, distance)
	var t23 := smoothstep(transition_23_start, transition_23_end, distance)
	var blended := _blend_profile(_profile_dict(presets[0]), _profile_dict(presets[1]), t01)
	blended = _blend_profile(blended, _profile_dict(presets[2]), t12)
	blended = _blend_profile(blended, _profile_dict(presets[3]), t23)
	return _apply_local_conditions(blended, Vector2(boat_visual.position.x, position_z)) if coastal_test_mode else blended


func _profile_dict(profile: Resource) -> Dictionary:
	return {
		"preset_id": profile.get("preset_id"),
		"display_name": profile.get("display_name"),
		"trough_color": profile.get("trough_color"),
		"water_color": profile.get("water_color"),
		"crest_color": profile.get("crest_color"),
		"atmospheric_color": profile.get("atmospheric_color"),
		"amplitude_multiplier": profile.get("amplitude_multiplier"),
		"secondary_strength": profile.get("secondary_strength"),
		"surface_contrast": profile.get("surface_contrast"),
		"saturation": profile.get("saturation"),
		"horizon_response": profile.get("horizon_response"),
		"specular_strength": profile.get("specular_strength"),
		"fresnel_strength": profile.get("fresnel_strength"),
	}


func _blend_profile(a: Dictionary, b: Dictionary, amount: float) -> Dictionary:
	var result := a.duplicate()
	for key in ["trough_color", "water_color", "crest_color", "atmospheric_color"]:
		result[key] = (a[key] as Color).lerp(b[key] as Color, amount)
	for key in ["amplitude_multiplier", "secondary_strength", "surface_contrast", "saturation", "horizon_response", "specular_strength", "fresnel_strength"]:
		result[key] = lerpf(float(a[key]), float(b[key]), amount)
	return result


func _apply_local_conditions(profile: Dictionary, pos: Vector2) -> Dictionary:
	var conditions := _get_local_conditions(pos)
	var result := profile.duplicate()
	# Local modifiers only touch the wave energy they need. Regional color
	# identity remains owned by the four presets above.
	result["amplitude_multiplier"] = float(result["amplitude_multiplier"]) * (1.0 - float(conditions["coast_mask"]) * 0.14 - float(conditions["harbor_mask"]) * 0.30)
	result["secondary_strength"] = float(result["secondary_strength"]) * (1.0 - float(conditions["coast_mask"]) * 0.24 - float(conditions["harbor_mask"]) * 0.44)
	result["surface_contrast"] = float(result["surface_contrast"]) * (1.0 - float(conditions["coast_mask"]) * 0.14 - float(conditions["harbor_mask"]) * 0.24)
	result["horizon_response"] = float(result["horizon_response"]) + float(conditions["harbor_mask"]) * 0.012
	return result


func _get_local_conditions(pos: Vector2) -> Dictionary:
	if not coastal_test_mode:
		return {"coast_mask": 0.0, "harbor_mask": 0.0, "shoreline_mask": 0.0}
	var route_distance := maxf(-pos.y - route_origin_z, 0.0)
	var coast_mask := smoothstep(62.0, 98.0, route_distance)
	var harbor_z := smoothstep(100.0, 114.0, route_distance) * (1.0 - smoothstep(138.0, 152.0, route_distance))
	var harbor_x := 1.0 - smoothstep(COAST_HARBOR_HALF_WIDTH, COAST_HARBOR_WALL_X, absf(pos.x))
	var harbor_mask := clampf(harbor_z * harbor_x, 0.0, 1.0)
	var outer_shore := smoothstep(COAST_HARBOR_HALF_WIDTH, COAST_HARBOR_WALL_X + 4.0, absf(pos.x))
	var shoreline_front := (1.0 - smoothstep(0.0, 3.0, absf(pos.y - COAST_FRONT_Z))) * outer_shore
	var shoreline_walls := (1.0 - smoothstep(0.0, 2.5, absf(absf(pos.x) - COAST_HARBOR_WALL_X + COAST_HARBOR_WALL_HALF_WIDTH))) * harbor_z
	return {
		"coast_mask": coast_mask,
		"harbor_mask": harbor_mask,
		"shoreline_mask": clampf(shoreline_front + shoreline_walls, 0.0, 1.0),
	}


func _coastal_position_is_land(position: Vector3) -> bool:
	if not coastal_test_mode:
		return false
	var x := absf(position.x)
	var z := position.z
	# Central channel is open between the two proxy harbor walls.
	if z <= COAST_HARBOR_ENTRY_Z and z >= COAST_HARBOR_BACK_Z and x < COAST_HARBOR_HALF_WIDTH - 1.0:
		return false
	# The outer headlands close the coast outside the harbor opening.
	if z < COAST_FRONT_Z and x > COAST_HARBOR_HALF_WIDTH - 1.0:
		return true
	# Back land closes the end of the harbor.
	if z < COAST_HARBOR_BACK_Z:
		return true
	return false


func _update_boat_wave_follow(delta: float) -> void:
	if boat_visual == null:
		return
	var profile := _get_route_profile(boat_visual.position.z)
	var sample := _calculate_wave(Vector2(boat_visual.position.x, boat_visual.position.z), visual_time / WAVE_TIME_FACTOR, profile)
	var target_y := BOAT_BASE_POSITION.y + float(sample["height"]) * 0.50
	boat_visual.position.y = lerpf(boat_visual.position.y, target_y, clampf(delta * 8.0, 0.0, 1.0))
	var water_normal: Vector3 = sample["normal"]
	var heading := _boat_forward()
	var lateral := Vector3(-heading.z, 0.0, heading.x)
	var forward_slope := clampf(water_normal.dot(heading), -0.6, 0.6)
	var lateral_slope := clampf(water_normal.dot(lateral), -0.6, 0.6)
	var target_pitch := forward_slope * 0.25
	var target_roll := lateral_slope * 0.18
	var target_basis := Basis(Vector3.UP, boat_yaw)
	target_basis = target_basis.rotated(target_basis.x, target_pitch)
	target_basis = target_basis.rotated(target_basis.z, target_roll)
	boat_visual.basis = boat_visual.basis.slerp(target_basis, clampf(delta * 7.0, 0.0, 1.0))
	if water_material != null:
		water_material.set_shader_parameter("boat_position_world", boat_visual.global_position)
		water_material.set_shader_parameter("boat_forward_world", heading)
		water_material.set_shader_parameter("boat_speed", absf(boat_speed) / TEST_FORWARD_SPEED)


func _calculate_wave(pos: Vector2, time: float, profile: Dictionary) -> Dictionary:
	var displacement := Vector3.ZERO
	var normal := Vector3.UP
	var amplitude_multiplier := float(profile["amplitude_multiplier"])
	for index in ACTIVE_WAVE_INDICES:
		var result := _calculate_gerstner_wave(WAVE_PARAMS[index], pos, time, 0.0, WAVE_AMPLITUDE_SCALE, WAVE_LENGTH_SCALE, amplitude_multiplier)
		displacement += result["displacement"]
		normal += result["normal"]
	var secondary_params := Vector4(-0.36, 0.93, 0.043 / WAVE_AMPLITUDE_SCALE, 7.2 / WAVE_LENGTH_SCALE)
	var secondary := _calculate_gerstner_wave(secondary_params, pos, time * 0.48, 3.4, 1.0, WAVE_LENGTH_SCALE, amplitude_multiplier)
	displacement += secondary["displacement"] * float(profile["secondary_strength"])
	normal += secondary["normal"] * float(profile["secondary_strength"]) * 0.55
	return {"height": displacement.y, "normal": normal.normalized(), "displacement": displacement}


func _calculate_gerstner_wave(params: Vector4, pos: Vector2, time: float, phase_offset: float, amplitude_scale: float, length_scale: float, regional_amplitude: float) -> Dictionary:
	var steepness := params.z * (1.0 + 0.5 * sin(time + pos.length() * 0.1)) * amplitude_scale * regional_amplitude
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


func _update_camera(delta: float) -> void:
	if camera == null or boat_visual == null:
		return
	camera_look_angle = wrapf(lerp_angle(camera_look_angle, camera_look_target, clampf(delta * TEST_CAMERA_SMOOTHING, 0.0, 1.0)), -PI, PI)
	camera_pitch = lerpf(camera_pitch, camera_pitch_target, clampf(delta * TEST_CAMERA_SMOOTHING, 0.0, 1.0))
	var rig_yaw := boat_yaw + camera_look_angle
	var desired_position := boat_visual.position + _rotate_camera_orbit(Vector3(-4.20, 4.05, 11.50), rig_yaw, camera_pitch)
	var desired_target := boat_visual.position + _rotate_camera_orbit(Vector3(0.0, 1.65, -17.80), rig_yaw, camera_pitch)
	if not camera_initialized:
		camera.position = desired_position
		camera_target = desired_target
		camera_initialized = true
	else:
		camera.position = camera.position.lerp(desired_position, clampf(delta * TEST_CAMERA_SMOOTHING, 0.0, 1.0))
		camera_target = camera_target.lerp(desired_target, clampf(delta * TEST_CAMERA_SMOOTHING, 0.0, 1.0))
	camera.look_at(camera_target, Vector3.UP)


func _rotate_camera_orbit(value: Vector3, yaw: float, pitch: float) -> Vector3:
	var yawed := value.rotated(Vector3.UP, yaw)
	var right_axis := Vector3.RIGHT.rotated(Vector3.UP, yaw)
	return yawed.rotated(right_axis, pitch)


func _route_distance() -> float:
	return maxf(-boat_visual.position.z - route_origin_z, 0.0) if boat_visual != null else 0.0


func _route_zone_name(distance: float) -> String:
	if coastal_test_mode:
		if distance < transition_01_start:
			return "North Atlantic / Faroe"
		if distance < transition_12_start:
			return "Open Ocean / Coastal Approach"
		if distance < transition_23_start:
			return "Shallow Coastal Water"
		return "Sheltered Harbor"
	if distance < transition_01_start:
		return "Harbor Calm"
	if distance < transition_12_start:
		return "North Atlantic / Faroe"
	if distance < transition_23_start:
		return "Open Ocean"
	return "Shallow Bay"


func _update_route_report() -> void:
	var distance := _route_distance()
	var zone := _route_zone_name(distance)
	if zone != current_zone:
		current_zone = zone
		print("REGIONAL_OCEAN_ZONE|name=%s|route_distance=%.2f|boat_speed=%.2f" % [zone, distance, boat_speed])
	if last_reported_route_distance < 0.0 or floor(distance / 10.0) > floor(last_reported_route_distance / 10.0):
		last_reported_route_distance = distance
		print("REGIONAL_OCEAN_ROUTE_SAMPLE|distance=%.2f|zone=%s|boat_speed=%.2f" % [distance, zone, boat_speed])


func _unhandled_input(event: InputEvent) -> void:
	if not interactive_mode or capture_mode or observe_mode:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			if absf(boat_speed) > 0.01 or stop_latched:
				stop_latched = true
			else:
				stop_latched = false
				boat_speed = 0.0
		if event.keycode == KEY_BACKSPACE:
			_set_boat_pose(COASTAL_BOAT_START if coastal_test_mode else BOAT_BASE_POSITION, 0.0, 0.0)
			stop_latched = false


func _input(event: InputEvent) -> void:
	if not interactive_mode or capture_mode or observe_mode:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		camera_look_target = wrapf(camera_look_target - motion.relative.x * TEST_CAMERA_LOOK_SENSITIVITY, -PI, PI)
		camera_pitch_target = clampf(camera_pitch_target - motion.relative.y * TEST_CAMERA_LOOK_VERTICAL_SENSITIVITY, TEST_CAMERA_LOOK_VERTICAL_MIN, TEST_CAMERA_LOOK_VERTICAL_MAX)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		camera_look_target = 0.0
		camera_pitch_target = 0.0


func _set_boat_pose(position: Vector3, yaw_degrees: float, speed: float) -> void:
	boat_visual.position = position
	boat_yaw = deg_to_rad(yaw_degrees)
	boat_speed = speed
	boat_visual.rotation = Vector3(0.0, boat_yaw, 0.0)
	boat_visual.set_meta("capture_speed", absf(speed) / TEST_FORWARD_SPEED)


func _configure_viewport() -> void:
	var window := get_window()
	window.size = VIEWPORT_SIZE
	window.content_scale_size = VIEWPORT_SIZE
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED


func _capture_all() -> void:
	var root := ProjectSettings.globalize_path(CAPTURE_ROOT)
	DirAccess.make_dir_recursive_absolute(root)
	for index in range(presets.size()):
		await _capture_preset(index, root.path_join(String(presets[index].get("preset_id"))))
	await _capture_route(root.path_join("route"))
	await _capture_iterations(root.path_join("iterations"))
	_restore_route_mode()
	var draw_calls := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitives := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("REGIONAL_OCEAN_RENDER_INFO|draw_calls=%s|primitives=%s|gpu_ms_unavailable_in_runtime=true" % [str(draw_calls), str(primitives)])
	get_tree().quit()


func _capture_coastal_route() -> void:
	# Small, useful evidence set for the continuous route. All images use the
	# actual test camera and the same boat visual; no debug UI is added.
	var root := ProjectSettings.globalize_path(COASTAL_CAPTURE_ROOT)
	DirAccess.make_dir_recursive_absolute(root)
	var points := [
		{"file": "01_open_ocean.png", "position": COASTAL_BOAT_START, "yaw": 0.0, "label": "OPEN_OCEAN"},
		{"file": "02_coastal_approach.png", "position": Vector3(0.0, 0.28, 2.0), "yaw": 0.0, "label": "COASTAL_APPROACH"},
		{"file": "03_shallow_shore.png", "position": Vector3(0.0, 0.28, -23.0), "yaw": 0.0, "label": "SHALLOW_SHORE"},
		{"file": "04_harbor_entrance.png", "position": Vector3(0.0, 0.28, -31.0), "yaw": 0.0, "label": "HARBOR_ENTRANCE"},
		{"file": "05_inside_harbor.png", "position": Vector3(0.0, 0.28, -56.0), "yaw": 0.0, "label": "INSIDE_HARBOR"},
		{"file": "06_return_open_ocean.png", "position": Vector3(0.0, 0.28, 45.0), "yaw": 0.0, "label": "RETURN_OPEN_OCEAN"},
	]
	for point in points:
		_set_boat_pose(point["position"], float(point["yaw"]), 0.0)
		_set_camera_view("overview")
		await _settle_frames(24)
		_save_capture(root.path_join(String(point["file"])), "COASTAL_WATER_%s" % String(point["label"]))
	_restore_route_mode()
	var draw_calls := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitives := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("COASTAL_WATER_RENDER_INFO|draw_calls=%s|primitives=%s|gpu_ms_unavailable_in_runtime=true" % [str(draw_calls), str(primitives)])
	get_tree().quit()


func _capture_preset(index: int, output_dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	_set_forced_profile(index, _profile_dict(presets[index]))
	_set_boat_pose(BOAT_BASE_POSITION, 0.0, 0.75)
	_set_camera_view("overview")
	await _settle_frames(24)
	_save_capture(output_dir.path_join("01_overview.png"), "REGIONAL_OCEAN_%s_OVERVIEW" % String(presets[index].get("display_name")))
	_set_camera_view("boat")
	await _settle_frames(12)
	_save_capture(output_dir.path_join("02_boat.png"), "REGIONAL_OCEAN_%s_BOAT" % String(presets[index].get("display_name")))
	_set_camera_view("low_angle")
	await _settle_frames(12)
	_save_capture(output_dir.path_join("03_world.png"), "REGIONAL_OCEAN_%s_LOW_ANGLE" % String(presets[index].get("display_name")))


func _capture_route(output_dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	_restore_route_mode()
	var points := [
		{"file": "00_harbor_calm.png", "position": Vector3(0.0, 0.28, 10.0)},
		{"file": "01_harbor_to_atlantic.png", "position": Vector3(0.0, 0.28, -24.0)},
		{"file": "02_north_atlantic.png", "position": Vector3(0.0, 0.28, -55.0)},
		{"file": "03_open_ocean.png", "position": Vector3(0.0, 0.28, -96.0)},
		{"file": "04_shallow_bay.png", "position": Vector3(0.0, 0.28, -138.0)},
	]
	for point in points:
		_set_boat_pose(point["position"], 0.0, 0.75)
		_set_camera_view("overview")
		await _settle_frames(18)
		_save_capture(output_dir.path_join(String(point["file"])), "REGIONAL_OCEAN_ROUTE_%s" % point["file"])


func _capture_iterations(output_dir: String) -> void:
	for index in range(presets.size()):
		var preset_dir := output_dir.path_join(String(presets[index].get("preset_id")))
		DirAccess.make_dir_recursive_absolute(preset_dir)
		for version in [1, 2, 3]:
			var variant := _iteration_variant(_profile_dict(presets[index]), version)
			_set_forced_profile(index, variant)
			_set_boat_pose(BOAT_BASE_POSITION, 0.0, 0.75)
			_set_camera_view("overview")
			await _settle_frames(18)
			_save_capture(preset_dir.path_join("V%d_overview.png" % version), "REGIONAL_OCEAN_%s_V%d" % [String(presets[index].get("display_name")), version])


func _iteration_variant(base: Dictionary, version: int) -> Dictionary:
	var variant := base.duplicate()
	if version == 1:
		variant["secondary_strength"] = min(float(base["secondary_strength"]) + 0.12, 1.10)
		variant["surface_contrast"] = min(float(base["surface_contrast"]) + 0.14, 1.0)
		variant["saturation"] = min(float(base["saturation"]) + 0.08, 1.10)
	elif version == 2:
		variant["secondary_strength"] = min(float(base["secondary_strength"]) + 0.05, 1.10)
		variant["surface_contrast"] = min(float(base["surface_contrast"]) + 0.05, 1.0)
		variant["saturation"] = min(float(base["saturation"]) + 0.02, 1.10)
	return variant


func _set_forced_profile(index: int, profile: Dictionary) -> void:
	forced_region = float(index)
	active_profile_override = profile
	water_material.set_shader_parameter("forced_region", forced_region)
	_set_region_uniforms(index, profile)


func _restore_route_mode() -> void:
	forced_region = -1.0
	active_profile_override = {}
	water_material.set_shader_parameter("forced_region", forced_region)
	_set_all_region_uniforms()


func _set_camera_view(view_name: String) -> void:
	if boat_visual == null or camera == null:
		return
	var offset := Vector3(-4.20, 4.05, 11.50)
	var target_offset := Vector3(0.0, 1.65, -17.80)
	var fov := 40.0
	if view_name == "boat":
		offset = Vector3(-2.80, 2.20, 6.20)
		target_offset = Vector3(0.0, 0.70, -1.50)
		fov = 44.0
	elif view_name == "low_angle":
		offset = Vector3(-3.80, 1.40, 7.40)
		target_offset = Vector3(0.0, 0.40, -8.50)
		fov = 42.0
	camera.position = boat_visual.position + offset
	camera.fov = fov
	camera.look_at(boat_visual.position + target_offset, Vector3.UP)
	camera_target = boat_visual.position + target_offset
	camera_initialized = true


func _settle_frames(frame_count: int) -> void:
	for _frame in range(frame_count):
		await get_tree().process_frame


func _save_capture(path: String, label: String) -> void:
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	if error != OK:
		push_error("Cannot save regional ocean capture: " + path)
	else:
		print(label + "=" + path)


func _observe_route() -> void:
	if coastal_test_mode:
		boat_visual.position = COASTAL_BOAT_START
		coastal_observation_phase = 0
		coastal_observation_elapsed = 0.0
		boat_yaw = 0.0
		boat_speed = COASTAL_OBSERVATION_FORWARD_SPEED
		print("COASTAL_OBSERVATION_BEGIN|seconds_target=%.1f|route=open_ocean>coastal_approach>shallow>harbor>open_ocean" % ((COASTAL_BOAT_START.z - COASTAL_OBSERVATION_INBOUND_END_Z + COASTAL_OBSERVATION_OUTBOUND_END_Z - COASTAL_BOAT_START.z) / COASTAL_OBSERVATION_FORWARD_SPEED))
		return
	boat_visual.position = BOAT_BASE_POSITION
	boat_speed = TEST_FORWARD_SPEED
	print("REGIONAL_OCEAN_OBSERVATION_BEGIN|seconds_target=%.1f|route=HarborCalm>NorthAtlantic>OpenOcean>ShallowBay" % (130.0 / TEST_FORWARD_SPEED))
