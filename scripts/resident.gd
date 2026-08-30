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
const REACTION_DIALOGUE_LINE := (
	"You brought the Blackwake Leviathan down and returned with proof. "
	+ "The cove will remember that."
)

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
var _talk_open := false
var _active_dialogue_kind := ""
var _reaction_request_state_before := ""
var _last_event_evidence: Dictionary = {}
var _last_talk_evidence: Dictionary = {}
var _last_talk_finish_evidence: Dictionary = {}
var _last_held_talk_evidence: Dictionary = {}


func _ready() -> void:
	queue_redraw()


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
	var dialogue_lines := normal_dialogue.duplicate()
	if _reaction_pending:
		_active_dialogue_kind = REACTION_DIALOGUE_KIND
		dialogue_lines = PackedStringArray([REACTION_DIALOGUE_LINE])
		_reaction_pending = false
		_reaction_show_count += 1
		_reaction_talk_attempt_number = _talk_attempt_count
		_normal_talk_after_reaction_pending = true
		_reaction_request_state_before = request_state
	else:
		_active_dialogue_kind = NORMAL_DIALOGUE_KIND
		_normal_talk_count += 1
		if _normal_talk_after_reaction_pending:
			_normal_talk_after_reaction_pending = false
			_normal_talk_after_reaction_count += 1

	_last_talk_evidence = {
		"success": true,
		"talk_attempt_count": _talk_attempt_count,
		"dialogue_kind": _active_dialogue_kind,
		"dialogue_lines": dialogue_lines.duplicate(),
		"request_state_before": request_state,
		"reaction_pending_before": reaction_pending_before,
		"reaction_pending_after": _reaction_pending,
		"reaction_show_count": _reaction_show_count,
		"normal_talk_count": _normal_talk_count,
		"normal_talk_after_reaction_count": _normal_talk_after_reaction_count,
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
	_last_talk_finish_evidence = {
		"success": true,
		"dialogue_kind": finished_dialogue_kind,
		"request_state_before": _reaction_request_state_before,
		"request_state_after": request_state,
		"request_state_unchanged_by_reaction": (
			finished_dialogue_kind != REACTION_DIALOGUE_KIND
			or _reaction_request_state_before == request_state
		),
		"reaction_finish_count": _reaction_finish_count,
		"reaction_show_count": _reaction_show_count,
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
		"relationship_value_count": 0,
		"relationship_point_count": 0,
		"relationship_increase_count": 0,
		"relationship_threshold_count": 0,
		"relationship_scene_count": 0,
		"relationship_save_count": 0,
		"relationship_load_count": 0,
		"romance_system_count": 0,
		"unnamed_resident_opinion_count": 0,
		"reputation_system_count": 0,
		"daily_schedule_system_count": 0,
		"reaction_to_every_action_count": 0,
	}


func _draw() -> void:
	draw_ellipse(Vector2(0, 14), 20.0, 8.0, Color("#12323c66"))
	draw_circle(Vector2.ZERO, 16.0, Color("#3c7280"))
	draw_circle(Vector2(0, -12), 10.0, Color("#b87952"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-16, -16), Vector2(-8, -25), Vector2(8, -25),
		Vector2(16, -16), Vector2(10, -11), Vector2(-10, -11),
	]), Color("#633f2a"))
	draw_line(Vector2(-9, 2), Vector2(9, 2), Color("#e2bf72"), 3.0)
