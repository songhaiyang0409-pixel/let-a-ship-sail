extends Node3D

## Overnight playable world: isolated A -> B production slice.
## Reuses RegionalOceanSystem for all sailing, camera, B+ V3 waves, coupling,
## and wake. This script only builds the temporary world around that system.

const VIEWPORT_SIZE := Vector2i(1152, 648)
const CAPTURE_ROOT := "res://scenes/staging/reconstruction_04_captures"
const START_Z := 160.0
const END_Z := -175.0
const ROUTE_M := START_Z - END_Z
const NORMAL_SPEED := 2.2
const TEST_SPEED := 5.0
const BUILDING_SCALE := 6.8
const WORLD_X := 92.0
const WORLD_FRONT := 235.0
const WORLD_BACK := -240.0
const COTTAGE := "res://V2FUN_INBOX/working/Faroe_Turf_Roof_Cottage__V2FUN__7e3dd2ee.glb"
const SHED := "res://V2FUN_INBOX/working/Harbor_Fishing_Shed__V2FUN__68c336dd.glb"

var canonical: Node3D
var ocean: Node3D
var visual_root: Node3D
var collision_root: Node3D
var last_safe_position := Vector3.ZERO
var capture_mode := false
var arrival_state := false
var arrival_lights: Array[OmniLight3D] = []


func _ready() -> void:
	_configure_viewport()
	capture_mode = OS.get_cmdline_user_args().has("--capture-overnight-world-reconstruction-04")
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
	_configure_route()
	_hide_old_proxies()
	_build_world()
	_mount_v2fun_assets()
	ocean.call("_set_boat_pose", Vector3(0.0, 0.28, START_Z), 0.0, 0.0)
	last_safe_position = _boat_position()
	print("NORTH_ATLANTIC_RECONSTRUCTION_04_READY|route_m=%d|normal_seconds=%.1f|test_seconds=%.1f|v2fun_scale=%.1f|formal_project_modified=false" % [ROUTE_M, ROUTE_M / NORMAL_SPEED, ROUTE_M / TEST_SPEED, BUILDING_SCALE])
	if capture_mode:
		ocean.set("interactive_mode", false)
		ocean.set("capture_mode", false)
		ocean.set("observe_mode", false)
		call_deferred("_capture_sequence")


func _configure_viewport() -> void:
	var window := get_window()
	window.size = VIEWPORT_SIZE
	window.content_scale_size = VIEWPORT_SIZE
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED


func _configure_route() -> void:
	ocean.set("route_origin_z", -START_Z)
	ocean.set("transition_01_start", 52.0)
	ocean.set("transition_01_end", 84.0)
	ocean.set("transition_12_start", 126.0)
	ocean.set("transition_12_end", 170.0)
	ocean.set("transition_23_start", 238.0)
	ocean.set("transition_23_end", 292.0)
	ocean.set("coastal_test_mode", false)
	var water := ocean.get("water_mesh") as MeshInstance3D
	if water != null:
		water.scale = Vector3(1.25, 1.0, 3.6)
	var camera := ocean.get("camera") as Camera3D
	if camera != null:
		camera.far = 520.0
	var material := ocean.get("water_material") as ShaderMaterial
	if material != null:
		for item in [
			["route_origin_z", -START_Z], ["transition_01_start", 52.0], ["transition_01_end", 84.0],
			["transition_12_start", 126.0], ["transition_12_end", 170.0],
			["transition_23_start", 238.0], ["transition_23_end", 292.0],
		]:
			material.set_shader_parameter(String(item[0]), item[1])
		material.set_shader_parameter("coastal_local_enabled", false)


func _hide_old_proxies() -> void:
	for path in ["CoastalWaterProxyWorld_PLACEHOLDER", "SailingReferenceScaleReferences", "RegionalOceanRouteMarkers_TEST_ONLY"]:
		var node := ocean.get_node_or_null(path) as Node3D
		if node != null:
			node.visible = false


func _build_world() -> void:
	var root := Node3D.new()
	root.name = "NorthAtlanticPlayableWorld01_ISOLATED"
	root.set_meta("asset_status", "NORTH_ATLANTIC_RECONSTRUCTION_04")
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
	_build_destination_b()
	_add_boundaries()
	_build_environmental_navigation()


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


