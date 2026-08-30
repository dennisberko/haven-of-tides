class_name RuinExplorationState
extends Node2D

const RUIN_ID := "test_island_ruin"
const ENTRANCE_POSITION := Vector2(1550.0, 1170.0)
const ISLAND_RETURN_POSITION := Vector2(1550.0, 1215.0)
const ENTRANCE_RANGE := 62.0
const RUIN_WALKING_RECT := Rect2(3440.0, 1840.0, 920.0, 280.0)
const RUIN_ENTRY_POSITION := Vector2(3520.0, 1980.0)
const RUIN_EXIT_POSITION := Vector2(3480.0, 1980.0)
const TREASURE_POSITION := Vector2(3990.0, 1980.0)
const TOOL_GATE_POSITION := Vector2(4110.0, 1980.0)
const GATED_TREASURE_POSITION := Vector2(4280.0, 1980.0)
const EXIT_RANGE := 58.0
const TREASURE_RANGE := 62.0
const TOOL_GATE_RANGE := 78.0
const TREASURE_LOT_NAME := "RUIN TREASURE LOT"
const TREASURE_PRICE_STATE := "NORMAL"
const EXPLORATION_TOOL_NAME := "RUIN PRY BAR"
const EXPLORATION_TOOL_SOURCE := "MARA'S DAMAGED DOCK REQUEST"
const ORIGINAL_TREASURE_ID := "original_treasure"
const GATED_TREASURE_ID := "gated_treasure"
const PATH_LENGTH := 470.0
const VIEWPORT_SIZE := Vector2(1152.0, 648.0)
const ENTRANCE_VISUAL_RECT := Rect2(
	ENTRANCE_POSITION + Vector2(-100.0, -60.0),
	Vector2(200.0, 120.0),
)

var _inside_ruin := false
var _treasure_available := true
var _treasure_collected := false
var _gated_treasure_available := true
var _gated_treasure_collected := false
var _treasure_choice_pending := false
var _pending_treasure_id := ""
var _exploration_tool_owned := false
var _tool_gate_open := false
var _transition_release_pending := false
var _player_position := Vector2.ZERO
var _dock_shore_id := ""
var _player_movement_enabled := false
var _entrance_distance := INF
var _exit_distance := INF
var _treasure_distance := INF
var _tool_gate_distance := INF
var _gated_treasure_distance := INF
var _walking_distance := 0.0
var _walking_furthest_progress := 0.0
var _previous_ruin_position := Vector2.ZERO
var _entrance_attempt_count := 0
var _entrance_success_count := 0
var _exit_attempt_count := 0
var _exit_success_count := 0
var _treasure_attempt_count := 0
var _treasure_collection_count := 0
var _original_treasure_collection_count := 0
var _gated_treasure_collection_count := 0
var _direct_keep_count := 0
var _choice_required_count := 0
var _leave_in_place_count := 0
var _replacement_keep_count := 0
var _displaced_cargo_discard_count := 0
var _held_input_count := 0
var _transition_release_count := 0
var _return_to_island_count := 0
var _return_to_ship_count := 0
var _sale_count := 0
var _tool_award_count := 0
var _tool_gate_attempt_count := 0
var _tool_gate_denied_count := 0
var _tool_gate_open_count := 0
var _gate_open_exit_count := 0
var _gate_open_return_entry_count := 0
var _last_transition_evidence: Dictionary = {}
var _last_treasure_evidence: Dictionary = {}
var _last_choice_evidence: Dictionary = {}
var _last_held_input_evidence: Dictionary = {}
var _last_sale_evidence: Dictionary = {}
var _last_tool_award_evidence: Dictionary = {}
var _last_tool_gate_evidence: Dictionary = {}
var _last_denied_tool_gate_evidence: Dictionary = {}
var _successful_tool_gate_evidence: Dictionary = {}
var _pending_cargo_snapshot: Array[String] = []

@onready var tool_gate_collision: CollisionShape2D = (
	$ToolGateBlocker/CollisionShape2D
)


func _ready() -> void:
	_sync_tool_gate_collision()
	queue_redraw()


