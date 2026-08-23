extends CharacterBody2D

const SPEED := 210.0

var facing := Vector2.DOWN


func _ready() -> void:
	queue_redraw()


func _physics_process(_delta: float) -> void:
	var direction := _read_direction()
	velocity = direction * SPEED

	if not direction.is_zero_approx():
		facing = direction
		queue_redraw()

	move_and_slide()


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
