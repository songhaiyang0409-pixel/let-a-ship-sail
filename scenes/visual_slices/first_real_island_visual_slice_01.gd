extends Node3D

## FIRST REAL ISLAND VISUAL SLICE 01
##
## This is an isolated presentation/playability slice. The canonical
## SailingReferenceScene owns the B+ V3 water, boat visual, wave coupling,
## camera, and keyboard/mouse sailing. This script only assembles a replaceable
## island visual layer around that reference scene.

const CAPTURE_DIR := "res://scenes/visual_slices/first_real_island_visual_slice_01_captures"
const VIEWPORT_SIZE := Vector2i(1152, 648)
const KAYKIT_ROOT := "res://assets/3d/environment/kaykit_forest_cc0/"

const KAYKIT_TREES := [
	"Tree_1_A_Color1.gltf",
	"Tree_1_B_Color1.gltf",
	"Tree_Bare_1_A_Color1.gltf",
]
const KAYKIT_BUSHES := [
	"Bush_1_A_Color1.gltf",
	"Bush_1_B_Color1.gltf",
]

const LAND_GREEN := Color(0.10, 0.20, 0.14, 1.0)
const LAND_GREEN_LIGHT := Color(0.15, 0.24, 0.14, 1.0)
const LAND_SHADOW := Color(0.07, 0.13, 0.13, 1.0)
const ROCK_GREY := Color(0.16, 0.20, 0.20, 1.0)
const ROCK_LIGHT := Color(0.24, 0.25, 0.22, 1.0)
const WOOD_DARK := Color(0.22, 0.18, 0.14, 1.0)
const BEACON_WARM := Color(0.83, 0.72, 0.55, 1.0)
const BEACON_CAP := Color(0.43, 0.18, 0.13, 1.0)

var reference_instance: Node3D
var regional_system: Node3D
var island_visual_root: Node3D
var terrain_root: Node3D
var rock_root: Node3D
var vegetation_root: Node3D
var harbor_root: Node3D
var landmark_root: Node3D
var building_locations_root: Node3D
var natural_only := false


func _ready() -> void:
	_configure_viewport()
	reference_instance = get_node_or_null("SailingReferenceScene") as Node3D
	await get_tree().process_frame
	await get_tree().process_frame
	if reference_instance == null:
		push_error("FirstRealIslandVisualSlice01 cannot find SailingReferenceScene.")
		return
	regional_system = reference_instance.get_node_or_null("RegionalOceanSystem") as Node3D
	if regional_system == null:
		push_error("FirstRealIslandVisualSlice01 cannot find RegionalOceanSystem.")
		return
	for _frame in range(60):
		if regional_system.get("boat_visual") != null:
			break
		await get_tree().process_frame
	if regional_system.get("boat_visual") == null:
		push_error("FirstRealIslandVisualSlice01 timed out waiting for the canonical boat visual.")
		return
	island_visual_root = get_node("IslandVisualRoot")
	terrain_root = island_visual_root.get_node("TerrainRoot")
	rock_root = island_visual_root.get_node("RockRoot")
	vegetation_root = island_visual_root.get_node("VegetationRoot")
	harbor_root = island_visual_root.get_node("HarborRoot")
	landmark_root = island_visual_root.get_node("LandmarkRoot")
	building_locations_root = island_visual_root.get_node("FutureBuildingLocations")
	_hide_old_proxy_layers()
	_build_island_visual_layer()
	_build_future_building_locations()
	natural_only = OS.get_cmdline_user_args().has("--natural-only") or OS.get_cmdline_user_args().has("--capture-first-real-island-natural-pass-02")
	if natural_only:
		_set_natural_only(true)
	print("FIRST_REAL_ISLAND_SLICE_READY|isolated=true|water_owner=SailingReferenceScene|boat_control_owner=RegionalOceanSystem|asset_source=KayKit_CC0|formal_project_modified=false")
	if OS.get_cmdline_user_args().has("--capture-first-real-island-natural-pass-02"):
		call_deferred("_capture_natural_pass_02")
	if OS.get_cmdline_user_args().has("--capture-first-real-island-slice"):
		call_deferred("_capture_all")


