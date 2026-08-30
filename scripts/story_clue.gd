class_name StoryClueState
extends Node2D

const RuinExplorationState := preload("res://scripts/ruin_exploration.gd")
const SAVE_PATH := "user://haven_of_tides_phase38_story_clue.cfg"
const SAVE_SECTION := "phase38_story_clue"
const SAVE_KEY := "payload"
const SAVE_FORMAT := "HAVEN_OF_TIDES_PHASE38_STORY_CLUE"
const SAVE_VERSION := 1
const FRAGMENT_ID := "blackwake_map_fragment"
const FRAGMENT_LOT_NAME := "TORN MAP FRAGMENT"
const FRAGMENT_POSITION := Vector2(4260.0, 1870.0)
const FRAGMENT_RANGE := 58.0
const CLUE_ID := "blackwake_deep_clue"
const CLUE_TITLE := "BLACKWAKE DEEP"
const CLUE_DESCRIPTION := (
	"A red ring marks deep water east of the test island."
)
const LOCATION_ID := "blackwake_deep"
const LOCATION_NAME := "BLACKWAKE DEEP"
const LOCATION_POSITION := Vector2(2250.0, 1500.0)

var _inside_ruin := false
var _tool_gate_open := false
var _player_position := Vector2.ZERO
var _fragment_distance := INF
var _fragment_available := true
var _fragment_acquired := false
var _fragment_choice_pending := false
var _interaction_release_pending := false
var _pending_cargo_snapshot: Array[String] = []
var _clue_entries: Array[Dictionary] = []
var _story_location_unlocked := false
var _fragment_attempt_count := 0
var _fragment_acquisition_count := 0
var _direct_keep_count := 0
var _choice_required_count := 0
var _leave_in_place_count := 0
var _replacement_keep_count := 0
var _displaced_cargo_discard_count := 0
var _held_input_count := 0
var _release_count := 0
var _return_to_cove_count := 0
var _save_count := 0
var _load_count := 0
var _startup_load_attempt_count := 0
var _startup_restore_count := 0
var _cleanup_count := 0
var _fragment_in_cargo_at_save := false
var _fragment_restored_to_cargo_count := 0
var _persisted_fragment_absent_count := 0
var _last_fragment_evidence: Dictionary = {}
var _successful_fragment_evidence: Dictionary = {}
var _last_choice_evidence: Dictionary = {}
var _last_held_input_evidence: Dictionary = {}
var _last_return_to_cove_evidence: Dictionary = {}
var _last_save_evidence: Dictionary = {}
var _last_load_evidence: Dictionary = {}
var _last_cleanup_evidence: Dictionary = {}


func _ready() -> void:
	queue_redraw()


func update_state(
	player_position: Vector2,
	inside_ruin: bool,
	tool_gate_open: bool,
) -> void:
	var visual_state_changed := (
		_inside_ruin != inside_ruin
		or _tool_gate_open != tool_gate_open
	)
	_player_position = player_position
	_inside_ruin = inside_ruin
	_tool_gate_open = tool_gate_open
	_fragment_distance = _player_position.distance_to(FRAGMENT_POSITION)
	if visual_state_changed:
		queue_redraw()


func can_take_fragment() -> bool:
	return (
		_inside_ruin
		and _tool_gate_open
		and _fragment_available
		and not _fragment_choice_pending
		and not _interaction_release_pending
		and _fragment_distance <= FRAGMENT_RANGE
	)


func is_near_fragment() -> bool:
	return (
		_inside_ruin
		and _tool_gate_open
		and _fragment_available
		and _fragment_distance <= FRAGMENT_RANGE
	)


func is_interaction_release_pending() -> bool:
	return _interaction_release_pending


func has_pending_fragment_choice() -> bool:
	return _fragment_choice_pending


func is_fragment_acquired() -> bool:
	return _fragment_acquired


func is_story_location_unlocked() -> bool:
	return _story_location_unlocked


func should_restore_fragment_to_cargo() -> bool:
	return _fragment_acquired and _fragment_in_cargo_at_save


func get_interaction_prompt() -> String:
	if can_take_fragment():
		return "[E] TAKE TORN MAP FRAGMENT"
	return ""


func get_clue_entries() -> Array[Dictionary]:
	var copied_entries: Array[Dictionary] = []
	for clue_entry in _clue_entries:
		copied_entries.append(clue_entry.duplicate(true))
	return copied_entries


func get_location_definition() -> Dictionary:
	return {
		"id": LOCATION_ID,
		"name": LOCATION_NAME,
		"position": LOCATION_POSITION,
	}


