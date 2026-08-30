class_name MonsterHunt
extends Node2D

const StoryClueState := preload("res://scripts/story_clue.gd")

const MONSTER_ID := "blackwake_leviathan"
const MONSTER_NAME := "BLACKWAKE LEVIATHAN"
const LOCATION_ID := StoryClueState.LOCATION_ID
const LOCATION_POSITION := StoryClueState.LOCATION_POSITION
const ENCOUNTER_RANGE := 220.0
const VISUAL_RADIUS := 118.0
const SAILING_VIEWPORT_SIZE := Vector2(1152.0, 648.0)
const VISUAL_LOCAL_BOUNDS := Rect2(-170.0, -190.0, 340.0, 360.0)
const HEALTH_MAX := 2
const HARPOON_DAMAGE := 1
const HARPOON_RELOAD_DURATION := 0.9
const CLEAR_ATTACK_WARNING_DURATION := 0.75
const STORM_ATTACK_WARNING_DURATION := 0.45
const PART_LOT_NAME := "BLACKWAKE MONSTER PART LOT"

var _ship_position := Vector2.ZERO
var _ship_distance := INF
var _player_aboard_ship := false
var _captain_aboard := false
var _sailing_view_active := false
var _input_available := false
var _clue_unlocked := false
var _weather_storm_active := false
var _modal_pause_active := false
var _visual_on_screen := false
var _sailing_viewport_world_rect := Rect2()
var _encounter_started := false
var _encounter_active := false
var _defeated := false
var _health := HEALTH_MAX
var _harpoon_reload_remaining := 0.0
var _attack_warning_remaining := 0.0
var _attack_request_pending := false
var _attack_completed := false
var _part_pending := false
var _part_choice_pending := false
var _pending_cargo_snapshot: Array[String] = []
var _encounter_start_count := 0
var _harpoon_attempt_count := 0
var _harpoon_hit_count := 0
var _harpoon_held_input_count := 0
var _harpoon_reload_rejected_count := 0
var _harpoon_no_ammunition_rejected_count := 0
var _harpoon_inactive_rejected_count := 0
var _harpoon_defeated_rejected_count := 0
var _monster_attack_request_count := 0
var _monster_attack_count := 0
var _monster_defeat_count := 0
var _part_generation_count := 0
var _part_direct_keep_count := 0
var _part_choice_required_count := 0
var _part_leave_blocked_count := 0
var _part_replacement_keep_count := 0
var _displaced_cargo_discard_count := 0
var _return_to_cove_count := 0
var _last_harpoon_result := "NO HARPOON ATTEMPT"
var _last_harpoon_evidence: Dictionary = {}
var _last_held_harpoon_evidence: Dictionary = {}
var _last_reload_rejection_evidence: Dictionary = {}
var _last_no_ammunition_evidence: Dictionary = {}
var _last_inactive_evidence: Dictionary = {}
var _last_attack_evidence: Dictionary = {}
var _last_defeat_evidence: Dictionary = {}
var _last_part_choice_evidence: Dictionary = {}
var _last_part_leave_blocked_evidence: Dictionary = {}
var _last_return_evidence: Dictionary = {}


func _ready() -> void:
	hide()
	queue_redraw()


