class_name CrewConditionState
extends RefCounted

const CONDITION_MAX := 100
const CONDITION_START := 100
const SUCCESSFUL_NAVAL_HITS_PER_INJURY := 2
const FIXED_INJURY_AMOUNT := 50
const LOW_CONDITION_THRESHOLD := 50
const LOW_SAILING_TOP_SPEED_MULTIPLIER := 0.8
const SAFE_DOCK_IDS := ["cove", "port"]

var _condition := CONDITION_START
var _successful_naval_damage_count := 0
var _hits_toward_next_injury := 0
var _injury_count := 0
var _restoration_attempt_count := 0
var _restoration_count := 0
var _last_naval_damage_evidence: Dictionary = {}
var _last_injury_evidence: Dictionary = {}
var _last_restoration_attempt_evidence: Dictionary = {}
var _last_successful_restoration_evidence: Dictionary = {}


func record_successful_naval_damage(
		source: String,
		base_sailing_top_speed: float,
) -> Dictionary:
	var condition_before := _condition
	var progress_before := _hits_toward_next_injury
	var low_before := is_low()
	var sailing_top_speed_before := get_sailing_top_speed(
		base_sailing_top_speed
	)
	_successful_naval_damage_count += 1
	_hits_toward_next_injury += 1
	var threshold_reached := (
		_hits_toward_next_injury >= SUCCESSFUL_NAVAL_HITS_PER_INJURY
	)
	if threshold_reached:
		_hits_toward_next_injury = 0
		_condition = maxi(0, _condition - FIXED_INJURY_AMOUNT)
	var injury_applied := _condition < condition_before
	if injury_applied:
		_injury_count += 1
	var low_after := is_low()
	var sailing_top_speed_after := get_sailing_top_speed(
		base_sailing_top_speed
	)
	_last_naval_damage_evidence = {
		"source": source,
		"successful_naval_damage_number": _successful_naval_damage_count,
		"successful_naval_damage_recorded": true,
		"injury_threshold": SUCCESSFUL_NAVAL_HITS_PER_INJURY,
		"threshold_progress_before": progress_before,
		"threshold_progress_after": _hits_toward_next_injury,
		"threshold_reached": threshold_reached,
		"injury_applied": injury_applied,
		"injury_number": _injury_count,
		"fixed_injury_amount": FIXED_INJURY_AMOUNT,
		"condition_before": condition_before,
		"condition_after": _condition,
		"condition_delta": _condition - condition_before,
		"low_before": low_before,
		"low_after": low_after,
		"affected_action": "SAILING_TOP_SPEED",
		"affected_action_count": 1,
		"base_sailing_top_speed": base_sailing_top_speed,
		"sailing_top_speed_before": sailing_top_speed_before,
		"sailing_top_speed_after": sailing_top_speed_after,
		"sailing_top_speed_delta": (
			sailing_top_speed_after - sailing_top_speed_before
		),
		"low_speed_multiplier": LOW_SAILING_TOP_SPEED_MULTIPLIER,
		"action_reduction_started": not low_before and low_after,
		"phase_33_defeat_triggered": false,
	}
	if injury_applied:
		_last_injury_evidence = _last_naval_damage_evidence.duplicate(true)
	return _last_naval_damage_evidence.duplicate(true)


func restore_at_dock(
		dock_id: String,
		base_sailing_top_speed: float,
) -> Dictionary:
	_restoration_attempt_count += 1
	var condition_before := _condition
	var threshold_progress_before := _hits_toward_next_injury
	var safe_dock := SAFE_DOCK_IDS.has(dock_id)
	var sailing_top_speed_before := get_sailing_top_speed(
		base_sailing_top_speed
	)
	var restored := safe_dock and _condition < CONDITION_MAX
	if safe_dock:
		_hits_toward_next_injury = 0
	if restored:
		_condition = CONDITION_MAX
		_restoration_count += 1
	var sailing_top_speed_after := get_sailing_top_speed(
		base_sailing_top_speed
	)
	_last_restoration_attempt_evidence = {
		"dock_id": dock_id,
		"safe_dock": safe_dock,
		"safe_dock_ids": SAFE_DOCK_IDS.duplicate(),
		"automatic": true,
		"restored": restored,
		"restoration_number": _restoration_count,
		"condition_before": condition_before,
		"condition_after": _condition,
		"condition_restored": _condition - condition_before,
		"restored_to_full": restored and _condition == CONDITION_MAX,
		"threshold_progress_before": threshold_progress_before,
		"threshold_progress_after": _hits_toward_next_injury,
		"threshold_progress_cleared_at_safe_dock": (
			not safe_dock or _hits_toward_next_injury == 0
		),
		"affected_action": "SAILING_TOP_SPEED",
		"affected_action_count": 1,
		"base_sailing_top_speed": base_sailing_top_speed,
		"sailing_top_speed_before": sailing_top_speed_before,
		"sailing_top_speed_after": sailing_top_speed_after,
		"action_restored_to_normal": (
			restored
			and sailing_top_speed_after == base_sailing_top_speed
			and sailing_top_speed_after > sailing_top_speed_before
		),
		"phase_33_recovery_triggered": false,
	}
	if restored:
		_last_successful_restoration_evidence = (
			_last_restoration_attempt_evidence.duplicate(true)
		)
	return _last_restoration_attempt_evidence.duplicate(true)