func _build_destination_b() -> void:
	var root := _new_region("DestinationB_ShelteredInhabitedCoast", "sheltered inhabited coast and working harbor")
	_add_landform(root, "B_West_ShelteredHeadland", -47.0, -178.0, -220.0, 23.0, 36.0, 14.0, 0.8, Color(0.27, 0.32, 0.33, 1.0), Color(0.27, 0.39, 0.28, 1.0))
	_add_landform(root, "B_East_ShelteredHeadland", 47.0, -180.0, -218.0, 22.0, 34.0, 12.0, 2.4, Color(0.25, 0.30, 0.32, 1.0), Color(0.25, 0.38, 0.28, 1.0))
	_add_landform(root, "B_InhabitedBackSlope", 0.0, -209.0, -236.0, 16.0, 29.0, 10.0, 4.2, Color(0.27, 0.31, 0.30, 1.0), Color(0.28, 0.39, 0.25, 1.0))
	_add_landform(root, "B_WestHarborArm", -25.0, -177.0, -202.0, 7.0, 10.0, 4.2, 1.1, Color(0.29, 0.32, 0.32, 1.0), Color(0.25, 0.37, 0.27, 1.0))
	_add_landform(root, "B_EastHarborArm", 25.0, -178.0, -202.0, 7.0, 10.0, 4.0, 2.7, Color(0.28, 0.31, 0.31, 1.0), Color(0.24, 0.36, 0.26, 1.0))
	_add_landform(root, "B_HarborWorkingBank", 5.0, -181.0, -206.0, 8.5, 11.0, 2.5, 1.7, Color(0.30, 0.32, 0.31, 1.0), Color(0.29, 0.34, 0.25, 1.0))
	_add_shore(root, "B_WorkingHarborApron", Vector3(5.0, 0.48, -191.5), Vector3(15.0, 0.28, 5.2), Color(0.24, 0.22, 0.18, 1.0))
	_add_rock_shore(root, "B_ShelteredShore", Vector3(0.0, 0.20, -178.0), 36.0, 0.35, 1.6)
	_add_rock_shore(root, "B_BreakwaterRocks", Vector3(24.0, 0.65, -184.0), 16.0, 0.6, 2.8)
	_add_path(root, "B_DockToWarehousePath", Vector3(5.0, 0.65, -188.0), Vector3(5.0, 1.8, -198.0), 1.8, Color(0.35, 0.31, 0.25, 1.0))
	_add_house(root, "B_House_Upper", Vector3(-14.0, 7.0, -222.0), 6.0, 4.0, Color(0.49, 0.45, 0.37, 1.0), Color(0.20, 0.22, 0.22, 1.0))
	_add_house(root, "B_House_Mid", Vector3(4.0, 5.0, -214.0), 5.0, 3.6, Color(0.45, 0.42, 0.36, 1.0), Color(0.19, 0.21, 0.21, 1.0))
	_add_pier(root, "B_WorkingPier", Vector3(5.0, 0.55, -190.0))
	_add_lighthouse(root, "B_HarborLandmark", Vector3(-29.0, 9.0, -223.0))
	_add_cargo(root, "B_CargoStaging", Vector3(11.0, 1.0, -190.0))
	_add_shore(root, "B_InnerQuay", Vector3(10.5, 0.62, -201.0), Vector3(18.0, 0.42, 3.2), Color(0.25, 0.22, 0.18, 1.0))
	_add_house(root, "B_NetLoft", Vector3(18.0, 3.0, -205.0), 4.5, 3.2, Color(0.52, 0.28, 0.20, 1.0), Color(0.18, 0.20, 0.20, 1.0))
	_add_collision("B_LeftLandCollision", Vector3(58.0, 24.0, 45.0), Vector3(-48.0, 10.0, -199.0))
	_add_collision("B_RightLandCollision", Vector3(56.0, 22.0, 44.0), Vector3(48.0, 9.0, -199.0))
	_add_collision("B_BackLandCollision", Vector3(76.0, 28.0, 28.0), Vector3(0.0, 14.0, -224.0))


