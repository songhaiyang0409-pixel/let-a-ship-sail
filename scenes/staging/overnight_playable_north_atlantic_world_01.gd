extends Node3D

## Overnight Playable North Atlantic World 01
##
## Isolated production derivative. The canonical RegionalOceanSystem continues
## to own boat control, camera, B+ V3 waves, wave-follow, and wake. This thin
## wrapper owns only route-scale staging and replaceable destination visuals.

const VIEWPORT_SIZE := Vector2i(1152, 648)
const CAPTURE_ROOT := "res://scenes/staging/overnight_playable_north_atlantic_world_01_captures"
const ROUTE_START_Z := 160.0
const ROUTE_END_Z := -175.0
const ROUTE_DISTANCE_M := ROUTE_START_Z - ROUTE_END_Z
const NORMAL_SPEED_MPS := 2.2
const TEST_SPEED_MPS := 5.0
const V2FUN_BUILDING_SCALE := 8.0
const COTTAGE_ASSET := "res://V2FUN_INBOX/working/Faroe_Turf_Roof_Cottage__V2FUN__7e3dd2ee.glb"
const SHED_ASSET := "res://V2FUN_INBOX/working/Harbor_Fishing_Shed__V2FUN__68c336dd.glb"
const WORLD_HALF_WIDTH := 92.0
const WORLD_BACK_Z := -240.0
const WORLD_FRONT_Z := 235.0

const WAVE_TRANSITIONS := {
	"01_start": 52.0,
	"01_end": 84.0,
	"12_start": 126.0,
	"12_end": 170.0,
	"23_start": 238.0,
	"23_end": 292.0,
}

var canonical_instance: Node3D
var regional_system: Node3D
var production_world_root: Node3D
var visual_root: Node3D
var collision_root: Node3D
var last_safe_boat_position := Vector3.ZERO
var capture_mode := false


func _ready() -> void:
	_configure_viewport()
	capture_mode = OS.get_cmdline_user_args().has("--capture-overnight-playable-world-01")
	canonical_instance = get_node_or_null("CanonicalSailingReference") as Node3D
	if canonical_instance == null:
		push_error("Playable world could not find CanonicalSailingReference.")
		return
	await get_tree().process_frame
	regional_system = canonical_instance.get_node_or_null("RegionalOceanSystem") as Node3D
	if regional_system == null:
		push_error("Playable world could not find RegionalOceanSystem.")
		return
	_configure_isolated_route()
	_hide_old_proxy_world()
	_build_production_world()
	_mount_v2fun_assets()
	_set_initial_boat_pose()
	last_safe_boat_position = _boat_position()
	print("OVERNIGHT_PLAYABLE_WORLD_READY|route_m=%d|normal_seconds=%.1f|v2fun_scale=%.1f|formal_project_modified=false" % [ROUTE_DISTANCE_M, ROUTE_DISTANCE_M / NORMAL_SPEED_MPS, V2FUN_BUILDING_SCALE])
	if capture_mode:
		regional_system.set("interactive_mode", false)
		regional_system.set("capture_mode", false)
		regional_system.set("observe_mode", false)
		call_deferred("_capture_world_sequence")


func _configure_viewport() -> void:
	var window := get_window()
	window.size = VIEWPORT_SIZE
	window.content_scale_size = VIEWPORT_SIZE
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED


func _configure_isolated_route() -> void:
	# Reuse the existing four approved RegionalOceanPreset resources, but stretch
	# their transitions across this longer isolated route.
	regional_system.set("route_origin_z", -ROUTE_START_Z)
	regional_system.set("transition_01_start", WAVE_TRANSITIONS["01_start"])
	regional_system.set("transition_01_end", WAVE_TRANSITIONS["01_end"])
	regional_system.set("transition_12_start", WAVE_TRANSITIONS["12_start"])
	regional_system.set("transition_12_end", WAVE_TRANSITIONS["12_end"])
	regional_system.set("transition_23_start", WAVE_TRANSITIONS["23_start"])
	regional_system.set("transition_23_end", WAVE_TRANSITIONS["23_end"])
	regional_system.set("coastal_test_mode", false)
	regional_system.set("canonical_reference_mode", true)
	var water_mesh := regional_system.get("water_mesh") as MeshInstance3D
	if water_mesh != null:
		water_mesh.scale = Vector3(1.25, 1.0, 3.6)
	var camera := regional_system.get("camera") as Camera3D
	if camera != null:
		camera.far = 520.0
	var material := regional_system.get("water_material") as ShaderMaterial
	if material != null:
		material.set_shader_parameter("route_origin_z", -ROUTE_START_Z)
		material.set_shader_parameter("transition_01_start", WAVE_TRANSITIONS["01_start"])
		material.set_shader_parameter("transition_01_end", WAVE_TRANSITIONS["01_end"])
		material.set_shader_parameter("transition_12_start", WAVE_TRANSITIONS["12_start"])
		material.set_shader_parameter("transition_12_end", WAVE_TRANSITIONS["12_end"])
		material.set_shader_parameter("transition_23_start", WAVE_TRANSITIONS["23_start"])
		material.set_shader_parameter("transition_23_end", WAVE_TRANSITIONS["23_end"])
		material.set_shader_parameter("coastal_local_enabled", false)


