class_name DefeatRecoveryState
extends RefCounted

const ShipDamageState := preload("res://scripts/ship_damage.gd")

enum FlowState {
	READY,
	RESULT_OPEN,
	RELEASE_GUARD,
	RECOVERY,
}

const DEFEAT_HULL_THRESHOLD := 0
const SAFE_RETURN_DOCK_ID := "cove"
const FIXED_CARGO_LOT_LOSS := 1
const FIXED_AMMUNITION_UNIT_LOSS := 1
const MINIMUM_RETAINED_CARGO_LOTS := 1
const FIXED_MONEY_LOSS := 0

var _flow_state := FlowState.READY
var _defeat_detection_count := 0
var _encounter_end_count := 0
var _forced_safe_return_count := 0
var _result_screen_open_count := 0
var _result_screen_close_count := 0
var _blocked_input_count := 0
var _salvage_recovery_count := 0
var _repair_recovery_count := 0
var _last_defeat_evidence: Dictionary = {}
var _last_salvage_recovery_evidence: Dictionary = {}
var _last_repair_recovery_evidence: Dictionary = {}


func should_begin_from_naval_damage(damage_evidence: Dictionary) -> bool:
	return (
		_flow_state == FlowState.READY
		and bool(damage_evidence.get("success", false))
		and String(damage_evidence.get("source", ""))
			== ShipDamageState.PIRATE_HUNTER_SOURCE
		and int(damage_evidence.get("damage", 0)) > 0
		and int(damage_evidence.get("hull_before", DEFEAT_HULL_THRESHOLD))
			> DEFEAT_HULL_THRESHOLD
		and int(damage_evidence.get("hull_after", DEFEAT_HULL_THRESHOLD + 1))
			<= DEFEAT_HULL_THRESHOLD
	)


