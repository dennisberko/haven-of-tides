class_name WeatherArea
extends Node2D

const WEATHER_CLEAR := "CLEAR"
const WEATHER_STORM := "STORM"
const AREA_ID := "shoal_storm_area"
const AREA_RADIUS := 220.0
const STORM_TURN_MULTIPLIER := 0.5
const NORMAL_TURN_MULTIPLIER := 1.0
const SAILING_VIEWPORT_SIZE := Vector2(1152.0, 648.0)
const VISUAL_LOCAL_BOUNDS := Rect2(-330.0, -348.0, 660.0, 678.0)

var _weather_state := WEATHER_CLEAR
var _ship_position := Vector2.ZERO
var _ship_distance := INF
var _sailing_view_active := false
var _ship_inside_active_storm := false
var _storm_visual_on_screen := false
var _sailing_viewport_world_rect := Rect2()
var _storm_seen_from_outside := false
var _outside_visibility_active := false
var _outside_visibility_count := 0
var _storm_entry_count := 0
var _storm_exit_count := 0
var _weather_toggle_attempt_count := 0
var _weather_toggle_success_count := 0
var _weather_toggle_denied_count := 0
var _weather_held_input_count := 0
var _storm_response_observed := false
var _last_response_kind := ""
var _last_turn_input_frame_recorded := 0
var _last_toggle_evidence: Dictionary = {}
var _last_held_toggle_evidence: Dictionary = {}
var _last_outside_visibility_evidence: Dictionary = {}
var _last_entry_evidence: Dictionary = {}
var _last_exit_evidence: Dictionary = {}
var _clear_response_evidence: Dictionary = {}
var _storm_outside_response_evidence: Dictionary = {}
var _storm_response_evidence: Dictionary = {}
var _recovery_response_evidence: Dictionary = {}
var _clear_turn_input_evidence: Dictionary = {}
var _storm_turn_input_evidence: Dictionary = {}
var _recovery_turn_input_evidence: Dictionary = {}


func _ready() -> void:
	hide()
	queue_redraw()


func update_state(
		ship_position: Vector2,
		sailing_view_active: bool,
) -> void:
	var was_inside_active_storm := _ship_inside_active_storm
	_ship_position = ship_position
	_sailing_view_active = sailing_view_active
	_ship_distance = _ship_position.distance_to(global_position)
	_ship_inside_active_storm = (
		is_storm_active() and _ship_distance <= AREA_RADIUS
	)
	_sailing_viewport_world_rect = Rect2(
		_ship_position - SAILING_VIEWPORT_SIZE * 0.5,
		SAILING_VIEWPORT_SIZE,
	)
	_storm_visual_on_screen = (
		_sailing_view_active
		and is_storm_active()
		and _sailing_viewport_world_rect.intersects(
			Rect2(
				global_position + VISUAL_LOCAL_BOUNDS.position,
				VISUAL_LOCAL_BOUNDS.size,
			),
			true,
		)
	)
	visible = _sailing_view_active and is_storm_active()

	var outside_visibility_now := (
		_storm_visual_on_screen and not _ship_inside_active_storm
	)
	if outside_visibility_now and not _outside_visibility_active:
		_outside_visibility_count += 1
		_storm_seen_from_outside = true
		_last_outside_visibility_evidence = {
			"weather_state": _weather_state,
			"ship_position": _ship_position,
			"storm_area_position": global_position,
			"ship_distance": _ship_distance,
			"storm_radius": AREA_RADIUS,
			"ship_outside_storm": _ship_distance > AREA_RADIUS,
			"storm_visual_on_screen": _storm_visual_on_screen,
			"visible_before_entry": (
				_ship_distance > AREA_RADIUS and _storm_visual_on_screen
			),
		}
	_outside_visibility_active = outside_visibility_now

	if _ship_inside_active_storm and not was_inside_active_storm:
		_storm_entry_count += 1
		_last_entry_evidence = {
			"weather_state": _weather_state,
			"ship_position": _ship_position,
			"storm_area_position": global_position,
			"ship_distance": _ship_distance,
			"storm_radius": AREA_RADIUS,
			"inside_before": false,
			"inside_after": true,
			"turn_multiplier_before": NORMAL_TURN_MULTIPLIER,
			"turn_multiplier_after": STORM_TURN_MULTIPLIER,
		}
	elif not _ship_inside_active_storm and was_inside_active_storm:
		_storm_exit_count += 1
		_last_exit_evidence = {
			"weather_state": _weather_state,
			"ship_position": _ship_position,
			"storm_area_position": global_position,
			"ship_distance": _ship_distance,
			"storm_radius": AREA_RADIUS,
			"inside_before": true,
			"inside_after": false,
			"turn_multiplier_before": STORM_TURN_MULTIPLIER,
			"turn_multiplier_after": NORMAL_TURN_MULTIPLIER,
			"exit_kind": (
				"LEFT_STORM_AREA" if is_storm_active() else "WEATHER_CLEARED"
			),
		}


