extends Node3D

const ISLAND_PROTOTYPE_SCENE := preload("res://scenes/world/IslandPrototype.tscn")

const SEA_BASE_COLOR := Color(0.02, 0.33, 0.58, 1.0)
const SEA_MID_COLOR := Color(0.05, 0.46, 0.68, 1.0)
const SEA_NEAR_COLOR := Color(0.03, 0.28, 0.48, 1.0)
const SEA_FAR_COLOR := Color(0.16, 0.58, 0.74, 0.64)
const SEA_LIGHT_COLOR := Color(0.52, 0.82, 0.84, 0.34)
const SKY_BLUE := Color(0.26, 0.66, 0.93, 1.0)
const CLOUD_WHITE := Color(0.96, 0.92, 0.82, 1.0)
const CLOUD_SHADE := Color(0.74, 0.86, 0.91, 1.0)
const FAR_BLUE := Color(0.18, 0.37, 0.52, 1.0)
const FAR_GREEN := Color(0.12, 0.34, 0.29, 1.0)
const HULL_WOOD := Color(0.70, 0.43, 0.19, 1.0)
const HULL_LIGHT := Color(0.92, 0.61, 0.27, 1.0)
const HULL_SHADOW := Color(0.46, 0.25, 0.12, 1.0)
const HULL_DEEP := Color(0.26, 0.16, 0.10, 1.0)
const HULL_DARK := Color(0.22, 0.17, 0.13, 1.0)
const CABIN_BODY := Color(0.78, 0.60, 0.36, 1.0)
const CABIN_LIGHT := Color(0.93, 0.72, 0.43, 1.0)
const CABIN_SHADOW := Color(0.55, 0.40, 0.24, 1.0)
const CABIN_ROOF := Color(0.10, 0.33, 0.45, 1.0)
const CABIN_ROOF_LIGHT := Color(0.16, 0.45, 0.58, 1.0)
const CABIN_ROOF_SHADOW := Color(0.06, 0.22, 0.30, 1.0)
const SAIL_WARM := Color(0.96, 0.88, 0.68, 1.0)
const SAIL_LIGHT := Color(1.0, 0.95, 0.74, 1.0)
const SAIL_SHADOW := Color(0.82, 0.72, 0.54, 0.72)
const WINDOW_DARK := Color(0.05, 0.16, 0.20, 1.0)
const WAKE_WHITE := Color(0.82, 0.95, 0.93, 0.46)

var camera: Camera3D
var boat_root: Node3D
var boat_visual_root: Node3D
var hull_visual_root: Node3D
var rig_visual_root: Node3D
var sail_root: Node3D
var far_silhouette_root: Node3D
var far_background_layer: Node3D
var island_root: Node3D
var island_visual_root: Node3D
var island_collision_root: Node3D
var island_landmark_root: Node3D
var island_prop_root: Node3D
var destination_island: Node3D
var destination_landmark: Node3D
var sea_strips: Array[Node3D] = []
var wake_mesh_instance: MeshInstance3D
var wake_history_points: Array[Vector3] = []
var wake_history_rights: Array[Vector3] = []
var wake_history_ages: Array[float] = []
var wake_history_strengths: Array[float] = []
var wake_distance_since_spawn := 0.0
var visual_time := 0.0
var sail_life := 0.0

# Navigation/control tuning for the PC prototype. These values describe intent
# and a small amount of motion; they are deliberately not a sailing simulator.
const BOAT_START_POSITION := Vector3(-0.28, 0.28, -0.18)
const AUTO_FORWARD_SPEED := 0.015
const JOURNEY_TEST_FORWARD_SPEED := 0.62
const JOURNEY_TEST_DESTINATION_POSITION := Vector3(0.0, 0.05, -33.0)
const JOURNEY_TEST_DESTINATION_SCALE := 0.42
const JOURNEY_TEST_APPROACH_DISTANCE := 28.0
const JOURNEY_TEST_ARRIVAL_DISTANCE := 7.0
const JOURNEY_TEST_APPROACH_SPEED := 0.40
const JOURNEY_TEST_DRIFT_SPEED := 0.015
const JOURNEY_TEST_SPEED_SMOOTHING := 0.080
const JOURNEY_TEST_ARRIVING_SPEED_SMOOTHING := 0.50
const JOURNEY_TEST_FAST_MULTIPLIER := 4.0
const JOURNEY_TEST_FAST_SMOOTHING := 6.0
const SEA_TRIAL_MAX_FORWARD_SPEED := JOURNEY_TEST_FORWARD_SPEED * 4.0
const SEA_TRIAL_MAX_REVERSE_SPEED := JOURNEY_TEST_FORWARD_SPEED * 0.70
const SEA_TRIAL_FORWARD_ACCELERATION := 0.75
const SEA_TRIAL_REVERSE_ACCELERATION := 0.34
const SEA_TRIAL_COAST_DECELERATION := 0.10
const SEA_TRIAL_BRAKE_DECELERATION := 1.10
const SEA_TRIAL_STOP_DECELERATION := 0.48
const SEA_TRIAL_THROTTLE_RESPONSE := 3.5
const SEA_TRIAL_STOP_EPSILON := 0.002
const SEA_TRIAL_WORLD_MIN_X := -24.0
const SEA_TRIAL_WORLD_MAX_X := 24.0
const SEA_TRIAL_WORLD_MIN_Z := -54.0
const SEA_TRIAL_WORLD_MAX_Z := 8.0
const SEA_TRIAL_BOUNDARY_SOFT_MARGIN := 4.0
const SEA_TRIAL_ISLAND_COLLISION_RADIUS_X := 3.35
const SEA_TRIAL_ISLAND_COLLISION_RADIUS_Z := 2.05
const STEERING_TURN_RATE := 0.38
const STEERING_SMOOTHING := 4.5
const CAMERA_LOOK_SENSITIVITY := 0.0045
const CAMERA_LOOK_VERTICAL_SENSITIVITY := 0.0030
const CAMERA_LOOK_VERTICAL_MIN := -0.17
const CAMERA_LOOK_VERTICAL_MAX := 0.35
const CAMERA_LOOK_SMOOTHING := 7.0
const CAMERA_FOLLOW_SMOOTHING := 8.0
const CAMERA_HEADING_FOLLOW_SMOOTHING := 1.65
const DEFAULT_CAMERA_POSITION := Vector3(-2.75, 3.82, 9.70)
const DEFAULT_CAMERA_TARGET := Vector3(-0.32, 0.72, -5.75)
const DEFAULT_CAMERA_FOV := 38.0
const HULL_VISUAL_SCALE := 0.50
const RIG_VISUAL_SCALE := 2.0 / 3.0
const BOAT_VISUAL_WATERLINE_OFFSET_Y := -0.15
const WAKE_SEGMENT_SPACING := 0.08
const WAKE_SEGMENT_LIFETIME := 2.6
const WAKE_GENERATION_MIN_SPEED := 0.035
const WAKE_STERN_OFFSET := 0.78
const WAKE_MAX_POINTS := 160
const WAKE_TRACE_OFFSET := 0.10
const WAKE_TRACE_HALF_WIDTH := 0.018

var boat_travel_position := BOAT_START_POSITION
var boat_heading := 0.0
var target_boat_heading := 0.0
var steering_intent := 0.0
var journey_test_active := false
var journey_arrival_test_active := false
var journey_arrival_requested := false
var journey_arrival_rearm_requires_exit := false
var sea_trial_active := false
var sea_trial_propulsion_intent := 0.0
var sea_trial_throttle_ratio := 0.0
var sea_trial_stop_requested := false
var sea_trial_space_departure_latched := false
var sea_trial_land_contact := false
var sea_trial_boundary_factor := 1.0
var current_travel_speed := AUTO_FORWARD_SPEED
var actual_travel_velocity := Vector3.ZERO
var test_fast_intent := false
var test_speed_multiplier := 1.0
var last_voyage_state := 2
var camera_shot_offset := Vector3.ZERO
var camera_shot_target_offset := Vector3(0.0, 0.45, -5.5)
var camera_shot_fov := 38.0
var camera_look_target := 0.0
var camera_look_angle := 0.0
var camera_look_vertical_target := 0.0
var camera_look_vertical_angle := 0.0
var camera_follow_heading := 0.0
var camera_target_position := Vector3.ZERO
var camera_target_initialized := false


func _ready() -> void:
	_build_world()


