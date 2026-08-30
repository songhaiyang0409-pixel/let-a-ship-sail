extends Node3D

## ISLAND WORLD READ RESET 03
##
## Isolated natural-geography iteration. Pass 02 remains unchanged as history.
## SailingReferenceScene continues to own B+ V3 water, the duplicated boat,
## shared wave sampling, camera, and keyboard/mouse input.

const CAPTURE_DIR := "res://scenes/visual_slices/island_world_read_reset_03_captures"
const VIEWPORT_SIZE := Vector2i(1152, 648)

const ROCK_DARK := Color(0.15, 0.18, 0.18, 1.0)
const ROCK_MID := Color(0.23, 0.26, 0.25, 1.0)
const ROCK_LIGHT := Color(0.32, 0.33, 0.29, 1.0)
const LAND_DARK := Color(0.10, 0.17, 0.15, 1.0)
const LAND_BASE := Color(0.15, 0.25, 0.18, 1.0)
const LAND_LIGHT := Color(0.23, 0.32, 0.20, 1.0)
const SHRUB_DARK := Color(0.12, 0.22, 0.17, 1.0)
const WOOD_DARK := Color(0.22, 0.17, 0.13, 1.0)
const MARKER_COLOR := Color(0.76, 0.58, 0.28, 1.0)

const BOAT_HULL_LENGTH_M := 6.0
const HUMAN_HEIGHT_M := 1.8
const DOCK_WIDTH_M := 2.0
const DOCK_CLEARANCE_M := 3.0
const SHORELINE_TYPICAL_HEIGHT_M := 1.2
const EXPOSED_CLIFF_HEIGHT_M := 6.0

var reference_instance: Node3D
var regional_system: Node3D
var island_root: Node3D
var terrain_root: Node3D
var rock_root: Node3D
var harbor_root: Node3D
var landmark_root: Node3D
var scale_root: Node3D
var natural_only := false
var show_scale_references := false


func _ready() -> void:
	_configure_viewport()
	reference_instance = get_node_or_null("SailingReferenceScene") as Node3D
	if reference_instance == null:
		push_error("IslandWorldReadReset03 cannot find SailingReferenceScene.")
		return
	await get_tree().process_frame
	regional_system = reference_instance.get_node_or_null("RegionalOceanSystem") as Node3D
	if regional_system == null:
		push_error("IslandWorldReadReset03 cannot find RegionalOceanSystem.")
		return
	for _frame in range(90):
		if regional_system.get("boat_visual") != null:
			break
		await get_tree().process_frame
	if regional_system.get("boat_visual") == null:
		push_error("IslandWorldReadReset03 timed out waiting for the canonical boat visual.")
		return
	_hide_old_proxy_layers()
	_build_scale_references()
	_build_natural_geography()
	_build_reserved_human_mounts()
	show_scale_references = OS.get_cmdline_user_args().has("--show-scale-references")
	scale_root.visible = show_scale_references
	natural_only = OS.get_cmdline_user_args().has("--natural-only")
	if natural_only:
		_set_natural_only(true)
	print("ISLAND_WORLD_READ_RESET_03_READY|isolated=true|pass_02_preserved=true|natural_only=%s|steering_profile=island_world_read_reset_03|formal_project_modified=false" % str(natural_only))
	if OS.get_cmdline_user_args().has("--capture-island-world-read-reset-03"):
		call_deferred("_capture_reset_03")


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
	var old_refs := regional_system.get("scale_reference_root") as Node3D
	if old_refs != null:
		old_refs.visible = false


