extends Node3D

## OVERNIGHT WORLD STAGING PREP 01
##
## Thin wrapper around the single canonical sailing reference. This scene owns
## only provisional world-scale anchors, future asset sockets, and evidence
## capture helpers. Water, boat/wave coupling, movement, camera, and controls
## remain owned by the canonical RegionalOceanSystem instance.

const VIEWPORT_SIZE := Vector2i(1152, 648)
const CAPTURE_ROOT := "res://scenes/staging/overnight_world_staging_captures"
const ROUTE_START := Vector3(0.0, 0.28, 70.0)
const ROUTE_END := Vector3(0.0, 0.28, -78.0)
const DESTINATION_A := Vector3(0.0, 0.0, 70.0)
const DESTINATION_B := Vector3(0.0, 0.0, -78.0)

var canonical_instance: Node3D
var regional_system: Node3D
var staging_world_root: Node3D
var capture_mode := false


func _ready() -> void:
	_configure_viewport()
	capture_mode = OS.get_cmdline_user_args().has("--capture-overnight-world-staging-01")
	canonical_instance = get_node_or_null("CanonicalSailingReference") as Node3D
	if canonical_instance == null:
		push_error("Overnight staging could not find CanonicalSailingReference.")
		return
	await get_tree().process_frame
	regional_system = canonical_instance.get_node_or_null("RegionalOceanSystem") as Node3D
	if regional_system == null:
		push_error("Overnight staging could not find RegionalOceanSystem.")
		return
	_build_staging_world()
	if capture_mode:
		# Capture mode reuses the canonical camera and wave-follow, but disables
		# keyboard navigation so each evidence frame is deterministic.
		regional_system.set("interactive_mode", false)
		regional_system.set("capture_mode", false)
		regional_system.set("observe_mode", false)
		call_deferred("_capture_route")
	print("OVERNIGHT_WORLD_STAGING_READY|isolated=true|canonical=res://scenes/reference/SailingReferenceScene.tscn|route=DestinationA>DestinationB|formal_project_modified=false")


func _configure_viewport() -> void:
	var window := get_window()
	window.size = VIEWPORT_SIZE
	window.content_scale_size = VIEWPORT_SIZE
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED


func _build_staging_world() -> void:
	staging_world_root = Node3D.new()
	staging_world_root.name = "OvernightStagingWorld_PROXY_ONLY"
	staging_world_root.set_meta("asset_status", "PLACEHOLDER_SPATIAL_STAGING")
	staging_world_root.set_meta("world_scale", "1 Godot unit approximately 1 meter")
	staging_world_root.set_meta("route_start", "Destination A / exposed northern coast")
	staging_world_root.set_meta("route_end", "Destination B / sheltered inhabited coast")
	add_child(staging_world_root)

	_build_destination_anchors()
	_build_asset_sockets()
	_build_exposed_coast_proxy()


func _build_destination_anchors() -> void:
	var anchors := Node3D.new()
	anchors.name = "DestinationAnchors_WORLD_SPACE"
	staging_world_root.add_child(anchors)

	var destination_a := Marker3D.new()
	destination_a.name = "DestinationA_ExposedNorthernCoast_ANCHOR"
	destination_a.position = DESTINATION_A
	destination_a.set_meta("role", "route origin")
	destination_a.set_meta("landscape", "exposed northern coast")
	anchors.add_child(destination_a)

	var destination_b := Marker3D.new()
	destination_b.name = "DestinationB_ShelteredInhabitedCoast_ANCHOR"
	destination_b.position = DESTINATION_B
	destination_b.set_meta("role", "route destination")
	destination_b.set_meta("landscape", "sheltered inhabited coast")
	destination_b.set_meta("visual_source", "existing canonical coastal proxy")
	anchors.add_child(destination_b)

	var route_info := Node3D.new()
	route_info.name = "RouteAtoB_148m_PROVISIONAL"
	route_info.set_meta("distance_m", DESTINATION_A.distance_to(DESTINATION_B))
	route_info.set_meta("normal_speed_mps", 2.2)
	route_info.set_meta("test_observation_speed_mps", 5.0)
	route_info.set_meta("normal_time_seconds", DESTINATION_A.distance_to(DESTINATION_B) / 2.2)
	route_info.set_meta("test_time_seconds", DESTINATION_A.distance_to(DESTINATION_B) / 5.0)
	anchors.add_child(route_info)