func begin_fragment_choice(cargo_before: Array[String]) -> bool:
	_fragment_attempt_count += 1
	if not can_take_fragment():
		_last_fragment_evidence = _build_denied_fragment_evidence(
			"FRAGMENT_NOT_AVAILABLE",
			cargo_before,
		)
		return false
	_fragment_choice_pending = true
	_choice_required_count += 1
	_pending_cargo_snapshot = cargo_before.duplicate()
	_last_fragment_evidence = {
		"action": "TAKE_MAP_FRAGMENT",
		"success": false,
		"resolution": "CARGO_CHOICE_REQUIRED",
		"fragment_id": FRAGMENT_ID,
		"fragment_lot": FRAGMENT_LOT_NAME,
		"cargo_before": cargo_before.duplicate(),
		"cargo_after": cargo_before.duplicate(),
		"cargo_unchanged_before_choice": true,
		"clue_count_before": _clue_entries.size(),
		"clue_count_after": _clue_entries.size(),
		"location_unlocked_before": _story_location_unlocked,
		"location_unlocked_after": _story_location_unlocked,
		"fresh_press_required": true,
	}
	_last_choice_evidence = _last_fragment_evidence.duplicate(true)
	return true


func collect_direct(
	cargo_before: Array[String],
	cargo_after: Array[String],
) -> bool:
	_fragment_attempt_count += 1
	if not can_take_fragment():
		_last_fragment_evidence = _build_denied_fragment_evidence(
			"FRAGMENT_NOT_AVAILABLE",
			cargo_before,
		)
		return false
	if (
		cargo_after.size() != cargo_before.size() + 1
		or cargo_after.count(FRAGMENT_LOT_NAME)
			!= cargo_before.count(FRAGMENT_LOT_NAME) + 1
	):
		_last_fragment_evidence = _build_denied_fragment_evidence(
			"CARGO_DELTA_INVALID",
			cargo_before,
		)
		return false
	if not _commit_fragment_acquisition():
		return false
	_direct_keep_count += 1
	_last_fragment_evidence = _build_successful_fragment_evidence(
		"DIRECT_KEEP",
		cargo_before,
		cargo_after,
		"",
	)
	_successful_fragment_evidence = _last_fragment_evidence.duplicate(true)
	_begin_interaction_release_guard()
	queue_redraw()
	return true


func leave_fragment_in_place(cargo_after: Array[String]) -> bool:
	if not _fragment_choice_pending:
		return false
	_fragment_choice_pending = false
	_leave_in_place_count += 1
	_last_choice_evidence = {
		"action": "LEAVE_MAP_FRAGMENT_IN_RUIN",
		"success": true,
		"resolution": "LEAVE_IN_PLACE",
		"fragment_id": FRAGMENT_ID,
		"fragment_lot": FRAGMENT_LOT_NAME,
		"cargo_before": _pending_cargo_snapshot.duplicate(),
		"cargo_after": cargo_after.duplicate(),
		"cargo_unchanged": cargo_after == _pending_cargo_snapshot,
		"fragment_still_available": _fragment_available,
		"clue_not_recorded": _clue_entries.is_empty(),
		"location_not_unlocked": not _story_location_unlocked,
	}
	_pending_cargo_snapshot.clear()
	return true


func collect_by_replacement(
	discarded_lot: String,
	cargo_after: Array[String],
) -> bool:
	if not _fragment_choice_pending or discarded_lot.is_empty():
		return false
	var fragment_count_before := _pending_cargo_snapshot.count(
		FRAGMENT_LOT_NAME
	)
	var expected_fragment_delta := (
		0 if discarded_lot == FRAGMENT_LOT_NAME else 1
	)
	if (
		cargo_after.size() != _pending_cargo_snapshot.size()
		or cargo_after.count(FRAGMENT_LOT_NAME)
			!= fragment_count_before + expected_fragment_delta
	):
		return false
	if not _commit_fragment_acquisition():
		return false
	_fragment_choice_pending = false
	_replacement_keep_count += 1
	_displaced_cargo_discard_count += 1
	_last_choice_evidence = _build_successful_fragment_evidence(
		"REPLACE_CARGO_SLOT",
		_pending_cargo_snapshot,
		cargo_after,
		discarded_lot,
	)
	_last_choice_evidence["fragment_count_before"] = fragment_count_before
	_last_choice_evidence["fragment_count_after"] = cargo_after.count(
		FRAGMENT_LOT_NAME
	)
	_last_choice_evidence["expected_fragment_count_delta"] = (
		expected_fragment_delta
	)
	_last_choice_evidence["fragment_count_delta_holds"] = (
		cargo_after.count(FRAGMENT_LOT_NAME) - fragment_count_before
			== expected_fragment_delta
	)
	_last_fragment_evidence = _last_choice_evidence.duplicate(true)
	_successful_fragment_evidence = _last_choice_evidence.duplicate(true)
	_pending_cargo_snapshot.clear()
	queue_redraw()
	return true


