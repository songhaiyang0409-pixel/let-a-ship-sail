extends Node3D

## PORT-TO-PORT SLICE 03
##
## An isolated playable presentation slice. It deliberately does not instance
## the formal Sea Trial / Journey Test controller, camera, collision, wake,
## timer, or state machine. MovementRoot owns navigation; WaveVisualRoot owns
## only visual wave response.

const BOAT_SOURCE_SCRIPT := preload("res://visual_prototype_3d.gd")
const SURFACE_RESPONSE_SHADER := preload("res://materials/water_test/stylized_water_surface_response_05.gdshader")
const CAPTURE_DIR := "res://scenes/water/overnight_v03/port_to_port_slice_03_captures"
const VIEWPORT_SIZE := Vector2i(1152, 648)

const PORT_A_CENTER := Vector3(0.0, 0.0, 0.0)
const BOAT_START := Vector3(0.0, 0.0, 5.0)
const PORT_B_CENTER := Vector3(0.0, 0.0, -130.0)
const PORT_B_HARBOR := Vector3(0.0, 0.0, -121.0)
const PORT_B_APPROACH_RADIUS := 27.0
const PORT_B_ARRIVAL_RADIUS := 8.0
const PORT_B_ARRIVED_RADIUS := 1.4
const PORT_A_ARRIVAL_RADIUS := 8.0
const PORT_A_ARRIVED_RADIUS := 1.4
const PORT_A_APPROACH_RADIUS := 27.0
const DEPARTURE_CLEAR_DISTANCE := 8.0
const AUTOPLAY_PORT_DWELL := 1.0

const NORMAL_SPEED := 2.05
const MAX_SPEED := 4.20
const ARRIVAL_ENTRY_SPEED := 0.82
const ARRIVAL_DRIFT_SPEED := 0.18
const ACCELERATION := 2.40
const BRAKE_ACCELERATION := 3.60
const TURN_RATE := 0.62
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

const WAKE_COLOR := Color(0.80, 0.94, 0.93, 0.38)
const WAKE_SEGMENT_SPACING := 0.11
const WAKE_SEGMENT_LIFETIME := 2.4
const WAKE_GENERATION_MIN_SPEED := 0.10
const WAKE_STERN_OFFSET := 0.82
const WAKE_MAX_POINTS := 120
const WAKE_TRACE_OFFSET := 0.11
const WAKE_TRACE_HALF_WIDTH := 0.024

const WAVE_TIME_FACTOR := 2.7
const WAVE_AMPLITUDE_SCALE := 0.55
const WAVE_LENGTH_SCALE := 4.60
const ACTIVE_WAVE_INDICES := [0, 4, 6, 7]
const WAVE_PARAMS: Array[Vector4] = [
	Vector4(0.34, 3.60, 0.18, 0.86),
	Vector4(-0.26, -0.19, 0.01, 0.47),
	Vector4(-7.67, 5.63, 0.10, 0.38),
	Vector4(-0.42, -1.63, 0.10, 0.28),
	Vector4(1.42, 0.28, 0.12, 2.18),
	Vector4(1.20, 1.14, 0.01, 0.33),
	Vector4(-1.05, 2.90, 0.08, 1.30),
	Vector4(-0.58, -1.22, 0.10, 1.82),
]

enum VoyageState {
	AT_PORT_A,
	DEPARTING_A,
	OPEN_WATER_TO_B,
	APPROACHING_B,
	ARRIVING_B,
	AT_PORT_B,
	DEPARTING_B,
	OPEN_WATER_TO_A,
	APPROACHING_A,
	ARRIVING_A,
}

var water_material: ShaderMaterial
var water_mesh: MeshInstance3D
var sun: DirectionalLight3D
var boat_movement_root: Node3D
var wave_visual_root: Node3D
var boat_visual: Node3D
var camera: Camera3D
var wake_mesh_instance: MeshInstance3D
var phase := VoyageState.AT_PORT_A
var boat_heading := 0.0
var boat_speed := 0.0
var visual_time := 0.0
var arrival_slow_time := 0.0
var capture_mode := false
var autoplay := false
var quit_on_arrival := false
var collision_check_mode := false
var roundtrip_mode := false
var quit_after_roundtrip := false
var abuse_check_mode := false
var autoplay_port_wait := 0.0
var roundtrip_count := 0
var route_target := PORT_B_HARBOR
var route_origin := BOAT_START
var visual_preset := "balanced"
var port_b_layout := "A"
var port_b_visual_enabled := true
var presentation_land_contact := false
var actual_velocity := Vector3.ZERO
var wake_history_points: Array[Vector3] = []
var wake_history_rights: Array[Vector3] = []
var wake_history_ages: Array[float] = []
var wake_history_strengths: Array[float] = []
var wake_distance_since_spawn := 0.0


func _ready() -> void:
	_configure_viewport()
	_read_command_line()
	_build_environment()
	_build_water()
	_build_port_a()
	_build_port_b()
	await _build_playable_boat()
	_build_wake()
	_build_camera()
	_update_wave_visual()
	boat_speed = 0.0
	actual_velocity = Vector3.ZERO
	_set_state(VoyageState.AT_PORT_A)
	print("PORT_TO_PORT_SLICE_03_READY|isolated=true|boat_controller=local|water=surface_response_05|hud=false|start=AT_PORT_A")
	if capture_mode:
		call_deferred("_capture_all")
	elif abuse_check_mode:
		call_deferred("_run_abuse_check")
	elif collision_check_mode:
		call_deferred("_run_collision_check")


func _physics_process(delta: float) -> void:
	visual_time += delta
	if boat_movement_root == null:
		return
	if not capture_mode:
		_update_navigation(delta)
		_update_wake(delta)
	_update_wave_visual()
	_update_camera(delta)
	_update_water_uniforms()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		# Match the approved Sea Trial drag semantics. Mouse input changes only
		# camera look intent; it never changes the boat heading.
		camera_look_target = wrapf(
			camera_look_target - motion.relative.x * CAMERA_LOOK_SENSITIVITY,
			-PI,
			PI
		)
		camera_look_vertical_target = clampf(
			camera_look_vertical_target - motion.relative.y * CAMERA_LOOK_VERTICAL_SENSITIVITY,
			CAMERA_LOOK_VERTICAL_MIN,
			CAMERA_LOOK_VERTICAL_MAX
		)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			reset_camera()
		if event.keycode == KEY_BACKSPACE:
			_reset_boat_to_port_a()
		if event.keycode == KEY_SPACE and phase in [VoyageState.AT_PORT_A, VoyageState.AT_PORT_B]:
			_begin_departure_from_current_port()


var camera_shot_offset := DEFAULT_CAMERA_POSITION
var camera_shot_target_offset := DEFAULT_CAMERA_TARGET
var camera_shot_fov := DEFAULT_CAMERA_FOV
var camera_look_target := 0.0
var camera_look_angle := 0.0
var camera_look_vertical_target := 0.0
var camera_look_vertical_angle := 0.0
var camera_follow_heading := 0.0
var camera_target_position := Vector3.ZERO
var camera_target_initialized := false