func update_encounter(
	delta: float,
	ship_position: Vector2,
	player_aboard_ship: bool,
	captain_aboard: bool,
	sailing_view_active: bool,
	input_available: bool,
	clue_unlocked: bool,
	weather_storm_active: bool,
	modal_pause_active: bool,
) -> bool:
	_ship_position = ship_position
	_player_aboard_ship = player_aboard_ship
	_captain_aboard = captain_aboard
	_sailing_view_active = sailing_view_active
	_input_available = input_available
	_clue_unlocked = clue_unlocked
	_weather_storm_active = weather_storm_active
	_modal_pause_active = modal_pause_active
	_ship_distance = _ship_position.distance_to(global_position)
	_sailing_viewport_world_rect = Rect2(
		_ship_position - SAILING_VIEWPORT_SIZE * 0.5,
		SAILING_VIEWPORT_SIZE,
	)
	_visual_on_screen = (
		_sailing_view_active
		and _clue_unlocked
		and _sailing_viewport_world_rect.intersects(
			Rect2(
				global_position + VISUAL_LOCAL_BOUNDS.position,
				VISUAL_LOCAL_BOUNDS.size,
			),
			true,
		)
	)
	visible = _visual_on_screen

	var was_active := _encounter_active
	_encounter_active = (
		_clue_unlocked
		and not _defeated
		and _player_aboard_ship
		and _captain_aboard
		and _sailing_view_active
		and _ship_distance <= ENCOUNTER_RANGE
	)
	if _encounter_active and not _encounter_started:
		_encounter_started = true
		_encounter_start_count += 1
		_attack_warning_remaining = _get_attack_warning_duration()
	if was_active != _encounter_active:
		queue_redraw()

	if _harpoon_reload_remaining > 0.0:
		_harpoon_reload_remaining = maxf(
			0.0,
			_harpoon_reload_remaining - delta,
		)
	if (
		_encounter_active
		and not _attack_completed
		and not _attack_request_pending
		and not _modal_pause_active
	):
		_attack_warning_remaining = maxf(
			0.0,
			_attack_warning_remaining - delta,
		)
		if is_zero_approx(_attack_warning_remaining):
			_attack_request_pending = true
			_monster_attack_request_count += 1
			return true
	return false


func is_encounter_active() -> bool:
	return _encounter_active


func is_defeated() -> bool:
	return _defeated


func has_pending_part() -> bool:
	return _part_pending


func has_pending_part_choice() -> bool:
	return _part_choice_pending


func try_begin_harpoon(
	input_available: bool,
	ammunition_units: int,
	context: Dictionary,
) -> Dictionary:
	_harpoon_attempt_count += 1
	var rejection_reason := ""
	if _defeated:
		rejection_reason = "MONSTER_DEFEATED"
	elif not _encounter_active or not input_available or not _input_available:
		rejection_reason = "ENCOUNTER_INACTIVE"
	elif _harpoon_reload_remaining > 0.0:
		rejection_reason = "RELOADING"
	elif ammunition_units <= 0:
		rejection_reason = "NO_AMMUNITION"
	if not rejection_reason.is_empty():
		var evidence := _build_rejected_harpoon_evidence(
			rejection_reason,
			ammunition_units,
			context,
		)
		_last_harpoon_evidence = evidence.duplicate(true)
		_last_harpoon_result = String(evidence["result"])
		if rejection_reason == "RELOADING":
			_harpoon_reload_rejected_count += 1
			_last_reload_rejection_evidence = evidence.duplicate(true)
		elif rejection_reason == "NO_AMMUNITION":
			_harpoon_no_ammunition_rejected_count += 1
			_last_no_ammunition_evidence = evidence.duplicate(true)
		elif rejection_reason == "MONSTER_DEFEATED":
			_harpoon_defeated_rejected_count += 1
			_last_inactive_evidence = evidence.duplicate(true)
		else:
			_harpoon_inactive_rejected_count += 1
			_last_inactive_evidence = evidence.duplicate(true)
		return evidence

	return {
		"success": true,
		"action": "HARPOON_BLACKWAKE_LEVIATHAN",
		"result": "HARPOON ACCEPTED",
		"monster_id": MONSTER_ID,
		"health_before": _health,
		"ammunition_before": ammunition_units,
		"fresh_press_required": true,
		"context_before": context.duplicate(true),
	}