func update_voyage(delta: float, progress: float, voyage_state: int) -> void:
	last_voyage_state = voyage_state
	var normal_sailing: bool = voyage_state == 2
	var arrival_drifting: bool = journey_arrival_test_active and (voyage_state == 4 or voyage_state == 5)
	var navigation_active: bool = normal_sailing or arrival_drifting
	_update_journey_arrival_zone(voyage_state)
	_update_navigation(delta, voyage_state, navigation_active)
	var motion_factor := _get_navigation_motion_factor(navigation_active)
	var slow_life: bool = voyage_state == 3 or voyage_state == 0 or voyage_state == 5
	var time_scale: float = 1.0 if normal_sailing else 0.24 if slow_life else 0.58
	if journey_arrival_test_active:
		time_scale = lerpf(0.42, 1.0, motion_factor)
	elif sea_trial_active:
		time_scale = lerpf(0.42, 1.0, motion_factor)
	visual_time += delta * time_scale
	var sail_target := 1.0 if normal_sailing else 0.28
	if journey_arrival_test_active:
		sail_target = lerpf(0.34, 1.0, motion_factor)
	elif sea_trial_active:
		sail_target = lerpf(0.28, 1.0, motion_factor)
	sail_life = move_toward(sail_life, sail_target, delta * 1.5)

	var p: float = clamp(progress, 0.0, 1.0)
	_animate_boat(motion_factor)
	_animate_sail()
	_animate_sea(delta, motion_factor, p)
	_animate_distant_silhouette(p)
	_update_follow_camera(delta)


func set_steering_intent(value: float) -> void:
	steering_intent = clamp(value, -1.0, 1.0)


func set_test_fast_intent(enabled: bool) -> void:
	test_fast_intent = enabled and journey_arrival_test_active and last_voyage_state == 2


func set_sea_trial_propulsion_intent(value: float) -> void:
	sea_trial_propulsion_intent = clampf(value, -1.0, 1.0) if sea_trial_active else 0.0
	if not is_zero_approx(sea_trial_propulsion_intent):
		sea_trial_stop_requested = false
		sea_trial_space_departure_latched = false
	elif sea_trial_space_departure_latched:
		# The one-shot Space departure must survive the next frame's normal
		# W/S polling until the boat has visibly started moving.
		sea_trial_propulsion_intent = 1.0


func request_sea_trial_stop() -> void:
	if sea_trial_active:
		sea_trial_propulsion_intent = 0.0
		sea_trial_stop_requested = true
		sea_trial_space_departure_latched = false


func toggle_sea_trial_space() -> void:
	if not sea_trial_active:
		return
	if absf(current_travel_speed) > SEA_TRIAL_STOP_EPSILON or sea_trial_stop_requested:
		request_sea_trial_stop()
		return
	sea_trial_stop_requested = false
	sea_trial_space_departure_latched = true
	sea_trial_propulsion_intent = 1.0


func reset_sea_trial() -> void:
	if not sea_trial_active:
		return
	boat_travel_position = BOAT_START_POSITION
	boat_heading = 0.0
	target_boat_heading = 0.0
	steering_intent = 0.0
	current_travel_speed = 0.0
	actual_travel_velocity = Vector3.ZERO
	sea_trial_propulsion_intent = 0.0
	sea_trial_throttle_ratio = 0.0
	sea_trial_stop_requested = false
	sea_trial_space_departure_latched = false
	sea_trial_land_contact = false
	sea_trial_boundary_factor = 1.0
	wake_distance_since_spawn = 0.0
	wake_history_points.clear()
	wake_history_rights.clear()
	wake_history_ages.clear()
	wake_history_strengths.clear()
	_rebuild_wake_mesh()
	camera_follow_heading = 0.0
	reset_camera()
	_update_follow_camera(0.0, true)


func set_journey_test_mode(enabled: bool) -> void:
	journey_test_active = enabled
	if not enabled or destination_island == null:
		return

	# The destination remains a fixed 3D place. Only its test placement and
	# temporary prototype scale differ from the normal V0.2 presentation.
	destination_island.position = JOURNEY_TEST_DESTINATION_POSITION
	destination_island.scale = Vector3.ONE * JOURNEY_TEST_DESTINATION_SCALE
	if destination_landmark != null:
		destination_landmark.position = Vector3(
			0.85,
			0.73,
			0.25
		)
		destination_landmark.scale = Vector3.ONE
		destination_landmark.visible = true
	if far_background_layer != null:
		far_background_layer.position.z = -72.0
	far_silhouette_root.position = Vector3.ZERO
	far_silhouette_root.scale = Vector3.ONE


func set_journey_arrival_test_mode(enabled: bool) -> void:
	journey_arrival_test_active = enabled
	if enabled:
		set_journey_test_mode(true)
		current_travel_speed = JOURNEY_TEST_FORWARD_SPEED
		test_speed_multiplier = 1.0
	else:
		test_fast_intent = false
		test_speed_multiplier = 1.0


func set_sea_trial_mode(enabled: bool) -> void:
	sea_trial_active = enabled
	journey_arrival_test_active = false
	journey_arrival_requested = false
	journey_arrival_rearm_requires_exit = false
	test_fast_intent = false
	test_speed_multiplier = 1.0
	sea_trial_propulsion_intent = 0.0
	sea_trial_throttle_ratio = 0.0
	sea_trial_stop_requested = false
	sea_trial_space_departure_latched = false
	sea_trial_land_contact = false
	sea_trial_boundary_factor = 1.0
	if enabled:
		set_journey_test_mode(true)
		current_travel_speed = 0.0
		actual_travel_velocity = Vector3.ZERO


func consume_journey_arrival_request() -> bool:
	var requested := journey_arrival_requested
	journey_arrival_requested = false
	return requested


func resume_journey_arrival_test() -> void:
	journey_arrival_requested = false
	journey_arrival_rearm_requires_exit = true


func get_journey_diagnostics() -> Dictionary:
	var distance := _get_destination_horizontal_distance()
	var distance_band := "FAR"
	if distance <= JOURNEY_TEST_ARRIVAL_DISTANCE:
		distance_band = "ARRIVAL"
	elif distance <= JOURNEY_TEST_APPROACH_DISTANCE:
		distance_band = "APPROACH"

	var heading_forward := _get_heading_forward()
	var slip_angle_degrees := 0.0
	if actual_travel_velocity.length_squared() > 0.000001:
		slip_angle_degrees = absf(rad_to_deg(
			heading_forward.signed_angle_to(actual_travel_velocity.normalized(), Vector3.UP)
		))

	return {
		"distance_band": distance_band,
		"distance": distance,
		"speed": actual_travel_velocity.length(),
		"heading_degrees": rad_to_deg(boat_heading),
		"slip_angle_degrees": slip_angle_degrees,
		"test_fast_active": journey_arrival_test_active and last_voyage_state == 2 and test_speed_multiplier > 1.05,
		"test_speed_multiplier": test_speed_multiplier,
		"camera_follow_lag_degrees": rad_to_deg(angle_difference(camera_follow_heading, boat_heading)),
		"active_wake_segments": _get_active_wake_segment_count(),
	}


func get_sea_trial_diagnostics() -> Dictionary:
	var drive_state := "STOPPED"
	if sea_trial_stop_requested or (sea_trial_propulsion_intent < -0.01 and current_travel_speed > SEA_TRIAL_STOP_EPSILON):
		drive_state = "BRAKING"
	elif current_travel_speed > SEA_TRIAL_STOP_EPSILON:
		drive_state = "FORWARD"
	elif current_travel_speed < -SEA_TRIAL_STOP_EPSILON:
		drive_state = "REVERSE"
	return {
		"speed": absf(current_travel_speed),
		"signed_speed": current_travel_speed,
		"drive_state": drive_state,
		"throttle_ratio": sea_trial_throttle_ratio,
		"heading_degrees": rad_to_deg(boat_heading),
		"active_wake_segments": _get_active_wake_segment_count(),
		"position": boat_travel_position,
		"land_contact": sea_trial_land_contact,
		"boundary_factor": sea_trial_boundary_factor,
	}


func _update_journey_arrival_zone(voyage_state: int) -> void:
	if not journey_arrival_test_active or destination_island == null:
		return

	var distance := _get_destination_horizontal_distance()
	if journey_arrival_rearm_requires_exit:
		if distance > JOURNEY_TEST_APPROACH_DISTANCE:
			journey_arrival_rearm_requires_exit = false
		return

	if voyage_state == 2 and distance <= JOURNEY_TEST_ARRIVAL_DISTANCE:
		journey_arrival_requested = true


func _get_destination_horizontal_distance() -> float:
	if destination_island == null:
		return INF
	var offset := boat_travel_position - destination_island.global_position
	return Vector2(offset.x, offset.z).length()


