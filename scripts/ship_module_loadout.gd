class_name ShipModuleLoadout
extends Area2D

const MODULE_NONE := "NONE"
const MODULE_CARGO_RACKS := "CARGO_RACKS"
const MODULE_LONG_GUNS := "LONG_GUNS"
const MODULE_FISHING_GEAR := "FISHING_GEAR"
const MODULE_IDS := [
	MODULE_CARGO_RACKS,
	MODULE_LONG_GUNS,
	MODULE_FISHING_GEAR,
]
const MODULE_NAMES := {
	MODULE_NONE: "NO MODULE SELECTED",
	MODULE_CARGO_RACKS: "CARGO RACKS",
	MODULE_LONG_GUNS: "LONG GUNS",
	MODULE_FISHING_GEAR: "FISHING GEAR",
}
const BASE_CARGO_LIMIT := 3
const CARGO_RACK_LIMIT := 4
const PURSUIT_RANGE := 425.0
const PURSUIT_MIN_FORWARD_DOT := 0.45
const PURSUIT_SAIL_DAMAGE := 25
const PURSUIT_RELOAD_DURATION := 0.9

var _selection_open := false
var _release_pending := false
var _pending_module := MODULE_NONE
var _active_module := MODULE_NONE
var _prepared_for_cove_departure := false
var _active_voyage_serial := 0
var _open_count := 0
var _close_count := 0
var _selection_attempt_count := 0
var _selection_success_count := 0
var _selection_denied_count := 0
var _selection_held_input_count := 0
var _blocked_input_count := 0
var _release_guard_input_count := 0
var _activation_count := 0
var _cove_voyage_start_count := 0
var _pursuit_reload_remaining := 0.0
var _pursuit_attempt_count := 0
var _pursuit_shot_count := 0
var _pursuit_hit_count := 0
var _pursuit_held_input_count := 0
var _pursuit_inactive_rejected_count := 0
var _pursuit_reload_rejected_count := 0
var _pursuit_no_ammunition_rejected_count := 0
var _pursuit_no_target_rejected_count := 0
var _last_selection_result := "SELECT ONE MODULE FOR THE NEXT COVE VOYAGE"
var _last_selection_evidence: Dictionary = {}
var _last_held_selection_evidence: Dictionary = {}
var _last_release_guard_evidence: Dictionary = {}
var _last_activation_evidence: Dictionary = {}
var _last_voyage_start_evidence: Dictionary = {}
var _last_pursuit_result := "NO PURSUIT ATTACK ATTEMPT"
var _last_pursuit_evidence: Dictionary = {}
var _last_held_pursuit_evidence: Dictionary = {}


func _ready() -> void:
	queue_redraw()


func open_selection(cargo_used: int) -> bool:
	if _selection_open or _release_pending:
		return false
	_selection_open = true
	_open_count += 1
	_last_selection_result = "SELECT ONE MODULE FOR THE NEXT COVE VOYAGE"
	_last_selection_evidence = {
		"success": true,
		"action": "OPEN_MODULE_SELECTION",
		"cargo_used": cargo_used,
		"pending_module": _pending_module,
		"active_module": _active_module,
		"fresh_press_required": true,
	}
	return true


func close_selection() -> bool:
	if not _selection_open:
		return false
	_selection_open = false
	_release_pending = true
	_close_count += 1
	_last_selection_result = "MODULE BENCH CLOSED · RELEASE ALL KEYS"
	return true


func release_guard() -> bool:
	if not _release_pending:
		return false
	_release_pending = false
	return true


func is_selection_open() -> bool:
	return _selection_open


func is_release_pending() -> bool:
	return _release_pending


