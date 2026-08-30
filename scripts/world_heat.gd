class_name WorldHeatState
extends RefCounted

const HEAT_STEP := 1
const DISPLAY_MAX_HEAT := 10
const SAVE_VERSION := 1

var _current_heat := 0
var _peaceful_target_ids_hit: Array[String] = []
var _peaceful_attack_in_current_voyage := false
var _successful_peaceful_hit_count := 0
var _first_peaceful_hit_count := 0
var _repeat_peaceful_hit_count := 0
var _non_peaceful_hit_count := 0
var _total_heat_added := 0
var _total_heat_removed_by_voyage_decay := 0
var _first_hit_exact_match_count := 0
var _repeat_hit_no_heat_match_count := 0
var _completed_voyage_update_count := 0
var _voyage_decay_count := 0
var _completed_voyage_without_peaceful_attack_count := 0
var _last_completed_voyage := 0
var _last_result := "WORLD HEAT CALM"
var _last_hit_evidence: Dictionary = {}
var _last_first_hit_evidence: Dictionary = {}
var _last_repeat_hit_evidence: Dictionary = {}
var _last_voyage_evidence: Dictionary = {}
var _load_count := 0
var _last_load_evidence: Dictionary = {}


func get_current_heat() -> int:
	return _current_heat


func get_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"current_heat": _current_heat,
		"peaceful_target_ids_hit": _peaceful_target_ids_hit.duplicate(),
		"peaceful_attack_in_current_voyage": (
			_peaceful_attack_in_current_voyage
		),
		"successful_peaceful_hit_count": _successful_peaceful_hit_count,
		"first_peaceful_hit_count": _first_peaceful_hit_count,
		"repeat_peaceful_hit_count": _repeat_peaceful_hit_count,
		"non_peaceful_hit_count": _non_peaceful_hit_count,
		"total_heat_added": _total_heat_added,
		"total_heat_removed_by_voyage_decay": (
			_total_heat_removed_by_voyage_decay
		),
		"first_hit_exact_match_count": _first_hit_exact_match_count,
		"repeat_hit_no_heat_match_count": _repeat_hit_no_heat_match_count,
		"completed_voyage_update_count": _completed_voyage_update_count,
		"voyage_decay_count": _voyage_decay_count,
		"completed_voyage_without_peaceful_attack_count": (
			_completed_voyage_without_peaceful_attack_count
		),
		"last_completed_voyage": _last_completed_voyage,
		"last_result": _last_result,
	}


func validate_save_data(
	save_data: Dictionary,
	known_peaceful_target_ids: Array[String],
) -> Dictionary:
	return _validate_save_data(save_data, known_peaceful_target_ids)