func update_state(
	player_position: Vector2,
	dock_shore_id: String,
	player_movement_enabled: bool,
) -> void:
	_player_position = player_position
	_dock_shore_id = dock_shore_id
	_player_movement_enabled = player_movement_enabled
	_entrance_distance = _player_position.distance_to(ENTRANCE_POSITION)
	_exit_distance = _player_position.distance_to(RUIN_EXIT_POSITION)
	_treasure_distance = _player_position.distance_to(TREASURE_POSITION)
	_tool_gate_distance = _player_position.distance_to(TOOL_GATE_POSITION)
	_gated_treasure_distance = _player_position.distance_to(
		GATED_TREASURE_POSITION
	)
	if not _inside_ruin:
		return
	if _previous_ruin_position == Vector2.ZERO:
		_previous_ruin_position = _player_position
	var frame_distance := _previous_ruin_position.distance_to(_player_position)
	if frame_distance <= 16.0:
		_walking_distance += frame_distance
	_previous_ruin_position = _player_position
	_walking_furthest_progress = maxf(
		_walking_furthest_progress,
		clampf(
			_player_position.x - RUIN_ENTRY_POSITION.x,
			0.0,
			PATH_LENGTH,
		),
	)


func can_enter() -> bool:
	return (
		not _inside_ruin
		and _dock_shore_id == "island"
		and _entrance_distance <= ENTRANCE_RANGE
		and not _transition_release_pending
	)


func can_take_treasure() -> bool:
	return (
		_inside_ruin
		and not _treasure_choice_pending
		and not _transition_release_pending
		and not _get_available_treasure_id().is_empty()
	)


func is_near_tool_gate() -> bool:
	return _inside_ruin and _tool_gate_distance <= TOOL_GATE_RANGE


func can_interact_tool_gate() -> bool:
	return (
		is_near_tool_gate()
		and not _tool_gate_open
		and not _treasure_choice_pending
		and not _transition_release_pending
	)


func can_exit() -> bool:
	return (
		_inside_ruin
		and _exit_distance <= EXIT_RANGE
		and not _treasure_choice_pending
		and not _transition_release_pending
	)


func is_inside() -> bool:
	return _inside_ruin


func is_transition_release_pending() -> bool:
	return _transition_release_pending


func has_pending_treasure_choice() -> bool:
	return _treasure_choice_pending


func is_treasure_available() -> bool:
	return _treasure_available


func get_walking_region() -> Dictionary:
	return {
		"kind": "RECTANGLE",
		"rect": RUIN_WALKING_RECT,
	}


func get_interaction_prompt() -> String:
	if _transition_release_pending:
		return ""
	if _inside_ruin:
		if can_take_treasure():
			return "[E] TAKE ONE RUIN TREASURE LOT"
		if can_interact_tool_gate():
			if _exploration_tool_owned:
				return "[E] OPEN BLOCKED PATH WITH RUIN PRY BAR"
			return "[E] BLOCKED PATH · NEED RUIN PRY BAR"
		if can_exit():
			return "[E] EXIT RUIN TO TEST ISLAND"
		return ""
	if can_enter():
		return "[E] ENTER TEST ISLAND RUIN"
	return ""


func try_enter(cargo_lots: Array[String]) -> bool:
	_entrance_attempt_count += 1
	if not can_enter():
		_last_transition_evidence = {
			"action": "ENTER_RUIN",
			"success": false,
			"cargo_before": cargo_lots.duplicate(),
			"cargo_after": cargo_lots.duplicate(),
			"cargo_unchanged": true,
			"reason": "ENTRANCE_NOT_AVAILABLE",
		}
		return false
	_inside_ruin = true
	_entrance_success_count += 1
	if _tool_gate_open:
		_gate_open_return_entry_count += 1
	_previous_ruin_position = RUIN_ENTRY_POSITION
	_begin_transition_guard("ENTER_RUIN", cargo_lots)
	queue_redraw()
	return true


func try_exit(cargo_lots: Array[String]) -> bool:
	_exit_attempt_count += 1
	if not can_exit():
		_last_transition_evidence = {
			"action": "EXIT_RUIN",
			"success": false,
			"cargo_before": cargo_lots.duplicate(),
			"cargo_after": cargo_lots.duplicate(),
			"cargo_unchanged": true,
			"reason": "EXIT_NOT_AVAILABLE",
		}
		return false
	_inside_ruin = false
	_exit_success_count += 1
	_return_to_island_count += 1
	if _tool_gate_open:
		_gate_open_exit_count += 1
	_previous_ruin_position = Vector2.ZERO
	_begin_transition_guard("EXIT_RUIN", cargo_lots)
	queue_redraw()
	return true


