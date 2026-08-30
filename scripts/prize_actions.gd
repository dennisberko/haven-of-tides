class_name PrizeActionState
extends RefCounted

const PRIZE_CARGO := "CARGO"
const PRIZE_CANNONS := "CANNONS"
const PRIZE_REPAIR_MATERIALS := "REPAIR_MATERIALS"
const PRIZE_TRADE_RECORDS := "TRADE_RECORDS"
const PRIZE_TYPES := [
	PRIZE_CARGO,
	PRIZE_CANNONS,
	PRIZE_REPAIR_MATERIALS,
	PRIZE_TRADE_RECORDS,
]
const PRIZE_KEYS := {
	PRIZE_CARGO: "1",
	PRIZE_CANNONS: "2",
	PRIZE_REPAIR_MATERIALS: "3",
	PRIZE_TRADE_RECORDS: "4",
}
const PRIZE_DISPLAY_NAMES := {
	PRIZE_CARGO: "CAPTURED CARGO",
	PRIZE_CANNONS: "USABLE CANNONS · SELLABLE CARGO",
	PRIZE_REPAIR_MATERIALS: "REPAIR MATERIALS · TIMBER LOT",
	PRIZE_TRADE_RECORDS: "TRADE RECORDS · PORT JOURNAL ENTRY",
}
const CAPTURED_CARGO_LOT_NAME := "CAPTURED MERCHANT CARGO LOT"
const CANNON_CARGO_LOT_NAME := "USABLE CANNONS LOT · SELLABLE CARGO"
const REPAIR_MATERIAL_CARGO_LOT_NAME := "TIMBER LOT"
const DEFAULT_ACTION_LIMIT := 2
const LOW_HULL_ACTION_LIMIT := 1
const LOW_HULL_THRESHOLD_PERCENT := 50

var screen_open := false
var active_target_id := ""
var active_target_name := ""
var action_limit := 0
var actions_remaining := 0
var hull_current_at_open := 0
var hull_max_at_open := 0
var low_hull_reduction_applied := false
var selected_prize_types: Array[String] = []
var awarded_cargo_lots: Array[String] = []
var cumulative_awarded_cargo_lot_count := 0
var trade_records_taken := false
var screen_open_count := 0
var screen_open_counts_by_target: Dictionary = {}
var screen_close_count := 0
var successful_selection_count := 0
var denied_selection_count := 0
var held_input_count := 0
var exhausted_rejection_count := 0
var cargo_full_rejection_count := 0
var already_taken_rejection_count := 0
var last_result := "NO PRIZE SCREEN"
var last_open_evidence: Dictionary = {}
var last_selection_evidence: Dictionary = {}
var last_denied_selection_evidence: Dictionary = {}
var last_held_input_evidence: Dictionary = {}
var _cargo_snapshot_at_open: Array[String] = []
var _journal_snapshot_at_open: Dictionary = {}