func _get_navigation_target_speed(voyage_state: int) -> float:
	if not journey_test_active:
		return AUTO_FORWARD_SPEED
	if not journey_arrival_test_active:
		return JOURNEY_TEST_FORWARD_SPEED
	if voyage_state == 2:
		if journey_arrival_rearm_requires_exit:
			return JOURNEY_TEST_FORWARD_SPEED * test_speed_multiplier
		var raw_approach: float = clampf(
			(JOURNEY_TEST_APPROACH_DISTANCE - _get_destination_horizontal_distance()) /
			(JOURNEY_TEST_APPROACH_DISTANCE - JOURNEY_TEST_ARRIVAL_DISTANCE),
			0.0,
			1.0
		)
		var eased_approach: float = raw_approach * raw_approach * (3.0 - 2.0 * raw_approach)
		var base_speed := lerpf(JOURNEY_TEST_FORWARD_SPEED, JOURNEY_TEST_APPROACH_SPEED, eased_approach)
		return base_speed * test_speed_multiplier
	return JOURNEY_TEST_DRIFT_SPEED


func _get_navigation_motion_factor(navigation_active: bool) -> float:
	if journey_arrival_test_active:
		return clamp(current_travel_speed / JOURNEY_TEST_FORWARD_SPEED, 0.06, 1.0)
	if sea_trial_active:
		return clampf(absf(current_travel_speed) / JOURNEY_TEST_FORWARD_SPEED, 0.0, 1.0)
	return 1.0 if navigation_active else 0.22


func add_camera_look_intent(horizontal_delta: float, vertical_delta: float) -> void:
	# Screen drag direction and orbit direction must agree: dragging left adds
	# positive Godot yaw (look left), dragging right adds negative yaw.
	camera_look_target = wrapf(
		camera_look_target - horizontal_delta * CAMERA_LOOK_SENSITIVITY,
		-PI,
		PI
	)
	camera_look_vertical_target = clamp(
		camera_look_vertical_target - vertical_delta * CAMERA_LOOK_VERTICAL_SENSITIVITY,
		CAMERA_LOOK_VERTICAL_MIN,
		CAMERA_LOOK_VERTICAL_MAX
	)


func reset_camera() -> void:
	# Keep the current camera position and let the normal smoothing return it.
	camera_shot_offset = DEFAULT_CAMERA_POSITION - BOAT_START_POSITION
	camera_shot_target_offset = DEFAULT_CAMERA_TARGET - BOAT_START_POSITION
	camera_shot_fov = DEFAULT_CAMERA_FOV
	camera_look_target = 0.0
	camera_look_vertical_target = 0.0


func set_camera_shot(shot_name: String) -> void:
	match shot_name:
		"boat_close":
			_set_camera(Vector3(-2.55, 2.45, 5.35), Vector3(-0.20, 0.78, -0.10), 42.0)
		"far_blocks":
			_set_camera(Vector3(-1.55, 4.85, 11.8), Vector3(0.35, 0.58, -13.5), 33.0)
		"phone_preview":
			_set_camera(Vector3(-2.85, 3.95, 10.25), Vector3(-0.30, 0.70, -6.40), 38.0)
		_:
			_set_camera(DEFAULT_CAMERA_POSITION, DEFAULT_CAMERA_TARGET, DEFAULT_CAMERA_FOV)


func _build_world() -> void:
	_build_environment()
	_build_far_sky_shapes()
	_build_sea()
	_build_far_silhouette()
	_build_boat()
	_build_camera()


func _build_environment() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = SKY_BLUE
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.82, 0.92, 1.0)
	env.ambient_light_energy = 0.95
	environment.environment = env
	add_child(environment)

	var light := DirectionalLight3D.new()
	light.name = "SimpleSun"
	light.light_energy = 1.55
	light.light_color = Color(1.0, 0.93, 0.80, 1.0)
	light.rotation_degrees = Vector3(-46.0, -28.0, 0.0)
	add_child(light)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "GameCamera"
	camera.current = true
	camera.near = 0.05
	camera.far = 120.0
	add_child(camera)
	set_camera_shot("normal")


func _build_sea() -> void:
	var sea := MeshInstance3D.new()
	sea.name = "SeaBigColorPlane"
	var sea_mesh := PlaneMesh.new()
	sea_mesh.size = Vector2(72.0, 92.0)
	sea.mesh = sea_mesh
	sea.material_override = _make_material("sea_base", SEA_BASE_COLOR, false)
	sea.position = Vector3(0.0, -0.025, -18.0)
	add_child(sea)

	var far_band := MeshInstance3D.new()
	far_band.name = "FarSeaWideColorBand"
	far_band.mesh = _make_horizontal_polygon_mesh(PackedVector2Array([
		Vector2(-36.0, -44.0),
		Vector2(36.0, -44.0),
		Vector2(36.0, -20.0),
		Vector2(-36.0, -17.5),
	]), -0.016)
	far_band.material_override = _make_material("sea_far_block", SEA_FAR_COLOR, true, 0.82)
	add_child(far_band)

	var mid_band := MeshInstance3D.new()
	mid_band.name = "MiddleSeaGraphicBlock"
	mid_band.mesh = _make_horizontal_polygon_mesh(PackedVector2Array([
		Vector2(-36.0, -21.0),
		Vector2(36.0, -23.5),
		Vector2(36.0, -2.0),
		Vector2(-36.0, 2.8),
	]), -0.014)
	mid_band.material_override = _make_material("sea_middle_block", SEA_MID_COLOR, true, 0.72)
	add_child(mid_band)

	var near_shadow := MeshInstance3D.new()
	near_shadow.name = "NearSeaLargeShadowPlane"
	near_shadow.mesh = _make_horizontal_polygon_mesh(PackedVector2Array([
		Vector2(-36.0, -2.5),
		Vector2(36.0, -7.0),
		Vector2(36.0, 28.0),
		Vector2(-36.0, 34.0),
	]), -0.012)
	near_shadow.material_override = _make_material("sea_near_shadow_block", SEA_NEAR_COLOR, true, 0.42)
	add_child(near_shadow)

	for i in range(18):
		var strip := _make_flat_rect("WaterGraphicStrip%02d" % i, Vector2(lerpf(1.5, 8.5, randf()), lerpf(0.025, 0.075, randf())), SEA_LIGHT_COLOR)
		var x := randf_range(-16.0, 16.0)
		var z := randf_range(-38.0, 7.0)
		strip.position = Vector3(x, 0.012 + float(i) * 0.0008, z)
		strip.rotation_degrees.y = randf_range(-2.5, 2.5)
		strip.scale.x = lerpf(0.75, 1.35, randf())
		sea_strips.append(strip)
		add_child(strip)


	wake_mesh_instance = MeshInstance3D.new()
	wake_mesh_instance.name = "ContinuousWorldSpaceWake"
	wake_mesh_instance.mesh = ArrayMesh.new()
	# Keep the material itself translucent so per-vertex age/strength alpha is
	# actually blended by Godot instead of rendering every point as solid white.
	var wake_material := _make_material("continuous_wake", Color(1.0, 1.0, 1.0, 0.72), true, 1.0)
	wake_material.vertex_color_use_as_albedo = true
	wake_mesh_instance.material_override = wake_material
	add_child(wake_mesh_instance)


func _build_far_sky_shapes() -> void:
	var cloud_root := Node3D.new()
	cloud_root.name = "GraphicClouds"
	add_child(cloud_root)

	_add_cloud_blob(cloud_root, Vector3(-10.0, 9.4, -42.0), Vector2(3.8, 0.82), CLOUD_WHITE)
	_add_cloud_blob(cloud_root, Vector3(-7.4, 9.55, -42.0), Vector2(2.0, 0.58), CLOUD_WHITE)
	_add_cloud_blob(cloud_root, Vector3(-12.4, 9.12, -42.0), Vector2(1.8, 0.48), CLOUD_SHADE)

	_add_cloud_blob(cloud_root, Vector3(7.2, 10.55, -46.0), Vector2(4.9, 1.08), CLOUD_WHITE)
	_add_cloud_blob(cloud_root, Vector3(10.4, 10.25, -46.0), Vector2(3.1, 0.78), CLOUD_WHITE)
	_add_cloud_blob(cloud_root, Vector3(5.0, 10.0, -46.0), Vector2(2.2, 0.62), CLOUD_SHADE)