func award_exploration_tool_from_request(
	request_title: String,
	request_state_before: String,
	request_state_after: String,
	cargo_lots: Array[String],
	money: int,
) -> bool:
	var cargo_before := cargo_lots.duplicate()
	var money_before := money
	if (
		_exploration_tool_owned
		or request_title != "DAMAGED DOCK"
		or request_state_before != "GOAL_COMPLETE"
		or request_state_after != "COMPLETE"
	):
		_last_tool_award_evidence = {
			"action": "AWARD_EXPLORATION_TOOL",
			"success": false,
			"tool_name": EXPLORATION_TOOL_NAME,
			"request_title": request_title,
			"request_state_before": request_state_before,
			"request_state_after": request_state_after,
			"cargo_before": cargo_before,
			"cargo_after": cargo_lots.duplicate(),
			"cargo_unchanged": cargo_before == cargo_lots,
			"money_before": money_before,
			"money_after": money,
			"money_unchanged": money_before == money,
			"reason": "REQUEST_NOT_ELIGIBLE_OR_TOOL_ALREADY_OWNED",
		}
		return false
	_exploration_tool_owned = true
	_tool_award_count += 1
	_last_tool_award_evidence = {
		"action": "AWARD_EXPLORATION_TOOL",
		"success": true,
		"tool_name": EXPLORATION_TOOL_NAME,
		"tool_source": EXPLORATION_TOOL_SOURCE,
		"request_title": request_title,
		"request_state_before": request_state_before,
		"request_state_after": request_state_after,
		"cargo_before": cargo_before,
		"cargo_after": cargo_lots.duplicate(),
		"cargo_unchanged": cargo_before == cargo_lots,
		"money_before": money_before,
		"money_after": money,
		"money_unchanged": money_before == money,
		"tool_award_count": _tool_award_count,
		"one_test_request_used": true,
	}
	queue_redraw()
	return true


func try_open_tool_gate(
	cargo_lots: Array[String],
	money: int,
) -> bool:
	_tool_gate_attempt_count += 1
	var cargo_before := cargo_lots.duplicate()
	var money_before := money
	if not can_interact_tool_gate() or not _exploration_tool_owned:
		_tool_gate_denied_count += 1
		_last_tool_gate_evidence = {
			"action": "OPEN_TOOL_GATE",
			"success": false,
			"required_tool": EXPLORATION_TOOL_NAME,
			"tool_owned": _exploration_tool_owned,
			"gate_open_before": _tool_gate_open,
			"gate_open_after": _tool_gate_open,
			"path_stayed_closed": not _tool_gate_open,
			"cargo_before": cargo_before,
			"cargo_after": cargo_lots.duplicate(),
			"cargo_unchanged": cargo_before == cargo_lots,
			"money_before": money_before,
			"money_after": money,
			"money_unchanged": money_before == money,
			"reason": (
				"NEED_RUIN_PRY_BAR"
				if not _exploration_tool_owned
				else "GATE_INTERACTION_NOT_AVAILABLE"
			),
		}
		_last_denied_tool_gate_evidence = _last_tool_gate_evidence.duplicate(true)
		return false
	_tool_gate_open = true
	_tool_gate_open_count += 1
	_sync_tool_gate_collision()
	_last_tool_gate_evidence = {
		"action": "OPEN_TOOL_GATE",
		"success": true,
		"required_tool": EXPLORATION_TOOL_NAME,
		"tool_owned": _exploration_tool_owned,
		"gate_open_before": false,
		"gate_open_after": true,
		"gate_open_count": _tool_gate_open_count,
		"cargo_before": cargo_before,
		"cargo_after": cargo_lots.duplicate(),
		"cargo_unchanged": cargo_before == cargo_lots,
		"money_before": money_before,
		"money_after": money,
		"money_unchanged": money_before == money,
		"tool_consumed": false,
		"gate_state_persistent": true,
	}
	_successful_tool_gate_evidence = _last_tool_gate_evidence.duplicate(true)
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
		"inside_ruin_before": _inside_ruin,
		"inside_ruin_after": _inside_ruin,
		"treasure_available_before": _treasure_available,
		"treasure_available_after": _treasure_available,
		"treasure_collection_count_before": _treasure_collection_count,
		"treasure_collection_count_after": _treasure_collection_count,
		"tool_owned_before": _exploration_tool_owned,
		"tool_owned_after": _exploration_tool_owned,
		"tool_gate_open_before": _tool_gate_open,
		"tool_gate_open_after": _tool_gate_open,
		"tool_gate_open_count_before": _tool_gate_open_count,
		"tool_gate_open_count_after": _tool_gate_open_count,
		"cargo_before": cargo_lots.duplicate(),
		"cargo_after": cargo_lots.duplicate(),
		"cargo_unchanged": true,
		"fresh_press_required": true,
		"result": "NO_CHANGE_HELD_OR_TRANSITION_GUARD",
	}


