extends Node3D

## Terra Showcase: isolated, landscape playable North Atlantic sailing slice.
## Reuses RegionalOceanSystem for all sailing, camera, B+ V3 waves, coupling,
## and wake. This script only builds the temporary world around that system.

const VIEWPORT_SIZE := Vector2i(1152, 648)
const CAPTURE_ROOT := "res://scenes/staging/terra_playable_north_atlantic_showcase_slice_01_captures"
const START_Z := 150.0
const END_Z := -193.0
const ROUTE_M := START_Z - END_Z
const NORMAL_SPEED := 2.2
const TEST_SPEED := 5.0
const WORLD_X := 92.0
const WORLD_FRONT := 235.0
const WORLD_BACK := -240.0
const WAKE_A_SCRIPT := preload("res://scenes/staging/terra_playable_north_atlantic_showcase_slice_01/terra_showcase_wake_candidate_a.gd")
const WAKE_B_SCRIPT := preload("res://scenes/staging/terra_playable_north_atlantic_showcase_slice_01/terra_showcase_wake_candidate_b.gd")
const DEFAULT_WAKE_CANDIDATE := "b"

var canonical: Node3D
var ocean: Node3D
var visual_root: Node3D
var collision_root: Node3D
var last_safe_position := Vector3.ZERO
var capture_mode := false
var harness_mode := false
var qa_mode := false
var layout_variant := "b"
var capture_root_override := ""
var wake_candidate: String = DEFAULT_WAKE_CANDIDATE
var contact_latched := false


func _ready() -> void:
	_configure_viewport()
	var args := OS.get_cmdline_user_args()
	capture_mode = args.has("--capture-terra-showcase-slice-01")
	qa_mode = args.has("--terra-showcase-qa")
	harness_mode = capture_mode or qa_mode or args.has("--terra-showcase-auto-route")
	layout_variant = "b"
	wake_candidate = "b" if args.has("--terra-wake-b") else DEFAULT_WAKE_CANDIDATE
	capture_root_override = "res://scenes/staging/terra_playable_north_atlantic_showcase_slice_01_captures/final_%s" % wake_candidate
	canonical = get_node_or_null("CanonicalSailingReference") as Node3D
	if canonical == null:
		push_error("Missing canonical sailing reference.")
		return
	await get_tree().process_frame
	ocean = canonical.get_node_or_null("RegionalOceanSystem") as Node3D
	if ocean == null:
		push_error("Missing RegionalOceanSystem.")
		return
	for _wait in range(40):
		if ocean.get('boat_visual') != null:
			break
		await get_tree().process_frame
	_configure_viewport()
	_configure_route()
	_hide_old_proxies()
	_build_world()
	await get_tree().process_frame
	ocean.call("_set_boat_pose", Vector3(0.0, 0.28, START_Z), 0.0, 0.0)
	last_safe_position = _boat_position()
	if not qa_mode:
		_build_showcase_wake()
	await get_tree().process_frame
	if not harness_mode:
		ocean.set("interactive_mode", true)
		ocean.set("steering_input_sign", -1.0)
		ocean.set("capture_mode", false)
		ocean.set("observe_mode", false)
	print("TERRA_SHOWCASE_SLICE_01_READY|layout=%s|route_m=%d|normal_seconds=%.1f|test_seconds=%.1f|wake_candidate=%s|landscape=true|formal_project_modified=false" % [layout_variant, ROUTE_M, ROUTE_M / NORMAL_SPEED, ROUTE_M / TEST_SPEED, wake_candidate])
	if harness_mode:
		ocean.set("interactive_mode", false)
		ocean.set("capture_mode", false)
		ocean.set("observe_mode", false)
		if qa_mode:
			call_deferred("_run_route_qa_and_quit")
		else:
			call_deferred("_capture_sequence")


func _configure_viewport() -> void:
	var window := get_window()
	window.size = VIEWPORT_SIZE
	window.content_scale_size = VIEWPORT_SIZE
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED


func _configure_route() -> void:
	ocean.set("route_origin_z", -START_Z)
	ocean.set("transition_01_start", 42.0)
	ocean.set("transition_01_end", 72.0)
	ocean.set("transition_12_start", 148.0)
	ocean.set("transition_12_end", 188.0)
	ocean.set("transition_23_start", 272.0)
	ocean.set("transition_23_end", 302.0)
	ocean.set("coastal_test_mode", false)
	var water := ocean.get("water_mesh") as MeshInstance3D
	if water != null:
		water.scale = Vector3(1.25, 1.0, 3.6)
	var camera := ocean.get("camera") as Camera3D
	if camera != null:
		camera.far = 520.0
	camera.fov = 58.0
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	var material := ocean.get("water_material") as ShaderMaterial
	if material != null:
		for item in [
			["route_origin_z", -START_Z], ["transition_01_start", 42.0], ["transition_01_end", 72.0],
			["transition_12_start", 148.0], ["transition_12_end", 188.0],
			["transition_23_start", 272.0], ["transition_23_end", 302.0],
		]:
			material.set_shader_parameter(String(item[0]), item[1])
		material.set_shader_parameter("coastal_local_enabled", false)


func _build_showcase_wake() -> void:
	var wake := Node3D.new()
	wake.name = "WakeCandidate_%s" % wake_candidate.to_upper()
	wake.set_script(WAKE_B_SCRIPT if wake_candidate == "b" else WAKE_A_SCRIPT)
	add_child(wake)

func _hide_old_proxies() -> void:
	for path in ["CoastalWaterProxyWorld_PLACEHOLDER", "SailingReferenceScaleReferences", "RegionalOceanRouteMarkers_TEST_ONLY"]:
		var node := ocean.get_node_or_null(path) as Node3D
		if node != null:
			node.visible = false


func _build_world() -> void:
	var root := Node3D.new()
	root.name = "NorthAtlanticPlayableWorld01_ISOLATED"
	root.set_meta("asset_status", "PORT_B_ARRIVAL_INTEGRATION_01_STAGING")
	root.set_meta("world_scale", "1 Godot unit approximately 1 meter")
	root.set_meta("route_distance_m", ROUTE_M)
	add_child(root)
	visual_root = Node3D.new()
	visual_root.name = "WorldVisualRoot_REPLACEABLE"
	root.add_child(visual_root)
	collision_root = Node3D.new()
	collision_root.name = "WorldCollisionRoot_SIMPLE_PROXY"
	root.add_child(collision_root)
	_build_environment(root)
	_build_destination_a()
	_build_distant_world_context()
	_build_crossing_rhythm()
	_build_destination_b()
	_add_boundaries()


