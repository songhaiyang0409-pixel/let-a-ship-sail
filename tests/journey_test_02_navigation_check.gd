extends SceneTree

const PROTOTYPE_SCRIPT := preload("res://visual_prototype_3d.gd")
const STEP := 1.0 / 60.0
const SAILING_STATE := 2
const ARRIVING_STATE := 4
const ARRIVED_STATE := 5

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	await _check_visual_scale_layers()
	await _check_left_turn_and_heading_hold()
	await _check_right_turn()
	await _check_full_circle_steering()
	await _check_camera_look_does_not_steer()
	await _check_full_circle_camera_orbit_and_follow_lag()
	await _check_wake_history_stays_in_world_space()
	await _check_turning_can_miss_destination()
	await _check_automatic_arrival_timing_and_drift()
	await _check_fast_travel_and_arrival_deceleration()
	await _check_fast_travel_is_disabled_outside_arrival_test()

	if failures.is_empty():
		print("JOURNEY_TEST_02_NAVIGATION_CHECK: PASS")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	print("JOURNEY_TEST_02_NAVIGATION_CHECK: FAIL (%d)" % failures.size())
	quit(1)


func _new_prototype() -> Node3D:
	var prototype: Node3D = PROTOTYPE_SCRIPT.new()
	root.add_child(prototype)
	await process_frame
	prototype.call("set_journey_arrival_test_mode", true)
	return prototype


func _dispose_prototype(prototype: Node3D) -> void:
	prototype.queue_free()
	await process_frame


func _step_prototype(prototype: Node3D, seconds: float, steering: float = 0.0, state: int = SAILING_STATE) -> void:
	prototype.call("set_steering_intent", steering)
	var frame_count := int(round(seconds / STEP))
	for _frame in range(frame_count):
		prototype.call("update_voyage", STEP, 0.0, state)


func _check_visual_scale_layers() -> void:
	var prototype := await _new_prototype()
	_check(prototype.hull_visual_root != null, "Hull visual root was not created.")
	_check(prototype.rig_visual_root != null, "Rig visual root was not created.")
	_check(prototype.hull_visual_root.scale.is_equal_approx(Vector3.ONE * 0.5), "Hull visual scale is not 50 percent.")
	_check(prototype.rig_visual_root.scale.is_equal_approx(Vector3.ONE * (2.0 / 3.0)), "Rig visual scale is not two thirds.")
	_check(prototype.boat_travel_position.is_equal_approx(prototype.BOAT_START_POSITION), "Visual scaling changed the logical boat position.")
	await _dispose_prototype(prototype)


func _check_left_turn_and_heading_hold() -> void:
	var prototype := await _new_prototype()
	await _step_prototype(prototype, 2.0, -1.0)
	var heading_after_left: float = prototype.boat_heading
	var velocity_after_left: Vector3 = prototype.actual_travel_velocity
	_check(heading_after_left > 0.05, "A/left intent did not produce a positive Godot yaw (left turn).")
	_check(velocity_after_left.x < -0.01, "A/left intent did not curve the real route toward world left.")

	await _step_prototype(prototype, 2.0, 0.0)
	var heading_after_release: float = prototype.boat_heading
	var diagnostics: Dictionary = prototype.call("get_journey_diagnostics")
	var release_catch_up_degrees := absf(rad_to_deg(angle_difference(heading_after_left, heading_after_release)))
	_check(release_catch_up_degrees < 5.5, "Releasing A changed heading by more than the existing smoothing catch-up (%.3f degrees)." % release_catch_up_degrees)
	_check(float(diagnostics["slip_angle_degrees"]) < 0.01, "Heading and actual velocity diverged after releasing A.")
	await _dispose_prototype(prototype)


func _check_right_turn() -> void:
	var prototype := await _new_prototype()
	await _step_prototype(prototype, 2.0, 1.0)
	_check(prototype.boat_heading < -0.05, "D/right intent did not produce a negative Godot yaw (right turn).")
	_check(prototype.actual_travel_velocity.x > 0.01, "D/right intent did not curve the real route toward world right.")
	var diagnostics: Dictionary = prototype.call("get_journey_diagnostics")
	_check(float(diagnostics["slip_angle_degrees"]) < 0.01, "Heading and actual velocity diverged during D/right turn.")
	await _dispose_prototype(prototype)