func resolve_accepted_harpoon(
	preflight: Dictionary,
	ammunition_evidence: Dictionary,
	context_after: Dictionary,
) -> Dictionary:
	if (
		not bool(preflight.get("success", false))
		or not bool(ammunition_evidence.get("success", false))
		or int(ammunition_evidence.get("ammunition_delta", 0)) != -1
		or not _encounter_active
		or _defeated
	):
		_last_harpoon_result = "HARPOON RESOLUTION FAILED"
		_last_harpoon_evidence = {
			"success": false,
			"result": _last_harpoon_result,
			"preflight": preflight.duplicate(true),
			"ammunition_evidence": ammunition_evidence.duplicate(true),
			"monster_health": _health,
			"no_monster_state_change": true,
		}
		return _last_harpoon_evidence.duplicate(true)

	var health_before := _health
	_health = maxi(0, _health - HARPOON_DAMAGE)
	_harpoon_hit_count += 1
	_harpoon_reload_remaining = HARPOON_RELOAD_DURATION
	var defeated_now := health_before > 0 and _health == 0
	if defeated_now:
		_defeated = true
		_encounter_active = false
		_monster_defeat_count += 1
		_part_pending = true
		_part_generation_count += 1
		_last_defeat_evidence = {
			"success": true,
			"monster_id": MONSTER_ID,
			"defeat_count": _monster_defeat_count,
			"health_before": health_before,
			"health_after": _health,
			"part_lot_name": PART_LOT_NAME,
			"part_generation_count": _part_generation_count,
			"generated_exactly_one_part": _part_generation_count == 1,
			"encounter_stopped": not _encounter_active,
			"attack_stopped": true,
		}
	_last_harpoon_result = (
		"MONSTER DEFEATED · ONE PART READY"
		if defeated_now
		else "HARPOON HIT · MONSTER %d / %d" % [_health, HEALTH_MAX]
	)
	_last_harpoon_evidence = {
		"success": true,
		"action": "HARPOON_BLACKWAKE_LEVIATHAN",
		"result": _last_harpoon_result,
		"monster_id": MONSTER_ID,
		"health_before": health_before,
		"health_after": _health,
		"health_delta": _health - health_before,
		"fixed_harpoon_damage": HARPOON_DAMAGE,
		"damage_matches_fixed_amount": (
			_health - health_before == -HARPOON_DAMAGE
		),
		"hit_count": _harpoon_hit_count,
		"defeated_now": defeated_now,
		"defeat_count": _monster_defeat_count,
		"ammunition_before": ammunition_evidence["ammunition_before"],
		"ammunition_after": ammunition_evidence["ammunition_after"],
		"ammunition_delta": ammunition_evidence["ammunition_delta"],
		"consumed_exactly_one_ammunition": (
			int(ammunition_evidence["ammunition_delta"]) == -1
		),
		"ammunition_evidence": ammunition_evidence.duplicate(true),
		"reload_started": HARPOON_RELOAD_DURATION,
		"fresh_press_required": true,
		"context_before": preflight.get("context_before", {}).duplicate(true),
		"context_after": context_after.duplicate(true),
		"transaction_atomic": true,
	}
	queue_redraw()
	return _last_harpoon_evidence.duplicate(true)


func record_held_harpoon(
	ammunition_units: int,
	context: Dictionary,
) -> void:
	_harpoon_held_input_count += 1
	_last_harpoon_result = "NO HARPOON · RELEASE V"
	_last_held_harpoon_evidence = {
		"success": false,
		"result": _last_harpoon_result,
		"rejection_reason": "HELD_KEY",
		"health_before": _health,
		"health_after": _health,
		"health_unchanged": true,
		"ammunition_before": ammunition_units,
		"ammunition_after": ammunition_units,
		"ammunition_delta": 0,
		"hit_count_before": _harpoon_hit_count,
		"hit_count_after": _harpoon_hit_count,
		"fresh_press_required": true,
		"context_before": context.duplicate(true),
		"context_after": context.duplicate(true),
		"no_state_change": true,
	}
	_last_harpoon_evidence = _last_held_harpoon_evidence.duplicate(true)


func record_attack_result(evidence: Dictionary) -> void:
	if not _attack_request_pending:
		return
	_attack_request_pending = false
	_attack_completed = true
	if bool(evidence.get("success", false)):
		_monster_attack_count += 1
	_last_attack_evidence = evidence.duplicate(true)
	_last_attack_evidence.merge({
		"monster_id": MONSTER_ID,
		"attack_name": "CRUSHING TENTACLE STRIKE",
		"attack_request_count": _monster_attack_request_count,
		"attack_count": _monster_attack_count,
		"one_authored_attack_only": _monster_attack_request_count == 1,
		"weather_storm_active": _weather_storm_active,
		"weather_warning_duration": _get_attack_warning_duration(),
		"attack_completed": _attack_completed,
	}, true)
	queue_redraw()


