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
const DOCK_DISTANCE_THRESHOLD := 70.0
const DOCK_MAX_SPEED := 12.0
const DOCK_MIN_ALIGNMENT := 0.92
const DOCK_IDS := ["cove", "island", "port"]
const DOCK_DEFINITIONS := {
	"cove": {
		"id": "cove",
		"name": "DAMAGED COVE DOCK",
		"approach_position": Vector2(1070.0, 760.0),
		"approach_heading": Vector2.UP,
		"snap_position": Vector2(1070.0, 510.0),
		"snap_rotation": PI,
		"shore_position": Vector2(894.0, 486.0),
		"shore_region": {
			"kind": "COVE_COLLISION",
			"center": Vector2.ZERO,
		},
	},
	"island": {
		"id": "island",
		"name": "TEST ISLAND DOCK",
		"approach_position": Vector2(1550.0, 1575.0),
		"approach_heading": Vector2.UP,
		"snap_position": Vector2(1550.0, 1575.0),
		"snap_rotation": PI,
		"shore_position": Vector2(1550.0, 1400.0),
		"shore_region": {
			"kind": "CIRCLE",
			"center": Vector2(1550.0, 1250.0),
			"radius": 150.0,
		},
	},
	"port": {
		"id": "port",
		"name": "TEST PORT DOCK",
		"approach_position": Vector2(2630.0, 785.0),
		"approach_heading": Vector2.UP,
		"snap_position": Vector2(2630.0, 785.0),
		"snap_rotation": PI,
		"shore_position": Vector2(2630.0, 630.0),
		"shore_region": {
			"kind": "RECTANGLE",
			"rect": Rect2(2420.0, 380.0, 420.0, 250.0),
		},
	},
}

var current_speed := 0.0
var sailing_velocity := Vector2.ZERO
var controls_enabled := false
var captain_aboard := false
var has_departed_dock := false
var at_damaged_dock := true
var is_docked := false
var current_dock_id := ""
var last_dock_id := ""
var last_collision_response := "NONE"
var navigation_input_blocked := false
var navigation_release_pending := false
var timber_lots := 0

var _sea_bounds := Rect2()
var _island_center := Vector2.ZERO
var _island_radius := 0.0
var _port_land_rect := Rect2()
var _cove_shoreline := PackedVector2Array()
var _dock_exit_cleared := false
var _departure_input_armed := false
var _restore_controls_after_navigation_release := false


func _ready() -> void:
	queue_redraw()


func configure_sailing_area(
		sea_bounds: Rect2,
		island_center: Vector2,
		island_radius: float,
		port_land_rect: Rect2,
		cove_shoreline: PackedVector2Array,
) -> void:
	_sea_bounds = sea_bounds
	_island_center = island_center
	_island_radius = island_radius
	_port_land_rect = port_land_rect
	_cove_shoreline = cove_shoreline


func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = (
		enabled
		and not is_docked
		and not navigation_input_blocked
		and not navigation_release_pending
	)
	if not controls_enabled:
		current_speed = 0.0
		sailing_velocity = Vector2.ZERO


func set_navigation_input_blocked(
	blocked: bool,
	restore_controls_after_release := false,
) -> void:
	navigation_input_blocked = blocked
	navigation_release_pending = not blocked
	_restore_controls_after_navigation_release = (
		restore_controls_after_release and not is_docked
	)
	controls_enabled = false
	current_speed = 0.0
	sailing_velocity = Vector2.ZERO
	# A chart transition must always require a fresh dock-departure press.
	_departure_input_armed = false


func set_captain_aboard(aboard: bool) -> void:
	captain_aboard = aboard
	if not captain_aboard:
		_departure_input_armed = false
		set_controls_enabled(false)


func can_leave_at_damaged_dock() -> bool:
	return (
		controls_enabled
		and captain_aboard
		and at_damaged_dock
		and not is_docked
		and not has_departed_dock
		and is_zero_approx(current_speed)
	)