func record_held_or_guarded_interaction(
	action: String,
	cargo_lots: Array[String],
) -> void:
	_held_input_count += 1
	_last_held_input_evidence = {
		"action": action,
		"success": false,
		"fragment_available_before": _fragment_available,
		"fragment_available_after": _fragment_available,
		"fragment_acquired_before": _fragment_acquired,
		"fragment_acquired_after": _fragment_acquired,
		"acquisition_count_before": _fragment_acquisition_count,
		"acquisition_count_after": _fragment_acquisition_count,
		"clue_count_before": _clue_entries.size(),
		"clue_count_after": _clue_entries.size(),
		"location_unlocked_before": _story_location_unlocked,
		"location_unlocked_after": _story_location_unlocked,
		"cargo_before": cargo_lots.duplicate(),
		"cargo_after": cargo_lots.duplicate(),
		"cargo_unchanged": true,
		"fresh_press_required": true,
		"result": "NO_CHANGE_HELD_OR_RELEASE_GUARD",
	}


func release_interaction_guard() -> bool:
	if not _interaction_release_pending:
		return false
	_interaction_release_pending = false
	_release_count += 1
	return true


func record_return_to_cove(
	ship_cargo_lots: Array[String],
	storage_cargo_lots: Array[String],
) -> Dictionary:
	_return_to_cove_count += 1
	var ship_fragment_count := ship_cargo_lots.count(FRAGMENT_LOT_NAME)
	var storage_fragment_count := storage_cargo_lots.count(FRAGMENT_LOT_NAME)
	_last_return_to_cove_evidence = {
		"success": _fragment_acquired,
		"result": (
			"STORY CLUE RETURNED TO COVE"
			if _fragment_acquired
			else "NO STORY CLUE TO SAVE"
		),
		"fragment_acquired": _fragment_acquired,
		"fragment_in_ship_cargo": ship_fragment_count == 1,
		"fragment_in_cove_storage": storage_fragment_count == 1,
		"fragment_in_existing_cargo_owner_count": (
			ship_fragment_count + storage_fragment_count
		),
		"one_physical_fragment_in_existing_cargo": (
			ship_fragment_count + storage_fragment_count == 1
		),
		"clue_entry_count": _clue_entries.size(),
		"story_location_unlocked": _story_location_unlocked,
		"return_to_cove_count": _return_to_cove_count,
	}
	return _last_return_to_cove_evidence.duplicate(true)


func save_persistence(
	ship_cargo_lots: Array[String],
	storage_cargo_lots: Array[String],
	reason: String,
) -> Dictionary:
	if not _fragment_acquired:
		_last_save_evidence = {
			"success": false,
			"result": "STORY CLUE SAVE DENIED",
			"reason": "FRAGMENT_NOT_ACQUIRED",
			"path": SAVE_PATH,
			"save_reason": reason,
			"save_count": _save_count,
		}
		return _last_save_evidence.duplicate(true)
	var ship_fragment_count := ship_cargo_lots.count(FRAGMENT_LOT_NAME)
	var storage_fragment_count := storage_cargo_lots.count(FRAGMENT_LOT_NAME)
	var existing_cargo_fragment_count := (
		ship_fragment_count + storage_fragment_count
	)
	if existing_cargo_fragment_count > 1:
		_last_save_evidence = {
			"success": false,
			"result": "STORY CLUE SAVE DENIED",
			"reason": "DUPLICATE_PHYSICAL_FRAGMENT",
			"path": SAVE_PATH,
			"save_reason": reason,
			"ship_fragment_count": ship_fragment_count,
			"storage_fragment_count": storage_fragment_count,
			"existing_cargo_fragment_count": existing_cargo_fragment_count,
			"save_count": _save_count,
		}
		return _last_save_evidence.duplicate(true)
	_fragment_in_cargo_at_save = existing_cargo_fragment_count == 1
	var payload := _get_save_payload()
	var validation := validate_save_payload(payload)
	if not bool(validation["valid"]):
		_last_save_evidence = {
			"success": false,
			"result": "STORY CLUE SAVE DENIED",
			"reason": validation["reason"],
			"path": SAVE_PATH,
			"save_reason": reason,
			"save_count": _save_count,
		}
		return _last_save_evidence.duplicate(true)
	var config := ConfigFile.new()
	config.set_value(SAVE_SECTION, SAVE_KEY, payload.duplicate(true))
	var save_error := config.save(SAVE_PATH)
	var verification := _read_persistence_file()
	var success := save_error == OK and bool(verification["valid"])
	if success:
		_save_count += 1
	_last_save_evidence = {
		"success": success,
		"result": (
			"STORY CLUE SAVED" if success else "STORY CLUE SAVE FAILED"
		),
		"reason": (
			"SAVED"
			if success
			else (
				"CONFIG_SAVE_ERROR_%d" % save_error
				if save_error != OK
				else verification["reason"]
			)
		),
		"path": SAVE_PATH,
		"save_reason": reason,
		"save_error": save_error,
		"file_exists_after": FileAccess.file_exists(SAVE_PATH),
		"written_payload": payload.duplicate(true),
		"verified_payload": verification.get("payload", {}).duplicate(true),
		"ship_fragment_count": ship_fragment_count,
		"storage_fragment_count": storage_fragment_count,
		"existing_cargo_fragment_count": existing_cargo_fragment_count,
		"one_physical_fragment_in_existing_cargo": (
			existing_cargo_fragment_count == 1
		),
		"save_count": _save_count,
	}
	return _last_save_evidence.duplicate(true)