func _build_asset_sockets() -> void:
	var sockets := Node3D.new()
	sockets.name = "V2FUN_Asset_Sockets_READY"
	sockets.set_meta("purpose", "replaceable visual staging only; no fabricated assets")
	staging_world_root.add_child(sockets)

	_add_socket(sockets, "TurfRoofCottage_SOCKET", Vector3(-6.0, 4.0, -70.0), "incoming cottage visual")
	_add_socket(sockets, "HarborWarehouseFishingShed_SOCKET", Vector3(6.0, 2.0, -72.0), "incoming harbor shed visual")
	_add_socket(sockets, "DestinationBLandmark_SOCKET", Vector3(-27.0, 6.0, -39.0), "replace existing beacon proxy when approved")
	_add_socket(sockets, "PierVisual_SOCKET", Vector3(7.5, 0.4, -57.0), "incoming pier visual")


func _add_socket(parent: Node3D, socket_name: String, position: Vector3, purpose: String) -> void:
	var socket := Node3D.new()
	socket.name = socket_name
	socket.position = position
	socket.set_meta("asset_status", "EMPTY_SOCKET")
	socket.set_meta("purpose", purpose)
	parent.add_child(socket)


func _build_exposed_coast_proxy() -> void:
	# One neutral, low-cost headland gives Destination A a physical scale cue.
	# It is deliberately outside the canonical harbor proxy and has no collision.
	var root := Node3D.new()
	root.name = "DestinationA_ExposedCoast_PROXY_VISUAL_ONLY"
	root.set_meta("asset_status", "PLACEHOLDER_PROXY_NO_COLLISION")
	staging_world_root.add_child(root)

	var coast := MeshInstance3D.new()
	coast.name = "ExposedNorthernHeadland_PROXY"
	coast.mesh = _make_headland_mesh(Vector3(34.0, 3.2, 20.0), 1.0, 2.8)
	coast.position = Vector3(-27.0, 0.0, 55.0)
	coast.material_override = _make_proxy_material(Color(0.17, 0.23, 0.25, 1.0))
	root.add_child(coast)


func _make_headland_mesh(size: Vector3, front_top: float, back_top: float) -> ArrayMesh:
	var half_width := size.x * 0.5
	var half_depth := size.z * 0.5
	var vertices := PackedVector3Array([
		Vector3(-half_width, 0.0, -half_depth), Vector3(half_width, 0.0, -half_depth),
		Vector3(half_width, 0.0, half_depth), Vector3(-half_width, 0.0, half_depth),
		Vector3(-half_width, back_top, -half_depth), Vector3(half_width, back_top, -half_depth),
		Vector3(half_width, front_top, half_depth), Vector3(-half_width, front_top, half_depth),
	])
	var indices := PackedInt32Array([
		0, 2, 1, 0, 3, 2, 4, 5, 6, 4, 6, 7,
		0, 1, 5, 0, 5, 4, 3, 6, 2, 3, 7, 6,
		0, 4, 7, 0, 7, 3, 1, 2, 6, 1, 6, 5,
	])
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _make_proxy_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.roughness = 1.0
	return material


func _capture_route() -> void:
	var root := ProjectSettings.globalize_path(CAPTURE_ROOT)
	DirAccess.make_dir_recursive_absolute(root)
	var captures := [
		{"file": "01_departure.png", "position": ROUTE_START, "label": "DEPARTURE_DESTINATION_A"},
		{"file": "02_open_sea.png", "position": Vector3(0.0, 0.28, 25.0), "label": "OPEN_SEA"},
		{"file": "03_first_destination_read.png", "position": Vector3(0.0, 0.28, -8.0), "label": "FIRST_DESTINATION_READ"},
		{"file": "04_near_approach.png", "position": Vector3(0.0, 0.28, -52.0), "label": "NEAR_APPROACH_DESTINATION_B"},
	]
	for capture in captures:
		regional_system.call("_set_boat_pose", capture["position"], 0.0, 0.0)
		regional_system.call("_set_camera_view", "overview")
		await _settle_frames(24)
		_save_capture(root.path_join(String(capture["file"])), String(capture["label"]))
	print("OVERNIGHT_WORLD_STAGING_CAPTURE_COMPLETE|route_distance_m=148|capture_root=%s" % root)
	get_tree().quit()


func _settle_frames(frame_count: int) -> void:
	for _frame in range(frame_count):
		await get_tree().process_frame


func _save_capture(path: String, label: String) -> void:
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	if error != OK:
		push_error("Cannot save overnight staging capture: " + path)
	else:
		print("%s=%s" % [label, path])