func select_module(module_id: String, cargo_used: int) -> Dictionary:
	_selection_attempt_count += 1
	var normalized_module := module_id.to_upper()
	var pending_before := _pending_module
	var active_before := _active_module
	var denial_reasons := PackedStringArray()
	if not _selection_open:
		denial_reasons.append("MODULE BENCH IS CLOSED")
	if not MODULE_IDS.has(normalized_module):
		denial_reasons.append("UNKNOWN MODULE")
	if (
		normalized_module != MODULE_CARGO_RACKS
		and _active_module == MODULE_CARGO_RACKS
		and cargo_used > BASE_CARGO_LIMIT
	):
		denial_reasons.append("OFFLOAD CARGO TO %d SLOTS FIRST" % BASE_CARGO_LIMIT)
	if not denial_reasons.is_empty():
		_selection_denied_count += 1
		_last_selection_result = "SELECTION DENIED · %s" % " · ".join(
			denial_reasons
		)
		_last_selection_evidence = {
			"success": false,
			"action": "SELECT_MODULE",
			"requested_module": normalized_module,
			"pending_before": pending_before,
			"pending_after": _pending_module,
			"active_before": active_before,
			"active_after": _active_module,
			"cargo_used": cargo_used,
			"denial_reasons": denial_reasons,
			"no_state_change": (
				pending_before == _pending_module
				and active_before == _active_module
			),
			"fresh_press_required": true,
		}
		return _last_selection_evidence.duplicate(true)

	_pending_module = normalized_module
	_prepared_for_cove_departure = false
	_selection_success_count += 1
	_last_selection_result = "%s SELECTED · ACTIVE WHEN CAPTAIN BOARDS" % (
		get_module_name(_pending_module)
	)
	_last_selection_evidence = {
		"success": true,
		"action": "SELECT_MODULE",
		"requested_module": normalized_module,
		"pending_before": pending_before,
		"pending_after": _pending_module,
		"active_before": active_before,
		"active_after": _active_module,
		"cargo_used": cargo_used,
		"one_slot_one_pending_choice": true,
		"fresh_press_required": true,
	}
	return _last_selection_evidence.duplicate(true)


func record_held_selection(module_id: String, cargo_used: int) -> Dictionary:
	_selection_held_input_count += 1
	_last_held_selection_evidence = {
		"success": false,
		"result": "NO CHANGE · RELEASE MODULE KEY",
		"requested_module": module_id,
		"pending_before": _pending_module,
		"pending_after": _pending_module,
		"active_before": _active_module,
		"active_after": _active_module,
		"cargo_used_before": cargo_used,
		"cargo_used_after": cargo_used,
		"no_state_change": true,
		"fresh_press_required": true,
	}
	_last_selection_result = String(_last_held_selection_evidence["result"])
	return _last_held_selection_evidence.duplicate(true)


func record_blocked_input(key_name: String, cargo_used: int) -> void:
	_blocked_input_count += 1
	_last_selection_result = "NO CHANGE · %s BLOCKED BY MODULE VIEW" % key_name
	_last_selection_evidence = {
		"success": false,
		"action": "BLOCKED_MODULE_MODAL_INPUT",
		"key": key_name,
		"pending_module": _pending_module,
		"active_module": _active_module,
		"cargo_used": cargo_used,
		"no_state_change": true,
	}


func record_release_guard_input(key_name: String, cargo_used: int) -> void:
	_release_guard_input_count += 1
	_last_release_guard_evidence = {
		"success": false,
		"action": "BLOCKED_MODULE_RELEASE_INPUT",
		"key": key_name,
		"pending_module_before": _pending_module,
		"pending_module_after": _pending_module,
		"active_module_before": _active_module,
		"active_module_after": _active_module,
		"cargo_used_before": cargo_used,
		"cargo_used_after": cargo_used,
		"release_pending": _release_pending,
		"no_state_change": true,
		"fresh_press_required": true,
	}