func inspect_persistence_file() -> Dictionary:
	return _read_persistence_file()


func load_persistence(
	reason: String,
	physical_context: Dictionary,
) -> Dictionary:
	if reason == "STARTUP":
		_startup_load_attempt_count += 1
	var state_before := _get_story_snapshot()
	var file_read := _read_persistence_file()
	if not bool(file_read["valid"]):
		_last_load_evidence = {
			"success": false,
			"result": "STORY CLUE NOT LOADED",
			"reason": file_read["reason"],
			"path": SAVE_PATH,
			"load_reason": reason,
			"state_before": state_before,
			"state_after": _get_story_snapshot(),
			"state_unchanged": state_before == _get_story_snapshot(),
			"load_count": _load_count,
			"startup_load_attempt_count": _startup_load_attempt_count,
		}
		return _last_load_evidence.duplicate(true)
	var payload: Dictionary = file_read["payload"]
	var fragment_expected_in_cargo := bool(
		payload["fragment_in_existing_cargo"]
	)
	var cargo_fragment_count_before := int(physical_context.get(
		"cargo_fragment_count_before",
		-1,
	))
	var cargo_fragment_count_after := int(physical_context.get(
		"cargo_fragment_count_after",
		-1,
	))
	var pending_fragment_transaction := bool(physical_context.get(
		"pending_fragment_transaction",
		false,
	))
	var restoration_added := bool(physical_context.get(
		"restoration_added",
		false,
	))
	var restoration_attempted := bool(physical_context.get(
		"restoration_attempted",
		false,
	))
	var restoration_succeeded := bool(physical_context.get(
		"restoration_succeeded",
		false,
	))
	var restoration_target := String(physical_context.get(
		"restoration_target",
		"NONE",
	))
	var expected_cargo_fragment_count := int(fragment_expected_in_cargo)
	var load_denial_reason := ""
	if pending_fragment_transaction:
		load_denial_reason = "PENDING_FRAGMENT_TRANSACTION"
	elif cargo_fragment_count_after > 1:
		load_denial_reason = "DUPLICATE_PHYSICAL_FRAGMENT"
	elif restoration_attempted and not restoration_succeeded:
		load_denial_reason = "PHYSICAL_FRAGMENT_ADD_FAILED"
	elif cargo_fragment_count_after != expected_cargo_fragment_count:
		load_denial_reason = (
			"NO_CARGO_SLOT_FOR_SAVED_FRAGMENT"
			if fragment_expected_in_cargo
			else "UNEXPECTED_PHYSICAL_FRAGMENT"
		)
	if not load_denial_reason.is_empty():
		_last_load_evidence = {
			"success": false,
			"result": "STORY CLUE LOAD DENIED",
			"reason": load_denial_reason,
			"path": SAVE_PATH,
			"load_reason": reason,
			"payload": payload.duplicate(true),
			"state_before": state_before,
			"state_after": _get_story_snapshot(),
			"state_unchanged": state_before == _get_story_snapshot(),
			"fragment_expected_in_existing_cargo": (
				fragment_expected_in_cargo
			),
			"cargo_fragment_count_before": cargo_fragment_count_before,
			"cargo_fragment_count_after": cargo_fragment_count_after,
			"restoration_added": restoration_added,
			"restoration_attempted": restoration_attempted,
			"restoration_succeeded": restoration_succeeded,
			"restoration_target": restoration_target,
			"pending_fragment_transaction": pending_fragment_transaction,
			"no_slot_rejection": (
				load_denial_reason == "NO_CARGO_SLOT_FOR_SAVED_FRAGMENT"
			),
			"load_count": _load_count,
			"startup_load_attempt_count": _startup_load_attempt_count,
		}
		return _last_load_evidence.duplicate(true)
	_fragment_available = false
	_fragment_acquired = true
	_fragment_acquisition_count = 1
	_fragment_choice_pending = false
	_interaction_release_pending = false
	_clue_entries = [_build_clue_entry()]
	_story_location_unlocked = true
	_fragment_in_cargo_at_save = fragment_expected_in_cargo
	_persisted_fragment_absent_count = int(
		not _fragment_in_cargo_at_save
	)
	_pending_cargo_snapshot.clear()
	_load_count += 1
	if restoration_added and restoration_succeeded:
		_fragment_restored_to_cargo_count += 1
	if reason == "STARTUP":
		_startup_restore_count += 1
	var state_after := _get_story_snapshot()
	_last_load_evidence = {
		"success": true,
		"result": "STORY CLUE LOADED",
		"reason": "LOADED",
		"path": SAVE_PATH,
		"load_reason": reason,
		"payload": payload.duplicate(true),
		"state_before": state_before,
		"state_after": state_after,
		"fragment_restored": _fragment_acquired,
		"clue_entry_restored": _clue_entries.size() == 1,
		"clue_identity_restored": (
			String(_clue_entries[0]["id"]) == CLUE_ID
		),
		"clue_description_restored": (
			String(_clue_entries[0]["description"])
				== CLUE_DESCRIPTION
		),
		"story_location_restored": _story_location_unlocked,
		"fragment_in_cargo_at_save": _fragment_in_cargo_at_save,
		"cargo_fragment_count_before": cargo_fragment_count_before,
		"cargo_fragment_count_after": cargo_fragment_count_after,
		"fragment_presence_satisfied_by_existing_owner": (
			fragment_expected_in_cargo
			and cargo_fragment_count_before == 1
			and not restoration_added
		),
		"fragment_found_in_cove_storage": bool(physical_context.get(
			"fragment_found_in_cove_storage",
			false,
		)),
		"restoration_added": restoration_added,
		"restoration_attempted": restoration_attempted,
		"restoration_succeeded": restoration_succeeded,
		"restoration_target": restoration_target,
		"one_physical_fragment_after_load": (
			fragment_expected_in_cargo
			and cargo_fragment_count_after == 1
		),
		"physical_fragment_count_matches_saved_presence": (
			cargo_fragment_count_after == expected_cargo_fragment_count
		),
		"valid_absent_fragment_load_case": (
			not fragment_expected_in_cargo
			and cargo_fragment_count_after == 0
		),
		"atomic_load_commit": true,
		"no_slot_rejection": false,
		"load_count": _load_count,
		"startup_load_attempt_count": _startup_load_attempt_count,
		"startup_restore_count": _startup_restore_count,
	}
	queue_redraw()
	return _last_load_evidence.duplicate(true)