func begin_defeat(
	damage_evidence: Dictionary,
	return_evidence: Dictionary,
	hunter_resolution_evidence: Dictionary,
	cove_storage_before: Array[String],
	cove_storage_after: Array[String],
	cove_storage_slots_before: Array[String],
	cove_storage_slots_after: Array[String],
	money_before: int,
	money_after: int,
) -> Dictionary:
	if not should_begin_from_naval_damage(damage_evidence):
		return {}

	_defeat_detection_count += 1
	if bool(hunter_resolution_evidence.get("resolved", false)):
		_encounter_end_count += 1
	if (
		bool(return_evidence.get("success", false))
		and String(return_evidence.get("return_dock_id", ""))
			== SAFE_RETURN_DOCK_ID
	):
		_forced_safe_return_count += 1
	_result_screen_open_count += 1
	_flow_state = FlowState.RESULT_OPEN

	var cargo_before: Array = return_evidence.get("cargo_before", [])
	var cargo_after: Array = return_evidence.get("cargo_after", [])
	var cargo_slot_loss := cargo_before.size() - cargo_after.size()
	var ammunition_before := int(return_evidence.get("ammunition_before", 0))
	var ammunition_after := int(return_evidence.get("ammunition_after", 0))
	var crew_before := int(return_evidence.get("crew_condition_before", 0))
	var crew_after := int(return_evidence.get("crew_condition_after", 0))
	var hull_before := int(return_evidence.get("hull_before", 0))
	var hull_after := int(return_evidence.get("hull_after", 0))
	var ordinary_cargo_loss_limited := bool(return_evidence.get(
		"ordinary_cargo_loss_limited",
		false,
	))
	var last_timber_lot_preserved := bool(return_evidence.get(
		"last_timber_lot_preserved",
		false,
	))
	_last_defeat_evidence = {
		"success": true,
		"supported_naval_damage": true,
		"damage_source": damage_evidence.get("source", ""),
		"damage_event": damage_evidence.duplicate(true),
		"defeat_hull_threshold": DEFEAT_HULL_THRESHOLD,
		"hull_before_damage": damage_evidence.get("hull_before", 0),
		"hull_after_damage": damage_evidence.get("hull_after", 0),
		"actual_damage": damage_evidence.get("damage", 0),
		"return": return_evidence.duplicate(true),
		"hunter_resolution": hunter_resolution_evidence.duplicate(true),
		"encounter_ended": bool(hunter_resolution_evidence.get(
			"resolved",
			false,
		)),
		"return_dock_id": return_evidence.get("return_dock_id", ""),
		"returned_to_safe_place": (
			String(return_evidence.get("return_dock_id", ""))
				== SAFE_RETURN_DOCK_ID
		),
		"cargo_before": cargo_before.duplicate(),
		"cargo_after": cargo_after.duplicate(),
		"cargo_lost_lots": (
			return_evidence.get("lost_cargo_lots", []) as Array
		).duplicate(),
		"cargo_slot_loss": cargo_slot_loss,
		"ordinary_cargo_lot_loss": int(return_evidence.get(
			"ordinary_cargo_lot_loss",
			0,
		)),
		"ordinary_cargo_loss_limited": ordinary_cargo_loss_limited,
		"timber_lots_before": return_evidence.get("timber_lots_before", 0),
		"timber_lots_after": return_evidence.get("timber_lots_after", 0),
		"last_timber_lot_preserved": last_timber_lot_preserved,
		"ammunition_before": ammunition_before,
		"ammunition_after": ammunition_after,
		"ammunition_loss": ammunition_before - ammunition_after,
		"cargo_before_after_accounted": (
			cargo_before.size() == cargo_after.size() + cargo_slot_loss
		),
		"ammunition_before_after_accounted": (
			ammunition_before
				== ammunition_after
					+ (ammunition_before - ammunition_after)
		),
		"money_before": money_before,
		"money_after": money_after,
		"money_loss": money_before - money_after,
		"hull_before_return": hull_before,
		"hull_after_return": hull_after,
		"hull_retained_damaged": hull_after < int(return_evidence.get(
			"hull_max",
			hull_after,
		)),
		"crew_condition_before_return": crew_before,
		"crew_condition_after_return": crew_after,
		"crew_retained_injured": crew_after < int(return_evidence.get(
			"crew_condition_max",
			crew_after,
		)),
		"crew_restoration_count_before": return_evidence.get(
			"crew_restoration_count_before",
			0,
		),
		"crew_restoration_count_after": return_evidence.get(
			"crew_restoration_count_after",
			0,
		),
		"defeat_return_skipped_crew_restoration": return_evidence.get(
			"defeat_return_skipped_crew_restoration",
			false,
		),
		"cove_storage_before": cove_storage_before.duplicate(),
		"cove_storage_after": cove_storage_after.duplicate(),
		"cove_storage_slots_before": cove_storage_slots_before.duplicate(),
		"cove_storage_slots_after": cove_storage_slots_after.duplicate(),
		"cove_storage_unchanged": (
			cove_storage_before == cove_storage_after
			and cove_storage_slots_before == cove_storage_slots_after
		),
		"fixed_cargo_lot_loss": FIXED_CARGO_LOT_LOSS,
		"fixed_ammunition_unit_loss": FIXED_AMMUNITION_UNIT_LOSS,
		"minimum_retained_cargo_lots": MINIMUM_RETAINED_CARGO_LOTS,
		"fixed_money_loss": FIXED_MONEY_LOSS,
		"cargo_retained": cargo_after.size() >= MINIMUM_RETAINED_CARGO_LOTS,
		"money_retained": money_after > 0,
		"fixed_limited_losses_applied": (
			(
				int(return_evidence.get("ordinary_cargo_lot_loss", 0))
					== FIXED_CARGO_LOT_LOSS
				or ordinary_cargo_loss_limited
			)
			and ammunition_before - ammunition_after
				== FIXED_AMMUNITION_UNIT_LOSS
			and cargo_after.size() >= MINIMUM_RETAINED_CARGO_LOTS
			and money_before == money_after
		),
		"available_safe_losses_applied": (
			(
				int(return_evidence.get("ordinary_cargo_lot_loss", 0))
					== FIXED_CARGO_LOT_LOSS
				or ordinary_cargo_loss_limited
			)
			and ammunition_before - ammunition_after
				== FIXED_AMMUNITION_UNIT_LOSS
			and cargo_after.size() >= MINIMUM_RETAINED_CARGO_LOTS
			and money_before == money_after
			and (
				int(return_evidence.get("timber_lots_before", 0)) == 0
				or last_timber_lot_preserved
			)
		),
		"main_ship_retained": bool(return_evidence.get(
			"main_ship_retained",
			false,
		)),
		"port_access_retained": bool(return_evidence.get(
			"port_access_retained",
			false,
		)),
		"result_screen_text": "",
	}
	_last_defeat_evidence["result_screen_text"] = get_result_text()
	return _last_defeat_evidence.duplicate(true)