func load_save_data(
	save_data: Dictionary,
	known_peaceful_target_ids: Array[String],
	rebased_completed_voyage: int,
) -> Dictionary:
	var state_before: Dictionary = get_save_data()
	var validation: Dictionary = _validate_save_data(
		save_data,
		known_peaceful_target_ids,
	)
	if rebased_completed_voyage < 0:
		validation = {"valid": false, "reason": "NEGATIVE_REBASE_VOYAGE"}
	elif (
		bool(validation["valid"])
		and rebased_completed_voyage
			> save_data.get("completed_voyage_update_count", -1)
	):
		validation = {
			"valid": false,
			"reason": "REBASE_VOYAGE_EXCEEDS_HEAT_UPDATE_COUNT",
		}
	if not bool(validation["valid"]):
		_last_load_evidence = {
			"success": false,
			"result": "WORLD HEAT LOAD DENIED",
			"reason": validation["reason"],
			"state_before": state_before,
			"state_after": get_save_data(),
			"no_state_change": state_before == get_save_data(),
			"load_count": _load_count,
		}
		return _last_load_evidence.duplicate(true)

	var loaded_target_ids: Array[String] = []
	for target_id_value in save_data["peaceful_target_ids_hit"]:
		loaded_target_ids.append(target_id_value)
	var loaded_current_heat: int = save_data["current_heat"]
	var loaded_attack_flag: bool = save_data[
		"peaceful_attack_in_current_voyage"
	]
	var expected_rebased_snapshot: Dictionary = save_data.duplicate(true)
	expected_rebased_snapshot["last_completed_voyage"] = (
		rebased_completed_voyage
	)
	expected_rebased_snapshot["peaceful_attack_in_current_voyage"] = (
		loaded_attack_flag
	)

	_current_heat = loaded_current_heat
	_peaceful_target_ids_hit = loaded_target_ids
	_peaceful_attack_in_current_voyage = loaded_attack_flag
	_successful_peaceful_hit_count = save_data["successful_peaceful_hit_count"]
	_first_peaceful_hit_count = save_data["first_peaceful_hit_count"]
	_repeat_peaceful_hit_count = save_data["repeat_peaceful_hit_count"]
	_non_peaceful_hit_count = save_data["non_peaceful_hit_count"]
	_total_heat_added = save_data["total_heat_added"]
	_total_heat_removed_by_voyage_decay = (
		save_data["total_heat_removed_by_voyage_decay"]
	)
	_first_hit_exact_match_count = save_data["first_hit_exact_match_count"]
	_repeat_hit_no_heat_match_count = (
		save_data["repeat_hit_no_heat_match_count"]
	)
	_completed_voyage_update_count = save_data["completed_voyage_update_count"]
	_voyage_decay_count = save_data["voyage_decay_count"]
	_completed_voyage_without_peaceful_attack_count = (
		save_data["completed_voyage_without_peaceful_attack_count"]
	)
	_last_completed_voyage = rebased_completed_voyage
	_last_result = save_data["last_result"]
	_last_hit_evidence = {}
	_last_first_hit_evidence = {}
	_last_repeat_hit_evidence = {}
	_last_voyage_evidence = {}
	_load_count += 1
	var state_after: Dictionary = get_save_data()
	_last_load_evidence = {
		"success": true,
		"result": "WORLD HEAT STATE LOADED",
		"state_before": state_before,
		"requested_snapshot": save_data.duplicate(true),
		"expected_rebased_snapshot": expected_rebased_snapshot,
		"state_after": state_after,
		"rebased_snapshot_equality_holds": (
			state_after == expected_rebased_snapshot
		),
		"current_heat_restored": (
			_current_heat == save_data["current_heat"]
		),
		"first_hit_target_ids_restored": (
			_peaceful_target_ids_hit
				== (save_data["peaceful_target_ids_hit"] as Array)
		),
		"current_voyage_attack_flag_restored": (
			_peaceful_attack_in_current_voyage
				== loaded_attack_flag
		),
		"saved_voyage_cursor": save_data["last_completed_voyage"],
		"rebased_voyage_cursor": _last_completed_voyage,
		"voyage_cursor_rebased_to_current_world": (
			_last_completed_voyage == rebased_completed_voyage
		),
		"accounting_holds_after_load": (
			_current_heat
				== _total_heat_added - _total_heat_removed_by_voyage_decay
		),
		"load_count": _load_count,
	}
	return _last_load_evidence.duplicate(true)


func get_attack_preview(
	target_id: String,
	peaceful: bool,
	estimated_heat_cost: int,
) -> Dictionary:
	var normalized_cost := maxi(0, estimated_heat_cost)
	var first_hit_already_recorded := _peaceful_target_ids_hit.has(target_id)
	var estimated_increase := (
		normalized_cost
		if peaceful and not first_hit_already_recorded
		else 0
	)
	return {
		"target_id": target_id,
		"peaceful": peaceful,
		"authored_estimated_heat_cost": normalized_cost,
		"first_hit_already_recorded": first_hit_already_recorded,
		"estimated_heat_increase": estimated_increase,
		"heat_before": _current_heat,
		"heat_after": _current_heat + estimated_increase,
		"first_successful_hit_required": true,
		"preview_does_not_apply_heat": true,
		"result": _get_preview_result(
			peaceful,
			first_hit_already_recorded,
			estimated_increase,
		),
	}


