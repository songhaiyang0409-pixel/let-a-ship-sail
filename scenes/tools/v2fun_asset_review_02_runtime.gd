extends Node3D

## Isolated runtime review for V2FUN GLBs. Loads source bytes through Godot's
## GLTFDocument without importing them into formal scenes or changing files.

const VIEWPORT_SIZE := Vector2i(1152, 648)
const PREVIEW_ROOT := "res://V2FUN_INBOX/previews/asset_review_02_runtime"
const COTTAGE_ASSET := "res://V2FUN_INBOX/working/Faroe_Turf_Roof_Cottage__V2FUN__7e3dd2ee.glb"
const SHED_ASSET := "res://V2FUN_INBOX/working/Harbor_Fishing_Shed__V2FUN__68c336dd.glb"
const WORKING_SCALE := 5.0

var camera: Camera3D
var asset_root: Node3D


func _ready() -> void:
	_configure_viewport()
	_build_environment()
	_build_ground()
	_build_assets()
	_build_scale_reference()
	_build_camera()
	call_deferred("_capture_all_views")


func _configure_viewport() -> void:
	var window := get_window()
	window.size = VIEWPORT_SIZE
	window.content_scale_size = VIEWPORT_SIZE
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED


func _build_environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "AssetReviewNeutralEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.70, 0.74, 0.76, 1.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.80, 0.82, 0.82, 1.0)
	environment.ambient_light_energy = 0.9
	world.environment = environment
	add_child(world)
	var key := DirectionalLight3D.new()
	key.name = "AssetReviewKey"
	key.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	key.light_color = Color(1.0, 0.94, 0.84, 1.0)
	key.light_energy = 1.1
	key.shadow_enabled = true
	add_child(key)


func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "AssetReviewGround"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(34.0, 26.0)
	ground.mesh = mesh
	ground.material_override = _material(Color(0.42, 0.46, 0.43, 1.0))
	add_child(ground)


func _build_assets() -> void:
	asset_root = Node3D.new()
	asset_root.name = "WorkingDerivatives_Scale5x"
	add_child(asset_root)
	_mount_asset(COTTAGE_ASSET, "FaroeTurfRoofCottage_WORKING_B", Vector3(-3.0, 0.0, 0.0))
	_mount_asset(SHED_ASSET, "HarborFishingShed_WORKING_B", Vector3(3.0, 0.0, 0.0))
	_add_label("COTTAGE  |  WORKING B", Vector3(-3.0, 4.3, 0.0))
	_add_label("SHED  |  WORKING B", Vector3(3.0, 4.3, 0.0))


func _mount_asset(asset_path: String, instance_name: String, position: Vector3) -> void:
	var model := _load_glb_runtime(asset_path)
	if model == null:
		return
	model.name = instance_name
	model.position = position
	model.scale = Vector3.ONE * WORKING_SCALE
	model.set_meta("asset_status", "V2FUN_WORKING_DERIVATIVE_PASS_THROUGH")
	model.set_meta("source_path", asset_path)
	asset_root.add_child(model)


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
		push_error("Runtime GLB did not generate a Node3D: " + asset_path)
		return null
	return model


func _build_scale_reference() -> void:
	var cube := MeshInstance3D.new()
	cube.name = "OneMeterCube"
	var cube_mesh := BoxMesh.new()
	cube_mesh.size = Vector3.ONE
	cube.mesh = cube_mesh
	cube.position = Vector3(-8.0, 0.5, 0.0)
	cube.material_override = _material(Color(0.76, 0.56, 0.25, 1.0))
	add_child(cube)
	_add_label("1 m", Vector3(-8.0, 1.35, 0.0))


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "V2FUNAssetReviewCamera"
	camera.current = true
	camera.fov = 42.0
	camera.near = 0.05
	camera.far = 100.0
	add_child(camera)


func _capture_all_views() -> void:
	var root := ProjectSettings.globalize_path(PREVIEW_ROOT)
	DirAccess.make_dir_recursive_absolute(root)
	var views := [
		{"file": "01_front.png", "position": Vector3(0.0, 4.8, 14.0), "target": Vector3(0.0, 1.8, 0.0)},
		{"file": "02_side.png", "position": Vector3(14.0, 4.8, 0.0), "target": Vector3(0.0, 1.8, 0.0)},
		{"file": "03_back.png", "position": Vector3(0.0, 4.8, -14.0), "target": Vector3(0.0, 1.8, 0.0)},
		{"file": "04_game_distance.png", "position": Vector3(16.0, 9.5, 23.0), "target": Vector3(0.0, 1.6, 0.0)},
	]
	for view in views:
		camera.position = view["position"]
		camera.look_at(view["target"], Vector3.UP)
		await _settle_frames(8)
		var image := get_viewport().get_texture().get_image()
		if image == null:
			push_error("Asset review viewport image was unavailable.")
			continue
		var path := root.path_join(String(view["file"]))
		var error := image.save_png(path)
		if error != OK:
			push_error("Could not save V2FUN asset review capture: " + path)
		else:
			print("V2FUN_ASSET_REVIEW_CAPTURE=%s" % path)
	print("V2FUN_ASSET_REVIEW_RUNTIME_COMPLETE|working_scale=%s|capture_root=%s" % [WORKING_SCALE, root])
	get_tree().quit()


func _settle_frames(frame_count: int) -> void:
	for _frame in range(frame_count):
		await get_tree().process_frame


func _add_label(text_value: String, position: Vector3) -> void:
	var label := Label3D.new()
	label.text = text_value
	label.position = position
	label.font_size = 28
	label.modulate = Color(0.10, 0.13, 0.14, 1.0)
	label.outline_size = 6
	label.outline_modulate = Color(0.86, 0.88, 0.84, 1.0)
	add_child(label)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	return material