func _hide_old_proxy_world() -> void:
	var old_proxy := regional_system.get_node_or_null("CoastalWaterProxyWorld_PLACEHOLDER") as Node3D
	if old_proxy != null:
		old_proxy.visible = false
	var references := regional_system.get_node_or_null("SailingReferenceScaleReferences") as Node3D
	if references != null:
		references.visible = false
	var markers := regional_system.get_node_or_null("RegionalOceanRouteMarkers_TEST_ONLY") as Node3D
	if markers != null:
		markers.visible = false


func _build_production_world() -> void:
	production_world_root = Node3D.new()
	production_world_root.name = "NorthAtlanticPlayableWorld01_ISOLATED"
	production_world_root.set_meta("asset_status", "OVERNIGHT_PRODUCTION_BLOCKOUT")
	production_world_root.set_meta("world_scale", "1 Godot unit approximately 1 meter")
	production_world_root.set_meta("route_distance_m", ROUTE_DISTANCE_M)
	add_child(production_world_root)

	visual_root = Node3D.new()
	visual_root.name = "WorldVisualRoot_REPLACEABLE"
	visual_root.set_meta("layer", "visual only")
	production_world_root.add_child(visual_root)
	collision_root = Node3D.new()
	collision_root.name = "WorldCollisionRoot_SIMPLE_PROXY"
	collision_root.set_meta("layer", "simple gameplay proxy")
	production_world_root.add_child(collision_root)

	_build_environment()
	_build_destination_a()
	_build_destination_b()
	_build_world_boundary_proxies()


func _build_environment() -> void:
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
	environment.fog_density = 0.0017
	environment.fog_height = 10.0
	environment.fog_height_density = 0.012
	world.environment = environment
	production_world_root.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "NorthAtlanticSoftDaylight"
	sun.rotation_degrees = Vector3(-47.0, -28.0, 0.0)
	sun.light_color = Color(0.91, 0.94, 0.94, 1.0)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	production_world_root.add_child(sun)


func _build_destination_a() -> void:
	var root := Node3D.new()
	root.name = "DestinationA_ExposedNorthernCoast"
	root.set_meta("role", "exposed northern coast")
	root.set_meta("asset_status", "LARGE_FORM_PROXY_WITH_ONE_V2FUN_FOCAL_ASSET")
	visual_root.add_child(root)

	_add_terrain_mass(root, "A_ExposedRockMass_L", Vector3(-46.0, 0.0, 207.0), Vector3(66.0, 18.0, 64.0), 5.0, 16.0, _material(Color(0.28, 0.33, 0.35, 1.0)), _material(Color(0.28, 0.39, 0.30, 1.0)))
	_add_terrain_mass(root, "A_ExposedRockMass_R", Vector3(44.0, 0.0, 214.0), Vector3(54.0, 14.0, 56.0), 4.0, 12.0, _material(Color(0.25, 0.30, 0.32, 1.0)), _material(Color(0.25, 0.36, 0.28, 1.0)))
	_add_terrain_mass(root, "A_HighTurfBack", Vector3(-18.0, 2.0, 230.0), Vector3(82.0, 22.0, 34.0), 12.0, 18.0, _material(Color(0.20, 0.27, 0.28, 1.0)), _material(Color(0.30, 0.42, 0.31, 1.0)))
	_add_rock_cluster(root, "A_WindwardRockCluster", Vector3(11.0, 2.0, 196.0), 5, 2.0, 6.0)
	_mount_v2fun(root, COTTAGE_ASSET, "A_FaroeTurfRoofCottage", Vector3(-20.0, 9.0, 207.0))
	_add_house_proxy(root, "A_SecondaryDwelling", Vector3(-3.0, 7.0, 216.0), 6.0, 4.0, Color(0.34, 0.36, 0.33, 1.0), Color(0.22, 0.25, 0.24, 1.0))
	_add_lighthouse(root, "A_ExposedCoastLandmark", Vector3(-52.0, 17.0, 228.0), Color(0.63, 0.65, 0.59, 1.0))
	_add_shore_strip(root, "A_RockyLanding", Vector3(-11.0, 0.25, 184.0), Vector3(30.0, 0.4, 7.0), Color(0.38, 0.40, 0.37, 1.0))
	_add_collision_box("A_LandCollision", Vector3(112.0, 28.0, 60.0), Vector3(0.0, 12.0, 215.0))


