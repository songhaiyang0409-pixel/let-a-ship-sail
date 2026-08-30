extends Node3D

## Isolated asset proportion gallery. This scene has no voyage controller,
## collision, wake, or formal camera dependency.
##
## The raw boat visual is preserved beside a non-destructive, target-scale
## duplicate. Nothing here changes the production boat or sailing scenes.

const BOAT_SOURCE_SCRIPT := preload("res://visual_prototype_3d.gd")
const OUTPUT_DIR := "res://scenes/water/overnight_v03/asset_gallery_captures"
const VIEWPORT_SIZE := Vector2i(1152, 648)

const RAW_HULL_LENGTH_M := 1.75
const INTENDED_HULL_LENGTH_M := 6.0
const INTENDED_BOAT_SCALE := INTENDED_HULL_LENGTH_M / RAW_HULL_LENGTH_M

var camera: Camera3D
var raw_boat: Node3D
var target_boat: Node3D


func _ready() -> void:
	_configure_viewport()
	_build_environment()
	_build_floor()
	_build_scale_references()
	await _build_boat_references()
	_build_camera()
	if OS.get_cmdline_user_args().has("--capture-asset-gallery"):
		call_deferred("_capture_gallery")


func _configure_viewport() -> void:
	var window := get_window()
	window.size = VIEWPORT_SIZE
	window.content_scale_size = VIEWPORT_SIZE
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED


func _build_environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "GalleryEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.72, 0.77, 0.78, 1.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.76, 0.78, 1.0)
	environment.ambient_light_energy = 0.9
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "GalleryKeyLight"
	sun.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	sun.light_color = Color(1.0, 0.94, 0.82, 1.0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)


func _build_floor() -> void:
	var floor := MeshInstance3D.new()
	floor.name = "UnifiedGalleryGround"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(26.0, 20.0)
	floor.mesh = mesh
	floor.material_override = _make_material(Color(0.42, 0.46, 0.43, 1.0))
	add_child(floor)
	for x in range(-12, 13):
		_add_box(self, "GroundGuideX_%d" % x, Vector3(0.012, 0.006, 20.0), Vector3(float(x), 0.006, 0.0), Color(0.58, 0.60, 0.55, 0.42))
	for z in range(-9, 10):
		_add_box(self, "GroundGuideZ_%d" % z, Vector3(26.0, 0.006, 0.012), Vector3(0.0, 0.007, float(z)), Color(0.58, 0.60, 0.55, 0.42))


func _build_scale_references() -> void:
	var refs := Node3D.new()
	refs.name = "StandardScaleReferences"
	add_child(refs)

	# Human-scale references are intentionally simple and dimensionally explicit.
	_add_box(refs, "OneMeterCube", Vector3.ONE, Vector3(-9.0, 0.5, -4.0), Color(0.75, 0.55, 0.25, 1.0))
	_add_box(refs, "HumanHeightMarker_1m8", Vector3(0.22, 1.8, 0.22), Vector3(-7.0, 0.9, -4.0), Color(0.24, 0.38, 0.43, 1.0))
	_add_box(refs, "ThreeMeterMarker", Vector3(0.24, 3.0, 0.24), Vector3(-4.5, 1.5, -4.0), Color(0.29, 0.33, 0.28, 1.0))
	_add_box(refs, "TenMeterMarker", Vector3(0.30, 10.0, 0.30), Vector3(-1.0, 5.0, -4.0), Color(0.36, 0.27, 0.22, 1.0))
	_add_label(refs, "1 m cube", Vector3(-9.0, 1.25, -4.0))
	_add_label(refs, "1.8 m human", Vector3(-7.0, 2.1, -4.0))
	_add_label(refs, "3 m", Vector3(-4.5, 3.35, -4.0))
	_add_label(refs, "10 m", Vector3(-1.0, 10.35, -4.0))

	# A dimensional guide is a gallery aid, not a production boat change.
	_add_box(refs, "IntendedHullLengthGuide_6m", Vector3(0.10, 0.04, INTENDED_HULL_LENGTH_M), Vector3(6.0, 0.025, 1.0), Color(0.84, 0.65, 0.25, 0.78))
	_add_label(refs, "6 m intended hull", Vector3(6.0, 0.20, 4.7))


func _build_boat_references() -> void:
	var source := BOAT_SOURCE_SCRIPT.new()
	source.name = "BoatSourceForGallery"
	source.visible = false
	add_child(source)
	await get_tree().process_frame
	var source_boat := source.get_node_or_null("MainCabinSailboatBlockoutV02") as Node3D
	if source_boat == null:
		push_error("AssetGallery could not extract the current boat visual.")
		source.free()
		return

	raw_boat = source_boat.duplicate()
	raw_boat.name = "RawBoatReference_1m75Hull"
	raw_boat.position = Vector3(-5.2, 0.0, 1.0)
	add_child(raw_boat)
	_add_label(self, "RAW MODEL SCALE\n~1.75 m hull", Vector3(-5.2, 2.75, 1.0))

	target_boat = source_boat.duplicate()
	target_boat.name = "IntendedGameWorldBoatReference_6mHull"
	target_boat.position = Vector3(6.0, 0.0, 1.0)
	target_boat.scale = Vector3.ONE * INTENDED_BOAT_SCALE
	add_child(target_boat)
	_add_label(self, "INTENDED GAME-WORLD SCALE\n~6 m hull", Vector3(6.0, 8.1, 1.0))

	source.free()


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "GalleryCamera"
	camera.current = true
	camera.fov = 42.0
	camera.near = 0.05
	camera.far = 100.0
	add_child(camera)
	camera.position = Vector3(18.5, 11.0, 24.0)
	camera.look_at(Vector3(0.0, 3.2, 0.0), Vector3.UP)


func _capture_gallery() -> void:
	var output_dir := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var shots := [
		{"position": Vector3(18.5, 11.0, 24.0), "target": Vector3(0.0, 3.2, 0.0), "file": "01_asset_gallery_overview.png"},
		{"position": Vector3(13.5, 7.0, 14.0), "target": Vector3(6.0, 3.0, 1.0), "file": "02_intended_6m_boat.png"},
		{"position": Vector3(12.0, 6.5, 18.0), "target": Vector3(-1.0, 3.0, -1.0), "file": "03_human_scale_comparison.png"},
	]
	for shot in shots:
		camera.position = shot["position"]
		camera.look_at(shot["target"], Vector3.UP)
		for _frame in range(20):
			await get_tree().process_frame
		var image := get_viewport().get_texture().get_image()
		var path := output_dir.path_join(String(shot["file"]))
		var error := image.save_png(path)
		if error != OK:
			push_error("Cannot save AssetGallery screenshot: " + path)
		else:
			print("ASSET_GALLERY_SCREENSHOT=" + path)
	get_tree().quit()


func _add_box(parent: Node, node_name: String, size: Vector3, position: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.material_override = _make_material(color)
	parent.add_child(instance)


func _add_label(parent: Node, text_value: String, position: Vector3) -> void:
	var label := Label3D.new()
	label.text = text_value
	label.position = position
	label.font_size = 28
	label.modulate = Color(0.10, 0.13, 0.14, 1.0)
	label.outline_size = 6
	label.outline_modulate = Color(0.86, 0.88, 0.84, 1.0)
	parent.add_child(label)


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	return material
