class_name WaypointDisplay
extends Control

const CHART_PANEL := Rect2(150.0, 82.0, 852.0, 484.0)
const CHART_WORLD := Rect2(194.0, 148.0, 764.0, 344.0)
const DIRECTION_CENTER := Vector2(576.0, 126.0)
const DIRECTION_RADIUS := 58.0

var chart_visible := false
var selected_location_id := ""

var _sea_bounds := Rect2()
var _known_locations := {}
var _ship_position := Vector2.ZERO
var _player_position := Vector2.ZERO
var _player_aboard_ship := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func configure(sea_bounds: Rect2, dock_definitions: Array) -> void:
	_sea_bounds = sea_bounds
	_known_locations.clear()
	for untyped_definition in dock_definitions:
		var definition: Dictionary = untyped_definition
		var location_id := String(definition.get("id", ""))
		if location_id.is_empty():
			continue
		_known_locations[location_id] = {
			"id": location_id,
			"name": String(definition.get("name", location_id.to_upper())),
			"position": definition.get("approach_position", Vector2.ZERO),
		}
	queue_redraw()


func set_chart_visible(visible: bool) -> void:
	chart_visible = visible
	queue_redraw()


func select_location(location_id: String) -> bool:
	if not _known_locations.has(location_id):
		return false
	selected_location_id = location_id
	queue_redraw()
	return true


func clear_location() -> void:
	selected_location_id = ""
	queue_redraw()


func update_positions(
	ship_position: Vector2,
	player_position: Vector2,
	player_aboard_ship: bool,
) -> void:
	_ship_position = ship_position
	_player_position = player_position
	_player_aboard_ship = player_aboard_ship
	queue_redraw()


func get_direction_vector() -> Vector2:
	if selected_location_id.is_empty() or not _known_locations.has(selected_location_id):
		return Vector2.ZERO
	var target_position: Vector2 = _known_locations[selected_location_id]["position"]
	return _ship_position.direction_to(target_position)


func get_target_position() -> Vector2:
	if selected_location_id.is_empty() or not _known_locations.has(selected_location_id):
		return Vector2.ZERO
	return _known_locations[selected_location_id]["position"]


func get_playtest_state() -> Dictionary:
	var known_locations := {}
	for location_id in _known_locations:
		known_locations[location_id] = (_known_locations[location_id] as Dictionary).duplicate(true)
	var direction := get_direction_vector()
	var direction_angle := 0.0
	if not direction.is_zero_approx():
		direction_angle = direction.angle()
	return {
		"chart_visible": chart_visible,
		"known_location_count": _known_locations.size(),
		"known_location_ids": PackedStringArray(_known_locations.keys()),
		"known_locations": known_locations,
		"selected_location_id": selected_location_id,
		"selected_marker_count": int(not selected_location_id.is_empty()),
		"chart_selected_marker_count": int(
			chart_visible and not selected_location_id.is_empty()
		),
		"sailing_direction_marker_count": int(
			not chart_visible
			and _player_aboard_ship
			and not selected_location_id.is_empty()
			and not direction.is_zero_approx()
		),
		"ship_position": _ship_position,
		"player_position": _player_position,
		"target_position": get_target_position(),
		"direction_vector": direction,
		"direction_angle_radians": direction_angle,
		"direction_angle_degrees": rad_to_deg(direction_angle),
	}


func _draw() -> void:
	if chart_visible:
		_draw_chart()
	elif _player_aboard_ship and not selected_location_id.is_empty():
		_draw_sailing_direction()