func release_transition_guard() -> bool:
	if not _transition_release_pending:
		return false
	_transition_release_pending = false
	_transition_release_count += 1
	_last_transition_evidence["release_guard_cleared"] = true
	_last_transition_evidence["transition_release_count"] = (
		_transition_release_count
	)
	return true


func begin_treasure_choice(cargo_before: Array[String]) -> bool:
	_treasure_attempt_count += 1
	var treasure_id := _get_available_treasure_id()
	if not can_take_treasure():
		_last_treasure_evidence = {
			"action": "TAKE_TREASURE",
			"success": false,
			"cargo_before": cargo_before.duplicate(),
			"cargo_after": cargo_before.duplicate(),
			"cargo_unchanged": true,
			"reason": "TREASURE_NOT_AVAILABLE",
		}
		return false
	_treasure_choice_pending = true
	_pending_treasure_id = treasure_id
	_choice_required_count += 1
	_pending_cargo_snapshot = cargo_before.duplicate()
	_last_treasure_evidence = {
		"action": "TAKE_TREASURE",
		"success": false,
		"resolution": "CARGO_CHOICE_REQUIRED",
		"treasure_id": treasure_id,
		"treasure_lot": TREASURE_LOT_NAME,
		"cargo_before": cargo_before.duplicate(),
		"cargo_after": cargo_before.duplicate(),
		"cargo_unchanged_before_choice": true,
		"fresh_press_required": true,
	}
	_last_choice_evidence = _last_treasure_evidence.duplicate(true)
	return true


func collect_direct(
	cargo_before: Array[String],
	cargo_after: Array[String],
) -> bool:
	_treasure_attempt_count += 1
	var treasure_id := _get_available_treasure_id()
	if not can_take_treasure():
		return false
	if (
		cargo_after.size() != cargo_before.size() + 1
		or cargo_after.count(TREASURE_LOT_NAME)
			!= cargo_before.count(TREASURE_LOT_NAME) + 1
	):
		return false
	if not _collect_treasure_state(treasure_id):
		return false
	_treasure_collection_count += 1
	_direct_keep_count += 1
	_last_treasure_evidence = {
		"action": "TAKE_TREASURE",
		"success": true,
		"resolution": "DIRECT_KEEP",
		"treasure_id": treasure_id,
		"treasure_lot": TREASURE_LOT_NAME,
		"cargo_before": cargo_before.duplicate(),
		"cargo_after": cargo_after.duplicate(),
		"cargo_delta": cargo_after.size() - cargo_before.size(),
		"one_normal_cargo_slot_used": true,
		"fresh_press_required": true,
	}
	_begin_transition_guard("TAKE_TREASURE_DIRECT", cargo_after)
	queue_redraw()
	return true


func leave_treasure_in_place(cargo_after: Array[String]) -> bool:
	if not _treasure_choice_pending:
		return false
	_treasure_choice_pending = false
	_leave_in_place_count += 1
	_last_choice_evidence = {
		"action": "LEAVE_TREASURE_IN_PLACE",
		"success": true,
		"resolution": "LEAVE_IN_PLACE",
		"treasure_id": _pending_treasure_id,
		"treasure_lot": TREASURE_LOT_NAME,
		"cargo_before": _pending_cargo_snapshot.duplicate(),
		"cargo_after": cargo_after.duplicate(),
		"cargo_unchanged": cargo_after == _pending_cargo_snapshot,
		"treasure_still_available": _is_treasure_available(
			_pending_treasure_id
		),
	}
	_pending_treasure_id = ""
	_pending_cargo_snapshot.clear()
	return true