func _build_environment(root: Node3D) -> void:
	var world := WorldEnvironment.new()
	world.name = "NorthAtlanticEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.43, 0.56, 0.63, 1.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.64, 0.70, 0.71, 1.0)
	environment.ambient_light_energy = 0.8
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.54, 0.63, 0.66, 1.0)
	environment.fog_light_energy = 0.45
	environment.fog_density = 0.00125
	environment.fog_height = 10.0
	environment.fog_height_density = 0.009
	world.environment = environment
	root.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "NorthAtlanticSoftDaylight"
	sun.rotation_degrees = Vector3(-47.0, -28.0, 0.0)
	sun.light_color = Color(0.91, 0.94, 0.94, 1.0)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	root.add_child(sun)


func _build_destination_a() -> void:
	var root := _new_region("DestinationA_ExposedNorthernCoast", "exposed northern coast")
	_add_landform(root, "A_West_ExposedSlope", -40.0, 184.0, 232.0, 23.0, 36.0, 18.0, 0.4, Color(0.20, 0.25, 0.27, 1.0), Color(0.17, 0.27, 0.23, 1.0))
	_add_landform(root, "A_East_ExposedSlope", 39.0, 187.0, 228.0, 24.0, 34.0, 15.0, 2.0, Color(0.22, 0.27, 0.29, 1.0), Color(0.19, 0.30, 0.24, 1.0))
	_add_landform(root, "A_WindwardRidge", -4.0, 197.0, 236.0, 13.0, 25.0, 10.0, 3.2, Color(0.24, 0.28, 0.29, 1.0), Color(0.20, 0.32, 0.23, 1.0))
	_add_rock_shore(root, "A_ExposedRockyLanding", Vector3(0.0, 0.25, 184.0), 34.0, 0.5, 0.7)
	_add_path(root, "A_CottagePath", Vector3(-1.0, 0.60, 185.0), Vector3(-21.0, 6.0, 212.0), 1.7, Color(0.34, 0.32, 0.26, 1.0))
	_add_lighthouse(root, "A_ExposedLandmark", Vector3(-55.0, 13.0, 223.0))
	_add_rocks(root, "A_WindwardRocks", Vector3(3.0, 1.0, 197.0), 4)
	_add_collision("A_LandCollision", Vector3(112.0, 28.0, 58.0), Vector3(0.0, 12.0, 215.0))


func _build_distant_world_context() -> void:
	var root := _new_region("DistantRegionalContext", "subordinate far-coast silhouettes for regional scale")
	root.set_meta("asset_status", "SHOWCASE_VISUAL_CONTEXT_ONLY")
	_add_landform(root, "FarWestCoastline", -112.0, -250.0, -330.0, 24.0, 38.0, 7.5, 1.2, Color(0.22, 0.27, 0.29, 1.0), Color(0.21, 0.31, 0.26, 1.0))
	_add_landform(root, "FarEastIslandGroup", 105.0, -268.0, -338.0, 18.0, 31.0, 5.8, 3.4, Color(0.24, 0.28, 0.29, 1.0), Color(0.23, 0.32, 0.26, 1.0))
	_add_rocks(root, "FarEastRocks", Vector3(77.0, 0.35, -245.0), 3)


func _build_crossing_rhythm() -> void:
	var root := _new_region("CrossingRhythm", "restrained near-mid-far framing outside the sailing lane")
	root.set_meta("asset_status", "P17_STRUCTURAL_WORLD_PASS")
	_add_landform(root, "A_WestCoastContinuation", -73.0, 92.0, 176.0, 16.0, 27.0, 10.0, 1.1, Color(0.19, 0.24, 0.26, 1.0), Color(0.16, 0.26, 0.22, 1.0))
	_add_landform(root, "A_EastCoastContinuation", 75.0, 78.0, 178.0, 15.0, 28.0, 8.0, 3.0, Color(0.20, 0.25, 0.27, 1.0), Color(0.18, 0.28, 0.23, 1.0))
	_add_skerry_chain(root, "WestDepartureSkerries", Vector3(-69.0, 0.0, 70.0), 4, 14.0, 0.3)
	_add_skerry_chain(root, "EastMidCrossingSkerries", Vector3(72.0, 0.0, -22.0), 3, 16.0, 2.2)
	_add_skerry_chain(root, "WestApproachSkerries", Vector3(-72.0, 0.0, -104.0), 4, 13.0, 4.1)
	_add_landform(root, "B_FarWestReveal", -101.0, -116.0, -210.0, 14.0, 29.0, 7.0, 2.5, Color(0.22, 0.27, 0.29, 1.0), Color(0.20, 0.31, 0.25, 1.0))
	_add_landform(root, "B_FarEastReveal", 103.0, -132.0, -222.0, 13.0, 27.0, 6.0, 4.2, Color(0.23, 0.28, 0.29, 1.0), Color(0.22, 0.32, 0.26, 1.0))


func _add_skerry_chain(parent: Node3D, node_name: String, center: Vector3, count: int, spacing: float, phase: float) -> void:
	var root := Node3D.new()
	root.name = node_name + "_ASYMMETRIC_SILHOUETTE"
	parent.add_child(root)
	for index in range(count):
		var t := float(index) - float(count - 1) * 0.5
		var rock := MeshInstance3D.new()
		rock.name = "Skerry_%02d" % index
		var mesh := SphereMesh.new()
		mesh.radius = 2.2 + float(index % 3) * 0.65
		mesh.height = mesh.radius * 1.25
		mesh.radial_segments = 7
		mesh.rings = 3
		rock.mesh = mesh
		rock.position = center + Vector3(sin(phase + index * 1.7) * 5.0, 0.3, t * spacing)
		rock.rotation_degrees.y = phase * 31.0 + index * 23.0
		rock.scale = Vector3(1.45 + 0.18 * (index % 2), 0.42 + 0.08 * (index % 3), 0.78)
		rock.material_override = _material(Color(0.24, 0.29, 0.30, 1.0))
		root.add_child(rock)