func prepare_for_cove_departure(cargo_used: int) -> Dictionary:
	var active_before := _active_module
	var cargo_limit_before := get_active_cargo_limit()
	if _pending_module == MODULE_NONE:
		_prepared_for_cove_departure = false
		_last_activation_evidence = {
			"success": false,
			"result": "SELECT A SHIP MODULE AT THE COVE BEFORE DEPARTURE",
			"active_before": active_before,
			"active_after": _active_module,
			"pending_module": _pending_module,
			"cargo_used": cargo_used,
			"no_state_change": true,
		}
		return _last_activation_evidence.duplicate(true)
	var next_limit := get_cargo_limit_for_module(_pending_module)
	if cargo_used > next_limit:
		_prepared_for_cove_departure = false
		_last_activation_evidence = {
			"success": false,
			"result": "OFFLOAD CARGO TO %d SLOTS BEFORE MODULE CHANGE" % next_limit,
			"active_before": active_before,
			"active_after": _active_module,
			"pending_module": _pending_module,
			"cargo_used": cargo_used,
			"next_cargo_limit": next_limit,
			"no_state_change": true,
		}
		return _last_activation_evidence.duplicate(true)

	_active_module = _pending_module
	_prepared_for_cove_departure = true
	_activation_count += 1
	_pursuit_reload_remaining = 0.0
	_last_activation_evidence = {
		"success": true,
		"result": "%s ACTIVE FOR NEXT COVE VOYAGE" % get_active_module_name(),
		"active_before": active_before,
		"active_after": _active_module,
		"pending_module": _pending_module,
		"cargo_used": cargo_used,
		"cargo_limit_before": cargo_limit_before,
		"cargo_limit_after": get_active_cargo_limit(),
		"one_active_choice": true,
		"no_over_capacity_state": cargo_used <= get_active_cargo_limit(),
	}
	return _last_activation_evidence.duplicate(true)


func begin_cove_voyage() -> Dictionary:
	if not _prepared_for_cove_departure or _active_module == MODULE_NONE:
		_last_voyage_start_evidence = {
			"success": false,
			"result": "COVE VOYAGE BLOCKED · NO PREPARED MODULE",
			"active_module": _active_module,
			"pending_module": _pending_module,
			"voyage_serial": _active_voyage_serial,
		}
		return _last_voyage_start_evidence.duplicate(true)
	var selected_for_voyage := _pending_module
	_active_voyage_serial += 1
	_cove_voyage_start_count += 1
	_prepared_for_cove_departure = false
	_pending_module = MODULE_NONE
	_last_voyage_start_evidence = {
		"success": true,
		"result": "COVE VOYAGE %d STARTED · %s" % [
			_active_voyage_serial,
			get_active_module_name(),
		],
		"active_module": _active_module,
		"selected_for_voyage": selected_for_voyage,
		"pending_module_before_start": selected_for_voyage,
		"pending_module_after_start": _pending_module,
		"fresh_selection_required_for_next_cove_voyage": true,
		"voyage_serial": _active_voyage_serial,
		"cargo_limit": get_active_cargo_limit(),
		"pursuit_attack_available": is_long_guns_active(),
		"larger_catch_available": is_fishing_gear_active(),
	}
	return _last_voyage_start_evidence.duplicate(true)


func update_timers(delta: float) -> void:
	if delta <= 0.0 or _pursuit_reload_remaining <= 0.0:
		return
	_pursuit_reload_remaining = maxf(0.0, _pursuit_reload_remaining - delta)


func try_begin_pursuit_attack(
	input_available: bool,
	ammunition_units: int,
	target_id: String,
	target_name: String,
	target_distance: float,
	target_forward_dot: float,
) -> Dictionary:
	_pursuit_attempt_count += 1
	var rejection_reason := ""
	if not is_long_guns_active() or not input_available:
		rejection_reason = "LONG_GUNS_INACTIVE"
		_pursuit_inactive_rejected_count += 1
	elif _pursuit_reload_remaining > 0.0:
		rejection_reason = "RELOADING"
		_pursuit_reload_rejected_count += 1
	elif ammunition_units <= 0:
		rejection_reason = "NO_AMMUNITION"
		_pursuit_no_ammunition_rejected_count += 1
	elif (
		target_id.is_empty()
		or target_distance > PURSUIT_RANGE
		or target_forward_dot < PURSUIT_MIN_FORWARD_DOT
	):
		rejection_reason = "NO_PURSUIT_TARGET"
		_pursuit_no_target_rejected_count += 1
	if not rejection_reason.is_empty():
		_last_pursuit_result = "NO PURSUIT SHOT · %s" % rejection_reason.replace(
			"_",
			" ",
		)
		_last_pursuit_evidence = {
			"success": false,
			"shot_fired": false,
			"rejection_reason": rejection_reason,
			"result": _last_pursuit_result,
			"active_module": _active_module,
			"ammunition_before": ammunition_units,
			"ammunition_after": ammunition_units,
			"target_id": target_id,
			"target_name": target_name,
			"target_distance": target_distance,
			"target_forward_dot": target_forward_dot,
			"no_state_change": true,
			"fresh_press_required": true,
		}
		return _last_pursuit_evidence.duplicate(true)

	return {
		"success": true,
		"shot_fired": true,
		"active_module": _active_module,
		"ammunition_before": ammunition_units,
		"target_id": target_id,
		"target_name": target_name,
		"target_distance": target_distance,
		"target_forward_dot": target_forward_dot,
		"fixed_sail_damage": PURSUIT_SAIL_DAMAGE,
		"fresh_press_required": true,
	}