func _check_full_circle_steering() -> void:
	var prototype := await _new_prototype()
	prototype.call("set_steering_intent", -1.0)
	var previous_heading: float = prototype.boat_heading
	var accumulated_turn := 0.0
	var maximum_slip := 0.0
	for _frame in range(int(round(20.0 / STEP))):
		prototype.call("update_voyage", STEP, 0.0, SAILING_STATE)
		accumulated_turn += absf(angle_difference(previous_heading, prototype.boat_heading))
		previous_heading = prototype.boat_heading
		var diagnostics: Dictionary = prototype.call("get_journey_diagnostics")
		maximum_slip = maxf(maximum_slip, float(diagnostics["slip_angle_degrees"]))
	_check(accumulated_turn > TAU + 0.5, "Continuous A steering did not complete a full circle (%.3f radians)." % accumulated_turn)
	_check(maximum_slip < 0.01, "Heading and velocity diverged during full-circle steering.")
	await _dispose_prototype(prototype)


func _check_camera_look_does_not_steer() -> void:
	var prototype := await _new_prototype()
	await _step_prototype(prototype, 1.0)
	var heading_before_look: float = prototype.boat_heading
	prototype.call("add_camera_look_intent", -100.0, -80.0)
	_check(prototype.camera_look_target > 0.0, "Dragging mouse left did not produce a left camera orbit.")
	await _step_prototype(prototype, 1.0)
	_check(absf(angle_difference(heading_before_look, prototype.boat_heading)) < 0.001, "Mouse look changed the boat heading.")
	_check(absf(prototype.camera_look_target) > 0.1, "Mouse look intent did not change the camera orbit target.")
	await _dispose_prototype(prototype)

	var right_prototype := await _new_prototype()
	right_prototype.call("add_camera_look_intent", 100.0, 0.0)
	_check(right_prototype.camera_look_target < 0.0, "Dragging mouse right did not produce a right camera orbit.")
	await _dispose_prototype(right_prototype)


func _check_full_circle_camera_orbit_and_follow_lag() -> void:
	var prototype := await _new_prototype()
	var original_heading: float = prototype.boat_heading
	var previous_look: float = prototype.camera_look_angle
	var accumulated_orbit := 0.0
	for _sample in range(52):
		prototype.call("add_camera_look_intent", -35.0, 0.0)
		await _step_prototype(prototype, 0.10)
		accumulated_orbit += absf(angle_difference(previous_look, prototype.camera_look_angle))
		previous_look = prototype.camera_look_angle
	_check(accumulated_orbit > TAU, "Mouse orbit did not complete a full 360-degree observation (%.3f radians)." % accumulated_orbit)
	_check(absf(angle_difference(original_heading, prototype.boat_heading)) < 0.001, "Full camera orbit changed boat heading.")

	prototype.call("reset_camera")
	await _step_prototype(prototype, 1.0)
	await _step_prototype(prototype, 1.5, -1.0)
	var camera_lag := absf(angle_difference(prototype.camera_follow_heading, prototype.boat_heading))
	_check(camera_lag > 0.04, "Camera heading remained welded to the boat during steering.")
	_check(camera_lag < 0.8, "Camera heading follow lag became excessive.")
	await _dispose_prototype(prototype)


func _check_wake_history_stays_in_world_space() -> void:
	var prototype := await _new_prototype()
	await _step_prototype(prototype, 1.0)
	_check(not prototype.wake_history_points.is_empty(), "No wake history point was generated during straight sailing.")
	if prototype.wake_history_points.is_empty():
		await _dispose_prototype(prototype)
		return

	var historical_index: int = prototype.wake_history_points.size() - 1
	var historical_position: Vector3 = prototype.wake_history_points[historical_index]
	var historical_right: Vector3 = prototype.wake_history_rights[historical_index]
	# Keep this comparison inside the new 2.6-second wake lifetime. Expired
	# history is expected to disappear; surviving history must stay world-fixed.
	await _step_prototype(prototype, 1.0, -1.0)
	_check(prototype.wake_history_points[historical_index].is_equal_approx(historical_position), "An old wake history point moved with the current boat position.")
	_check(prototype.wake_history_rights[historical_index].is_equal_approx(historical_right), "An old wake tangent rotated to the current heading.")
	var newest_right: Vector3 = prototype.wake_history_rights[prototype.wake_history_rights.size() - 1]
	_check(historical_right.angle_to(newest_right) > 0.2, "New wake history points did not follow the curved route tangent.")
	await _dispose_prototype(prototype)