func _build_destination_b() -> void:
	var root := _new_region("DestinationB_ShelteredInhabitedCoast", "sheltered inhabited coast and working harbor")
	match layout_variant:
		"a":
			_build_b_offset_inlet(root)
		"c":
			_build_b_asymmetric_headland(root)
		_:
			_build_b_dogleg_cove(root)
func _build_b_offset_inlet(root: Node3D) -> void:
	_add_landform(root, "B_A_WestOuterHeadland", -58.0, -165.0, -242.0, 29.0, 37.0, 13.0, 0.5, Color(0.25, 0.30, 0.31, 1.0), Color(0.24, 0.37, 0.27, 1.0))
	_add_landform(root, "B_A_EastOuterHeadland", 53.0, -178.0, -242.0, 24.0, 33.0, 15.0, 2.3, Color(0.24, 0.29, 0.30, 1.0), Color(0.23, 0.36, 0.27, 1.0))
	_add_landform(root, "B_A_BackSlope", 0.0, -220.0, -245.0, 23.0, 31.0, 10.0, 4.4, Color(0.26, 0.31, 0.30, 1.0), Color(0.27, 0.39, 0.25, 1.0))
	_add_landform(root, "B_A_WestInletShoulder", -31.0, -181.0, -202.0, 11.0, 14.0, 5.0, 1.0, Color(0.27, 0.31, 0.31, 1.0), Color(0.25, 0.37, 0.27, 1.0))
	_add_shore(root, "B_A_WorkingApron", Vector3(11.0, 0.48, -193.0), Vector3(17.0, 0.28, 5.0), Color(0.24, 0.22, 0.18, 1.0))
	_add_rock_shore(root, "B_A_InnerShore", Vector3(7.0, 0.20, -179.0), 25.0, 0.35, 1.4)
	_add_rock_shore(root, "B_A_OuterBreakwater", Vector3(30.0, 0.55, -185.0), 13.0, 0.55, 2.6)
	_add_path(root, "B_A_WorkPath", Vector3(11.0, 0.65, -190.0), Vector3(4.0, 1.8, -215.0), 1.7, Color(0.34, 0.30, 0.24, 1.0))
	_add_house(root, "B_A_UpperHouse", Vector3(-10.0, 7.0, -225.0), 6.0, 4.0, Color(0.48, 0.44, 0.36, 1.0), Color(0.19, 0.22, 0.22, 1.0))
	_add_house(root, "B_A_LowerHouse", Vector3(5.0, 5.0, -214.0), 5.0, 3.5, Color(0.45, 0.41, 0.34, 1.0), Color(0.18, 0.21, 0.21, 1.0))
	_add_pier(root, "B_A_WorkingPier", Vector3(11.0, 0.55, -191.0))
	_add_lighthouse(root, "B_A_HarborLandmark", Vector3(-34.0, 9.0, -225.0))
	_add_cargo(root, "B_A_WorkingGear", Vector3(17.0, 1.0, -191.0))
	_add_collision("B_A_LeftLandCollision", Vector3(56.0, 24.0, 56.0), Vector3(-54.0, 11.0, -205.0))
	_add_collision("B_A_RightLandCollision", Vector3(48.0, 22.0, 48.0), Vector3(52.0, 10.0, -207.0))
	_add_collision("B_A_BackLandCollision", Vector3(72.0, 28.0, 24.0), Vector3(0.0, 14.0, -232.0))
func _build_b_dogleg_cove(root: Node3D) -> void:
	# The outer mass reaches the mouth before folding back into a lower inner
	# shoulder. From the gameplay camera this makes B a coast with a cut in it,
	# rather than two unrelated islands flanking a dock.
	_add_landform(root, "B_B_WestDominantHeadland", -57.0, -145.0, -224.0, 33.0, 39.0, 18.0, 0.7, Color(0.24, 0.29, 0.30, 1.0), Color(0.22, 0.35, 0.26, 1.0))
	_add_landform(root, "B_B_EastOuterShoulder", 55.0, -190.0, -241.0, 19.0, 34.0, 11.0, 2.6, Color(0.25, 0.30, 0.31, 1.0), Color(0.25, 0.38, 0.28, 1.0))
	_add_landform(root, "B_B_RearInhabitedSlope", 15.0, -212.0, -245.0, 15.0, 28.0, 15.0, 4.6, Color(0.26, 0.31, 0.30, 1.0), Color(0.27, 0.39, 0.25, 1.0))
	_add_landform(root, "B_B_ContinuousRearCoast", 6.0, -219.0, -248.0, 36.0, 48.0, 18.0, 5.0, Color(0.25, 0.30, 0.30, 1.0), Color(0.26, 0.38, 0.25, 1.0))
	_add_landform(root, "B_B_WestInnerShelter", -38.0, -174.0, -220.0, 13.0, 22.0, 8.5, 1.55, Color(0.25, 0.30, 0.30, 1.0), Color(0.23, 0.36, 0.26, 1.0))
	_add_landform(root, "B_B_EastInnerArm", 22.0, -165.0, -205.0, 10.0, 14.0, 6.5, 2.1, Color(0.27, 0.31, 0.31, 1.0), Color(0.24, 0.37, 0.27, 1.0))
	_add_harbor_bank(root, "B_B_WorkingShoreBank", Vector3(-15.0, -0.18, -204.0), Vector3(23.0, 1.05, 9.0))
	_add_quay(root, "B_B_MainQuay", Vector3(-7.0, 0.28, -196.0), Vector3(7.0, 0.18, 1.8))
	_add_slipway(root, "B_B_Slipway", Vector3(-16.0, 0.02, -197.0), Vector3(3.4, 0.32, 6.0))
	_add_rock_shore(root, "B_B_InnerShore", Vector3(-3.0, 0.20, -181.0), 25.0, 0.34, 1.8)
	_add_rock_shore(root, "B_B_CoveBreakwater", Vector3(22.0, 0.55, -190.0), 12.0, 0.5, 2.9)
	_add_path(root, "B_B_WorkPath", Vector3(-8.0, 0.65, -191.0), Vector3(3.0, 1.8, -215.0), 1.7, Color(0.34, 0.30, 0.24, 1.0))
	# Upper-house proxy intentionally omitted: it read as a floating grey staging block in the gameplay frame.
	_add_quay(root, "B_B_WorkShedApron", Vector3(-7.0, 0.30, -204.0), Vector3(7.2, 0.32, 5.2))
	_add_house(root, "B_B_WorkHouse", Vector3(-7.0, 0.55, -204.0), 4.8, 2.8, Color(0.25, 0.25, 0.23, 1.0), Color(0.16, 0.19, 0.19, 1.0))
	_add_pier(root, "B_B_WorkingPier", Vector3(-8.0, 0.55, -192.0))
	_add_lighthouse(root, "B_B_HeadlandLandmark", Vector3(-29.0, 12.0, -217.0))
	_add_arrival_beacon(root, Vector3(-29.0, 18.5, -217.0))
	_add_cargo(root, "B_B_WorkingGear", Vector3(-1.0, 1.0, -192.0))
	_add_rock_shore(root, "B_B_WestTidalContact", Vector3(-27.0, -0.05, -180.0), 19.0, 0.28, 0.35)
	_add_collision("B_B_WestLandCollision", Vector3(58.0, 26.0, 60.0), Vector3(-55.0, 12.0, -195.0))
	_add_collision("B_B_EastLandCollision", Vector3(40.0, 22.0, 44.0), Vector3(55.0, 10.0, -216.0))
	_add_collision("B_B_RearLandCollision", Vector3(68.0, 28.0, 25.0), Vector3(10.0, 14.0, -233.0))