func _build_destination_b() -> void:
	var root := Node3D.new()
	root.name = "DestinationB_ShelteredInhabitedCoast"
	root.set_meta("role", "sheltered inhabited coast and working harbor")
	root.set_meta("asset_status", "BLOCKOUT_WITH_V2FUN_WORKING_ASSET")
	visual_root.add_child(root)

	_add_terrain_mass(root, "B_ShelteredHeadland_L", Vector3(-48.0, 0.0, -183.0), Vector3(68.0, 13.0, 78.0), 3.0, 11.0, _material(Color(0.29, 0.34, 0.34, 1.0)), _material(Color(0.28, 0.40, 0.30, 1.0)))
	_add_terrain_mass(root, "B_ShelteredHeadland_R", Vector3(49.0, 0.0, -181.0), Vector3(62.0, 11.0, 72.0), 3.0, 9.0, _material(Color(0.27, 0.32, 0.33, 1.0)), _material(Color(0.28, 0.39, 0.30, 1.0)))
	_add_terrain_mass(root, "B_HarborBackSlope", Vector3(0.0, 0.0, -221.0), Vector3(84.0, 20.0, 35.0), 8.0, 16.0, _material(Color(0.25, 0.30, 0.31, 1.0)), _material(Color(0.31, 0.43, 0.31, 1.0)))
	_add_terrain_mass(root, "B_InhabitedSlope", Vector3(0.0, 1.0, -201.0), Vector3(55.0, 11.0, 42.0), 2.0, 8.0, _material(Color(0.32, 0.37, 0.35, 1.0)), _material(Color(0.36, 0.46, 0.32, 1.0)))
	_add_house_proxy(root, "B_House_Upper", Vector3(-13.0, 8.0, -218.0), 6.0, 4.0, Color(0.54, 0.48, 0.38, 1.0), Color(0.22, 0.23, 0.22, 1.0))
	_add_house_proxy(root, "B_House_Mid", Vector3(2.0, 5.0, -208.0), 5.0, 3.6, Color(0.49, 0.45, 0.37, 1.0), Color(0.20, 0.22, 0.22, 1.0))
	_mount_v2fun(root, SHED_ASSET, "B_HarborFishingShed", Vector3(15.0, 2.4, -190.0))
	_add_pier(root, "B_WorkingPier", Vector3(6.0, 0.55, -192.0))
	_add_breakwater(root, "B_RockBreakwater", Vector3(25.0, 1.0, -182.0))
	_add_lighthouse(root, "B_HarborLandmark", Vector3(-28.0, 12.0, -221.0), Color(0.68, 0.64, 0.54, 1.0))
	_add_shore_strip(root, "B_ShelteredShore", Vector3(0.0, 0.20, -177.0), Vector3(28.0, 0.35, 5.0), Color(0.43, 0.40, 0.33, 1.0))
	_add_small_cargo(root, "B_CargoStaging", Vector3(10.0, 1.0, -188.0))
	_add_collision_box("B_LeftLandCollision", Vector3(62.0, 24.0, 86.0), Vector3(-49.0, 10.0, -190.0))
	_add_collision_box("B_RightLandCollision", Vector3(55.0, 20.0, 78.0), Vector3(49.0, 9.0, -190.0))
	_add_collision_box("B_BackLandCollision", Vector3(88.0, 28.0, 30.0), Vector3(0.0, 14.0, -222.0))