func _read_command_line() -> void:
	var args := OS.get_cmdline_user_args()
	capture_mode = args.has("--capture-port-to-port-v03")
	autoplay = args.has("--port-to-port-v03-autoplay")
	roundtrip_mode = args.has("--port-to-port-v03-roundtrip")
	quit_after_roundtrip = args.has("--quit-after-roundtrip")
	quit_on_arrival = args.has("--quit-on-arrival")
	collision_check_mode = args.has("--port-to-port-v03-collision-check")
	abuse_check_mode = args.has("--port-to-port-v03-abuse-check")
	port_b_visual_enabled = not args.has("--port-b-visual-off")
	if args.has("--port-b-layout-b"):
		port_b_layout = "B"
	elif args.has("--port-b-layout-c"):
		port_b_layout = "C"
	if args.has("--v03-calm"):
		visual_preset = "calm"
	elif args.has("--v03-lively"):
		visual_preset = "lively"


func _configure_viewport() -> void:
	var window := get_window()
	window.size = VIEWPORT_SIZE
	window.content_scale_size = VIEWPORT_SIZE
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "PortToPortEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.18, 0.42, 0.64, 1.0)
	sky_material.sky_horizon_color = Color(0.76, 0.85, 0.86, 1.0)
	sky_material.ground_bottom_color = Color(0.08, 0.20, 0.28, 1.0)
	sky_material.ground_horizon_color = Color(0.56, 0.72, 0.75, 1.0)
	sky_material.sun_angle_max = 12.0
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.64, 0.74, 0.80, 1.0)
	environment.ambient_light_energy = 0.78
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.62, 0.74, 0.76, 1.0)
	environment.fog_light_energy = 0.50
	environment.fog_density = 0.0022
	environment.fog_sky_affect = 0.22
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	if visual_preset == "calm":
		environment.fog_density = 0.0026
		environment.fog_light_energy = 0.44
	elif visual_preset == "lively":
		environment.fog_density = 0.0019
		environment.fog_light_energy = 0.56
	world_environment.environment = environment
	add_child(world_environment)

	sun = DirectionalLight3D.new()
	sun.name = "PortToPortSun"
	sun.rotation_degrees = Vector3(-48.0, -26.0, 0.0)
	sun.light_color = Color(1.0, 0.93, 0.82, 1.0)
	sun.light_energy = 1.08
	if visual_preset == "calm":
		sun.light_energy = 1.00
	elif visual_preset == "lively":
		sun.light_energy = 1.12
	sun.shadow_enabled = true
	add_child(sun)


func _build_water() -> void:
	water_mesh = MeshInstance3D.new()
	water_mesh.name = "Water"
	var plane := PlaneMesh.new()
	plane.size = Vector2(220.0, 300.0)
	plane.subdivide_width = 160
	plane.subdivide_depth = 160
	water_mesh.mesh = plane
	water_material = ShaderMaterial.new()
	water_material.shader = SURFACE_RESPONSE_SHADER
	for index in range(WAVE_PARAMS.size()):
		water_material.set_shader_parameter("wave_%d" % (index + 1), WAVE_PARAMS[index])
	water_material.set_shader_parameter("wave_time", 0.0)
	water_material.set_shader_parameter("time_factor", WAVE_TIME_FACTOR)
	water_material.set_shader_parameter("wave_amplitude_scale", WAVE_AMPLITUDE_SCALE)
	water_material.set_shader_parameter("wave_length_scale", WAVE_LENGTH_SCALE)
	water_material.set_shader_parameter("trough_color", Vector3(0.045, 0.160, 0.255))
	water_material.set_shader_parameter("water_color", Vector3(0.065, 0.255, 0.355))
	water_material.set_shader_parameter("crest_color", Vector3(0.120, 0.335, 0.405))
	water_material.set_shader_parameter("atmospheric_water_color", Vector3(0.205, 0.345, 0.415))
	water_material.set_shader_parameter("sky_tint", Vector3(0.47, 0.62, 0.68))
	water_material.set_shader_parameter("crest_strength", 0.19)
	water_material.set_shader_parameter("directional_shading_strength", 0.20)
	water_material.set_shader_parameter("fresnel_strength", 0.075)
	water_material.set_shader_parameter("distance_color_strength", 0.18)
	water_material.set_shader_parameter("breakup_strength", 0.03)
	water_material.set_shader_parameter("ripple_direction", Vector2(0.94, 0.34))
	water_material.set_shader_parameter("ripple_frequency", 0.72)
	water_material.set_shader_parameter("ripple_speed", 0.52)
	water_material.set_shader_parameter("ripple_normal_strength", 0.11)
	water_material.set_shader_parameter("ripple_light_strength", 0.32)
	water_material.set_shader_parameter("ripple_specular_strength", 0.62)
	water_material.set_shader_parameter("ripple_near_distance", 4.0)
	water_material.set_shader_parameter("ripple_far_distance", 30.0)
	if visual_preset == "calm":
		water_material.set_shader_parameter("crest_strength", 0.16)
		water_material.set_shader_parameter("directional_shading_strength", 0.17)
		water_material.set_shader_parameter("fresnel_strength", 0.06)
		water_material.set_shader_parameter("ripple_light_strength", 0.24)
		water_material.set_shader_parameter("ripple_specular_strength", 0.48)
	elif visual_preset == "lively":
		water_material.set_shader_parameter("crest_strength", 0.22)
		water_material.set_shader_parameter("directional_shading_strength", 0.23)
		water_material.set_shader_parameter("fresnel_strength", 0.085)
		water_material.set_shader_parameter("ripple_light_strength", 0.36)
		water_material.set_shader_parameter("ripple_specular_strength", 0.70)
	water_mesh.material_override = water_material
	add_child(water_mesh)


func _build_port_a() -> void:
	var port := Node3D.new()
	port.name = "PortA_Departure"
	port.set_meta("asset_status", "PLACEHOLDER_BLOCKOUT_ONLY")
	port.position = PORT_A_CENTER
	add_child(port)
	# A connected U-shaped harbor: two low arms lead back to a quiet settlement
	# shore. The central basin and the northern mouth remain fully navigable.
	var land_color := Color(0.46, 0.34, 0.22, 1.0)
	var upper_color := Color(0.34, 0.38, 0.27, 1.0)
	var left_arm := _add_slope_mass(port, "HarborArm_Left", Vector3(4.4, 1.2, 13.0), Vector3(-5.7, -0.08, 7.4), 0.70, 1.02, land_color)
	left_arm.rotation_degrees.y = -4.0
	var right_arm := _add_slope_mass(port, "HarborArm_Right", Vector3(4.4, 1.2, 13.0), Vector3(5.7, -0.08, 7.4), 0.70, 1.02, land_color)
	right_arm.rotation_degrees.y = 4.0
	_add_slope_mass(port, "SettlementShore", Vector3(15.4, 1.5, 4.0), Vector3(0.0, -0.06, 14.5), 0.88, 1.20, land_color)
	_add_slope_mass(port, "SettlementGreen", Vector3(10.8, 0.55, 2.8), Vector3(0.3, 0.78, 14.6), 0.18, 0.32, upper_color)
	_add_block(port, "DepartureDock", Vector3(1.6, 0.18, 4.8), Vector3(-3.35, 0.18, 9.2), Vector3.ZERO, Color(0.30, 0.20, 0.13, 1.0))
	_add_block(port, "DepartureDockEnd", Vector3(2.3, 0.20, 0.70), Vector3(-3.35, 0.30, 6.85), Vector3.ZERO, Color(0.40, 0.26, 0.15, 1.0))
	_add_house(port, "PortA_House_West", Vector3(-4.8, 1.38, 13.8), Vector3(1.7, 1.05, 1.3), 0.0)
	_add_house(port, "PortA_House_Center", Vector3(0.1, 1.52, 14.4), Vector3(1.9, 1.18, 1.4), 0.0)
	_add_house(port, "PortA_House_East", Vector3(4.4, 1.35, 13.6), Vector3(1.6, 1.0, 1.25), 0.0)
	_add_house(port, "PortA_Workshop", Vector3(-5.4, 1.20, 9.8), Vector3(1.5, 0.95, 1.2), 0.0)
	_add_cylinder(port, "PortA_HarborMarker", 0.24, 3.0, Vector3(4.55, 2.25, 1.4), Color(0.82, 0.75, 0.58, 1.0), 8)
	_add_cylinder(port, "PortA_HarborMarkerCap", 0.34, 0.22, Vector3(4.55, 3.86, 1.4), Color(0.56, 0.22, 0.14, 1.0), 8)


