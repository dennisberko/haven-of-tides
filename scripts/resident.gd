class_name CoveResident
extends Area2D

@export var display_name := "Mara"
@export var request_offer_dialogue := PackedStringArray([
	"The eastern dock took another hard wave.",
	"Please inspect the damaged boards and tell me what you find.",
])
@export var request_active_dialogue := PackedStringArray([
	"The damaged dock is east of here.",
	"Tell me what you find after you inspect it.",
])
@export var request_report_dialogue := PackedStringArray([
	"You found the split supports before they gave way.",
	"Thank you. Take my ruin pry bar. It can open one blocked stone path.",
])
@export var request_complete_dialogue := PackedStringArray([
	"The dock will hold until we can repair those supports.",
	"Keep the ruin pry bar. It can open the blocked path in the test island ruin.",
])

const IMPORTANT_EVENT_ID := "blackwake_leviathan_defeated_returned_to_cove"
const IMPORTANT_EVENT_NAME := "BLACKWAKE LEVIATHAN DEFEATED"
const IMPORTANT_EVENT_SOURCE := "MONSTER_HUNT_RETURN_TO_COVE"
const REACTION_DIALOGUE_KIND := "IMPORTANT_EVENT_REACTION"
const NORMAL_DIALOGUE_KIND := "NORMAL_REQUEST_DIALOGUE"
const RELATIONSHIP_DIALOGUE_KIND := "RELATIONSHIP_THRESHOLD_SCENE"
const NIGHT_DIALOGUE_KIND := "MARA_NIGHT_SCENE"
const REACTION_DIALOGUE_LINE := (
	"You brought the Blackwake Leviathan down and returned with proof. "
	+ "The cove will remember that."
)
const RELATIONSHIP_DIALOGUE_LINE_1 := (
	"You did more than inspect old boards. You gave me time to make the dock safe."
)
const RELATIONSHIP_DIALOGUE_LINE_2 := (
	"You have my trust now. When the sea turns hard, come back and talk to me."
)
const NIGHT_DIALOGUE_LINE_1 := (
	"The cove sounds different after dark. The sea gives us room to speak."
)
const NIGHT_DIALOGUE_LINE_2 := (
	"You came back with the night tide. Sit by the fire before the next voyage."
)
const RELATIONSHIP_RESIDENT_ID := "mara"
const RELATIONSHIP_REQUEST_TITLE := "DAMAGED DOCK"
const RELATIONSHIP_INITIAL_VALUE := 0
const RELATIONSHIP_INCREASE := 1
const RELATIONSHIP_THRESHOLD := 1
const RELATIONSHIP_MAX_VALUE := 1
const RELATIONSHIP_SAVE_PATH := (
	"user://haven_of_tides_phase42_mara_relationship.cfg"
)
const RELATIONSHIP_SAVE_SECTION := "mara_relationship"
const RELATIONSHIP_SAVE_KEY := "value"

var _important_event_record_count := 0
var _reaction_arm_count := 0
var _reaction_show_count := 0
var _reaction_finish_count := 0
var _normal_talk_count := 0
var _normal_talk_after_reaction_count := 0
var _talk_attempt_count := 0
var _held_talk_input_count := 0
var _talk_attempt_count_at_arm := -1
var _reaction_talk_attempt_number := -1
var _reaction_pending := false
var _normal_talk_after_reaction_pending := false
var _normal_talk_after_relationship_pending := false
var _talk_open := false
var _active_dialogue_kind := ""
var _reaction_request_state_before := ""
var _active_talk_request_state_before := ""
var _relationship_value := RELATIONSHIP_INITIAL_VALUE
var _relationship_increase_count := 0
var _relationship_already_applied_request_count := 0
var _relationship_threshold_reach_count := 0
var _relationship_scene_show_count := 0
var _relationship_scene_finish_count := 0
var _relationship_normal_talk_after_count := 0
var _relationship_scene_pending := false
var _relationship_priority_conflict_count := 0
var _relationship_priority_reaction_win_count := 0
var _relationship_save_count := 0
var _relationship_load_count := 0
var _relationship_load_reject_count := 0
var _relationship_startup_load_attempt_count := 0
var _relationship_cleanup_count := 0
var _last_relationship_completion_evidence: Dictionary = {}
var _last_relationship_save_evidence: Dictionary = {}
var _last_relationship_load_evidence: Dictionary = {}
var _last_relationship_cleanup_evidence: Dictionary = {}
var _last_relationship_runtime_reset_evidence: Dictionary = {}
var _known_time_state := "DAY"
var _night_scene_arm_count := 0
var _night_scene_show_count := 0
var _night_scene_finish_count := 0
var _night_scene_normal_talk_after_count := 0
var _night_scene_pending := false
var _normal_talk_after_night_pending := false
var _night_priority_delay_count := 0
var _last_night_state_evidence: Dictionary = {}
var _last_event_evidence: Dictionary = {}
var _last_talk_evidence: Dictionary = {}
var _last_talk_finish_evidence: Dictionary = {}
var _last_held_talk_evidence: Dictionary = {}


func _ready() -> void:
	queue_redraw()


