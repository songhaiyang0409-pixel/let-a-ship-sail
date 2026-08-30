extends Node

const VOYAGE_TEXTURE_PATH := "res://assets/approach/voyage_base_clean.png"
const ARRIVAL_TEXTURE_PATH := "res://assets/approach/arrival_harbor_entrance.png"
const ISLAND_TEXTURE_PATH := "res://assets/approach/island_cutout.png"
const VISUAL_PROTOTYPE_3D_SCRIPT := preload("res://visual_prototype_3d.gd")

enum VoyageState {
	IDLE_PORT,
	DEPARTING,
	SAILING,
	PAUSED,
	ARRIVING,
	ARRIVED,
}

const DEPARTING_DURATION := 2.2
const ARRIVING_DURATION := 1.5
const DEBUG_VOYAGE_CONTROLS := true
const DEBUG_PREVIEW_DURATION := 24.0
const JOURNEY_TEST_01_DURATION := 180.0
const JOURNEY_TEST_02_ARRIVING_DURATION := 7.0
const APPROACH_POWER := 1.55
const ISLAND_START_POS := Vector2(540.0, 710.0)
const ISLAND_END_POS := Vector2(540.0, 760.0)
const ISLAND_START_SCALE := 0.075
const ISLAND_END_SCALE := 0.58
const ISLAND_SILHOUETTE_ALPHA_START := 0.58
const ISLAND_SILHOUETTE_ALPHA_END := 0.0
const ISLAND_DETAIL_ALPHA_START := 0.12
const ISLAND_DETAIL_ALPHA_END := 1.0
const WATER_WARM_START := Color(0.02, 0.10, 0.16, 0.12)
const WATER_WARM_END := Color(0.10, 0.16, 0.15, 0.07)
const CAPTURE_DIR := "res://voyage_debug_captures"
const VISUAL_PROTOTYPE_V01 := true
const VISUAL_PROTOTYPE_CAPTURE_DIR := "res://visual_prototype_v02_captures"

class WaveOverlay extends Control:
	var voyage_progress := 0.0
	var voyage_time := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_voyage_visuals(progress: float, time: float) -> void:
		voyage_progress = clamp(progress, 0.0, 1.0)
		voyage_time = time
		queue_redraw()

	func _draw() -> void:
		var viewport_size := get_viewport_rect().size
		var water_start := viewport_size.y * 0.47
		var water_height := viewport_size.y - water_start

		for row in range(20):
			var depth := float(row) / 19.0
			var y := water_start + 20.0 + depth * water_height
			var points := PackedVector2Array()
			var speed := lerpf(0.22, 1.85, depth)
			var amplitude := lerpf(1.6, 8.5, depth) * lerpf(0.8, 1.25, voyage_progress)
			var wave_length := lerpf(0.011, 0.026, depth)
			var row_phase := voyage_time * speed + float(row) * 1.37 + voyage_progress * depth * 5.0

			for column in range(28):
				var x := -60.0 + float(column) * (viewport_size.x + 120.0) / 27.0
				var local_wave := sin(row_phase + x * wave_length) * amplitude
				local_wave += sin(row_phase * 0.63 + x * wave_length * 1.9) * amplitude * 0.28
				points.append(Vector2(x, y + local_wave))

			var alpha := lerpf(0.045, 0.15, depth) + float(row % 3) * 0.012
			var wave_color := Color(0.86, 0.97, 1.0, alpha)
			draw_polyline(points, wave_color, lerpf(1.2, 2.8, depth), true)

		var wake_alpha := 0.10 + voyage_progress * 0.08
		for trail in range(7):
			var trail_depth := float(trail) / 6.0
			var start_y := viewport_size.y * 0.78 + trail_depth * 58.0
			var half_width := 20.0 + trail_depth * 135.0
			var center_x := viewport_size.x * 0.5 + sin(voyage_time * 0.9 + trail_depth * 3.0) * 5.0
			var left := PackedVector2Array()
			var right := PackedVector2Array()
			for segment in range(10):
				var t := float(segment) / 9.0
				var y := start_y + t * 165.0
				var spread := half_width + t * 70.0
				var ripple := sin(voyage_time * 2.4 + t * 5.0 + trail_depth * 2.0) * 4.0
				left.append(Vector2(center_x - spread - ripple, y))
				right.append(Vector2(center_x + spread + ripple, y))
			var color := Color(0.92, 0.99, 1.0, wake_alpha * (1.0 - trail_depth * 0.78))
			draw_polyline(left, color, 2.0, true)
			draw_polyline(right, color, 2.0, true)

var background_holder: Control
var port_background: TextureRect
var voyage_background: TextureRect
var shade_overlay: ColorRect
var approach_root: Control
var island_root: Node2D
var island_silhouette_sprite: Sprite2D
var island_detail_sprite: Sprite2D
var wave_overlay: WaveOverlay
var timer_label: Label
var status_label: Label
var progress_bar: ProgressBar
var start_button: Button
var reward_label: Label
var sail_state_label: Label
var debug_panel: PanelContainer
var debug_slider: HSlider
var debug_preview_button: Button
var debug_progress_label: Label

var voyage_texture: Texture2D
var arrival_texture: Texture2D
var island_texture: Texture2D
var selected_duration := 10.0
var remaining := 10.0
var voyage_state := VoyageState.IDLE_PORT
var state_elapsed := 0.0
var motion_time := 0.0
var voyage_motion_time := 0.0
var forward_progress := 0.0
var departure_visual_progress := 0.0
var arrival_visual_progress := 0.0
var sail_power := 0.0
var target_sail_power := 0.0
var debug_progress_override := false
var debug_preview_active := false
var debug_preview_elapsed := 0.0
var is_capture_mode := false
var is_visual_prototype_capture_mode := false
var is_journey_test_01_mode := false
var is_journey_test_02_mode := false
var is_journey_test_02_capture_mode := false
var is_sea_trial_01_mode := false
var is_sea_trial_01_capture_mode := false
var is_sea_trial_02_mode := false
var is_sea_trial_02_capture_mode := false
var visual_prototype_3d: Node3D
var pc_camera_dragging := false
var pc_camera_reset_was_pressed := false
var journey_test_diagnostics_label: Label
var sea_trial_diagnostics_label: Label
var journey_test_elapsed := 0.0
var journey_last_logged_state := ""
var journey_last_logged_band := ""
var journey_last_logged_fast := false