func _new_region(node_name: String, role: String) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	root.set_meta("role", role)
	root.set_meta("asset_status", "OVERNIGHT_BLOCKOUT")
	visual_root.add_child(root)
	return root


func _mount_v2fun_assets() -> void:
	var a := visual_root.get_node_or_null("DestinationA_ExposedNorthernCoast") as Node3D
	var b := visual_root.get_node_or_null("DestinationB_ShelteredInhabitedCoast") as Node3D
	if a != null:
		_mount_v2fun(a, COTTAGE, "A_FaroeTurfRoofCottage", Vector3(-20.0, 9.0, 207.0))
	if b != null:
		_mount_v2fun(b, SHED, "B_HarborFishingShed", Vector3(5.0, 2.0, -198.0))


func _mount_v2fun(parent: Node3D, path: String, node_name: String, position: Vector3) -> void:
	var model := _load_glb(path)
	if model == null:
		return
	model.name = node_name + "_WORKING_B"
	model.position = position
	model.scale = Vector3.ONE * BUILDING_SCALE
	model.set_meta("asset_status", "V2FUN_WORKING_DERIVATIVE_PASS_THROUGH")
	model.set_meta("source_path", path)
	model.set_meta("scene_instance_scale", BUILDING_SCALE)
	parent.add_child(model)


func _load_glb(path: String) -> Node3D:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error := document.append_from_file(ProjectSettings.globalize_path(path), state)
	if error != OK:
		push_error("GLB load failed (%s): %s" % [error, path])
		return null
	var generated := document.generate_scene(state)
	var model := generated as Node3D
	if model == null:
		if generated != null:
			generated.free()
		push_error("GLB did not generate Node3D: " + path)
		return null
	return model


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
	for index in range(6):
		var rock := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		var radius := 1.0 + float(index % 3) * 0.42
		mesh.radius = radius
		mesh.height = radius * 1.2
		mesh.radial_segments = 6
		mesh.rings = 2
		rock.mesh = mesh
		var t := float(index) / 5.0
		rock.position = center + Vector3((t - 0.5) * span, radius * 0.35, sin(phase + float(index) * 1.4) * 1.8)
		rock.scale = Vector3(1.25, height, 0.72)
		rock.material_override = _material(Color(0.31, 0.34, 0.33, 1.0))
		root.add_child(rock)


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


func _add_pier(parent: Node3D, node_name: String, position: Vector3) -> void:
	var root := Node3D.new()
	root.name = node_name + "_PROXY"
	root.position = position
	parent.add_child(root)
	for index in range(4):
		var plank := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.4, 0.38, 8.0)
		plank.mesh = mesh
		plank.position = Vector3(float(index) * 1.7 - 2.6, 0.0, float(index) * -2.0)
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


func _build_environmental_navigation() -> void:
	# Paired daymarks establish a readable dog-leg: enter left of center, then turn
	# toward the working quay. They are world objects, not HUD route markers.
	var b := visual_root.get_node_or_null("DestinationB_ShelteredInhabitedCoast") as Node3D
	if b == null:
		return
	_add_daymark(b, "B_OuterPortDaymark", Vector3(-18.0, 0.25, -158.0), Color(0.74, 0.24, 0.18, 1.0))
	_add_daymark(b, "B_OuterStarboardDaymark", Vector3(8.0, 0.25, -166.0), Color(0.86, 0.78, 0.48, 1.0))
	_add_daymark(b, "B_InnerTurnDaymark", Vector3(4.0, 0.25, -184.0), Color(0.74, 0.24, 0.18, 1.0))
	_add_daymark(b, "B_BerthDaymark", Vector3(15.0, 0.25, -196.0), Color(0.86, 0.78, 0.48, 1.0), true)


