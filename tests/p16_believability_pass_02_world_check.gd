extends SceneTree

const SCENE := preload("res://scenes/staging/believability_pass_02/AutonomousWorldOceanBelievabilityPass02.tscn")

func _initialize() -> void:
	var instance := SCENE.instantiate()
	root.add_child(instance)
	for _frame in range(90):
		await process_frame
	var world := instance.get_node_or_null("NorthAtlanticPlayableWorld01_ISOLATED")
	assert(world != null, "P-16 world did not build")
	var visual := world.get_node_or_null("WorldVisualRoot_REPLACEABLE")
	var collision := world.get_node_or_null("WorldCollisionRoot_SIMPLE_PROXY")
	assert(visual != null and collision != null, "Visual/collision separation regressed")
	var voyage := visual.get_node_or_null("OpenSeaDistanceContext")
	assert(voyage != null, "Open-sea distance context missing")
	assert(voyage.get_node_or_null("West_DistantCoast_GEOLOGY_BLOCKOUT") != null)
	assert(voyage.get_node_or_null("East_DistantCoast_GEOLOGY_BLOCKOUT") != null)
	assert(voyage.get_node_or_null("WestRouteSkerry_DISTANCE_SILHOUETTE") != null)
	var destination_a := visual.get_node_or_null("DestinationA_ExposedNorthernCoast")
	var destination_b := visual.get_node_or_null("DestinationB_ShelteredInhabitedCoast")
	assert(destination_a.get_node_or_null("A_ContinuousTidalShelf_DESIGNED_EDGE") != null)
	assert(destination_b.get_node_or_null("B_ContinuousShelteredTidalShelf_DESIGNED_EDGE") != null)
	assert(destination_b.get_node_or_null("B_AttachedStoneQuay_WORKING_STRUCTURE") != null)
	var ocean := instance.get_node("CanonicalSailingReference/RegionalOceanSystem")
	assert(ocean.get("water_material") != null, "B+ V3 water material missing")
	assert(ocean.get("boat_visual") != null, "Boat/wave-coupled visual missing")
	print("P16_WORLD_CHECK_PASS|distance_context=4|tidal_shelves=2|attached_quay=true|visual_collision_separate=true|b_plus_v3_present=true")
	quit(0)