func _ready() -> void:
	is_capture_mode = OS.get_cmdline_user_args().has("--capture-voyage-stages")
	is_visual_prototype_capture_mode = OS.get_cmdline_user_args().has("--capture-visual-v02") or OS.get_cmdline_user_args().has("--capture-visual-v01")
	is_journey_test_02_capture_mode = OS.get_cmdline_user_args().has("--capture-journey-test-02-2")
	is_journey_test_02_mode = OS.get_cmdline_user_args().has("--journey-test-02") or is_journey_test_02_capture_mode
	is_journey_test_01_mode = OS.get_cmdline_user_args().has("--journey-test-01") or is_journey_test_02_mode
	is_sea_trial_01_capture_mode = OS.get_cmdline_user_args().has("--capture-sea-trial-01")
	is_sea_trial_02_mode = OS.get_cmdline_user_args().has("--sea-trial-02")
	is_sea_trial_02_capture_mode = OS.get_cmdline_user_args().has("--capture-sea-trial-02")
	is_sea_trial_01_mode = (
		OS.get_cmdline_user_args().has("--sea-trial-01")
		or is_sea_trial_02_mode
		or is_sea_trial_01_capture_mode
		or is_sea_trial_02_capture_mode
	)
	if is_sea_trial_01_mode:
		_ensure_sea_trial_input_actions()

	if VISUAL_PROTOTYPE_V01:
		selected_duration = JOURNEY_TEST_01_DURATION if is_journey_test_01_mode else 25.0 * 60.0
		remaining = selected_duration
		_build_visual_prototype_v01()
		if is_sea_trial_01_mode and visual_prototype_3d.has_method("set_sea_trial_mode"):
			visual_prototype_3d.call("set_sea_trial_mode", true)
		elif is_journey_test_02_mode and visual_prototype_3d.has_method("set_journey_arrival_test_mode"):
			visual_prototype_3d.call("set_journey_arrival_test_mode", true)
		elif is_journey_test_01_mode and visual_prototype_3d.has_method("set_journey_test_mode"):
			visual_prototype_3d.call("set_journey_test_mode", true)
		_set_voyage_state(VoyageState.SAILING)
		if is_journey_test_02_mode and not is_journey_test_02_capture_mode:
			_build_journey_test_diagnostics()
			_update_journey_test_diagnostics()
		if is_sea_trial_01_mode and not is_sea_trial_01_capture_mode and not is_sea_trial_02_capture_mode:
			_build_sea_trial_diagnostics()
			_update_sea_trial_diagnostics()
		if is_sea_trial_01_capture_mode:
			call_deferred("_capture_sea_trial_01")
		if is_sea_trial_02_capture_mode:
			call_deferred("_capture_sea_trial_02")
		if is_journey_test_02_capture_mode:
			call_deferred("_capture_journey_test_02_2_wake")
		if is_visual_prototype_capture_mode:
			call_deferred("_capture_visual_prototype_v01")
		return

	voyage_texture = _load_project_image_texture(VOYAGE_TEXTURE_PATH)
	arrival_texture = _load_project_image_texture(ARRIVAL_TEXTURE_PATH)
	island_texture = _load_project_image_texture(ISLAND_TEXTURE_PATH)
	_build_background()
	_build_interface()
	_apply_voyage_progress(0.0)
	_update_interface()
	if is_capture_mode:
		call_deferred("_capture_voyage_stages")


func _process(delta: float) -> void:
	motion_time += delta
	if is_journey_test_02_mode:
		journey_test_elapsed += delta
	if VISUAL_PROTOTYPE_V01:
		_update_visual_pc_control_intent()

	if debug_preview_active:
		_update_debug_preview(delta)
		_animate_scene()
		_update_visual_prototype(delta)
		return

	match voyage_state:
		VoyageState.DEPARTING:
			voyage_motion_time += delta * 0.45
			state_elapsed += delta
			_update_departure_visual(state_elapsed / DEPARTING_DURATION)
			if state_elapsed >= DEPARTING_DURATION:
				_set_voyage_state(VoyageState.SAILING)
		VoyageState.SAILING:
			voyage_motion_time += delta
			if is_sea_trial_01_mode:
				pass
			elif is_journey_test_02_mode:
				if visual_prototype_3d != null and visual_prototype_3d.has_method("consume_journey_arrival_request"):
					if bool(visual_prototype_3d.call("consume_journey_arrival_request")):
						_set_voyage_state(VoyageState.ARRIVING)
			else:
				remaining = max(0.0, remaining - delta)
				_apply_voyage_progress(_get_timer_progress())
				_update_interface()
				if remaining <= 0.0:
					_set_voyage_state(VoyageState.ARRIVING)
		VoyageState.ARRIVING:
			voyage_motion_time += delta * 0.35
			state_elapsed += delta
			if not is_journey_test_02_mode:
				_update_arrival_visual(state_elapsed / ARRIVING_DURATION)
			var arriving_duration := JOURNEY_TEST_02_ARRIVING_DURATION if is_journey_test_02_mode else ARRIVING_DURATION
			if state_elapsed >= arriving_duration:
				_set_voyage_state(VoyageState.ARRIVED)

	_animate_scene()
	_update_visual_prototype(delta)
	if is_journey_test_02_mode:
		_update_journey_test_diagnostics()
	if is_sea_trial_01_mode:
		_update_sea_trial_diagnostics()