func close_result_screen() -> bool:
	if _flow_state != FlowState.RESULT_OPEN:
		return false
	_result_screen_close_count += 1
	_flow_state = FlowState.RELEASE_GUARD
	return true


func complete_release_guard() -> bool:
	if _flow_state != FlowState.RELEASE_GUARD:
		return false
	_flow_state = FlowState.RECOVERY
	return true


func record_blocked_input() -> void:
	if _flow_state == FlowState.RESULT_OPEN:
		_blocked_input_count += 1


func record_existing_salvage_recovery(
	lot_name: String,
	cargo_after: Array[String],
	ship_timber_count: int,
	cargo_limit: int,
) -> void:
	if (
		_defeat_detection_count <= 0
		or lot_name != "TIMBER LOT"
		or ship_timber_count <= 0
		or _salvage_recovery_count > 0
	):
		return
	_salvage_recovery_count += 1
	_last_salvage_recovery_evidence = {
		"success": true,
		"activity": "EXISTING_WRECK_SALVAGE",
		"lot_name": lot_name,
		"cargo_after": cargo_after.duplicate(),
		"ship_timber_count": ship_timber_count,
		"cargo_limit": cargo_limit,
		"normal_cargo_limit_used": cargo_after.size() <= cargo_limit,
		"new_recovery_activity_added": false,
	}


func record_existing_repair_recovery(repair_evidence: Dictionary) -> void:
	if (
		_defeat_detection_count <= 0
		or _repair_recovery_count > 0
		or not bool(repair_evidence.get("success", false))
	):
		return
	_repair_recovery_count += 1
	_last_repair_recovery_evidence = {
		"success": true,
		"activity": "EXISTING_DOCKED_TIMBER_REPAIR",
		"repair": repair_evidence.duplicate(true),
		"hull_before": repair_evidence.get("hull_before", 0),
		"hull_after": repair_evidence.get("hull_after", 0),
		"hull_increased": int(repair_evidence.get("hull_after", 0))
			> int(repair_evidence.get("hull_before", 0)),
		"new_recovery_activity_added": false,
	}


func is_result_open() -> bool:
	return _flow_state == FlowState.RESULT_OPEN


func is_release_guard_pending() -> bool:
	return _flow_state == FlowState.RELEASE_GUARD


func has_defeat_occurred() -> bool:
	return _defeat_detection_count > 0


