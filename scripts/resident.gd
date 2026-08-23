class_name CoveResident
extends Area2D

@export var display_name := "Mara"
@export var dialogue_lines := PackedStringArray([
	"The tide brought you home in one piece.",
	"Keep the cove close when the open sea calls.",
])


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_ellipse(Vector2(0, 14), 20.0, 8.0, Color("#12323c66"))
	draw_circle(Vector2.ZERO, 16.0, Color("#3c7280"))
	draw_circle(Vector2(0, -12), 10.0, Color("#b87952"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-16, -16), Vector2(-8, -25), Vector2(8, -25),
		Vector2(16, -16), Vector2(10, -11), Vector2(-10, -11),
	]), Color("#633f2a"))
	draw_line(Vector2(-9, 2), Vector2(9, 2), Color("#e2bf72"), 3.0)