func cleanup_persistence_for_mcp() -> Dictionary:
	var file_existed_before := FileAccess.file_exists(SAVE_PATH)
	var displaced_cargo_discard_count_before := (
		_displaced_cargo_discard_count
	)
	var remove_error := OK
	if file_existed_before:
		remove_error = DirAccess.remove_absolute(
			ProjectSettings.globalize_path(SAVE_PATH)
		)
	var file_exists_after := FileAccess.file_exists(SAVE_PATH)
	var success := remove_error == OK and not file_exists_after
	if success:
		if file_existed_before:
			_cleanup_count += 1
		_reset_runtime_story_state(true)
	_last_cleanup_evidence = {
		"success": success,
		"result": (
			"PHASE 38 STORY CLUE FILE REMOVED"
			if success and file_existed_before
			else (
				"PHASE 38 STORY CLUE FILE ALREADY ABSENT"
				if success
				else "PHASE 38 STORY CLUE FILE REMOVE FAILED"
			)
		),
		"path": SAVE_PATH,
		"only_exact_story_clue_file_targeted": true,
		"file_existed_before": file_existed_before,
		"file_exists_after": file_exists_after,
		"remove_error": remove_error,
		"cleanup_count": _cleanup_count,
		"displaced_cargo_discard_count_before": (
			displaced_cargo_discard_count_before
		),
		"displaced_cargo_discard_count_after": (
			_displaced_cargo_discard_count
		),
		"displaced_cargo_accounting_preserved": (
			not success
			or _displaced_cargo_discard_count
				== displaced_cargo_discard_count_before
		),
		"replacement_then_cleanup_sequence_observed": (
			success and displaced_cargo_discard_count_before > 0
		),
		"replacement_then_cleanup_ledger_holds": (
			displaced_cargo_discard_count_before == 0
			or (
				success
				and _displaced_cargo_discard_count
					== displaced_cargo_discard_count_before
			)
		),
	}
	queue_redraw()
	return _last_cleanup_evidence.duplicate(true)