func _build_port_b() -> void:
	var port := Node3D.new()
	port.name = "PortB_Root"
	port.set_meta("asset_status", "PLACEHOLDER_BLOCKOUT_ONLY")
	port.set_meta("architecture", "VisualRoot is replaceable; CollisionRoot is script-owned")
	port.position = PORT_B_CENTER
	add_child(port)
	var visual_root := Node3D.new()
	visual_root.name = "PortBVisualRoot"
	visual_root.set_meta("replaceable", true)
	port.add_child(visual_root)
	var collision_root := Node3D.new()
	collision_root.name = "PortBCollisionRoot"
	collision_root.set_meta("collision_owner", "_is_presentation_land(position)")
	collision_root.set_meta("replace_visual_without_rebuilding_collision", true)
	port.add_child(collision_root)
	var layouts_root := Node3D.new()
	layouts_root.name = "PortBVisualLayouts"
	visual_root.add_child(layouts_root)
	var active_layout: Node3D
	for layout_name in ["A", "B", "C"]:
		var layout := Node3D.new()
		layout.name = "PortBVisualLayout_%s" % layout_name
		layout.set_meta("layout_id", layout_name)
		layout.set_meta("placeholder_only", true)
		layout.visible = layout_name == port_b_layout and port_b_visual_enabled
		layouts_root.add_child(layout)
		for mount_name in ["Lighthouse", "Houses", "Pier", "Breakwater", "Rocks", "Vegetation", "LandmarkProps"]:
			var mount := Node3D.new()
			mount.name = "%sMount" % mount_name
			mount.set_meta("replace_with_glb", true)
			layout.add_child(mount)
		if layout_name == port_b_layout:
			active_layout = layout
	if active_layout == null:
		active_layout = layouts_root.get_node("PortBVisualLayout_A")
	# Keep the existing generator below intact while redirecting all of its
	# placeholder visuals into the selected replaceable layout container.
	port = active_layout
	var lighthouse_mount: Node3D = active_layout.get_node("LighthouseMount")
	var houses_mount: Node3D = active_layout.get_node("HousesMount")
	var pier_mount: Node3D = active_layout.get_node("PierMount")
	var breakwater_mount: Node3D = active_layout.get_node("BreakwaterMount")
	var high := Node3D.new()
	high.name = "HighTerrace_LandmarkLayer"
	active_layout.add_child(high)
	var middle := Node3D.new()
	middle.name = "MiddleSlope_SettlementLayer"
	active_layout.add_child(middle)
	var shore := Node3D.new()
	shore.name = "LowerShore_DockLayer"
	active_layout.add_child(shore)

	# Two headlands form a real cove. The central water corridor continues to a
	# low back shore while the dock sits safely to one side.
	var shore_color := Color(0.53, 0.39, 0.22, 1.0)
	var slope_color := Color(0.16, 0.31, 0.28, 1.0)
	var high_color := Color(0.22, 0.36, 0.29, 1.0)
	var left_headland := _add_slope_mass(breakwater_mount, "CoveHeadland_Left", Vector3(7.6, 1.8, 7.0), Vector3(-6.2, -0.22, 8.5), 0.62, 1.18, shore_color)
	left_headland.rotation_degrees.y = -5.0
	var right_headland := _add_slope_mass(breakwater_mount, "CoveHeadland_Right", Vector3(7.6, 1.8, 7.0), Vector3(6.2, -0.22, 8.5), 0.62, 1.18, shore_color)
	right_headland.rotation_degrees.y = 5.0
	_add_slope_mass(shore, "CoveBackShore", Vector3(12.0, 1.6, 3.0), Vector3(0.0, -0.20, 2.5), 0.70, 1.15, shore_color)
	_add_block(pier_mount, "ArrivalDock", Vector3(1.55, 0.18, 6.5), Vector3(-3.0, 0.25, 7.0), Vector3.ZERO, Color(0.31, 0.21, 0.13, 1.0))
	_add_block(pier_mount, "ArrivalDockEnd", Vector3(2.4, 0.20, 0.72), Vector3(-3.0, 0.35, 10.15), Vector3.ZERO, Color(0.42, 0.27, 0.15, 1.0))
	_add_slope_mass(middle, "MiddleSlope_Left", Vector3(6.6, 2.4, 5.2), Vector3(-3.8, 0.48, -0.5), 0.88, 1.84, slope_color)
	_add_slope_mass(middle, "MiddleSlope_Center", Vector3(5.8, 2.7, 4.8), Vector3(0.0, 0.72, -1.2), 1.05, 2.18, slope_color)
	_add_slope_mass(middle, "MiddleSlope_Right", Vector3(6.2, 2.3, 5.0), Vector3(3.8, 0.54, -0.7), 0.82, 1.72, slope_color)
	_add_slope_mass(high, "HighTerrace", Vector3(5.8, 1.8, 3.4), Vector3(0.8, 2.38, -3.7), 0.66, 1.18, high_color)
	_add_house(houses_mount, "PortB_House_Left", Vector3(-4.2, 2.45, 0.2), Vector3(1.8, 1.15, 1.35), -5.0)
	_add_house(houses_mount, "PortB_House_Center", Vector3(-1.2, 2.75, -0.3), Vector3(2.0, 1.30, 1.50), -3.0)
	_add_house(houses_mount, "PortB_House_Right", Vector3(2.1, 2.55, 0.0), Vector3(1.8, 1.15, 1.35), -6.0)
	_add_house(houses_mount, "PortB_House_Back", Vector3(4.2, 3.08, -1.5), Vector3(1.6, 1.10, 1.25), -7.0)
	_add_house(houses_mount, "PortB_HighHouse", Vector3(-1.9, 4.15, -3.0), Vector3(1.5, 1.0, 1.15), -4.0)
	_add_block(middle, "PathFromDock", Vector3(0.48, 0.10, 4.0), Vector3(-2.7, 1.75, 1.5), Vector3(-10.0, 0.0, -12.0), Color(0.25, 0.22, 0.17, 1.0))
	_add_block(middle, "PathToHigh", Vector3(0.42, 0.10, 3.1), Vector3(1.7, 3.25, -2.0), Vector3(-12.0, 0.0, 0.0), Color(0.25, 0.22, 0.17, 1.0))
	_add_cylinder(lighthouse_mount, "PortB_Lighthouse", 0.38, 3.7, Vector3(2.2, 5.45, -3.4), Color(0.86, 0.80, 0.66, 1.0), 10)
	_add_cylinder(lighthouse_mount, "PortB_LighthouseCap", 0.50, 0.28, Vector3(2.2, 7.44, -3.4), Color(0.66, 0.25, 0.16, 1.0), 10)