func _input(event: InputEvent) -> void:
	if not VISUAL_PROTOTYPE_V01 or visual_prototype_3d == null:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pc_camera_dragging = event.pressed
	elif event is InputEventMouseMotion and pc_camera_dragging:
		if visual_prototype_3d.has_method("add_camera_look_intent"):
			visual_prototype_3d.call("add_camera_look_intent", event.relative.x, event.relative.y)
	elif event is InputEventKey and event.pressed and not event.echo:
		if is_sea_trial_01_mode:
			if event.keycode == KEY_SPACE or event.physical_keycode == KEY_SPACE:
				if visual_prototype_3d.has_method("toggle_sea_trial_space"):
					visual_prototype_3d.call("toggle_sea_trial_space")
			elif event.keycode == KEY_BACKSPACE or event.physical_keycode == KEY_BACKSPACE:
				if visual_prototype_3d.has_method("reset_sea_trial"):
					visual_prototype_3d.call("reset_sea_trial")
		elif is_journey_test_02_mode and voyage_state == VoyageState.ARRIVED:
			if event.keycode == KEY_SPACE or event.physical_keycode == KEY_SPACE:
				if visual_prototype_3d.has_method("resume_journey_arrival_test"):
					visual_prototype_3d.call("resume_journey_arrival_test")
				_set_voyage_state(VoyageState.SAILING)


func _update_visual_pc_control_intent() -> void:
	if visual_prototype_3d == null or not visual_prototype_3d.has_method("set_steering_intent"):
		return
	var steering := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		steering -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		steering += 1.0
	visual_prototype_3d.call("set_steering_intent", steering)
	if visual_prototype_3d.has_method("set_sea_trial_propulsion_intent"):
		var propulsion := 0.0
		if is_sea_trial_01_mode:
			if Input.is_action_pressed("sea_trial_forward"):
				propulsion += 1.0
			if Input.is_action_pressed("sea_trial_reverse"):
				propulsion -= 1.0
		visual_prototype_3d.call("set_sea_trial_propulsion_intent", propulsion)
	if visual_prototype_3d.has_method("set_test_fast_intent"):
		var test_fast_pressed := (
			is_journey_test_02_mode
			and voyage_state == VoyageState.SAILING
			and Input.is_key_pressed(KEY_SHIFT)
		)
		visual_prototype_3d.call("set_test_fast_intent", test_fast_pressed)

	var reset_pressed := Input.is_key_pressed(KEY_R)
	if reset_pressed and not pc_camera_reset_was_pressed:
		if visual_prototype_3d.has_method("reset_camera"):
			visual_prototype_3d.call("reset_camera")
	pc_camera_reset_was_pressed = reset_pressed


func _ensure_sea_trial_input_actions() -> void:
	_ensure_sea_trial_action("sea_trial_forward", KEY_W)
	_ensure_sea_trial_action("sea_trial_reverse", KEY_S)
	_ensure_sea_trial_action("sea_trial_space", KEY_SPACE)
	_ensure_sea_trial_action("sea_trial_reset", KEY_BACKSPACE)


func _ensure_sea_trial_action(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for existing_event in InputMap.action_get_events(action_name):
		if existing_event is InputEventKey and (existing_event.physical_keycode == keycode or existing_event.keycode == keycode):
			return
	var key_event := InputEventKey.new()
	key_event.keycode = keycode
	key_event.physical_keycode = keycode
	InputMap.action_add_event(action_name, key_event)


func _build_sea_trial_diagnostics() -> void:
	var diagnostics_layer := CanvasLayer.new()
	diagnostics_layer.name = "SeaTrial01Diagnostics"
	diagnostics_layer.layer = 100
	add_child(diagnostics_layer)

	sea_trial_diagnostics_label = Label.new()
	sea_trial_diagnostics_label.name = "DiagnosticsLabel"
	sea_trial_diagnostics_label.position = Vector2(18.0, 18.0)
	sea_trial_diagnostics_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sea_trial_diagnostics_label.add_theme_font_size_override("font_size", 20)
	sea_trial_diagnostics_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0, 1.0))
	sea_trial_diagnostics_label.add_theme_color_override("font_outline_color", Color(0.02, 0.08, 0.12, 0.92))
	sea_trial_diagnostics_label.add_theme_constant_override("outline_size", 5)
	diagnostics_layer.add_child(sea_trial_diagnostics_label)


func _update_sea_trial_diagnostics() -> void:
	if sea_trial_diagnostics_label == null or visual_prototype_3d == null:
		return
	if not visual_prototype_3d.has_method("get_sea_trial_diagnostics"):
		return
	var diagnostics: Dictionary = visual_prototype_3d.call("get_sea_trial_diagnostics")
	sea_trial_diagnostics_label.text = (
		"SEA TRIAL\n"
		+ "速度: %.2f m/s\n" % float(diagnostics.get("speed", 0.0))
		+ "状态: %s\n" % String(diagnostics.get("drive_state", "STOPPED"))
		+ "油门: %+.0f%%\n" % (float(diagnostics.get("throttle_ratio", 0.0)) * 100.0)
		+ "W 前进 / S 刹车与倒船 / A D 转向\n"
		+ "Space 平滑停船 / R 镜头复位\n"
		+ "Backspace 返回起点"
	)

func _build_visual_prototype_v01() -> void:
	visual_prototype_3d = VISUAL_PROTOTYPE_3D_SCRIPT.new()
	visual_prototype_3d.name = "VisualPrototypeV01"
	add_child(visual_prototype_3d)


func _build_journey_test_diagnostics() -> void:
	var diagnostics_layer := CanvasLayer.new()
	diagnostics_layer.name = "JourneyTest02Diagnostics"
	diagnostics_layer.layer = 100
	add_child(diagnostics_layer)

	journey_test_diagnostics_label = Label.new()
	journey_test_diagnostics_label.name = "DiagnosticsLabel"
	journey_test_diagnostics_label.position = Vector2(18.0, 18.0)
	journey_test_diagnostics_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	journey_test_diagnostics_label.add_theme_font_size_override("font_size", 20)
	journey_test_diagnostics_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0, 1.0))
	journey_test_diagnostics_label.add_theme_color_override("font_outline_color", Color(0.02, 0.08, 0.12, 0.92))
	journey_test_diagnostics_label.add_theme_constant_override("outline_size", 5)
	diagnostics_layer.add_child(journey_test_diagnostics_label)