func resolve_pursuit_attack(
	preflight: Dictionary,
	ammunition_evidence: Dictionary,
	target_evidence: Dictionary,
	heat_evidence: Dictionary,
) -> Dictionary:
	if (
		not bool(preflight.get("success", false))
		or not bool(ammunition_evidence.get("success", false))
	):
		_last_pursuit_result = "PURSUIT SHOT ROLLED BACK · AMMUNITION FAILED"
		_last_pursuit_evidence = preflight.duplicate(true)
		_last_pursuit_evidence.merge({
			"success": false,
			"shot_fired": false,
			"result": _last_pursuit_result,
			"ammunition_evidence": ammunition_evidence.duplicate(true),
			"target_evidence": target_evidence.duplicate(true),
		}, true)
		return _last_pursuit_evidence.duplicate(true)

	_pursuit_shot_count += 1
	_pursuit_reload_remaining = PURSUIT_RELOAD_DURATION
	var target_hit := bool(target_evidence.get("success", false))
	if target_hit:
		_pursuit_hit_count += 1
	_last_pursuit_result = (
		"PURSUIT HIT · %s SAILS %d/%d" % [
			preflight["target_name"],
			target_evidence.get("sail_after", 0),
			target_evidence.get("sail_max", 0),
		]
		if target_hit
		else "PURSUIT SHOT MISSED"
	)
	_last_pursuit_evidence = preflight.duplicate(true)
	_last_pursuit_evidence.merge({
		"success": true,
		"shot_fired": true,
		"target_hit": target_hit,
		"result": _last_pursuit_result,
		"ammunition_evidence": ammunition_evidence.duplicate(true),
		"ammunition_after": ammunition_evidence.get("ammunition_after", -1),
		"ammunition_delta": ammunition_evidence.get("ammunition_delta", 0),
		"consumed_exactly_one_ammunition": bool(
			ammunition_evidence.get("consumed_exactly_one", false)
		),
		"target_evidence": target_evidence.duplicate(true),
		"target_sail_delta": target_evidence.get("sail_delta", 0),
		"fixed_sail_damage_applied": (
			not target_hit
			or int(target_evidence.get("sail_delta", 0))
				== -PURSUIT_SAIL_DAMAGE
		),
		"heat_evidence": heat_evidence.duplicate(true),
		"reload_duration": PURSUIT_RELOAD_DURATION,
	}, true)
	return _last_pursuit_evidence.duplicate(true)


func record_held_pursuit(
	ammunition_units: int,
	target_sails: Dictionary,
) -> Dictionary:
	_pursuit_held_input_count += 1
	_last_held_pursuit_evidence = {
		"success": false,
		"shot_fired": false,
		"result": "NO PURSUIT SHOT · RELEASE P",
		"ammunition_before": ammunition_units,
		"ammunition_after": ammunition_units,
		"target_sails_before": target_sails.duplicate(true),
		"target_sails_after": target_sails.duplicate(true),
		"no_ammunition_use": true,
		"no_target_damage": true,
		"fresh_press_required": true,
	}
	_last_pursuit_result = String(_last_held_pursuit_evidence["result"])
	return _last_held_pursuit_evidence.duplicate(true)