func collect_by_replacement(
	discarded_lot: String,
	cargo_after: Array[String],
) -> bool:
	if not _treasure_choice_pending or discarded_lot.is_empty():
		return false
	var treasure_count_before := _pending_cargo_snapshot.count(
		TREASURE_LOT_NAME
	)
	var expected_treasure_count_delta := (
		0 if discarded_lot == TREASURE_LOT_NAME else 1
	)
	var treasure_count_after := cargo_after.count(TREASURE_LOT_NAME)
	if (
		cargo_after.size() != _pending_cargo_snapshot.size()
		or treasure_count_after
			!= treasure_count_before + expected_treasure_count_delta
	):
		return false
	var treasure_id := _pending_treasure_id
	if not _collect_treasure_state(treasure_id):
		return false
	_treasure_choice_pending = false
	_treasure_collection_count += 1
	_replacement_keep_count += 1
	_displaced_cargo_discard_count += 1
	_last_choice_evidence = {
		"action": "REPLACE_CARGO_WITH_TREASURE",
		"success": true,
		"resolution": "REPLACE_CARGO_SLOT",
		"treasure_id": treasure_id,
		"discarded_lot": discarded_lot,
		"kept_lot": TREASURE_LOT_NAME,
		"cargo_before": _pending_cargo_snapshot.duplicate(),
		"cargo_after": cargo_after.duplicate(),
		"cargo_slot_count_unchanged": true,
		"same_name_treasure_replacement": (
			discarded_lot == TREASURE_LOT_NAME
		),
		"treasure_count_before": treasure_count_before,
		"treasure_count_after": treasure_count_after,
		"expected_treasure_count_delta": expected_treasure_count_delta,
		"actual_treasure_count_delta": (
			treasure_count_after - treasure_count_before
		),
		"treasure_count_delta_holds": (
			treasure_count_after - treasure_count_before
				== expected_treasure_count_delta
		),
		"treasure_kept": true,
	}
	_pending_treasure_id = ""
	_pending_cargo_snapshot.clear()
	queue_redraw()
	return true


func record_return_to_ship(cargo_lots: Array[String]) -> void:
	_return_to_ship_count += 1
	_last_transition_evidence = {
		"action": "RETURN_TO_SHIP_FROM_ISLAND",
		"success": true,
		"cargo_lots": cargo_lots.duplicate(),
		"treasure_collected": _treasure_collected,
		"gated_treasure_collected": _gated_treasure_collected,
		"treasure_cargo_count": cargo_lots.count(TREASURE_LOT_NAME),
		"tool_owned": _exploration_tool_owned,
		"tool_gate_open": _tool_gate_open,
	}


func record_sale(evidence: Dictionary) -> void:
	if bool(evidence.get("success", false)):
		_sale_count += 1
	_last_sale_evidence = evidence.duplicate(true)


