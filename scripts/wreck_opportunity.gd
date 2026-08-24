class_name WreckOpportunity
extends Node2D

const WRECK_ID := "off_route_wreck"
const EARLY_VISIBILITY_RANGE := 1050.0
const NEAR_MARKER_RANGE := 260.0
const REACHED_RANGE := 150.0
const SALVAGE_RANGE := 150.0
const SALVAGE_MAX_SPEED := 12.0
const ROUTE_ACQUIRE_RANGE := 150.0
const ROUTE_DEPARTURE_RANGE := 225.0
const RETURN_PROGRESS_DISTANCE := 50.0
const SAILING_VIEWPORT_SIZE := Vector2(1152.0, 648.0)
const WRECK_VISUAL_LOCAL_BOUNDS := Rect2(-100.0, -248.0, 212.0, 304.0)
const INITIAL_SALVAGE_LOTS := [
	"TIMBER LOT",
	"SAILCLOTH LOT",
	"BRASS FITTINGS LOT",
	"HERBAL SUPPLIES LOT",
]

var _route_start := Vector2.ZERO
var _route_end := Vector2.ZERO
var _ship_position := Vector2.ZERO
var _ship_heading := Vector2.ZERO
var _ship_speed := 0.0
var _ship_distance := INF
var _ship_route_offset := INF
var _ship_route_progress := 0.0
var _wreck_route_offset := 0.0
var _wreck_route_progress := 0.0
var _port_distance := INF
var _player_aboard_ship := false
var _captain_aboard := false
var _ship_has_departed := false
var _selected_waypoint_id := ""
var _sailing_view_active := false
var _chart_closed := true
var _sailing_viewport_world_rect := Rect2()
var _wreck_visual_world_rect := Rect2()
var _early_visible := false
var _wreck_visual_on_screen := false
var _near_marker_visible := false
var _started_toward_port := false
var _direct_route_acquired := false
var _seen_before_passing := false
var _sailing_toward_wreck := false
var _left_direct_route := false
var _reached := false
var _reached_after_course_change := false
var _distance_to_port_at_reach := INF
var _returning_to_port := false
var _wreck_empty := false
var _salvage_eligible := false
var _salvage_lots: Array[String] = [
	"TIMBER LOT",
	"SAILCLOTH LOT",
	"BRASS FITTINGS LOT",
	"HERBAL SUPPLIES LOT",
]
var _successful_collection_count := 0
var _last_salvage_result := "NOT_ATTEMPTED"
var _repeat_salvage_result := "NOT_ATTEMPTED"


func _ready() -> void:
	hide()
	queue_redraw()


func configure_route(route_start: Vector2, route_end: Vector2) -> void:
	_route_start = route_start
	_route_end = route_end
	var wreck_route_metrics := _get_route_metrics(global_position)
	_wreck_route_offset = wreck_route_metrics["offset"]
	_wreck_route_progress = wreck_route_metrics["progress"]