func record_day_night_state(
	time_state: String,
	transition_evidence: Dictionary,
) -> Dictionary:
	var state_before := _known_time_state
	if time_state != "DAY" and time_state != "NIGHT":
		_last_night_state_evidence = {
			"success": false,
			"result": "MARA NIGHT SCENE NOT ARMED",
			"reason": "INVALID TIME STATE",
			"time_state_before": state_before,
			"time_state_after": _known_time_state,
			"night_scene_pending": _night_scene_pending,
			"night_scene_arm_count": _night_scene_arm_count,
			"night_scene_show_count": _night_scene_show_count,
			"no_state_change": true,
		}
		return _last_night_state_evidence.duplicate(true)
	_known_time_state = time_state
	var valid_night_transition := (
		time_state == "NIGHT"
		and bool(transition_evidence.get("success", false))
		and String(transition_evidence.get("state_before", "")) == "DAY"
		and String(transition_evidence.get("state_after", "")) == "NIGHT"
		and bool(transition_evidence.get(
			"eligible_counted_cove_return",
			false,
		))
	)
	var armed := false
	var reason := "TIME STATUS UPDATED"
	if valid_night_transition:
		if _night_scene_arm_count == 0 and _night_scene_show_count == 0:
			_night_scene_pending = true
			_night_scene_arm_count = 1
			armed = true
			reason = "COUNTED VOYAGE RETURNED TO COVE AT NIGHT"
		else:
			reason = "NIGHT SCENE ALREADY ARMED OR SHOWN"
	elif time_state == "DAY":
		reason = "UNAVAILABLE DURING DAY · RETURN FROM A COUNTED VOYAGE TO THE COVE"
	else:
		reason = "NO ELIGIBLE DAY TO NIGHT TRANSITION"
	_last_night_state_evidence = {
		"success": armed,
		"result": (
			"MARA NIGHT SCENE READY"
			if armed
			else "MARA NIGHT SCENE NOT ARMED"
		),
		"reason": reason,
		"time_state_before": state_before,
		"time_state_after": _known_time_state,
		"valid_counted_cove_return_transition": valid_night_transition,
		"night_scene_pending": _night_scene_pending,
		"night_scene_arm_count": _night_scene_arm_count,
		"night_scene_show_count": _night_scene_show_count,
		"shows_one_time": _night_scene_show_count <= 1,
		"transition_evidence": transition_evidence.duplicate(true),
	}
	return _last_night_state_evidence.duplicate(true)


func get_night_scene_status_text() -> String:
	if _known_time_state == "DAY":
		return (
			"MARA NIGHT SCENE · UNAVAILABLE DURING DAY\n"
			+ "NORMAL DIALOGUE AVAILABLE · RETURN FROM A COUNTED VOYAGE TO THE COVE"
		)
	if _night_scene_pending:
		return (
			"MARA NIGHT SCENE · READY\n"
			+ "NEXT ELIGIBLE FRESH TALK AFTER PRIOR DIALOGUE"
		)
	if _night_scene_show_count == 1:
		return "MARA NIGHT SCENE · SHOWN ONCE\nNORMAL DIALOGUE AVAILABLE"
	return "MARA NIGHT SCENE · NOT READY\nNORMAL DIALOGUE AVAILABLE"


func record_important_voyage_event(
	event_id: String,
	event_name: String,
	return_evidence: Dictionary,
) -> bool:
	if (
		_important_event_record_count > 0
		or event_id != IMPORTANT_EVENT_ID
		or event_name != IMPORTANT_EVENT_NAME
		or not bool(return_evidence.get("success", false))
		or not bool(return_evidence.get("monster_defeated", false))
		or int(return_evidence.get("monster_defeat_count", 0)) != 1
		or int(return_evidence.get("return_to_cove_count", 0)) != 1
		or int(return_evidence.get("part_in_cargo_count", 0)) != 1
	):
		return false

	_important_event_record_count = 1
	_reaction_arm_count = 1
	_reaction_pending = true
	_talk_attempt_count_at_arm = _talk_attempt_count
	_last_event_evidence = {
		"success": true,
		"event_id": IMPORTANT_EVENT_ID,
		"event_name": IMPORTANT_EVENT_NAME,
		"event_source": IMPORTANT_EVENT_SOURCE,
		"important_event_record_count": _important_event_record_count,
		"reaction_arm_count": _reaction_arm_count,
		"reaction_pending": _reaction_pending,
		"talk_attempt_count_at_arm": _talk_attempt_count_at_arm,
		"armed_only_after_monster_defeat": true,
		"armed_only_after_return_to_cove": true,
		"return_evidence": return_evidence.duplicate(true),
	}
	return true


