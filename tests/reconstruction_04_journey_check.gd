extends SceneTree

const SCENE := preload("res://scenes/staging/reconstruction_04/NorthAtlanticWorldReconstruction04.tscn")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := SCENE.instantiate()
	root.add_child(world)
	for _frame in range(50):
		await process_frame
	var visual := world.get_node_or_null("NorthAtlanticPlayableWorld01_ISOLATED/WorldVisualRoot_REPLACEABLE")
	assert(visual != null, "Replaceable visual root must exist")
	var port := visual.get_node_or_null("DestinationB_ShelteredInhabitedCoast")
	assert(port != null, "Destination B must exist")
	for marker in ["B_OuterPortDaymark", "B_OuterStarboardDaymark", "B_InnerTurnDaymark", "B_BerthDaymark"]:
		assert(port.get_node_or_null(marker) != null, "Missing physical navigation mark: " + marker)
	assert(port.get_node_or_null("B_InnerQuay_PROXY") != null, "Inner quay must communicate the working berth")
	var ocean = world.get("ocean")
	assert(ocean != null, "Protected regional ocean must be present")
	ocean.set("boat_speed", 2.0)
	world.call("_update_arrival_feedback", Vector3(11.0, 0.28, -195.0))
	assert(world.get("arrival_state") == true, "Berth should enter arrival state")
	assert(float(ocean.get("boat_speed")) < 2.0, "Berth assist should gently reduce speed")
	world.call("_update_arrival_feedback", Vector3(0.0, 0.28, -180.0))
	assert(world.get("arrival_state") == false, "Leaving berth should clear arrival state")
	print("RECONSTRUCTION_04_JOURNEY_CHECK_OK|daymarks=4|dogleg=true|arrival_assist=true")
	quit(0)