func _build_playable_boat() -> void:
	var source := BOAT_SOURCE_SCRIPT.new()
	source.name = "BoatVisualSource_TEMPORARY"
	source.visible = false
	add_child(source)
	await get_tree().process_frame
	var source_boat := source.get_node_or_null("MainCabinSailboatBlockoutV02")
	if source_boat == null:
		push_error("PortToPortSlice01 could not extract boat visual.")
		source.free()
		return
	boat_movement_root = Node3D.new()
	boat_movement_root.name = "PlayableBoat"
	boat_movement_root.set_meta("architecture", "BoatMovementRoot owns navigation")
	boat_movement_root.position = BOAT_START
	add_child(boat_movement_root)
	wave_visual_root = Node3D.new()
	wave_visual_root.name = "WaveVisualRoot"
	wave_visual_root.set_meta("architecture", "WaveVisualRoot owns heave pitch roll only")
	boat_movement_root.add_child(wave_visual_root)
	boat_visual = source_boat.duplicate()
	boat_visual.name = "BoatVisual"
	boat_visual.position = Vector3.ZERO
	wave_visual_root.add_child(boat_visual)
	source.free()


func _build_wake() -> void:
	wake_mesh_instance = MeshInstance3D.new()
	wake_mesh_instance.name = "PresentationWake_WorldSpace"
	wake_mesh_instance.mesh = ArrayMesh.new()
	var wake_material := StandardMaterial3D.new()
	wake_material.albedo_color = Color(1.0, 1.0, 1.0, 0.72)
	wake_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wake_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wake_material.vertex_color_use_as_albedo = true
	wake_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	wake_mesh_instance.material_override = wake_material
	add_child(wake_mesh_instance)


func _update_wake(delta: float) -> void:
	for index in range(wake_history_ages.size()):
		wake_history_ages[index] += delta
	while not wake_history_ages.is_empty() and wake_history_ages[0] >= WAKE_SEGMENT_LIFETIME:
		wake_history_points.pop_front()
		wake_history_rights.pop_front()
		wake_history_ages.pop_front()
		wake_history_strengths.pop_front()

	var travel_speed := actual_velocity.length()
	if not _is_at_port() and travel_speed >= WAKE_GENERATION_MIN_SPEED:
		wake_distance_since_spawn += travel_speed * delta
		while wake_distance_since_spawn >= WAKE_SEGMENT_SPACING:
			wake_distance_since_spawn -= WAKE_SEGMENT_SPACING
			_spawn_wake_segment(clampf(travel_speed / NORMAL_SPEED, 0.0, 1.0))
	_rebuild_wake_mesh()


func _spawn_wake_segment(strength: float) -> void:
	if actual_velocity.length_squared() < 0.0001:
		return
	var travel_direction := actual_velocity.normalized()
	var trailing_direction := -travel_direction
	var right_direction := travel_direction.cross(Vector3.UP).normalized()
	var point := boat_movement_root.position + trailing_direction * WAKE_STERN_OFFSET
	var wave := _calculate_wave(Vector2(point.x, point.z), visual_time / WAVE_TIME_FACTOR)
	point.y = float(wave["height"]) + 0.045
	wake_history_points.append(point)
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
		for index in range(wake_history_points.size()):
			var right: Vector3 = wake_history_rights[index].normalized()
			var center: Vector3 = wake_history_points[index] + right * float(side) * WAKE_TRACE_OFFSET
			vertices.append(center - right * WAKE_TRACE_HALF_WIDTH)
			vertices.append(center + right * WAKE_TRACE_HALF_WIDTH)
			var life := clampf(1.0 - wake_history_ages[index] / WAKE_SEGMENT_LIFETIME, 0.0, 1.0)
			var alpha := WAKE_COLOR.a * wake_history_strengths[index] * life * life
			var color := Color(WAKE_COLOR.r, WAKE_COLOR.g, WAKE_COLOR.b, alpha)
			colors.append(color)
			colors.append(color)
		for index in range(wake_history_points.size() - 1):
			var a := side_start + index * 2
			var b := a + 2
			_add_quad_indices(indices, a, b, b + 1, a + 1)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	wake_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


func _clear_wake() -> void:
	wake_history_points.clear()
	wake_history_rights.clear()
	wake_history_ages.clear()
	wake_history_strengths.clear()
	wake_distance_since_spawn = 0.0
	_rebuild_wake_mesh()


func _seed_wake_for_capture(strength: float) -> void:
	_clear_wake()
	var travel_direction := _heading_forward()
	var trailing_direction := -travel_direction
	var right_direction := travel_direction.cross(Vector3.UP).normalized()
	for index in range(24):
		var distance := WAKE_STERN_OFFSET + float(index) * WAKE_SEGMENT_SPACING
		var point := boat_movement_root.position + trailing_direction * distance
		var wave := _calculate_wave(Vector2(point.x, point.z), visual_time / WAVE_TIME_FACTOR)
		point.y = float(wave["height"]) + 0.045
		wake_history_points.push_front(point)
		wake_history_rights.push_front(right_direction)
		wake_history_ages.push_front(float(index) / 23.0 * WAKE_SEGMENT_LIFETIME * 0.86)
		wake_history_strengths.push_front(strength)
	_rebuild_wake_mesh()


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "CameraRig"
	camera.current = true
	camera.near = 0.05
	camera.far = 240.0
	camera.fov = DEFAULT_CAMERA_FOV
	add_child(camera)
	_update_camera(0.0)


func _update_navigation(delta: float) -> void:
	if _is_at_port():
		boat_speed = 0.0
		actual_velocity = Vector3.ZERO
		if autoplay:
			autoplay_port_wait += delta
			if autoplay_port_wait >= AUTOPLAY_PORT_DWELL:
				_begin_departure_from_current_port()
		return

	var steering := 0.0
	if not autoplay:
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			steering -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			steering += 1.0
	boat_heading = wrapf(boat_heading + steering * TURN_RATE * delta, -TAU, TAU)

	var distance_before := _horizontal_distance_to(route_target, boat_movement_root.position)
	var target_speed := NORMAL_SPEED
	if not autoplay and Input.is_key_pressed(KEY_W):
		target_speed = MAX_SPEED
	if not autoplay and Input.is_key_pressed(KEY_S):
		target_speed = 0.0
	if phase in [VoyageState.APPROACHING_A, VoyageState.APPROACHING_B]:
		target_speed = min(target_speed, NORMAL_SPEED * 0.78)
	elif phase in [VoyageState.ARRIVING_A, VoyageState.ARRIVING_B]:
		var arrival_radius := PORT_A_ARRIVAL_RADIUS if phase == VoyageState.ARRIVING_A else PORT_B_ARRIVAL_RADIUS
		var arrival_mix := clampf(distance_before / arrival_radius, 0.0, 1.0)
		target_speed = lerpf(ARRIVAL_DRIFT_SPEED, ARRIVAL_ENTRY_SPEED, arrival_mix)
	var rate := ACCELERATION if target_speed >= boat_speed else BRAKE_ACCELERATION
	boat_speed = move_toward(boat_speed, target_speed, rate * delta)

	var forward := _heading_forward()
	var previous_position := boat_movement_root.position
	boat_movement_root.position = _move_with_land_guard(forward, delta)
	actual_velocity = (boat_movement_root.position - previous_position) / maxf(delta, 0.0001)
	var distance_to_target := _horizontal_distance_to(route_target, boat_movement_root.position)
	_update_route_state(delta, distance_to_target)