func validate_save_payload(payload: Dictionary) -> Dictionary:
	var required_keys := [
		"format",
		"version",
		"fragment_id",
		"fragment_acquired",
		"fragment_in_existing_cargo",
		"clue_entries",
		"story_location_ids",
	]
	if payload.size() != required_keys.size():
		return {"valid": false, "reason": "UNEXPECTED_FIELD_COUNT"}
	for required_key in required_keys:
		if not payload.has(required_key):
			return {
				"valid": false,
				"reason": "MISSING_%s" % String(required_key).to_upper(),
			}
	if typeof(payload["format"]) != TYPE_STRING:
		return {"valid": false, "reason": "INVALID_TYPE_FORMAT"}
	if typeof(payload["version"]) != TYPE_INT:
		return {"valid": false, "reason": "INVALID_TYPE_VERSION"}
	if typeof(payload["fragment_id"]) != TYPE_STRING:
		return {"valid": false, "reason": "INVALID_TYPE_FRAGMENT_ID"}
	if typeof(payload["fragment_acquired"]) != TYPE_BOOL:
		return {"valid": false, "reason": "INVALID_TYPE_FRAGMENT_ACQUIRED"}
	if typeof(payload["fragment_in_existing_cargo"]) != TYPE_BOOL:
		return {"valid": false, "reason": "INVALID_TYPE_FRAGMENT_CARGO"}
	if typeof(payload["clue_entries"]) != TYPE_ARRAY:
		return {"valid": false, "reason": "INVALID_TYPE_CLUE_ENTRIES"}
	if typeof(payload["story_location_ids"]) != TYPE_ARRAY:
		return {"valid": false, "reason": "INVALID_TYPE_LOCATION_IDS"}
	if payload["format"] != SAVE_FORMAT:
		return {"valid": false, "reason": "INVALID_FORMAT"}
	if payload["version"] != SAVE_VERSION:
		return {"valid": false, "reason": "UNSUPPORTED_VERSION"}
	if payload["fragment_id"] != FRAGMENT_ID:
		return {"valid": false, "reason": "UNKNOWN_FRAGMENT_ID"}
	if not payload["fragment_acquired"]:
		return {"valid": false, "reason": "FRAGMENT_NOT_ACQUIRED"}
	var clue_entries: Array = payload["clue_entries"]
	if clue_entries.size() != 1 or typeof(clue_entries[0]) != TYPE_DICTIONARY:
		return {"valid": false, "reason": "INVALID_CLUE_ENTRY_COUNT"}
	var clue_entry: Dictionary = clue_entries[0]
	var expected_clue := _build_clue_entry()
	if clue_entry != expected_clue:
		return {"valid": false, "reason": "CLUE_ENTRY_CONTRACT_MISMATCH"}
	var location_ids: Array = payload["story_location_ids"]
	if location_ids.size() != 1 or location_ids[0] != LOCATION_ID:
		return {"valid": false, "reason": "LOCATION_ID_CONTRACT_MISMATCH"}
	return {
		"valid": true,
		"reason": "VALID",
		"exact_clue_entry": true,
		"exact_story_location": true,
	}


func get_playtest_state() -> Dictionary:
	var clue_entries := get_clue_entries()
	return {
		"system_count": 1,
		"owner_count": 1,
		"fragment_id": FRAGMENT_ID,
		"fragment_lot_name": FRAGMENT_LOT_NAME,
		"fragment_position": FRAGMENT_POSITION,
		"fragment_range": FRAGMENT_RANGE,
		"fragment_distance": _fragment_distance,
		"fragment_available": _fragment_available,
		"fragment_visible": (
			_inside_ruin and _tool_gate_open and _fragment_available
		),
		"fragment_behind_existing_tool_gate": (
			FRAGMENT_POSITION.x > RuinExplorationState.TOOL_GATE_POSITION.x
		),
		"fragment_interaction_available": can_take_fragment(),
		"fragment_acquired": _fragment_acquired,
		"fragment_choice_pending": _fragment_choice_pending,
		"fragment_attempt_count": _fragment_attempt_count,
		"fragment_acquisition_count": _fragment_acquisition_count,
		"fragment_collects_once": _fragment_acquisition_count <= 1,
		"direct_keep_count": _direct_keep_count,
		"choice_required_count": _choice_required_count,
		"leave_in_place_count": _leave_in_place_count,
		"replacement_keep_count": _replacement_keep_count,
		"displaced_cargo_discard_count": _displaced_cargo_discard_count,
		"world_fragment_lot_count": int(_fragment_available),
		"initial_fragment_lot_count": 1,
		"interaction_prompt": get_interaction_prompt(),
		"interaction_release_pending": _interaction_release_pending,
		"release_count": _release_count,
		"held_input_count": _held_input_count,
		"fresh_press_required": true,
		"last_fragment_evidence": _last_fragment_evidence.duplicate(true),
		"successful_fragment_evidence": (
			_successful_fragment_evidence.duplicate(true)
		),
		"last_choice_evidence": _last_choice_evidence.duplicate(true),
		"last_held_input_evidence": (
			_last_held_input_evidence.duplicate(true)
		),
		"clue_list_count": 1,
		"clue_entry_count": clue_entries.size(),
		"clue_entries": clue_entries,
		"clue_id": CLUE_ID,
		"clue_title": CLUE_TITLE,
		"clue_description": CLUE_DESCRIPTION,
		"clue_description_count": int(not clue_entries.is_empty()),
		"one_clue_entry_only": clue_entries.size() <= 1,
		"clue_recorded_only_after_acquisition": (
			clue_entries.is_empty() == not _fragment_acquired
		),
		"clue_identity_exact": (
			clue_entries.is_empty()
			or clue_entries[0] == _build_clue_entry()
		),
		"story_location_id": LOCATION_ID,
		"story_location_name": LOCATION_NAME,
		"story_location_position": LOCATION_POSITION,
		"story_location_count": int(_story_location_unlocked),
		"story_location_unlocked": _story_location_unlocked,
		"story_location_unlocked_with_clue": (
			_story_location_unlocked == not clue_entries.is_empty()
		),
		"return_to_cove_count": _return_to_cove_count,
		"last_return_to_cove_evidence": (
			_last_return_to_cove_evidence.duplicate(true)
		),
		"save_path": SAVE_PATH,
		"save_section": SAVE_SECTION,
		"save_key": SAVE_KEY,
		"save_format": SAVE_FORMAT,
		"save_version": SAVE_VERSION,
		"save_file_exists": FileAccess.file_exists(SAVE_PATH),
		"save_count": _save_count,
		"load_count": _load_count,
		"startup_load_attempt_count": _startup_load_attempt_count,
		"startup_restore_count": _startup_restore_count,
		"cleanup_count": _cleanup_count,
		"fragment_in_cargo_at_save": _fragment_in_cargo_at_save,
		"fragment_restored_to_cargo_count": (
			_fragment_restored_to_cargo_count
		),
		"persisted_fragment_absent_count": (
			_persisted_fragment_absent_count
		),
		"last_save_evidence": _last_save_evidence.duplicate(true),
		"last_load_evidence": _last_load_evidence.duplicate(true),
		"last_cleanup_evidence": _last_cleanup_evidence.duplicate(true),
		"cargo_owner_count": 1,
		"clue_chain_count": int(_fragment_acquired),
		"clue_combination_system_count": 0,
		"deduction_screen_count": 0,
		"cursed_object_count": 0,
		"resident_reaction_system_count": 0,
		"relationship_progress_system_count": 0,
		"monster_system_count": 0,
		"harpoon_action_count": 0,
		"monster_attack_count": 0,
		"monster_part_cargo_count": 0,
		"ship_module_loadout_system_count": 0,
	}