func complete_relationship_from_request(
	request_title: String,
	request_state_before: String,
	request_state_after: String,
) -> Dictionary:
	var relationship_before := _relationship_value
	var state_before := _capture_relationship_progress_state()
	if (
		request_title != RELATIONSHIP_REQUEST_TITLE
		or request_state_before != "GOAL_COMPLETE"
		or request_state_after != "COMPLETE"
	):
		_last_relationship_completion_evidence = {
			"success": false,
			"result": "MARA RELATIONSHIP NOT CHANGED",
			"reason": "INVALID_OR_ALREADY_APPLIED_REQUEST_TRANSITION",
			"request_title": request_title,
			"request_state_before": request_state_before,
			"request_state_after": request_state_after,
			"relationship_before": relationship_before,
			"relationship_after": _relationship_value,
			"relationship_unchanged": relationship_before == _relationship_value,
			"increase_count": _relationship_increase_count,
		}
		return _last_relationship_completion_evidence.duplicate(true)
	if _relationship_value == RELATIONSHIP_MAX_VALUE:
		var existing_save_evidence := save_relationship_progress(
			"REQUEST_COMPLETE_ALREADY_APPLIED"
		)
		if bool(existing_save_evidence.get("success", false)):
			_relationship_already_applied_request_count += 1
		_last_relationship_completion_evidence = {
			"success": bool(existing_save_evidence.get("success", false)),
			"result": "MARA RELATIONSHIP 1 -> 1 (+0)",
			"reason": "RELATIONSHIP_INCREASE_ALREADY_PERSISTED",
			"request_title": request_title,
			"request_state_before": request_state_before,
			"request_state_after": request_state_after,
			"exact_request_transition": true,
			"relationship_before": relationship_before,
			"relationship_after": _relationship_value,
			"relationship_increase": 0,
			"relationship_increased": false,
			"duplicate_increase_prevented": true,
			"request_can_complete_after_relationship_load": bool(
				existing_save_evidence.get("success", false)
			),
			"already_applied_request_count": (
				_relationship_already_applied_request_count
			),
			"save_evidence": existing_save_evidence.duplicate(true),
		}
		return _last_relationship_completion_evidence.duplicate(true)
	if (
		_relationship_value != RELATIONSHIP_INITIAL_VALUE
		or _relationship_increase_count != 0
	):
		_last_relationship_completion_evidence = {
			"success": false,
			"result": "MARA RELATIONSHIP NOT CHANGED",
			"reason": "INVALID_RELATIONSHIP_STATE",
			"relationship_before": relationship_before,
			"relationship_after": _relationship_value,
			"increase_count": _relationship_increase_count,
		}
		return _last_relationship_completion_evidence.duplicate(true)

	_relationship_value += RELATIONSHIP_INCREASE
	_relationship_increase_count += 1
	_relationship_threshold_reach_count += 1
	_relationship_scene_pending = true
	var save_evidence := save_relationship_progress("REQUEST_COMPLETE")
	if not bool(save_evidence.get("success", false)):
		_restore_relationship_progress_state(state_before)
		_last_relationship_completion_evidence = {
			"success": false,
			"result": "MARA RELATIONSHIP NOT CHANGED",
			"reason": "SAVE_FAILED",
			"request_title": request_title,
			"request_state_before": request_state_before,
			"request_state_after": request_state_after,
			"relationship_before": relationship_before,
			"relationship_after": _relationship_value,
			"relationship_unchanged": relationship_before == _relationship_value,
			"save_evidence": save_evidence.duplicate(true),
		}
		return _last_relationship_completion_evidence.duplicate(true)

	_last_relationship_completion_evidence = {
		"success": true,
		"result": "MARA RELATIONSHIP 0 -> 1 (+1)",
		"request_title": request_title,
		"request_state_before": request_state_before,
		"request_state_after": request_state_after,
		"exact_request_transition": true,
		"relationship_before": relationship_before,
		"relationship_after": _relationship_value,
		"relationship_increase": RELATIONSHIP_INCREASE,
		"relationship_increased": true,
		"fixed_increase": true,
		"increase_count": _relationship_increase_count,
		"exactly_one_increase": _relationship_increase_count == 1,
		"threshold": RELATIONSHIP_THRESHOLD,
		"threshold_reached": _relationship_value == RELATIONSHIP_THRESHOLD,
		"relationship_scene_pending": _relationship_scene_pending,
		"save_after_request_completion": true,
		"save_evidence": save_evidence.duplicate(true),
	}
	return _last_relationship_completion_evidence.duplicate(true)


func save_relationship_progress(reason: String = "PUBLIC_GAME_SAVE") -> Dictionary:
	var value_before := _relationship_value
	var validation := _validate_relationship_value(_relationship_value)
	if not bool(validation["valid"]):
		_last_relationship_save_evidence = {
			"success": false,
			"result": "MARA RELATIONSHIP NOT SAVED",
			"reason": validation["reason"],
			"path": RELATIONSHIP_SAVE_PATH,
			"save_reason": reason,
			"relationship_value": _relationship_value,
			"save_count": _relationship_save_count,
		}
		return _last_relationship_save_evidence.duplicate(true)

	var config := ConfigFile.new()
	config.set_value(
		RELATIONSHIP_SAVE_SECTION,
		RELATIONSHIP_SAVE_KEY,
		_relationship_value,
	)
	var save_error := config.save(RELATIONSHIP_SAVE_PATH)
	var verification := inspect_relationship_save()
	var success := (
		save_error == OK
		and bool(verification.get("valid", false))
		and int(verification.get("relationship_value", -1)) == _relationship_value
	)
	if success:
		_relationship_save_count += 1
	_last_relationship_save_evidence = {
		"success": success,
		"result": (
			"MARA RELATIONSHIP SAVED"
			if success
			else "MARA RELATIONSHIP SAVE FAILED"
		),
		"reason": (
			"SAVED"
			if success
			else (
				"CONFIG_SAVE_ERROR_%d" % save_error
				if save_error != OK
				else verification.get("reason", "VERIFY_FAILED")
			)
		),
		"path": RELATIONSHIP_SAVE_PATH,
		"save_reason": reason,
		"save_error": save_error,
		"relationship_value_before": value_before,
		"relationship_value_after": _relationship_value,
		"relationship_value_unchanged": value_before == _relationship_value,
		"only_relationship_value_persisted": true,
		"owner_id": RELATIONSHIP_RESIDENT_ID,
		"owner_safe_path": true,
		"verification": verification.duplicate(true),
		"save_count": _relationship_save_count,
	}
	return _last_relationship_save_evidence.duplicate(true)