func record_successful_hit(
	target_id: String,
	peaceful: bool,
	estimated_heat_cost: int,
) -> Dictionary:
	var heat_before := _current_heat
	var normalized_cost := maxi(0, estimated_heat_cost)
	var first_hit_already_recorded := _peaceful_target_ids_hit.has(target_id)
	var applied_heat := 0
	var result := "NON-PEACEFUL TARGET · HEAT UNCHANGED"
	if peaceful:
		_successful_peaceful_hit_count += 1
		_peaceful_attack_in_current_voyage = true
		if first_hit_already_recorded:
			_repeat_peaceful_hit_count += 1
			result = "PEACEFUL TARGET · FIRST HIT ALREADY COUNTED · HEAT UNCHANGED"
		else:
			_peaceful_target_ids_hit.append(target_id)
			_first_peaceful_hit_count += 1
			applied_heat = normalized_cost
			_current_heat += applied_heat
			_total_heat_added += applied_heat
			_first_hit_exact_match_count += 1
			result = "PEACEFUL TARGET · FIRST HIT · HEAT +%d" % applied_heat
		if first_hit_already_recorded:
			_repeat_hit_no_heat_match_count += 1
	else:
		_non_peaceful_hit_count += 1

	_last_hit_evidence = {
		"success": true,
		"target_id": target_id,
		"peaceful": peaceful,
		"successful_target_hit": true,
		"authored_estimated_heat_cost": normalized_cost,
		"first_hit_already_recorded_before": first_hit_already_recorded,
		"first_successful_hit": peaceful and not first_hit_already_recorded,
		"later_hit_on_same_peaceful_target": (
			peaceful and first_hit_already_recorded
		),
		"heat_before": heat_before,
		"heat_after": _current_heat,
		"heat_delta": _current_heat - heat_before,
		"shown_amount_applied_exactly": (
			not peaceful
			or first_hit_already_recorded
			or _current_heat - heat_before == normalized_cost
		),
		"later_hit_added_no_heat": (
			not peaceful
			or not first_hit_already_recorded
			or _current_heat == heat_before
		),
		"peaceful_attack_in_current_voyage": (
			_peaceful_attack_in_current_voyage
		),
		"result": result,
	}
	_last_result = result
	if peaceful and not first_hit_already_recorded:
		_last_first_hit_evidence = _last_hit_evidence.duplicate(true)
	elif peaceful:
		_last_repeat_hit_evidence = _last_hit_evidence.duplicate(true)
	return _last_hit_evidence.duplicate(true)


func record_completed_voyage(completed_voyage: int) -> Dictionary:
	var heat_before := _current_heat
	if completed_voyage <= _last_completed_voyage:
		return {
			"success": false,
			"result": "VOYAGE HEAT UPDATE ALREADY RECORDED",
			"completed_voyage": completed_voyage,
			"last_completed_voyage": _last_completed_voyage,
			"heat_before": heat_before,
			"heat_after": _current_heat,
			"heat_delta": 0,
			"no_state_change": true,
		}

	var had_peaceful_attack := _peaceful_attack_in_current_voyage
	var decay_applied := 0
	if not had_peaceful_attack:
		_completed_voyage_without_peaceful_attack_count += 1
		decay_applied = mini(HEAT_STEP, _current_heat)
		_current_heat -= decay_applied
		_total_heat_removed_by_voyage_decay += decay_applied
		if decay_applied > 0:
			_voyage_decay_count += 1
	_completed_voyage_update_count += 1
	_last_completed_voyage = completed_voyage
	_peaceful_attack_in_current_voyage = false
	_last_voyage_evidence = {
		"success": true,
		"result": (
			"PEACEFUL ATTACK THIS VOYAGE · HEAT HELD"
			if had_peaceful_attack
			else "NO PEACEFUL ATTACK · HEAT -%d" % decay_applied
		),
		"completed_voyage": completed_voyage,
		"peaceful_attack_during_completed_voyage": had_peaceful_attack,
		"heat_before": heat_before,
		"heat_after": _current_heat,
		"heat_delta": _current_heat - heat_before,
		"decay_step": HEAT_STEP,
		"decay_applied": decay_applied,
		"decayed_exactly_one_step_when_possible": (
			had_peaceful_attack
			or heat_before == 0
			or heat_before - _current_heat == HEAT_STEP
		),
		"heat_held_after_peaceful_attack_voyage": (
			not had_peaceful_attack or _current_heat == heat_before
		),
		"next_voyage_peaceful_attack_reset": (
			not _peaceful_attack_in_current_voyage
		),
	}
	_last_result = String(_last_voyage_evidence["result"])
	return _last_voyage_evidence.duplicate(true)