func try_toggle_weather(input_available: bool, context: Dictionary) -> bool:
	_weather_toggle_attempt_count += 1
	var state_before := _weather_state
	if not input_available:
		_weather_toggle_denied_count += 1
		_last_toggle_evidence = {
			"success": false,
			"result": "NO_CHANGE_WEATHER_INPUT_UNAVAILABLE",
			"state_before": state_before,
			"state_after": _weather_state,
			"state_unchanged": state_before == _weather_state,
			"fresh_press_required": true,
			"context_before": context.duplicate(true),
			"context_after": context.duplicate(true),
		}
		return false

	_weather_state = (
		WEATHER_STORM
		if _weather_state == WEATHER_CLEAR
		else WEATHER_CLEAR
	)
	_weather_toggle_success_count += 1
	_last_toggle_evidence = {
		"success": true,
		"result": "STARTED_STORM" if is_storm_active() else "RETURNED_TO_CLEAR",
		"state_before": state_before,
		"state_after": _weather_state,
		"state_changed_once": state_before != _weather_state,
		"fresh_press_required": true,
		"context_before": context.duplicate(true),
		"context_after": context.duplicate(true),
		"cargo_unchanged": true,
		"money_unchanged": true,
		"hull_unchanged": true,
	}
	queue_redraw()
	return true


func record_held_toggle(context: Dictionary) -> void:
	_weather_held_input_count += 1
	_last_held_toggle_evidence = {
		"result": "NO_CHANGE_HELD_WEATHER_INPUT",
		"weather_state_before": _weather_state,
		"weather_state_after": _weather_state,
		"weather_state_unchanged": true,
		"fresh_press_required": true,
		"context_before": context.duplicate(true),
		"context_after": context.duplicate(true),
		"cargo_unchanged": true,
		"money_unchanged": true,
		"hull_unchanged": true,
	}


func record_ship_response(
		base_turn_speed: float,
		actual_turn_speed: float,
		context: Dictionary,
) -> void:
	var response_kind := _get_response_kind()
	if not _sailing_view_active or response_kind == _last_response_kind:
		return
	_last_response_kind = response_kind
	var expected_multiplier := get_turn_multiplier()
	var response_evidence := {
		"weather_state": _weather_state,
		"ship_inside_active_storm": _ship_inside_active_storm,
		"ship_position": _ship_position,
		"ship_distance": _ship_distance,
		"base_turn_speed_radians": base_turn_speed,
		"base_turn_speed_degrees": rad_to_deg(base_turn_speed),
		"expected_turn_multiplier": expected_multiplier,
		"actual_turn_speed_radians": actual_turn_speed,
		"actual_turn_speed_degrees": rad_to_deg(actual_turn_speed),
		"response_matches_weather": is_equal_approx(
			actual_turn_speed,
			base_turn_speed * expected_multiplier,
		),
		"top_speed_unchanged_by_weather": true,
		"context": context.duplicate(true),
	}
	if _weather_state == WEATHER_CLEAR:
		_clear_response_evidence = response_evidence
	elif _ship_inside_active_storm:
		_storm_response_observed = true
		_storm_response_evidence = response_evidence
	else:
		_storm_outside_response_evidence = response_evidence
	if _storm_response_observed and not _ship_inside_active_storm:
		_recovery_response_evidence = response_evidence