func _build_far_silhouette() -> void:
	far_silhouette_root = Node3D.new()
	far_silhouette_root.name = "SimpleDistantLandSilhouette"
	far_silhouette_root.set_meta("asset_status", "PLACEHOLDER")
	far_silhouette_root.set_meta("replacement_scene", "res://scenes/world/IslandPrototype.tscn")
	add_child(far_silhouette_root)

	var far_points := PackedVector2Array([
		Vector2(-24.0, 0.0),
		Vector2(-18.0, 0.36),
		Vector2(-12.0, 0.22),
		Vector2(-6.5, 0.74),
		Vector2(0.0, 0.42),
		Vector2(6.0, 0.68),
		Vector2(13.0, 0.28),
		Vector2(22.0, 0.0),
	])
	var far_layer := MeshInstance3D.new()
	far_layer.name = "FarBlueGrayMountainSilhouette"
	far_layer.set_meta("asset_status", "PLACEHOLDER")
	far_layer.mesh = _make_extruded_vertical_mesh(far_points, -0.08, 2.0)
	far_layer.material_override = _make_material("far_blue_gray", FAR_BLUE, true, 0.52)
	far_layer.position = Vector3(0.0, 0.05, -48.0)
	far_silhouette_root.add_child(far_layer)
	far_background_layer = far_layer

	var island_points := PackedVector2Array([
		Vector2(-6.2, 0.0),
		Vector2(-4.6, 0.38),
		Vector2(-2.2, 0.52),
		Vector2(0.0, 0.92),
		Vector2(2.4, 0.56),
		Vector2(4.8, 0.32),
		Vector2(6.7, 0.0),
	])
	island_root = ISLAND_PROTOTYPE_SCENE.instantiate()
	island_root.name = "IslandPrototype_PLACEHOLDER"
	island_root.set_meta("asset_status", "PLACEHOLDER_CONTAINER")
	island_root.position = Vector3(0.0, 0.05, -35.0)
	far_silhouette_root.add_child(island_root)
	island_visual_root = island_root.get_node("VisualRoot")
	island_collision_root = island_root.get_node("CollisionRoot")
	island_landmark_root = island_root.get_node("LandmarkRoot")
	island_prop_root = island_root.get_node("PropRoot")

	# VisualRoot is the replacement boundary. An imported GLB/GLTF child placed
	# there suppresses this generated placeholder without touching navigation.
	if island_visual_root.get_child_count() == 0:
		var island_layer := MeshInstance3D.new()
		island_layer.name = "TinyDestinationSilhouette_PLACEHOLDER"
		island_layer.set_meta("asset_status", "PLACEHOLDER")
		island_layer.mesh = _make_extruded_vertical_mesh(island_points, -0.06, 1.6)
		island_layer.material_override = _make_material("distant_green_silhouette", FAR_GREEN, true, 0.86)
		island_visual_root.add_child(island_layer)
	destination_island = island_root

	var landmark := MeshInstance3D.new()
	landmark.name = "JourneyTestSimpleHighPoint"
	landmark.set_meta("asset_status", "PLACEHOLDER")
	var landmark_mesh := BoxMesh.new()
	landmark_mesh.size = Vector3(0.34, 2.2, 0.34)
	landmark.mesh = landmark_mesh
	landmark.material_override = _make_material("journey_test_landmark", FAR_GREEN, true, 0.92)
	landmark.position = Vector3(0.85, 0.73, 0.25)
	landmark.visible = false
	island_landmark_root.add_child(landmark)
	destination_landmark = landmark


func _build_boat() -> void:
	boat_root = Node3D.new()
	boat_root.name = "MainCabinSailboatBlockoutV02"
	boat_root.position = BOAT_START_POSITION
	boat_travel_position = BOAT_START_POSITION
	boat_root.rotation_degrees.y = 0.0
	add_child(boat_root)

	# This parent changes only the visible model's waterline. Logical movement,
	# camera tracking, destination distance, and wake coordinates stay on boat_root.
	boat_visual_root = Node3D.new()
	boat_visual_root.name = "BoatVisualWaterlineOffset"
	boat_visual_root.position.y = BOAT_VISUAL_WATERLINE_OFFSET_Y
	boat_root.add_child(boat_visual_root)

	hull_visual_root = Node3D.new()
	hull_visual_root.name = "HullVisual50Percent"
	hull_visual_root.scale = Vector3.ONE * HULL_VISUAL_SCALE
	boat_visual_root.add_child(hull_visual_root)

	rig_visual_root = Node3D.new()
	rig_visual_root.name = "RigVisualTwoThirds"
	rig_visual_root.scale = Vector3.ONE * RIG_VISUAL_SCALE
	boat_visual_root.add_child(rig_visual_root)

	_add_boat_mesh(hull_visual_root, "HullBaseDesignedVolume", _make_hull_mesh(), HULL_WOOD)
	_add_boat_mesh(hull_visual_root, "HullPortLightPlane", _make_hull_port_plane_mesh(), HULL_LIGHT)
	_add_boat_mesh(hull_visual_root, "HullLowerShadowPlane", _make_hull_lower_shadow_mesh(), HULL_SHADOW)
	_add_boat_mesh(hull_visual_root, "HullSternDeepPlane", _make_hull_stern_mesh(), HULL_DEEP)
	_add_boat_mesh(hull_visual_root, "DeckLongWarmPlane", _make_deck_mesh(), Color(0.86, 0.54, 0.25, 1.0))
	_add_boat_mesh(hull_visual_root, "DeckInnerShadowPlane", _make_inner_deck_mesh(), Color(0.42, 0.25, 0.13, 1.0))

	_add_boat_mesh(hull_visual_root, "CabinSlopedBodyVolume", _make_cabin_body_mesh(), CABIN_BODY)
	_add_boat_mesh(hull_visual_root, "CabinPortLightPlane", _make_cabin_port_plane_mesh(), CABIN_LIGHT)
	_add_boat_mesh(hull_visual_root, "CabinRearShadowPlane", _make_cabin_rear_plane_mesh(), CABIN_SHADOW)
	_add_boat_mesh(hull_visual_root, "CabinDesignedRoofVolume", _make_cabin_roof_mesh(), CABIN_ROOF)
	_add_boat_mesh(hull_visual_root, "CabinRoofLightFacet", _make_cabin_roof_light_facet_mesh(), CABIN_ROOF_LIGHT)
	_add_boat_mesh(hull_visual_root, "CabinRoofShadowFacet", _make_cabin_roof_shadow_facet_mesh(), CABIN_ROOF_SHADOW)
	_add_boat_mesh(hull_visual_root, "CabinRearWindow", _make_quad_mesh_3d(
		Vector3(-0.17, 0.63, 0.982),
		Vector3(0.18, 0.635, 0.98),
		Vector3(0.16, 0.75, 0.965),
		Vector3(-0.15, 0.75, 0.968)
	), WINDOW_DARK)
	_add_boat_mesh(hull_visual_root, "CabinSideWindow", _make_quad_mesh_3d(
		Vector3(-0.407, 0.63, 0.20),
		Vector3(-0.423, 0.63, 0.51),
		Vector3(-0.382, 0.745, 0.53),
		Vector3(-0.368, 0.745, 0.22)
	), WINDOW_DARK)

	_add_cylinder(rig_visual_root, "SingleMast", 0.033, 3.18, Vector3(0.0, 1.80, -0.45), Vector3.ZERO, HULL_DARK, 10)
	_add_cylinder(rig_visual_root, "SimpleBoom", 0.026, 1.32, Vector3(0.34, 1.13, -0.42), Vector3(0.0, 0.0, 90.0), HULL_DARK, 8)
	_add_boat_mesh(hull_visual_root, "SimpleDesignedRudder", _make_rudder_mesh(), HULL_DARK)

	sail_root = Node3D.new()
	sail_root.name = "MainSailWindShape"
	sail_root.position = Vector3(0.0, 0.0, -0.47)
	rig_visual_root.add_child(sail_root)

	_add_boat_mesh(sail_root, "WarmMainSailBasePlane", _make_main_sail_mesh(), SAIL_WARM)
	_add_boat_mesh(sail_root, "MainSailLightPlane", _make_main_sail_light_mesh(), SAIL_LIGHT)
	_add_boat_mesh(sail_root, "MainSailShadowPlane", _make_main_sail_shadow_mesh(), SAIL_SHADOW, true, 0.72)

	var flag := MeshInstance3D.new()
	flag.name = "TinyWindFlag"
	flag.mesh = _make_vertical_polygon_mesh(PackedVector2Array([
		Vector2(0.02, 3.28),
		Vector2(0.47, 3.22),
		Vector2(0.27, 3.04),
		Vector2(0.02, 3.05),
	]))
	flag.material_override = _make_material("small_blue_flag", Color(0.04, 0.22, 0.35, 1.0), true)
	flag.position.z = 0.0
	sail_root.add_child(flag)