func _configure_viewport() -> void:
	var window := get_window()
	window.size = VIEWPORT_SIZE
	window.content_scale_size = VIEWPORT_SIZE
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED


func _hide_old_proxy_layers() -> void:
	var proxy := regional_system.get("coastal_world_root") as Node3D
	if proxy != null:
		proxy.visible = false
		proxy.set_meta("hidden_by_slice", true)
	var scale_refs := regional_system.get("scale_reference_root") as Node3D
	if scale_refs != null:
		scale_refs.visible = false


func _build_island_visual_layer() -> void:
	island_visual_root.set_meta("asset_status", "NATURAL_WORLD_PASS_02_WITH_PLACEHOLDER_MANMADE_LAYER")
	island_visual_root.set_meta("visual_only", true)
	# Natural land is deliberately built in two readable strata: exposed grey rock
	# at the waterline, with a smaller green upper landform seated above it.
	_add_natural_headland("WestHeadland", Vector3(-31.0, 0.0, -28.0), Vector3(38.0, 7.0, 27.0), LAND_GREEN)
	_add_natural_headland("EastHeadland", Vector3(31.0, 0.0, -28.0), Vector3(38.0, 6.6, 27.0), LAND_GREEN_LIGHT)
	_add_natural_headland("HarborBackRise", Vector3(0.0, 0.0, -76.0), Vector3(43.0, 6.8, 18.0), LAND_GREEN)
	_add_mound(terrain_root, "WestInnerSlope_PLACEHOLDER", Vector3(-20.0, 0.15, -48.0), Vector3(17.0, 4.0, 15.0), LAND_SHADOW, 0.86)
	_add_mound(terrain_root, "EastInnerSlope_PLACEHOLDER", Vector3(20.0, 0.15, -48.0), Vector3(17.0, 3.8, 15.0), LAND_SHADOW, 0.92)

	# KayKit is used as a small curated natural set, not as random scatter.
	var west_grove := _add_group(vegetation_root, "WestShelteredGrove")
	_add_kaykit_asset(west_grove, KAYKIT_ROOT + KAYKIT_TREES[0], "Tree_WestGrove_A", Vector3(-35.0, 3.5, -37.0), 1.26, 0.12)
	_add_kaykit_asset(west_grove, KAYKIT_ROOT + KAYKIT_TREES[1], "Tree_WestGrove_B", Vector3(-29.0, 3.0, -40.5), 1.08, -0.20)
	_add_kaykit_asset(west_grove, KAYKIT_ROOT + KAYKIT_BUSHES[0], "Bush_WestGrove", Vector3(-32.0, 2.25, -35.0), 2.15, 0.0)
	var east_grove := _add_group(vegetation_root, "EastShelteredGrove")
	_add_kaykit_asset(east_grove, KAYKIT_ROOT + KAYKIT_TREES[0], "Tree_EastGrove_A", Vector3(35.0, 3.3, -37.0), 1.18, 0.48)
	_add_kaykit_asset(east_grove, KAYKIT_ROOT + KAYKIT_TREES[1], "Tree_EastGrove_B", Vector3(29.0, 3.0, -42.0), 1.04, -0.38)
	_add_kaykit_asset(east_grove, KAYKIT_ROOT + KAYKIT_BUSHES[1], "Bush_EastGrove", Vector3(32.0, 2.1, -35.0), 2.05, 0.45)
	var windward_group := _add_group(vegetation_root, "WindwardSparseVegetation")
	_add_kaykit_asset(windward_group, KAYKIT_ROOT + KAYKIT_TREES[2], "Tree_WindwardBare", Vector3(-8.5, 4.9, -70.0), 1.42, 0.05)
	_add_kaykit_asset(windward_group, KAYKIT_ROOT + KAYKIT_BUSHES[0], "Bush_Windward", Vector3(7.0, 4.0, -72.5), 1.9, -0.35)

	# Rocks define the irregular shoreline and the protected harbor mouth.
	_add_boulder(rock_root, "Rock_WestOuterHeadland", Vector3(-49.0, 1.25, -13.5), Vector3(4.0, 1.7, 2.8), ROCK_LIGHT, 0.18)
	_add_boulder(rock_root, "Rock_WestShoreCluster", Vector3(-43.0, 0.95, -12.0), Vector3(3.3, 1.35, 2.3), ROCK_GREY, -0.34)
	_add_boulder(rock_root, "Rock_WestInnerShore", Vector3(-38.5, 1.4, -24.0), Vector3(3.5, 1.6, 2.6), ROCK_LIGHT, 0.42)
	_add_boulder(rock_root, "Rock_WestHarborMouth", Vector3(-17.5, 1.0, -27.0), Vector3(3.0, 1.25, 2.2), ROCK_GREY, -0.55)
	_add_boulder(rock_root, "Rock_EastOuterHeadland", Vector3(49.0, 1.25, -13.5), Vector3(3.9, 1.65, 2.7), ROCK_LIGHT, 0.50)
	_add_boulder(rock_root, "Rock_EastShoreCluster", Vector3(43.0, 0.95, -12.0), Vector3(3.2, 1.3, 2.3), ROCK_GREY, -0.24)
	_add_boulder(rock_root, "Rock_EastInnerShore", Vector3(38.5, 1.4, -24.0), Vector3(3.4, 1.55, 2.5), ROCK_LIGHT, 0.32)
	_add_boulder(rock_root, "Rock_EastHarborMouth", Vector3(17.5, 1.0, -27.0), Vector3(3.0, 1.2, 2.1), ROCK_GREY, 0.70)
	_add_boulder(rock_root, "Rock_BackHarborWest", Vector3(-14.0, 1.5, -56.0), Vector3(2.8, 1.25, 2.2), ROCK_GREY, -0.18)
	_add_boulder(rock_root, "Rock_BackHarborEast", Vector3(14.0, 1.4, -56.5), Vector3(2.7, 1.2, 2.1), ROCK_GREY, 0.34)

	_add_box(harbor_root, "PierDeck_PLACEHOLDER", Vector3(2.6, 0.22, 8.0), Vector3(0.0, 0.27, -36.0), WOOD_DARK)
	_add_box(harbor_root, "PierEnd_PLACEHOLDER", Vector3(3.8, 0.28, 1.2), Vector3(0.0, 0.38, -40.0), WOOD_DARK)

	_add_house_placeholder(terrain_root, "HouseSite_West_PLACEHOLDER", Vector3(-8.0, 3.0, -61.0), 1.0)
	_add_house_placeholder(terrain_root, "HouseSite_Center_PLACEHOLDER", Vector3(0.0, 3.2, -66.0), 0.92)
	_add_house_placeholder(terrain_root, "HouseSite_East_PLACEHOLDER", Vector3(8.0, 3.0, -61.0), 1.05)
	_add_landmark()


