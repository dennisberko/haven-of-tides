class_name InspectableTargetShip
extends Node2D

const VISIBILITY_RANGE := 900.0
const INSPECTION_RANGE := 250.0

@export var target_id := "target_ship"
@export var display_name := "MERCHANT SHIP"
@export var owner_name := "UNKNOWN OWNER"
@export var flag_name := "UNKNOWN FLAG"
@export var ship_class := "UNKNOWN CLASS"
@export var likely_speed := "UNKNOWN SPEED"
@export var general_cargo_type := "GENERAL GOODS"
@export_enum("LOW", "MEDIUM", "HIGH") var threat_estimate := "LOW"
@export var peaceful := true
@export_range(0, 9, 1) var estimated_heat_cost := 0
@export var hull_color := Color("#b27a47")
@export var sail_color := Color("#f3dfb0")
@export var flag_color := Color("#d7b45a")

var _player_ship_position := Vector2.ZERO
var _player_aboard := false
var _chart_closed := true
var _distance_to_player_ship := INF
var _inspection_available := false


func _ready() -> void:
	hide()
	queue_redraw()


func update_player_ship_state(
	player_ship_position: Vector2,
	player_aboard: bool,
	chart_closed: bool,
) -> void:
	_player_ship_position = player_ship_position
	_player_aboard = player_aboard
	_chart_closed = chart_closed
	_distance_to_player_ship = global_position.distance_to(_player_ship_position)
	var was_visible := visible
	var was_inspection_available := _inspection_available
	visible = _player_aboard and _distance_to_player_ship <= VISIBILITY_RANGE
	_inspection_available = (
		visible
		and _chart_closed
		and _distance_to_player_ship <= INSPECTION_RANGE
	)
	if was_visible != visible or was_inspection_available != _inspection_available:
		queue_redraw()


func is_inspection_available() -> bool:
	return _inspection_available


func get_distance_to_player_ship() -> float:
	return _distance_to_player_ship


func get_estimate_state() -> Dictionary:
	return {
		"target_id": target_id,
		"display_name": display_name,
		"owner_estimate": owner_name,
		"flag_estimate": flag_name,
		"ship_class_estimate": ship_class,
		"likely_speed_estimate": likely_speed,
		"general_cargo_type_estimate": general_cargo_type,
		"threat_estimate": threat_estimate,
		"peaceful_estimate": peaceful,
		"estimated_heat_cost": estimated_heat_cost,
		"all_values_are_estimates": true,
	}


func get_playtest_state() -> Dictionary:
	var estimate := get_estimate_state()
	return {
		"target_id": target_id,
		"display_name": display_name,
		"position": global_position,
		"player_ship_position": _player_ship_position,
		"distance_to_player_ship": _distance_to_player_ship,
		"visibility_range": VISIBILITY_RANGE,
		"inspection_range": INSPECTION_RANGE,
		"visual_visible": visible,
		"player_aboard": _player_aboard,
		"chart_closed": _chart_closed,
		"inspection_available": _inspection_available,
		"estimate": estimate,
	}


func _draw() -> void:
	# The long hull, mast, sails, and flag make each target a clear sea ship.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-54.0, -20.0),
		Vector2(38.0, -24.0),
		Vector2(63.0, 0.0),
		Vector2(38.0, 24.0),
		Vector2(-54.0, 20.0),
		Vector2(-68.0, 0.0),
	]), hull_color)
	draw_polyline(PackedVector2Array([
		Vector2(-54.0, -20.0),
		Vector2(38.0, -24.0),
		Vector2(63.0, 0.0),
		Vector2(38.0, 24.0),
		Vector2(-54.0, 20.0),
		Vector2(-68.0, 0.0),
		Vector2(-54.0, -20.0),
	]), Color("#2e2926"), 4.0)
	draw_line(Vector2(-6.0, -46.0), Vector2(-6.0, 45.0), Color("#493323"), 6.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-3.0, -40.0),
		Vector2(43.0, -4.0),
		Vector2(-3.0, -4.0),
	]), sail_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9.0, 4.0),
		Vector2(29.0, 36.0),
		Vector2(-9.0, 36.0),
	]), sail_color.darkened(0.12))
	draw_line(Vector2(-35.0, -18.0), Vector2(-35.0, -47.0), Color("#493323"), 4.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-33.0, -46.0),
		Vector2(-10.0, -39.0),
		Vector2(-33.0, -32.0),
	]), flag_color)

	if not _inspection_available:
		return
	draw_arc(Vector2.ZERO, 90.0, 0.0, TAU, 48, Color("#fff1c5"), 4.0)
	var font := ThemeDB.fallback_font
	draw_string(
		font,
		Vector2(-110.0, -104.0),
		"%s · E INSPECT" % display_name,
		HORIZONTAL_ALIGNMENT_CENTER,
		220.0,
		16,
		Color("#fff1c5"),
	)
