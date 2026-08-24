class_name FinishedStorageShedVisual
extends Node2D


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	# The finished shed is one distinct, permanent cove building visual.
	_draw_ellipse_shape(Vector2(0.0, 27.0), 82.0, 24.0, Color("#12323c66"))
	draw_rect(Rect2(-72.0, -54.0, 144.0, 88.0), Color("#8b5a36"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-87.0, -50.0),
		Vector2(0.0, -103.0),
		Vector2(87.0, -50.0),
	]), Color("#493323"))
	for roof_x in [-58.0, -30.0, 0.0, 30.0, 58.0]:
		draw_line(
			Vector2(roof_x, -54.0),
			Vector2(roof_x * 0.18, -96.0),
			Color("#6b452c"),
			7.0,
		)
	draw_rect(Rect2(-24.0, -18.0, 48.0, 52.0), Color("#342b29"))
	draw_line(Vector2(0.0, -16.0), Vector2(0.0, 32.0), Color("#b27a47"), 4.0)
	draw_rect(Rect2(-63.0, -29.0, 25.0, 23.0), Color("#b9e4dc"))
	draw_rect(Rect2(38.0, -29.0, 25.0, 23.0), Color("#b9e4dc"))
	draw_rect(Rect2(-79.0, 40.0, 158.0, 25.0), Color("#493323"))
	var font := ThemeDB.fallback_font
	draw_string(
		font,
		Vector2(-106.0, 59.0),
		"STORAGE SHED",
		HORIZONTAL_ALIGNMENT_CENTER,
		212.0,
		18,
		Color("#fff1c5"),
	)


func _draw_ellipse_shape(
	center: Vector2,
	radius_x: float,
	radius_y: float,
	color: Color,
) -> void:
	var points := PackedVector2Array()
	for index in range(32):
		var angle := TAU * float(index) / 32.0
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(points, color)
