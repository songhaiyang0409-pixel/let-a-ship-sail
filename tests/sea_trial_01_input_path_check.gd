extends SceneTree

const MAIN_SCRIPT := preload("res://main.gd")
const STEP := 1.0 / 60.0
const SAILING_STATE := 2
const EPSILON := 0.002

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	await _check_w_s_path_brakes_before_reverse()
	await _check_space_path_stops_without_held_input()
	await _check_space_path_restarts_after_stop()

	Input.action_release("sea_trial_forward")
	Input.action_release("sea_trial_reverse")
	Input.action_release("sea_trial_space")
	Input.action_release("sea_trial_reset")
	if failures.is_empty():
		print("SEA_TRIAL_01_INPUT_PATH_CHECK: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("SEA_TRIAL_01_INPUT_PATH_CHECK: FAIL (%d)" % failures.size())
	quit(1)


func _new_sea_trial_main() -> Node:
	var main: Node = MAIN_SCRIPT.new()
	root.add_child(main)
	await process_frame
	main.is_sea_trial_01_mode = true
	main.call("_ensure_sea_trial_input_actions")
	main.visual_prototype_3d.call("set_sea_trial_mode", true)
	main.call("_set_voyage_state", SAILING_STATE)
	return main


func _dispose(main: Node) -> void:
	Input.action_release("sea_trial_forward")
	Input.action_release("sea_trial_reverse")
	Input.action_release("sea_trial_space")
	main.queue_free()
	await process_frame


func _step(main: Node, seconds: float) -> void:
	for _frame in range(int(round(seconds / STEP))):
		main.call("_process", STEP)


func _check_w_s_path_brakes_before_reverse() -> void:
	var main := await _new_sea_trial_main()
	Input.action_press("sea_trial_forward")
	await _step(main, 4.0)
	Input.action_release("sea_trial_forward")
	var powered_speed: float = main.visual_prototype_3d.current_travel_speed
	_check(powered_speed > 2.0, "Real W InputMap path did not produce clear forward speed.")

	Input.action_press("sea_trial_reverse")
	var previous_speed := powered_speed
	var saw_zero := false
	var negative_before_zero := false
	var saw_continuous_decrease := true
	for _frame in range(int(round(4.0 / STEP))):
		main.call("_process", STEP)
		var speed: float = main.visual_prototype_3d.current_travel_speed
		if speed > previous_speed + 0.0001 and not saw_zero:
			saw_continuous_decrease = false
		if speed < -EPSILON and not saw_zero:
			negative_before_zero = true
		if absf(speed) <= EPSILON:
			saw_zero = true
		previous_speed = speed
	_check(saw_continuous_decrease, "Real S InputMap path did not keep reducing forward speed before zero.")
	_check(saw_zero, "Real S InputMap path never reached true zero before reverse.")
	_check(not negative_before_zero, "Real S InputMap path entered reverse before reaching zero.")

	await _step(main, 2.5)
	_check(main.visual_prototype_3d.current_travel_speed < -0.05, "Real S InputMap path did not reverse after reaching zero.")
	await _dispose(main)


func _check_space_path_stops_without_held_input() -> void:
	var main := await _new_sea_trial_main()
	Input.action_press("sea_trial_forward")
	await _step(main, 4.0)
	Input.action_release("sea_trial_forward")
	await _step(main, 0.2)
	var speed_before_space: float = main.visual_prototype_3d.current_travel_speed
	_press_key(main, KEY_SPACE)
	main.call("_process", STEP)
	var speed_after_space: float = main.visual_prototype_3d.current_travel_speed
	_check(speed_after_space < speed_before_space, "Real Space InputMap path did not begin braking immediately.")
	_check(speed_after_space > 0.0, "Real Space InputMap path stopped instantly instead of smoothing.")

	await _step(main, 7.0)
	_check(is_zero_approx(main.visual_prototype_3d.current_travel_speed), "Releasing Space did not continue braking to zero.")
	await _step(main, 2.0)
	_check(is_zero_approx(main.visual_prototype_3d.current_travel_speed), "Stopped Sea Trial boat restarted without input.")
	await _dispose(main)


func _check_space_path_restarts_after_stop() -> void:
	var main := await _new_sea_trial_main()
	_check(is_zero_approx(main.visual_prototype_3d.current_travel_speed), "Space restart test did not begin stopped.")
	_press_key(main, KEY_SPACE)
	main.call("_process", STEP)
	await _step(main, 1.2)
	_check(main.visual_prototype_3d.current_travel_speed > 0.05, "Second Space press did not restart Sea Trial from a full stop.")
	await _dispose(main)


func _press_key(main: Node, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	main.call("_input", event)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