func _update_route_state(delta: float, distance_to_target: float) -> void:
	match phase:
		VoyageState.DEPARTING_A:
			if _horizontal_distance_to(route_origin, boat_movement_root.position) >= DEPARTURE_CLEAR_DISTANCE:
				_set_state(VoyageState.OPEN_WATER_TO_B)
		VoyageState.DEPARTING_B:
			if _horizontal_distance_to(route_origin, boat_movement_root.position) >= DEPARTURE_CLEAR_DISTANCE:
				_set_state(VoyageState.OPEN_WATER_TO_A)
		VoyageState.OPEN_WATER_TO_B:
			if distance_to_target <= PORT_B_APPROACH_RADIUS:
				_set_state(VoyageState.APPROACHING_B)
		VoyageState.APPROACHING_B:
			if distance_to_target > PORT_B_APPROACH_RADIUS + 4.0:
				_set_state(VoyageState.OPEN_WATER_TO_B)
			elif distance_to_target <= PORT_B_ARRIVAL_RADIUS:
				_set_state(VoyageState.ARRIVING_B)
		VoyageState.ARRIVING_B:
			if distance_to_target > PORT_B_ARRIVAL_RADIUS + 3.0:
				_set_state(VoyageState.APPROACHING_B)
			elif distance_to_target <= PORT_B_ARRIVED_RADIUS and boat_speed <= ARRIVAL_DRIFT_SPEED + 0.12:
				arrival_slow_time += delta
				if arrival_slow_time >= 1.0:
					_set_state(VoyageState.AT_PORT_B)
			else:
				arrival_slow_time = 0.0
		VoyageState.OPEN_WATER_TO_A:
			if distance_to_target <= PORT_A_APPROACH_RADIUS:
				_set_state(VoyageState.APPROACHING_A)
		VoyageState.APPROACHING_A:
			if distance_to_target > PORT_A_APPROACH_RADIUS + 4.0:
				_set_state(VoyageState.OPEN_WATER_TO_A)
			elif distance_to_target <= PORT_A_ARRIVAL_RADIUS:
				_set_state(VoyageState.ARRIVING_A)
		VoyageState.ARRIVING_A:
			if distance_to_target > PORT_A_ARRIVAL_RADIUS + 3.0:
				_set_state(VoyageState.APPROACHING_A)
			elif distance_to_target <= PORT_A_ARRIVED_RADIUS and boat_speed <= ARRIVAL_DRIFT_SPEED + 0.12:
				arrival_slow_time += delta
				if arrival_slow_time >= 1.0:
					_set_state(VoyageState.AT_PORT_A)
			else:
				arrival_slow_time = 0.0
	if _is_at_port() and autoplay:
		if phase == VoyageState.AT_PORT_A:
			roundtrip_count += 1
		if quit_after_roundtrip and roundtrip_count >= 2:
			print("PORT_TO_PORT_SLICE_03_AUTOPLAY_COMPLETE|round_trips=%d" % roundtrip_count)
			get_tree().quit()


func _run_collision_check() -> void:
	var failures: Array[String] = []
	# Port A land: approach the left arm away from the dock. The swept guard
	# must keep the root at the last safe position and stop forward travel.
	boat_movement_root.position = PORT_A_CENTER + Vector3(-3.0, 0.0, 3.0)
	boat_heading = -PI / 2.0
	boat_speed = 2.0
	presentation_land_contact = false
	var port_a_after := _move_with_land_guard(_heading_forward(), 0.5)
	if _is_presentation_land(port_a_after) or boat_speed > 0.001:
		failures.append("Port A bank did not stop the boat at the last safe position.")
	# Steering away from the contact must remain possible.
	boat_heading = PI / 2.0
	boat_speed = 2.0
	var port_a_escape := _move_with_land_guard(_heading_forward(), 0.5)
	if port_a_escape.x <= port_a_after.x + 0.001:
		failures.append("Port A contact did not allow an escape direction.")
	# Both visible docks are part of the same lightweight forbidden geometry.
	if not _is_presentation_land(PORT_A_CENTER + Vector3(-3.35, 0.0, 9.2)):
		failures.append("Port A dock was not included in the presentation collision.")
	if not _is_presentation_land(PORT_B_CENTER + Vector3(-3.0, 0.0, 7.0)):
		failures.append("Port B dock was not included in the presentation collision.")
	# Port B: approach the broad shore from the open-water side.
	boat_movement_root.position = PORT_B_CENTER + Vector3(-1.9, 0.0, 8.5)
	boat_heading = -PI / 2.0
	boat_speed = 2.0
	presentation_land_contact = false
	var port_b_after := _move_with_land_guard(_heading_forward(), 0.5)
	if _is_presentation_land(port_b_after) or boat_speed > 0.001:
		failures.append("Port B shore did not stop the boat at the last safe position.")
	_reset_boat_to_port_a()
	if _is_presentation_land(boat_movement_root.position):
		failures.append("Backspace reset spawn is inside presentation collision.")
	if failures.is_empty():
		print("PORT_TO_PORT_SLICE_03_COLLISION_CHECK=PASS|PortA=blocked_escape_ok|PortB=blocked|docks=blocked|reset=safe")
	else:
		for failure in failures:
			push_error(failure)
		print("PORT_TO_PORT_SLICE_03_COLLISION_CHECK=FAIL|count=%d" % failures.size())
	get_tree().quit()


func _run_abuse_check() -> void:
	var failures: Array[String] = []
	var case_count := 0
	var start_position := boat_movement_root.position
	# 1: a stopped port remains stopped, even when the simulation is stepped.
	for _step in range(20):
		_update_navigation(0.1)
	case_count += 1
	if boat_movement_root.position.distance_to(start_position) > 0.001 or boat_speed > 0.001:
		failures.append("idle Port A moved")
	# 2-5: both Port A arms, shore, and dock remain forbidden.
	var port_a_points := [
		PORT_A_CENTER + Vector3(-5.7, 0.0, 7.4),
		PORT_A_CENTER + Vector3(5.7, 0.0, 7.4),
		PORT_A_CENTER + Vector3(0.0, 0.0, 14.5),
		PORT_A_CENTER + Vector3(-3.35, 0.0, 9.2),
	]
	for point in port_a_points:
		case_count += 1
		if not _is_presentation_land(point):
			failures.append("Port A forbidden region missing")
	# 6: Port A contact can be escaped by reversing away.
	boat_movement_root.position = PORT_A_CENTER + Vector3(-3.0, 0.0, 3.0)
	boat_heading = -PI / 2.0
	boat_speed = 2.0
	var a_contact := _move_with_land_guard(_heading_forward(), 0.5)
	boat_heading = PI / 2.0
	boat_speed = 2.0
	var a_escape := _move_with_land_guard(_heading_forward(), 0.5)
	case_count += 1
	if a_escape.x <= a_contact.x + 0.001:
		failures.append("Port A escape failed")
	# 7-12: both Port B headlands, back shore, slope, terrace, and dock are guarded.
	var port_b_points := [
		PORT_B_CENTER + Vector3(-6.2, 0.0, 8.5),
		PORT_B_CENTER + Vector3(6.2, 0.0, 8.5),
		PORT_B_CENTER + Vector3(0.0, 0.0, 2.5),
		PORT_B_CENTER + Vector3(0.0, 0.0, -0.8),
		PORT_B_CENTER + Vector3(0.6, 0.0, -3.5),
		PORT_B_CENTER + Vector3(-3.0, 0.0, 7.0),
	]
	for point in port_b_points:
		case_count += 1
		if not _is_presentation_land(point):
			failures.append("Port B forbidden region missing")
	# 13: Backspace returns to safe Port A water.
	_reset_boat_to_port_a()
	case_count += 1
	if _is_presentation_land(boat_movement_root.position) or phase != VoyageState.AT_PORT_A:
		failures.append("reset did not return to safe Port A")
	# 14-17: A -> B is a real route, stops at B, and can depart again.
	_begin_departure_from_current_port()
	var reached_b := _simulate_until_port(VoyageState.AT_PORT_B, 1000)
	case_count += 1
	if not reached_b:
		failures.append("A to B did not arrive")
	case_count += 1
	if phase != VoyageState.AT_PORT_B or boat_speed > 0.001:
		failures.append("Port B did not remain stopped")
	var b_position := boat_movement_root.position
	for _step in range(20):
		_update_navigation(0.1)
	case_count += 1
	if boat_movement_root.position.distance_to(b_position) > 0.001:
		failures.append("idle Port B moved")
	_begin_departure_from_current_port()
	case_count += 1
	if phase != VoyageState.DEPARTING_B:
		failures.append("Port B departure did not start")
	# 18-20: B -> A completes, a second departure starts, and the loop can
	# be repeated without invalid state or duplicated arrival behavior.
	var reached_a := _simulate_until_port(VoyageState.AT_PORT_A, 1000)
	case_count += 1
	if not reached_a:
		failures.append("B to A did not arrive")
	_begin_departure_from_current_port()
	case_count += 1
	if phase != VoyageState.DEPARTING_A:
		failures.append("second Port A departure did not start")
	var reached_b_again := _simulate_until_port(VoyageState.AT_PORT_B, 1000)
	case_count += 1
	if not reached_b_again:
		failures.append("second A to B did not arrive")
	if failures.is_empty():
		print("PORT_TO_PORT_SLICE_03_ABUSE_CHECK=PASS|cases=%d|routes=A-B-A-B" % case_count)
	else:
		for failure in failures:
			push_error(failure)
		print("PORT_TO_PORT_SLICE_03_ABUSE_CHECK=FAIL|cases=%d|failures=%d" % [case_count, failures.size()])
	get_tree().quit()