func is_at_cove_entrance() -> bool:
	return global_position.distance_to(COVE_ENTRANCE_POSITION) <= COVE_ENTRANCE_RADIUS


func get_forward_direction() -> Vector2:
	return Vector2.UP.rotated(rotation)


func can_accept_salvaged_timber_lot() -> bool:
	return timber_lots == 0


func add_salvaged_timber_lot() -> bool:
	if not can_accept_salvaged_timber_lot():
		return false
	timber_lots = 1
	queue_redraw()
	return true


func get_available_dock_id() -> String:
	for dock_id in DOCK_IDS:
		var metrics := get_dock_eligibility(dock_id)
		if metrics["eligible"]:
			return dock_id
	return ""


func get_dock_eligibility(dock_id: String) -> Dictionary:
	if not DOCK_DEFINITIONS.has(dock_id):
		return {}

	var definition: Dictionary = DOCK_DEFINITIONS[dock_id]
	var approach_position: Vector2 = definition["approach_position"]
	var approach_heading: Vector2 = definition["approach_heading"]
	var distance := global_position.distance_to(approach_position)
	var speed := absf(current_speed)
	var alignment := get_forward_direction().dot(approach_heading.normalized())
	var close_enough := distance <= DOCK_DISTANCE_THRESHOLD
	var slow_enough := speed <= DOCK_MAX_SPEED
	var aligned := alignment >= DOCK_MIN_ALIGNMENT
	var operating := controls_enabled and captain_aboard and not is_docked
	var rejection_reasons := PackedStringArray()
	if not operating:
		rejection_reasons.append("SHIP_NOT_UNDER_SAILING_CONTROL")
	if not close_enough:
		rejection_reasons.append("TOO_FAR")
	if not slow_enough:
		rejection_reasons.append("TOO_FAST")
	if not aligned:
		rejection_reasons.append("WRONG_HEADING")

	return {
		"dock_id": dock_id,
		"dock_name": definition["name"],
		"distance": distance,
		"speed": speed,
		"alignment": alignment,
		"heading_error_degrees": rad_to_deg(acos(clampf(alignment, -1.0, 1.0))),
		"distance_threshold": DOCK_DISTANCE_THRESHOLD,
		"max_speed": DOCK_MAX_SPEED,
		"min_alignment": DOCK_MIN_ALIGNMENT,
		"close_enough": close_enough,
		"slow_enough": slow_enough,
		"aligned": aligned,
		"operating": operating,
		"eligible": operating and close_enough and slow_enough and aligned,
		"rejection_reasons": rejection_reasons,
	}


func dock_at_available() -> String:
	var dock_id := get_available_dock_id()
	if dock_id.is_empty():
		return ""

	var definition: Dictionary = DOCK_DEFINITIONS[dock_id]
	global_position = definition["snap_position"]
	rotation = definition["snap_rotation"]
	current_speed = 0.0
	sailing_velocity = Vector2.ZERO
	controls_enabled = false
	is_docked = true
	current_dock_id = dock_id
	last_dock_id = dock_id
	at_damaged_dock = dock_id == "cove"
	_dock_exit_cleared = dock_id != "cove"
	_departure_input_armed = false
	last_collision_response = "DOCKED_%s" % dock_id.to_upper()
	queue_redraw()
	return dock_id


func get_current_dock_definition() -> Dictionary:
	if current_dock_id.is_empty() or not DOCK_DEFINITIONS.has(current_dock_id):
		return {}
	return (DOCK_DEFINITIONS[current_dock_id] as Dictionary).duplicate(true)


func get_dock_definition(dock_id: String) -> Dictionary:
	if not DOCK_DEFINITIONS.has(dock_id):
		return {}
	return (DOCK_DEFINITIONS[dock_id] as Dictionary).duplicate(true)