func load_relationship_progress(reason: String = "PUBLIC_GAME_LOAD") -> Dictionary:
	if reason == "STARTUP":
		_relationship_startup_load_attempt_count += 1
	var relationship_before := _relationship_value
	var scene_pending_before := _relationship_scene_pending
	var file_read := inspect_relationship_save()
	if not bool(file_read.get("valid", false)):
		_relationship_load_reject_count += int(
			String(file_read.get("reason", "")) != "FILE_NOT_FOUND"
		)
		_last_relationship_load_evidence = {
			"success": false,
			"result": "MARA RELATIONSHIP NOT LOADED",
			"reason": file_read.get("reason", "INVALID_FILE"),
			"path": RELATIONSHIP_SAVE_PATH,
			"load_reason": reason,
			"relationship_before": relationship_before,
			"relationship_after": _relationship_value,
			"relationship_unchanged": relationship_before == _relationship_value,
			"scene_pending_before": scene_pending_before,
			"scene_pending_after": _relationship_scene_pending,
			"state_unchanged": (
				relationship_before == _relationship_value
				and scene_pending_before == _relationship_scene_pending
			),
			"invalid_data_rejected_without_state_change": (
				String(file_read.get("reason", "")) == "FILE_NOT_FOUND"
				or (
					relationship_before == _relationship_value
					and scene_pending_before == _relationship_scene_pending
				)
			),
			"file_read": file_read.duplicate(true),
			"load_count": _relationship_load_count,
			"load_reject_count": _relationship_load_reject_count,
			"startup_load_attempt_count": _relationship_startup_load_attempt_count,
		}
		return _last_relationship_load_evidence.duplicate(true)

	_relationship_value = int(file_read["relationship_value"])
	_relationship_scene_pending = (
		_relationship_value >= RELATIONSHIP_THRESHOLD
		and _relationship_scene_show_count == 0
	)
	_relationship_load_count += 1
	_last_relationship_load_evidence = {
		"success": true,
		"result": "MARA RELATIONSHIP LOADED",
		"reason": "LOADED",
		"path": RELATIONSHIP_SAVE_PATH,
		"load_reason": reason,
		"relationship_before": relationship_before,
		"relationship_after": _relationship_value,
		"relationship_value_restored": (
			_relationship_value == int(file_read["relationship_value"])
		),
		"relationship_scene_pending": _relationship_scene_pending,
		"only_relationship_value_loaded": true,
		"owner_id": RELATIONSHIP_RESIDENT_ID,
		"owner_safe_path": true,
		"file_read": file_read.duplicate(true),
		"load_count": _relationship_load_count,
		"load_reject_count": _relationship_load_reject_count,
		"startup_load_attempt_count": _relationship_startup_load_attempt_count,
	}
	return _last_relationship_load_evidence.duplicate(true)


func inspect_relationship_save() -> Dictionary:
	if not FileAccess.file_exists(RELATIONSHIP_SAVE_PATH):
		return {
			"valid": false,
			"reason": "FILE_NOT_FOUND",
			"path": RELATIONSHIP_SAVE_PATH,
			"file_found": false,
			"load_error": ERR_FILE_NOT_FOUND,
		}
	var config := ConfigFile.new()
	var load_error := config.load(RELATIONSHIP_SAVE_PATH)
	if load_error != OK:
		return {
			"valid": false,
			"reason": "CONFIG_LOAD_ERROR_%d" % load_error,
			"path": RELATIONSHIP_SAVE_PATH,
			"file_found": true,
			"load_error": load_error,
		}
	var sections := config.get_sections()
	if sections.size() != 1 or sections[0] != RELATIONSHIP_SAVE_SECTION:
		return {
			"valid": false,
			"reason": "INVALID_CONFIG_SECTIONS",
			"path": RELATIONSHIP_SAVE_PATH,
			"file_found": true,
			"load_error": load_error,
		}
	var section_keys := config.get_section_keys(RELATIONSHIP_SAVE_SECTION)
	if section_keys.size() != 1 or section_keys[0] != RELATIONSHIP_SAVE_KEY:
		return {
			"valid": false,
			"reason": "INVALID_CONFIG_KEYS",
			"path": RELATIONSHIP_SAVE_PATH,
			"file_found": true,
			"load_error": load_error,
		}
	var stored_value = config.get_value(
		RELATIONSHIP_SAVE_SECTION,
		RELATIONSHIP_SAVE_KEY,
	)
	var validation := _validate_relationship_value(stored_value)
	return {
		"valid": validation["valid"],
		"reason": validation["reason"],
		"path": RELATIONSHIP_SAVE_PATH,
		"file_found": true,
		"load_error": load_error,
		"relationship_value": stored_value,
		"owner_id": RELATIONSHIP_RESIDENT_ID,
		"owner_safe_path": true,
		"exact_section_and_key_contract": true,
		"persisted_field_count": 1,
		"only_relationship_value_persisted": true,
	}


func reset_relationship_runtime_for_mcp() -> Dictionary:
	if _talk_open:
		_last_relationship_runtime_reset_evidence = {
			"success": false,
			"result": "MARA RELATIONSHIP RUNTIME RESET DENIED",
			"reason": "TALK_OPEN",
			"state_unchanged": true,
		}
		return _last_relationship_runtime_reset_evidence.duplicate(true)
	var file_exists_before := FileAccess.file_exists(RELATIONSHIP_SAVE_PATH)
	_reset_relationship_runtime_state(true)
	_last_relationship_runtime_reset_evidence = {
		"success": true,
		"result": "MARA RELATIONSHIP RUNTIME RESET",
		"relationship_value": _relationship_value,
		"file_exists_before": file_exists_before,
		"file_exists_after": FileAccess.file_exists(RELATIONSHIP_SAVE_PATH),
		"save_file_preserved": (
			file_exists_before == FileAccess.file_exists(RELATIONSHIP_SAVE_PATH)
		),
	}
	return _last_relationship_runtime_reset_evidence.duplicate(true)