func _simulate_until_port(expected_state: VoyageState, max_steps: int) -> bool:
	for _step in range(max_steps):
		_update_navigation(0.1)
		if phase == expected_state:
			return true
	return false


func _set_state(new_state: VoyageState) -> void:
	if phase == new_state:
		return
	phase = new_state
	arrival_slow_time = 0.0
	if new_state == VoyageState.AT_PORT_A or new_state == VoyageState.AT_PORT_B:
		boat_speed = 0.0
		actual_velocity = Vector3.ZERO
		autoplay_port_wait = 0.0
		print("PORT_TO_PORT_SLICE_03_STATE=%s" % _state_name(new_state))
	else:
		print("PORT_TO_PORT_SLICE_03_STATE=%s" % _state_name(new_state))


func _state_name(value: VoyageState) -> String:
	return ["AT_PORT_A", "DEPARTING_A", "OPEN_WATER_TO_B", "APPROACHING_B", "ARRIVING_B", "AT_PORT_B", "DEPARTING_B", "OPEN_WATER_TO_A", "APPROACHING_A", "ARRIVING_A"][int(value)]


func _is_at_port() -> bool:
	return phase == VoyageState.AT_PORT_A or phase == VoyageState.AT_PORT_B


func _begin_departure_from_current_port() -> void:
	if phase == VoyageState.AT_PORT_A:
		route_origin = BOAT_START
		route_target = PORT_B_HARBOR
		boat_heading = 0.0
		_set_state(VoyageState.DEPARTING_A)
	elif phase == VoyageState.AT_PORT_B:
		route_origin = PORT_B_HARBOR
		route_target = BOAT_START
		boat_heading = PI
		_set_state(VoyageState.DEPARTING_B)
	else:
		return
	boat_speed = 0.0
	actual_velocity = Vector3.ZERO
	_clear_wake()
	print("PORT_TO_PORT_SLICE_03_DEPART=%s" % _state_name(phase))


func _heading_forward() -> Vector3:
	return Vector3(sin(boat_heading), 0.0, -cos(boat_heading)).normalized()


func _horizontal_distance_to(target: Vector3, position: Vector3) -> float:
	return Vector2(target.x - position.x, target.z - position.z).length()


func _move_with_land_guard(forward: Vector3, delta: float) -> Vector3:
	var start := boat_movement_root.position
	var travel := forward * boat_speed * delta
	var step_count := maxi(1, ceili(travel.length() / 0.25))
	var resolved := start
	var collided := false
	for step in range(1, step_count + 1):
		var candidate := start + travel * (float(step) / float(step_count))
		if _is_presentation_land(candidate):
			collided = true
			break
		resolved = candidate
	if collided:
		# Keep the last safe sub-step. This is a soft stop, not a teleport or
		# rigid-body impulse, so steering can still turn the boat away.
		boat_speed = 0.0
		if not presentation_land_contact:
			print("PORT_TO_PORT_LAND_CONTACT=1")
		presentation_land_contact = true
	else:
		if presentation_land_contact:
			print("PORT_TO_PORT_LAND_CONTACT=0")
		presentation_land_contact = false
	return resolved


func _is_presentation_land(position: Vector3) -> bool:
	# Low-cost presentation collision: a few broad world-space rectangles around
	# obvious land and dock masses. No per-building physics and no formal system
	# coupling are needed for this slice.
	if _inside_xz_rect(position, PORT_A_CENTER + Vector3(-5.7, 0.0, 7.4), Vector2(2.2, 6.5)):
		return true
	if _inside_xz_rect(position, PORT_A_CENTER + Vector3(5.7, 0.0, 7.4), Vector2(2.2, 6.5)):
		return true
	if _inside_xz_rect(position, PORT_A_CENTER + Vector3(0.0, 0.0, 14.5), Vector2(7.7, 2.0)):
		return true
	if _inside_xz_rect(position, PORT_A_CENTER + Vector3(-3.35, 0.0, 9.2), Vector2(0.8, 2.4)):
		return true
	if _inside_xz_rect(position, PORT_B_CENTER + Vector3(-6.2, 0.0, 8.5), Vector2(3.8, 3.5)):
		return true
	if _inside_xz_rect(position, PORT_B_CENTER + Vector3(6.2, 0.0, 8.5), Vector2(3.8, 3.5)):
		return true
	if _inside_xz_rect(position, PORT_B_CENTER + Vector3(0.0, 0.0, 2.5), Vector2(6.0, 1.5)):
		return true
	if _inside_xz_rect(position, PORT_B_CENTER + Vector3(0.0, 0.0, -0.8), Vector2(7.0, 3.0)):
		return true
	if _inside_xz_rect(position, PORT_B_CENTER + Vector3(0.6, 0.0, -3.5), Vector2(4.0, 2.0)):
		return true
	if _inside_xz_rect(position, PORT_B_CENTER + Vector3(-3.0, 0.0, 7.0), Vector2(0.78, 3.25)):
		return true
	return false


func _inside_xz_rect(position: Vector3, center: Vector3, half_extents: Vector2) -> bool:
	return absf(position.x - center.x) <= half_extents.x and absf(position.z - center.z) <= half_extents.y


func reset_camera() -> void:
	# Keep the current camera position and let the approved smoothing return it
	# to the default rear three-quarter sailing view.
	camera_shot_offset = DEFAULT_CAMERA_POSITION
	camera_shot_target_offset = DEFAULT_CAMERA_TARGET
	camera_shot_fov = DEFAULT_CAMERA_FOV
	camera_look_target = 0.0
	camera_look_vertical_target = 0.0


func _rotate_horizontal(value: Vector3, angle: float) -> Vector3:
	return value.rotated(Vector3.UP, angle)