func open_for_victory(
	target_id: String,
	target_name: String,
	hull_current: int,
	hull_max: int,
	cargo_lots: Array[String],
	journal_entry: Dictionary,
) -> Dictionary:
	if screen_open:
		return {
			"success": false,
			"result": "PRIZE SCREEN ALREADY OPEN",
			"screen_open_count": screen_open_count,
			"no_state_change": true,
		}
	var target_open_count := int(screen_open_counts_by_target.get(target_id, 0))
	if target_open_count >= 1:
		return {
			"success": false,
			"result": "TARGET PRIZE VICTORY ALREADY OPENED",
			"target_id": target_id,
			"target_screen_open_count": target_open_count,
			"screen_open_count": screen_open_count,
			"no_state_change": true,
		}
	screen_open = true
	active_target_id = target_id
	active_target_name = target_name
	hull_current_at_open = hull_current
	hull_max_at_open = hull_max
	var hull_percent := 0
	if hull_max_at_open > 0:
		hull_percent = int(floor(
			100.0 * float(hull_current_at_open) / float(hull_max_at_open)
		))
	low_hull_reduction_applied = hull_percent <= LOW_HULL_THRESHOLD_PERCENT
	action_limit = (
		LOW_HULL_ACTION_LIMIT
		if low_hull_reduction_applied
		else DEFAULT_ACTION_LIMIT
	)
	actions_remaining = action_limit
	selected_prize_types.clear()
	awarded_cargo_lots.clear()
	trade_records_taken = false
	_cargo_snapshot_at_open = cargo_lots.duplicate()
	_journal_snapshot_at_open = journal_entry.duplicate(true)
	screen_open_count += 1
	screen_open_counts_by_target[target_id] = target_open_count + 1
	last_result = "CHOOSE %d PRIZE ACTIONS" % action_limit
	last_selection_evidence = {}
	last_denied_selection_evidence = {}
	last_held_input_evidence = {}
	last_open_evidence = {
		"success": true,
		"result": last_result,
		"target_id": active_target_id,
		"target_name": active_target_name,
		"fight_victory_required": true,
		"screen_open_count": screen_open_count,
		"target_screen_open_count": int(
			screen_open_counts_by_target[target_id]
		),
		"prize_type_count": PRIZE_TYPES.size(),
		"prize_types": PRIZE_TYPES.duplicate(),
		"action_limit": action_limit,
		"actions_remaining": actions_remaining,
		"actions_visible_before_first_choice": true,
		"hull_current": hull_current_at_open,
		"hull_max": hull_max_at_open,
		"hull_percent": hull_percent,
		"low_hull_threshold_percent": LOW_HULL_THRESHOLD_PERCENT,
		"low_hull_reduction_applied": low_hull_reduction_applied,
		"default_action_limit": DEFAULT_ACTION_LIMIT,
		"low_hull_action_limit": LOW_HULL_ACTION_LIMIT,
		"cargo_at_open": _cargo_snapshot_at_open.duplicate(),
		"journal_at_open": _journal_snapshot_at_open.duplicate(true),
	}
	return last_open_evidence.duplicate(true)


func can_attempt_selection(prize_type: String) -> bool:
	return screen_open and PRIZE_TYPES.has(prize_type)


func record_successful_selection(
	prize_type: String,
	cargo_before: Array[String],
	cargo_after: Array[String],
	journal_before: Dictionary,
	journal_after: Dictionary,
) -> Dictionary:
	var actions_before := actions_remaining
	if (
		not can_attempt_selection(prize_type)
		or actions_remaining <= 0
		or selected_prize_types.has(prize_type)
	):
		return record_denied_selection(
			prize_type,
			"INVALID SUCCESS RECORD",
			cargo_before,
			journal_before,
		)
	selected_prize_types.append(prize_type)
	actions_remaining -= 1
	successful_selection_count += 1
	var awarded_lot := get_cargo_lot_name(prize_type)
	if not awarded_lot.is_empty():
		awarded_cargo_lots.append(awarded_lot)
		cumulative_awarded_cargo_lot_count += 1
	if prize_type == PRIZE_TRADE_RECORDS:
		trade_records_taken = true
	last_result = "TOOK %s · %d ACTIONS REMAIN" % [
		String(PRIZE_DISPLAY_NAMES[prize_type]),
		actions_remaining,
	]
	last_selection_evidence = {
		"success": true,
		"result": last_result,
		"prize_type": prize_type,
		"display_name": PRIZE_DISPLAY_NAMES[prize_type],
		"selection_number": successful_selection_count,
		"actions_before": actions_before,
		"actions_after": actions_remaining,
		"action_delta": actions_remaining - actions_before,
		"exactly_one_action_used": actions_remaining == actions_before - 1,
		"cargo_before": cargo_before.duplicate(),
		"cargo_after": cargo_after.duplicate(),
		"cargo_delta": cargo_after.size() - cargo_before.size(),
		"awarded_cargo_lot": awarded_lot,
		"cannon_is_sellable_cargo": prize_type == PRIZE_CANNONS,
		"repair_material_is_timber": (
			prize_type == PRIZE_REPAIR_MATERIALS
			and awarded_lot == REPAIR_MATERIAL_CARGO_LOT_NAME
		),
		"journal_before": journal_before.duplicate(true),
		"journal_after": journal_after.duplicate(true),
		"trade_records_updated_one_port_entry": (
			prize_type == PRIZE_TRADE_RECORDS
			and int(journal_after.get(
				"prize_trade_records_update_count",
				0,
			)) == int(journal_before.get(
				"prize_trade_records_update_count",
				0,
			)) + 1
			and int(journal_after.get("port_entry_count", 0)) == 1
		),
		"selected_prize_types": selected_prize_types.duplicate(),
		"action_limit_prevents_all_four": action_limit < PRIZE_TYPES.size(),
	}
	return last_selection_evidence.duplicate(true)


