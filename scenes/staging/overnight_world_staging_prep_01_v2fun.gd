extends Node3D

## Isolated V2FUN staging wrapper.
## The original overnight staging scene remains untouched. This wrapper only
## mounts approved-for-review working derivatives into its existing sockets.

const STAGING_SCENE := preload("res://scenes/staging/OvernightWorldStagingPrep01.tscn")
const COTTAGE_ASSET := "res://V2FUN_INBOX/working/Faroe_Turf_Roof_Cottage__V2FUN__7e3dd2ee.glb"
const SHED_ASSET := "res://V2FUN_INBOX/working/Harbor_Fishing_Shed__V2FUN__68c336dd.glb"
const WORKING_SCALE := 5.0

var staging_instance: Node3D


func _ready() -> void:
	staging_instance = STAGING_SCENE.instantiate() as Node3D
	staging_instance.name = "OvernightWorldStagingPrep01_ORIGINAL_UNCHANGED"
	add_child(staging_instance)
	await get_tree().process_frame
	_mount_assets_into_existing_sockets()
	print("V2FUN_STAGING_READY|original_staging_unchanged=true|working_scale=%s" % WORKING_SCALE)


func _mount_assets_into_existing_sockets() -> void:
	var socket_root := staging_instance.get_node_or_null("OvernightStagingWorld_PROXY_ONLY/V2FUN_Asset_Sockets_READY") as Node3D
	if socket_root == null:
		push_error("V2FUN staging could not find the original asset socket root.")
		return
	_mount(socket_root.get_node_or_null("TurfRoofCottage_SOCKET") as Node3D, COTTAGE_ASSET, "FaroeTurfRoofCottage_WORKING_B")
	_mount(socket_root.get_node_or_null("HarborWarehouseFishingShed_SOCKET") as Node3D, SHED_ASSET, "HarborFishingShed_WORKING_B")


func _mount(socket: Node3D, asset_path: String, instance_name: String) -> void:
	if socket == null:
		push_error("Missing V2FUN socket for " + instance_name)
		return
	var packed := load(asset_path) as PackedScene
	if packed == null:
		push_error("Could not load V2FUN working asset: " + asset_path)
		return
	var instance := packed.instantiate()
	var model := instance as Node3D
	if model == null:
		instance.free()
		push_error("V2FUN asset is not a Node3D scene: " + asset_path)
		return
	model.name = instance_name
	model.scale = Vector3.ONE * WORKING_SCALE
	model.set_meta("asset_status", "V2FUN_WORKING_DERIVATIVE_PASS_THROUGH")
	model.set_meta("source_path", asset_path)
	model.set_meta("non_destructive_scale", WORKING_SCALE)
	socket.add_child(model)