func _commit_fragment_acquisition() -> bool:
	if not _fragment_available or _fragment_acquired:
		return false
	_fragment_available = false
	_fragment_acquired = true
	_fragment_acquisition_count += 1
	_clue_entries = [_build_clue_entry()]
	_story_location_unlocked = true
	return true


func _build_clue_entry() -> Dictionary:
	return {
		"id": CLUE_ID,
		"title": CLUE_TITLE,
		"description": CLUE_DESCRIPTION,
		"location_id": LOCATION_ID,
	}


func _build_successful_fragment_evidence(
	resolution: String,
	cargo_before: Array[String],
	cargo_after: Array[String],
	discarded_lot: String,
) -> Dictionary:
	return {
		"action": "TAKE_MAP_FRAGMENT",
		"success": true,
		"resolution": resolution,
		"fragment_id": FRAGMENT_ID,
		"fragment_lot": FRAGMENT_LOT_NAME,
		"discarded_lot": discarded_lot,
		"cargo_before": cargo_before.duplicate(),
		"cargo_after": cargo_after.duplicate(),
		"cargo_within_limit": cargo_after.size() <= 3,
		"fragment_acquired": _fragment_acquired,
		"fragment_acquisition_count": _fragment_acquisition_count,
		"clue_entry": _build_clue_entry(),
		"clue_entry_count": _clue_entries.size(),
		"clue_recorded_same_action": _clue_entries.size() == 1,
		"story_location_id": LOCATION_ID,
		"story_location_position": LOCATION_POSITION,
		"story_location_unlocked_same_action": _story_location_unlocked,
		"fresh_press_required": true,
	}


func _build_denied_fragment_evidence(
	reason: String,
	cargo_lots: Array[String],
) -> Dictionary:
	return {
		"action": "TAKE_MAP_FRAGMENT",
		"success": false,
		"reason": reason,
		"fragment_available_before": _fragment_available,
		"fragment_available_after": _fragment_available,
		"fragment_acquired_before": _fragment_acquired,
		"fragment_acquired_after": _fragment_acquired,
		"clue_count_before": _clue_entries.size(),
		"clue_count_after": _clue_entries.size(),
		"location_unlocked_before": _story_location_unlocked,
		"location_unlocked_after": _story_location_unlocked,
		"cargo_before": cargo_lots.duplicate(),
		"cargo_after": cargo_lots.duplicate(),
		"cargo_unchanged": true,
	}


func _begin_interaction_release_guard() -> void:
	_interaction_release_pending = true