func _add_daymark(parent: Node3D, node_name: String, position: Vector3, color: Color, arrival_light := false) -> void:
	var root := Node3D.new()
	root.name = node_name
	root.position = position
	root.set_meta("navigation_role", "physical harbor daymark")
	parent.add_child(root)
	var post := MeshInstance3D.new()
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = 0.16
	post_mesh.bottom_radius = 0.22
	post_mesh.height = 2.8
	post_mesh.radial_segments = 8
	post.mesh = post_mesh
	post.position.y = 1.4
	post.material_override = _material(Color(0.24, 0.24, 0.22, 1.0))
	root.add_child(post)
	var board := MeshInstance3D.new()
	var board_mesh := BoxMesh.new()
	board_mesh.size = Vector3(0.95, 1.25, 0.22)
	board.mesh = board_mesh
	board.position.y = 3.05
	board.material_override = _material(color)
	root.add_child(board)
	if arrival_light:
		var lamp := OmniLight3D.new()
		lamp.name = "ArrivalLantern"
		lamp.position.y = 3.4
		lamp.light_color = Color(1.0, 0.68, 0.32, 1.0)
		lamp.light_energy = 0.0
		lamp.omni_range = 12.0
		root.add_child(lamp)
		arrival_lights.append(lamp)


func _update_arrival_feedback(position: Vector3) -> void:
	var in_berth := position.z < -190.0 and position.z > -208.0 and position.x > 4.0 and position.x < 20.0
	if in_berth:
		# A gentle berth assist prevents overshooting without changing steering or controls.
		var speed := float(ocean.get("boat_speed"))
		ocean.set("boat_speed", move_toward(speed, 0.0, 0.035))
	if in_berth == arrival_state:
		return
	arrival_state = in_berth
	for lamp in arrival_lights:
		lamp.light_energy = 2.2 if arrival_state else 0.0
	print("RECONSTRUCTION_04_ARRIVAL_STATE|arrived=%s|x=%.2f|z=%.2f" % [arrival_state, position.x, position.z])


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
	if ocean == null or capture_mode:
		return
	var boat := ocean.get("boat_visual") as Node3D
	if boat == null:
		return
	var position := boat.position
	_update_arrival_feedback(position)
	var blocked := _land_mask(position)
	var outside := absf(position.x) > WORLD_X - 3.0 or position.z > WORLD_FRONT - 3.0 or position.z < WORLD_BACK + 3.0
	if blocked or outside:
		boat.position = last_safe_position
		ocean.set("boat_speed", 0.0)
	else:
		last_safe_position = position


func _land_mask(position: Vector3) -> bool:
	var x := absf(position.x)
	var z := position.z
	if z >= 184.0 and z <= 235.0 and x > 21.0:
		return true
	if z >= -226.0 and z <= -144.0 and x > 17.0:
		return true
	return z < -226.0


func _capture_sequence() -> void:
	var root := ProjectSettings.globalize_path(CAPTURE_ROOT)
	DirAccess.make_dir_recursive_absolute(root)
	var captures := [
		["01_departure_A.png", Vector3(0.0, 0.28, START_Z), 0.0],
		["02_open_sea.png", Vector3(0.0, 0.28, 78.0), 0.0],
		["03_mid_voyage.png", Vector3(0.0, 0.28, 45.0), 0.0],
		["04_first_distant_read_B.png", Vector3(0.0, 0.28, 15.0), 0.0],
		["05_approach_B.png", Vector3(0.0, 0.28, -92.0), 0.0],
		["06_harbor_entry_B.png", Vector3(-10.0, 0.28, -158.0), -0.18],
		["07_inner_harbor_turn.png", Vector3(1.0, 0.28, -181.0), -0.55],
		["08_arrival_B.png", Vector3(11.0, 0.28, -195.0), -0.35],
		["09_reverse_view.png", Vector3(11.0, 0.28, -195.0), PI],
	]
	for item in captures:
		ocean.call("_set_boat_pose", item[1], item[2], 0.0)
		ocean.call("_set_camera_view", "overview")
		await _settle(20)
		var image := get_viewport().get_texture().get_image()
		if image != null:
			image.save_png(root.path_join(String(item[0])))
	print("RECONSTRUCTION_04_CAPTURE_COMPLETE|route_distance_m=%d|root=%s" % [ROUTE_M, root])
	get_tree().quit()


func _settle(count: int) -> void:
	for _frame in range(count):
		await get_tree().process_frame