func cleanup_relationship_save_for_mcp() -> Dictionary:
	if _talk_open:
		_last_relationship_cleanup_evidence = {
			"success": false,
			"result": "MARA RELATIONSHIP CLEANUP DENIED",
			"reason": "TALK_OPEN",
			"state_unchanged": true,
		}
		return _last_relationship_cleanup_evidence.duplicate(true)
	var file_existed_before := FileAccess.file_exists(RELATIONSHIP_SAVE_PATH)
	var remove_error := OK
	if file_existed_before:
		remove_error = DirAccess.remove_absolute(
			ProjectSettings.globalize_path(RELATIONSHIP_SAVE_PATH)
		)
	var file_exists_after := FileAccess.file_exists(RELATIONSHIP_SAVE_PATH)
	var success := remove_error == OK and not file_exists_after
	if success:
		_reset_relationship_runtime_state(false)
		if file_existed_before:
			_relationship_cleanup_count += 1
	_last_relationship_cleanup_evidence = {
		"success": success,
		"result": (
			"PHASE 42 MARA RELATIONSHIP FILE REMOVED"
			if success and file_existed_before
			else (
				"PHASE 42 MARA RELATIONSHIP FILE ALREADY ABSENT"
				if success
				else "PHASE 42 MARA RELATIONSHIP FILE REMOVE FAILED"
			)
		),
		"path": RELATIONSHIP_SAVE_PATH,
		"only_exact_relationship_file_targeted": true,
		"file_existed_before": file_existed_before,
		"file_exists_after": file_exists_after,
		"remove_error": remove_error,
		"relationship_value_after": _relationship_value,
		"cleanup_count": _relationship_cleanup_count,
	}
	return _last_relationship_cleanup_evidence.duplicate(true)


func begin_talk(
	normal_dialogue: PackedStringArray,
	request_state: String,
) -> Dictionary:
	if _talk_open or normal_dialogue.is_empty():
		return {
			"success": false,
			"result": "TALK NOT STARTED",
			"talk_already_open": _talk_open,
			"normal_dialogue_empty": normal_dialogue.is_empty(),
		}

	_talk_attempt_count += 1
	_talk_open = true
	var reaction_pending_before := _reaction_pending
	var relationship_scene_pending_before := _relationship_scene_pending
	var night_scene_pending_before := _night_scene_pending
	var priority_conflict := (
		_reaction_pending and _relationship_scene_pending
	)
	if priority_conflict:
		_relationship_priority_conflict_count += 1
	if (
		_night_scene_pending
		and (
			_reaction_pending
			or _normal_talk_after_reaction_pending
			or _relationship_scene_pending
			or _normal_talk_after_relationship_pending
		)
	):
		_night_priority_delay_count += 1
	var dialogue_lines := normal_dialogue.duplicate()
	if _reaction_pending:
		_active_dialogue_kind = REACTION_DIALOGUE_KIND
		dialogue_lines = PackedStringArray([REACTION_DIALOGUE_LINE])
		_reaction_pending = false
		_reaction_show_count += 1
		_reaction_talk_attempt_number = _talk_attempt_count
		_normal_talk_after_reaction_pending = true
		_reaction_request_state_before = request_state
		if priority_conflict:
			_relationship_priority_reaction_win_count += 1
	elif _normal_talk_after_reaction_pending:
		_active_dialogue_kind = NORMAL_DIALOGUE_KIND
		_normal_talk_count += 1
		_normal_talk_after_reaction_pending = false
		_normal_talk_after_reaction_count += 1
	elif _relationship_scene_pending:
		_active_dialogue_kind = RELATIONSHIP_DIALOGUE_KIND
		dialogue_lines = _get_relationship_dialogue()
		_relationship_scene_pending = false
		_relationship_scene_show_count += 1
		_normal_talk_after_relationship_pending = true
	elif _normal_talk_after_relationship_pending:
		_active_dialogue_kind = NORMAL_DIALOGUE_KIND
		_normal_talk_count += 1
		_normal_talk_after_relationship_pending = false
		_relationship_normal_talk_after_count += 1
	elif _night_scene_pending and _known_time_state == "NIGHT":
		_active_dialogue_kind = NIGHT_DIALOGUE_KIND
		dialogue_lines = _get_night_dialogue()
		_night_scene_pending = false
		_night_scene_show_count += 1
		_normal_talk_after_night_pending = true
	elif _normal_talk_after_night_pending:
		_active_dialogue_kind = NORMAL_DIALOGUE_KIND
		_normal_talk_count += 1
		_normal_talk_after_night_pending = false
		_night_scene_normal_talk_after_count += 1
	else:
		_active_dialogue_kind = NORMAL_DIALOGUE_KIND
		_normal_talk_count += 1
	_active_talk_request_state_before = request_state

	_last_talk_evidence = {
		"success": true,
		"talk_attempt_count": _talk_attempt_count,
		"dialogue_kind": _active_dialogue_kind,
		"dialogue_lines": dialogue_lines.duplicate(),
		"request_state_before": request_state,
		"reaction_pending_before": reaction_pending_before,
		"reaction_pending_after": _reaction_pending,
		"relationship_scene_pending_before": relationship_scene_pending_before,
		"relationship_scene_pending_after": _relationship_scene_pending,
		"relationship_scene_show_count": _relationship_scene_show_count,
		"night_scene_pending_before": night_scene_pending_before,
		"night_scene_pending_after": _night_scene_pending,
		"night_scene_show_count": _night_scene_show_count,
		"priority_conflict": priority_conflict,
		"dialogue_priority": _get_dialogue_priority(),
		"important_reaction_won_priority": (
			not priority_conflict
			or _active_dialogue_kind == REACTION_DIALOGUE_KIND
		),
		"normal_dialogue_forced_after_reaction": (
			_active_dialogue_kind == NORMAL_DIALOGUE_KIND
			and reaction_pending_before == false
			and relationship_scene_pending_before
			and _normal_talk_after_reaction_count > 0
		),
		"reaction_show_count": _reaction_show_count,
		"normal_talk_count": _normal_talk_count,
		"normal_talk_after_reaction_count": _normal_talk_after_reaction_count,
		"night_scene_waited_for_earlier_priority": (
			not night_scene_pending_before
			or _active_dialogue_kind == NIGHT_DIALOGUE_KIND
			or _active_dialogue_kind == REACTION_DIALOGUE_KIND
			or _active_dialogue_kind == RELATIONSHIP_DIALOGUE_KIND
			or _active_dialogue_kind == NORMAL_DIALOGUE_KIND
		),
		"fresh_press_required": true,
		"next_talk_after_arm": (
			_active_dialogue_kind == REACTION_DIALOGUE_KIND
			and _reaction_talk_attempt_number == _talk_attempt_count_at_arm + 1
		),
	}
	return _last_talk_evidence.duplicate(true)


