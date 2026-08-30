extends SceneTree

const PROTOTYPE_SCRIPT := preload("res://visual_prototype_3d.gd")
const STEP := 1.0 / 60.0
const SAILING_STATE := 2

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	await _check_island_contact()
	await _check_contact_can_escape_with_reverse()
	await _check_contact_can_escape_with_turn_and_forward()
	await _check_soft_world_boundary()

	if failures.is_empty():
		print("SEA_TRIAL_02_WORLD_CHECK: PASS")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	print("SEA_TRIAL_02_WORLD_CHECK: FAIL (%d)" % failures.size())
	quit(1)


func _new_sea_trial() -> Node3D:
	var prototype: Node3D = PROTOTYPE_SCRIPT.new()
	root.add_child(prototype)
	await process_frame
	prototype.call("set_sea_trial_mode", true)
	return prototype


func _dispose(prototype: Node3D) -> void:
	prototype.queue_free()
	await process_frame


func _step(prototype: Node3D, seconds: float, propulsion: float = 0.0, steering: float = 0.0) -> void:
	prototype.call("set_sea_trial_propulsion_intent", propulsion)
	prototype.call("set_steering_intent", steering)
	for _frame in range(int(round(seconds / STEP))):
		prototype.call("update_voyage", STEP, 0.0, SAILING_STATE)


func _check_island_contact() -> void:
	var prototype := await _new_sea_trial()
	await _step(prototype, 20.0, 1.0)
	var diagnostics: Dictionary = prototype.call("get_sea_trial_diagnostics")
	_check(bool(diagnostics["land_contact"]), "Straight Sea Trial did not register contact with the island collision zone.")
	_check(is_zero_approx(float(diagnostics["signed_speed"])), "Island contact did not reduce forward speed to zero.")
	_check(not prototype.call("_is_inside_sea_trial_island", prototype.boat_travel_position), "Boat position entered the simplified island collision region.")
	_check(prototype.boat_travel_position.z > prototype.JOURNEY_TEST_DESTINATION_POSITION.z - prototype.SEA_TRIAL_ISLAND_COLLISION_RADIUS_Z - 0.01, "Boat was pushed through the island instead of stopping at its safe boundary.")

	var heading_before: float = prototype.boat_heading
	await _step(prototype, 1.0, 0.0, -1.0)
	_check(absf(angle_difference(heading_before, prototype.boat_heading)) > 0.01, "A/D steering stopped working while the boat was touching land.")
	await _dispose(prototype)


func _check_contact_can_escape_with_reverse() -> void:
	var prototype := await _new_sea_trial()
	await _step(prototype, 20.0, 1.0)
	var contact_position: Vector3 = prototype.boat_travel_position
	await _step(prototype, 2.5, -1.0)
	_check(prototype.current_travel_speed < -0.05, "S did not produce reverse motion after island contact.")
	_check(prototype.boat_travel_position.z > contact_position.z + 0.05, "Reverse motion did not move the boat away from the island.")
	_check(not bool(prototype.call("get_sea_trial_diagnostics")["land_contact"]), "Land contact remained latched after the boat backed away.")
	await _dispose(prototype)


func _check_contact_can_escape_with_turn_and_forward() -> void:
	var prototype := await _new_sea_trial()
	await _step(prototype, 20.0, 1.0)
	var contact_position: Vector3 = prototype.boat_travel_position
	await _step(prototype, 1.5, 0.0, -1.0)
	var turned_heading: float = prototype.boat_heading
	await _step(prototype, 3.0, 1.0, -1.0)
	_check(absf(angle_difference(0.0, turned_heading)) > 0.05, "Turning away from the shore did not change the escape heading.")
	_check(prototype.boat_travel_position.distance_to(contact_position) > 0.05, "W after turning did not move the boat away from the contact position.")
	await _dispose(prototype)


func _check_soft_world_boundary() -> void:
	var prototype := await _new_sea_trial()
	prototype.boat_travel_position = Vector3(19.5, prototype.BOAT_START_POSITION.y, -10.0)
	prototype.boat_heading = -PI * 0.5
	prototype.target_boat_heading = prototype.boat_heading
	await _step(prototype, 5.0, 1.0)
	var boundary_diagnostics: Dictionary = prototype.call("get_sea_trial_diagnostics")
	_check(float(boundary_diagnostics["boundary_factor"]) < 1.0, "Outer boundary did not reduce outward propulsion in the soft margin.")
	_check(prototype.boat_travel_position.x <= prototype.SEA_TRIAL_WORLD_MAX_X + 0.001, "Boat crossed the configured world X boundary.")
	_check(absf(prototype.current_travel_speed) <= prototype.SEA_TRIAL_MAX_FORWARD_SPEED + 0.001, "Soft boundary produced an invalid speed.")

	var x_at_edge: float = prototype.boat_travel_position.x
	prototype.boat_heading = PI * 0.5
	prototype.target_boat_heading = prototype.boat_heading
	await _step(prototype, 2.0, 1.0)
	var inward_diagnostics: Dictionary = prototype.call("get_sea_trial_diagnostics")
	_check(prototype.boat_travel_position.x < x_at_edge - 0.05, "Turning inward did not restore movement away from the outer boundary.")
	_check(float(inward_diagnostics["boundary_factor"]) > 0.95, "Boundary attenuation did not clear promptly after turning inward.")
	await _dispose(prototype)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