func _update_journey_test_diagnostics() -> void:
	if journey_test_diagnostics_label == null or visual_prototype_3d == null:
		return
	if not visual_prototype_3d.has_method("get_journey_diagnostics"):
		return

	var diagnostics: Dictionary = visual_prototype_3d.call("get_journey_diagnostics")
	var state_name := _get_voyage_state_name(voyage_state)
	var distance_band := String(diagnostics.get("distance_band", "FAR"))
	var test_fast_active := bool(diagnostics.get("test_fast_active", false))
	var fast_text := "TEST FAST ×4" if test_fast_active else "OFF"
	var prompt := ""
	if voyage_state == VoyageState.ARRIVED:
		prompt = "\nSpace 再次启航"

	journey_test_diagnostics_label.text = (
		"Journey Test 02\n"
		+ "状态: %s\n" % state_name
		+ "距离档位: %s\n" % distance_band
		+ "距离: %.1f m\n" % float(diagnostics.get("distance", 0.0))
		+ "速度: %.2f m/s\n" % float(diagnostics.get("speed", 0.0))
		+ "船头: %.1f°\n" % float(diagnostics.get("heading_degrees", 0.0))
		+ "侧滑角: %.2f°\n" % float(diagnostics.get("slip_angle_degrees", 0.0))
		+ "快进: %s" % fast_text
		+ prompt
	)

	if state_name != journey_last_logged_state or distance_band != journey_last_logged_band or test_fast_active != journey_last_logged_fast:
		print(
			"JOURNEY_TEST_02|t=%.2f|state=%s|band=%s|distance=%.2f|speed=%.3f|heading=%.2f|slip=%.3f|fast=%s" % [
				journey_test_elapsed,
				state_name,
				distance_band,
				float(diagnostics.get("distance", 0.0)),
				float(diagnostics.get("speed", 0.0)),
				float(diagnostics.get("heading_degrees", 0.0)),
				float(diagnostics.get("slip_angle_degrees", 0.0)),
				str(test_fast_active),
			]
		)
		journey_last_logged_state = state_name
		journey_last_logged_band = distance_band
		journey_last_logged_fast = test_fast_active


func _get_voyage_state_name(state: VoyageState) -> String:
	match state:
		VoyageState.IDLE_PORT:
			return "IDLE_PORT"
		VoyageState.DEPARTING:
			return "DEPARTING"
		VoyageState.SAILING:
			return "SAILING"
		VoyageState.PAUSED:
			return "PAUSED"
		VoyageState.ARRIVING:
			return "ARRIVING"
		VoyageState.ARRIVED:
			return "ARRIVED"
	return "UNKNOWN"


func _update_visual_prototype(delta: float) -> void:
	if visual_prototype_3d == null:
		return
	if visual_prototype_3d.has_method("update_voyage"):
		visual_prototype_3d.call("update_voyage", delta, forward_progress, voyage_state)