func _add_arrival_beacon(parent: Node3D, position: Vector3) -> void:
	var beacon := MeshInstance3D.new()
	beacon.name = "B_ArrivalBeacon_DIEGETIC"
	var mesh := SphereMesh.new()
	mesh.radius = 0.28
	mesh.height = 0.56
	mesh.radial_segments = 8
	mesh.rings = 4
	beacon.mesh = mesh
	beacon.position = position
	beacon.material_override = _material(Color(0.94, 0.73, 0.39, 1.0))
	parent.add_child(beacon)
	var light := OmniLight3D.new()
	light.name = "WarmHarborWelcomeLight"
	light.position = position
	light.light_color = Color(1.0, 0.72, 0.40, 1.0)
	light.light_energy = 1.8
	light.omni_range = 9.0
	parent.add_child(light)
func _build_b_asymmetric_headland(root: Node3D) -> void:
	_add_landform(root, "B_C_WestHighHeadland", -62.0, -154.0, -242.0, 30.0, 42.0, 20.0, 0.9, Color(0.23, 0.28, 0.30, 1.0), Color(0.21, 0.34, 0.25, 1.0))
	_add_landform(root, "B_C_EastLowShoulder", 52.0, -180.0, -242.0, 18.0, 32.0, 8.0, 2.8, Color(0.26, 0.31, 0.31, 1.0), Color(0.25, 0.38, 0.28, 1.0))
	_add_landform(root, "B_C_BackSettlementSlope", 2.0, -218.0, -246.0, 22.0, 33.0, 12.0, 4.8, Color(0.27, 0.32, 0.31, 1.0), Color(0.28, 0.40, 0.26, 1.0))
	_add_landform(root, "B_C_RestrainedEastArm", 28.0, -182.0, -201.0, 8.0, 12.0, 4.5, 2.0, Color(0.28, 0.32, 0.31, 1.0), Color(0.25, 0.37, 0.27, 1.0))
	_add_shore(root, "B_C_WorkingApron", Vector3(13.0, 0.48, -194.0), Vector3(17.0, 0.28, 5.0), Color(0.24, 0.22, 0.18, 1.0))
	_add_rock_shore(root, "B_C_InnerShore", Vector3(6.0, 0.20, -181.0), 25.0, 0.32, 1.5)
	_add_rock_shore(root, "B_C_Breakwater", Vector3(26.0, 0.55, -191.0), 12.0, 0.5, 2.7)
	_add_path(root, "B_C_WorkPath", Vector3(13.0, 0.65, -191.0), Vector3(4.0, 1.8, -216.0), 1.7, Color(0.34, 0.30, 0.24, 1.0))
	_add_house(root, "B_C_UpperHouse", Vector3(-7.0, 7.0, -227.0), 6.0, 4.0, Color(0.49, 0.45, 0.37, 1.0), Color(0.19, 0.22, 0.22, 1.0))
	_add_house(root, "B_C_WorkHouse", Vector3(4.0, 5.0, -215.0), 5.2, 3.6, Color(0.45, 0.41, 0.34, 1.0), Color(0.18, 0.21, 0.21, 1.0))
	_add_pier(root, "B_C_WorkingPier", Vector3(13.0, 0.55, -192.0))
	_add_lighthouse(root, "B_C_HighHeadlandLandmark", Vector3(-36.0, 13.0, -224.0))
	_add_cargo(root, "B_C_WorkingGear", Vector3(19.0, 1.0, -192.0))
	_add_collision("B_C_WestLandCollision", Vector3(62.0, 26.0, 60.0), Vector3(-59.0, 12.0, -197.0))
	_add_collision("B_C_EastLandCollision", Vector3(36.0, 20.0, 44.0), Vector3(53.0, 10.0, -216.0))
	_add_collision("B_C_RearLandCollision", Vector3(70.0, 28.0, 25.0), Vector3(0.0, 14.0, -234.0))
func _new_region(node_name: String, role: String) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	root.set_meta("role", role)
	root.set_meta("asset_status", "OVERNIGHT_BLOCKOUT")
	visual_root.add_child(root)
	return root