func _build_world_boundary_proxies() -> void:
	# A lightweight soft boundary is enforced in _process. These invisible
	# StaticBody proxies document the future collision layer without creating a
	# physics dependency for the existing Node3D boat controller.
	var root := Node3D.new()
	root.name = "PlayableWorldBoundary_SoftProxy"
	root.set_meta("purpose", "soft world limit; replace later with geography/fog")
	collision_root.add_child(root)
	_add_collision_box_to(root, "WorldWestBoundary", Vector3(1.0, 20.0, 470.0), Vector3(-WORLD_HALF_WIDTH, 10.0, 0.0))
	_add_collision_box_to(root, "WorldEastBoundary", Vector3(1.0, 20.0, 470.0), Vector3(WORLD_HALF_WIDTH, 10.0, 0.0))
	_add_collision_box_to(root, "WorldFrontBoundary", Vector3(184.0, 20.0, 1.0), Vector3(0.0, 10.0, WORLD_FRONT_Z))
	_add_collision_box_to(root, "WorldBackBoundary", Vector3(184.0, 20.0, 1.0), Vector3(0.0, 10.0, WORLD_BACK_Z))


func _mount_v2fun(parent: Node3D, asset_path: String, instance_name: String, position: Vector3) -> void:
	var model := _load_glb_runtime(asset_path)
	if model == null:
		return
	model.name = instance_name + "_WORKING_B"
	model.position = position
	model.scale = Vector3.ONE * V2FUN_BUILDING_SCALE
	model.set_meta("asset_status", "V2FUN_WORKING_DERIVATIVE_PASS_THROUGH")
	model.set_meta("source_path", asset_path)
	model.set_meta("scene_instance_scale", V2FUN_BUILDING_SCALE)
	parent.add_child(model)


func _load_glb_runtime(asset_path: String) -> Node3D:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error := document.append_from_file(ProjectSettings.globalize_path(asset_path), state)
	if error != OK:
		push_error("Runtime GLB load failed (%s): %s" % [error, asset_path])
		return null
	var generated := document.generate_scene(state)
	var model := generated as Node3D
	if model == null:
		if generated != null:
			generated.free()
		push_error("Runtime GLB did not generate Node3D: " + asset_path)
		return null
	return model


func _add_terrain_mass(parent: Node3D, node_name: String, position: Vector3, size: Vector3, near_height: float, far_height: float, base_material: Material, cap_material: Material) -> void:
	var base := MeshInstance3D.new()
	base.name = node_name + "_ROCK_BASE_PROXY"
	base.mesh = _make_wedge_mesh(size, near_height, far_height)
	base.position = position
	base.material_override = base_material
	parent.add_child(base)
	var cap := MeshInstance3D.new()
	cap.name = node_name + "_TURF_CAP_PROXY"
	cap.mesh = _make_wedge_mesh(Vector3(size.x * 0.92, size.y * 0.55, size.z * 0.88), maxf(near_height - 1.2, 0.5), maxf(far_height - 1.0, 0.8))
	cap.position = position + Vector3(0.0, maxf(near_height * 0.45, 0.8), 0.0)
	cap.material_override = cap_material
	parent.add_child(cap)


func _make_wedge_mesh(size: Vector3, near_height: float, far_height: float) -> ArrayMesh:
	var half_width := size.x * 0.5
	var half_depth := size.z * 0.5
	var vertices := PackedVector3Array([
		Vector3(-half_width, 0.0, -half_depth), Vector3(half_width, 0.0, -half_depth),
		Vector3(half_width, 0.0, half_depth), Vector3(-half_width, 0.0, half_depth),
		Vector3(-half_width, far_height, -half_depth), Vector3(half_width, far_height, -half_depth),
		Vector3(half_width, near_height, half_depth), Vector3(-half_width, near_height, half_depth),
	])
	var indices := PackedInt32Array([0, 2, 1, 0, 3, 2, 4, 5, 6, 4, 6, 7, 0, 1, 5, 0, 5, 4, 3, 6, 2, 3, 7, 6, 0, 4, 7, 0, 7, 3, 1, 2, 6, 1, 6, 5])
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _add_house_proxy(parent: Node3D, node_name: String, position: Vector3, width: float, height: float, wall_color: Color, roof_color: Color) -> void:
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
	roof.mesh = _make_gable_roof(width * 1.15, width * 0.92, height * 0.42)
	roof.position.y = height
	roof.material_override = _material(roof_color)
	root.add_child(roof)