func _check_turning_can_miss_destination() -> void:
	var prototype := await _new_prototype()
	await _step_prototype(prototype, 2.0, -1.0)
	prototype.call("set_steering_intent", 0.0)
	var false_arrival := false
	for _frame in range(int(round(75.0 / STEP))):
		prototype.call("update_voyage", STEP, 0.0, SAILING_STATE)
		if bool(prototype.call("consume_journey_arrival_request")):
			false_arrival = true
			break
	_check(not false_arrival, "Turning away from the target incorrectly triggered arrival.")
	await _dispose_prototype(prototype)


func _check_automatic_arrival_timing_and_drift() -> void:
	var prototype := await _new_prototype()
	var arrival_request_time := -1.0
	for frame in range(int(round(65.0 / STEP))):
		prototype.call("update_voyage", STEP, 0.0, SAILING_STATE)
		if bool(prototype.call("consume_journey_arrival_request")):
			arrival_request_time = float(frame + 1) * STEP
			break
	_check(arrival_request_time >= 45.0 and arrival_request_time <= 55.0, "Automatic arrival request was not reached near 50 seconds (actual %.2f)." % arrival_request_time)
	print("JOURNEY_TEST_02_NORMAL_ARRIVAL_REQUEST=%.2f" % arrival_request_time)

	await _step_prototype(prototype, 7.0, 0.0, ARRIVING_STATE)
	var arriving_diagnostics: Dictionary = prototype.call("get_journey_diagnostics")
	_check(float(arriving_diagnostics["speed"]) <= 0.02, "ARRIVING did not reduce speed to the drift range after 7 seconds.")
	await _step_prototype(prototype, 1.0, 0.0, ARRIVED_STATE)
	var arrived_diagnostics: Dictionary = prototype.call("get_journey_diagnostics")
	_check(float(arrived_diagnostics["speed"]) > 0.0, "ARRIVED incorrectly froze the boat instead of retaining drift.")
	_check(float(arrived_diagnostics["speed"]) <= 0.02, "ARRIVED drift speed remained too high.")
	await _dispose_prototype(prototype)


func _check_fast_travel_and_arrival_deceleration() -> void:
	var prototype := await _new_prototype()
	prototype.call("set_test_fast_intent", true)
	var arrival_request_time := -1.0
	var observed_fast := false
	for frame in range(int(round(25.0 / STEP))):
		prototype.call("update_voyage", STEP, 0.0, SAILING_STATE)
		var diagnostics: Dictionary = prototype.call("get_journey_diagnostics")
		observed_fast = observed_fast or bool(diagnostics["test_fast_active"])
		if bool(prototype.call("consume_journey_arrival_request")):
			arrival_request_time = float(frame + 1) * STEP
			break
	_check(observed_fast, "Journey Test 02 fast travel never became active.")
	_check(arrival_request_time > 0.0 and arrival_request_time < 20.0, "Fast travel did not reach ARRIVING within 20 seconds (actual %.2f)." % arrival_request_time)
	print("JOURNEY_TEST_02_FAST_ARRIVAL_REQUEST=%.2f" % arrival_request_time)

	await _step_prototype(prototype, 7.0, 0.0, ARRIVING_STATE)
	var arriving_diagnostics: Dictionary = prototype.call("get_journey_diagnostics")
	_check(not bool(arriving_diagnostics["test_fast_active"]), "Fast travel remained active during ARRIVING.")
	_check(float(arriving_diagnostics["speed"]) <= 0.02, "Fast travel did not return to drift speed during the 7-second ARRIVING state.")
	await _dispose_prototype(prototype)


func _check_fast_travel_is_disabled_outside_arrival_test() -> void:
	var prototype: Node3D = PROTOTYPE_SCRIPT.new()
	root.add_child(prototype)
	await process_frame
	prototype.call("set_test_fast_intent", true)
	await _step_prototype(prototype, 1.0)
	var diagnostics: Dictionary = prototype.call("get_journey_diagnostics")
	_check(not bool(diagnostics["test_fast_active"]), "Fast travel became active outside Journey Test 02.")
	_check(is_equal_approx(float(diagnostics["speed"]), prototype.AUTO_FORWARD_SPEED), "Normal mode speed changed when Shift fast travel was requested.")
	await _dispose_prototype(prototype)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
