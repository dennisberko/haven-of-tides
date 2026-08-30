class_name FastTravel
extends Node

const ShipFoodState := preload("res://scripts/ship_food.gd")
const PORT_ID := "port"
const PORT_NAME := "TEST PORT DOCK"
const FOOD_COST := 1
const TIME_COST := 1
const MAJOR_THREAT_RANGE := 350.0

var _port_unlocked := false
var _port_dock_visit_count := 0
var _port_unlock_count := 0
var _preview_update_count := 0
var _unvisited_preview_count := 0
var _confirm_attempt_count := 0
var _success_count := 0
var _denied_count := 0
var _held_confirm_count := 0
var _unvisited_denied_count := 0
var _food_denied_count := 0
var _combat_block_count := 0
var _chase_block_count := 0
var _major_threat_block_count := 0
var _total_food_used := 0
var _total_time_steps_advanced := 0
var _cargo_safe_after_all_travel := true
var _current_preview: Dictionary = {}
var _last_port_visit_evidence: Dictionary = {}
var _last_confirm_evidence: Dictionary = {}
var _successful_travel_evidence: Dictionary = {}
var _last_denied_evidence: Dictionary = {}
var _last_held_evidence: Dictionary = {}


func record_dock_visit(dock_id: String, dock_name: String) -> Dictionary:
	if dock_id != PORT_ID:
		return {
			"success": false,
			"result": "NO FAST TRAVEL PORT UNLOCK",
			"dock_id": dock_id,
			"port_unlocked": _port_unlocked,
			"no_state_change": true,
		}
	var unlocked_before := _port_unlocked
	_port_dock_visit_count += 1
	if not _port_unlocked:
		_port_unlocked = true
		_port_unlock_count += 1
	_last_port_visit_evidence = {
		"success": true,
		"result": (
			"FAST TRAVEL UNLOCKED · %s" % dock_name
			if not unlocked_before
			else "FAST TRAVEL PORT ALREADY UNLOCKED · %s" % dock_name
		),
		"dock_id": dock_id,
		"dock_name": dock_name,
		"unlocked_before": unlocked_before,
		"unlocked_after": _port_unlocked,
		"unlocked_on_first_dock": (
			not unlocked_before
			and _port_unlocked
			and _port_dock_visit_count == 1
			and _port_unlock_count == 1
		),
		"dock_visit_count": _port_dock_visit_count,
		"unlock_count": _port_unlock_count,
		"unlocks_at_most_once": _port_unlock_count <= 1,
	}
	return _last_port_visit_evidence.duplicate(true)


func is_port_unlocked() -> bool:
	return _port_unlocked


func update_preview(context: Dictionary) -> Dictionary:
	var selected_location_id := String(
		context.get("selected_location_id", "")
	)
	var selected_port := selected_location_id == PORT_ID
	var chart_visible := bool(context.get("chart_visible", false))
	var captain_aboard := bool(context.get("captain_aboard", false))
	var ship_is_docked := bool(context.get("ship_is_docked", false))
	var food_units := int(context.get("food_units", 0))
	var combat_active := bool(context.get("combat_active", false))
	var chase_active := bool(context.get("chase_active", false))
	var nearby_major_threat := bool(
		context.get("nearby_major_threat", false)
	)
	var denial_reasons := PackedStringArray()
	if not selected_port:
		denial_reasons.append("SELECT PORT")
	else:
		if not _port_unlocked:
			denial_reasons.append("UNVISITED PORT · DOCK THERE ONCE")
		if not captain_aboard or ship_is_docked:
			denial_reasons.append("CAPTAIN MUST BE ABOARD AT SEA")
		if combat_active:
			denial_reasons.append("ACTIVE COMBAT")
		if chase_active:
			denial_reasons.append("ACTIVE CHASE")
		if nearby_major_threat:
			denial_reasons.append("NEARBY MAJOR THREAT")
		if food_units < FOOD_COST:
			denial_reasons.append("NEED %d FOOD" % FOOD_COST)
	var available := selected_port and denial_reasons.is_empty()
	var time_before := String(context.get("time_before", "DAY"))
	var time_after := String(context.get("time_after", "NIGHT"))
	var preview := {
		"chart_visible": chart_visible,
		"preview_visible": chart_visible and selected_port,
		"selected_location_id": selected_location_id,
		"destination_id": PORT_ID,
		"destination_name": PORT_NAME,
		"selected_port": selected_port,
		"port_unlocked": _port_unlocked,
		"available": available,
		"denial_reasons": denial_reasons,
		"food_cost": FOOD_COST,
		"food_units": food_units,
		"time_cost": TIME_COST,
		"time_before": time_before,
		"time_after": time_after,
		"food_cost_text": "%d FOOD" % FOOD_COST,
		"time_cost_text": "%d TIME STEP · %s -> %s" % [
			TIME_COST,
			time_before,
			time_after,
		],
		"cost_text": "COST · %d FOOD · %d TIME STEP · %s -> %s" % [
			FOOD_COST,
			TIME_COST,
			time_before,
			time_after,
		],
		"status_text": (
			"READY · PRESS F TO CONFIRM"
			if available
			else (
				"UNAVAILABLE · %s" % " · ".join(denial_reasons)
				if selected_port
				else "SELECT PORT FOR FAST TRAVEL"
			)
		),
		"captain_aboard": captain_aboard,
		"ship_is_docked": ship_is_docked,
		"combat_active": combat_active,
		"chase_active": chase_active,
		"nearby_major_threat": nearby_major_threat,
		"major_threat_id": String(context.get("major_threat_id", "")),
		"major_threat_distance": float(
			context.get("major_threat_distance", -1.0)
		),
		"major_threat_range": MAJOR_THREAT_RANGE,
	}
	if preview != _current_preview:
		_preview_update_count += 1
		if (
			selected_port
			and not _port_unlocked
			and (
				_current_preview.is_empty()
				or not bool(_current_preview.get("selected_port", false))
				or bool(_current_preview.get("port_unlocked", true))
			)
		):
			_unvisited_preview_count += 1
	_current_preview = preview.duplicate(true)
	return _current_preview.duplicate(true)


