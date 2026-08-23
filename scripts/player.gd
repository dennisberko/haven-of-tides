class_name CovePlayer
extends CharacterBody2D

const SPEED := 210.0

enum ControlMode {
	WALKING,
	ABOARD_SHIP,
}

var facing := Vector2.DOWN
var movement_enabled := true
var control_mode := ControlMode.WALKING


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if control_mode != ControlMode.WALKING or not movement_enabled:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction := _read_direction()
	velocity = direction * SPEED

	if not direction.is_zero_approx():
		facing = direction
		queue_redraw()

	move_and_slide()


func enter_ship(standing_position: Vector2) -> void:
	global_position = standing_position
	control_mode = ControlMode.ABOARD_SHIP
	movement_enabled = false
	velocity = Vector2.ZERO


func leave_ship(cove_position: Vector2) -> void:
	global_position = cove_position
	control_mode = ControlMode.WALKING
	movement_enabled = true
	velocity = Vector2.ZERO


func _read_direction() -> Vector2:
	var horizontal := float(
		Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
	) - float(
		Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
	)
	var vertical := float(
		Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	) - float(
		Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	)
	return Vector2(horizontal, vertical).normalized()


func get_playtest_state() -> Dictionary:
	return {
		"position": position,
		"velocity": velocity,
		"facing": facing,
		"movement_enabled": movement_enabled,
		"control_mode": ControlMode.keys()[control_mode],
	}


func _draw() -> void:
	draw_ellipse(Vector2(0, 13), 19.0, 8.0, Color("#12323c66"))
	draw_circle(Vector2.ZERO, 16.0, Color("#d05a43"))
	draw_circle(Vector2(0, -11), 10.0, Color("#f0bd84"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-19, -14), Vector2(0, -27), Vector2(19, -14),
		Vector2(11, -9), Vector2(-11, -9)
	]), Color("#24313b"))
	draw_line(Vector2.ZERO, facing * 12.0, Color("#fff1c5"), 3.0)