func _make_gable_roof(width: float, depth: float, height: float) -> ArrayMesh:
	var w := width * 0.5
	var d := depth * 0.5
	var vertices := PackedVector3Array([
		Vector3(-w, 0.0, -d), Vector3(w, 0.0, -d), Vector3(0.0, height, -d),
		Vector3(-w, 0.0, d), Vector3(w, 0.0, d), Vector3(0.0, height, d),
	])
	var indices := PackedInt32Array([0, 1, 2, 4, 3, 5, 0, 3, 4, 0, 4, 1, 2, 1, 4, 2, 4, 5, 0, 2, 5, 0, 5, 3])
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _add_lighthouse(parent: Node3D, node_name: String, position: Vector3, body_color: Color) -> void:
	var root := Node3D.new()
	root.name = node_name + "_PROXY"
	root.position = position
	parent.add_child(root)
	var tower := MeshInstance3D.new()
	tower.name = "Tower"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.42
	cylinder.bottom_radius = 0.75
	cylinder.height = 7.5
	cylinder.radial_segments = 8
	tower.mesh = cylinder
	tower.position.y = 3.75
	tower.material_override = _material(body_color)
	root.add_child(tower)
	var cap := MeshInstance3D.new()
	cap.name = "Cap"
	var cap_mesh := CylinderMesh.new()
	cap_mesh.top_radius = 0.0
	cap_mesh.bottom_radius = 0.85
	cap_mesh.height = 1.3
	cap_mesh.radial_segments = 8
	cap.mesh = cap_mesh
	cap.position.y = 8.15
	cap.material_override = _material(Color(0.24, 0.28, 0.28, 1.0))
	root.add_child(cap)


func _add_pier(parent: Node3D, node_name: String, position: Vector3) -> void:
	var root := Node3D.new()
	root.name = node_name + "_PROXY"
	root.position = position
	parent.add_child(root)
	for index in range(4):
		var plank := MeshInstance3D.new()
		plank.name = "Plank_%02d" % index
		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.4, 0.38, 8.0)
		plank.mesh = mesh
		plank.position = Vector3(float(index) * 1.7 - 2.6, 0.0, float(index) * -2.0)
		plank.material_override = _material(Color(0.27, 0.22, 0.17, 1.0))
		root.add_child(plank)


func _add_breakwater(parent: Node3D, node_name: String, position: Vector3) -> void:
	var root := Node3D.new()
	root.name = node_name + "_PROXY"
	root.position = position
	parent.add_child(root)
	_add_rock_cluster(root, "Rocks", Vector3.ZERO, 7, 1.0, 3.0)


func _add_rock_cluster(parent: Node3D, node_name: String, position: Vector3, count: int, min_radius: float, max_radius: float) -> void:
	var root := Node3D.new()
	root.name = node_name
	root.position = position
	parent.add_child(root)
	for index in range(count):
		var rock := MeshInstance3D.new()
		rock.name = "Rock_%02d" % index
		var mesh := SphereMesh.new()
		var radius := lerpf(min_radius, max_radius, float(index % 4) / 3.0)
		mesh.radius = radius
		mesh.height = radius * 1.35
		mesh.radial_segments = 6
		mesh.rings = 3
		rock.mesh = mesh
		rock.position = Vector3(float(index) * 2.3 - float(count) * 1.1, radius * 0.45, float(index % 2) * 2.0 - 1.0)
		rock.scale = Vector3(1.0, 0.7, 0.85)
		rock.material_override = _material(Color(0.30, 0.34, 0.34, 1.0))
		root.add_child(rock)


func _add_shore_strip(parent: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color) -> void:
	var strip := MeshInstance3D.new()
	strip.name = node_name + "_PROXY"
	var mesh := BoxMesh.new()
	mesh.size = size
	strip.mesh = mesh
	strip.position = position
	strip.material_override = _material(color)
	parent.add_child(strip)


func _add_small_cargo(parent: Node3D, node_name: String, position: Vector3) -> void:
	var cargo := MeshInstance3D.new()
	cargo.name = node_name + "_PROXY"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.2, 1.0, 1.5)
	cargo.mesh = mesh
	cargo.position = position
	cargo.material_override = _material(Color(0.39, 0.30, 0.21, 1.0))
	parent.add_child(cargo)


