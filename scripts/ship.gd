extends Node2D

const ACCELERATION := 140.0
const COAST_DECELERATION := 90.0
const BRAKE_DECELERATION := 260.0
const TOP_SPEED := 280.0
const TURN_SPEED := PI / 2.0
const HULL_CLEARANCE := 105.0
const DOCK_POSITION := Vector2(1070.0, 510.0)
const DOCK_ROTATION := PI
const DOCK_DEPARTURE_DISTANCE := 0.01
const DOCK_EXIT_CLEAR_Y := 655.0
const DOCK_EXIT_HALF_WIDTH := 45.0
const COVE_ENTRANCE_POSITION := Vector2(1070.0, 760.0)
const COVE_ENTRANCE_RADIUS := 110.0

var current_speed := 0.0
var sailing_velocity := Vector2.ZERO
var controls_enabled := false
var has_departed_dock := false
var at_damaged_dock := true
var last_collision_response := "NONE"

var _sea_bounds := Rect2()
var _island_center := Vector2.ZERO
var _island_radius := 0.0
var _cove_shoreline := PackedVector2Array()
var _dock_exit_cleared := false


func _ready() -> void:
	queue_redraw()


func configure_sailing_area(
		sea_bounds: Rect2,
		island_center: Vector2,
		island_radius: float,
		cove_shoreline: PackedVector2Array,
) -> void:
	_sea_bounds = sea_bounds
	_island_center = island_center
	_island_radius = island_radius
	_cove_shoreline = cove_shoreline


func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	if not controls_enabled:
		current_speed = 0.0
		sailing_velocity = Vector2.ZERO


func can_leave_at_damaged_dock() -> bool:
	return (
		controls_enabled
		and at_damaged_dock
		and not has_departed_dock
		and is_zero_approx(current_speed)
	)


func is_at_cove_entrance() -> bool:
	return global_position.distance_to(COVE_ENTRANCE_POSITION) <= COVE_ENTRANCE_RADIUS


func get_forward_direction() -> Vector2:
	return Vector2.UP.rotated(rotation)


func _physics_process(delta: float) -> void:
	if not controls_enabled:
		return

	var throttle_pressed := (
		Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	)
	var brake_pressed := (
		Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	)
	var turn_input := float(
		Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
	) - float(
		Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
	)

	if _dock_exit_cleared:
		rotation = wrapf(rotation + turn_input * TURN_SPEED * delta, -PI, PI)
	else:
		# The ship must first move straight out of the damaged dock corridor.
		rotation = DOCK_ROTATION

	if throttle_pressed:
		current_speed = move_toward(current_speed, TOP_SPEED, ACCELERATION * delta)
	elif brake_pressed:
		current_speed = move_toward(current_speed, 0.0, BRAKE_DECELERATION * delta)
	else:
		current_speed = move_toward(current_speed, 0.0, COAST_DECELERATION * delta)

	sailing_velocity = get_forward_direction() * current_speed
	_move_with_sailing_limits(delta)


func _move_with_sailing_limits(delta: float) -> void:
	if sailing_velocity.is_zero_approx() or _sea_bounds.size.is_zero_approx():
		return

	var proposed_position := global_position + sailing_velocity * delta
	var minimum := _sea_bounds.position + Vector2.ONE * HULL_CLEARANCE
	var maximum := _sea_bounds.end - Vector2.ONE * HULL_CLEARANCE
	var bounded_position := proposed_position.clamp(minimum, maximum)
	if not bounded_position.is_equal_approx(proposed_position):
		global_position = bounded_position
		current_speed = 0.0
		sailing_velocity = Vector2.ZERO
		last_collision_response = "SEA_EDGE_STOP"
		return

	var island_clearance := _island_radius + HULL_CLEARANCE
	var island_offset := proposed_position - _island_center
	if island_offset.length() < island_clearance:
		var safe_direction := island_offset.normalized()
		if safe_direction.is_zero_approx():
			safe_direction = -get_forward_direction()
		global_position = _island_center + safe_direction * island_clearance
		current_speed = 0.0
		sailing_velocity = Vector2.ZERO
		last_collision_response = "ISLAND_STOP"
		return

	if (
		_collides_with_cove_shore(proposed_position)
		and not _is_in_initial_dock_exit(proposed_position)
	):
		current_speed = 0.0
		sailing_velocity = Vector2.ZERO
		last_collision_response = "COVE_SHORE_STOP"
		return

	global_position = proposed_position
	_update_dock_exit_state()
	last_collision_response = "NONE"


