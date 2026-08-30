extends Node3D

@onready var camera: Camera3D = $Camera3D
const CAPTURE_DIR := "res://water_test_captures"


func _ready() -> void:
	# Keep this scene intentionally isolated: it validates the imported water
	# prefab components without touching the sailing prototype scene.
	camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)
	print("WATER_TEST_READY|ocean=%s|material=%s" % [
		str(has_node("OceanPrefab")),
		str($OceanPrefab.material != null),
	])
	if OS.get_cmdline_user_args().has("--capture-water-test"):
		call_deferred("_capture_water_test")


func _capture_water_test() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var output_dir := ProjectSettings.globalize_path(CAPTURE_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(output_dir.path_join("water_test_prefab.png"))
	if error != OK:
		push_error("Cannot save Water Test screenshot.")
	else:
		print("WATER_TEST_SCREENSHOT=" + output_dir.path_join("water_test_prefab.png"))