func finish_talk(request_state: String) -> Dictionary:
	if not _talk_open:
		return {"success": false, "result": "NO TALK OPEN"}

	var finished_dialogue_kind := _active_dialogue_kind
	_talk_open = false
	_active_dialogue_kind = ""
	if finished_dialogue_kind == REACTION_DIALOGUE_KIND:
		_reaction_finish_count += 1
	elif finished_dialogue_kind == RELATIONSHIP_DIALOGUE_KIND:
		_relationship_scene_finish_count += 1
	elif finished_dialogue_kind == NIGHT_DIALOGUE_KIND:
		_night_scene_finish_count += 1
	_last_talk_finish_evidence = {
		"success": true,
		"dialogue_kind": finished_dialogue_kind,
		"request_state_before": _reaction_request_state_before,
		"request_state_after": request_state,
		"active_talk_request_state_before": _active_talk_request_state_before,
		"request_state_unchanged_by_reaction": (
			finished_dialogue_kind != REACTION_DIALOGUE_KIND
			or _reaction_request_state_before == request_state
		),
		"request_state_unchanged_by_relationship_scene": (
			finished_dialogue_kind != RELATIONSHIP_DIALOGUE_KIND
			or _active_talk_request_state_before == request_state
		),
		"reaction_finish_count": _reaction_finish_count,
		"reaction_show_count": _reaction_show_count,
		"relationship_scene_finish_count": _relationship_scene_finish_count,
		"relationship_scene_show_count": _relationship_scene_show_count,
		"night_scene_finish_count": _night_scene_finish_count,
		"night_scene_show_count": _night_scene_show_count,
		"request_state_unchanged_by_night_scene": (
			finished_dialogue_kind != NIGHT_DIALOGUE_KIND
			or _active_talk_request_state_before == request_state
		),
	}
	return _last_talk_finish_evidence.duplicate(true)


func record_held_talk_input(request_state: String) -> Dictionary:
	_held_talk_input_count += 1
	_last_held_talk_evidence = {
		"success": false,
		"result": "NO TALK CHANGE · RELEASE E",
		"rejection_reason": "HELD_INTERACTION",
		"dialogue_open": _talk_open,
		"dialogue_kind": _active_dialogue_kind,
		"request_state_before": request_state,
		"request_state_after": request_state,
		"important_event_record_count_before": _important_event_record_count,
		"important_event_record_count_after": _important_event_record_count,
		"reaction_show_count_before": _reaction_show_count,
		"reaction_show_count_after": _reaction_show_count,
		"relationship_value_before": _relationship_value,
		"relationship_value_after": _relationship_value,
		"relationship_scene_show_count_before": _relationship_scene_show_count,
		"relationship_scene_show_count_after": _relationship_scene_show_count,
		"night_scene_show_count_before": _night_scene_show_count,
		"night_scene_show_count_after": _night_scene_show_count,
		"night_scene_pending_before": _night_scene_pending,
		"night_scene_pending_after": _night_scene_pending,
		"normal_talk_count_before": _normal_talk_count,
		"normal_talk_count_after": _normal_talk_count,
		"fresh_press_required": true,
		"no_state_change": true,
	}
	return _last_held_talk_evidence.duplicate(true)


