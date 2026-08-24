extends Node2D


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	# One cleared foundation and its timber frame mark the only construction site.
	_draw_ellipse_shape(Vector2(0.0, 24.0), 74.0, 22.0, Color("#12323c66"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-67.0, -35.0),
		Vector2(58.0, -35.0),
		Vector2(76.0, 30.0),
		Vector2(-76.0, 30.0),
	]), Color("#b88b55"))
	for post_x in [-58.0, 58.0]:
		draw_line(Vector2(post_x, 24.0), Vector2(post_x, -67.0), Color("#6b452c"), 9.0)
	draw_line(Vector2(-62.0, -63.0), Vector2(62.0, -63.0), Color("#b27a47"), 10.0)
	draw_line(Vector2(-60.0, -61.0), Vector2(60.0, 20.0), Color("#6b452c"), 7.0)
	draw_line(Vector2(60.0, -61.0), Vector2(-60.0, 20.0), Color("#6b452c"), 7.0)
	draw_rect(Rect2(-64.0, 39.0, 128.0, 25.0), Color("#493323"))
	var font := ThemeDB.fallback_font
	draw_string(
		font,
		Vector2(-106.0, 58.0),
		"STORAGE SHED SITE",
		HORIZONTAL_ALIGNMENT_CENTER,
		212.0,
		17,
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