func _update_dock_exit_state() -> void:
	var outward_separation := global_position.y - DOCK_POSITION.y
	if not has_departed_dock and outward_separation > DOCK_DEPARTURE_DISTANCE:
		has_departed_dock = true
		at_damaged_dock = false
		queue_redraw()

	if not _dock_exit_cleared and global_position.y >= DOCK_EXIT_CLEAR_Y:
		_dock_exit_cleared = true


func _is_in_initial_dock_exit(proposed_position: Vector2) -> bool:
	return (
		not _dock_exit_cleared
		and absf(proposed_position.x - DOCK_POSITION.x) <= DOCK_EXIT_HALF_WIDTH
		and proposed_position.y >= DOCK_POSITION.y
		and proposed_position.y <= DOCK_EXIT_CLEAR_Y + HULL_CLEARANCE
	)


func _collides_with_cove_shore(proposed_position: Vector2) -> bool:
	if _cove_shoreline.size() < 3:
		return false
	if Geometry2D.is_point_in_polygon(proposed_position, _cove_shoreline):
		return true

	for index in range(_cove_shoreline.size()):
		var segment_start := _cove_shoreline[index]
		var segment_end := _cove_shoreline[(index + 1) % _cove_shoreline.size()]
		var closest_point := Geometry2D.get_closest_point_to_segment(
			proposed_position,
			segment_start,
			segment_end,
		)
		if proposed_position.distance_to(closest_point) < HULL_CLEARANCE:
			return true

	return false


func get_playtest_state() -> Dictionary:
	return {
		"position": global_position,
		"rotation_radians": rotation,
		"rotation_degrees": rad_to_deg(rotation),
		"heading": get_forward_direction(),
		"current_speed": current_speed,
		"velocity": sailing_velocity,
		"acceleration": ACCELERATION,
		"coast_deceleration": COAST_DECELERATION,
		"brake_deceleration": BRAKE_DECELERATION,
		"top_speed": TOP_SPEED,
		"turn_speed": TURN_SPEED,
		"controls_enabled": controls_enabled,
		"has_departed_dock": has_departed_dock,
		"at_damaged_dock": at_damaged_dock,
		"leave_allowed": can_leave_at_damaged_dock(),
		"steering_locked": not _dock_exit_cleared,
		"dock_exit_cleared": _dock_exit_cleared,
		"dock_exit_progress": maxf(0.0, global_position.y - DOCK_POSITION.y),
		"dock_exit_clear_y": DOCK_EXIT_CLEAR_Y,
		"at_cove_entrance": is_at_cove_entrance(),
		"damaged_dock_position": DOCK_POSITION,
		"cove_entrance_position": COVE_ENTRANCE_POSITION,
		"cove_entrance_radius": COVE_ENTRANCE_RADIUS,
		"sea_bounds": _sea_bounds,
		"island_center": _island_center,
		"island_radius": _island_radius,
		"cove_shoreline": _cove_shoreline,
		"collision_radius": HULL_CLEARANCE,
		"hull_clearance": HULL_CLEARANCE,
		"last_collision_response": last_collision_response,
		"controls": {
			"forward": "W_OR_UP",
			"turn_left": "A_OR_LEFT",
			"turn_right": "D_OR_RIGHT",
			"brake": "S_OR_DOWN",
		},
	}


func _draw() -> void:
	# The one ship, viewed from above.
	draw_ellipse(Vector2(5, 8), 48.0, 99.0, Color("#12323c66"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-31, -86), Vector2(31, -86), Vector2(47, 35),
		Vector2(0, 94), Vector2(-47, 35),
	]), Color("#493323"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-23, -72), Vector2(23, -72), Vector2(34, 31),
		Vector2(0, 77), Vector2(-34, 31),
	]), Color("#b27a47"))

	# Deck details make the ship direction and standing position clear.
	draw_line(Vector2(-25, -38), Vector2(25, -38), Color("#6b452c"), 5.0)
	draw_line(Vector2(-30, 18), Vector2(30, 18), Color("#6b452c"), 5.0)
	draw_circle(Vector2(0, -12), 8.0, Color("#342b29"))
	draw_line(Vector2(0, -12), Vector2(18, -47), Color("#e8d2a2"), 4.0)

	# The gangplank is visible only before the ship leaves the damaged dock.
	if at_damaged_dock:
		draw_line(Vector2(176, 24), Vector2(39, 24), Color("#493323"), 18.0)
		draw_line(Vector2(176, 24), Vector2(39, 24), Color("#b27a47"), 11.0)