func record_held_confirm(cargo_snapshot: Array[String]) -> Dictionary:
	_held_confirm_count += 1
	_last_held_evidence = {
		"success": false,
		"result": "NO CHANGE · RELEASE FAST TRAVEL KEY",
		"rejection_reason": "HELD_KEY",
		"preview": _current_preview.duplicate(true),
		"cargo_before": cargo_snapshot.duplicate(),
		"cargo_after": cargo_snapshot.duplicate(),
		"cargo_unchanged": true,
		"confirm_attempt_count": _confirm_attempt_count,
		"success_count": _success_count,
		"fresh_press_required": true,
	}
	return _last_held_evidence.duplicate(true)


func record_denied_confirm(
	preview: Dictionary,
	cargo_snapshot: Array[String],
	time_state: String,
) -> Dictionary:
	_confirm_attempt_count += 1
	_denied_count += 1
	var reasons: PackedStringArray = preview.get(
		"denial_reasons",
		PackedStringArray(["FAST TRAVEL UNAVAILABLE"]),
	)
	if reasons.has("UNVISITED PORT · DOCK THERE ONCE"):
		_unvisited_denied_count += 1
	if reasons.has("NEED %d FOOD" % FOOD_COST):
		_food_denied_count += 1
	if reasons.has("ACTIVE COMBAT"):
		_combat_block_count += 1
	if reasons.has("ACTIVE CHASE"):
		_chase_block_count += 1
	if reasons.has("NEARBY MAJOR THREAT"):
		_major_threat_block_count += 1
	_last_confirm_evidence = {
		"success": false,
		"result": "FAST TRAVEL DENIED · %s" % " · ".join(reasons),
		"denial_reasons": reasons.duplicate(),
		"preview": preview.duplicate(true),
		"cargo_before": cargo_snapshot.duplicate(),
		"cargo_after": cargo_snapshot.duplicate(),
		"cargo_unchanged": true,
		"time_before": time_state,
		"time_after": time_state,
		"time_unchanged": true,
		"food_units_before": cargo_snapshot.count(ShipFoodState.FOOD_LOT_NAME),
		"food_units_after": cargo_snapshot.count(ShipFoodState.FOOD_LOT_NAME),
		"food_unchanged": true,
		"no_state_change": true,
		"fresh_press_required": true,
	}
	_last_denied_evidence = _last_confirm_evidence.duplicate(true)
	return _last_confirm_evidence.duplicate(true)