func _add_landform(parent: Node3D, node_name: String, center_x: float, front_z: float, back_z: float, front_half_width: float, back_half_width: float, peak_height: float, phase: float, rock_color: Color, turf_color: Color) -> void:
	var root := Node3D.new()
	root.name = node_name + "_GEOLOGY_BLOCKOUT"
	root.set_meta("asset_status", "DESIGNED_TERRAIN_PROXY")
	parent.add_child(root)
	var rows := 7
	var columns := 7
	var top_vertices := PackedVector3Array()
	var top_indices := PackedInt32Array()
	for row in range(rows):
		var t := float(row) / float(rows - 1)
		var z_base := lerpf(front_z, back_z, t)
		var shore_curve := sin(phase * 0.8 + t * 2.4) * 1.5 * (1.0 - t)
		var row_width := lerpf(front_half_width, back_half_width, t) * (1.0 + sin(phase + t * 3.7) * 0.10)
		for column in range(columns):
			var u := float(column) / float(columns - 1) * 2.0 - 1.0
			var edge_break := sin(phase * 1.3 + float(row) * 1.4 + float(column) * 1.1) * (1.7 - 0.5 * t)
			var z_ripple := sin(phase + float(column) * 1.7 + t * 2.2) * 2.0 * (1.0 - t * 0.35)
			var x := center_x + u * row_width + edge_break * (1.0 - absf(u) * 0.35)
			var z := z_base + shore_curve + z_ripple
			var shoulder := 1.0 - pow(absf(u), 1.55) * 0.36
			var crossfall := (1.0 - absf(u)) * 1.5
			var ridge_shift := sin(phase * 0.7 + t * 2.0) * 0.22
			var ridge := exp(-pow((u - ridge_shift) / 0.58, 2.0)) * peak_height * 0.13 * (0.25 + 0.75 * t)
			var relief := sin(phase + float(row) * 1.6 + float(column) * 0.9) * 0.55 * t
			var front_lift := (1.0 - t) * crossfall
			var y := 0.22 + pow(t, 1.10) * peak_height * shoulder + ridge + relief + front_lift
			top_vertices.append(Vector3(x, maxf(y, 0.24), z))
	for row in range(rows - 1):
		for column in range(columns - 1):
			var i := row * columns + column
			top_indices.append(i)
			top_indices.append(i + columns)
			top_indices.append(i + 1)
			top_indices.append(i + 1)
			top_indices.append(i + columns)
			top_indices.append(i + columns + 1)
	var turf := MeshInstance3D.new()
	turf.name = "TurfSlope"
	turf.mesh = _array_mesh(top_vertices, top_indices)
	turf.material_override = _material(turf_color)
	root.add_child(turf)
	var side_vertices := PackedVector3Array()
	var side_indices := PackedInt32Array()
	for row in range(rows):
		var left_top := top_vertices[row * columns]
		var right_top := top_vertices[row * columns + columns - 1]
		var left_index := side_vertices.size()
		side_vertices.append(left_top)
		side_vertices.append(right_top)
		side_vertices.append(Vector3(left_top.x - 2.8, -0.2, left_top.z + 1.6))
		side_vertices.append(Vector3(right_top.x + 2.8, -0.2, right_top.z + 1.6))
		if row > 0:
			var previous := left_index - 4
			side_indices.append(previous)
			side_indices.append(left_index)
			side_indices.append(previous + 2)
			side_indices.append(previous + 2)
			side_indices.append(left_index)
			side_indices.append(left_index + 2)
			side_indices.append(previous + 1)
			side_indices.append(previous + 3)
			side_indices.append(left_index + 1)
			side_indices.append(left_index + 1)
			side_indices.append(previous + 3)
			side_indices.append(left_index + 3)
	for edge_row in [0, rows - 1]:
		for column in range(columns - 1):
			var top_a := top_vertices[edge_row * columns + column]
			var top_b := top_vertices[edge_row * columns + column + 1]
			var edge_index := side_vertices.size()
			side_vertices.append(top_a)
			side_vertices.append(top_b)
			var outward_a := 2.8 if top_a.x >= center_x else -2.8
			var outward_b := 2.8 if top_b.x >= center_x else -2.8
			side_vertices.append(Vector3(top_a.x + outward_a, -0.2, top_a.z + 1.6))
			side_vertices.append(Vector3(top_b.x + outward_b, -0.2, top_b.z + 1.6))
			if edge_row == 0:
				side_indices.append(edge_index)
				side_indices.append(edge_index + 2)
				side_indices.append(edge_index + 1)
				side_indices.append(edge_index + 1)
				side_indices.append(edge_index + 2)
				side_indices.append(edge_index + 3)
			else:
				side_indices.append(edge_index)
				side_indices.append(edge_index + 1)
				side_indices.append(edge_index + 2)
				side_indices.append(edge_index + 2)
				side_indices.append(edge_index + 1)
				side_indices.append(edge_index + 3)
	var rock := MeshInstance3D.new()
	rock.name = "RockCutSides"
	rock.mesh = _array_mesh(side_vertices, side_indices)
	rock.material_override = _material(rock_color)
	root.add_child(rock)


func _array_mesh(vertices: PackedVector3Array, indices: PackedInt32Array) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _add_rock_shore(parent: Node3D, node_name: String, center: Vector3, span: float, height: float, phase: float) -> void:
	var root := Node3D.new()
	root.name = node_name + "_IRREGULAR_EDGE"
	parent.add_child(root)
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var segments := 11
	for index in range(segments):
		var t := float(index) / float(segments - 1)
		var x := center.x + (t - 0.5) * span
		var water_z := center.z + sin(phase + index * 1.17) * 1.15
		var bank_z := water_z + 2.0 + 0.55 * sin(phase * 0.7 + index * 1.63)
		var crest := center.y + height * (0.75 + 0.35 * sin(phase + index * 1.31))
		vertices.append(Vector3(x, center.y - 0.22, water_z))
		vertices.append(Vector3(x, crest, bank_z))
		if index > 0:
			var previous := (index - 1) * 2
			var current := index * 2
			indices.append_array(PackedInt32Array([previous, current + 1, current, previous, previous + 1, current + 1]))
	var edge := MeshInstance3D.new()
	edge.name = "ContinuousRockWaterContact"
	edge.mesh = _array_mesh(vertices, indices)
	edge.material_override = _material(Color(0.29, 0.33, 0.33, 1.0))
	root.add_child(edge)