func begin_part_choice(cargo_before: Array[String]) -> bool:
	if not _part_pending or _part_choice_pending:
		return false
	_part_choice_pending = true
	_part_choice_required_count += 1
	_pending_cargo_snapshot = cargo_before.duplicate()
	_last_part_choice_evidence = {
		"success": false,
		"resolution": "CARGO_CHOICE_REQUIRED",
		"part_lot_name": PART_LOT_NAME,
		"cargo_before": cargo_before.duplicate(),
		"cargo_after": cargo_before.duplicate(),
		"cargo_unchanged_before_choice": true,
		"part_pending": true,
	}
	return true


func resolve_direct_keep(
	cargo_before: Array[String],
	cargo_after: Array[String],
) -> bool:
	if (
		not _part_pending
		or _part_choice_pending
		or cargo_after.size() != cargo_before.size() + 1
		or cargo_after.count(PART_LOT_NAME)
			!= cargo_before.count(PART_LOT_NAME) + 1
	):
		return false
	_part_pending = false
	_part_direct_keep_count += 1
	_last_part_choice_evidence = _build_part_resolution_evidence(
		"DIRECT_KEEP",
		cargo_before,
		cargo_after,
		"",
	)
	return true


func record_blocked_leave(cargo_lots: Array[String]) -> Dictionary:
	if not _part_pending or not _part_choice_pending:
		return {}
	_part_leave_blocked_count += 1
	_last_part_leave_blocked_evidence = {
		"success": false,
		"action": "LEAVE_MONSTER_PART",
		"result": "MONSTER PART MUST REPLACE A CARGO SLOT",
		"rejection_reason": "REPLACEMENT_REQUIRED",
		"blocked_count": _part_leave_blocked_count,
		"part_lot_name": PART_LOT_NAME,
		"cargo_before": cargo_lots.duplicate(),
		"cargo_after": cargo_lots.duplicate(),
		"cargo_unchanged": true,
		"part_pending_before": true,
		"part_pending_after": _part_pending,
		"part_choice_pending_after": _part_choice_pending,
		"part_generation_count": _part_generation_count,
		"part_generation_unchanged": true,
		"part_in_cargo_count": cargo_lots.count(PART_LOT_NAME),
		"replacement_required": true,
		"choice_stays_open": _part_choice_pending,
		"no_part_cargo_or_accounting_change": true,
	}
	_last_part_choice_evidence = (
		_last_part_leave_blocked_evidence.duplicate(true)
	)
	return _last_part_leave_blocked_evidence.duplicate(true)


func resolve_replacement(
	discarded_lot: String,
	cargo_after: Array[String],
) -> bool:
	if (
		not _part_pending
		or not _part_choice_pending
		or discarded_lot.is_empty()
		or cargo_after.size() != _pending_cargo_snapshot.size()
		or cargo_after.count(PART_LOT_NAME)
			!= _pending_cargo_snapshot.count(PART_LOT_NAME) + 1
	):
		return false
	_part_pending = false
	_part_choice_pending = false
	_part_replacement_keep_count += 1
	_displaced_cargo_discard_count += 1
	_last_part_choice_evidence = _build_part_resolution_evidence(
		"REPLACE_CARGO_SLOT",
		_pending_cargo_snapshot,
		cargo_after,
		discarded_lot,
	)
	_pending_cargo_snapshot.clear()
	return true


func record_return_to_cove(
	cargo_lots: Array[String],
	at_cove: bool,
) -> bool:
	if (
		_return_to_cove_count > 0
		or not _defeated
		or not at_cove
		or cargo_lots.count(PART_LOT_NAME) != 1
	):
		return false
	_return_to_cove_count += 1
	_last_return_evidence = {
		"success": true,
		"result": "RETURNED TO COVE WITH ONE MONSTER PART",
		"return_to_cove_count": _return_to_cove_count,
		"monster_defeated": _defeated,
		"monster_defeat_count": _monster_defeat_count,
		"part_lot_name": PART_LOT_NAME,
		"part_in_cargo_count": cargo_lots.count(PART_LOT_NAME),
		"one_part_in_cargo": cargo_lots.count(PART_LOT_NAME) == 1,
		"cargo_lots": cargo_lots.duplicate(),
		"encounter_stays_resolved": not _encounter_active,
	}
	return true