func _rotate_camera_orbit(value: Vector3, yaw: float, pitch: float) -> Vector3:
	var yawed := _rotate_horizontal(value, yaw)
	var right_axis := _rotate_horizontal(Vector3.RIGHT, yaw)
	return yawed.rotated(right_axis, pitch)


func _update_wave_visual() -> void:
	if wave_visual_root == null:
		return
	var sample := Vector2(boat_movement_root.position.x, boat_movement_root.position.z)
	var wave := _calculate_wave(sample, visual_time / WAVE_TIME_FACTOR)
	var normal: Vector3 = wave["normal"]
	var heave_factor := 1.0
	var tilt_factor := 1.0
	if phase in [VoyageState.ARRIVING_A, VoyageState.ARRIVING_B]:
		heave_factor = 0.75
		tilt_factor = 0.58
	elif _is_at_port():
		heave_factor = 0.55
		tilt_factor = 0.35
	normal = Vector3.UP.lerp(normal, tilt_factor).normalized()
	wave_visual_root.position = Vector3(0.0, 0.28 + float(wave["height"]) * heave_factor, 0.0)
	var forward := _heading_forward()
	var projected_forward := (forward - normal * forward.dot(normal)).normalized()
	if projected_forward.length_squared() < 0.0001:
		projected_forward = forward
	var right := projected_forward.cross(normal).normalized()
	wave_visual_root.basis = Basis(right, normal, -projected_forward).orthonormalized()


func _calculate_wave(pos: Vector2, time: float) -> Dictionary:
	var displacement := Vector3.ZERO
	var normal := Vector3(0.0, 1.0, 0.0)
	for index in ACTIVE_WAVE_INDICES:
		var result := _calculate_gerstner_wave(WAVE_PARAMS[index], pos, time)
		displacement += result["displacement"]
		normal += result["normal"]
	return {"height": displacement.y, "normal": normal.normalized()}


func _calculate_gerstner_wave(params: Vector4, pos: Vector2, time: float) -> Dictionary:
	var steepness := params.z * (1.0 + 0.5 * sin(time + pos.length() * 0.1)) * WAVE_AMPLITUDE_SCALE
	var wavelength := params.w * WAVE_LENGTH_SCALE
	var k := TAU / wavelength
	var speed := sqrt(9.81 / k)
	var direction := Vector2(params.x, params.y).normalized()
	var phase_value := k * (direction.dot(pos) - speed * time)
	var amplitude := steepness / k
	var displacement := Vector3(
		direction.x * amplitude * cos(phase_value),
		amplitude * sin(phase_value),
		direction.y * amplitude * cos(phase_value)
	)
	var tangent := Vector3(
		1.0 - direction.x * direction.x * steepness * sin(phase_value),
		steepness * cos(phase_value),
		-direction.x * direction.y * steepness * sin(phase_value)
	)
	var binormal := Vector3(
		-direction.x * direction.y * steepness * sin(phase_value),
		steepness * cos(phase_value),
		1.0 - direction.y * direction.y * steepness * sin(phase_value)
	)
	return {"displacement": displacement, "normal": binormal.cross(tangent).normalized()}


func _update_water_uniforms() -> void:
	if water_material == null:
		return
	water_material.set_shader_parameter("wave_time", visual_time)
	water_material.set_shader_parameter("camera_position_world", camera.global_position if camera != null else Vector3.ZERO)
	water_material.set_shader_parameter("directional_light_direction_world", -sun.global_transform.basis.z)


func _update_camera(delta: float) -> void:
	if camera == null or boat_movement_root == null:
		return
	if delta <= 0.0:
		camera_look_angle = camera_look_target
		camera_look_vertical_angle = camera_look_vertical_target
		camera_follow_heading = boat_heading
		camera_target_initialized = false
	else:
		var look_blend := 1.0 - exp(-CAMERA_LOOK_SMOOTHING * delta)
		camera_look_angle = wrapf(lerp_angle(camera_look_angle, camera_look_target, look_blend), -PI, PI)
		camera_look_vertical_angle = lerpf(camera_look_vertical_angle, camera_look_vertical_target, look_blend)
		camera_follow_heading = wrapf(
			lerp_angle(camera_follow_heading, boat_heading, 1.0 - exp(-CAMERA_HEADING_FOLLOW_SMOOTHING * delta)),
			-PI,
			PI
		)
	var rig_angle := wrapf(camera_follow_heading + camera_look_angle, -PI, PI)
	var desired_position := boat_movement_root.position + _rotate_camera_orbit(camera_shot_offset, rig_angle, camera_look_vertical_angle)
	var desired_target := boat_movement_root.position + _rotate_camera_orbit(camera_shot_target_offset, rig_angle, camera_look_vertical_angle)
	if delta <= 0.0:
		camera.position = desired_position
		camera_target_position = desired_target
		camera_target_initialized = true
	else:
		var follow_blend := 1.0 - exp(-CAMERA_FOLLOW_SMOOTHING * delta)
		camera.position = camera.position.lerp(desired_position, follow_blend)
		if not camera_target_initialized:
			camera_target_position = desired_target
			camera_target_initialized = true
		else:
			camera_target_position = camera_target_position.lerp(desired_target, follow_blend)
	camera.fov = camera_shot_fov
	camera.look_at(camera_target_position, Vector3.UP)


func _reset_boat_to_port_a() -> void:
	if boat_movement_root == null:
		return
	boat_movement_root.position = BOAT_START
	boat_heading = 0.0
	boat_speed = 0.0
	actual_velocity = Vector3.ZERO
	arrival_slow_time = 0.0
	route_origin = BOAT_START
	route_target = PORT_B_HARBOR
	_clear_wake()
	_set_state(VoyageState.AT_PORT_A)
	print("PORT_TO_PORT_SLICE_03_RESET=PORT_A")