func _draw_chart() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color("#071a23e8"))
	draw_rect(CHART_PANEL, Color("#e8d2a2"))
	draw_rect(CHART_PANEL.grow(-6.0), Color("#173f4b"), false, 4.0)
	draw_string(
		font,
		Vector2(CHART_PANEL.position.x + 30.0, CHART_PANEL.position.y + 43.0),
		"SEA CHART",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		28,
		Color("#173f4b"),
	)
	draw_rect(CHART_WORLD, Color("#13788b"))
	draw_rect(CHART_WORLD, Color("#d8eee8"), false, 3.0)

	for y in range(int(CHART_WORLD.position.y + 28.0), int(CHART_WORLD.end.y), 38):
		draw_line(
			Vector2(CHART_WORLD.position.x + 12.0, y),
			Vector2(CHART_WORLD.end.x - 12.0, y - 10.0),
			Color("#48a8aa70"),
			2.0,
		)

	for location_id in _known_locations:
		var location: Dictionary = _known_locations[location_id]
		var chart_position := _world_to_chart(location["position"])
		draw_circle(chart_position, 10.0, Color("#fff1c5"))
		draw_circle(chart_position, 5.0, Color("#493323"))
		draw_string(
			font,
			chart_position + Vector2(14.0, 5.0),
			_location_label(location_id),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			16,
			Color("#fff1c5"),
		)

	if not selected_location_id.is_empty() and _known_locations.has(selected_location_id):
		var selected_position := _world_to_chart(get_target_position())
		draw_arc(selected_position, 19.0, 0.0, TAU, 32, Color("#ef6b35"), 5.0)
		draw_line(
			selected_position + Vector2(0.0, -28.0),
			selected_position + Vector2(0.0, -17.0),
			Color("#ef6b35"),
			4.0,
		)

	var ship_chart_position := _world_to_chart(_ship_position)
	draw_colored_polygon(PackedVector2Array([
		ship_chart_position + Vector2(0.0, -13.0),
		ship_chart_position + Vector2(9.0, 9.0),
		ship_chart_position + Vector2(-9.0, 9.0),
	]), Color("#ef6b35"))
	draw_string(
		font,
		ship_chart_position + Vector2(13.0, -8.0),
		"SHIP",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		14,
		Color("#ef6b35"),
	)

	if not _player_aboard_ship:
		var player_chart_position := _world_to_chart(_player_position)
		draw_circle(player_chart_position, 7.0, Color("#d8eee8"))
		draw_string(
			font,
			player_chart_position + Vector2(11.0, 14.0),
			"YOU",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			14,
			Color("#d8eee8"),
		)

	var selection_text := "WAYPOINT: NONE"
	if not selected_location_id.is_empty():
		selection_text = "WAYPOINT: %s" % _location_label(selected_location_id)
	draw_string(
		font,
		Vector2(CHART_PANEL.position.x + 30.0, CHART_PANEL.end.y - 25.0),
		selection_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		18,
		Color("#173f4b"),
	)
	draw_string(
		font,
		Vector2(CHART_PANEL.end.x - 445.0, CHART_PANEL.end.y - 25.0),
		"[1] COVE  [2] ISLAND  [3] PORT  [X] CLEAR  [M] CLOSE",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		15,
		Color("#173f4b"),
	)


func _draw_sailing_direction() -> void:
	var direction := get_direction_vector()
	if direction.is_zero_approx():
		return
	var font := ThemeDB.fallback_font
	draw_circle(DIRECTION_CENTER, DIRECTION_RADIUS + 8.0, Color("#071a23c8"))
	draw_arc(
		DIRECTION_CENTER,
		DIRECTION_RADIUS,
		0.0,
		TAU,
		40,
		Color("#fff1c5"),
		4.0,
	)
	var tip := DIRECTION_CENTER + direction * 48.0
	draw_line(DIRECTION_CENTER, tip, Color("#ef6b35"), 7.0)
	draw_colored_polygon(PackedVector2Array([
		tip,
		tip - direction.rotated(0.62) * 18.0,
		tip - direction.rotated(-0.62) * 18.0,
	]), Color("#ef6b35"))
	draw_string(
		font,
		DIRECTION_CENTER + Vector2(-110.0, 92.0),
		"WAYPOINT: %s" % _location_label(selected_location_id),
		HORIZONTAL_ALIGNMENT_CENTER,
		220.0,
		17,
		Color("#fff1c5"),
	)


func _world_to_chart(world_position: Vector2) -> Vector2:
	if not _sea_bounds.has_area():
		return CHART_WORLD.get_center()
	var normalized := Vector2(
		inverse_lerp(_sea_bounds.position.x, _sea_bounds.end.x, world_position.x),
		inverse_lerp(_sea_bounds.position.y, _sea_bounds.end.y, world_position.y),
	)
	normalized = normalized.clamp(Vector2.ZERO, Vector2.ONE)
	return CHART_WORLD.position + normalized * CHART_WORLD.size


func _location_label(location_id: String) -> String:
	match location_id:
		"cove":
			return "COVE"
		"island":
			return "ISLAND"
		"port":
			return "PORT"
	return location_id.to_upper()
