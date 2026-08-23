class_name CoveSign
extends Area2D

@export_multiline var interaction_message := "The cove keeps a light for every safe return."


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_ellipse(Vector2(0, 14), 32.0, 7.0, Color("#12323c55"))
	draw_line(Vector2(0, 18), Vector2(0, -25), Color("#493323"), 9.0)
	draw_rect(Rect2(-34, -43, 68, 29), Color("#6b452c"))
	draw_line(Vector2(-29, -36), Vector2(29, -36), Color("#b27a47"), 4.0)
	draw_line(Vector2(-29, -21), Vector2(29, -21), Color("#493323"), 3.0)