func _capture_all() -> void:
	var output_dir := ProjectSettings.globalize_path(CAPTURE_DIR).path_join(visual_preset).path_join("layout_%s" % port_b_layout.to_lower())
	DirAccess.make_dir_recursive_absolute(output_dir)
	var shots := [
		{"position": BOAT_START, "state": VoyageState.AT_PORT_A, "yaw": 0.0, "wake": 0.0, "file": "01_idle_port_a.png"},
		{"position": Vector3(0.0, 0.0, 2.5), "state": VoyageState.DEPARTING_A, "yaw": 0.0, "wake": 0.85, "file": "02_depart_port_a.png"},
		{"position": Vector3(0.0, 0.0, -18.0), "state": VoyageState.OPEN_WATER_TO_B, "yaw": PI, "wake": 0.82, "file": "03_port_a_receding.png"},
		{"position": Vector3(0.0, 0.0, -48.0), "state": VoyageState.OPEN_WATER_TO_B, "yaw": 0.0, "wake": 0.78, "file": "04_open_water_to_b.png"},
		{"position": Vector3(0.0, 0.0, -78.0), "state": VoyageState.OPEN_WATER_TO_B, "yaw": 0.0, "wake": 0.74, "file": "05_port_b_distant.png"},
		{"position": Vector3(0.0, 0.0, -105.0), "state": VoyageState.APPROACHING_B, "yaw": 0.0, "wake": 0.62, "file": "06_port_b_approach.png"},
		{"position": Vector3(0.0, 0.0, -116.5), "state": VoyageState.ARRIVING_B, "yaw": 0.0, "wake": 0.34, "file": "07_harbor_entry_b.png"},
		{"position": Vector3(0.0, 0.0, -119.6), "state": VoyageState.AT_PORT_B, "yaw": 0.0, "wake": 0.0, "file": "08_idle_port_b.png"},
		{"position": Vector3(0.0, 0.0, -116.0), "state": VoyageState.DEPARTING_B, "yaw": 0.0, "wake": 0.84, "file": "09_depart_port_b.png"},
		{"position": Vector3(0.0, 0.0, -80.0), "state": VoyageState.OPEN_WATER_TO_A, "yaw": 0.0, "wake": 0.76, "file": "10_open_water_to_a.png"},
		{"position": Vector3(0.0, 0.0, -20.0), "state": VoyageState.APPROACHING_A, "yaw": 0.0, "wake": 0.58, "file": "11_port_a_approach.png"},
		{"position": BOAT_START, "state": VoyageState.AT_PORT_A, "yaw": 0.0, "wake": 0.0, "file": "12_returned_port_a.png"},
		{"position": Vector3(0.0, 0.0, -64.0), "state": VoyageState.OPEN_WATER_TO_B, "yaw": 0.0, "wake": 0.0, "overview": true, "file": "13_world_overview.png"},
	]
	for shot in shots:
		boat_movement_root.position = shot["position"]
		var shot_state: VoyageState = shot["state"]
		phase = shot_state
		if shot_state in [VoyageState.DEPARTING_B, VoyageState.OPEN_WATER_TO_A, VoyageState.APPROACHING_A, VoyageState.ARRIVING_A]:
			boat_heading = PI
			route_origin = PORT_B_HARBOR
			route_target = BOAT_START
		else:
			boat_heading = 0.0
			route_origin = BOAT_START
			route_target = PORT_B_HARBOR
		boat_speed = 0.0 if _is_at_port() else NORMAL_SPEED
		actual_velocity = _heading_forward() * boat_speed
		camera_look_target = float(shot["yaw"])
		camera_look_angle = camera_look_target
		camera_look_vertical_target = 0.0
		camera_look_vertical_angle = 0.0
		camera_follow_heading = boat_heading
		camera_target_initialized = false
		if shot.get("overview", false):
			camera_shot_offset = Vector3(-80.0, 80.0, 0.0)
			camera_shot_target_offset = Vector3.ZERO
			camera_shot_fov = 48.0
		else:
			camera_shot_offset = DEFAULT_CAMERA_POSITION
			camera_shot_target_offset = DEFAULT_CAMERA_TARGET
			camera_shot_fov = DEFAULT_CAMERA_FOV
		for _frame in range(30):
			visual_time += 1.0 / 60.0
			_update_wave_visual()
			_update_camera(1.0 / 60.0)
			_update_water_uniforms()
			await get_tree().process_frame
		if float(shot["wake"]) > 0.0:
			_seed_wake_for_capture(float(shot["wake"]))
		else:
			_clear_wake()
		await get_tree().process_frame
		var image := get_viewport().get_texture().get_image()
		var path := output_dir.path_join(String(shot["file"]))
		var error := image.save_png(path)
		if error != OK:
			push_error("Cannot save PortToPortSlice03 screenshot: " + path)
		else:
			print("PORT_TO_PORT_SLICE_03_SCREENSHOT=" + path)
	var draw_calls := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitives := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("PORT_TO_PORT_SLICE_03_RENDER_INFO|draw_calls=%s|primitives=%s|gpu_ms_unavailable_in_runtime=true" % [str(draw_calls), str(primitives)])
	get_tree().quit()


func _add_block(parent: Node3D, name: String, size: Vector3, position: Vector3, rotation_degrees: Vector3, color: Color) -> MeshInstance3D:
	var block := MeshInstance3D.new()
	block.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	block.mesh = mesh
	block.position = position
	block.rotation_degrees = rotation_degrees
	block.material_override = _make_unshaded_material(color)
	parent.add_child(block)
	return block


func _add_slope_mass(parent: Node3D, name: String, size: Vector3, position: Vector3, front_top: float, back_top: float, color: Color) -> MeshInstance3D:
	var slope := MeshInstance3D.new()
	slope.name = name
	var half_width := size.x * 0.5
	var half_depth := size.z * 0.5
	# Chamfer the plan corners so the blockout reads as a low-cost shoreline
	# mass instead of a set of unmodified rectangular walls. The top ring keeps
	# the existing front/back slope, while the footprint remains inexpensive.
	var chamfer := minf(0.55, minf(half_width * 0.35, half_depth * 0.35))
	var footprint := [
		Vector2(-half_width + chamfer, -half_depth), Vector2(half_width - chamfer, -half_depth),
		Vector2(half_width, -half_depth + chamfer), Vector2(half_width, half_depth - chamfer),
		Vector2(half_width - chamfer, half_depth), Vector2(-half_width + chamfer, half_depth),
		Vector2(-half_width, half_depth - chamfer), Vector2(-half_width, -half_depth + chamfer),
	]
	var vertices := PackedVector3Array()
	for point in footprint:
		vertices.append(Vector3(point.x, 0.0, point.y))
	for point in footprint:
		var slope_t := clampf((point.y + half_depth) / maxf(size.z, 0.001), 0.0, 1.0)
		vertices.append(Vector3(point.x, lerpf(back_top, front_top, slope_t), point.y))
	var indices := PackedInt32Array()
	# Bottom and top caps.
	for index in range(1, 7):
		indices.append(0)
		indices.append(index + 1)
		indices.append(index)
		indices.append(8)
		indices.append(8 + index)
		indices.append(8 + index + 1)
	# Eight chamfered side faces.
	for index in range(8):
		var next := (index + 1) % 8
		indices.append(index)
		indices.append(next)
		indices.append(8 + next)
		indices.append(index)
		indices.append(8 + next)
		indices.append(8 + index)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	slope.mesh = array_mesh
	slope.position = position
	slope.material_override = _make_unshaded_material(color)
	parent.add_child(slope)
	return slope


func _add_house(parent: Node3D, name: String, position: Vector3, body_size: Vector3, rotation_x: float) -> void:
	var root := Node3D.new()
	root.name = name
	root.position = position
	root.rotation_degrees.x = rotation_x
	parent.add_child(root)
	_add_block(root, "Body", body_size, Vector3.ZERO, Vector3.ZERO, Color(0.75, 0.61, 0.43, 1.0))
	var roof := MeshInstance3D.new()
	roof.name = "PitchedRoof"
	var roof_mesh := CylinderMesh.new()
	roof_mesh.top_radius = 0.0
	roof_mesh.bottom_radius = 0.52
	roof_mesh.height = 0.38
	roof_mesh.radial_segments = 4
	roof.mesh = roof_mesh
	roof.position.y = body_size.y * 0.5 + 0.20
	roof.scale = Vector3(body_size.x / 1.15, 1.0, body_size.z / 0.90)
	roof.material_override = _make_unshaded_material(Color(0.46, 0.19, 0.12, 1.0))
	root.add_child(roof)


func _add_cylinder(parent: Node3D, name: String, radius: float, height: float, position: Vector3, color: Color, segments: int) -> void:
	var cylinder := MeshInstance3D.new()
	cylinder.name = name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	cylinder.mesh = mesh
	cylinder.position = position
	cylinder.material_override = _make_unshaded_material(color)
	parent.add_child(cylinder)


func _add_quad_indices(indices: PackedInt32Array, a: int, b: int, c: int, d: int) -> void:
	indices.append(a)
	indices.append(b)
	indices.append(c)
	indices.append(a)
	indices.append(c)
	indices.append(d)


func _make_unshaded_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