func get_playtest_state() -> Dictionary:
	var normal_request_dialogue_unchanged := (
		request_offer_dialogue == PackedStringArray([
			"The eastern dock took another hard wave.",
			"Please inspect the damaged boards and tell me what you find.",
		])
		and request_active_dialogue == PackedStringArray([
			"The damaged dock is east of here.",
			"Tell me what you find after you inspect it.",
		])
		and request_report_dialogue == PackedStringArray([
			"You found the split supports before they gave way.",
			"Thank you. Take my ruin pry bar. It can open one blocked stone path.",
		])
		and request_complete_dialogue == PackedStringArray([
			"The dock will hold until we can repair those supports.",
			"Keep the ruin pry bar. It can open the blocked path in the test island ruin.",
		])
	)
	return {
		"system_count": 1,
		"owner_count": 1,
		"named_resident_count": 1,
		"resident_name": display_name,
		"important_event_type_count": 1,
		"important_event_id": IMPORTANT_EVENT_ID,
		"important_event_name": IMPORTANT_EVENT_NAME,
		"important_event_source": IMPORTANT_EVENT_SOURCE,
		"important_event_record_count": _important_event_record_count,
		"records_exactly_one_important_event": _important_event_record_count == 1,
		"records_at_most_one_important_event": _important_event_record_count <= 1,
		"last_event_evidence": _last_event_evidence.duplicate(true),
		"reaction_dialogue_kind": REACTION_DIALOGUE_KIND,
		"reaction_dialogue": PackedStringArray([REACTION_DIALOGUE_LINE]),
		"reaction_arm_count": _reaction_arm_count,
		"reaction_pending": _reaction_pending,
		"reaction_show_count": _reaction_show_count,
		"reaction_finish_count": _reaction_finish_count,
		"reaction_shows_one_time": _reaction_show_count <= 1,
		"reaction_armed_one_time": _reaction_arm_count <= 1,
		"talk_attempt_count": _talk_attempt_count,
		"talk_attempt_count_at_arm": _talk_attempt_count_at_arm,
		"reaction_talk_attempt_number": _reaction_talk_attempt_number,
		"reaction_is_next_talk_after_event": (
			_important_event_record_count == 0
			or (
				_reaction_show_count == 0
				and _reaction_pending
				and _talk_attempt_count == _talk_attempt_count_at_arm
			)
			or (
				_reaction_show_count == 1
				and _reaction_talk_attempt_number == _talk_attempt_count_at_arm + 1
			)
		),
		"talk_open": _talk_open,
		"active_dialogue_kind": _active_dialogue_kind,
		"normal_dialogue_kind": NORMAL_DIALOGUE_KIND,
		"normal_talk_count": _normal_talk_count,
		"normal_talk_after_reaction_pending": (
			_normal_talk_after_reaction_pending
		),
		"normal_talk_after_reaction_count": (
			_normal_talk_after_reaction_count
		),
		"normal_dialogue_available_after_reaction": (
			_reaction_show_count == 1
			and not _reaction_pending
			and not _talk_open
		),
		"normal_request_dialogue_unchanged": normal_request_dialogue_unchanged,
		"held_talk_input_count": _held_talk_input_count,
		"fresh_press_required": true,
		"last_talk_evidence": _last_talk_evidence.duplicate(true),
		"last_talk_finish_evidence": _last_talk_finish_evidence.duplicate(true),
		"last_held_talk_evidence": _last_held_talk_evidence.duplicate(true),
		"relationship_system_count": 1,
		"relationship_owner_count": 1,
		"relationship_named_resident_count": 1,
		"relationship_resident_id": RELATIONSHIP_RESIDENT_ID,
		"relationship_resident_name": display_name,
		"relationship_value_count": 1,
		"relationship_point_count": 0,
		"relationship_value": _relationship_value,
		"relationship_initial_value": RELATIONSHIP_INITIAL_VALUE,
		"relationship_max_value": RELATIONSHIP_MAX_VALUE,
		"relationship_increase_amount": RELATIONSHIP_INCREASE,
		"relationship_increase_count": _relationship_increase_count,
		"relationship_already_applied_request_count": (
			_relationship_already_applied_request_count
		),
		"relationship_exactly_one_fixed_increase": (
			_relationship_increase_count <= 1
			and RELATIONSHIP_INCREASE == 1
		),
		"relationship_request_title": RELATIONSHIP_REQUEST_TITLE,
		"relationship_exact_request_transition": "GOAL_COMPLETE -> COMPLETE",
		"relationship_last_completion_evidence": (
			_last_relationship_completion_evidence.duplicate(true)
		),
		"relationship_result_text": String(
			_last_relationship_completion_evidence.get("result", "")
		),
		"relationship_threshold_count": 1,
		"relationship_threshold": RELATIONSHIP_THRESHOLD,
		"relationship_threshold_reached": (
			_relationship_value >= RELATIONSHIP_THRESHOLD
		),
		"relationship_threshold_reach_count": _relationship_threshold_reach_count,
		"relationship_scene_count": 1,
		"relationship_scene_dialogue_kind": RELATIONSHIP_DIALOGUE_KIND,
		"relationship_scene_dialogue": _get_relationship_dialogue(),
		"relationship_scene_pending": _relationship_scene_pending,
		"relationship_scene_available": (
			_relationship_value >= RELATIONSHIP_THRESHOLD
			and _relationship_scene_show_count == 0
		),
		"relationship_scene_show_count": _relationship_scene_show_count,
		"relationship_scene_finish_count": _relationship_scene_finish_count,
		"relationship_scene_shows_once_per_runtime": (
			_relationship_scene_show_count <= 1
		),
		"relationship_normal_talk_after_pending": (
			_normal_talk_after_relationship_pending
		),
		"relationship_normal_talk_after_count": (
			_relationship_normal_talk_after_count
		),
		"relationship_normal_dialogue_available_after_scene": (
			_relationship_scene_show_count == 1
			and not _relationship_scene_pending
			and not _talk_open
		),
		"dialogue_priority": _get_dialogue_priority(),
		"dialogue_priority_conflict_count": _relationship_priority_conflict_count,
		"dialogue_priority_reaction_win_count": (
			_relationship_priority_reaction_win_count
		),
		"phase41_reaction_has_priority": true,
		"phase41_normal_talk_keeps_priority_after_reaction": true,
		"relationship_save_path": RELATIONSHIP_SAVE_PATH,
		"relationship_save_section": RELATIONSHIP_SAVE_SECTION,
		"relationship_save_key": RELATIONSHIP_SAVE_KEY,
		"relationship_save_count": _relationship_save_count,
		"relationship_load_count": _relationship_load_count,
		"relationship_load_reject_count": _relationship_load_reject_count,
		"relationship_startup_load_attempt_count": (
			_relationship_startup_load_attempt_count
		),
		"relationship_cleanup_count": _relationship_cleanup_count,
		"relationship_save_file_exists": FileAccess.file_exists(
			RELATIONSHIP_SAVE_PATH
		),
		"relationship_only_value_persisted": true,
		"relationship_owner_safe_path": true,
		"relationship_last_save_evidence": (
			_last_relationship_save_evidence.duplicate(true)
		),
		"relationship_last_load_evidence": (
			_last_relationship_load_evidence.duplicate(true)
		),
		"relationship_last_cleanup_evidence": (
			_last_relationship_cleanup_evidence.duplicate(true)
		),
		"relationship_last_runtime_reset_evidence": (
			_last_relationship_runtime_reset_evidence.duplicate(true)
		),
		"romance_system_count": 0,
		"gift_system_count": 0,
		"relationship_decay_system_count": 0,
		"relationship_currency_count": 1,
		"multiple_relationship_currency_count": 0,
		"unnamed_resident_opinion_count": 0,
		"reputation_system_count": 0,
		"daily_schedule_system_count": 0,
		"passive_stat_bonus_count": 0,
		"day_state_count": 0,
		"night_state_count": 0,
		"time_advance_system_count": 0,
		"night_only_scene_count": 1,
		"night_scene_dialogue_kind": NIGHT_DIALOGUE_KIND,
		"night_scene_dialogue": _get_night_dialogue(),
		"known_time_state": _known_time_state,
		"night_scene_arm_count": _night_scene_arm_count,
		"night_scene_pending": _night_scene_pending,
		"night_scene_available": (
			_known_time_state == "NIGHT"
			and _night_scene_pending
			and _night_scene_show_count == 0
		),
		"night_scene_block_reason": (
			"UNAVAILABLE DURING DAY · RETURN FROM A COUNTED VOYAGE TO THE COVE"
			if _known_time_state == "DAY"
			else ""
		),
		"night_scene_status_text": get_night_scene_status_text(),
		"night_scene_show_count": _night_scene_show_count,
		"night_scene_finish_count": _night_scene_finish_count,
		"night_scene_shows_one_time": _night_scene_show_count <= 1,
		"night_scene_arm_once": _night_scene_arm_count <= 1,
		"night_scene_normal_talk_after_pending": (
			_normal_talk_after_night_pending
		),
		"night_scene_normal_talk_after_count": (
			_night_scene_normal_talk_after_count
		),
		"night_scene_normal_dialogue_available_after": (
			_night_scene_show_count == 1
			and not _night_scene_pending
			and not _talk_open
		),
		"night_priority_delay_count": _night_priority_delay_count,
		"last_night_state_evidence": (
			_last_night_state_evidence.duplicate(true)
		),
		"reaction_to_every_action_count": 0,
	}