func _build_scale_references() -> void:
	scale_root = Node3D.new()
	scale_root.name = "ScaleReferences_DEVELOPMENT_ONLY"
	scale_root.set_meta("asset_status", "DEVELOPMENT_REFERENCE_ONLY")
	scale_root.set_meta("world_scale", "1 Godot unit approximately 1 meter")
	add_child(scale_root)
	_add_box(scale_root, "HumanHeight_1m80", Vector3(0.14, HUMAN_HEIGHT_M, 0.14), Vector3(-16.0, HUMAN_HEIGHT_M * 0.5, -28.0), MARKER_COLOR)
	_add_box(scale_root, "BoatLength_6m", Vector3(BOAT_HULL_LENGTH_M, 0.10, 0.10), Vector3(-7.0, 0.08, -28.0), MARKER_COLOR)
	_add_box(scale_root, "DockWidth_2m", Vector3(DOCK_WIDTH_M, 0.10, 0.10), Vector3(2.0, 0.08, -28.0), MARKER_COLOR)
	_add_box(scale_root, "DockClearance_3m", Vector3(0.12, 0.12, DOCK_CLEARANCE_M), Vector3(6.0, 0.10, -28.0), MARKER_COLOR)
	_add_box(scale_root, "Shoreline_1m2", Vector3(0.12, SHORELINE_TYPICAL_HEIGHT_M, 0.12), Vector3(9.0, SHORELINE_TYPICAL_HEIGHT_M * 0.5, -28.0), MARKER_COLOR)
	_add_box(scale_root, "ExposedCliff_6m", Vector3(0.12, EXPOSED_CLIFF_HEIGHT_M, 0.12), Vector3(12.0, EXPOSED_CLIFF_HEIGHT_M * 0.5, -28.0), MARKER_COLOR)
	_add_label(scale_root, "1.8m human", Vector3(-16.0, 2.15, -28.0))
	_add_label(scale_root, "6m boat", Vector3(-7.0, 0.28, -28.0))
	_add_label(scale_root, "2m dock", Vector3(2.0, 0.28, -28.0))
	_add_label(scale_root, "3m clear", Vector3(6.0, 0.28, -28.0))
	_add_label(scale_root, "1.2m shore", Vector3(9.0, 1.48, -28.0))
	_add_label(scale_root, "6m cliff", Vector3(12.0, 6.35, -28.0))


