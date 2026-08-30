class_name DayNightCycle
extends Node

const DAY := "DAY"
const NIGHT := "NIGHT"
const TIME_STATES := [DAY, NIGHT]

var _time_state := DAY
var _arrival_check_count := 0
var _eligible_cove_return_count := 0
var _advance_count := 0
var _uncounted_arrival_count := 0
var _same_dock_arrival_count := 0
var _non_cove_arrival_count := 0
var _already_night_arrival_count := 0
var _last_arrival_evidence: Dictionary = {}
var _successful_advance_evidence: Dictionary = {}


func record_voyage_arrival(voyage_evidence: Dictionary) -> Dictionary:
	_arrival_check_count += 1
	var state_before := _time_state
	var counted := bool(voyage_evidence.get("counted", false))
	var origin_dock_id := String(voyage_evidence.get("origin_dock_id", ""))
	var destination_dock_id := String(
		voyage_evidence.get("destination_dock_id", "")
	)
	var reason := "COUNTED_COVE_RETURN"
	var eligible := (
		counted
		and not origin_dock_id.is_empty()
		and origin_dock_id != destination_dock_id
		and destination_dock_id == "cove"
	)
	if not counted:
		_uncounted_arrival_count += 1
		reason = String(voyage_evidence.get("reason", "UNCOUNTED_ARRIVAL"))
		if reason == "SAME_DOCK_ARRIVAL":
			_same_dock_arrival_count += 1
	elif origin_dock_id == destination_dock_id:
		_same_dock_arrival_count += 1
		reason = "SAME_DOCK_ARRIVAL"
	elif destination_dock_id != "cove":
		_non_cove_arrival_count += 1
		reason = "COUNTED_ARRIVAL_NOT_AT_COVE"

	var advanced := false
	if eligible:
		_eligible_cove_return_count += 1
		if _time_state == DAY:
			_time_state = NIGHT
			_advance_count += 1
			advanced = true
		else:
			_already_night_arrival_count += 1
			reason = "COVE RETURN ALREADY AT NIGHT"

	_last_arrival_evidence = {
		"success": advanced,
		"result": (
			"COVE TIME · DAY -> NIGHT"
			if advanced
			else "COVE TIME UNCHANGED · %s" % _time_state
		),
		"reason": reason,
		"counted_voyage": counted,
		"origin_dock_id": origin_dock_id,
		"destination_dock_id": destination_dock_id,
		"eligible_counted_cove_return": eligible,
		"state_before": state_before,
		"state_after": _time_state,
		"completed_voyage_before": int(
			voyage_evidence.get("completed_voyage_before", 0)
		),
		"completed_voyage_after": int(
			voyage_evidence.get("completed_voyage_after", 0)
		),
		"advanced_exactly_once": _advance_count == 1,
		"uncounted_arrival_did_not_advance": (
			counted or state_before == _time_state
		),
		"same_dock_arrival_did_not_advance": (
			reason != "SAME_DOCK_ARRIVAL" or state_before == _time_state
		),
		"non_cove_arrival_did_not_advance": (
			destination_dock_id == "cove" or state_before == _time_state
		),
	}
	if advanced:
		_successful_advance_evidence = _last_arrival_evidence.duplicate(true)
	return _last_arrival_evidence.duplicate(true)


func get_time_state() -> String:
	return _time_state


func is_day() -> bool:
	return _time_state == DAY


func is_night() -> bool:
	return _time_state == NIGHT


func get_playtest_state() -> Dictionary:
	return {
		"system_count": 1,
		"owner_count": 1,
		"state_count": TIME_STATES.size(),
		"states": TIME_STATES.duplicate(),
		"initial_state": DAY,
		"time_state": _time_state,
		"day_active": is_day(),
		"night_active": is_night(),
		"arrival_check_count": _arrival_check_count,
		"eligible_cove_return_count": _eligible_cove_return_count,
		"advance_count": _advance_count,
		"advances_at_most_once": _advance_count <= 1,
		"uncounted_arrival_count": _uncounted_arrival_count,
		"same_dock_arrival_count": _same_dock_arrival_count,
		"non_cove_arrival_count": _non_cove_arrival_count,
		"already_night_arrival_count": _already_night_arrival_count,
		"advance_rule": "COUNTED DIFFERENT-DOCK VOYAGE RETURN TO COVE",
		"last_arrival_evidence": _last_arrival_evidence.duplicate(true),
		"successful_advance_evidence": (
			_successful_advance_evidence.duplicate(true)
		),
		"calendar_system_count": 0,
		"season_system_count": 0,
		"resident_schedule_system_count": 0,
		"timed_request_failure_system_count": 0,
		"sleep_need_system_count": 0,
		"real_time_wait_system_count": 0,
		"port_unlock_system_count": 0,
		"fast_travel_action_count": 0,
		"fast_travel_food_cost_count": 0,
		"fast_travel_chart_action_count": 0,
		"fast_travel_combat_block_count": 0,
	}