func update_state(
	ship_position: Vector2,
	ship_heading: Vector2,
	ship_speed: float,
	player_aboard_ship: bool,
	captain_aboard: bool,
	ship_has_departed: bool,
	selected_waypoint_id: String,
	sailing_view_active: bool,
	chart_closed: bool,
) -> void:
	_ship_position = ship_position
	_ship_heading = ship_heading.normalized()
	_ship_speed = ship_speed
	_player_aboard_ship = player_aboard_ship
	_captain_aboard = captain_aboard
	_ship_has_departed = ship_has_departed
	_selected_waypoint_id = selected_waypoint_id
	_sailing_view_active = sailing_view_active
	_chart_closed = chart_closed
	_ship_distance = _ship_position.distance_to(global_position)
	_port_distance = _ship_position.distance_to(_route_end)
	_sailing_viewport_world_rect = Rect2(
		_ship_position - SAILING_VIEWPORT_SIZE * 0.5,
		SAILING_VIEWPORT_SIZE,
	)
	_wreck_visual_world_rect = Rect2(
		global_position + WRECK_VISUAL_LOCAL_BOUNDS.position,
		WRECK_VISUAL_LOCAL_BOUNDS.size,
	)

	var ship_route_metrics := _get_route_metrics(_ship_position)
	_ship_route_offset = ship_route_metrics["offset"]
	_ship_route_progress = ship_route_metrics["progress"]

	var was_early_visible := _early_visible
	var was_near_marker_visible := _near_marker_visible
	_early_visible = (
		_player_aboard_ship and _ship_distance <= EARLY_VISIBILITY_RANGE
	)
	_near_marker_visible = (
		_early_visible and _ship_distance <= NEAR_MARKER_RANGE
	)
	_salvage_eligible = (
		_captain_aboard
		and _ship_distance <= SALVAGE_RANGE
		and absf(_ship_speed) <= SALVAGE_MAX_SPEED
		and not _wreck_empty
		and _chart_closed
	)
	_wreck_visual_on_screen = (
		_sailing_view_active
		and _early_visible
		and _sailing_viewport_world_rect.intersects(
			_wreck_visual_world_rect,
			true,
		)
	)
	visible = _early_visible
	if (
		was_early_visible != _early_visible
		or was_near_marker_visible != _near_marker_visible
	):
		queue_redraw()

	var port_selected := _selected_waypoint_id == "port"
	var heading_to_port := _ship_position.direction_to(_route_end)
	var heading_to_wreck := _ship_position.direction_to(global_position)
	var sailing_toward_port := (
		port_selected
		and _player_aboard_ship
		and _ship_has_departed
		and _ship_speed > 5.0
		and _ship_heading.dot(heading_to_port) >= 0.55
	)
	if sailing_toward_port:
		_started_toward_port = true
	_sailing_toward_wreck = (
		_player_aboard_ship
		and _ship_speed > 5.0
		and _ship_heading.dot(heading_to_wreck) >= 0.55
	)

	var route_acquired_before_update := _direct_route_acquired
	if _started_toward_port and _ship_route_offset <= ROUTE_ACQUIRE_RANGE:
		_direct_route_acquired = true

	if (
		_wreck_visual_on_screen
		and _started_toward_port
		and port_selected
		and _ship_route_progress < _wreck_route_progress
	):
		_seen_before_passing = true

	if (
		_seen_before_passing
		and route_acquired_before_update
		and _sailing_toward_wreck
		and _ship_route_offset >= ROUTE_DEPARTURE_RANGE
	):
		_left_direct_route = true

	if not _reached and _ship_distance <= REACHED_RANGE:
		_reached = true
	if (
		not _reached_after_course_change
		and _left_direct_route
		and _ship_distance <= REACHED_RANGE
	):
		_reached_after_course_change = true
		_distance_to_port_at_reach = _port_distance

	if (
		_reached_after_course_change
		and port_selected
		and _player_aboard_ship
		and _ship_speed > 5.0
		and _ship_heading.dot(heading_to_port) >= 0.55
		and _port_distance <= _distance_to_port_at_reach - RETURN_PROGRESS_DISTANCE
	):
		_returning_to_port = true


func can_receive_salvage_press() -> bool:
	return (
		_captain_aboard
		and _ship_distance <= SALVAGE_RANGE
		and absf(_ship_speed) <= SALVAGE_MAX_SPEED
		and _chart_closed
	)


func is_salvage_eligible() -> bool:
	return _salvage_eligible


func get_next_salvage_lot() -> String:
	if _salvage_lots.is_empty():
		return ""
	return _salvage_lots[0]


func get_salvage_lots() -> Array[String]:
	return _salvage_lots.duplicate()


func can_take_next_salvage_lot(expected_lot: String) -> bool:
	return (
		_salvage_eligible
		and not expected_lot.is_empty()
		and get_next_salvage_lot() == expected_lot
	)


