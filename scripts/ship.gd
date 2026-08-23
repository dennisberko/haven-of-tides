extends Node2D


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	# The one ship at the damaged dock, viewed from above.
	draw_ellipse(Vector2(5, 8), 48.0, 99.0, Color("#12323c66"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-31, -86), Vector2(31, -86), Vector2(47, 35),
		Vector2(0, 94), Vector2(-47, 35),
	]), Color("#493323"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-23, -72), Vector2(23, -72), Vector2(34, 31),
		Vector2(0, 77), Vector2(-34, 31),
	]), Color("#b27a47"))

	# Deck details make the standing position clear without adding controls.
	draw_line(Vector2(-25, -38), Vector2(25, -38), Color("#6b452c"), 5.0)
	draw_line(Vector2(-30, 18), Vector2(30, 18), Color("#6b452c"), 5.0)
	draw_circle(Vector2(0, -12), 8.0, Color("#342b29"))
	draw_line(Vector2(0, -12), Vector2(18, -47), Color("#e8d2a2"), 4.0)

	# The gangplank connects the fixed ship to the damaged dock entry point.
	draw_line(Vector2(-176, -24), Vector2(-39, -24), Color("#493323"), 18.0)
	draw_line(Vector2(-176, -24), Vector2(-39, -24), Color("#b27a47"), 11.0)