func get_playtest_state() -> Dictionary:
	var physical_treasure_count := int(_treasure_available) + int(
		_gated_treasure_available
	)
	var player_viewport_rect := Rect2(
		_player_position - VIEWPORT_SIZE * 0.5,
		VIEWPORT_SIZE,
	)
	return {
		"system_count": 1,
		"owner_count": 1,
		"ruin_id": RUIN_ID,
		"ruin_count": 1,
		"entrance_count": 1,
		"entrance_position": ENTRANCE_POSITION,
		"entrance_range": ENTRANCE_RANGE,
		"entrance_visible": true,
		"entrance_visual_rect": ENTRANCE_VISUAL_RECT,
		"entrance_visual_on_screen": player_viewport_rect.intersects(
			ENTRANCE_VISUAL_RECT,
			true,
		),
		"entrance_distance": _entrance_distance,
		"entrance_in_island_walking_region": (
			ENTRANCE_POSITION.distance_to(Vector2(1550.0, 1250.0)) <= 150.0
		),
		"island_return_position": ISLAND_RETURN_POSITION,
		"inside_ruin": _inside_ruin,
		"ruin_area_count": 1,
		"ruin_walking_rect": RUIN_WALKING_RECT,
		"ruin_visual_rect": RUIN_WALKING_RECT.grow(50.0),
		"ruin_visual_on_screen": (
			_inside_ruin
			and player_viewport_rect.intersects(
				RUIN_WALKING_RECT.grow(50.0),
				true,
			)
		),
		"ruin_entry_position": RUIN_ENTRY_POSITION,
		"ruin_exit_position": RUIN_EXIT_POSITION,
		"ruin_exit_count": 1,
		"ruin_exit_visible": _inside_ruin,
		"exit_range": EXIT_RANGE,
		"exit_distance": _exit_distance,
		"treasure_position": TREASURE_POSITION,
		"treasure_range": TREASURE_RANGE,
		"treasure_distance": _treasure_distance,
		"treasure_lot_name": TREASURE_LOT_NAME,
		"treasure_type_count": 1,
		"treasure_price_state": TREASURE_PRICE_STATE,
		"treasure_available": _treasure_available,
		"treasure_visible": _inside_ruin and _treasure_available,
		"treasure_collected": _treasure_collected,
		"treasure_choice_pending": _treasure_choice_pending,
		"pending_treasure_id": _pending_treasure_id,
		"gated_treasure_position": GATED_TREASURE_POSITION,
		"gated_treasure_distance": _gated_treasure_distance,
		"gated_treasure_available": _gated_treasure_available,
		"gated_treasure_visible": (
			_inside_ruin and _tool_gate_open and _gated_treasure_available
		),
		"gated_treasure_collected": _gated_treasure_collected,
		"gated_treasure_count": 1,
		"gated_normal_treasure_count": 1,
		"normal_treasure_count": 2,
		"physical_treasure_lot_count": physical_treasure_count,
		"initial_treasure_lot_count": 2,
		"player_position": _player_position,
		"dock_shore_id": _dock_shore_id,
		"player_movement_enabled": _player_movement_enabled,
		"interaction_prompt": get_interaction_prompt(),
		"walking_distance": _walking_distance,
		"walking_furthest_progress": _walking_furthest_progress,
		"walking_path_length": PATH_LENGTH,
		"walking_path_progress_ratio": (
			_walking_furthest_progress / PATH_LENGTH
		),
		"walking_path_reached_treasure_end": (
			_walking_furthest_progress >= PATH_LENGTH - TREASURE_RANGE
		),
		"entrance_attempt_count": _entrance_attempt_count,
		"entrance_success_count": _entrance_success_count,
		"exit_attempt_count": _exit_attempt_count,
		"exit_success_count": _exit_success_count,
		"treasure_attempt_count": _treasure_attempt_count,
		"treasure_collection_count": _treasure_collection_count,
		"original_treasure_collection_count": (
			_original_treasure_collection_count
		),
		"gated_treasure_collection_count": _gated_treasure_collection_count,
		"direct_keep_count": _direct_keep_count,
		"choice_required_count": _choice_required_count,
		"leave_in_place_count": _leave_in_place_count,
		"replacement_keep_count": _replacement_keep_count,
		"displaced_cargo_discard_count": (
			_displaced_cargo_discard_count
		),
		"held_input_count": _held_input_count,
		"transition_release_pending": _transition_release_pending,
		"transition_release_count": _transition_release_count,
		"return_to_island_count": _return_to_island_count,
		"return_to_ship_count": _return_to_ship_count,
		"sale_count": _sale_count,
		"exploration_tool_count": 1,
		"exploration_tool_owner_count": 1,
		"exploration_tool_name": EXPLORATION_TOOL_NAME,
		"exploration_tool_source": EXPLORATION_TOOL_SOURCE,
		"exploration_tool_owned": _exploration_tool_owned,
		"tool_award_count": _tool_award_count,
		"last_tool_award_evidence": (
			_last_tool_award_evidence.duplicate(true)
		),
		"tool_gate_system_count": 1,
		"blocked_path_count": 1,
		"tool_gate_type_count": 1,
		"tool_gate_position": TOOL_GATE_POSITION,
		"tool_gate_range": TOOL_GATE_RANGE,
		"tool_gate_distance": _tool_gate_distance,
		"tool_gate_near": is_near_tool_gate(),
		"tool_gate_open": _tool_gate_open,
		"tool_gate_closed": not _tool_gate_open,
		"tool_gate_collision_enabled": not tool_gate_collision.disabled,
		"tool_gate_attempt_count": _tool_gate_attempt_count,
		"tool_gate_denied_count": _tool_gate_denied_count,
		"tool_gate_open_count": _tool_gate_open_count,
		"tool_gate_opens_once": _tool_gate_open_count <= 1,
		"tool_gate_open_persists": (
			not _tool_gate_open or _tool_gate_open_count == 1
		),
		"gate_open_exit_count": _gate_open_exit_count,
		"gate_open_return_entry_count": _gate_open_return_entry_count,
		"tool_gate_open_after_return": (
			_gate_open_return_entry_count == 0 or _tool_gate_open
		),
		"tool_gate_completion_flow_holds": (
			_tool_gate_denied_count >= 1
			and _exploration_tool_owned
			and _tool_award_count == 1
			and _tool_gate_open
			and _tool_gate_open_count == 1
			and _gated_treasure_collected
			and _gated_treasure_collection_count == 1
		),
		"last_tool_gate_evidence": _last_tool_gate_evidence.duplicate(true),
		"last_denied_tool_gate_evidence": (
			_last_denied_tool_gate_evidence.duplicate(true)
		),
		"successful_tool_gate_evidence": (
			_successful_tool_gate_evidence.duplicate(true)
		),
		"last_transition_evidence": _last_transition_evidence.duplicate(true),
		"last_treasure_evidence": _last_treasure_evidence.duplicate(true),
		"last_choice_evidence": _last_choice_evidence.duplicate(true),
		"last_held_input_evidence": _last_held_input_evidence.duplicate(true),
		"last_sale_evidence": _last_sale_evidence.duplicate(true),
		"fresh_press_required": true,
		"treasure_collects_once": _original_treasure_collection_count <= 1,
		"gated_treasure_collects_once": _gated_treasure_collection_count <= 1,
		"treasure_state_consistent": (
			(_treasure_available and not _treasure_collected)
			or (not _treasure_available and _treasure_collected)
		),
		"gated_treasure_state_consistent": (
			(_gated_treasure_available and not _gated_treasure_collected)
			or (
				not _gated_treasure_available
				and _gated_treasure_collected
			)
		),
		"cargo_accounting_holds": (
			_treasure_collection_count
			== _direct_keep_count + _replacement_keep_count
		),
		"movement_owner_count": 1,
		"cargo_owner_count": 1,
		"tool_upgrade_count": 0,
		"tool_durability_system_count": 0,
		"required_return_visit_count": 1,
		"skill_tree_system_count": 0,
		"puzzle_system_count": 0,
		"story_clue_system_count": 0,
		"map_fragment_count": 0,
		"clue_list_count": 0,
		"clue_description_count": 0,
		"new_story_chart_location_count": 0,
		"story_clue_persistence_count": 0,
		"curse_system_count": 0,
		"ruin_combat_system_count": 0,
		"procedural_ruin_system_count": 0,
		"treasure_variant_count": 1,
		"new_market_system_count": 0,
		"monster_hunting_system_count": 0,
		"ship_module_loadout_system_count": 0,
		"resident_reaction_system_count": 0,
		"relationship_progress_system_count": 0,
		"day_night_system_count": 0,
		"fast_travel_system_count": 0,
	}


