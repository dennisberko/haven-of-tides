extends Node2D

enum RequestState {
	AVAILABLE,
	ACTIVE,
	GOAL_COMPLETE,
	COMPLETE,
}

const REQUEST_TITLE := "DAMAGED DOCK"
const REQUEST_ACTIVE_GOAL := "Inspect the damaged dock"
const REQUEST_RETURN_GOAL := "Return to Mara"

@onready var player = $Player
@onready var sign: CoveSign = $InteractiveObjects/Sign
@onready var resident = $InteractiveObjects/Resident
@onready var sea_area = $SeaArea
@onready var ship = $Ship
@onready var ship_entry: Area2D = $ShipAccess/EntryPoint
@onready var ship_standing_position: Marker2D = $Ship/StandingPosition
@onready var damaged_dock_return_position: Marker2D = $ShipAccess/DamagedDockReturnPosition
@onready var damaged_dock_goal: Area2D = $RequestAreas/DamagedDockGoal
@onready var travel_camera: Camera2D = $TravelCamera
@onready var interaction_prompt: Label = $Interface/InteractionPrompt
@onready var sign_message: Label = $Interface/SignMessage
@onready var dialogue_box: ColorRect = $Interface/DialogueBox
@onready var speaker_name: Label = $Interface/DialogueBox/SpeakerName
@onready var dialogue_text: Label = $Interface/DialogueBox/DialogueText
@onready var request_view: ColorRect = $Interface/RequestView
@onready var request_title: Label = $Interface/RequestView/RequestTitle
@onready var request_status: Label = $Interface/RequestView/RequestStatus
@onready var request_goal: Label = $Interface/RequestView/RequestGoal
@onready var controls_help: Label = $Interface/Controls

const COVE_CAMERA_POSITION := Vector2(576.0, 324.0)
const WALKING_CONTROLS_TEXT := "WASD / ARROWS TO MOVE · E INTERACT"
const SAILING_CONTROLS_TEXT := "W / UP SAIL · A / D TURN · S / DOWN BRAKE"

var _player_near_sign := false
var _player_near_resident := false
var _player_near_ship_entry := false
var _player_aboard_ship := false
var _interact_held := false
var _read_count := 0
var _dialogue_open := false
var _dialogue_line_index := -1
var _dialogue_lines := PackedStringArray()
var _request_state := RequestState.AVAILABLE
var _last_leave_allowed := false


func _ready() -> void:
	var sea_state: Dictionary = sea_area.get_playtest_state()
	ship.configure_sailing_area(
		sea_state["bounds"],
		sea_state["island_center"],
		sea_state["island_radius"],
		sea_state["cove_shoreline"],
	)
	travel_camera.global_position = COVE_CAMERA_POSITION
	interaction_prompt.hide()
	sign_message.hide()
	dialogue_box.hide()
	request_view.hide()
	sign.body_entered.connect(_on_sign_body_entered)
	sign.body_exited.connect(_on_sign_body_exited)
	resident.body_entered.connect(_on_resident_body_entered)
	resident.body_exited.connect(_on_resident_body_exited)
	ship_entry.body_entered.connect(_on_ship_entry_body_entered)
	ship_entry.body_exited.connect(_on_ship_entry_body_exited)
	damaged_dock_goal.body_entered.connect(_on_damaged_dock_goal_body_entered)


func _physics_process(_delta: float) -> void:
	if _player_aboard_ship:
		player.global_position = ship_standing_position.global_position
		travel_camera.global_position = ship.global_position
		var leave_allowed: bool = ship.can_leave_at_damaged_dock()
		if leave_allowed != _last_leave_allowed:
			_last_leave_allowed = leave_allowed
			_update_interaction_prompt()
	else:
		travel_camera.global_position = COVE_CAMERA_POSITION


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if key_event.physical_keycode != KEY_E and key_event.keycode != KEY_E:
		return
	if not key_event.pressed:
		_interact_held = false
		return
	if key_event.echo or _interact_held:
		return

	_interact_held = true
	if _dialogue_open:
		_advance_dialogue()
		get_viewport().set_input_as_handled()
		return

	if _player_aboard_ship:
		if ship.can_leave_at_damaged_dock():
			_leave_ship_at_damaged_dock()
		get_viewport().set_input_as_handled()
		return

	if _player_near_resident:
		_start_dialogue()
		get_viewport().set_input_as_handled()
		return

	if _player_near_ship_entry:
		_enter_ship()
		get_viewport().set_input_as_handled()
		return

	if _player_near_sign:
		_read_sign()
		get_viewport().set_input_as_handled()