func _add_path(parent: Node3D, node_name: String, from_position: Vector3, to_position: Vector3, width: float, color: Color) -> void:
	var root := Node3D.new()
	root.name = node_name + "_FUNCTIONAL_GROUND_PATH"
	parent.add_child(root)
	var direction := to_position - from_position
	for index in range(5):
		var t := (float(index) + 0.5) / 5.0
		var segment := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(width * (0.92 + 0.08 * sin(float(index))), 0.08, direction.length() / 5.0 + 0.3)
		segment.mesh = mesh
		segment.position = from_position.lerp(to_position, t)
		segment.rotation.y = atan2(direction.x, direction.z)
		segment.material_override = _material(color)
		root.add_child(segment)

func _add_mass(parent: Node3D, node_name: String, position: Vector3, size: Vector3, near_height: float, far_height: float, base_color: Color, cap_color: Color) -> void:
	var base := MeshInstance3D.new()
	base.name = node_name + "_ROCK_BASE_PROXY"
	base.mesh = _wedge(size, near_height, far_height)
	base.position = position
	base.material_override = _material(base_color)
	parent.add_child(base)
	var cap := MeshInstance3D.new()
	cap.name = node_name + "_TURF_CAP_PROXY"
	cap.mesh = _wedge(Vector3(size.x * 0.92, size.y * 0.5, size.z * 0.88), maxf(near_height - 1.2, 0.5), maxf(far_height - 1.0, 0.8))
	cap.position = position + Vector3(0.0, maxf(near_height * 0.45, 0.8), 0.0)
	cap.material_override = _material(cap_color)
	parent.add_child(cap)


func _wedge(size: Vector3, near_height: float, far_height: float) -> ArrayMesh:
	var w := size.x * 0.5
	var d := size.z * 0.5
	var vertices := PackedVector3Array([Vector3(-w, 0.0, -d), Vector3(w, 0.0, -d), Vector3(w, 0.0, d), Vector3(-w, 0.0, d), Vector3(-w, far_height, -d), Vector3(w, far_height, -d), Vector3(w, near_height, d), Vector3(-w, near_height, d)])
	var indices := PackedInt32Array([0,2,1,0,3,2,4,5,6,4,6,7,0,1,5,0,5,4,3,6,2,3,7,6,0,4,7,0,7,3,1,2,6,1,6,5])
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _add_house(parent: Node3D, node_name: String, position: Vector3, width: float, height: float, wall_color: Color, roof_color: Color) -> void:
	var root := Node3D.new()
	root.name = node_name + "_PROXY"
	root.position = position
	parent.add_child(root)
	var walls := MeshInstance3D.new()
	walls.name = "Walls"
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(width, height, width * 0.82)
	walls.mesh = wall_mesh
	walls.position.y = height * 0.5
	walls.material_override = _material(wall_color)
	root.add_child(walls)
	var roof := MeshInstance3D.new()
	roof.name = "GableRoof"
	roof.mesh = _gable(width * 1.15, width * 0.92, height * 0.42)
	roof.position.y = height
	roof.material_override = _material(roof_color)
	root.add_child(roof)


func _gable(width: float, depth: float, height: float) -> ArrayMesh:
	var w := width * 0.5
	var d := depth * 0.5
	var vertices := PackedVector3Array([Vector3(-w,0,-d),Vector3(w,0,-d),Vector3(0,height,-d),Vector3(-w,0,d),Vector3(w,0,d),Vector3(0,height,d)])
	var indices := PackedInt32Array([0,1,2,4,3,5,0,3,4,0,4,1,2,1,4,2,4,5,0,2,5,0,5,3])
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _add_lighthouse(parent: Node3D, node_name: String, position: Vector3) -> void:
	var root := Node3D.new()
	root.name = node_name + "_PROXY"
	root.position = position
	parent.add_child(root)
	var base := MeshInstance3D.new()
	base.name = "RockFooting"
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 1.1
	base_mesh.bottom_radius = 1.8
	base_mesh.height = 1.2
	base_mesh.radial_segments = 7
	base.mesh = base_mesh
	base.position.y = 0.6
	base.material_override = _material(Color(0.29, 0.32, 0.31, 1.0))
	root.add_child(base)
	var tower := MeshInstance3D.new()
	tower.name = "ShortBeaconTower"
	var body := CylinderMesh.new()
	body.top_radius = 0.46
	body.bottom_radius = 0.72
	body.height = 5.2
	body.radial_segments = 8
	tower.mesh = body
	tower.position.y = 3.2
	tower.material_override = _material(Color(0.62, 0.64, 0.59, 1.0))
	root.add_child(tower)
	var cap := MeshInstance3D.new()
	cap.name = "BeaconRoof"
	var cap_mesh := CylinderMesh.new()
	cap_mesh.top_radius = 0.0
	cap_mesh.bottom_radius = 0.75
	cap_mesh.height = 0.9
	cap_mesh.radial_segments = 8
	cap.mesh = cap_mesh
	cap.position.y = 6.25
	cap.material_override = _material(Color(0.23, 0.27, 0.27, 1.0))
	root.add_child(cap)


func _add_rocks(parent: Node3D, node_name: String, position: Vector3, count: int) -> void:
	var root := Node3D.new()
	root.name = node_name
	root.position = position
	parent.add_child(root)
	for index in range(count):
		var rock := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		var radius := 1.0 + float(index % 4) * 0.55
		mesh.radius = radius
		mesh.height = radius * 1.35
		mesh.radial_segments = 6
		mesh.rings = 3
		rock.mesh = mesh
		rock.position = Vector3(float(index) * 2.3 - float(count) * 1.1, radius * 0.45, float(index % 2) * 2.0 - 1.0)
		rock.scale = Vector3(1.0, 0.7, 0.85)
		rock.material_override = _material(Color(0.30, 0.34, 0.34, 1.0))
		root.add_child(rock)


func _add_quay(parent: Node3D, node_name: String, position: Vector3, size: Vector3) -> void:
	var quay := MeshInstance3D.new()
	quay.name = node_name + "_PROXY"
	var mesh := BoxMesh.new()
	mesh.size = size
	quay.mesh = mesh
	quay.position = position
	quay.material_override = _material(Color(0.29, 0.27, 0.23, 1.0))
	parent.add_child(quay)