func _get_available_treasure_id() -> String:
	if _treasure_available and _treasure_distance <= TREASURE_RANGE:
		return ORIGINAL_TREASURE_ID
	if (
		_tool_gate_open
		and _gated_treasure_available
		and _gated_treasure_distance <= TREASURE_RANGE
	):
		return GATED_TREASURE_ID
	return ""


func _is_treasure_available(treasure_id: String) -> bool:
	if treasure_id == ORIGINAL_TREASURE_ID:
		return _treasure_available
	if treasure_id == GATED_TREASURE_ID:
		return _gated_treasure_available
	return false


func _collect_treasure_state(treasure_id: String) -> bool:
	if treasure_id == ORIGINAL_TREASURE_ID and _treasure_available:
		_treasure_available = false
		_treasure_collected = true
		_original_treasure_collection_count += 1
		return true
	if (
		treasure_id == GATED_TREASURE_ID
		and _tool_gate_open
		and _gated_treasure_available
	):
		_gated_treasure_available = false
		_gated_treasure_collected = true
		_gated_treasure_collection_count += 1
		return true
	return false


func _sync_tool_gate_collision() -> void:
	tool_gate_collision.set_deferred("disabled", _tool_gate_open)


func _begin_transition_guard(action: String, cargo_lots: Array[String]) -> void:
	_transition_release_pending = true
	_last_transition_evidence = {
		"action": action,
		"success": true,
		"inside_ruin": _inside_ruin,
		"cargo_lots": cargo_lots.duplicate(),
		"release_guard_started": true,
		"release_guard_cleared": false,
		"fresh_press_required": true,
	}


func _draw() -> void:
	_draw_island_entrance()
	if _inside_ruin:
		_draw_ruin_area()


func _draw_island_entrance() -> void:
	draw_circle(ENTRANCE_POSITION + Vector2(0.0, 17.0), 46.0, Color("#15323899"))
	draw_rect(
		Rect2(ENTRANCE_POSITION + Vector2(-44.0, -34.0), Vector2(88.0, 70.0)),
		Color("#70665c"),
	)
	draw_circle(ENTRANCE_POSITION + Vector2(0.0, 8.0), 29.0, Color("#151b20"))
	draw_rect(
		Rect2(ENTRANCE_POSITION + Vector2(-29.0, 8.0), Vector2(58.0, 38.0)),
		Color("#151b20"),
	)
	draw_string(
		ThemeDB.fallback_font,
		ENTRANCE_POSITION + Vector2(-90.0, -48.0),
		"TEST ISLAND RUIN",
		HORIZONTAL_ALIGNMENT_CENTER,
		180.0,
		17,
		Color("#fff1c5"),
	)