func needs_ship_response_record() -> bool:
	return (
		_sailing_view_active and _get_response_kind() != _last_response_kind
	)


func needs_turn_input_response_record(turn_input_frame_count: int) -> bool:
	return turn_input_frame_count > _last_turn_input_frame_recorded


func record_turn_input_response(evidence: Dictionary) -> void:
	var frame_number := int(evidence.get("frame_number", 0))
	if frame_number <= _last_turn_input_frame_recorded:
		return
	_last_turn_input_frame_recorded = frame_number
	var weather_evidence := evidence.duplicate(true)
	weather_evidence["weather_state"] = _weather_state
	weather_evidence["ship_inside_active_storm"] = _ship_inside_active_storm
	if _weather_state == WEATHER_CLEAR:
		_clear_turn_input_evidence = weather_evidence
	elif _ship_inside_active_storm:
		_storm_turn_input_evidence = weather_evidence
	elif _storm_response_observed:
		_recovery_turn_input_evidence = weather_evidence


func _get_response_kind() -> String:
	if _weather_state == WEATHER_CLEAR:
		return "CLEAR"
	if _ship_inside_active_storm:
		return "STORM_INSIDE"
	return "STORM_OUTSIDE"


func is_storm_active() -> bool:
	return _weather_state == WEATHER_STORM


func is_ship_inside_active_storm() -> bool:
	return _ship_inside_active_storm


func is_fishing_blocked() -> bool:
	return _ship_inside_active_storm


func get_turn_multiplier() -> float:
	return (
		STORM_TURN_MULTIPLIER
		if _ship_inside_active_storm
		else NORMAL_TURN_MULTIPLIER
	)


func get_hud_title() -> String:
	return "WEATHER · %s" % _weather_state


func get_hud_status() -> String:
	if _weather_state == WEATHER_CLEAR:
		return "TURN RATE 100% · [T] START STORM"
	if _ship_inside_active_storm:
		return "INSIDE STORM · TURN RATE 50% · FISHING BLOCKED · [T] CLEAR"
	return "STORM AREA ACTIVE · TURN RATE 100% OUTSIDE · [T] CLEAR"


