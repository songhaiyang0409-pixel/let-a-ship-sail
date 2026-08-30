extends Node3D

## Isolated preview for V2FUN_INBOX/working.
## This scene has no sailing, collision, camera, or production-scene dependency.

const VIEWPORT_SIZE := Vector2i(1152, 648)
const INBOX_WORKING := "res://V2FUN_INBOX/working"
const SUPPORTED := [".glb", ".gltf", ".fbx", ".obj"]

var camera: Camera3D


func _ready() -> void:
	_configure_viewport()
	_build_environment()
	_build_ground()
	_build_scale_references()
	_build_asset_rows()
	_build_camera()


func _configure_viewport() -> void:
	var window := get_window()
	window.size = VIEWPORT_SIZE
	window.content_scale_size = VIEWPORT_SIZE
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED


func _build_environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "NeutralPreviewEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.72, 0.76, 0.78, 1.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.78, 0.80, 0.80, 1.0)
	environment.ambient_light_energy = 0.85
	world.environment = environment
	add_child(world)
	var key := DirectionalLight3D.new()
	key.name = "NeutralPreviewKey"
	key.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	key.light_color = Color(1.0, 0.94, 0.84, 1.0)
	key.light_energy = 1.1
	key.shadow_enabled = true
	add_child(key)


func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "NeutralPreviewGround"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(30.0, 20.0)
	ground.mesh = mesh
	ground.material_override = _material(Color(0.42, 0.46, 0.43, 1.0))
	add_child(ground)


func _build_scale_references() -> void:
	_add_box("OneMeterCube", Vector3.ONE, Vector3(-10.0, 0.5, 0.0), Color(0.76, 0.56, 0.25, 1.0))
	_add_box("HumanHeight_1m8", Vector3(0.20, 1.8, 0.20), Vector3(-8.0, 0.9, 0.0), Color(0.24, 0.38, 0.43, 1.0))
	_add_box("ThreeMeterMarker", Vector3(0.24, 3.0, 0.24), Vector3(-5.5, 1.5, 0.0), Color(0.30, 0.34, 0.28, 1.0))
	_add_box("TenMeterMarker", Vector3(0.30, 10.0, 0.30), Vector3(-2.0, 5.0, 0.0), Color(0.36, 0.27, 0.22, 1.0))
	_add_label("1 m cube", Vector3(-10.0, 1.35, 0.0))
	_add_label("1.8 m", Vector3(-8.0, 2.15, 0.0))
	_add_label("3 m", Vector3(-5.5, 3.35, 0.0))
	_add_label("10 m", Vector3(-2.0, 10.35, 0.0))


func _build_asset_rows() -> void:
	var directory := DirAccess.open(INBOX_WORKING)
	if directory == null:
		_add_label("No working assets yet", Vector3(4.0, 2.0, 0.0))
		return
	var asset_files: Array[String] = []
	_collect_asset_files(INBOX_WORKING, asset_files)
	asset_files.sort()
	if asset_files.is_empty():
		_add_label("No processed assets yet", Vector3(4.0, 2.0, 0.0))
		return
	for index in range(asset_files.size()):
		var asset_path := asset_files[index]
		var file_name := asset_path.trim_prefix(INBOX_WORKING + "/")
		var resource: Resource = load(asset_path)
		var packed_scene := resource as PackedScene
		if packed_scene != null:
			var instance: Node = packed_scene.instantiate()
			var model := instance as Node3D
			if model != null:
				model.name = "Preview_" + file_name.get_basename()
				model.position = Vector3(4.0 + float(index % 3) * 5.0, 0.0, float(index / 3) * 5.0)
				add_child(model)
				_add_label(file_name, model.position + Vector3(0.0, 2.5, 0.0))
			else:
				instance.free()
				_add_label(file_name + "\nnot a Node3D scene", Vector3(4.0 + float(index % 3) * 5.0, 1.5, float(index / 3) * 5.0))
		else:
			_add_label(file_name + "\nnot loadable as PackedScene", Vector3(4.0 + float(index % 3) * 5.0, 1.5, float(index / 3) * 5.0))


func _collect_asset_files(directory_path: String, result: Array[String]) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return
	for file_name in directory.get_files():
		var lower := file_name.to_lower()
		for suffix in SUPPORTED:
			if lower.ends_with(suffix):
				result.append(directory_path.path_join(file_name))
				break
	for child_directory in directory.get_directories():
		_collect_asset_files(directory_path.path_join(child_directory), result)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "V2FUNInboxPreviewCamera"
	camera.current = true
	camera.fov = 42.0
	camera.near = 0.05
	camera.far = 100.0
	camera.position = Vector3(15.0, 11.0, 22.0)
	add_child(camera)
	camera.look_at(Vector3(0.0, 3.0, 0.0), Vector3.UP)


func _add_box(node_name: String, size: Vector3, position: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.material_override = _material(color)
	add_child(instance)


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