func get_result_text() -> String:
	if _last_defeat_evidence.is_empty():
		return ""
	var lost_lots: Array = _last_defeat_evidence.get("cargo_lost_lots", [])
	var cargo_loss_text := "NONE"
	if not lost_lots.is_empty():
		var lost_lot_names := PackedStringArray()
		for lost_lot in lost_lots:
			lost_lot_names.append(String(lost_lot))
		cargo_loss_text = ", ".join(lost_lot_names)
	var cargo_limit_text := ""
	if (
		bool(_last_defeat_evidence.get("ordinary_cargo_loss_limited", false))
		and int(_last_defeat_evidence.get("timber_lots_before", 0)) > 0
		and bool(_last_defeat_evidence.get("last_timber_lot_preserved", false))
	):
		cargo_limit_text = (
			"CARGO LOSS LIMITED · LAST REPAIR TIMBER RETAINED\n"
		)
	return (
		"RETURNED TO COVE\n"
		+ "CARGO LOST · %d LOT · %s\n" % [
			int(_last_defeat_evidence.get("ordinary_cargo_lot_loss", 0)),
			cargo_loss_text,
		]
		+ cargo_limit_text
		+ "AMMUNITION LOST · %d UNIT · %d -> %d\n" % [
			int(_last_defeat_evidence.get("ammunition_loss", 0)),
			int(_last_defeat_evidence.get("ammunition_before", 0)),
			int(_last_defeat_evidence.get("ammunition_after", 0)),
		]
		+ "MONEY RETAINED · %d COINS · LOSS %d\n" % [
			int(_last_defeat_evidence.get("money_after", 0)),
			int(_last_defeat_evidence.get("money_loss", 0)),
		]
		+ "HULL RETAINED DAMAGED · %d / %d\n" % [
			int(_last_defeat_evidence.get("hull_after_return", 0)),
			int((_last_defeat_evidence.get("return", {}) as Dictionary).get(
				"hull_max",
				0,
			)),
		]
		+ "CREW RETAINED INJURED · %d / %d\n" % [
			int(_last_defeat_evidence.get("crew_condition_after_return", 0)),
			int((_last_defeat_evidence.get("return", {}) as Dictionary).get(
				"crew_condition_max",
				0,
			)),
		]
		+ "COVE STORAGE · UNCHANGED · %d LOTS\n"
			% (_last_defeat_evidence.get("cove_storage_after", []) as Array).size()
		+ "RECOVERY · SALVAGE TIMBER · RETURN TO A SAFE DOCK · REPAIR"
	)


func get_playtest_state() -> Dictionary:
	var flow_name := String(FlowState.keys()[_flow_state])
	var defeat_evidence := _last_defeat_evidence.duplicate(true)
	return {
		"system_count": 1,
		"owner_count": 1,
		"flow_state": flow_name,
		"defeat_hull_threshold": DEFEAT_HULL_THRESHOLD,
		"supported_naval_damage_source": ShipDamageState.PIRATE_HUNTER_SOURCE,
		"safe_return_dock_id": SAFE_RETURN_DOCK_ID,
		"fixed_cargo_lot_loss": FIXED_CARGO_LOT_LOSS,
		"fixed_ammunition_unit_loss": FIXED_AMMUNITION_UNIT_LOSS,
		"minimum_retained_cargo_lots": MINIMUM_RETAINED_CARGO_LOTS,
		"fixed_money_loss": FIXED_MONEY_LOSS,
		"defeat_detection_count": _defeat_detection_count,
		"encounter_end_count": _encounter_end_count,
		"forced_safe_return_count": _forced_safe_return_count,
		"result_screen_open": is_result_open(),
		"result_screen_open_count": _result_screen_open_count,
		"result_screen_close_count": _result_screen_close_count,
		"release_guard_pending": is_release_guard_pending(),
		"blocked_input_count": _blocked_input_count,
		"cargo_lot_loss_count": int(defeat_evidence.get(
			"ordinary_cargo_lot_loss",
			0,
		)),
		"total_cargo_slot_loss_count": int(defeat_evidence.get(
			"cargo_slot_loss",
			0,
		)),
		"ammunition_unit_loss_count": int(defeat_evidence.get(
			"ammunition_loss",
			0,
		)),
		"money_loss_count": int(defeat_evidence.get("money_loss", 0)),
		"salvage_recovery_count": _salvage_recovery_count,
		"repair_recovery_count": _repair_recovery_count,
		"existing_salvage_recovery_used": _salvage_recovery_count > 0,
		"existing_repair_recovery_used": _repair_recovery_count > 0,
		"last_defeat_evidence": defeat_evidence,
		"last_salvage_recovery_evidence": (
			_last_salvage_recovery_evidence.duplicate(true)
		),
		"last_repair_recovery_evidence": (
			_last_repair_recovery_evidence.duplicate(true)
		),
		"debt_system_count": 0,
		"loan_system_count": 0,
		"main_ship_loss_count": 0,
		"permanent_port_access_loss_count": 0,
		"automatic_save_deletion_count": 0,
		"new_recovery_activity_count": 0,
		"fishing_system_count": 0,
	}