func _capture_visual_prototype_v01() -> void:
	if visual_prototype_3d == null:
		get_tree().quit(1)
		return

	var output_dir := ProjectSettings.globalize_path(VISUAL_PROTOTYPE_CAPTURE_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var shots := [
		{"file": "visual_v02_a_main_sailing.png", "camera": "normal", "progress": 0.22},
		{"file": "visual_v02_b_boat_close_three_quarter.png", "camera": "boat_close", "progress": 0.22},
		{"file": "visual_v02_c_phone_preview.png", "camera": "phone_preview", "progress": 0.22},
	]

	for shot in shots:
		var progress: float = float(shot["progress"])
		remaining = selected_duration * (1.0 - progress)
		_apply_voyage_progress(progress)
		if visual_prototype_3d.has_method("set_camera_shot"):
			visual_prototype_3d.call("set_camera_shot", String(shot["camera"]))
		for frame in range(18):
			_update_visual_prototype(1.0 / 60.0)
			await get_tree().process_frame
		var image := get_viewport().get_texture().get_image()
		var file_name: String = String(shot["file"])
		var error := image.save_png(output_dir.path_join(file_name))
		if error != OK:
			push_error("Cannot save visual prototype screenshot: %s" % file_name)

	get_tree().quit()


func _capture_journey_test_02_2_wake() -> void:
	if visual_prototype_3d == null:
		get_tree().quit(1)
		return
	set_process(false)
	var output_dir := ProjectSettings.globalize_path(VISUAL_PROTOTYPE_CAPTURE_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)
	visual_prototype_3d.call("set_steering_intent", -1.0)

	# Advance simulation faster than wall time while still rendering through the
	# real game camera. Six simulated seconds creates a readable curved history.
	for rendered_frame in range(48):
		for simulation_step in range(8):
			visual_prototype_3d.call("update_voyage", 1.0 / 60.0, 0.0, VoyageState.SAILING)
		await get_tree().process_frame
		if rendered_frame == 23:
			var turning_image := get_viewport().get_texture().get_image()
			var turning_error := turning_image.save_png(output_dir.path_join("journey_test_02_2_turning_camera_lag.png"))
			if turning_error != OK:
				push_error("Cannot save Journey Test 02.2 turning camera screenshot.")

	visual_prototype_3d.call("set_steering_intent", 0.0)
	for rendered_frame in range(16):
		for simulation_step in range(8):
			visual_prototype_3d.call("update_voyage", 1.0 / 60.0, 0.0, VoyageState.SAILING)
		await get_tree().process_frame

	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(output_dir.path_join("journey_test_02_2_curved_wake.png"))
	if error != OK:
		push_error("Cannot save Journey Test 02.2 curved wake screenshot.")
	get_tree().quit()


func _capture_sea_trial_01() -> void:
	if visual_prototype_3d == null:
		get_tree().quit(1)
		return
	set_process(false)
	var output_dir := ProjectSettings.globalize_path(VISUAL_PROTOTYPE_CAPTURE_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)
	visual_prototype_3d.call("set_camera_shot", "boat_close")
	visual_prototype_3d.call("set_sea_trial_propulsion_intent", 1.0)

	for _rendered_frame in range(36):
		for _simulation_step in range(6):
			visual_prototype_3d.call("update_voyage", 1.0 / 60.0, 0.0, VoyageState.SAILING)
		await get_tree().process_frame
	var moving_image := get_viewport().get_texture().get_image()
	var moving_error := moving_image.save_png(output_dir.path_join("sea_trial_01_waterline_moving.png"))
	if moving_error != OK:
		push_error("Cannot save Sea Trial 01 moving waterline screenshot.")

	visual_prototype_3d.call("request_sea_trial_stop")
	for _rendered_frame in range(78):
		for _simulation_step in range(6):
			visual_prototype_3d.call("update_voyage", 1.0 / 60.0, 0.0, VoyageState.SAILING)
		await get_tree().process_frame
	var stopped_image := get_viewport().get_texture().get_image()
	var stopped_error := stopped_image.save_png(output_dir.path_join("sea_trial_01_stopped_wake_faded.png"))
	if stopped_error != OK:
		push_error("Cannot save Sea Trial 01 stopped wake screenshot.")
	get_tree().quit()


func _capture_sea_trial_02() -> void:
	if visual_prototype_3d == null:
		get_tree().quit(1)
		return
	set_process(false)
	var output_dir := ProjectSettings.globalize_path(VISUAL_PROTOTYPE_CAPTURE_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)
	visual_prototype_3d.call("set_camera_shot", "normal")
	visual_prototype_3d.call("set_sea_trial_propulsion_intent", 1.0)

	# These are real game-camera frames from the same Sea Trial 02 world. The
	# simulation is stepped faster only so visual QA does not require waiting.
	for _rendered_frame in range(24):
		for _simulation_step in range(15):
			visual_prototype_3d.call("update_voyage", 1.0 / 60.0, 0.0, VoyageState.SAILING)
		await get_tree().process_frame
	var far_image := get_viewport().get_texture().get_image()
	var far_error := far_image.save_png(output_dir.path_join("sea_trial_02_far_island.png"))
	if far_error != OK:
		push_error("Cannot save Sea Trial 02 far-island screenshot.")

	for _rendered_frame in range(48):
		for _simulation_step in range(15):
			visual_prototype_3d.call("update_voyage", 1.0 / 60.0, 0.0, VoyageState.SAILING)
		await get_tree().process_frame
	var contact_image := get_viewport().get_texture().get_image()
	var contact_error := contact_image.save_png(output_dir.path_join("sea_trial_02_island_contact.png"))
	if contact_error != OK:
		push_error("Cannot save Sea Trial 02 island-contact screenshot.")

	visual_prototype_3d.call("reset_sea_trial")
	visual_prototype_3d.boat_travel_position = Vector3(21.0, visual_prototype_3d.BOAT_START_POSITION.y, -10.0)
	visual_prototype_3d.boat_heading = -PI * 0.5
	visual_prototype_3d.target_boat_heading = visual_prototype_3d.boat_heading
	visual_prototype_3d.call("set_sea_trial_propulsion_intent", 1.0)
	for _rendered_frame in range(18):
		for _simulation_step in range(10):
			visual_prototype_3d.call("update_voyage", 1.0 / 60.0, 0.0, VoyageState.SAILING)
		await get_tree().process_frame
	var boundary_image := get_viewport().get_texture().get_image()
	var boundary_error := boundary_image.save_png(output_dir.path_join("sea_trial_02_soft_boundary.png"))
	if boundary_error != OK:
		push_error("Cannot save Sea Trial 02 soft-boundary screenshot.")
	get_tree().quit()


func _load_project_image_texture(path: String) -> Texture2D:
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("Cannot load image texture: %s" % path)
		return ImageTexture.create_from_image(Image.create(16, 16, false, Image.FORMAT_RGBA8))
	return ImageTexture.create_from_image(image)


func _build_background() -> void:
	background_holder = Control.new()
	background_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_holder.pivot_offset = Vector2(540.0, 960.0)
	add_child(background_holder)

	port_background = _create_background_rect(arrival_texture)
	background_holder.add_child(port_background)

	voyage_background = _create_background_rect(voyage_texture)
	background_holder.add_child(voyage_background)
	_set_background_mix(1.0, 0.0)

	approach_root = Control.new()
	approach_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	approach_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_holder.add_child(approach_root)

	_build_approach_island()
	_set_voyage_scene_alpha(0.0)

	shade_overlay = ColorRect.new()
	shade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade_overlay.color = WATER_WARM_START
	shade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_holder.add_child(shade_overlay)

	wave_overlay = WaveOverlay.new()
	wave_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_holder.add_child(wave_overlay)


func _create_background_rect(texture: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.texture = texture
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _build_approach_island() -> void:
	island_root = Node2D.new()
	island_root.position = ISLAND_START_POS
	approach_root.add_child(island_root)

	island_silhouette_sprite = Sprite2D.new()
	island_silhouette_sprite.texture = island_texture
	island_silhouette_sprite.centered = true
	island_silhouette_sprite.modulate = Color(0.10, 0.23, 0.21, ISLAND_SILHOUETTE_ALPHA_START)
	island_silhouette_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	island_root.add_child(island_silhouette_sprite)

	island_detail_sprite = Sprite2D.new()
	island_detail_sprite.texture = island_texture
	island_detail_sprite.centered = true
	island_detail_sprite.modulate = Color(1.0, 1.0, 1.0, ISLAND_DETAIL_ALPHA_START)
	island_detail_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	island_root.add_child(island_detail_sprite)


func _add_polygon(parent: Node, points: PackedVector2Array, color: Color) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.color = color
	parent.add_child(polygon)
	return polygon


func _add_tree(parent: Node, base_position: Vector2) -> void:
	_add_polygon(parent, PackedVector2Array([
		base_position + Vector2(-6.0, 28.0),
		base_position + Vector2(6.0, 28.0),
		base_position + Vector2(5.0, 2.0),
		base_position + Vector2(-5.0, 2.0),
	]), Color(0.36, 0.25, 0.16, 0.86))
	_add_polygon(parent, PackedVector2Array([
		base_position + Vector2(-28.0, 6.0),
		base_position + Vector2(0.0, -38.0),
		base_position + Vector2(28.0, 6.0),
	]), Color(0.12, 0.36, 0.25, 0.90))


func _add_house(parent: Node, base_position: Vector2) -> void:
	_add_polygon(parent, PackedVector2Array([
		base_position + Vector2(-28.0, 24.0),
		base_position + Vector2(28.0, 24.0),
		base_position + Vector2(28.0, -10.0),
		base_position + Vector2(-28.0, -10.0),
	]), Color(0.77, 0.68, 0.50, 0.90))
	_add_polygon(parent, PackedVector2Array([
		base_position + Vector2(-36.0, -10.0),
		base_position + Vector2(0.0, -38.0),
		base_position + Vector2(36.0, -10.0),
	]), Color(0.55, 0.29, 0.22, 0.92))


func _build_interface() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)

	var top_panel := PanelContainer.new()
	top_panel.position = Vector2(36.0, 36.0)
	top_panel.size = Vector2(1008.0, 190.0)
	top_panel.modulate = Color(1.0, 1.0, 1.0, 0.90)
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.02, 0.12, 0.18, 0.60)
	top_style.corner_radius_top_left = 28
	top_style.corner_radius_top_right = 28
	top_style.corner_radius_bottom_left = 28
	top_style.corner_radius_bottom_right = 28
	top_style.border_width_left = 1
	top_style.border_width_top = 1
	top_style.border_width_right = 1
	top_style.border_width_bottom = 1
	top_style.border_color = Color(1.0, 1.0, 1.0, 0.20)
	top_panel.add_theme_stylebox_override("panel", top_style)
	ui.add_child(top_panel)

	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 28)
	top_margin.add_theme_constant_override("margin_right", 28)
	top_margin.add_theme_constant_override("margin_top", 20)
	top_margin.add_theme_constant_override("margin_bottom", 20)
	top_panel.add_child(top_margin)

	var top_box := VBoxContainer.new()
	top_box.add_theme_constant_override("separation", 3)
	top_margin.add_child(top_box)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 28)
	top_box.add_child(status_label)

	timer_label = Label.new()
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 64)
	timer_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.78))
	top_box.add_child(timer_label)

	var bottom := PanelContainer.new()
	bottom.position = Vector2(36.0, 1480.0)
	bottom.size = Vector2(1008.0, 390.0)
	var bottom_style := StyleBoxFlat.new()
	bottom_style.bg_color = Color(0.02, 0.10, 0.15, 0.82)
	bottom_style.corner_radius_top_left = 34
	bottom_style.corner_radius_top_right = 34
	bottom_style.corner_radius_bottom_left = 34
	bottom_style.corner_radius_bottom_right = 34
	bottom_style.border_width_left = 1
	bottom_style.border_width_top = 1
	bottom_style.border_width_right = 1
	bottom_style.border_width_bottom = 1
	bottom_style.border_color = Color(1.0, 1.0, 1.0, 0.18)
	bottom.add_theme_stylebox_override("panel", bottom_style)
	ui.add_child(bottom)

	var bottom_margin := MarginContainer.new()
	bottom_margin.add_theme_constant_override("margin_left", 32)
	bottom_margin.add_theme_constant_override("margin_right", 32)
	bottom_margin.add_theme_constant_override("margin_top", 26)
	bottom_margin.add_theme_constant_override("margin_bottom", 24)
	bottom.add_child(bottom_margin)

	var bottom_box := VBoxContainer.new()
	bottom_box.add_theme_constant_override("separation", 16)
	bottom_margin.add_child(bottom_box)

	progress_bar = ProgressBar.new()
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(0.0, 18.0)
	bottom_box.add_child(progress_bar)

	reward_label = Label.new()
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.add_theme_font_size_override("font_size", 25)
	reward_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55))
	bottom_box.add_child(reward_label)

	sail_state_label = Label.new()
	sail_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sail_state_label.add_theme_font_size_override("font_size", 22)
	sail_state_label.add_theme_color_override("font_color", Color(0.82, 0.92, 0.92, 0.92))
	bottom_box.add_child(sail_state_label)

	var options := HBoxContainer.new()
	options.alignment = BoxContainer.ALIGNMENT_CENTER
	options.add_theme_constant_override("separation", 12)
	bottom_box.add_child(options)
	_add_duration_button(options, "体验 10 秒", 10.0)
	_add_duration_button(options, "1 分钟", 60.0)
	_add_duration_button(options, "25 分钟", 25.0 * 60.0)

	start_button = Button.new()
	start_button.custom_minimum_size = Vector2(0.0, 76.0)
	start_button.add_theme_font_size_override("font_size", 30)
	start_button.pressed.connect(_on_start_pressed)
	bottom_box.add_child(start_button)

	var hint := Label.new()
	hint.text = "完成一次专注，船就会抵达港口"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(0.82, 0.90, 0.90, 0.88))
	bottom_box.add_child(hint)

	if DEBUG_VOYAGE_CONTROLS:
		_build_debug_controls(ui)


