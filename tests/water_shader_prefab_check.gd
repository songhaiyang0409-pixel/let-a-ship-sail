extends SceneTree

const WATER_TEST_SCENE := preload("res://scenes/water/WaterTest.tscn")
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_check")


func _run_check() -> void:
	var scene := WATER_TEST_SCENE.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var ocean := scene.get_node_or_null("OceanPrefab")
	var camera := scene.get_node_or_null("Camera3D")
	var material_ok := ocean != null and ocean.get("material") != null
	var generated_mesh_count := 0
	if ocean != null:
		for child in ocean.get_children():
			if child is MeshInstance3D and String(child.name).begins_with("_gen_"):
				generated_mesh_count += 1

	if ocean == null:
		failures.append("Water Test could not instantiate OceanPrefab.")
	if camera == null:
		failures.append("Water Test camera is missing.")
	if not material_ok:
		failures.append("Water Test OceanPrefab has no material.")
	if generated_mesh_count == 0:
		failures.append("Water Test OceanPrefab did not generate runtime meshes.")

	if ocean != null:
		print("WATER_TEST_PREFAB|material=%s|generated_meshes=%d" % [str(material_ok), generated_mesh_count])
	if failures.is_empty():
		print("WATER_SHADER_PREFAB_CHECK: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("WATER_SHADER_PREFAB_CHECK: FAIL")
		quit(1)