func _get_save_payload() -> Dictionary:
	return {
		"format": SAVE_FORMAT,
		"version": SAVE_VERSION,
		"fragment_id": FRAGMENT_ID,
		"fragment_acquired": _fragment_acquired,
		"fragment_in_existing_cargo": _fragment_in_cargo_at_save,
		"clue_entries": get_clue_entries(),
		"story_location_ids": [LOCATION_ID],
	}


func _read_persistence_file() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {
			"valid": false,
			"reason": "FILE_NOT_FOUND",
			"path": SAVE_PATH,
			"file_found": false,
			"load_error": ERR_FILE_NOT_FOUND,
		}
	var config := ConfigFile.new()
	var load_error := config.load(SAVE_PATH)
	if load_error != OK:
		return {
			"valid": false,
			"reason": "CONFIG_LOAD_ERROR_%d" % load_error,
			"path": SAVE_PATH,
			"file_found": true,
			"load_error": load_error,
		}
	var sections := config.get_sections()
	if sections.size() != 1 or sections[0] != SAVE_SECTION:
		return {
			"valid": false,
			"reason": "INVALID_CONFIG_SECTIONS",
			"path": SAVE_PATH,
			"file_found": true,
			"load_error": load_error,
		}
	var section_keys := config.get_section_keys(SAVE_SECTION)
	if section_keys.size() != 1 or section_keys[0] != SAVE_KEY:
		return {
			"valid": false,
			"reason": "INVALID_CONFIG_KEYS",
			"path": SAVE_PATH,
			"file_found": true,
			"load_error": load_error,
		}
	var payload_value = config.get_value(SAVE_SECTION, SAVE_KEY)
	if typeof(payload_value) != TYPE_DICTIONARY:
		return {
			"valid": false,
			"reason": "INVALID_PAYLOAD_TYPE",
			"path": SAVE_PATH,
			"file_found": true,
			"load_error": load_error,
		}
	var payload: Dictionary = payload_value
	var validation := validate_save_payload(payload)
	return {
		"valid": validation["valid"],
		"reason": validation["reason"],
		"path": SAVE_PATH,
		"file_found": true,
		"load_error": load_error,
		"payload": payload.duplicate(true),
		"payload_validation": validation.duplicate(true),
		"exact_section_and_key_contract": true,
	}


func _get_story_snapshot() -> Dictionary:
	return {
		"fragment_available": _fragment_available,
		"fragment_acquired": _fragment_acquired,
		"clue_entries": get_clue_entries(),
		"story_location_unlocked": _story_location_unlocked,
		"fragment_in_cargo_at_save": _fragment_in_cargo_at_save,
	}


func _reset_runtime_story_state(
	preserve_displaced_cargo_accounting := false,
) -> void:
	var displaced_cargo_discard_count_before := (
		_displaced_cargo_discard_count
	)
	_fragment_available = true
	_fragment_acquired = false
	_fragment_choice_pending = false
	_interaction_release_pending = false
	_pending_cargo_snapshot.clear()
	_clue_entries.clear()
	_story_location_unlocked = false
	_fragment_in_cargo_at_save = false
	_persisted_fragment_absent_count = 0
	_fragment_attempt_count = 0
	_fragment_acquisition_count = 0
	_direct_keep_count = 0
	_choice_required_count = 0
	_leave_in_place_count = 0
	_replacement_keep_count = 0
	_displaced_cargo_discard_count = (
		displaced_cargo_discard_count_before
		if preserve_displaced_cargo_accounting
		else 0
	)
	_held_input_count = 0
	_release_count = 0
	_return_to_cove_count = 0
	_save_count = 0
	_load_count = 0
	_startup_load_attempt_count = 0
	_startup_restore_count = 0
	_fragment_restored_to_cargo_count = 0
	_last_fragment_evidence = {}
	_successful_fragment_evidence = {}
	_last_choice_evidence = {}
	_last_held_input_evidence = {}
	_last_return_to_cove_evidence = {}
	_last_save_evidence = {}
	_last_load_evidence = {}


func _draw() -> void:
	if not _inside_ruin or not _tool_gate_open or not _fragment_available:
		return
	draw_rect(
		Rect2(FRAGMENT_POSITION + Vector2(-28.0, -20.0), Vector2(56.0, 40.0)),
		Color("#e8d2a2"),
	)
	for line_index in range(3):
		draw_line(
			FRAGMENT_POSITION + Vector2(-18.0, -10.0 + line_index * 9.0),
			FRAGMENT_POSITION + Vector2(18.0, -10.0 + line_index * 9.0),
			Color("#8b4f35"),
			2.0,
		)
	draw_circle(FRAGMENT_POSITION + Vector2(12.0, 8.0), 6.0, Color("#b52d31"))
	draw_string(
		ThemeDB.fallback_font,
		FRAGMENT_POSITION + Vector2(-84.0, -34.0),
		"TORN MAP FRAGMENT",
		HORIZONTAL_ALIGNMENT_CENTER,
		168.0,
		16,
		Color("#fff1c5"),
	)
