extends SceneTree

const PROTOTYPE_SCRIPT := preload("res://visual_prototype_3d.gd")
const STEP := 1.0 / 60.0
const SAILING_STATE := 2

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	await _check_waterline_is_visual_only()
	await _check_forward_acceleration_and_coasting()
	await _check_braking_and_reverse()
	await _check_smooth_stop()
	await _check_steering_and_no_side_slip()
	await _check_reset_to_start()
	await _check_no_automatic_arrival()
	await _check_wake_stops_and_fades()
	await _check_manual_propulsion_is_disabled_outside_sea_trial()

	if failures.is_empty():
		print("SEA_TRIAL_01_NAVIGATION_CHECK: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("SEA_TRIAL_01_NAVIGATION_CHECK: FAIL (%d)" % failures.size())
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


func _check_waterline_is_visual_only() -> void:
	var prototype := await _new_sea_trial()
	_check(prototype.boat_visual_root != null, "Boat visual waterline root was not created.")
	_check(is_equal_approx(prototype.boat_visual_root.position.y, -0.15), "Boat visual waterline offset is not -0.15 m.")
	_check(prototype.boat_travel_position.is_equal_approx(prototype.BOAT_START_POSITION), "Waterline adjustment changed the logical boat position.")
	var hull_min_y := -0.48
	var hull_max_y := 0.37
	var local_waterline: float = -(prototype.BOAT_START_POSITION.y + prototype.BOAT_VISUAL_WATERLINE_OFFSET_Y) / prototype.HULL_VISUAL_SCALE
	var submerged_fraction: float = (local_waterline - hull_min_y) / (hull_max_y - hull_min_y)
	_check(submerged_fraction >= 0.20 and submerged_fraction <= 0.30, "Calculated hull immersion is outside 20-30 percent (%.3f)." % submerged_fraction)
	print("SEA_TRIAL_01_HULL_SUBMERGED_FRACTION=%.3f" % submerged_fraction)
	await _dispose(prototype)


func _check_forward_acceleration_and_coasting() -> void:
	var prototype := await _new_sea_trial()
	await _step(prototype, 5.0, 1.0)
	var powered_speed: float = prototype.current_travel_speed
	_check(powered_speed > prototype.JOURNEY_TEST_FORWARD_SPEED * 3.8, "W did not reach approximately four times normal test speed (%.3f)." % powered_speed)
	_check(powered_speed <= prototype.SEA_TRIAL_MAX_FORWARD_SPEED + 0.001, "W exceeded the configured forward maximum.")
	await _step(prototype, 1.0, 0.0)
	var coast_speed: float = prototype.current_travel_speed
	_check(coast_speed < powered_speed, "Releasing W did not begin gradual deceleration.")
	_check(coast_speed > powered_speed * 0.90, "Releasing W removed too much inertia in the first second.")
	print("SEA_TRIAL_01_FORWARD_MAX=%.3f|COAST_AFTER_1S=%.3f" % [powered_speed, coast_speed])
	await _dispose(prototype)


func _check_braking_and_reverse() -> void:
	var prototype := await _new_sea_trial()
	await _step(prototype, 4.0, 1.0)
	await _step(prototype, 4.5, -1.0)
	_check(prototype.current_travel_speed < -0.05, "Holding S did not brake through zero and enter reverse.")
	_check(absf(prototype.current_travel_speed) <= prototype.SEA_TRIAL_MAX_REVERSE_SPEED + 0.001, "Reverse exceeded its configured maximum.")
	var diagnostics: Dictionary = prototype.call("get_sea_trial_diagnostics")
	_check(String(diagnostics["drive_state"]) == "REVERSE", "Sea Trial diagnostics did not report REVERSE.")
	await _dispose(prototype)


func _check_smooth_stop() -> void:
	var prototype := await _new_sea_trial()
	await _step(prototype, 4.0, 1.0)
	var speed_before_stop: float = prototype.current_travel_speed
	prototype.call("request_sea_trial_stop")
	await _step(prototype, 0.5)
	_check(prototype.current_travel_speed > 0.0, "Space stop changed speed to zero instantly.")
	_check(prototype.current_travel_speed < speed_before_stop, "Space stop did not begin decelerating.")
	await _step(prototype, 6.0)
	_check(is_zero_approx(prototype.current_travel_speed), "Space stop did not settle at zero.")
	await _dispose(prototype)


func _check_steering_and_no_side_slip() -> void:
	var prototype := await _new_sea_trial()
	await _step(prototype, 2.0, 1.0, -1.0)
	_check(prototype.boat_heading > 0.05, "A did not turn left in Sea Trial mode.")
	var expected_velocity: Vector3 = prototype._get_heading_forward() * prototype.current_travel_speed
	_check(prototype.actual_travel_velocity.is_equal_approx(expected_velocity), "Sea Trial velocity did not remain aligned with the hull heading.")
	await _step(prototype, 18.0, 1.0, -1.0)
	_check(absf(prototype.boat_heading) <= PI, "Sea Trial heading escaped wrapped angle bounds.")
	await _dispose(prototype)


func _check_reset_to_start() -> void:
	var prototype := await _new_sea_trial()
	await _step(prototype, 3.0, 1.0, 1.0)
	_check(not prototype.boat_travel_position.is_equal_approx(prototype.BOAT_START_POSITION), "Boat did not leave the start before reset check.")
	prototype.call("reset_sea_trial")
	_check(prototype.boat_travel_position.is_equal_approx(prototype.BOAT_START_POSITION), "Backspace reset did not restore the start position.")
	_check(is_zero_approx(prototype.current_travel_speed), "Backspace reset did not clear speed.")
	_check(is_zero_approx(prototype.boat_heading), "Backspace reset did not restore heading.")
	_check(prototype.wake_history_points.is_empty(), "Backspace reset did not clear historical wake.")
	await _dispose(prototype)


func _check_no_automatic_arrival() -> void:
	var prototype := await _new_sea_trial()
	await _step(prototype, 20.0, 1.0)
	_check(not bool(prototype.call("consume_journey_arrival_request")), "Sea Trial incorrectly requested Journey arrival near or beyond the island.")
	_check(prototype.last_voyage_state == SAILING_STATE, "Sea Trial changed the VoyageState outside main.gd.")
	await _dispose(prototype)


func _check_wake_stops_and_fades() -> void:
	var prototype := await _new_sea_trial()
	await _step(prototype, 2.5, 1.0)
	_check(not prototype.wake_history_points.is_empty(), "Moving Sea Trial boat did not generate wake.")
	prototype.call("request_sea_trial_stop")
	prototype.call("set_sea_trial_propulsion_intent", 0.0)
	var no_generation_time := -1.0
	var wake_empty_time := -1.0
	var points_when_generation_stopped := -1
	for frame in range(int(round(9.0 / STEP))):
		prototype.call("update_voyage", STEP, 0.0, SAILING_STATE)
		var elapsed := float(frame + 1) * STEP
		if no_generation_time < 0.0 and absf(prototype.current_travel_speed) < prototype.WAKE_GENERATION_MIN_SPEED:
			no_generation_time = elapsed
			points_when_generation_stopped = prototype.wake_history_points.size()
		if no_generation_time >= 0.0:
			_check(prototype.wake_history_points.size() <= points_when_generation_stopped, "Near-zero boat continued adding wake points.")
			points_when_generation_stopped = prototype.wake_history_points.size()
			if prototype.wake_history_points.is_empty():
				wake_empty_time = elapsed
				break
	_check(no_generation_time > 0.0, "Wake generation never stopped near zero speed.")
	_check(wake_empty_time > 0.0, "Existing wake never fully faded after stopping.")
	var fade_after_stop := wake_empty_time - no_generation_time
	_check(fade_after_stop >= 2.0 and fade_after_stop <= 2.8, "Wake fade after generation stopped was not approximately 2-3 seconds (%.3f)." % fade_after_stop)
	_check(is_equal_approx(prototype.WAKE_SEGMENT_LIFETIME, 2.6), "Wake lifetime is not 2.6 seconds.")
	print("SEA_TRIAL_01_WAKE_FADE_AFTER_STOP=%.3f" % fade_after_stop)
	await _dispose(prototype)


func _check_manual_propulsion_is_disabled_outside_sea_trial() -> void:
	var prototype: Node3D = PROTOTYPE_SCRIPT.new()
	root.add_child(prototype)
	await process_frame
	prototype.call("set_sea_trial_propulsion_intent", 1.0)
	for _frame in range(60):
		prototype.call("update_voyage", STEP, 0.0, SAILING_STATE)
	_check(not prototype.sea_trial_active, "Sea Trial was active in normal mode.")
	_check(is_equal_approx(prototype.current_travel_speed, prototype.AUTO_FORWARD_SPEED), "Manual throttle changed normal automatic sailing speed.")
	await _dispose(prototype)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