func _add_harbor_bank(parent: Node3D, node_name: String, position: Vector3, size: Vector3) -> void:
	# A low, dark foundation visually joins the quay, slip and terrain at the
	# waterline. It is visual-only so the established collision corridor remains
	# independently reversible.
	var bank := MeshInstance3D.new()
	bank.name = node_name + "_GROUNDED_EDGE"
	bank.mesh = _wedge(size, size.y * 0.72, size.y)
	bank.position = position
	bank.rotation_degrees.y = -7.0
	bank.material_override = _material(Color(0.24, 0.27, 0.26, 1.0))
	parent.add_child(bank)

func _add_slipway(parent: Node3D, node_name: String, position: Vector3, size: Vector3) -> void:
	var slipway := MeshInstance3D.new()
	slipway.name = node_name + "_PROXY"
	slipway.mesh = _wedge(size, 0.06, 0.42)
	slipway.position = position
	slipway.material_override = _material(Color(0.31, 0.30, 0.27, 1.0))
	parent.add_child(slipway)

func _add_pier(parent: Node3D, node_name: String, position: Vector3) -> void:
	var root := Node3D.new()
	root.name = node_name + "_PROXY"
	root.position = position
	parent.add_child(root)
	for index in range(3):
		var plank := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.20, 0.22, 4.2)
		plank.mesh = mesh
		plank.position = Vector3(float(index) * 0.20, 0.0, float(index) * 3.0)
		plank.rotation_degrees.y = 2.0
		plank.material_override = _material(Color(0.27, 0.22, 0.17, 1.0))
		root.add_child(plank)


func _add_shore(parent: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color) -> void:
	var strip := MeshInstance3D.new()
	strip.name = node_name + "_PROXY"
	var mesh := BoxMesh.new()
	mesh.size = size
	strip.mesh = mesh
	strip.position = position
	strip.material_override = _material(color)
	parent.add_child(strip)


func _add_cargo(parent: Node3D, node_name: String, position: Vector3) -> void:
	var cargo := MeshInstance3D.new()
	cargo.name = node_name + "_PROXY"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.2, 1.0, 1.5)
	cargo.mesh = mesh
	cargo.position = position
	cargo.material_override = _material(Color(0.39, 0.30, 0.21, 1.0))
	parent.add_child(cargo)