func take_next_salvage_lot(expected_lot: String) -> bool:
	if _salvage_lots.is_empty():
		_last_salvage_result = "NO_CHANGE_WRECK_EMPTY"
		_repeat_salvage_result = _last_salvage_result
		return false
	if not can_take_next_salvage_lot(expected_lot):
		_last_salvage_result = "NO_CHANGE_INELIGIBLE"
		return false

	_salvage_lots.pop_front()
	_wreck_empty = _salvage_lots.is_empty()
	_salvage_eligible = false
	_successful_collection_count += 1
	if expected_lot == "TIMBER LOT":
		_last_salvage_result = "COLLECTED_ONE_TIMBER_LOT"
	else:
		_last_salvage_result = "KEPT_%s" % _result_name(expected_lot)
	queue_redraw()
	return true


func mark_salvage_choice_pending(expected_lot: String) -> bool:
	if expected_lot.is_empty() or get_next_salvage_lot() != expected_lot:
		return false
	_last_salvage_result = "CARGO_CHOICE_REQUIRED_%s" % _result_name(expected_lot)
	return true


func leave_salvage_lot_at_wreck(expected_lot: String) -> bool:
	if expected_lot.is_empty() or get_next_salvage_lot() != expected_lot:
		return false
	_last_salvage_result = "LEFT_%s_AT_WRECK" % _result_name(expected_lot)
	_repeat_salvage_result = _last_salvage_result
	queue_redraw()
	return true


func exchange_salvage_lot(expected_lot: String, returned_lot: String) -> bool:
	if (
		expected_lot.is_empty()
		or returned_lot.is_empty()
		or get_next_salvage_lot() != expected_lot
	):
		return false
	_salvage_lots[0] = returned_lot
	_wreck_empty = false
	_last_salvage_result = "REPLACED_WITH_%s" % _result_name(expected_lot)
	_successful_collection_count += 1
	queue_redraw()
	return true


func try_collect_timber_lot() -> bool:
	if _wreck_empty:
		_last_salvage_result = "NO_CHANGE_WRECK_EMPTY"
		_repeat_salvage_result = _last_salvage_result
		return false
	if not _salvage_eligible:
		_last_salvage_result = "NO_CHANGE_INELIGIBLE"
		return false

	if get_next_salvage_lot() != "TIMBER LOT":
		_last_salvage_result = "NO_CHANGE_TIMBER_NOT_NEXT"
		return false
	return take_next_salvage_lot("TIMBER LOT")