func _add_collision_box(node_name: String, size: Vector3, position: Vector3) -> void:
	_add_collision_box_to(collision_root, node_name, size, position)


func _add_collision_box_to(parent: Node3D, node_name: String, size: Vector3, position: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.position = position
	body.add_child(shape)
	parent.add_child(body)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.roughness = 1.0
	return material


func _set_initial_boat_pose() -> void:
	regional_system.call("_set_boat_pose", Vector3(0.0, 0.28, ROUTE_START_Z), 0.0, 0.0)


func _boat_position() -> Vector3:
	var boat := regional_system.get("boat_visual") as Node3D
	return boat.position if boat != null else Vector3.ZERO


func _process(_delta: float) -> void:
	if regional_system == null:
		return
	var boat := regional_system.get("boat_visual") as Node3D
	if boat == null:
		return
	if not capture_mode:
		_enforce_soft_world_limits(boat)
	last_safe_boat_position = boat.position if not _is_blocked_by_proxy_land(boat.position) else last_safe_boat_position


func _enforce_soft_world_limits(boat: Node3D) -> void:
	var position := boat.position
	var clamped := position
	var outside := false
	if absf(position.x) > WORLD_HALF_WIDTH - 3.0:
		clamped.x = signf(position.x) * (WORLD_HALF_WIDTH - 3.0)
		outside = true
	if position.z > WORLD_FRONT_Z - 3.0 or position.z < WORLD_BACK_Z + 3.0:
		clamped.z = clampf(position.z, WORLD_BACK_Z + 3.0, WORLD_FRONT_Z - 3.0)
		outside = true
	if _is_blocked_by_proxy_land(position):
		clamped = last_safe_boat_position
		outside = true
	if outside:
		boat.position = clamped
		regional_system.set("boat_speed", 0.0)


func _is_blocked_by_proxy_land(position: Vector3) -> bool:
	# Broad, low-cost navigation masks. The central harbor channel remains open.
	var z := position.z
	var x := absf(position.x)
	if z >= 184.0 and z <= 235.0 and x > 21.0:
		return true
	if z >= -226.0 and z <= -144.0 and x > 17.0:
		return true
	if z < -226.0:
		return true
	return false


func _capture_world_sequence() -> void:
	var root := ProjectSettings.globalize_path(CAPTURE_ROOT)
	DirAccess.make_dir_recursive_absolute(root)
	var captures := [
		{"file": "01_departure_A.png", "position": Vector3(0.0, 0.28, ROUTE_START_Z), "yaw": 0.0},
		{"file": "02_open_sea.png", "position": Vector3(0.0, 0.28, 78.0), "yaw": 0.0},
		{"file": "03_first_distant_read_B.png", "position": Vector3(0.0, 0.28, 15.0), "yaw": 0.0},
		{"file": "04_approach_B.png", "position": Vector3(0.0, 0.28, -92.0), "yaw": 0.0},
		{"file": "05_harbor_entry_B.png", "position": Vector3(0.0, 0.28, -151.0), "yaw": 0.0},
		{"file": "06_arrival_B.png", "position": Vector3(0.0, 0.28, -174.0), "yaw": 0.0},
		{"file": "07_reverse_view.png", "position": Vector3(0.0, 0.28, -174.0), "yaw": PI},
	]
	for capture in captures:
		regional_system.call("_set_boat_pose", capture["position"], capture["yaw"], 0.0)
		regional_system.call("_set_camera_view", "overview")
		await _settle_frames(20)
		var image := get_viewport().get_texture().get_image()
		if image == null:
			push_error("Playable world capture image unavailable.")
			continue
		var path := root.path_join(String(capture["file"]))
		var error := image.save_png(path)
		if error != OK:
			push_error("Could not save playable world capture: " + path)
		else:
			print("PLAYABLE_WORLD_CAPTURE=%s" % path)
	print("PLAYABLE_WORLD_CAPTURE_COMPLETE|route_distance_m=%d|root=%s" % [ROUTE_DISTANCE_M, root])
	get_tree().quit()


func _settle_frames(frame_count: int) -> void:
	for _frame in range(frame_count):
		await get_tree().process_frame