func _build_future_building_locations() -> void:
	for item in [
		{"name": "FutureHouseSite_A", "position": Vector3(-8.0, 3.0, -61.0)},
		{"name": "FutureHouseSite_B", "position": Vector3(0.0, 3.2, -66.0)},
		{"name": "FutureHouseSite_C", "position": Vector3(8.0, 3.0, -61.0)},
		{"name": "FutureHarborBuildingSite_D", "position": Vector3(-5.5, 1.0, -45.0)},
	]:
		var marker := Node3D.new()
		marker.name = String(item["name"])
		marker.position = item["position"]
		marker.set_meta("reserved_only", true)
		building_locations_root.add_child(marker)


func _set_natural_only(hidden: bool) -> void:
	landmark_root.visible = not hidden
	building_locations_root.visible = not hidden
	for child in terrain_root.get_children():
		if child.name.contains("HouseSite"):
			child.visible = not hidden
	# The pier remains visible: it is a restrained spatial cue for the harbor,
	# while buildings and high landmarks are the layers being tested as hidden.
	natural_only = hidden


func _add_group(parent: Node3D, group_name: String) -> Node3D:
	var group := Node3D.new()
	group.name = group_name
	group.set_meta("asset_status", "CURATED_NATURAL_GROUP")
	parent.add_child(group)
	return group