func _build_debug_controls(parent: Control) -> void:
	debug_panel = PanelContainer.new()
	debug_panel.position = Vector2(36.0, 1270.0)
	debug_panel.size = Vector2(1008.0, 175.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.01, 0.07, 0.10, 0.68)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(1.0, 1.0, 1.0, 0.14)
	debug_panel.add_theme_stylebox_override("panel", style)
	parent.add_child(debug_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	debug_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	debug_progress_label = Label.new()
	debug_progress_label.text = "调试航程：0%"
	debug_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	debug_progress_label.add_theme_font_size_override("font_size", 20)
	debug_progress_label.add_theme_color_override("font_color", Color(0.86, 0.94, 0.94, 0.90))
	box.add_child(debug_progress_label)

	debug_slider = HSlider.new()
	debug_slider.min_value = 0.0
	debug_slider.max_value = 100.0
	debug_slider.step = 0.1
	debug_slider.value_changed.connect(_on_debug_slider_changed)
	box.add_child(debug_slider)

	debug_preview_button = Button.new()
	debug_preview_button.text = "加速预览完整航程（24秒）"
	debug_preview_button.custom_minimum_size = Vector2(0.0, 48.0)
	debug_preview_button.add_theme_font_size_override("font_size", 20)
	debug_preview_button.pressed.connect(_on_debug_preview_pressed)
	box.add_child(debug_preview_button)


func _add_duration_button(parent: HBoxContainer, title: String, duration: float) -> void:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(190.0, 52.0)
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(func() -> void:
		if voyage_state == VoyageState.IDLE_PORT:
			selected_duration = duration
			remaining = duration
			forward_progress = 0.0
			debug_progress_override = false
			debug_preview_active = false
			target_sail_power = 0.0
			_set_background_mix(1.0, 0.0)
			_apply_voyage_progress(0.0)
			_update_interface()
	)
	parent.add_child(button)


func _get_timer_progress() -> float:
	var duration: float = max(selected_duration, 0.001)
	return clamp((duration - remaining) / duration, 0.0, 1.0)


func _apply_voyage_progress(progress: float, update_debug_slider: bool = true) -> void:
	forward_progress = clamp(progress, 0.0, 1.0)
	var approach_progress: float = pow(forward_progress, APPROACH_POWER)
	_update_island_visual(approach_progress)
	_update_water_visual(forward_progress)

	if debug_slider != null and update_debug_slider:
		debug_slider.set_value_no_signal(forward_progress * 100.0)
	if debug_progress_label != null:
		debug_progress_label.text = "调试航程：%d%%" % int(round(forward_progress * 100.0))


func _update_island_visual(approach_progress: float) -> void:
	if island_root == null:
		return

	var screen_progress: float = clamp(approach_progress, 0.0, 1.0)
	island_root.position = ISLAND_START_POS.lerp(ISLAND_END_POS, screen_progress)
	var island_scale: float = lerpf(ISLAND_START_SCALE, ISLAND_END_SCALE, screen_progress)
	island_root.scale = Vector2.ONE * island_scale

	var detail_alpha: float = lerpf(
		ISLAND_DETAIL_ALPHA_START,
		ISLAND_DETAIL_ALPHA_END,
		smoothstep(0.18, 0.82, forward_progress)
	)
	var silhouette_alpha: float = lerpf(
		ISLAND_SILHOUETTE_ALPHA_START,
		ISLAND_SILHOUETTE_ALPHA_END,
		smoothstep(0.0, 0.65, forward_progress)
	)
	island_silhouette_sprite.modulate = Color(0.10, 0.23, 0.21, silhouette_alpha)
	island_detail_sprite.modulate = Color(1.0, 1.0, 1.0, detail_alpha)


func _update_water_visual(progress: float) -> void:
	var p: float = clamp(progress, 0.0, 1.0)
	if shade_overlay != null:
		shade_overlay.color = WATER_WARM_START.lerp(WATER_WARM_END, smoothstep(0.78, 1.0, p))
	if wave_overlay != null:
		wave_overlay.set_voyage_visuals(p, voyage_motion_time)


func _on_debug_slider_changed(value: float) -> void:
	debug_preview_active = false
	debug_progress_override = true
	var progress: float = clamp(value / 100.0, 0.0, 1.0)
	voyage_motion_time = progress * selected_duration
	remaining = selected_duration * (1.0 - progress)
	_set_background_mix(0.0, 1.0)
	_set_voyage_scene_alpha(1.0)
	_apply_voyage_progress(progress, false)
	_update_interface()


func _on_debug_preview_pressed() -> void:
	debug_progress_override = true
	debug_preview_active = true
	debug_preview_elapsed = 0.0
	voyage_motion_time = 0.0
	remaining = selected_duration
	_set_background_mix(0.0, 1.0)
	_set_voyage_scene_alpha(1.0)
	_apply_voyage_progress(0.0)
	_update_interface()


func _update_debug_preview(delta: float) -> void:
	debug_preview_elapsed += delta
	var progress: float = clamp(debug_preview_elapsed / DEBUG_PREVIEW_DURATION, 0.0, 1.0)
	voyage_motion_time = progress * selected_duration
	remaining = selected_duration * (1.0 - progress)
	_apply_voyage_progress(progress)
	if progress >= 1.0:
		debug_preview_active = false


func _capture_voyage_stages() -> void:
	if debug_panel != null:
		debug_panel.visible = false

	_set_voyage_state(VoyageState.PAUSED)
	_set_background_mix(0.0, 1.0)
	_set_voyage_scene_alpha(1.0)

	var output_dir := ProjectSettings.globalize_path(CAPTURE_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var stages := [0.0, 0.25, 0.5, 0.75, 1.0]

	for stage in stages:
		var progress: float = stage
		remaining = selected_duration * (1.0 - progress)
		voyage_motion_time = selected_duration * progress
		_apply_voyage_progress(progress)
		_update_interface()
		await get_tree().process_frame
		await get_tree().process_frame
		var image := get_viewport().get_texture().get_image()
		var file_name := "voyage_progress_%03d.png" % int(round(progress * 100.0))
		image.save_png(output_dir.path_join(file_name))

	get_tree().quit()


func _on_start_pressed() -> void:
	match voyage_state:
		VoyageState.IDLE_PORT:
			if remaining <= 0.0:
				remaining = selected_duration
			_set_voyage_state(VoyageState.DEPARTING)
		VoyageState.SAILING:
			_set_voyage_state(VoyageState.PAUSED)
		VoyageState.PAUSED:
			_set_voyage_state(VoyageState.SAILING)
		VoyageState.ARRIVED:
			_reset_voyage()


func _reset_voyage() -> void:
	remaining = selected_duration
	forward_progress = 0.0
	_set_voyage_state(VoyageState.IDLE_PORT)


func _set_voyage_state(new_state: VoyageState) -> void:
	voyage_state = new_state
	state_elapsed = 0.0

	match voyage_state:
		VoyageState.IDLE_PORT:
			target_sail_power = 0.0
			departure_visual_progress = 0.0
			arrival_visual_progress = 0.0
			_set_background_mix(1.0, 0.0)
			_set_voyage_scene_alpha(0.0)
			_apply_voyage_progress(0.0)
		VoyageState.DEPARTING:
			target_sail_power = 1.0
			_update_departure_visual(0.0)
		VoyageState.SAILING:
			target_sail_power = 1.0
			departure_visual_progress = 0.0
			arrival_visual_progress = 0.0
			_set_background_mix(0.0, 1.0)
			_set_voyage_scene_alpha(1.0)
			_apply_voyage_progress(_get_timer_progress())
		VoyageState.PAUSED:
			target_sail_power = 0.0
		VoyageState.ARRIVING:
			target_sail_power = 0.0
			if not is_journey_test_02_mode:
				remaining = 0.0
				_update_arrival_visual(0.0)
		VoyageState.ARRIVED:
			target_sail_power = 0.0
			if not is_journey_test_02_mode:
				remaining = 0.0
				departure_visual_progress = 0.0
				arrival_visual_progress = 0.0
				_set_background_mix(1.0, 0.0)
				_set_voyage_scene_alpha(0.0)

	_update_interface()


func _update_departure_visual(raw_progress: float) -> void:
	var progress: float = clamp(raw_progress, 0.0, 1.0)
	departure_visual_progress = progress * progress * (3.0 - 2.0 * progress)
	arrival_visual_progress = 0.0
	_set_background_mix(1.0 - departure_visual_progress, departure_visual_progress)
	_set_voyage_scene_alpha(departure_visual_progress)


func _update_arrival_visual(raw_progress: float) -> void:
	var progress: float = clamp(raw_progress, 0.0, 1.0)
	arrival_visual_progress = progress * progress * (3.0 - 2.0 * progress)
	departure_visual_progress = 0.0
	_set_background_mix(arrival_visual_progress, 1.0 - arrival_visual_progress)
	_set_voyage_scene_alpha(1.0 - arrival_visual_progress)


func _set_background_mix(port_alpha: float, voyage_alpha: float) -> void:
	_set_canvas_alpha(port_background, clamp(port_alpha, 0.0, 1.0))
	_set_canvas_alpha(voyage_background, clamp(voyage_alpha, 0.0, 1.0))


func _set_voyage_scene_alpha(alpha: float) -> void:
	_set_canvas_alpha(approach_root, clamp(alpha, 0.0, 1.0))


func _set_canvas_alpha(item: CanvasItem, alpha: float) -> void:
	if item == null:
		return
	var color := item.modulate
	color.a = alpha
	item.modulate = color


func _animate_scene() -> void:
	if background_holder == null:
		return
	sail_power = move_toward(sail_power, target_sail_power, get_process_delta_time() * 1.8)
	var wave_strength := 0.35 + sail_power * 0.65
	var bob := sin(motion_time * 1.25) * (1.1 + 3.0 * wave_strength)
	var sway := sin(motion_time * 0.72) * (0.0012 + 0.0022 * wave_strength)
	var departure_push := -departure_visual_progress * 14.0
	var arrival_push := arrival_visual_progress * 8.0
	var forward_offset := departure_push + arrival_push
	background_holder.position = Vector2(sin(motion_time * 0.85) * 1.8, bob + forward_offset)
	background_holder.rotation = sway
	background_holder.scale = Vector2.ONE * (1.002 + forward_progress * 0.014 + departure_visual_progress * 0.012 + sin(motion_time * 0.7) * 0.0015)


func _update_interface() -> void:
	if timer_label == null:
		return

	var minutes := int(remaining) / 60
	var seconds := int(remaining) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

	start_button.disabled = voyage_state == VoyageState.DEPARTING or voyage_state == VoyageState.ARRIVING

	match voyage_state:
		VoyageState.IDLE_PORT:
			status_label.text = "准备出发"
			reward_label.text = "船停在港口，等待下一次专注"
			sail_state_label.text = "帆已落下"
			start_button.text = "开始专注"
			progress_bar.value = 0.0
		VoyageState.DEPARTING:
			status_label.text = "正在启航"
			reward_label.text = "起锚，升帆，船缓慢离开港口"
			sail_state_label.text = "帆正在升起"
			start_button.text = "启航中"
			progress_bar.value = 0.0
		VoyageState.SAILING:
			status_label.text = "正在远航 · 帆已升起"
			reward_label.text = "船正在慢慢靠近目的地……"
			sail_state_label.text = "海浪继续起伏 · 船正在前进"
			start_button.text = "落帆 · 暂停航行"
			progress_bar.value = (1.0 - remaining / selected_duration) * 100.0
		VoyageState.PAUSED:
			status_label.text = "航行已暂停 · 帆已落下"
			reward_label.text = "海浪仍在流动，但船已经停下"
			sail_state_label.text = "升帆后继续前进"
			start_button.text = "升帆 · 继续航行"
			progress_bar.value = (1.0 - remaining / selected_duration) * 100.0
		VoyageState.ARRIVING:
			status_label.text = "正在靠港"
			reward_label.text = "远处出现港口，船正在慢慢靠近"
			sail_state_label.text = "帆正在落下"
			start_button.text = "靠港中"
			progress_bar.value = 100.0
		VoyageState.ARRIVED:
			status_label.text = "抵达港口"
			reward_label.text = "获得奖励：港口贝壳 × 1"
			sail_state_label.text = "帆已落下 · 可以整理货物"
			start_button.text = "再次出发"
			progress_bar.value = 100.0