func _build_natural_geography() -> void:
	island_root = Node3D.new()
	island_root.name = "IslandWorldReadReset03_NaturalGeography_PLACEHOLDER"
	island_root.set_meta("asset_status", "PLACEHOLDER_GEOGRAPHY_BLOCKOUT")
	island_root.set_meta("design_reference", "Faroe / North Atlantic exposed side + Robin Hoods Bay sheltered side")
	add_child(island_root)
	terrain_root = Node3D.new()
	terrain_root.name = "TerrainMasses"
	island_root.add_child(terrain_root)
	rock_root = Node3D.new()
	rock_root.name = "IrregularRockShelves"
	island_root.add_child(rock_root)
	harbor_root = Node3D.new()
	harbor_root.name = "ShelteredHarborBasin"
	island_root.add_child(harbor_root)
	landmark_root = Node3D.new()
	landmark_root.name = "FutureLandmarkMounts"
	island_root.add_child(landmark_root)

	# Several overlapping, asymmetric masses create geography rather than one
	# radial mound. The west side is exposed and cliff-like; the east side is
	# lower and wraps a protected basin.
	_add_land_mass(terrain_root, "WestExposedHeadland_PLACEHOLDER", [
		Vector3(-31.0, 0.0, -20.0), Vector3(-28.0, 0.0, -28.0),
		Vector3(-27.0, 0.0, -38.0), Vector3(-24.0, 0.0, -49.0),
		Vector3(-15.0, 0.0, -57.0), Vector3(-10.0, 0.0, -48.0),
		Vector3(-12.0, 0.0, -37.0), Vector3(-18.0, 0.0, -26.0)
	], [0.8, 2.4, 4.8, 6.5, 5.4, 3.8, 2.2, 1.2], ROCK_MID)
	_add_land_mass(terrain_root, "WestGreenWindwardSlope_PLACEHOLDER", [
		Vector3(-26.0, 0.0, -27.0), Vector3(-23.0, 0.0, -36.0),
		Vector3(-21.0, 0.0, -46.0), Vector3(-15.0, 0.0, -52.0),
		Vector3(-12.0, 0.0, -44.0), Vector3(-14.0, 0.0, -34.0),
		Vector3(-19.0, 0.0, -27.0)
	], [1.3, 2.8, 3.9, 4.3, 3.4, 2.4, 1.7], LAND_BASE)
	_add_land_mass(terrain_root, "EastShelteredShoulder_PLACEHOLDER", [
		Vector3(31.0, 0.0, -22.0), Vector3(28.0, 0.0, -32.0),
		Vector3(25.0, 0.0, -44.0), Vector3(21.0, 0.0, -52.0),
		Vector3(14.0, 0.0, -55.0), Vector3(10.0, 0.0, -47.0),
		Vector3(11.0, 0.0, -36.0), Vector3(17.0, 0.0, -26.0)
	], [0.6, 1.5, 2.5, 3.8, 3.5, 2.2, 1.4, 0.8], ROCK_LIGHT)
	_add_land_mass(terrain_root, "EastShelteredGreenSlope_PLACEHOLDER", [
		Vector3(26.0, 0.0, -28.0), Vector3(24.0, 0.0, -37.0),
		Vector3(21.0, 0.0, -47.0), Vector3(15.0, 0.0, -51.0),
		Vector3(12.0, 0.0, -45.0), Vector3(13.0, 0.0, -36.0),
		Vector3(18.0, 0.0, -28.0)
	], [1.0, 1.8, 2.7, 3.0, 2.2, 1.5, 1.1], LAND_LIGHT)
	_add_land_mass(terrain_root, "BackHighRidge_PLACEHOLDER", [
		Vector3(-17.0, 0.0, -51.0), Vector3(-13.0, 0.0, -60.0),
		Vector3(-7.0, 0.0, -68.0), Vector3(2.0, 0.0, -72.0),
		Vector3(11.0, 0.0, -66.0), Vector3(17.0, 0.0, -57.0),
		Vector3(12.0, 0.0, -51.0), Vector3(0.0, 0.0, -49.0)
	], [2.5, 5.5, 8.0, 9.5, 7.0, 4.8, 3.2, 2.8], LAND_DARK)
	_add_land_mass(terrain_root, "BackGreenCrown_PLACEHOLDER", [
		Vector3(-11.0, 0.0, -55.0), Vector3(-8.0, 0.0, -63.0),
		Vector3(-2.0, 0.0, -68.0), Vector3(6.0, 0.0, -66.0),
		Vector3(11.0, 0.0, -59.0), Vector3(7.0, 0.0, -54.0),
		Vector3(0.0, 0.0, -52.0)
	], [3.4, 5.8, 7.0, 6.4, 5.2, 3.6, 3.2], LAND_BASE)

	# The harbor is an open gap between the two shoulders and a lower inner
	# landing. No rectangular hole or dock-only trick defines the basin.
	_add_land_mass(harbor_root, "ShelteredInnerShore_West_PLACEHOLDER", [
		Vector3(-14.0, 0.0, -34.0), Vector3(-10.0, 0.0, -39.0),
		Vector3(-10.0, 0.0, -49.0), Vector3(-7.0, 0.0, -55.0),
		Vector3(-4.5, 0.0, -52.0), Vector3(-5.0, 0.0, -43.0),
		Vector3(-7.0, 0.0, -36.0)
	], [0.5, 0.7, 0.8, 1.0, 0.8, 0.7, 0.5], LAND_DARK)
	_add_land_mass(harbor_root, "ShelteredInnerShore_East_PLACEHOLDER", [
		Vector3(4.5, 0.0, -35.0), Vector3(7.0, 0.0, -40.0),
		Vector3(7.0, 0.0, -50.0), Vector3(10.0, 0.0, -54.0),
		Vector3(13.0, 0.0, -49.0), Vector3(12.0, 0.0, -40.0),
		Vector3(9.0, 0.0, -35.0)
	], [0.5, 0.8, 0.9, 1.2, 1.0, 0.7, 0.5], LAND_DARK)

	# Broken shelves and partially submerged stones vary the exposed coastline.
	_add_shelf(rock_root, "WestShelf_A", [Vector3(-33.0, 0.0, -25.0), Vector3(-29.0, 0.0, -22.0), Vector3(-26.0, 0.0, -28.0), Vector3(-31.0, 0.0, -32.0)], 0.45, ROCK_LIGHT)
	_add_shelf(rock_root, "WestShelf_B", [Vector3(-29.0, 0.0, -45.0), Vector3(-25.0, 0.0, -42.0), Vector3(-22.0, 0.0, -49.0), Vector3(-27.0, 0.0, -53.0)], 0.65, ROCK_DARK)
	_add_shelf(rock_root, "WestShelf_C", [Vector3(-21.0, 0.0, -57.0), Vector3(-15.0, 0.0, -55.0), Vector3(-14.0, 0.0, -61.0), Vector3(-19.0, 0.0, -63.0)], 0.38, ROCK_MID)
	_add_shelf(rock_root, "EastShelf_A", [Vector3(32.0, 0.0, -29.0), Vector3(28.0, 0.0, -26.0), Vector3(25.0, 0.0, -31.0), Vector3(29.0, 0.0, -35.0)], 0.30, ROCK_MID)
	_add_shelf(rock_root, "EastShelf_B", [Vector3(28.0, 0.0, -46.0), Vector3(24.0, 0.0, -43.0), Vector3(21.0, 0.0, -49.0), Vector3(25.0, 0.0, -53.0)], 0.55, ROCK_LIGHT)
	_add_shelf(rock_root, "HarborMouthWest", [Vector3(-18.0, 0.0, -34.0), Vector3(-14.0, 0.0, -32.0), Vector3(-12.0, 0.0, -36.0), Vector3(-15.0, 0.0, -39.0)], 0.34, ROCK_DARK)
	_add_shelf(rock_root, "HarborMouthEast", [Vector3(12.0, 0.0, -35.0), Vector3(16.0, 0.0, -32.0), Vector3(19.0, 0.0, -36.0), Vector3(15.0, 0.0, -40.0)], 0.42, ROCK_MID)
	_add_boulder(rock_root, "PartiallySubmergedRock_West", Vector3(-29.0, 0.42, -36.0), Vector3(3.2, 0.75, 2.0), ROCK_DARK, -0.2)
	_add_boulder(rock_root, "PartiallySubmergedRock_East", Vector3(28.0, 0.34, -39.0), Vector3(2.8, 0.65, 1.8), ROCK_LIGHT, 0.45)
	_add_boulder(rock_root, "HarborMouthStone_West", Vector3(-13.5, 0.45, -31.7), Vector3(1.8, 0.70, 1.3), ROCK_MID, 0.2)
	_add_boulder(rock_root, "HarborMouthStone_East", Vector3(14.5, 0.38, -32.0), Vector3(2.0, 0.62, 1.4), ROCK_DARK, -0.3)

	# Low-profile vegetation masses only. No rounded bright tree asset is used
	# in gameplay-camera positions; the northern/open side stays sparse.
	_add_low_shrub(terrain_root, "ShelteredShrub_A", Vector3(-7.0, 1.1, -48.0), Vector3(2.2, 0.55, 1.0), SHRUB_DARK)
	_add_low_shrub(terrain_root, "ShelteredShrub_B", Vector3(6.0, 1.0, -51.0), Vector3(2.0, 0.48, 0.9), SHRUB_DARK)
	_add_low_shrub(terrain_root, "WindwardGrassMass", Vector3(-4.0, 6.1, -64.0), Vector3(3.8, 0.48, 1.2), LAND_DARK)