func _add_natural_headland(prefix: String, position: Vector3, size: Vector3, green_color: Color) -> void:
	_add_mound(terrain_root, prefix + "_ExposedRockBase_PLACEHOLDER", position, size, ROCK_GREY, 1.0)
	_add_mound(terrain_root, prefix + "_GreenUpperLand_PLACEHOLDER", position + Vector3(0.0, 1.15, 1.9), Vector3(size.x * 0.72, size.y * 0.94, size.z * 0.72), green_color, 1.0)


func _add_boulder(parent: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color, yaw: float) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = node_name
	var mesh := SphereMesh.new()
	mesh.radial_segments = 7
	mesh.rings = 3
	mesh.radius = 0.5
	mesh.height = 1.0
	item.mesh = mesh
	item.position = position
	item.rotation.y = yaw
	item.scale = size
	item.material_override = _make_material(color)
	item.set_meta("asset_status", "PLACEHOLDER_LOW_POLY_COASTAL_BOULDER")
	parent.add_child(item)
	return item


func _add_mound(parent: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color, ridge_bias: float) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = node_name
	var mesh := ArrayMesh.new()
	var vertices := PackedVector3Array()
	var lower_indices := PackedInt32Array()
	var upper_indices := PackedInt32Array()
	var ring_angles := [0.0, 0.785, 1.57, 2.356, 3.142, 3.927, 4.712, 5.498]
	var irregular := [1.0, 0.91, 1.06, 0.94, 1.02, 0.88, 1.08, 0.95]
	for angle_index in range(ring_angles.size()):
		var angle: float = ring_angles[angle_index]
		var radius: float = irregular[angle_index]
		vertices.append(Vector3(cos(angle) * size.x * 0.5 * radius, 0.0, sin(angle) * size.z * 0.5 * radius))
	for angle_index in range(ring_angles.size()):
		var angle: float = ring_angles[angle_index]
		var radius: float = irregular[angle_index]
		var middle_height: float = size.y * (0.38 + 0.12 * sin(angle + ridge_bias))
		vertices.append(Vector3(cos(angle) * size.x * 0.38 * radius, middle_height, sin(angle) * size.z * 0.38 * radius))
	vertices.append(Vector3(-size.x * 0.10 * ridge_bias, size.y, -size.z * 0.16))
	var top_index := vertices.size() - 1
	for angle_index in range(ring_angles.size()):
		var next := (angle_index + 1) % ring_angles.size()
		lower_indices.append_array([angle_index, next, 8 + angle_index, next, 8 + next, 8 + angle_index])
		upper_indices.append_array([8 + angle_index, 8 + next, top_index])
	var lower_arrays := []
	lower_arrays.resize(Mesh.ARRAY_MAX)
	lower_arrays[Mesh.ARRAY_VERTEX] = vertices
	lower_arrays[Mesh.ARRAY_INDEX] = lower_indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, lower_arrays)
	mesh.surface_set_material(0, _make_natural_material(color.darkened(0.18)))
	var upper_arrays := []
	upper_arrays.resize(Mesh.ARRAY_MAX)
	upper_arrays[Mesh.ARRAY_VERTEX] = vertices
	upper_arrays[Mesh.ARRAY_INDEX] = upper_indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, upper_arrays)
	mesh.surface_set_material(1, _make_natural_material(color.lightened(0.06)))
	item.mesh = mesh
	item.position = position
	item.material_override = _make_material(color)
	item.set_meta("asset_status", "PLACEHOLDER_NATURAL_MOUND")
	parent.add_child(item)
	return item