func get_hud_title() -> String:
	return "SEA MONSTER · %s" % MONSTER_NAME


func get_hud_status(ammunition_units: int) -> String:
	if _defeated:
		return "DEFEATED · ONE PART AWARDED"
	if not _encounter_active:
		return "FOLLOW CLUE TO BLACKWAKE DEEP"
	if _harpoon_reload_remaining > 0.0:
		return "HEALTH %d/%d · HARPOON RELOAD %.1f" % [
			_health,
			HEALTH_MAX,
			_harpoon_reload_remaining,
		]
	if ammunition_units <= 0:
		return "HEALTH %d/%d · NO AMMUNITION" % [_health, HEALTH_MAX]
	return "HEALTH %d/%d · [V] HARPOON · 1 AMMUNITION" % [
		_health,
		HEALTH_MAX,
	]


func get_hud_result() -> String:
	if _encounter_active and not _attack_completed:
		return "%s · ATTACK IN %.1f" % [
			_last_harpoon_result,
			_attack_warning_remaining,
		]
	return _last_harpoon_result


func get_playtest_state(
	cargo_lots: Array[String],
	storage_lots: Array[String] = [],
) -> Dictionary:
	var visual_world_rect := Rect2(
		global_position + VISUAL_LOCAL_BOUNDS.position,
		VISUAL_LOCAL_BOUNDS.size,
	)
	var part_in_ship_cargo_count := cargo_lots.count(PART_LOT_NAME)
	var part_in_storage_count := storage_lots.count(PART_LOT_NAME)
	var part_in_cargo_count := (
		part_in_ship_cargo_count + part_in_storage_count
	)
	var resolved_part_count := (
		_part_direct_keep_count
		+ _part_replacement_keep_count
	)
	return {
		"system_count": 1,
		"owner_count": 1,
		"monster_count": 1,
		"monster_type_count": 1,
		"monster_id": MONSTER_ID,
		"monster_name": MONSTER_NAME,
		"location_id": LOCATION_ID,
		"location_position": global_position,
		"expected_location_position": LOCATION_POSITION,
		"location_matches_story_clue_exactly": (
			global_position.is_equal_approx(LOCATION_POSITION)
		),
		"encounter_range": ENCOUNTER_RANGE,
		"visual_radius": VISUAL_RADIUS,
		"visual_local_bounds": VISUAL_LOCAL_BOUNDS,
		"visual_world_rect": visual_world_rect,
		"visual_on_screen": _visual_on_screen,
		"visible": visible,
		"sailing_view_active": _sailing_view_active,
		"sailing_viewport_world_rect": _sailing_viewport_world_rect,
		"ship_position": _ship_position,
		"ship_distance": _ship_distance,
		"clue_unlocked": _clue_unlocked,
		"player_aboard_ship": _player_aboard_ship,
		"captain_aboard": _captain_aboard,
		"input_available": _input_available,
		"modal_pause_active": _modal_pause_active,
		"encounter_started": _encounter_started,
		"encounter_active": _encounter_active,
		"encounter_start_count": _encounter_start_count,
		"activation_requires_exact_unlocked_clue_location": (
			not _encounter_active
			or (
				_clue_unlocked
				and _ship_distance <= ENCOUNTER_RANGE
				and global_position.is_equal_approx(LOCATION_POSITION)
			)
		),
		"health": _health,
		"health_max": HEALTH_MAX,
		"defeated": _defeated,
		"monster_defeat_count": _monster_defeat_count,
		"defeat_once_holds": _monster_defeat_count <= 1,
		"harpoon_action_count": 1,
		"harpoon_key": "V",
		"harpoon_damage": HARPOON_DAMAGE,
		"harpoon_reload_duration": HARPOON_RELOAD_DURATION,
		"harpoon_reload_remaining": _harpoon_reload_remaining,
		"harpoon_reload_ready": is_zero_approx(_harpoon_reload_remaining),
		"harpoon_attempt_count": _harpoon_attempt_count,
		"harpoon_hit_count": _harpoon_hit_count,
		"harpoon_held_input_count": _harpoon_held_input_count,
		"harpoon_reload_rejected_count": _harpoon_reload_rejected_count,
		"harpoon_no_ammunition_rejected_count": (
			_harpoon_no_ammunition_rejected_count
		),
		"harpoon_inactive_rejected_count": _harpoon_inactive_rejected_count,
		"harpoon_defeated_rejected_count": _harpoon_defeated_rejected_count,
		"last_harpoon_result": _last_harpoon_result,
		"last_harpoon_evidence": _last_harpoon_evidence.duplicate(true),
		"last_held_harpoon_evidence": (
			_last_held_harpoon_evidence.duplicate(true)
		),
		"last_reload_rejection_evidence": (
			_last_reload_rejection_evidence.duplicate(true)
		),
		"last_no_ammunition_evidence": (
			_last_no_ammunition_evidence.duplicate(true)
		),
		"last_inactive_evidence": _last_inactive_evidence.duplicate(true),
		"fresh_press_required": true,
		"accepted_harpoon_uses_existing_ammunition": true,
		"accepted_harpoon_ammunition_delta": -1,
		"monster_attack_action_count": 1,
		"monster_attack_name": "CRUSHING TENTACLE STRIKE",
		"monster_attack_request_count": _monster_attack_request_count,
		"monster_attack_count": _monster_attack_count,
		"monster_attack_completed": _attack_completed,
		"monster_attack_request_pending": _attack_request_pending,
		"monster_attack_warning_remaining": _attack_warning_remaining,
		"one_monster_attack_only": _monster_attack_request_count <= 1,
		"last_attack_evidence": _last_attack_evidence.duplicate(true),
		"last_defeat_evidence": _last_defeat_evidence.duplicate(true),
		"weather_storm_active": _weather_storm_active,
		"clear_attack_warning_duration": CLEAR_ATTACK_WARNING_DURATION,
		"storm_attack_warning_duration": STORM_ATTACK_WARNING_DURATION,
		"current_attack_warning_duration": _get_attack_warning_duration(),
		"weather_effect_count": 1,
		"weather_effect_kind": "STORM_SHORTENS_MONSTER_ATTACK_WARNING",
		"part_lot_name": PART_LOT_NAME,
		"part_generation_count": _part_generation_count,
		"part_pending_count": 1 if _part_pending else 0,
		"world_part_lot_count": 1 if _part_pending else 0,
		"part_choice_pending": _part_choice_pending,
		"part_direct_keep_count": _part_direct_keep_count,
		"part_choice_required_count": _part_choice_required_count,
		"part_leave_available": false,
		"part_requires_replacement_when_full": true,
		"part_leave_blocked_count": _part_leave_blocked_count,
		"part_replacement_keep_count": _part_replacement_keep_count,
		"part_displaced_cargo_discard_count": (
			_displaced_cargo_discard_count
		),
		"part_in_ship_cargo_count": part_in_ship_cargo_count,
		"part_in_cove_storage_count": part_in_storage_count,
		"part_in_cargo_count": part_in_cargo_count,
		"last_part_choice_evidence": (
			_last_part_choice_evidence.duplicate(true)
		),
		"last_part_leave_blocked_evidence": (
			_last_part_leave_blocked_evidence.duplicate(true)
		),
		"part_accounting_holds": (
			_part_generation_count
			== resolved_part_count + (1 if _part_pending else 0)
		),
		"one_part_award_holds": _part_generation_count <= 1,
		"one_part_physical_holds": (
			not _defeated
			or part_in_cargo_count + (1 if _part_pending else 0) == 1
		),
		"return_to_cove_count": _return_to_cove_count,
		"returned_to_cove_with_part": _return_to_cove_count == 1,
		"last_return_evidence": _last_return_evidence.duplicate(true),
		"uses_existing_story_clue_owner": true,
		"uses_existing_ammunition_owner": true,
		"uses_existing_ship_damage_owner": true,
		"uses_existing_crew_condition_owner": true,
		"uses_existing_cargo_owner": true,
		"uses_existing_cargo_choice": true,
		"uses_existing_weather_owner": true,
		"separate_combat_screen_count": 0,
		"extra_monster_type_count": 0,
		"harpoon_upgrade_count": 0,
		"gear_crafting_system_count": 0,
		"repeatable_boss_system_count": 0,
		"ship_module_slot_count": 0,
		"ship_module_selection_count": 0,
		"cargo_rack_module_count": 0,
		"long_gun_module_count": 0,
		"fishing_gear_module_count": 0,
		"resident_reaction_count": 0,
		"relationship_progress_count": 0,
	}