func _add_collision(node_name: String, size: Vector3, position: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	collision_root.add_child(body)


func _add_boundaries() -> void:
	_add_collision("WorldWestBoundary", Vector3(1.0, 20.0, 470.0), Vector3(-WORLD_X, 10.0, 0.0))
	_add_collision("WorldEastBoundary", Vector3(1.0, 20.0, 470.0), Vector3(WORLD_X, 10.0, 0.0))
	_add_collision("WorldFrontBoundary", Vector3(184.0, 20.0, 1.0), Vector3(0.0, 10.0, WORLD_FRONT))
	_add_collision("WorldBackBoundary", Vector3(184.0, 20.0, 1.0), Vector3(0.0, 10.0, WORLD_BACK))


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.roughness = 1.0
	return material


func _boat_position() -> Vector3:
	var boat := ocean.get("boat_visual") as Node3D
	return boat.position if boat != null else Vector3.ZERO


func _process(_delta: float) -> void:
	if ocean == null or harness_mode:
		return
	var boat := ocean.get("boat_visual") as Node3D
	if boat == null:
		return
	var position := boat.position
	var blocked := _land_mask(position)
	var outside := absf(position.x) > WORLD_X - 3.0 or position.z > WORLD_FRONT - 3.0 or position.z < WORLD_BACK + 3.0
	if blocked or outside:
		boat.position = last_safe_position
		if not contact_latched:
			print("TERRA_SHOWCASE_CONTACT|blocked=%s|outside=%s|position=%s" % [blocked, outside, str(position)])
		contact_latched = true
		# The correction only applies on actual proxy contact. It never creates a broad harbor slow zone.
		var impact_speed := float(ocean.get("boat_speed"))
		if impact_speed > 0.55:
			ocean.set("boat_speed", 0.55)
	else:
		last_safe_position = position
		contact_latched = false

func _land_mask(position: Vector3) -> bool:
	var x := position.x
	var z := position.z
	if z >= 184.0 and z <= 235.0 and absf(x) > 21.0:
		return true
	if z < -246.0:
		return true
	# Layout B keeps a wide exposed entrance, then asks for one readable left dog-leg
	# without applying any speed modifier inside either water corridor.
	if z >= -160.0 and z <= -145.0:
		return x < -31.0 or x > 34.0
	if z >= -181.0 and z < -160.0:
		return x < -27.0 or x > 15.0
	if z >= -225.0 and z < -181.0:
		return x < -24.0 or x > 15.0
	return false


func _input(event: InputEvent) -> void:
	if harness_mode or ocean == null:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_BACKSPACE:
		ocean.call("_set_boat_pose", Vector3(0.0, 0.28, START_Z), 0.0, 0.0)
		last_safe_position = _boat_position()
		contact_latched = false
		get_viewport().set_input_as_handled()
		print("TERRA_SHOWCASE_RESET|position=%s" % str(last_safe_position))

func _capture_sequence() -> void:
	var root := ProjectSettings.globalize_path(capture_root_override if capture_root_override != "" else CAPTURE_ROOT)
	DirAccess.make_dir_recursive_absolute(root)
	var stages := [
		["01_departure.png", Vector3(0.0, 0.28, START_Z)],
		["02_departure_separation.png", Vector3(0.0, 0.28, 92.0)],
		["03_open_sea_wake.png", Vector3(0.0, 0.28, 28.0), "wake_review"],
		["04_mid_crossing.png", Vector3(0.0, 0.28, -42.0)],
		["05_first_land_reveal.png", Vector3(0.0, 0.28, -112.0)],
		["06_destination_context.png", Vector3(0.0, 0.28, -142.0)],
		["07_B_approach.png", Vector3(0.0, 0.28, -149.0)],
		["08_entrance.png", Vector3(-4.0, 0.28, -157.0)],
		["09_dog_leg_turn.png", Vector3(-12.0, 0.28, -168.0), "wake_review"],
		["10_inner_harbor.png", Vector3(-12.0, 0.28, -178.0)],
		["11_arrival_stop.png", Vector3(-8.0, 0.28, END_Z), "overview", true],
	]
	var previous := Vector3(0.0, 0.28, START_Z)
	for item in stages:
		var target: Vector3 = item[1]
		await _traverse_to(previous, target, 72)
		if item.size() > 3 and bool(item[3]):
			ocean.call("_set_boat_pose", target, 0.0, 0.0)
			await _settle(90)
		await _capture_image(root, String(item[0]), String(item[2]) if item.size() > 2 else "overview")
		previous = target
	print("TERRA_SHOWCASE_CAPTURE_COMPLETE|route=A_TO_B|stages=11|root=%s|harness=deterministic_in_engine" % root)
	get_tree().quit()


func _run_route_qa_and_quit() -> void:
	await _settle(4)
	var routes := {
		"center": [Vector3(0.0, 0.28, -151.0), Vector3(-12.0, 0.28, -163.0), Vector3(-11.0, 0.28, -174.0), Vector3(-8.0, 0.28, -193.0)],
		"moderate_left": [Vector3(-12.0, 0.28, -151.0), Vector3(-18.0, 0.28, -163.0), Vector3(-14.0, 0.28, -174.0), Vector3(-12.0, 0.28, -193.0)],
		"moderate_right": [Vector3(12.0, 0.28, -151.0), Vector3(10.0, 0.28, -163.0), Vector3(4.0, 0.28, -174.0), Vector3(4.0, 0.28, -193.0)],
		"reverse_B_to_A": [Vector3(-8.0, 0.28, -193.0), Vector3(-8.0, 0.28, -174.0), Vector3(0.0, 0.28, -151.0), Vector3(0.0, 0.28, -105.0), Vector3(0.0, 0.28, 10.0), Vector3(0.0, 0.28, 70.0), Vector3(0.0, 0.28, START_Z)],
		"slightly_late_turn": [Vector3(0.0, 0.28, -151.0), Vector3(0.0, 0.28, -166.0), Vector3(-22.0, 0.28, -174.0), Vector3(-12.0, 0.28, -193.0)],
		"slightly_early_turn": [Vector3(0.0, 0.28, -151.0), Vector3(-12.0, 0.28, -158.0), Vector3(-12.0, 0.28, -174.0), Vector3(-12.0, 0.28, -193.0)],
		"lateral_safe": [Vector3(14.0, 0.28, -151.0), Vector3(12.0, 0.28, -163.0), Vector3(8.0, 0.28, -174.0), Vector3(4.0, 0.28, -193.0)],
		"excess_lateral_rejected": [Vector3(20.0, 0.28, -151.0), Vector3(20.0, 0.28, -163.0), Vector3(12.0, 0.28, -174.0), Vector3(4.0, 0.28, -193.0)],
	}
	for route_name in routes.keys():
		var points: Array = routes[route_name]
		var logical_clear := true
		var physics_clear := true
		var min_margin := 999.0
		for index in range(points.size()):
			var point: Vector3 = points[index]
			if _land_mask(point):
				logical_clear = false
			if point.z >= -225.0 and point.z <= -145.0:
				min_margin = minf(min_margin, minf(absf(point.x + 26.0), absf(35.0 - point.x)))
			if _physics_probe(point):
				physics_clear = false
			if index < points.size() - 1:
				var from_point: Vector3 = point
				var to_point: Vector3 = points[index + 1]
				for sample in range(1, 13):
					var probe := from_point.lerp(to_point, float(sample) / 12.0)
					if _land_mask(probe):
						logical_clear = false
					if _physics_probe(probe):
						physics_clear = false
		var clear := logical_clear and physics_clear
		print("PORT_B_ROUTE_QA|route=%s|clear=%s|logical_clear=%s|physics_clear=%s|min_entrance_margin=%.1f" % [route_name, clear, logical_clear, physics_clear, min_margin])
	print("PORT_B_COLLISION_QA|entrance=headlands|quay=working_apron|slipway=work_path|shoreline=inner_shore|visual_collision_separated=true|human_steering_certified=false")
	get_tree().quit()


func _physics_probe(position: Vector3) -> bool:
	var query := PhysicsPointQueryParameters3D.new()
	query.position = position + Vector3(0.0, 0.45, 0.0)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return get_world_3d().direct_space_state.intersect_point(query, 8).size() > 0


func _traverse_to(from_position: Vector3, to_position: Vector3, frame_count: int) -> void:
	var direction := to_position - from_position
	var yaw := atan2(direction.x, -direction.z)
	for frame in range(frame_count):
		var t := float(frame + 1) / float(frame_count)
		var position := from_position.lerp(to_position, t)
		ocean.call("_set_boat_pose", position, rad_to_deg(yaw), TEST_SPEED)
		await get_tree().process_frame


func _capture_image(root: String, file_name: String, view_name: String = "overview") -> void:
	await _settle(10)
	var freeze_ocean_for_wake_frame := view_name == "wake_review"
	if freeze_ocean_for_wake_frame:
		ocean.process_mode = Node.PROCESS_MODE_DISABLED
	if view_name == "wake_review":
		_set_wake_review_camera()
	else:
		ocean.call("_set_camera_view", view_name)
	if freeze_ocean_for_wake_frame:
		await get_tree().process_frame
		ocean.process_mode = Node.PROCESS_MODE_INHERIT
	var image := get_viewport().get_texture().get_image()
	if image != null:
		image.save_png(root.path_join(file_name))


func _set_wake_review_camera() -> void:
	var boat := ocean.get("boat_visual") as Node3D
	var camera := ocean.get("camera") as Camera3D
	if boat == null or camera == null:
		return
	var forward: Vector3 = ocean.call("_boat_forward")
	var right := forward.cross(Vector3.UP).normalized()
	camera.position = boat.position + right * 7.0 - forward * 8.0 + Vector3.UP * 4.4
	camera.fov = 46.0
	camera.look_at(boat.position + forward * 2.5 + Vector3.UP * 0.55, Vector3.UP)

func _settle(count: int) -> void:
	for _frame in range(count):
		await get_tree().process_frame