func _animate_boat(motion_factor: float) -> void:
	if boat_root == null:
		return
	var boat_life := motion_factor
	if journey_arrival_test_active:
		boat_life = lerpf(0.46, 1.0, motion_factor)
	elif sea_trial_active:
		boat_life = lerpf(0.42, 1.0, motion_factor)
	var bob := sin(visual_time * 1.18) * 0.045 * boat_life
	var roll := sin(visual_time * 0.92) * 1.4 * boat_life
	var pitch := sin(visual_time * 0.73 + 0.8) * 0.75 * boat_life
	boat_root.position = Vector3(boat_travel_position.x, BOAT_START_POSITION.y + bob, boat_travel_position.z)
	boat_root.rotation_degrees.x = pitch
	boat_root.rotation_degrees.z = roll
	boat_root.rotation_degrees.y = rad_to_deg(boat_heading)


func _update_navigation(delta: float, voyage_state: int, navigation_active: bool) -> void:
	var fast_target := JOURNEY_TEST_FAST_MULTIPLIER if test_fast_intent and voyage_state == 2 else 1.0
	test_speed_multiplier = move_toward(
		test_speed_multiplier,
		fast_target,
		JOURNEY_TEST_FAST_SMOOTHING * delta
	)
	if voyage_state != 2:
		test_fast_intent = false

	if navigation_active:
		# PC input intent is device-independent: negative means A/left and
		# positive means D/right. Godot's positive Y rotation turns the local
		# forward axis left, so the intent is inverted exactly once here.
		target_boat_heading = wrapf(
			target_boat_heading - steering_intent * STEERING_TURN_RATE * delta,
			-PI,
			PI
		)
		boat_heading = wrapf(lerp_angle(
			boat_heading,
			target_boat_heading,
			1.0 - exp(-STEERING_SMOOTHING * delta)
		), -PI, PI)
		var forward := _get_heading_forward()
		if sea_trial_active:
			_update_sea_trial_speed(delta)
		else:
			var target_speed := _get_navigation_target_speed(voyage_state)
			if journey_arrival_test_active:
				var speed_smoothing := (
					JOURNEY_TEST_ARRIVING_SPEED_SMOOTHING
						if voyage_state == 4 or voyage_state == 5
						else JOURNEY_TEST_SPEED_SMOOTHING
				)
				current_travel_speed = move_toward(
					current_travel_speed,
					target_speed,
					speed_smoothing * delta
				)
			else:
				current_travel_speed = target_speed
		if sea_trial_active:
			_move_sea_trial_with_world_constraints(delta, forward)
		else:
			actual_travel_velocity = forward * current_travel_speed
			boat_travel_position += actual_travel_velocity * delta
	else:
		actual_travel_velocity = Vector3.ZERO

	camera_look_angle = wrapf(lerp_angle(
		camera_look_angle,
		camera_look_target,
		1.0 - exp(-CAMERA_LOOK_SMOOTHING * delta)
	), -PI, PI)
	camera_look_vertical_angle = lerp(
		camera_look_vertical_angle,
		camera_look_vertical_target,
		1.0 - exp(-CAMERA_LOOK_SMOOTHING * delta)
	)


func _update_sea_trial_speed(delta: float) -> void:
	var requested_throttle := 0.0 if sea_trial_stop_requested else sea_trial_propulsion_intent
	sea_trial_throttle_ratio = move_toward(
		sea_trial_throttle_ratio,
		requested_throttle,
		SEA_TRIAL_THROTTLE_RESPONSE * delta
	)

	if sea_trial_stop_requested:
		current_travel_speed = move_toward(
			current_travel_speed,
			0.0,
			SEA_TRIAL_STOP_DECELERATION * delta
		)
		if absf(current_travel_speed) <= SEA_TRIAL_STOP_EPSILON:
			current_travel_speed = 0.0
			sea_trial_stop_requested = false
		return

	if sea_trial_space_departure_latched and current_travel_speed >= JOURNEY_TEST_FORWARD_SPEED:
		sea_trial_space_departure_latched = false

	if sea_trial_propulsion_intent > 0.01:
		if current_travel_speed < 0.0:
			current_travel_speed = move_toward(
				current_travel_speed,
				0.0,
				SEA_TRIAL_BRAKE_DECELERATION * delta
			)
		else:
			current_travel_speed = move_toward(
				current_travel_speed,
				SEA_TRIAL_MAX_FORWARD_SPEED,
				SEA_TRIAL_FORWARD_ACCELERATION * maxf(sea_trial_throttle_ratio, 0.15) * delta
			)
	elif sea_trial_propulsion_intent < -0.01:
		if current_travel_speed > 0.0:
			current_travel_speed = move_toward(
				current_travel_speed,
				0.0,
				SEA_TRIAL_BRAKE_DECELERATION * delta
			)
		else:
			current_travel_speed = move_toward(
				current_travel_speed,
				-SEA_TRIAL_MAX_REVERSE_SPEED,
				SEA_TRIAL_REVERSE_ACCELERATION * maxf(-sea_trial_throttle_ratio, 0.15) * delta
			)
	else:
		current_travel_speed = move_toward(
			current_travel_speed,
			0.0,
			SEA_TRIAL_COAST_DECELERATION * delta
		)


func _move_sea_trial_with_world_constraints(delta: float, forward: Vector3) -> void:
	sea_trial_land_contact = false
	sea_trial_boundary_factor = _get_sea_trial_boundary_factor(boat_travel_position, forward * current_travel_speed)
	if sea_trial_boundary_factor < 1.0 and current_travel_speed != 0.0:
		current_travel_speed *= sea_trial_boundary_factor

	var proposed_position := boat_travel_position + forward * current_travel_speed * delta
	if _is_inside_sea_trial_island(proposed_position):
		boat_travel_position = _get_sea_trial_island_contact_position(proposed_position)
		current_travel_speed = 0.0
		actual_travel_velocity = Vector3.ZERO
		sea_trial_land_contact = true
		return

	boat_travel_position = Vector3(
		clampf(proposed_position.x, SEA_TRIAL_WORLD_MIN_X, SEA_TRIAL_WORLD_MAX_X),
		boat_travel_position.y,
		clampf(proposed_position.z, SEA_TRIAL_WORLD_MIN_Z, SEA_TRIAL_WORLD_MAX_Z)
	)
	actual_travel_velocity = forward * current_travel_speed


func _get_sea_trial_boundary_factor(position: Vector3, velocity: Vector3) -> float:
	var factor := 1.0
	if velocity.x < 0.0 and position.x < SEA_TRIAL_WORLD_MIN_X + SEA_TRIAL_BOUNDARY_SOFT_MARGIN:
		factor = minf(factor, _smooth_boundary_factor(
			(position.x - SEA_TRIAL_WORLD_MIN_X) / SEA_TRIAL_BOUNDARY_SOFT_MARGIN
		))
	if velocity.x > 0.0 and position.x > SEA_TRIAL_WORLD_MAX_X - SEA_TRIAL_BOUNDARY_SOFT_MARGIN:
		factor = minf(factor, _smooth_boundary_factor(
			(SEA_TRIAL_WORLD_MAX_X - position.x) / SEA_TRIAL_BOUNDARY_SOFT_MARGIN
		))
	if velocity.z < 0.0 and position.z < SEA_TRIAL_WORLD_MIN_Z + SEA_TRIAL_BOUNDARY_SOFT_MARGIN:
		factor = minf(factor, _smooth_boundary_factor(
			(position.z - SEA_TRIAL_WORLD_MIN_Z) / SEA_TRIAL_BOUNDARY_SOFT_MARGIN
		))
	if velocity.z > 0.0 and position.z > SEA_TRIAL_WORLD_MAX_Z - SEA_TRIAL_BOUNDARY_SOFT_MARGIN:
		factor = minf(factor, _smooth_boundary_factor(
			(SEA_TRIAL_WORLD_MAX_Z - position.z) / SEA_TRIAL_BOUNDARY_SOFT_MARGIN
		))
	return clampf(factor, 0.0, 1.0)


