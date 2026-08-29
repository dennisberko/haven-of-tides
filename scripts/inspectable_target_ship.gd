class_name InspectableTargetShip
extends Node2D

const VISIBILITY_RANGE := 900.0
const INSPECTION_RANGE := 250.0
const HULL_MAX := 100
const HIT_FEEDBACK_DURATION := 0.55

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
var _hull_current := HULL_MAX
var _disabled := false
var _hit_feedback_remaining := 0.0
var _hit_count := 0
var _last_hit_side := "NONE"
var _last_hit_damage := 0
var _last_hit_evidence: Dictionary = {}


func _ready() -> void:
	hide()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _hit_feedback_remaining <= 0.0:
		return
	_hit_feedback_remaining = maxf(0.0, _hit_feedback_remaining - delta)
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


func can_receive_hull_damage() -> bool:
	return not _disabled and _hull_current > 0


func apply_broadside_hull_damage(damage: int, attack_side: String) -> Dictionary:
	var hull_before: int = _hull_current
	if damage <= 0 or not can_receive_hull_damage():
		return {
			"success": false,
			"target_id": target_id,
			"target_name": display_name,
			"attack_side": attack_side,
			"damage": 0,
			"hull_before": hull_before,
			"hull_after": _hull_current,
			"hull_max": HULL_MAX,
			"hull_delta": 0,
			"disabled": _disabled,
			"result": "NO TARGET HULL CHANGE",
		}
	_hull_current = maxi(0, _hull_current - damage)
	_disabled = _hull_current == 0
	_hit_count += 1
	_last_hit_side = attack_side
	_last_hit_damage = hull_before - _hull_current
	_hit_feedback_remaining = HIT_FEEDBACK_DURATION
	_last_hit_evidence = {
		"success": true,
		"target_id": target_id,
		"target_name": display_name,
		"attack_side": attack_side,
		"damage": _last_hit_damage,
		"hull_before": hull_before,
		"hull_after": _hull_current,
		"hull_max": HULL_MAX,
		"hull_delta": _hull_current - hull_before,
		"disabled": _disabled,
		"reached_zero_hull": _disabled and _hull_current == 0,
		"hit_feedback_started": true,
		"result": (
			"TARGET DISABLED"
			if _disabled
			else "TARGET HIT · -%d HULL" % _last_hit_damage
		),
	}
	queue_redraw()
	return _last_hit_evidence.duplicate(true)


func get_hull_state() -> Dictionary:
	return {
		"hull_current": _hull_current,
		"hull_max": HULL_MAX,
		"hull_ratio": float(_hull_current) / float(HULL_MAX),
		"disabled": _disabled,
		"can_receive_hull_damage": can_receive_hull_damage(),
		"hit_count": _hit_count,
		"last_hit_side": _last_hit_side,
		"last_hit_damage": _last_hit_damage,
		"hit_feedback_duration": HIT_FEEDBACK_DURATION,
		"hit_feedback_remaining": _hit_feedback_remaining,
		"hit_feedback_active": _hit_feedback_remaining > 0.0,
		"hull_condition_visible": visible,
		"hull_condition_text": (
			"DISABLED · HULL 0 / %d" % HULL_MAX
			if _disabled
			else "HULL %d / %d" % [_hull_current, HULL_MAX]
		),
		"disabled_visual_visible": visible and _disabled,
		"last_hit_evidence": _last_hit_evidence.duplicate(true),
	}


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
	var estimate: Dictionary = get_estimate_state()
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
		"hull": get_hull_state(),
	}


func _draw() -> void:
	# The long hull, mast, sails, and flag make each target a clear sea ship.
	var active_hull_color: Color = hull_color
	var active_sail_color: Color = sail_color
	if _disabled:
		active_hull_color = hull_color.darkened(0.68)
		active_sail_color = sail_color.darkened(0.7)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-54.0, -20.0),
		Vector2(38.0, -24.0),
		Vector2(63.0, 0.0),
		Vector2(38.0, 24.0),
		Vector2(-54.0, 20.0),
		Vector2(-68.0, 0.0),
	]), active_hull_color)
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
	]), active_sail_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9.0, 4.0),
		Vector2(29.0, 36.0),
		Vector2(-9.0, 36.0),
	]), active_sail_color.darkened(0.12))
	draw_line(Vector2(-35.0, -18.0), Vector2(-35.0, -47.0), Color("#493323"), 4.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-33.0, -46.0),
		Vector2(-10.0, -39.0),
		Vector2(-33.0, -32.0),
	]), flag_color)

	var font: Font = ThemeDB.fallback_font
	var hull_text: String = "HULL %d / %d" % [_hull_current, HULL_MAX]
	var hull_text_color: Color = Color("#fff1c5")
	if _disabled:
		hull_text = "DISABLED · HULL 0 / %d" % HULL_MAX
		hull_text_color = Color("#ff806e")
		draw_line(Vector2(-55.0, -35.0), Vector2(55.0, 35.0), hull_text_color, 8.0)
		draw_line(Vector2(-55.0, 35.0), Vector2(55.0, -35.0), hull_text_color, 8.0)
	draw_string(
		font,
		Vector2(-110.0, 82.0),
		hull_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		220.0,
		17,
		hull_text_color,
	)
	if _hit_feedback_remaining > 0.0:
		draw_arc(Vector2.ZERO, 82.0, 0.0, TAU, 48, Color("#ff4b3e"), 9.0)
		draw_string(
			font,
			Vector2(-100.0, 112.0),
			(
				"DISABLED"
				if _disabled
				else "HIT · -%d HULL" % _last_hit_damage
			),
			HORIZONTAL_ALIGNMENT_CENTER,
			200.0,
			20,
			Color("#ff806e"),
		)

	if not _inspection_available:
		return
	draw_arc(Vector2.ZERO, 90.0, 0.0, TAU, 48, Color("#fff1c5"), 4.0)
	draw_string(
		font,
		Vector2(-110.0, -104.0),
		"%s · E INSPECT" % display_name,
		HORIZONTAL_ALIGNMENT_CENTER,
		220.0,
		16,
		Color("#fff1c5"),
	)
