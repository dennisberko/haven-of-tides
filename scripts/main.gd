extends Node2D

@onready var player = $Player
@onready var sign: CoveSign = $InteractiveObjects/Sign
@onready var resident = $InteractiveObjects/Resident
@onready var interaction_prompt: Label = $Interface/InteractionPrompt
@onready var sign_message: Label = $Interface/SignMessage
@onready var dialogue_box: ColorRect = $Interface/DialogueBox
@onready var speaker_name: Label = $Interface/DialogueBox/SpeakerName
@onready var dialogue_text: Label = $Interface/DialogueBox/DialogueText

var _player_near_sign := false
var _player_near_resident := false
var _interact_held := false
var _read_count := 0
var _dialogue_open := false
var _dialogue_line_index := -1


func _ready() -> void:
	interaction_prompt.hide()
	sign_message.hide()
	dialogue_box.hide()
	sign.body_entered.connect(_on_sign_body_entered)
	sign.body_exited.connect(_on_sign_body_exited)
	resident.body_entered.connect(_on_resident_body_entered)
	resident.body_exited.connect(_on_resident_body_exited)


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

	if _player_near_resident:
		_start_dialogue()
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


func _read_sign() -> void:
	_read_count += 1
	sign_message.text = sign.interaction_message
	sign_message.show()


func _start_dialogue() -> void:
	if resident.dialogue_lines.is_empty():
		return

	_dialogue_open = true
	_dialogue_line_index = 0
	player.movement_enabled = false
	sign_message.hide()
	interaction_prompt.hide()
	speaker_name.text = resident.display_name
	dialogue_text.text = resident.dialogue_lines[_dialogue_line_index]
	dialogue_box.show()


func _advance_dialogue() -> void:
	_dialogue_line_index += 1
	if _dialogue_line_index >= resident.dialogue_lines.size():
		_close_dialogue()
		return

	dialogue_text.text = resident.dialogue_lines[_dialogue_line_index]


func _close_dialogue() -> void:
	_dialogue_open = false
	_dialogue_line_index = -1
	player.movement_enabled = true
	dialogue_box.hide()
	_update_interaction_prompt()


func _update_interaction_prompt() -> void:
	if _dialogue_open:
		interaction_prompt.hide()
		return

	if _player_near_resident:
		interaction_prompt.text = "[E] TALK TO %s" % resident.display_name.to_upper()
		interaction_prompt.show()
		return

	if _player_near_sign:
		interaction_prompt.text = "[E] READ SIGN"
		interaction_prompt.show()
		return

	interaction_prompt.hide()


func get_playtest_state() -> Dictionary:
	return {
		"player_position": player.position,
		"sign_position": sign.position,
		"resident_position": resident.position,
		"player_near_sign": _player_near_sign,
		"player_near_resident": _player_near_resident,
		"prompt_visible": interaction_prompt.visible,
		"prompt_text": interaction_prompt.text,
		"message_visible": sign_message.visible,
		"message_text": sign_message.text,
		"read_count": _read_count,
		"dialogue_open": _dialogue_open,
		"dialogue_line_index": _dialogue_line_index,
		"speaker_name": speaker_name.text,
		"dialogue_text": dialogue_text.text,
	}