func get_condition() -> int:
	return _condition


func is_low() -> bool:
	return _condition <= LOW_CONDITION_THRESHOLD


func get_sailing_top_speed(base_sailing_top_speed: float) -> float:
	if is_low():
		return base_sailing_top_speed * LOW_SAILING_TOP_SPEED_MULTIPLIER
	return base_sailing_top_speed


func get_status_text(base_sailing_top_speed: float) -> String:
	var effective_top_speed := get_sailing_top_speed(base_sailing_top_speed)
	if is_low():
		return "LOW · SAILING TOP SPEED %.0f -> %.0f" % [
			base_sailing_top_speed,
			effective_top_speed,
		]
	if not _last_successful_restoration_evidence.is_empty():
		return "RESTORED AT %s · SAILING TOP SPEED %.0f" % [
			String(_last_successful_restoration_evidence["dock_id"]).to_upper(),
			effective_top_speed,
		]
	return "READY · SAILING TOP SPEED %.0f" % effective_top_speed


func get_playtest_state(base_sailing_top_speed: float) -> Dictionary:
	var effective_top_speed := get_sailing_top_speed(base_sailing_top_speed)
	return {
		"system_count": 1,
		"owner_count": 1,
		"aggregate_value_count": 1,
		"condition": _condition,
		"condition_max": CONDITION_MAX,
		"condition_start": CONDITION_START,
		"full": _condition == CONDITION_MAX,
		"low": is_low(),
		"low_condition_threshold": LOW_CONDITION_THRESHOLD,
		"successful_naval_hits_per_injury": (
			SUCCESSFUL_NAVAL_HITS_PER_INJURY
		),
		"fixed_injury_amount": FIXED_INJURY_AMOUNT,
		"successful_naval_damage_count": _successful_naval_damage_count,
		"hits_toward_next_injury": _hits_toward_next_injury,
		"injury_count": _injury_count,
		"restoration_attempt_count": _restoration_attempt_count,
		"restoration_count": _restoration_count,
		"safe_dock_ids": SAFE_DOCK_IDS.duplicate(),
		"safe_dock_count": SAFE_DOCK_IDS.size(),
		"automatic_safe_dock_restoration": true,
		"affected_action": "SAILING_TOP_SPEED",
		"affected_action_count": 1,
		"base_sailing_top_speed": base_sailing_top_speed,
		"effective_sailing_top_speed": effective_top_speed,
		"normal_sailing_top_speed": base_sailing_top_speed,
		"low_sailing_top_speed": (
			base_sailing_top_speed * LOW_SAILING_TOP_SPEED_MULTIPLIER
		),
		"low_speed_multiplier": LOW_SAILING_TOP_SPEED_MULTIPLIER,
		"status_text": get_status_text(base_sailing_top_speed),
		"last_naval_damage_evidence": (
			_last_naval_damage_evidence.duplicate(true)
		),
		"last_injury_evidence": _last_injury_evidence.duplicate(true),
		"last_restoration_attempt_evidence": (
			_last_restoration_attempt_evidence.duplicate(true)
		),
		"last_successful_restoration_evidence": (
			_last_successful_restoration_evidence.duplicate(true)
		),
		"individual_crew_member_count": 0,
		"officer_injury_count": 0,
		"wage_system_count": 0,
		"mutiny_system_count": 0,
		"crew_schedule_system_count": 0,
		"recruitment_market_count": 0,
		"separate_injury_type_count": 0,
		"medical_supply_system_count": 0,
		"new_crew_task_count": 0,
		"player_defeat_detection_count": 0,
		"encounter_end_on_player_defeat_count": 0,
		"forced_safe_return_count": 0,
		"defeat_cargo_loss_count": 0,
		"defeat_ammunition_loss_count": 0,
		"defeat_money_loss_count": 0,
		"defeat_result_screen_count": 0,
		"salvage_recovery_trigger_count": 0,
		"phase_33_recovery_behavior_count": 0,
	}