func get_dock_definitions() -> Array:
	var definitions := []
	for dock_id in DOCK_IDS:
		definitions.append((DOCK_DEFINITIONS[dock_id] as Dictionary).duplicate(true))
	return definitions


func _release_current_dock() -> void:
	if not is_docked or not captain_aboard:
		return

	var departing_dock_id := current_dock_id
	is_docked = false
	current_dock_id = ""
	controls_enabled = true
	current_speed = 0.0
	sailing_velocity = Vector2.ZERO
	if departing_dock_id == "cove":
		at_damaged_dock = true
		_dock_exit_cleared = false
	else:
		at_damaged_dock = false
		_dock_exit_cleared = true
	last_collision_response = "RELEASED_%s" % departing_dock_id.to_upper()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if navigation_input_blocked:
		current_speed = 0.0
		sailing_velocity = Vector2.ZERO
		controls_enabled = false
		_departure_input_armed = false
		return

	if navigation_release_pending:
		current_speed = 0.0
		sailing_velocity = Vector2.ZERO
		controls_enabled = false
		_departure_input_armed = false
		if not _is_any_movement_key_pressed():
			navigation_release_pending = false
			controls_enabled = (
				_restore_controls_after_navigation_release
				and captain_aboard
				and not is_docked
			)
		return

	var throttle_pressed := (
		Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	)
	if is_docked:
		current_speed = 0.0
		sailing_velocity = Vector2.ZERO
		if captain_aboard:
			if not throttle_pressed:
				_departure_input_armed = true
			elif _departure_input_armed:
				_departure_input_armed = false
				_release_current_dock()
		return

	if not controls_enabled:
		return

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


func _is_any_movement_key_pressed() -> bool:
	return (
		Input.is_key_pressed(KEY_W)
		or Input.is_key_pressed(KEY_A)
		or Input.is_key_pressed(KEY_S)
		or Input.is_key_pressed(KEY_D)
		or Input.is_key_pressed(KEY_UP)
		or Input.is_key_pressed(KEY_LEFT)
		or Input.is_key_pressed(KEY_DOWN)
		or Input.is_key_pressed(KEY_RIGHT)
	)


func _move_with_sailing_limits(delta: float) -> void:
	if sailing_velocity.is_zero_approx() or _sea_bounds.size.is_zero_approx():
		return

	var proposed_position := global_position + sailing_velocity * delta
	var minimum := _sea_bounds.position + Vector2.ONE * HULL_CLEARANCE
	var maximum := _sea_bounds.end - Vector2.ONE * HULL_CLEARANCE
	var bounded_position := proposed_position.clamp(minimum, maximum)
	if not bounded_position.is_equal_approx(proposed_position):
		global_position = bounded_position
		_stop_at_land("SEA_EDGE_STOP")
		return

	var island_clearance := _island_radius + HULL_CLEARANCE
	var island_offset := proposed_position - _island_center
	if island_offset.length() < island_clearance:
		var safe_direction := island_offset.normalized()
		if safe_direction.is_zero_approx():
			safe_direction = -get_forward_direction()
		global_position = _island_center + safe_direction * island_clearance
		_stop_at_land("ISLAND_STOP")
		return

	if _collides_with_port_land(proposed_position):
		_stop_at_land("PORT_STOP")
		return

	if (
		_collides_with_cove_shore(proposed_position)
		and not _is_in_damaged_dock_exit(proposed_position)
	):
		_stop_at_land("COVE_SHORE_STOP")
		return

	global_position = proposed_position
	_update_dock_exit_state()
	last_collision_response = "NONE"


func _stop_at_land(response: String) -> void:
	current_speed = 0.0
	sailing_velocity = Vector2.ZERO
	last_collision_response = response


func _update_dock_exit_state() -> void:
	var outward_separation := global_position.y - DOCK_POSITION.y
	if at_damaged_dock and outward_separation > DOCK_DEPARTURE_DISTANCE:
		has_departed_dock = true
		at_damaged_dock = false
		queue_redraw()

	if not _dock_exit_cleared and global_position.y >= DOCK_EXIT_CLEAR_Y:
		_dock_exit_cleared = true