func get_playtest_state() -> Dictionary:
	return {
		"system_count": 1,
		"meter_count": 1,
		"scope": "FULL_WORLD",
		"current_heat": _current_heat,
		"display_max_heat": DISPLAY_MAX_HEAT,
		"heat_step": HEAT_STEP,
		"heat_nonnegative": _current_heat >= 0,
		"last_result": _last_result,
		"peaceful_target_ids_hit": _peaceful_target_ids_hit.duplicate(),
		"peaceful_target_first_hit_count": _peaceful_target_ids_hit.size(),
		"successful_peaceful_hit_count": _successful_peaceful_hit_count,
		"first_peaceful_hit_count": _first_peaceful_hit_count,
		"repeat_peaceful_hit_count": _repeat_peaceful_hit_count,
		"non_peaceful_hit_count": _non_peaceful_hit_count,
		"total_heat_added": _total_heat_added,
		"total_heat_removed_by_voyage_decay": (
			_total_heat_removed_by_voyage_decay
		),
		"first_hit_exact_match_count": _first_hit_exact_match_count,
		"repeat_hit_no_heat_match_count": _repeat_hit_no_heat_match_count,
		"all_first_hits_matched_shown_amount": (
			_first_hit_exact_match_count == _first_peaceful_hit_count
		),
		"all_repeat_hits_added_no_heat": (
			_repeat_hit_no_heat_match_count == _repeat_peaceful_hit_count
		),
		"heat_accounting_holds": (
			_current_heat
				== _total_heat_added - _total_heat_removed_by_voyage_decay
		),
		"peaceful_attack_in_current_voyage": (
			_peaceful_attack_in_current_voyage
		),
		"completed_voyage_update_count": _completed_voyage_update_count,
		"completed_voyage_without_peaceful_attack_count": (
			_completed_voyage_without_peaceful_attack_count
		),
		"voyage_decay_count": _voyage_decay_count,
		"last_completed_voyage": _last_completed_voyage,
		"last_hit_evidence": _last_hit_evidence.duplicate(true),
		"last_first_hit_evidence": _last_first_hit_evidence.duplicate(true),
		"last_repeat_hit_evidence": _last_repeat_hit_evidence.duplicate(true),
		"last_voyage_evidence": _last_voyage_evidence.duplicate(true),
		"save_version": SAVE_VERSION,
		"load_count": _load_count,
		"last_load_evidence": _last_load_evidence.duplicate(true),
		"later_hits_same_target_add_no_heat": (
			_repeat_hit_no_heat_match_count == _repeat_peaceful_hit_count
		),
		"pirate_hunter_system_count": 0,
		"pirate_hunter_warning_count": 0,
		"pirate_hunter_chase_count": 0,
		"pirate_hunter_attack_count": 0,
		"port_service_refusal_count": 0,
		"per_nation_heat_meter_count": 0,
		"law_system_count": 0,
		"bribe_system_count": 0,
		"wanted_level_system_count": 0,
		"resident_reaction_count": 0,
	}