func _build_reserved_human_mounts() -> void:
	var dock := MeshInstance3D.new()
	dock.name = "FutureDockLandingMarker_PLACEHOLDER"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(DOCK_WIDTH_M, 0.18, 6.0)
	dock.mesh = mesh
	dock.position = Vector3(6.0, 0.22, -44.0)
	dock.material_override = _make_material(WOOD_DARK)
	dock.set_meta("asset_status", "FUTURE_DOCK_MOUNT_ONLY")
	harbor_root.add_child(dock)
	var landmark := MeshInstance3D.new()
	landmark.name = "FutureLandmarkLocation_MARKER_ONLY"
	var marker_mesh := CylinderMesh.new()
	marker_mesh.top_radius = 0.22
	marker_mesh.bottom_radius = 0.30
	marker_mesh.height = 3.0
	marker_mesh.radial_segments = 6
	landmark.mesh = marker_mesh
	landmark.position = Vector3(-5.0, 7.6, -64.0)
	landmark.material_override = _make_material(MARKER_COLOR)
	landmark_root.add_child(landmark)


func _set_natural_only(hidden: bool) -> void:
	var dock := harbor_root.get_node_or_null("FutureDockLandingMarker_PLACEHOLDER") as Node3D
	if dock != null:
		dock.visible = not hidden
	landmark_root.visible = not hidden


