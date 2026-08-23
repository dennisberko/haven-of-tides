extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var sign: CoveSign = $InteractiveObjects/Sign
@onready var interaction_prompt: Label = $Interface/InteractionPrompt
@onready var sign_message: Label = $Interface/SignMessage

var _player_near_sign := false
var _interact_held := false
var _read_count := 0


func _ready() -> void:
	interaction_prompt.hide()
	sign_message.hide()
	sign.body_entered.connect(_on_sign_body_entered)
	sign.body_exited.connect(_on_sign_body_exited)


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
	if not _player_near_sign:
		return

	_read_count += 1
	sign_message.text = sign.interaction_message
	sign_message.show()
	get_viewport().set_input_as_handled()


func _on_sign_body_entered(body: Node2D) -> void:
	if body != player:
		return

	_player_near_sign = true
	interaction_prompt.show()


func _on_sign_body_exited(body: Node2D) -> void:
	if body != player:
		return

	_player_near_sign = false
	interaction_prompt.hide()
	sign_message.hide()


func get_playtest_state() -> Dictionary:
	return {
		"player_position": player.position,
		"sign_position": sign.position,
		"player_near_sign": _player_near_sign,
		"prompt_visible": interaction_prompt.visible,
		"message_visible": sign_message.visible,
		"message_text": sign_message.text,
		"read_count": _read_count,
	}