func get_playtest_state() -> Dictionary:
	return {
		"wreck_count": 1,
		"wreck_id": WRECK_ID,
		"wreck_position": global_position,
		"direct_route_start": _route_start,
		"direct_route_end": _route_end,
		"direct_route_offset": _wreck_route_offset,
		"wreck_direct_route_progress": _wreck_route_progress,
		"route_acquire_range": ROUTE_ACQUIRE_RANGE,
		"route_departure_range": ROUTE_DEPARTURE_RANGE,
		"early_visibility_range": EARLY_VISIBILITY_RANGE,
		"range_visibility_active": _early_visible,
		"current_visibility": _wreck_visual_on_screen,
		"early_visible": _early_visible,
		"visual_visible": visible,
		"sailing_view_active": _sailing_view_active,
		"sailing_viewport_size": SAILING_VIEWPORT_SIZE,
		"sailing_viewport_world_rect": _sailing_viewport_world_rect,
		"wreck_visual_local_bounds": WRECK_VISUAL_LOCAL_BOUNDS,
		"wreck_visual_world_rect": _wreck_visual_world_rect,
		"wreck_visual_on_screen": _wreck_visual_on_screen,
		"on_screen": _wreck_visual_on_screen,
		"near_marker_range": NEAR_MARKER_RANGE,
		"near_marker_visible": _near_marker_visible,
		"near_marker_count": int(_near_marker_visible),
		"reached_range": REACHED_RANGE,
		"ship_position": _ship_position,
		"ship_distance": _ship_distance,
		"ship_direct_route_offset": _ship_route_offset,
		"ship_direct_route_progress": _ship_route_progress,
		"port_distance": _port_distance,
		"player_aboard_ship": _player_aboard_ship,
		"captain_aboard": _captain_aboard,
		"ship_has_departed": _ship_has_departed,
		"selected_waypoint_id": _selected_waypoint_id,
		"port_waypoint_selected": _selected_waypoint_id == "port",
		"started_toward_port": _started_toward_port,
		"direct_route_acquired": _direct_route_acquired,
		"seen_before_passing": _seen_before_passing,
		"sailing_toward_wreck": _sailing_toward_wreck,
		"left_direct_route": _left_direct_route,
		"reached": _reached,
		"reached_after_course_change": _reached_after_course_change,
		"distance_to_port_at_reach": _distance_to_port_at_reach,
		"returning_to_port": _returning_to_port,
		"route_state": _get_route_state(),
		"known_chart_location": false,
		"chart_marker_count": 0,
		"salvage_range": SALVAGE_RANGE,
		"salvage_max_speed": SALVAGE_MAX_SPEED,
		"salvage_ship_distance": _ship_distance,
		"salvage_ship_speed": absf(_ship_speed),
		"salvage_captain_aboard": _captain_aboard,
		"salvage_beside_wreck": _ship_distance <= SALVAGE_RANGE,
		"salvage_slow_enough": absf(_ship_speed) <= SALVAGE_MAX_SPEED,
		"salvage_chart_closed": _chart_closed,
		"salvage_wreck_not_empty": not _wreck_empty,
		"salvage_eligible": _salvage_eligible,
		"salvage_eligibility": {
			"captain_aboard": _captain_aboard,
			"beside_wreck": _ship_distance <= SALVAGE_RANGE,
			"wreck_not_empty": not _wreck_empty,
			"chart_closed": _chart_closed,
			"slow_enough": absf(_ship_speed) <= SALVAGE_MAX_SPEED,
			"eligible": _salvage_eligible,
		},
		"wreck_salvage_lots": get_salvage_lots(),
		"wreck_salvage_lot_count": _salvage_lots.size(),
		"wreck_initial_salvage_lots": INITIAL_SALVAGE_LOTS.duplicate(),
		"wreck_initial_salvage_lot_count": INITIAL_SALVAGE_LOTS.size(),
		"wreck_has_more_lots_than_ship_limit_at_start": (
			INITIAL_SALVAGE_LOTS.size() > 3
		),
		"next_salvage_lot": get_next_salvage_lot(),
		"wreck_empty": _wreck_empty,
		"successful_collection_count": _successful_collection_count,
		"last_salvage_result": _last_salvage_result,
		"repeat_salvage_result": _repeat_salvage_result,
	}


func _result_name(lot_name: String) -> String:
	return lot_name.to_upper().replace(" ", "_")


func _get_route_state() -> String:
	if _returning_to_port:
		return "RETURNING_TO_PORT"
	if _reached_after_course_change:
		return "REACHED_WRECK"
	if _left_direct_route:
		return "LEFT_PORT_ROUTE"
	if _seen_before_passing:
		return "WRECK_SEEN_BEFORE_PASSING"
	if _started_toward_port:
		return "SAILING_TOWARD_PORT"
	if _selected_waypoint_id == "port":
		return "PORT_SELECTED"
	return "WAITING_FOR_PORT_WAYPOINT"


func _get_route_metrics(world_point: Vector2) -> Dictionary:
	var route_vector := _route_end - _route_start
	var route_length_squared := route_vector.length_squared()
	if is_zero_approx(route_length_squared):
		return {
			"offset": world_point.distance_to(_route_start),
			"progress": 0.0,
		}

	var progress := clampf(
		(world_point - _route_start).dot(route_vector) / route_length_squared,
		0.0,
		1.0,
	)
	var closest_point := _route_start + route_vector * progress
	return {
		"offset": world_point.distance_to(closest_point),
		"progress": progress,
	}