func _draw_ruin_area() -> void:
	draw_rect(RUIN_WALKING_RECT.grow(34.0), Color("#12181d"))
	draw_rect(RUIN_WALKING_RECT, Color("#403f3a"))
	draw_rect(
		Rect2(
			Vector2(RUIN_EXIT_POSITION.x, RUIN_EXIT_POSITION.y - 46.0),
			Vector2(TREASURE_POSITION.x - RUIN_EXIT_POSITION.x, 92.0),
		),
		Color("#716952"),
	)
	for x in range(int(RUIN_EXIT_POSITION.x + 38.0), int(TREASURE_POSITION.x), 72):
		draw_rect(
			Rect2(Vector2(float(x), RUIN_EXIT_POSITION.y - 34.0), Vector2(42.0, 68.0)),
			Color("#81785e"),
			false,
			3.0,
		)
	draw_rect(
		Rect2(
			Vector2(TREASURE_POSITION.x + 36.0, TREASURE_POSITION.y - 46.0),
			Vector2(
				GATED_TREASURE_POSITION.x - TREASURE_POSITION.x - 36.0,
				92.0,
			),
		),
		Color("#655f4e"),
	)
	draw_rect(
		Rect2(RUIN_EXIT_POSITION + Vector2(-22.0, -54.0), Vector2(44.0, 108.0)),
		Color("#d7b66a"),
		false,
		6.0,
	)
	draw_string(
		ThemeDB.fallback_font,
		RUIN_EXIT_POSITION + Vector2(-54.0, -70.0),
		"EXIT",
		HORIZONTAL_ALIGNMENT_CENTER,
		108.0,
		18,
		Color("#fff1c5"),
	)
	if _treasure_available:
		draw_rect(
			Rect2(TREASURE_POSITION + Vector2(-32.0, -22.0), Vector2(64.0, 44.0)),
			Color("#a86b2d"),
		)
		draw_rect(
			Rect2(TREASURE_POSITION + Vector2(-32.0, -22.0), Vector2(64.0, 44.0)),
			Color("#f5cf68"),
			false,
			5.0,
		)
		draw_circle(TREASURE_POSITION, 7.0, Color("#fff2a8"))
	if _tool_gate_open:
		draw_rect(
			Rect2(
				TOOL_GATE_POSITION + Vector2(-12.0, -140.0),
				Vector2(24.0, 70.0),
			),
			Color("#8d7b58"),
		)
		draw_rect(
			Rect2(
				TOOL_GATE_POSITION + Vector2(-12.0, 70.0),
				Vector2(24.0, 70.0),
			),
			Color("#8d7b58"),
		)
	else:
		draw_rect(
			Rect2(
				TOOL_GATE_POSITION + Vector2(-12.0, -140.0),
				Vector2(24.0, 280.0),
			),
			Color("#8d7b58"),
		)
		for gate_y in range(-118, 119, 36):
			draw_circle(
				TOOL_GATE_POSITION + Vector2(0.0, float(gate_y)),
				7.0,
				Color("#c4aa70"),
			)
		draw_string(
			ThemeDB.fallback_font,
			TOOL_GATE_POSITION + Vector2(-108.0, -154.0),
			"RUIN PRY BAR REQUIRED",
			HORIZONTAL_ALIGNMENT_CENTER,
			216.0,
			17,
			Color("#fff1c5"),
		)
	if _tool_gate_open and _gated_treasure_available:
		draw_rect(
			Rect2(
				GATED_TREASURE_POSITION + Vector2(-32.0, -22.0),
				Vector2(64.0, 44.0),
			),
			Color("#a86b2d"),
		)
		draw_rect(
			Rect2(
				GATED_TREASURE_POSITION + Vector2(-32.0, -22.0),
				Vector2(64.0, 44.0),
			),
			Color("#f5cf68"),
			false,
			5.0,
		)
		draw_circle(GATED_TREASURE_POSITION, 7.0, Color("#fff2a8"))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(RUIN_WALKING_RECT.position.x, RUIN_WALKING_RECT.position.y - 48.0),
		"TEST ISLAND RUIN · FOLLOW THE GOLD PATH",
		HORIZONTAL_ALIGNMENT_CENTER,
		RUIN_WALKING_RECT.size.x,
		22,
		Color("#fff1c5"),
	)