func _add_landmark() -> void:
	var tower := MeshInstance3D.new()
	tower.name = "WindwardBeacon_PLACEHOLDER"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.42
	mesh.bottom_radius = 0.72
	mesh.height = 6.0
	mesh.radial_segments = 8
	tower.mesh = mesh
	tower.position = Vector3(-8.5, 8.0, -70.0)
	tower.material_override = _make_material(BEACON_WARM)
	landmark_root.add_child(tower)
	var cap := MeshInstance3D.new()
	cap.name = "WindwardBeaconCap_PLACEHOLDER"
	var cap_mesh := CylinderMesh.new()
	cap_mesh.top_radius = 0.0
	cap_mesh.bottom_radius = 0.70
	cap_mesh.height = 0.65
	cap_mesh.radial_segments = 8
	cap.mesh = cap_mesh
	cap.position = Vector3(-8.5, 11.32, -70.0)
	cap.material_override = _make_material(BEACON_CAP)
	landmark_root.add_child(cap)


func _add_house_placeholder(parent: Node3D, node_name: String, position: Vector3, scale_value: float) -> void:
	var house := Node3D.new()
	house.name = node_name
	house.position = position
	house.scale = Vector3.ONE * scale_value
	house.set_meta("asset_status", "PLACEHOLDER_FUTURE_BUILDING_SITE")
	parent.add_child(house)
	_add_box(house, "Body", Vector3(2.5, 1.45, 2.15), Vector3(0.0, 0.72, 0.0), Color(0.35, 0.32, 0.27, 1.0))
	var roof := MeshInstance3D.new()
	roof.name = "GableRoof"
	var roof_mesh := ArrayMesh.new()
	var width := 1.48
	var depth := 1.30
	var ridge_height := 0.66
	var vertices := PackedVector3Array([
		Vector3(-width, 0.0, -depth), Vector3(width, 0.0, -depth),
		Vector3(width, 0.0, depth), Vector3(-width, 0.0, depth),
		Vector3(0.0, ridge_height, -depth), Vector3(0.0, ridge_height, depth),
	])
	var indices := PackedInt32Array([
		0, 1, 4, 3, 5, 2,
		0, 4, 5, 0, 5, 3,
		1, 2, 5, 1, 5, 4,
	])
	var roof_arrays := []
	roof_arrays.resize(Mesh.ARRAY_MAX)
	roof_arrays[Mesh.ARRAY_VERTEX] = vertices
	roof_arrays[Mesh.ARRAY_INDEX] = indices
	roof_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, roof_arrays)
	roof.mesh = roof_mesh
	roof.position.y = 1.48
	roof.material_override = _make_material(Color(0.15, 0.19, 0.18, 1.0))
	house.add_child(roof)