func _on_sign_body_entered(body: Node2D) -> void:
	if body != player:
		return

	_player_near_sign = true
	_update_interaction_prompt()


func _on_sign_body_exited(body: Node2D) -> void:
	if body != player:
		return

	_player_near_sign = false
	sign_message.hide()
	_update_interaction_prompt()


func _on_resident_body_entered(body: Node2D) -> void:
	if body != player:
		return

	_player_near_resident = true
	_update_interaction_prompt()


func _on_resident_body_exited(body: Node2D) -> void:
	if body != player:
		return

	_player_near_resident = false
	_update_interaction_prompt()


func _on_ship_entry_body_entered(body: Node2D) -> void:
	if body != player or _player_aboard_ship:
		return

	_player_near_ship_entry = true
	_update_interaction_prompt()


func _on_ship_entry_body_exited(body: Node2D) -> void:
	if body != player:
		return

	_player_near_ship_entry = false
	_update_interaction_prompt()


func _on_damaged_dock_goal_body_entered(body: Node2D) -> void:
	if body != player or _request_state != RequestState.ACTIVE:
		return

	_request_state = RequestState.GOAL_COMPLETE
	_update_request_view()


func _read_sign() -> void:
	_read_count += 1
	sign_message.text = sign.interaction_message
	sign_message.show()


func _enter_ship() -> void:
	if _player_aboard_ship or not _player_near_ship_entry:
		return

	_player_aboard_ship = true
	ship.set_controls_enabled(true)
	player.enter_ship(ship_standing_position.global_position)
	_last_leave_allowed = ship.can_leave_at_damaged_dock()
	controls_help.text = SAILING_CONTROLS_TEXT
	sign_message.hide()
	_update_interaction_prompt()


func _leave_ship_at_damaged_dock() -> void:
	if not _player_aboard_ship or not ship.can_leave_at_damaged_dock():
		return

	_player_aboard_ship = false
	ship.set_controls_enabled(false)
	_player_near_ship_entry = true
	player.leave_ship(damaged_dock_return_position.global_position)
	_last_leave_allowed = false
	controls_help.text = WALKING_CONTROLS_TEXT
	_update_interaction_prompt()


func _start_dialogue() -> void:
	_dialogue_lines = _get_resident_dialogue()
	if _dialogue_lines.is_empty():
		return

	if _request_state == RequestState.AVAILABLE:
		_request_state = RequestState.ACTIVE
		_update_request_view()

	_dialogue_open = true
	_dialogue_line_index = 0
	player.movement_enabled = false
	sign_message.hide()
	interaction_prompt.hide()
	speaker_name.text = resident.display_name
	dialogue_text.text = _dialogue_lines[_dialogue_line_index]
	dialogue_box.show()


func _advance_dialogue() -> void:
	_dialogue_line_index += 1
	if _dialogue_line_index >= _dialogue_lines.size():
		_close_dialogue()
		return

	dialogue_text.text = _dialogue_lines[_dialogue_line_index]


func _close_dialogue() -> void:
	var finished_request := _request_state == RequestState.GOAL_COMPLETE
	_dialogue_open = false
	_dialogue_line_index = -1
	_dialogue_lines = PackedStringArray()
	player.movement_enabled = true
	dialogue_box.hide()
	if finished_request:
		_request_state = RequestState.COMPLETE
		_update_request_view()
	_update_interaction_prompt()


func _get_resident_dialogue() -> PackedStringArray:
	match _request_state:
		RequestState.AVAILABLE:
			return resident.request_offer_dialogue
		RequestState.ACTIVE:
			return resident.request_active_dialogue
		RequestState.GOAL_COMPLETE:
			return resident.request_report_dialogue
		RequestState.COMPLETE:
			return resident.request_complete_dialogue

	return PackedStringArray()


func _update_request_view() -> void:
	if _request_state == RequestState.AVAILABLE:
		request_view.hide()
		return

	request_title.text = REQUEST_TITLE
	request_view.show()
	match _request_state:
		RequestState.ACTIVE:
			request_status.text = "ACTIVE REQUEST"
			request_goal.text = REQUEST_ACTIVE_GOAL
		RequestState.GOAL_COMPLETE:
			request_status.text = "GOAL COMPLETE"
			request_goal.text = REQUEST_RETURN_GOAL
		RequestState.COMPLETE:
			request_status.text = "REQUEST COMPLETE"
			request_goal.text = "Dock inspected for Mara"