func _build_rejected_harpoon_evidence(
	reason: String,
	ammunition_units: int,
	context: Dictionary,
) -> Dictionary:
	var result_map := {
		"MONSTER_DEFEATED": "NO HARPOON · MONSTER DEFEATED",
		"ENCOUNTER_INACTIVE": "NO HARPOON · FOLLOW CLUE TO MONSTER",
		"RELOADING": "NO HARPOON · RELOADING",
		"NO_AMMUNITION": "NO HARPOON · NO AMMUNITION",
	}
	return {
		"success": false,
		"action": "HARPOON_BLACKWAKE_LEVIATHAN",
		"result": String(result_map.get(reason, "NO HARPOON")),
		"rejection_reason": reason,
		"health_before": _health,
		"health_after": _health,
		"health_unchanged": true,
		"ammunition_before": ammunition_units,
		"ammunition_after": ammunition_units,
		"ammunition_delta": 0,
		"hit_count_before": _harpoon_hit_count,
		"hit_count_after": _harpoon_hit_count,
		"fresh_press_required": true,
		"context_before": context.duplicate(true),
		"context_after": context.duplicate(true),
		"no_state_change": true,
	}


func _build_part_resolution_evidence(
	resolution: String,
	cargo_before: Array[String],
	cargo_after: Array[String],
	discarded_lot: String,
) -> Dictionary:
	return {
		"success": true,
		"resolution": resolution,
		"part_lot_name": PART_LOT_NAME,
		"discarded_lot": discarded_lot,
		"cargo_before": cargo_before.duplicate(),
		"cargo_after": cargo_after.duplicate(),
		"cargo_slot_delta": cargo_after.size() - cargo_before.size(),
		"part_count_before": cargo_before.count(PART_LOT_NAME),
		"part_count_after": cargo_after.count(PART_LOT_NAME),
		"part_count_delta": (
			cargo_after.count(PART_LOT_NAME)
			- cargo_before.count(PART_LOT_NAME)
		),
		"part_pending_after": false,
		"one_part_generated": _part_generation_count == 1,
	}