func has_pending_selection() -> bool:
	return _pending_module != MODULE_NONE


func is_cargo_racks_active() -> bool:
	return _active_module == MODULE_CARGO_RACKS


func is_long_guns_active() -> bool:
	return _active_module == MODULE_LONG_GUNS


func is_fishing_gear_active() -> bool:
	return _active_module == MODULE_FISHING_GEAR


func get_active_module() -> String:
	return _active_module


func get_pending_module() -> String:
	return _pending_module


func get_active_module_name() -> String:
	return get_module_name(_active_module)


func get_pending_module_name() -> String:
	return get_module_name(_pending_module)


func get_active_voyage_serial() -> int:
	return _active_voyage_serial


func get_active_cargo_limit() -> int:
	return get_cargo_limit_for_module(_active_module)


func get_cargo_limit_for_module(module_id: String) -> int:
	return CARGO_RACK_LIMIT if module_id == MODULE_CARGO_RACKS else BASE_CARGO_LIMIT


func get_module_name(module_id: String) -> String:
	return String(MODULE_NAMES.get(module_id, MODULE_NAMES[MODULE_NONE]))


func get_interaction_prompt() -> String:
	return "[E] PREPARE SHIP MODULE"


func get_selection_result() -> String:
	return _last_selection_result


func get_pursuit_result() -> String:
	return _last_pursuit_result