func _smooth_boundary_factor(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _is_inside_sea_trial_island(position: Vector3) -> bool:
	var center := Vector2(JOURNEY_TEST_DESTINATION_POSITION.x, JOURNEY_TEST_DESTINATION_POSITION.z)
	var offset := Vector2(position.x, position.z) - center
	var normalized := Vector2(
		offset.x / SEA_TRIAL_ISLAND_COLLISION_RADIUS_X,
		offset.y / SEA_TRIAL_ISLAND_COLLISION_RADIUS_Z
	)
	return normalized.length_squared() < 1.0


func _get_sea_trial_island_contact_position(position: Vector3) -> Vector3:
	var center := Vector2(JOURNEY_TEST_DESTINATION_POSITION.x, JOURNEY_TEST_DESTINATION_POSITION.z)
	var offset := Vector2(position.x, position.z) - center
	var normalized := Vector2(
		offset.x / SEA_TRIAL_ISLAND_COLLISION_RADIUS_X,
		offset.y / SEA_TRIAL_ISLAND_COLLISION_RADIUS_Z
	)
	var direction := normalized.normalized()
	if direction.length_squared() < 0.000001:
		direction = Vector2(0.0, 1.0)
	var safe_offset := Vector2(
		direction.x * SEA_TRIAL_ISLAND_COLLISION_RADIUS_X,
		direction.y * SEA_TRIAL_ISLAND_COLLISION_RADIUS_Z
	)
	return Vector3(center.x + safe_offset.x, position.y, center.y + safe_offset.y)


func _animate_sail() -> void:
	if sail_root == null:
		return
	var breath := sin(visual_time * 1.55) * 0.035 * sail_life
	sail_root.rotation_degrees.y = -5.5 + sin(visual_time * 0.85) * 1.6 * sail_life
	sail_root.scale = Vector3(1.0 + breath, 1.0, 1.0)


func _animate_sea(delta: float, motion_factor: float, progress: float) -> void:
	var speed_factor := motion_factor
	for i in sea_strips.size():
		var strip: Node3D = sea_strips[i]
		var depth: float = clamp((strip.position.z + 38.0) / 45.0, 0.0, 1.0)
		var speed: float = lerpf(0.30, 1.55, depth) * speed_factor
		strip.position.z += speed * delta
		strip.position.x += sin(visual_time * 0.28 + float(i)) * 0.002
		if strip.position.z > 8.0:
			strip.position.z = -38.0
			strip.position.x = randf_range(-16.0, 16.0)
		var strip_scale: float = 0.86 + sin(visual_time * 0.55 + float(i) * 0.7) * 0.06
		strip.scale.y = strip_scale


	_update_wake_trail(delta, motion_factor)


func _update_wake_trail(delta: float, motion_factor: float) -> void:
	for i in range(wake_history_ages.size()):
		wake_history_ages[i] += delta
	while not wake_history_ages.is_empty() and wake_history_ages[0] >= WAKE_SEGMENT_LIFETIME:
		wake_history_points.pop_front()
		wake_history_rights.pop_front()
		wake_history_ages.pop_front()
		wake_history_strengths.pop_front()

	if actual_travel_velocity.length() >= WAKE_GENERATION_MIN_SPEED:
		wake_distance_since_spawn += actual_travel_velocity.length() * delta
		while wake_distance_since_spawn >= WAKE_SEGMENT_SPACING:
			wake_distance_since_spawn -= WAKE_SEGMENT_SPACING
			_spawn_wake_segment(clampf(motion_factor, 0.0, 1.0))
	_rebuild_wake_mesh()


func _spawn_wake_segment(strength: float) -> void:
	var travel_direction := actual_travel_velocity.normalized()
	var trailing_direction := -travel_direction
	var right_direction := travel_direction.cross(Vector3.UP).normalized()
	wake_history_points.append(Vector3(
		boat_travel_position.x + trailing_direction.x * WAKE_STERN_OFFSET,
		0.026,
		boat_travel_position.z + trailing_direction.z * WAKE_STERN_OFFSET
	))
	wake_history_rights.append(right_direction)
	wake_history_ages.append(0.0)
	wake_history_strengths.append(strength)
	while wake_history_points.size() > WAKE_MAX_POINTS:
		wake_history_points.pop_front()
		wake_history_rights.pop_front()
		wake_history_ages.pop_front()
		wake_history_strengths.pop_front()


func _rebuild_wake_mesh() -> void:
	if wake_mesh_instance == null or not wake_mesh_instance.mesh is ArrayMesh:
		return
	var wake_mesh: ArrayMesh = wake_mesh_instance.mesh
	wake_mesh.clear_surfaces()
	if wake_history_points.size() < 2:
		return

	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for side in [-1.0, 1.0]:
		var side_start := vertices.size()
		for i in range(wake_history_points.size()):
			var right: Vector3 = wake_history_rights[i].normalized()
			var center: Vector3 = wake_history_points[i] + right * float(side) * WAKE_TRACE_OFFSET
			vertices.append(center - right * WAKE_TRACE_HALF_WIDTH)
			vertices.append(center + right * WAKE_TRACE_HALF_WIDTH)
			var life: float = clampf(1.0 - wake_history_ages[i] / WAKE_SEGMENT_LIFETIME, 0.0, 1.0)
			var alpha: float = WAKE_WHITE.a * wake_history_strengths[i] * life * life
			var color: Color = Color(WAKE_WHITE.r, WAKE_WHITE.g, WAKE_WHITE.b, alpha)
			colors.append(color)
			colors.append(color)

		for i in range(wake_history_points.size() - 1):
			var a := side_start + i * 2
			var b := a + 2
			_add_quad_indices(indices, a, b, b + 1, a + 1)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	wake_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


func _get_active_wake_segment_count() -> int:
	return wake_history_points.size()


func _animate_distant_silhouette(progress: float) -> void:
	if far_silhouette_root == null:
		return
	if journey_test_active:
		return
	var approach := pow(clamp(progress, 0.0, 1.0), 1.6)
	far_silhouette_root.position.z = approach * 1.1
	far_silhouette_root.scale = Vector3.ONE * (1.0 + approach * 0.045)


func _set_camera(position: Vector3, target: Vector3, fov: float) -> void:
	if camera == null:
		return
	camera_shot_offset = position - BOAT_START_POSITION
	camera_shot_target_offset = target - BOAT_START_POSITION
	camera_shot_fov = fov
	camera_look_target = 0.0
	camera_look_angle = 0.0
	camera_look_vertical_target = 0.0
	camera_look_vertical_angle = 0.0
	camera_follow_heading = boat_heading
	camera_target_initialized = false
	camera.fov = camera_shot_fov
	_update_follow_camera(0.0, true)


func _update_follow_camera(delta: float, immediate: bool = false) -> void:
	if camera == null or boat_root == null:
		return
	if immediate:
		camera_follow_heading = boat_heading
	else:
		camera_follow_heading = wrapf(lerp_angle(
			camera_follow_heading,
			boat_heading,
			1.0 - exp(-CAMERA_HEADING_FOLLOW_SMOOTHING * max(delta, 0.0))
		), -PI, PI)
	var rig_angle := wrapf(camera_follow_heading + camera_look_angle, -PI, PI)
	var desired_position := boat_root.position + _rotate_camera_orbit(camera_shot_offset, rig_angle, camera_look_vertical_angle)
	var desired_target := boat_root.position + _rotate_camera_orbit(camera_shot_target_offset, rig_angle, camera_look_vertical_angle)
	if immediate:
		camera.position = desired_position
		camera_target_position = desired_target
		camera_target_initialized = true
	else:
		var blend := 1.0 - exp(-CAMERA_FOLLOW_SMOOTHING * max(delta, 0.0))
		camera.position = camera.position.lerp(desired_position, blend)
		if not camera_target_initialized:
			camera_target_position = desired_target
			camera_target_initialized = true
		else:
			camera_target_position = camera_target_position.lerp(desired_target, blend)
	camera.fov = camera_shot_fov
	camera.look_at(camera_target_position, Vector3.UP)


func _rotate_horizontal(value: Vector3, angle: float) -> Vector3:
	return value.rotated(Vector3.UP, angle)


func _get_heading_forward() -> Vector3:
	return Vector3.FORWARD.rotated(Vector3.UP, boat_heading).normalized()


func _rotate_camera_orbit(value: Vector3, yaw: float, pitch: float) -> Vector3:
	var yawed := _rotate_horizontal(value, yaw)
	var right_axis := _rotate_horizontal(Vector3.RIGHT, yaw)
	return yawed.rotated(right_axis, pitch)


func _make_material(name: String, color: Color, unshaded: bool = false, alpha: float = 1.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = name
	var final_color := color
	final_color.a *= alpha
	material.albedo_color = final_color
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if final_color.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.no_depth_test = false
	return material


func _add_box(parent: Node3D, node_name: String, size: Vector3, position: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.material_override = _make_material(node_name + "_mat", color)
	parent.add_child(instance)
	return instance


func _add_cylinder(parent: Node3D, node_name: String, radius: float, height: float, position: Vector3, rotation_degrees: Vector3, color: Color, radial_segments: int = 12) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = radial_segments
	instance.mesh = mesh
	instance.position = position
	instance.rotation_degrees = rotation_degrees
	instance.material_override = _make_material(node_name + "_mat", color)
	parent.add_child(instance)
	return instance


func _make_flat_rect(node_name: String, size: Vector2, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := PlaneMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = _make_material(node_name + "_mat", color, true)
	return instance


func _add_cloud_blob(parent: Node3D, position: Vector3, scale_2d: Vector2, color: Color) -> void:
	var blob := MeshInstance3D.new()
	blob.name = "FlatGraphicCloudBlob"
	blob.mesh = _make_disc_mesh(32)
	blob.material_override = _make_material("cloud_blob", color, true)
	blob.position = position
	blob.scale = Vector3(scale_2d.x, scale_2d.y, 1.0)
	parent.add_child(blob)


func _make_disc_mesh(segments: int) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	vertices.append(Vector3.ZERO)
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		vertices.append(Vector3(cos(angle), sin(angle), 0.0))
	for i in range(segments):
		indices.append(0)
		indices.append(i + 1)
		indices.append(1 + ((i + 1) % segments))
	return _make_array_mesh(vertices, indices)


func _make_vertical_polygon_mesh(points: PackedVector2Array) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	for point in points:
		vertices.append(Vector3(point.x, point.y, 0.0))
	for i in range(1, points.size() - 1):
		indices.append(0)
		indices.append(i)
		indices.append(i + 1)
	return _make_array_mesh(vertices, indices)


func _make_vertical_filled_mesh(top_points: PackedVector2Array, bottom_y: float) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	for point in top_points:
		vertices.append(Vector3(point.x, point.y, 0.0))
	for i in range(top_points.size() - 2):
		indices.append(0)
		indices.append(i + 1)
		indices.append(i + 2)
	var left_bottom_index := vertices.size()
	vertices.append(Vector3(top_points[0].x, bottom_y, 0.0))
	var right_bottom_index := vertices.size()
	vertices.append(Vector3(top_points[top_points.size() - 1].x, bottom_y, 0.0))
	indices.append(0)
	indices.append(left_bottom_index)
	indices.append(right_bottom_index)
	indices.append(0)
	indices.append(right_bottom_index)
	indices.append(top_points.size() - 1)
	return _make_array_mesh(vertices, indices)


func _make_extruded_vertical_mesh(top_points: PackedVector2Array, bottom_y: float, depth: float) -> ArrayMesh:
	# A shallow 3D extrusion keeps the low-cost silhouette while preventing the
	# distant land from behaving like a single paper-thin plane when observed
	# from the side. The front face remains the authored graphic silhouette.
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var half_depth := depth * 0.5
	var point_count := top_points.size()
	if point_count < 3:
		return _make_vertical_filled_mesh(top_points, bottom_y)

	var front_top_start := vertices.size()
	for point in top_points:
		vertices.append(Vector3(point.x, point.y, half_depth))
	var front_left_bottom := vertices.size()
	vertices.append(Vector3(top_points[0].x, bottom_y, half_depth))
	var front_right_bottom := vertices.size()
	vertices.append(Vector3(top_points[point_count - 1].x, bottom_y, half_depth))

	for i in range(point_count - 2):
		indices.append(front_top_start)
		indices.append(front_top_start + i + 1)
		indices.append(front_top_start + i + 2)
	indices.append(front_top_start)
	indices.append(front_left_bottom)
	indices.append(front_right_bottom)
	indices.append(front_top_start)
	indices.append(front_right_bottom)
	indices.append(front_top_start + point_count - 1)

	var back_top_start := vertices.size()
	for point in top_points:
		vertices.append(Vector3(point.x, point.y, -half_depth))
	var back_left_bottom := vertices.size()
	vertices.append(Vector3(top_points[0].x, bottom_y, -half_depth))
	var back_right_bottom := vertices.size()
	vertices.append(Vector3(top_points[point_count - 1].x, bottom_y, -half_depth))

	for i in range(point_count - 2):
		indices.append(back_top_start)
		indices.append(back_top_start + i + 2)
		indices.append(back_top_start + i + 1)
	indices.append(back_top_start)
	indices.append(back_right_bottom)
	indices.append(back_left_bottom)
	indices.append(back_top_start)
	indices.append(back_top_start + point_count - 1)
	indices.append(back_right_bottom)

	# Connect the silhouette edge and the lower edge. These faces are deliberately
	# simple; the land remains a graphic mass rather than a detailed terrain mesh.
	for i in range(point_count - 1):
		_add_quad_indices(
			indices,
			front_top_start + i,
			back_top_start + i,
			back_top_start + i + 1,
			front_top_start + i + 1
		)
	_add_quad_indices(indices, front_left_bottom, front_right_bottom, back_right_bottom, back_left_bottom)
	_add_quad_indices(indices, front_top_start, front_left_bottom, back_left_bottom, back_top_start)
	_add_quad_indices(
		indices,
		front_top_start + point_count - 1,
		back_top_start + point_count - 1,
		back_right_bottom,
		front_right_bottom
	)
	return _make_array_mesh(vertices, indices)


func _add_boat_mesh(parent: Node3D, node_name: String, mesh: ArrayMesh, color: Color, unshaded: bool = true, alpha: float = 1.0) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = _make_material(node_name + "_mat", color, unshaded, alpha)
	parent.add_child(instance)
	return instance


func _hull_sections() -> Array:
	return [
		{"z": -1.92, "top_half": 0.055, "chine_half": 0.040, "top_y": 0.34, "chine_y": 0.11, "keel_y": 0.02},
		{"z": -1.42, "top_half": 0.42, "chine_half": 0.31, "top_y": 0.37, "chine_y": -0.17, "keel_y": -0.31},
		{"z": -0.35, "top_half": 0.67, "chine_half": 0.50, "top_y": 0.34, "chine_y": -0.29, "keel_y": -0.48},
		{"z": 0.72, "top_half": 0.74, "chine_half": 0.54, "top_y": 0.27, "chine_y": -0.25, "keel_y": -0.41},
		{"z": 1.58, "top_half": 0.52, "chine_half": 0.39, "top_y": 0.18, "chine_y": -0.07, "keel_y": -0.19},
	]


func _hull_point(section: Dictionary, point_name: String, offset_x: float = 0.0, offset_y: float = 0.0, offset_z: float = 0.0) -> Vector3:
	var z: float = float(section["z"]) + offset_z
	match point_name:
		"port_top":
			return Vector3(-float(section["top_half"]) + offset_x, float(section["top_y"]) + offset_y, z)
		"starboard_top":
			return Vector3(float(section["top_half"]) + offset_x, float(section["top_y"]) + offset_y, z)
		"port_chine":
			return Vector3(-float(section["chine_half"]) + offset_x, float(section["chine_y"]) + offset_y, z)
		"starboard_chine":
			return Vector3(float(section["chine_half"]) + offset_x, float(section["chine_y"]) + offset_y, z)
		_:
			return Vector3(offset_x, float(section["keel_y"]) + offset_y, z)


func _make_hull_port_plane_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var sections: Array = _hull_sections()
	for section_index in range(sections.size()):
		var section: Dictionary = sections[section_index]
		vertices.append(_hull_point(section, "port_top", -0.012, 0.004))
		vertices.append(_hull_point(section, "port_chine", -0.012, 0.004))
	for i in range(sections.size() - 1):
		var a := i * 2
		var b := (i + 1) * 2
		_add_quad_indices(indices, a, b, b + 1, a + 1)
	return _make_array_mesh(vertices, indices)


func _make_hull_lower_shadow_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var sections: Array = _hull_sections()
	for section_index in range(1, sections.size()):
		var section: Dictionary = sections[section_index]
		vertices.append(_hull_point(section, "port_chine", -0.016, -0.006))
		vertices.append(_hull_point(section, "keel", -0.006, -0.006))
	for i in range(sections.size() - 2):
		var a := i * 2
		var b := (i + 1) * 2
		_add_quad_indices(indices, a, b, b + 1, a + 1)
	return _make_array_mesh(vertices, indices)


func _make_hull_stern_mesh() -> ArrayMesh:
	var sections: Array = _hull_sections()
	var stern: Dictionary = sections[sections.size() - 1]
	var vertices := PackedVector3Array([
		_hull_point(stern, "port_top", 0.0, 0.0, 0.012),
		_hull_point(stern, "starboard_top", 0.0, 0.0, 0.012),
		_hull_point(stern, "starboard_chine", 0.0, 0.0, 0.012),
		_hull_point(stern, "keel", 0.0, 0.0, 0.012),
		_hull_point(stern, "port_chine", 0.0, 0.0, 0.012),
	])
	var indices := PackedInt32Array([0, 1, 2, 0, 2, 3, 0, 3, 4])
	return _make_array_mesh(vertices, indices)


func _make_deck_mesh() -> ArrayMesh:
	return _make_horizontal_polygon_mesh(PackedVector2Array([
		Vector2(-0.055, -1.78),
		Vector2(0.055, -1.78),
		Vector2(0.50, -1.18),
		Vector2(0.66, -0.22),
		Vector2(0.62, 0.82),
		Vector2(0.46, 1.42),
		Vector2(-0.46, 1.42),
		Vector2(-0.62, 0.82),
		Vector2(-0.66, -0.22),
		Vector2(-0.50, -1.18),
	]), 0.392)


func _make_inner_deck_mesh() -> ArrayMesh:
	return _make_horizontal_polygon_mesh(PackedVector2Array([
		Vector2(-0.11, -1.18),
		Vector2(0.33, -1.05),
		Vector2(0.43, -0.20),
		Vector2(0.39, 0.68),
		Vector2(0.28, 1.05),
		Vector2(-0.38, 1.03),
		Vector2(-0.48, 0.50),
		Vector2(-0.46, -0.52),
	]), 0.408)


func _make_cabin_body_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array([
		Vector3(-0.34, 0.45, -0.10),
		Vector3(0.33, 0.45, -0.12),
		Vector3(-0.27, 0.82, -0.08),
		Vector3(0.27, 0.82, -0.10),
		Vector3(-0.44, 0.45, 0.98),
		Vector3(0.40, 0.45, 1.00),
		Vector3(-0.34, 0.80, 0.95),
		Vector3(0.32, 0.81, 0.96),
	])
	var indices := PackedInt32Array()
	_add_quad_indices(indices, 0, 1, 3, 2)
	_add_quad_indices(indices, 4, 6, 7, 5)
	_add_quad_indices(indices, 0, 2, 6, 4)
	_add_quad_indices(indices, 1, 5, 7, 3)
	_add_quad_indices(indices, 2, 3, 7, 6)
	return _make_array_mesh(vertices, indices)


func _make_cabin_port_plane_mesh() -> ArrayMesh:
	return _make_quad_mesh_3d(
		Vector3(-0.356, 0.458, -0.10),
		Vector3(-0.464, 0.458, 0.99),
		Vector3(-0.352, 0.812, 0.96),
		Vector3(-0.282, 0.832, -0.08)
	)


func _make_cabin_rear_plane_mesh() -> ArrayMesh:
	return _make_quad_mesh_3d(
		Vector3(-0.44, 0.45, 1.012),
		Vector3(0.40, 0.45, 1.012),
		Vector3(0.32, 0.81, 0.982),
		Vector3(-0.34, 0.80, 0.982)
	)


func _make_cabin_roof_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array([
		Vector3(-0.50, 0.80, -0.18),
		Vector3(-0.31, 0.965, -0.16),
		Vector3(0.25, 0.995, -0.17),
		Vector3(0.50, 0.815, -0.18),
		Vector3(-0.55, 0.79, 1.05),
		Vector3(-0.34, 0.95, 1.03),
		Vector3(0.31, 0.975, 1.04),
		Vector3(0.54, 0.805, 1.05),
	])
	var indices := PackedInt32Array()
	_add_quad_indices(indices, 0, 1, 5, 4)
	_add_quad_indices(indices, 1, 2, 6, 5)
	_add_quad_indices(indices, 2, 3, 7, 6)
	_add_quad_indices(indices, 0, 4, 7, 3)
	_add_quad_indices(indices, 0, 3, 2, 1)
	_add_quad_indices(indices, 4, 5, 6, 7)
	return _make_array_mesh(vertices, indices)


func _make_cabin_roof_light_facet_mesh() -> ArrayMesh:
	return _make_quad_mesh_3d(
		Vector3(-0.50, 0.807, -0.17),
		Vector3(-0.55, 0.797, 1.04),
		Vector3(-0.34, 0.958, 1.025),
		Vector3(-0.31, 0.973, -0.155)
	)


func _make_cabin_roof_shadow_facet_mesh() -> ArrayMesh:
	return _make_quad_mesh_3d(
		Vector3(0.25, 1.004, -0.155),
		Vector3(0.31, 0.984, 1.035),
		Vector3(0.54, 0.813, 1.052),
		Vector3(0.50, 0.823, -0.175)
	)


func _make_rudder_mesh() -> ArrayMesh:
	return _make_quad_mesh_3d(
		Vector3(-0.055, -0.02, 1.62),
		Vector3(0.075, -0.02, 1.60),
		Vector3(0.055, -0.55, 1.70),
		Vector3(-0.060, -0.47, 1.72)
	)


func _make_main_sail_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array([
		Vector3(0.08, 0.95, 0.005),
		Vector3(0.11, 3.08, -0.005),
		Vector3(0.88, 1.17, 0.135),
		Vector3(0.67, 0.90, 0.070),
	])
	var indices := PackedInt32Array([0, 1, 2, 0, 2, 3])
	return _make_array_mesh(vertices, indices)


func _make_main_sail_light_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array([
		Vector3(0.13, 1.02, 0.025),
		Vector3(0.15, 2.82, 0.012),
		Vector3(0.47, 1.25, 0.090),
		Vector3(0.38, 0.98, 0.060),
	])
	var indices := PackedInt32Array([0, 1, 2, 0, 2, 3])
	return _make_array_mesh(vertices, indices)


func _make_main_sail_shadow_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array([
		Vector3(0.46, 1.13, 0.125),
		Vector3(0.82, 1.18, 0.155),
		Vector3(0.66, 0.91, 0.087),
		Vector3(0.54, 0.95, 0.072),
	])
	var indices := PackedInt32Array([0, 1, 2, 0, 2, 3])
	return _make_array_mesh(vertices, indices)


func _make_horizontal_polygon_mesh(points: PackedVector2Array, y: float) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	for point in points:
		vertices.append(Vector3(point.x, y, point.y))
	for i in range(1, points.size() - 1):
		indices.append(0)
		indices.append(i)
		indices.append(i + 1)
	return _make_array_mesh(vertices, indices)


func _make_quad_mesh_3d(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> ArrayMesh:
	var vertices := PackedVector3Array([a, b, c, d])
	var indices := PackedInt32Array([0, 1, 2, 0, 2, 3])
	return _make_array_mesh(vertices, indices)


func _make_hull_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array()
	var sections: Array = _hull_sections()
	for section_index in range(sections.size()):
		var section: Dictionary = sections[section_index]
		vertices.append(_hull_point(section, "port_top"))
		vertices.append(_hull_point(section, "starboard_top"))
		vertices.append(_hull_point(section, "port_chine"))
		vertices.append(_hull_point(section, "starboard_chine"))
		vertices.append(_hull_point(section, "keel"))

	var indices := PackedInt32Array()
	for i in range(sections.size() - 1):
		var a := i * 5
		var b := (i + 1) * 5
		_add_quad_indices(indices, a + 0, b + 0, b + 2, a + 2)
		_add_quad_indices(indices, a + 3, b + 3, b + 1, a + 1)
		_add_quad_indices(indices, a + 2, b + 2, b + 4, a + 4)
		_add_quad_indices(indices, a + 4, b + 4, b + 3, a + 3)
		_add_quad_indices(indices, a + 0, a + 1, b + 1, b + 0)

	indices.append(0)
	indices.append(2)
	indices.append(4)
	indices.append(0)
	indices.append(4)
	indices.append(3)
	indices.append(0)
	indices.append(3)
	indices.append(1)

	var last := (sections.size() - 1) * 5
	indices.append(last + 0)
	indices.append(last + 1)
	indices.append(last + 3)
	indices.append(last + 0)
	indices.append(last + 3)
	indices.append(last + 4)
	indices.append(last + 0)
	indices.append(last + 4)
	indices.append(last + 2)
	return _make_array_mesh(vertices, indices)


func _add_quad_indices(indices: PackedInt32Array, a: int, b: int, c: int, d: int) -> void:
	indices.append(a)
	indices.append(b)
	indices.append(c)
	indices.append(a)
	indices.append(c)
	indices.append(d)


func _make_array_mesh(vertices: PackedVector3Array, indices: PackedInt32Array) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