func record_denied_selection(
	prize_type: String,
	reason: String,
	cargo_lots: Array[String],
	journal_entry: Dictionary,
) -> Dictionary:
	var actions_before := actions_remaining
	var selected_before := selected_prize_types.duplicate()
	denied_selection_count += 1
	if reason == "NO FREE SHIP CARGO SLOT":
		cargo_full_rejection_count += 1
	elif reason == "NO PRIZE ACTIONS REMAIN":
		exhausted_rejection_count += 1
	elif reason == "PRIZE ALREADY TAKEN":
		already_taken_rejection_count += 1
	last_result = "PRIZE DENIED · %s" % reason
	last_denied_selection_evidence = {
		"success": false,
		"result": last_result,
		"rejection_reason": reason,
		"prize_type": prize_type,
		"actions_before": actions_before,
		"actions_after": actions_remaining,
		"selected_before": selected_before,
		"selected_after": selected_prize_types.duplicate(),
		"cargo_before": cargo_lots.duplicate(),
		"cargo_after": cargo_lots.duplicate(),
		"journal_before": journal_entry.duplicate(true),
		"journal_after": journal_entry.duplicate(true),
		"no_action_change": actions_before == actions_remaining,
		"no_cargo_change": true,
		"no_journal_change": true,
		"no_state_change": (
			actions_before == actions_remaining
			and selected_before == selected_prize_types
		),
	}
	return last_denied_selection_evidence.duplicate(true)


func record_held_input(
	prize_type: String,
	cargo_lots: Array[String],
	journal_entry: Dictionary,
) -> Dictionary:
	held_input_count += 1
	last_held_input_evidence = {
		"success": false,
		"result": "PRIZE INPUT HELD · RELEASE KEY",
		"rejection_reason": "HELD_KEY",
		"prize_type": prize_type,
		"fresh_press_required": true,
		"actions_before": actions_remaining,
		"actions_after": actions_remaining,
		"cargo_before": cargo_lots.duplicate(),
		"cargo_after": cargo_lots.duplicate(),
		"journal_before": journal_entry.duplicate(true),
		"journal_after": journal_entry.duplicate(true),
		"no_state_change": true,
	}
	return last_held_input_evidence.duplicate(true)


func close_screen() -> Dictionary:
	if not screen_open:
		return {
			"success": false,
			"result": "PRIZE SCREEN NOT OPEN",
			"no_state_change": true,
		}
	screen_open = false
	screen_close_count += 1
	last_result = "PRIZE CHOICE COMPLETE · RETURN TO PLAYER SHIP"
	return {
		"success": true,
		"result": last_result,
		"screen_close_count": screen_close_count,
		"actions_used": action_limit - actions_remaining,
		"actions_remaining": actions_remaining,
		"selected_prize_types": selected_prize_types.duplicate(),
	}


func get_cargo_lot_name(prize_type: String) -> String:
	if prize_type == PRIZE_CARGO:
		return CAPTURED_CARGO_LOT_NAME
	if prize_type == PRIZE_CANNONS:
		return CANNON_CARGO_LOT_NAME
	if prize_type == PRIZE_REPAIR_MATERIALS:
		return REPAIR_MATERIAL_CARGO_LOT_NAME
	return ""


func get_awarded_cargo_lot_count() -> int:
	return cumulative_awarded_cargo_lot_count