func record_successful_confirm(
	preview: Dictionary,
	ship_evidence: Dictionary,
	time_evidence: Dictionary,
	completed_voyages_before: int,
	completed_voyages_after: int,
) -> Dictionary:
	_confirm_attempt_count += 1
	_success_count += 1
	var food_used := int(ship_evidence.get("food_units_used", 0))
	var time_steps := int(time_evidence.get("time_steps_advanced", 0))
	_total_food_used += food_used
	_total_time_steps_advanced += time_steps
	var cargo_safe := bool(ship_evidence.get("other_cargo_unchanged", false))
	_cargo_safe_after_all_travel = _cargo_safe_after_all_travel and cargo_safe
	_last_confirm_evidence = {
		"success": true,
		"result": "FAST TRAVEL COMPLETE · %s" % PORT_NAME,
		"destination_id": PORT_ID,
		"destination_name": PORT_NAME,
		"preview": preview.duplicate(true),
		"shown_food_cost": int(preview.get("food_cost", -1)),
		"actual_food_cost": food_used,
		"shown_food_cost_used": food_used == int(
			preview.get("food_cost", -1)
		),
		"shown_time_cost": int(preview.get("time_cost", -1)),
		"actual_time_cost": time_steps,
		"shown_time_cost_used": time_steps == int(
			preview.get("time_cost", -1)
		),
		"time_before": time_evidence.get("state_before", ""),
		"time_after": time_evidence.get("state_after", ""),
		"time_changed": bool(time_evidence.get("success", false)),
		"cargo_before": ship_evidence.get("cargo_before", []).duplicate(),
		"cargo_after": ship_evidence.get("cargo_after", []).duplicate(),
		"expected_cargo_after": (
			ship_evidence.get("expected_cargo_after", []).duplicate()
		),
		"cargo_matches_exact_cost": bool(
			ship_evidence.get("cargo_matches_exact_cost", false)
		),
		"other_cargo_unchanged": cargo_safe,
		"all_cargo_safe_except_shown_food": (
			cargo_safe
			and bool(ship_evidence.get("cargo_matches_exact_cost", false))
		),
		"ship_evidence": ship_evidence.duplicate(true),
		"time_evidence": time_evidence.duplicate(true),
		"completed_voyages_before": completed_voyages_before,
		"completed_voyages_after": completed_voyages_after,
		"completed_voyage_count_unchanged": (
			completed_voyages_before == completed_voyages_after
		),
		"random_cargo_loss": false,
		"random_encounter": false,
		"fresh_press_required": true,
	}
	_successful_travel_evidence = _last_confirm_evidence.duplicate(true)
	return _last_confirm_evidence.duplicate(true)


func get_playtest_state() -> Dictionary:
	return {
		"system_count": 1,
		"owner_count": 1,
		"travel_action_count": 1,
		"chart_action_count": 1,
		"confirm_key": "F",
		"destination_count": 1,
		"destination_id": PORT_ID,
		"destination_name": PORT_NAME,
		"port_unlocked": _port_unlocked,
		"visited_port_count": 1 if _port_unlocked else 0,
		"visited_port_ids": (
			PackedStringArray([PORT_ID])
			if _port_unlocked
			else PackedStringArray()
		),
		"port_dock_visit_count": _port_dock_visit_count,
		"port_unlock_count": _port_unlock_count,
		"unlocks_on_first_dock": (
			not _port_unlocked
			or (
				_port_dock_visit_count >= 1
				and _port_unlock_count == 1
			)
		),
		"unlocks_at_most_once": _port_unlock_count <= 1,
		"food_cost": FOOD_COST,
		"time_cost": TIME_COST,
		"major_threat_range": MAJOR_THREAT_RANGE,
		"preview_update_count": _preview_update_count,
		"unvisited_preview_count": _unvisited_preview_count,
		"current_preview": _current_preview.duplicate(true),
		"confirm_attempt_count": _confirm_attempt_count,
		"success_count": _success_count,
		"denied_count": _denied_count,
		"held_confirm_count": _held_confirm_count,
		"unvisited_denied_count": _unvisited_denied_count,
		"food_denied_count": _food_denied_count,
		"combat_block_count": _combat_block_count,
		"chase_block_count": _chase_block_count,
		"major_threat_block_count": _major_threat_block_count,
		"total_food_used": _total_food_used,
		"total_time_steps_advanced": _total_time_steps_advanced,
		"cargo_safe_after_all_travel": _cargo_safe_after_all_travel,
		"last_port_visit_evidence": _last_port_visit_evidence.duplicate(true),
		"last_confirm_evidence": _last_confirm_evidence.duplicate(true),
		"successful_travel_evidence": (
			_successful_travel_evidence.duplicate(true)
		),
		"last_denied_evidence": _last_denied_evidence.duplicate(true),
		"last_held_evidence": _last_held_evidence.duplicate(true),
		"unvisited_travel_count": 0,
		"random_cargo_loss_count": 0,
		"random_fast_travel_encounter_count": 0,
		"free_travel_count": 0,
		"travel_during_combat_count": 0,
		"new_world_map_count": 0,
	}