func _get_attack_warning_duration() -> float:
	return (
		STORM_ATTACK_WARNING_DURATION
		if _weather_storm_active
		else CLEAR_ATTACK_WARNING_DURATION
	)


func _draw() -> void:
	var water_color := Color("#4c173b88") if not _defeated else Color("#27384588")
	var body_color := Color("#7c2458") if not _defeated else Color("#40505a")
	draw_circle(Vector2.ZERO, VISUAL_RADIUS, water_color)
	draw_arc(
		Vector2.ZERO,
		VISUAL_RADIUS,
		0.0,
		TAU,
		64,
		Color("#ef88c4") if not _defeated else Color("#8096a0"),
		6.0,
	)
	for angle in [0.2, 1.25, 2.3, 3.35, 4.4, 5.45]:
		var start := Vector2.from_angle(angle) * 34.0
		var middle := Vector2.from_angle(angle + 0.28) * 78.0
		var end := Vector2.from_angle(angle - 0.18) * 116.0
		draw_polyline(
			PackedVector2Array([start, middle, end]),
			body_color,
			14.0,
			true,
		)
	draw_circle(Vector2.ZERO, 47.0, body_color)
	draw_circle(Vector2(-16.0, -10.0), 7.0, Color("#ffe29a"))
	draw_circle(Vector2(16.0, -10.0), 7.0, Color("#ffe29a"))
	var font := ThemeDB.fallback_font
	draw_rect(
		Rect2(Vector2(-165.0, -184.0), Vector2(330.0, 42.0)),
		Color("#1d0d1be8"),
	)
	draw_string(
		font,
		Vector2(-156.0, -155.0),
		"BLACKWAKE DEEP · SEA MONSTER",
		HORIZONTAL_ALIGNMENT_CENTER,
		312.0,
		18,
		Color("#fff0c4"),
	)