func _add_land_mass(parent: Node3D, node_name: String, footprint: Array[Vector3], heights: Array[float], color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = node_name
	item.set_meta("asset_status", "PLACEHOLDER_INTENTIONAL_TERRAIN_MASS")
	var mesh := ArrayMesh.new()
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var center := Vector3.ZERO
	for point in footprint:
		center += Vector3(point.x, 0.0, point.z)
	center /= float(footprint.size())
	for point in footprint:
		vertices.append(Vector3(point.x, -0.15, point.z))
	for index in range(footprint.size()):
		var shoulder := center.lerp(Vector3(footprint[index].x, 0.0, footprint[index].z), 0.68)
		vertices.append(Vector3(shoulder.x, maxf(0.22, heights[index] * 0.58), shoulder.z))
	var top_center_index := vertices.size()
	var average_height := 0.0
	for height in heights:
		average_height += height
	average_height /= float(heights.size())
	vertices.append(Vector3(center.x - 1.2, average_height + 0.24, center.z - 0.8))
	for index in range(footprint.size()):
		var next := (index + 1) % footprint.size()
		indices.append_array([index, next, footprint.size() + next, index, footprint.size() + next, footprint.size() + index])
		indices.append_array([footprint.size() + index, footprint.size() + next, top_center_index])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	item.mesh = mesh
	item.material_override = _make_material(color)
	parent.add_child(item)
	return item


func _add_shelf(parent: Node3D, node_name: String, footprint: Array[Vector3], height: float, color: Color) -> MeshInstance3D:
	return _add_land_mass(parent, node_name, footprint, [height, height * 0.75, height * 0.35, height * 0.6], color)


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
	item.set_meta("asset_status", "PLACEHOLDER_IRREGULAR_COASTAL_ROCK")
	parent.add_child(item)
	return item


func _add_low_shrub(parent: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = node_name
	var mesh := SphereMesh.new()
	mesh.radial_segments = 7
	mesh.rings = 2
	mesh.radius = 0.5
	mesh.height = 1.0
	item.mesh = mesh
	item.position = position
	item.scale = size
	item.material_override = _make_material(color)
	item.set_meta("asset_status", "PLACEHOLDER_LOW_PROFILE_VEGETATION")
	parent.add_child(item)
	return item


func _add_box(parent: Node, node_name: String, size: Vector3, position: Vector3, color: Color) -> void:
	var item := MeshInstance3D.new()
	item.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.position = position
	item.material_override = _make_material(color)
	parent.add_child(item)


func _add_label(parent: Node, text_value: String, position: Vector3) -> void:
	var label := Label3D.new()
	label.text = text_value
	label.position = position
	label.font_size = 24
	label.outline_size = 5
	label.modulate = Color(0.10, 0.12, 0.12, 1.0)
	label.outline_modulate = Color(0.88, 0.88, 0.82, 1.0)
	parent.add_child(label)


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	material.metallic = 0.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _capture_reset_03() -> void:
	var output_dir := ProjectSettings.globalize_path(CAPTURE_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var shots := [
		{"file": "01_far_approach.png", "position": Vector3(0.0, 0.28, 70.0), "view": "overview"},
		{"file": "02_medium_approach.png", "position": Vector3(0.0, 0.28, 10.0), "view": "overview"},
		{"file": "03_harbor_approach.png", "position": Vector3(0.0, 0.28, -18.0), "view": "world_read"},
		{"file": "04_near_coastline.png", "position": Vector3(0.0, 0.28, -34.0), "view": "boat_to_island"},
		{"file": "05_natural_only.png", "position": Vector3(0.0, 0.28, -27.0), "view": "world_read"},
	]
	for shot_index in range(shots.size()):
		var shot: Dictionary = shots[shot_index]
		if shot_index == shots.size() - 1:
			_set_natural_only(true)
		regional_system.call("_set_boat_pose", shot["position"], 0.0, 0.0)
		regional_system.call("_set_camera_view", shot["view"])
		await _settle_frames(24)
		var image := get_viewport().get_texture().get_image()
		var path := output_dir.path_join(String(shot["file"]))
		var error := image.save_png(path)
		if error != OK:
			push_error("Cannot save Reset 03 screenshot: " + path)
		else:
			print("ISLAND_WORLD_READ_RESET_03_SCREENSHOT=" + path)
	var draw_calls := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitives := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("ISLAND_WORLD_READ_RESET_03_RENDER_INFO|draw_calls=%s|primitives=%s|natural_only=true" % [str(draw_calls), str(primitives)])
	get_tree().quit()


func _settle_frames(frame_count: int) -> void:
	for _frame in range(frame_count):
		await get_tree().process_frame