func _validate_relationship_value(value) -> Dictionary:
	if typeof(value) != TYPE_INT:
		return {"valid": false, "reason": "INVALID_VALUE_TYPE"}
	var relationship_value := int(value)
	if (
		relationship_value < RELATIONSHIP_INITIAL_VALUE
		or relationship_value > RELATIONSHIP_MAX_VALUE
	):
		return {"valid": false, "reason": "VALUE_OUT_OF_RANGE"}
	return {"valid": true, "reason": "VALID"}


func _get_relationship_dialogue() -> PackedStringArray:
	return PackedStringArray([
		RELATIONSHIP_DIALOGUE_LINE_1,
		RELATIONSHIP_DIALOGUE_LINE_2,
	])


func _get_night_dialogue() -> PackedStringArray:
	return PackedStringArray([
		NIGHT_DIALOGUE_LINE_1,
		NIGHT_DIALOGUE_LINE_2,
	])


func _get_dialogue_priority() -> PackedStringArray:
	return PackedStringArray([
		REACTION_DIALOGUE_KIND,
		"NORMAL_AFTER_IMPORTANT_EVENT_REACTION",
		RELATIONSHIP_DIALOGUE_KIND,
		"NORMAL_AFTER_RELATIONSHIP_THRESHOLD_SCENE",
		NIGHT_DIALOGUE_KIND,
		NORMAL_DIALOGUE_KIND,
	])


func _capture_relationship_progress_state() -> Dictionary:
	return {
		"relationship_value": _relationship_value,
		"increase_count": _relationship_increase_count,
		"threshold_reach_count": _relationship_threshold_reach_count,
		"scene_pending": _relationship_scene_pending,
	}


func _restore_relationship_progress_state(snapshot: Dictionary) -> void:
	_relationship_value = int(snapshot["relationship_value"])
	_relationship_increase_count = int(snapshot["increase_count"])
	_relationship_threshold_reach_count = int(snapshot["threshold_reach_count"])
	_relationship_scene_pending = bool(snapshot["scene_pending"])


func _reset_relationship_runtime_state(
	preserve_persistence_tracking: bool,
) -> void:
	_relationship_value = RELATIONSHIP_INITIAL_VALUE
	_relationship_increase_count = 0
	_relationship_already_applied_request_count = 0
	_relationship_threshold_reach_count = 0
	_relationship_scene_show_count = 0
	_relationship_scene_finish_count = 0
	_relationship_normal_talk_after_count = 0
	_relationship_scene_pending = false
	_relationship_priority_conflict_count = 0
	_relationship_priority_reaction_win_count = 0
	_normal_talk_after_relationship_pending = false
	_last_relationship_completion_evidence = {}
	if not preserve_persistence_tracking:
		_relationship_save_count = 0
		_relationship_load_count = 0
		_relationship_load_reject_count = 0
		_relationship_startup_load_attempt_count = 0
		_last_relationship_save_evidence = {}
		_last_relationship_load_evidence = {}
		_last_relationship_runtime_reset_evidence = {}


func _draw() -> void:
	draw_ellipse(Vector2(0, 14), 20.0, 8.0, Color("#12323c66"))
	draw_circle(Vector2.ZERO, 16.0, Color("#3c7280"))
	draw_circle(Vector2(0, -12), 10.0, Color("#b87952"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-16, -16), Vector2(-8, -25), Vector2(8, -25),
		Vector2(16, -16), Vector2(10, -11), Vector2(-10, -11),
	]), Color("#633f2a"))
	draw_line(Vector2(-9, 2), Vector2(9, 2), Color("#e2bf72"), 3.0)