func get_playtest_state() -> Dictionary:
	var visual_world_rect := Rect2(
		global_position + VISUAL_LOCAL_BOUNDS.position,
		VISUAL_LOCAL_BOUNDS.size,
	)
	return {
		"system_count": 1,
		"owner_count": 1,
		"weather_state_count": 2,
		"weather_states": [WEATHER_CLEAR, WEATHER_STORM],
		"weather_state": _weather_state,
		"clear_active": _weather_state == WEATHER_CLEAR,
		"storm_active": is_storm_active(),
		"storm_area_count": 1,
		"storm_area_id": AREA_ID,
		"storm_area_position": global_position,
		"storm_area_radius": AREA_RADIUS,
		"storm_outside_test_position": (
			global_position + Vector2(0.0, -AREA_RADIUS - 80.0)
		),
		"storm_inside_test_position": global_position,
		"storm_exit_test_position": (
			global_position + Vector2(0.0, AREA_RADIUS + 15.0)
		),
		"storm_area_visible": visible,
		"storm_visual_local_bounds": VISUAL_LOCAL_BOUNDS,
		"storm_visual_world_rect": visual_world_rect,
		"storm_visual_on_screen": _storm_visual_on_screen,
		"sailing_view_active": _sailing_view_active,
		"sailing_viewport_world_rect": _sailing_viewport_world_rect,
		"ship_position": _ship_position,
		"ship_distance": _ship_distance,
		"ship_inside_active_storm": _ship_inside_active_storm,
		"storm_seen_from_outside": _storm_seen_from_outside,
		"outside_visibility_count": _outside_visibility_count,
		"last_outside_visibility_evidence": (
			_last_outside_visibility_evidence.duplicate(true)
		),
		"storm_entry_count": _storm_entry_count,
		"storm_exit_count": _storm_exit_count,
		"last_entry_evidence": _last_entry_evidence.duplicate(true),
		"last_exit_evidence": _last_exit_evidence.duplicate(true),
		"normal_turn_multiplier": NORMAL_TURN_MULTIPLIER,
		"storm_turn_multiplier": STORM_TURN_MULTIPLIER,
		"current_turn_multiplier": get_turn_multiplier(),
		"fishing_blocked": is_fishing_blocked(),
		"toggle_key": "T",
		"toggle_attempt_count": _weather_toggle_attempt_count,
		"toggle_success_count": _weather_toggle_success_count,
		"toggle_denied_count": _weather_toggle_denied_count,
		"held_input_count": _weather_held_input_count,
		"fresh_press_required": true,
		"last_toggle_evidence": _last_toggle_evidence.duplicate(true),
		"last_held_toggle_evidence": (
			_last_held_toggle_evidence.duplicate(true)
		),
		"clear_response_evidence": _clear_response_evidence.duplicate(true),
		"storm_outside_response_evidence": (
			_storm_outside_response_evidence.duplicate(true)
		),
		"storm_response_evidence": _storm_response_evidence.duplicate(true),
		"recovery_response_evidence": (
			_recovery_response_evidence.duplicate(true)
		),
		"clear_turn_input_evidence": _clear_turn_input_evidence.duplicate(true),
		"storm_turn_input_evidence": _storm_turn_input_evidence.duplicate(true),
		"recovery_turn_input_evidence": (
			_recovery_turn_input_evidence.duplicate(true)
		),
		"hud_title": get_hud_title(),
		"hud_status": get_hud_status(),
		"season_system_count": 0,
		"detailed_forecast_system_count": 0,
		"wind_simulation_enabled": false,
		"random_cargo_loss_enabled": false,
		"strange_or_cursed_storm_enabled": false,
		"day_night_system_count": 0,
		"ruin_system_count": 0,
		"tool_gate_system_count": 0,
		"story_clue_system_count": 0,
		"monster_hunting_system_count": 0,
		"ship_motion_owner_count": 1,
		"fishing_owner_count": 1,
		"uses_existing_ship_damage_owner": true,
		"storm_random_hull_damage_enabled": false,
	}


func _draw() -> void:
	draw_circle(Vector2.ZERO, AREA_RADIUS, Color("#32445688"))
	for ring_radius in [AREA_RADIUS, AREA_RADIUS - 44.0, AREA_RADIUS - 88.0]:
		draw_arc(
			Vector2.ZERO,
			ring_radius,
			0.0,
			TAU,
			72,
			Color("#b9d6dfb8"),
			5.0 if ring_radius == AREA_RADIUS else 2.0,
		)
	for cloud_position in [
		Vector2(-130.0, -80.0),
		Vector2(-25.0, -128.0),
		Vector2(102.0, -62.0),
	]:
		draw_circle(cloud_position, 48.0, Color("#d8e1e6d8"))
		draw_circle(cloud_position + Vector2(42.0, 10.0), 38.0, Color("#b8c8d1d8"))
		draw_line(
			cloud_position + Vector2(-28.0, 56.0),
			cloud_position + Vector2(-48.0, 104.0),
			Color("#8ad7e8"),
			6.0,
		)
		draw_line(
			cloud_position + Vector2(18.0, 58.0),
			cloud_position + Vector2(-2.0, 106.0),
			Color("#8ad7e8"),
			6.0,
		)
	draw_rect(
		Rect2(Vector2(-230.0, -340.0), Vector2(460.0, 42.0)),
		Color("#142936ed"),
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-216.0, -311.0),
		"STORM AREA · TURN RATE 50% · FISHING BLOCKED",
		HORIZONTAL_ALIGNMENT_CENTER,
		432.0,
		18,
		Color("#edf8ff"),
	)