func get_playtest_state(
	cargo_lots: Array[String],
	journal_entry: Dictionary,
	returned_to_player_ship: bool,
) -> Dictionary:
	var selected_prizes_persist := true
	for awarded_lot in awarded_cargo_lots:
		if cargo_lots.count(awarded_lot) < awarded_cargo_lots.count(awarded_lot):
			selected_prizes_persist = false
	var trade_records_persist := (
		not trade_records_taken or not journal_entry.is_empty()
	)
	var current_target_screen_open_count := int(
		screen_open_counts_by_target.get(active_target_id, 0)
	)
	return {
		"system_count": 1,
		"owner_count": 1,
		"screen_open": screen_open,
		"screen_open_count": screen_open_count,
		"screen_open_counts_by_target": screen_open_counts_by_target.duplicate(true),
		"current_target_screen_open_count": current_target_screen_open_count,
		"screen_close_count": screen_close_count,
		"opens_once_per_victory": current_target_screen_open_count == 1,
		"active_target_id": active_target_id,
		"active_target_name": active_target_name,
		"prize_type_count": PRIZE_TYPES.size(),
		"prize_types": PRIZE_TYPES.duplicate(),
		"prize_keys": PRIZE_KEYS.duplicate(true),
		"prize_display_names": PRIZE_DISPLAY_NAMES.duplicate(true),
		"exactly_four_visible_prize_types": PRIZE_TYPES.size() == 4,
		"cargo_prize_type": PRIZE_CARGO,
		"cargo_prize_lot_name": CAPTURED_CARGO_LOT_NAME,
		"cannon_prize_type": PRIZE_CANNONS,
		"cannon_cargo_lot_name": CANNON_CARGO_LOT_NAME,
		"cannon_is_usable": true,
		"cannon_is_sellable_cargo": true,
		"cannon_module_system_count": 0,
		"repair_material_prize_type": PRIZE_REPAIR_MATERIALS,
		"repair_material_cargo_lot_name": REPAIR_MATERIAL_CARGO_LOT_NAME,
		"repair_material_uses_existing_timber": true,
		"trade_records_prize_type": PRIZE_TRADE_RECORDS,
		"trade_records_update_one_port_entry": true,
		"action_limit": action_limit,
		"actions_remaining": actions_remaining,
		"actions_used": action_limit - actions_remaining,
		"actions_visible_before_first_choice": (
			last_open_evidence.get(
				"actions_visible_before_first_choice",
				false,
			)
		),
		"default_action_limit": DEFAULT_ACTION_LIMIT,
		"low_hull_action_limit": LOW_HULL_ACTION_LIMIT,
		"low_hull_threshold_percent": LOW_HULL_THRESHOLD_PERCENT,
		"hull_current_at_open": hull_current_at_open,
		"hull_max_at_open": hull_max_at_open,
		"low_hull_reduction_applied": low_hull_reduction_applied,
		"low_hull_reduces_action_limit": (
			not low_hull_reduction_applied
			or action_limit < DEFAULT_ACTION_LIMIT
		),
		"action_limit_prevents_taking_all_four": (
			action_limit < PRIZE_TYPES.size()
		),
		"selected_prize_types": selected_prize_types.duplicate(),
		"selected_prize_count": selected_prize_types.size(),
		"awarded_cargo_lots": awarded_cargo_lots.duplicate(),
		"awarded_cargo_lot_count": awarded_cargo_lots.size(),
		"current_victory_awarded_cargo_lot_count": (
			awarded_cargo_lots.size()
		),
		"cumulative_awarded_cargo_lot_count": (
			cumulative_awarded_cargo_lot_count
		),
		"trade_records_taken": trade_records_taken,
		"successful_selection_count": successful_selection_count,
		"denied_selection_count": denied_selection_count,
		"held_input_count": held_input_count,
		"exhausted_rejection_count": exhausted_rejection_count,
		"cargo_full_rejection_count": cargo_full_rejection_count,
		"already_taken_rejection_count": already_taken_rejection_count,
		"fresh_press_required": true,
		"last_result": last_result,
		"last_open_evidence": last_open_evidence.duplicate(true),
		"last_selection_evidence": last_selection_evidence.duplicate(true),
		"last_denied_selection_evidence": (
			last_denied_selection_evidence.duplicate(true)
		),
		"last_held_input_evidence": last_held_input_evidence.duplicate(true),
		"cargo_at_open": _cargo_snapshot_at_open.duplicate(),
		"journal_at_open": _journal_snapshot_at_open.duplicate(true),
		"current_cargo_lots": cargo_lots.duplicate(),
		"current_journal_entry": journal_entry.duplicate(true),
		"selected_prizes_persist": selected_prizes_persist,
		"trade_records_persist": trade_records_persist,
		"returned_to_player_ship": returned_to_player_ship,
		"persistence_after_return_holds": (
			returned_to_player_ship
			and selected_prizes_persist
			and trade_records_persist
		),
		"ship_capture_system_count": 0,
		"ransom_system_count": 0,
		"prisoner_system_count": 0,
		"story_clue_system_count": 0,
		"crew_injury_system_count": 0,
		"heat_change_count": 0,
	}