func _is_in_damaged_dock_exit(proposed_position: Vector2) -> bool:
	return (
		not _dock_exit_cleared
		and absf(proposed_position.x - DOCK_POSITION.x) <= DOCK_EXIT_HALF_WIDTH
		and proposed_position.y >= DOCK_POSITION.y
		and proposed_position.y <= DOCK_EXIT_CLEAR_Y + HULL_CLEARANCE
	)


func _collides_with_port_land(proposed_position: Vector2) -> bool:
	if not _port_land_rect.has_area():
		return false
	var closest_point := proposed_position.clamp(
		_port_land_rect.position,
		_port_land_rect.end,
	)
	return (
		_port_land_rect.has_point(proposed_position)
		or proposed_position.distance_to(closest_point) < HULL_CLEARANCE
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
	var eligibility := {}
	for dock_id in DOCK_IDS:
		eligibility[dock_id] = get_dock_eligibility(dock_id)
	var current_definition := get_current_dock_definition()
	var fixed_pose := false
	if not current_definition.is_empty():
		fixed_pose = (
			global_position.is_equal_approx(current_definition["snap_position"])
			and is_equal_approx(rotation, float(current_definition["snap_rotation"]))
			and is_zero_approx(current_speed)
			and sailing_velocity.is_zero_approx()
		)

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
		"captain_aboard": captain_aboard,
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
		"port_land_rect": _port_land_rect,
		"cove_shoreline": _cove_shoreline,
		"collision_radius": HULL_CLEARANCE,
		"hull_clearance": HULL_CLEARANCE,
		"last_collision_response": last_collision_response,
		"dock_count": DOCK_IDS.size(),
		"dock_ids": DOCK_IDS.duplicate(),
		"dock_names": [
			DOCK_DEFINITIONS["cove"]["name"],
			DOCK_DEFINITIONS["island"]["name"],
			DOCK_DEFINITIONS["port"]["name"],
		],
		"dock_definitions": get_dock_definitions(),
		"dock_thresholds": {
			"distance": DOCK_DISTANCE_THRESHOLD,
			"max_speed": DOCK_MAX_SPEED,
			"min_alignment": DOCK_MIN_ALIGNMENT,
		},
		"dock_eligibility": eligibility,
		"available_dock_id": get_available_dock_id(),
		"is_docked": is_docked,
		"current_dock_id": current_dock_id,
		"last_dock_id": last_dock_id,
		"fixed_dock_pose": fixed_pose,
		"departure_input_armed": _departure_input_armed,
		"navigation_input_blocked": navigation_input_blocked,
		"navigation_release_pending": navigation_release_pending,
		"timber_lots": timber_lots,
		"has_salvaged_timber": timber_lots == 1,
		"restore_controls_after_navigation_release": (
			_restore_controls_after_navigation_release
		),
		"controls": {
			"forward": "W_OR_UP",
			"turn_left": "A_OR_LEFT",
			"turn_right": "D_OR_RIGHT",
			"brake": "S_OR_DOWN",
			"dock_or_ashore": "E",
			"salvage": "E",
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
	if timber_lots == 1:
		# One fixed timber stack shows the one collected lot on the deck.
		for timber_y in [-1.0, 8.0, 27.0, 36.0]:
			draw_line(
				Vector2(-25.0, timber_y),
				Vector2(25.0, timber_y),
				Color("#d69b5d"),
				7.0,
			)

	# The gangplank is visible when the ship is at the damaged cove dock.
	if at_damaged_dock:
		draw_line(Vector2(176, 24), Vector2(39, 24), Color("#493323"), 18.0)
		draw_line(Vector2(176, 24), Vector2(39, 24), Color("#b27a47"), 11.0)