func _add_box(parent: Node3D, node_name: String, size: Vector3, position: Vector3, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.position = position
	item.material_override = _make_material(color)
	item.set_meta("asset_status", "PLACEHOLDER_PRODUCTION_LAYOUT")
	parent.add_child(item)
	return item


func _add_kaykit_asset(parent: Node3D, resource_path: String, node_name: String, position: Vector3, scale_value: float, yaw: float) -> Node3D:
	var packed := load(resource_path) as PackedScene
	if packed == null:
		push_error("Missing or unimportable environment asset: " + resource_path)
		return null
	var item := packed.instantiate() as Node3D
	if item == null:
		push_error("Environment asset is not a Node3D scene: " + resource_path)
		return null
	item.name = node_name
	item.position = position
	item.rotation.y = yaw
	item.scale = Vector3.ONE * scale_value
	item.set_meta("asset_source", "KayKit Forest Nature Pack 1.0 FREE / CC0")
	parent.add_child(item)
	var is_vegetation := resource_path.contains("Tree") or resource_path.contains("Bush")
	_tone_asset_palette(item, is_vegetation)
	if resource_path.contains("Bare"):
		_flatten_asset_palette(item, Color(0.24, 0.22, 0.17, 1.0))
	return item


func _tone_asset_palette(root: Node3D, vegetation: bool) -> void:
	var target_tint := Color(0.27, 0.32, 0.24, 1.0) if vegetation else Color(0.36, 0.37, 0.34, 1.0)
	var blend_amount := 0.72 if vegetation else 0.50
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		for surface_index in range(mesh_instance.mesh.get_surface_count()):
			var source_material := mesh_instance.get_active_material(surface_index)
			if source_material is StandardMaterial3D:
				var toned_material := source_material.duplicate() as StandardMaterial3D
				toned_material.albedo_color = toned_material.albedo_color.lerp(target_tint, blend_amount)
				toned_material.roughness = maxf(toned_material.roughness, 0.88)
				mesh_instance.set_surface_override_material(surface_index, toned_material)


func _flatten_asset_palette(root: Node3D, color: Color) -> void:
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance != null:
			mesh_instance.material_override = _make_material(color)


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.roughness = 0.92
	material.metallic = 0.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _make_natural_material(color: Color) -> StandardMaterial3D:
	var material := _make_material(color)
	# Graphic blockout land needs stable designed color blocks; water and the
	# imported hero assets keep the normal lit material path.
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _capture_all() -> void:
	var output_dir := ProjectSettings.globalize_path(CAPTURE_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var shots := [
		{"file": "01_overview.png", "position": Vector3(0.0, 0.28, 70.0), "view": "overview"},
		{"file": "02_approach.png", "position": Vector3(0.0, 0.28, -2.0), "view": "approach"},
		{"file": "03_world_read.png", "position": Vector3(0.0, 0.28, -20.0), "view": "world_read"},
		{"file": "04_boat_to_island.png", "position": Vector3(0.0, 0.28, -38.0), "view": "boat_to_island"},
		{"file": "05_island_silhouette.png", "position": Vector3(0.0, 0.28, -52.0), "view": "island_silhouette"},
	]
	for shot in shots:
		regional_system.call("_set_boat_pose", shot["position"], 0.0, 0.0)
		regional_system.call("_set_camera_view", shot["view"])
		for _frame in range(24):
			await get_tree().process_frame
		var image := get_viewport().get_texture().get_image()
		var path := output_dir.path_join(String(shot["file"]))
		var error := image.save_png(path)
		if error != OK:
			push_error("Cannot save island slice screenshot: " + path)
		else:
			print("FIRST_REAL_ISLAND_SLICE_SCREENSHOT=" + path)
	var draw_calls := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitives := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("FIRST_REAL_ISLAND_SLICE_RENDER_INFO|draw_calls=%s|primitives=%s|gpu_ms_unavailable_in_runtime=true" % [str(draw_calls), str(primitives)])
	get_tree().quit()


func _capture_natural_pass_02() -> void:
	var capture_dir := "res://scenes/visual_slices/first_real_island_natural_world_pass_02_captures"
	var output_dir := ProjectSettings.globalize_path(capture_dir)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var shots := [
		{"file": "01_distant_approach.png", "position": Vector3(0.0, 0.28, 70.0), "view": "overview"},
		{"file": "02_medium_approach.png", "position": Vector3(0.0, 0.28, -2.0), "view": "approach"},
		{"file": "03_coastline.png", "position": Vector3(0.0, 0.28, -20.0), "view": "world_read"},
		{"file": "04_harbor_entrance.png", "position": Vector3(0.0, 0.28, -30.0), "view": "boat_to_island"},
		{"file": "05_inside_harbor.png", "position": Vector3(0.0, 0.28, -42.0), "view": "island_silhouette"},
		{"file": "06_buildings_hidden_natural_view.png", "position": Vector3(0.0, 0.28, -54.0), "view": "island_silhouette"},
	]
	for shot in shots:
		regional_system.call("_set_boat_pose", shot["position"], 0.0, 0.0)
		regional_system.call("_set_camera_view", shot["view"])
		for _frame in range(24):
			await get_tree().process_frame
		var image := get_viewport().get_texture().get_image()
		var path := output_dir.path_join(String(shot["file"]))
		var error := image.save_png(path)
		if error != OK:
			push_error("Cannot save natural world screenshot: " + path)
		else:
			print("FIRST_REAL_ISLAND_NATURAL_SCREENSHOT=" + path)
	var draw_calls := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitives := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("FIRST_REAL_ISLAND_NATURAL_RENDER_INFO|draw_calls=%s|primitives=%s|buildings_hidden=true" % [str(draw_calls), str(primitives)])
	get_tree().quit()