func _validate_save_data(
	save_data: Dictionary,
	known_peaceful_target_ids: Array[String],
) -> Dictionary:
	var required_keys := [
		"version",
		"current_heat",
		"peaceful_target_ids_hit",
		"peaceful_attack_in_current_voyage",
		"successful_peaceful_hit_count",
		"first_peaceful_hit_count",
		"repeat_peaceful_hit_count",
		"non_peaceful_hit_count",
		"total_heat_added",
		"total_heat_removed_by_voyage_decay",
		"first_hit_exact_match_count",
		"repeat_hit_no_heat_match_count",
		"completed_voyage_update_count",
		"voyage_decay_count",
		"completed_voyage_without_peaceful_attack_count",
		"last_completed_voyage",
		"last_result",
	]
	if save_data.size() != required_keys.size():
		return {"valid": false, "reason": "UNEXPECTED_FIELD_COUNT"}
	for required_key in required_keys:
		if not save_data.has(required_key):
			return {
				"valid": false,
				"reason": "MISSING_%s" % String(required_key).to_upper(),
			}
	var exact_int_keys := [
		"version",
		"current_heat",
		"successful_peaceful_hit_count",
		"first_peaceful_hit_count",
		"repeat_peaceful_hit_count",
		"non_peaceful_hit_count",
		"total_heat_added",
		"total_heat_removed_by_voyage_decay",
		"first_hit_exact_match_count",
		"repeat_hit_no_heat_match_count",
		"completed_voyage_update_count",
		"voyage_decay_count",
		"completed_voyage_without_peaceful_attack_count",
		"last_completed_voyage",
	]
	for exact_int_key in exact_int_keys:
		if typeof(save_data[exact_int_key]) != TYPE_INT:
			return {
				"valid": false,
				"reason": "INVALID_TYPE_%s" % (
					String(exact_int_key).to_upper()
				),
			}
	if typeof(save_data["peaceful_attack_in_current_voyage"]) != TYPE_BOOL:
		return {"valid": false, "reason": "INVALID_TYPE_ATTACK_FLAG"}
	if typeof(save_data["last_result"]) != TYPE_STRING:
		return {"valid": false, "reason": "INVALID_TYPE_LAST_RESULT"}
	if typeof(save_data["peaceful_target_ids_hit"]) != TYPE_ARRAY:
		return {"valid": false, "reason": "INVALID_TYPE_TARGET_IDS"}
	if save_data["version"] != SAVE_VERSION:
		return {"valid": false, "reason": "UNSUPPORTED_VERSION"}
	if save_data["current_heat"] < 0:
		return {"valid": false, "reason": "NEGATIVE_HEAT"}
	var unique_target_ids: Array[String] = []
	for target_id_value in save_data["peaceful_target_ids_hit"]:
		if typeof(target_id_value) != TYPE_STRING:
			return {"valid": false, "reason": "INVALID_TARGET_ID_TYPE"}
		var target_id: String = target_id_value
		if target_id.is_empty() or unique_target_ids.has(target_id):
			return {"valid": false, "reason": "INVALID_TARGET_IDENTITY"}
		if not known_peaceful_target_ids.has(target_id):
			return {"valid": false, "reason": "UNKNOWN_PEACEFUL_TARGET_ID"}
		unique_target_ids.append(target_id)
	for counter_key in exact_int_keys:
		if counter_key == "version":
			continue
		if save_data[counter_key] < 0:
			return {
				"valid": false,
				"reason": "NEGATIVE_%s" % String(counter_key).to_upper(),
			}
	if save_data["first_peaceful_hit_count"] != unique_target_ids.size():
		return {"valid": false, "reason": "FIRST_HIT_IDENTITY_MISMATCH"}
	if save_data["successful_peaceful_hit_count"] != (
		save_data["first_peaceful_hit_count"]
		+ save_data["repeat_peaceful_hit_count"]
	):
		return {"valid": false, "reason": "PEACEFUL_HIT_COUNT_MISMATCH"}
	if save_data["first_hit_exact_match_count"] != (
		save_data["first_peaceful_hit_count"]
	):
		return {"valid": false, "reason": "FIRST_HIT_EXACT_COUNT_MISMATCH"}
	if save_data["repeat_hit_no_heat_match_count"] != (
		save_data["repeat_peaceful_hit_count"]
	):
		return {"valid": false, "reason": "REPEAT_HIT_EXACT_COUNT_MISMATCH"}
	if save_data["current_heat"] != (
		save_data["total_heat_added"]
		- save_data["total_heat_removed_by_voyage_decay"]
	):
		return {"valid": false, "reason": "HEAT_ACCOUNTING_MISMATCH"}
	if save_data["voyage_decay_count"] > (
		save_data["completed_voyage_without_peaceful_attack_count"]
	):
		return {"valid": false, "reason": "VOYAGE_DECAY_COUNT_MISMATCH"}
	if save_data["completed_voyage_without_peaceful_attack_count"] > (
		save_data["completed_voyage_update_count"]
	):
		return {"valid": false, "reason": "SAFE_VOYAGE_COUNT_MISMATCH"}
	if save_data["total_heat_removed_by_voyage_decay"] != (
		save_data["voyage_decay_count"] * HEAT_STEP
	):
		return {"valid": false, "reason": "VOYAGE_DECAY_ACCOUNTING_MISMATCH"}
	if save_data["last_completed_voyage"] > (
		save_data["completed_voyage_update_count"]
	):
		return {"valid": false, "reason": "VOYAGE_CURSOR_COUNT_MISMATCH"}
	if save_data["last_result"].is_empty():
		return {"valid": false, "reason": "EMPTY_LAST_RESULT"}
	return {"valid": true, "reason": "VALID"}


func _get_preview_result(
	peaceful: bool,
	first_hit_already_recorded: bool,
	estimated_increase: int,
) -> String:
	if not peaceful:
		return "NOT PEACEFUL · NO HEAT EXPECTED"
	if first_hit_already_recorded:
		return "FIRST HIT ALREADY COUNTED · NO MORE HEAT"
	return "PEACEFUL · FIRST HIT HEAT +%d" % estimated_increase