func _update_interaction_prompt() -> void:
	if _dialogue_open:
		interaction_prompt.hide()
		return

	if _player_aboard_ship:
		if ship.can_leave_at_damaged_dock():
			interaction_prompt.text = "[E] LEAVE SHIP AT DOCK"
			interaction_prompt.show()
		else:
			interaction_prompt.hide()
		return

	if _player_near_resident:
		interaction_prompt.text = "[E] TALK TO %s" % resident.display_name.to_upper()
		interaction_prompt.show()
		return

	if _player_near_ship_entry:
		interaction_prompt.text = "[E] ENTER SHIP"
		interaction_prompt.show()
		return

	if _player_near_sign:
		interaction_prompt.text = "[E] READ SIGN"
		interaction_prompt.show()
		return

	interaction_prompt.hide()


func get_playtest_state() -> Dictionary:
	var ship_state: Dictionary = ship.get_playtest_state()
	return {
		"player_position": player.position,
		"sign_position": sign.position,
		"resident_position": resident.position,
		"ship_position": ship.global_position,
		"ship_rotation_radians": ship_state["rotation_radians"],
		"ship_rotation_degrees": ship_state["rotation_degrees"],
		"ship_heading": ship_state["heading"],
		"ship_speed": ship_state["current_speed"],
		"ship_velocity": ship_state["velocity"],
		"ship_acceleration": ship_state["acceleration"],
		"ship_coast_deceleration": ship_state["coast_deceleration"],
		"ship_brake_deceleration": ship_state["brake_deceleration"],
		"ship_top_speed": ship_state["top_speed"],
		"ship_turn_speed": ship_state["turn_speed"],
		"ship_controls": ship_state["controls"],
		"ship_controls_enabled": ship_state["controls_enabled"],
		"ship_has_departed_dock": ship_state["has_departed_dock"],
		"ship_at_damaged_dock": ship_state["at_damaged_dock"],
		"ship_leave_allowed": ship_state["leave_allowed"],
		"ship_at_cove_entrance": ship_state["at_cove_entrance"],
		"damaged_dock_position": ship_state["damaged_dock_position"],
		"cove_entrance_position": ship_state["cove_entrance_position"],
		"cove_entrance_radius": ship_state["cove_entrance_radius"],
		"sea_bounds": ship_state["sea_bounds"],
		"test_island_center": ship_state["island_center"],
		"test_island_radius": ship_state["island_radius"],
		"ship_collision_radius": ship_state["collision_radius"],
		"ship_collision_response": ship_state["last_collision_response"],
		"ship_steering_locked": ship_state["steering_locked"],
		"ship_dock_exit_cleared": ship_state["dock_exit_cleared"],
		"ship_dock_exit_progress": ship_state["dock_exit_progress"],
		"ship_dock_exit_clear_y": ship_state["dock_exit_clear_y"],
		"ship_hull_clearance": ship_state["hull_clearance"],
		"cove_shoreline": ship_state["cove_shoreline"],
		"camera_position": travel_camera.global_position,
		"camera_target": "SHIP" if _player_aboard_ship else "COVE",
		"ship_entry_position": ship_entry.global_position,
		"ship_standing_position": ship_standing_position.global_position,
		"damaged_dock_return_position": damaged_dock_return_position.global_position,
		"player_near_sign": _player_near_sign,
		"player_near_resident": _player_near_resident,
		"player_near_ship_entry": _player_near_ship_entry,
		"player_aboard_ship": _player_aboard_ship,
		"player_control_mode": player.get_playtest_state()["control_mode"],
		"prompt_visible": interaction_prompt.visible,
		"prompt_text": interaction_prompt.text,
		"message_visible": sign_message.visible,
		"message_text": sign_message.text,
		"read_count": _read_count,
		"dialogue_open": _dialogue_open,
		"dialogue_line_index": _dialogue_line_index,
		"speaker_name": speaker_name.text,
		"dialogue_text": dialogue_text.text,
		"request_state": RequestState.keys()[_request_state],
		"request_view_visible": request_view.visible,
		"request_title": request_title.text,
		"request_status": request_status.text,
		"request_goal": request_goal.text,
	}