func _draw() -> void:
	# Fixed wreck pieces give the player one clear visual target.
	_draw_ellipse_shape(Vector2(8.0, 12.0), 92.0, 38.0, Color("#12323c66"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-82.0, -8.0),
		Vector2(-25.0, -34.0),
		Vector2(32.0, -24.0),
		Vector2(77.0, 14.0),
		Vector2(16.0, 35.0),
		Vector2(-55.0, 27.0),
	]), Color("#493323"))
	if not _wreck_empty:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-64.0, -8.0),
			Vector2(-22.0, -24.0),
			Vector2(15.0, -18.0),
			Vector2(-2.0, 23.0),
			Vector2(-47.0, 18.0),
		]), Color("#b27a47"))
	draw_line(Vector2(-96.0, 45.0), Vector2(-28.0, 16.0), Color("#6b452c"), 10.0)
	if _wreck_empty:
		draw_line(Vector2(42.0, 27.0), Vector2(108.0, 52.0), Color("#6b452c"), 9.0)
	else:
		draw_line(Vector2(42.0, 27.0), Vector2(108.0, 52.0), Color("#b27a47"), 9.0)
		for lot_index in range(_salvage_lots.size()):
			var lot_x := -45.0 + float(lot_index % 3) * 34.0
			var lot_y := -10.0 + float(lot_index / 3) * 22.0
			var lot_color := Color("#d7b45a")
			if _salvage_lots[lot_index] == "TIMBER LOT":
				lot_color = Color("#d69b5d")
			draw_rect(
				Rect2(Vector2(lot_x, lot_y), Vector2(28.0, 14.0)),
				lot_color,
			)
			draw_rect(
				Rect2(Vector2(lot_x, lot_y), Vector2(28.0, 14.0)),
				Color("#493323"),
				false,
				2.0,
			)
		draw_line(Vector2(9.0, -20.0), Vector2(30.0, -78.0), Color("#342b29"), 8.0)
		draw_circle(Vector2(19.0, -48.0), 13.0, Color("#ef6b35"))
		draw_circle(Vector2(17.0, -56.0), 7.0, Color("#ffd067"))

		# The smoke has no random motion, so its visible state is deterministic.
		draw_circle(Vector2(23.0, -88.0), 23.0, Color("#33444cb8"))
		draw_circle(Vector2(7.0, -122.0), 30.0, Color("#405159aa"))
		draw_circle(Vector2(25.0, -164.0), 35.0, Color("#4c5c63a0"))
		draw_circle(Vector2(3.0, -207.0), 39.0, Color("#5a686e90"))

	if not _near_marker_visible:
		return
	var font := ThemeDB.fallback_font
	draw_arc(Vector2.ZERO, 124.0, 0.0, TAU, 48, Color("#fff1c5"), 5.0)
	draw_line(Vector2(0.0, -124.0), Vector2(0.0, -238.0), Color("#fff1c5"), 4.0)
	var marker_text := "WRECK · %d LOTS" % _salvage_lots.size()
	var marker_width := 210.0
	var marker_x := -105.0
	if _wreck_empty:
		marker_text = "EMPTY WRECK"
		marker_width = 176.0
		marker_x = -88.0
	draw_string(
		font,
		Vector2(marker_x, -252.0),
		marker_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		marker_width,
		20,
		Color("#fff1c5"),
	)


func _draw_ellipse_shape(
	center: Vector2,
	radius_x: float,
	radius_y: float,
	color: Color,
) -> void:
	var points := PackedVector2Array()
	for index in range(32):
		var angle := TAU * float(index) / 32.0
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(points, color)