func get_playtest_state(
	cargo_used: int,
	ship_cargo_limit: int,
	view_visible: bool,
	view_text: String,
	player_near_station: bool,
) -> Dictionary:
	var active_effect_count := (
		int(is_cargo_racks_active())
		+ int(is_long_guns_active())
		+ int(is_fishing_gear_active())
	)
	return {
		"system_count": 1,
		"owner_count": 1,
		"module_slot_count": 1,
		"module_choice_count": MODULE_IDS.size(),
		"module_ids": MODULE_IDS.duplicate(),
		"module_names": [
			get_module_name(MODULE_CARGO_RACKS),
			get_module_name(MODULE_LONG_GUNS),
			get_module_name(MODULE_FISHING_GEAR),
		],
		"pending_module": _pending_module,
		"pending_module_name": get_pending_module_name(),
		"active_module": _active_module,
		"active_module_name": get_active_module_name(),
		"has_pending_selection": has_pending_selection(),
		"has_active_selection": _active_module != MODULE_NONE,
		"fresh_selection_required_for_next_cove_voyage": (
			_pending_module == MODULE_NONE
			and not _prepared_for_cove_departure
		),
		"cove_boarding_requires_prepared_selection": true,
		"active_effect_count": active_effect_count,
		"mutual_exclusivity_holds": active_effect_count <= 1,
		"exactly_one_active_when_selected": (
			_active_module == MODULE_NONE or active_effect_count == 1
		),
		"selection_open": _selection_open,
		"selection_release_pending": _release_pending,
		"view_visible": view_visible,
		"view_text": view_text,
		"player_near_station": player_near_station,
		"interaction_prompt": get_interaction_prompt(),
		"open_count": _open_count,
		"close_count": _close_count,
		"selection_attempt_count": _selection_attempt_count,
		"selection_success_count": _selection_success_count,
		"selection_denied_count": _selection_denied_count,
		"selection_held_input_count": _selection_held_input_count,
		"blocked_input_count": _blocked_input_count,
		"release_guard_input_count": _release_guard_input_count,
		"fresh_selection_press_required": true,
		"last_selection_result": _last_selection_result,
		"last_selection_evidence": _last_selection_evidence.duplicate(true),
		"last_held_selection_evidence": (
			_last_held_selection_evidence.duplicate(true)
		),
		"last_release_guard_evidence": (
			_last_release_guard_evidence.duplicate(true)
		),
		"activation_count": _activation_count,
		"prepared_for_cove_departure": _prepared_for_cove_departure,
		"last_activation_evidence": _last_activation_evidence.duplicate(true),
		"active_voyage_serial": _active_voyage_serial,
		"cove_voyage_start_count": _cove_voyage_start_count,
		"last_voyage_start_evidence": (
			_last_voyage_start_evidence.duplicate(true)
		),
		"base_cargo_limit": BASE_CARGO_LIMIT,
		"cargo_rack_limit": CARGO_RACK_LIMIT,
		"cargo_rack_bonus_slots": CARGO_RACK_LIMIT - BASE_CARGO_LIMIT,
		"active_cargo_limit": get_active_cargo_limit(),
		"ship_cargo_limit": ship_cargo_limit,
		"cargo_used": cargo_used,
		"cargo_limit_matches_active_module": (
			ship_cargo_limit == get_active_cargo_limit()
		),
		"cargo_capacity_safe": cargo_used <= ship_cargo_limit,
		"cargo_racks_add_space": (
			not is_cargo_racks_active() or ship_cargo_limit == CARGO_RACK_LIMIT
		),
		"long_guns_add_no_cargo_space": (
			not is_long_guns_active() or ship_cargo_limit == BASE_CARGO_LIMIT
		),
		"fishing_gear_adds_no_cargo_space": (
			not is_fishing_gear_active() or ship_cargo_limit == BASE_CARGO_LIMIT
		),
		"pursuit_attack_option_count": 1,
		"pursuit_attack_key": "P",
		"pursuit_attack_available": is_long_guns_active(),
		"pursuit_range": PURSUIT_RANGE,
		"pursuit_min_forward_dot": PURSUIT_MIN_FORWARD_DOT,
		"pursuit_fixed_sail_damage": PURSUIT_SAIL_DAMAGE,
		"pursuit_reload_duration": PURSUIT_RELOAD_DURATION,
		"pursuit_reload_remaining": _pursuit_reload_remaining,
		"pursuit_attempt_count": _pursuit_attempt_count,
		"pursuit_shot_count": _pursuit_shot_count,
		"pursuit_hit_count": _pursuit_hit_count,
		"pursuit_held_input_count": _pursuit_held_input_count,
		"pursuit_inactive_rejected_count": _pursuit_inactive_rejected_count,
		"pursuit_reload_rejected_count": _pursuit_reload_rejected_count,
		"pursuit_no_ammunition_rejected_count": (
			_pursuit_no_ammunition_rejected_count
		),
		"pursuit_no_target_rejected_count": _pursuit_no_target_rejected_count,
		"last_pursuit_result": _last_pursuit_result,
		"last_pursuit_evidence": _last_pursuit_evidence.duplicate(true),
		"last_held_pursuit_evidence": (
			_last_held_pursuit_evidence.duplicate(true)
		),
		"fishing_gear_active": is_fishing_gear_active(),
		"cargo_racks_active": is_cargo_racks_active(),
		"long_guns_active": is_long_guns_active(),
		"extra_module_slot_count": 0,
		"module_levels_count": 0,
		"upgrade_tree_count": 0,
		"large_upgrade_tree_count": 0,
		"passive_percentage_bonus_count": 0,
		"ship_cosmetic_count": 0,
		"owned_ship_count": 1,
		"extra_owned_ship_count": 0,
		"more_owned_ship_count": 0,
		"resident_reaction_count": 0,
		"relationship_progress_count": 0,
	}


func _draw() -> void:
	draw_rect(Rect2(-62.0, -30.0, 124.0, 60.0), Color("#593b2a"))
	draw_rect(Rect2(-54.0, -22.0, 108.0, 44.0), Color("#d3a35f"))
	draw_line(Vector2(-45.0, -12.0), Vector2(45.0, -12.0), Color("#3c2b25"), 5.0)
	draw_line(Vector2(-32.0, 2.0), Vector2(32.0, 2.0), Color("#3c2b25"), 5.0)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-92.0, -43.0),
		"SHIP MODULE BENCH",
		HORIZONTAL_ALIGNMENT_CENTER,
		184.0,
		15,
		Color("#fff0bb"),
	)
