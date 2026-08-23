extends Node2D


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	# Ocean and shallow water.
	draw_rect(Rect2(0, 0, 1152, 648), Color("#13788b"))
	for y in range(105, 620, 42):
		draw_line(Vector2(0, y), Vector2(1152, y - 18), Color("#48a8aa80"), 3.0)

	# The first cove play area.
	var shore := PackedVector2Array([
		Vector2(64, 158), Vector2(178, 76), Vector2(451, 48),
		Vector2(817, 64), Vector2(1048, 174), Vector2(1090, 366),
		Vector2(1018, 548), Vector2(774, 598), Vector2(302, 590),
		Vector2(100, 494), Vector2(48, 314)
	])
	draw_colored_polygon(shore, Color("#e2bf72"))

	var grass := PackedVector2Array([
		Vector2(108, 176), Vector2(224, 106), Vector2(473, 82),
		Vector2(800, 96), Vector2(1006, 190), Vector2(1043, 361),
		Vector2(972, 508), Vector2(748, 553), Vector2(320, 548),
		Vector2(146, 466), Vector2(96, 309)
	])
	draw_colored_polygon(grass, Color("#65a85a"))

	# Paths.
	draw_polyline(PackedVector2Array([
		Vector2(512, 332), Vector2(650, 348), Vector2(826, 386), Vector2(982, 420)
	]), Color("#d6aa65"), 42.0)
	draw_polyline(PackedVector2Array([
		Vector2(510, 335), Vector2(416, 418), Vector2(285, 477)
	]), Color("#d6aa65"), 34.0)

	# Dock.
	draw_rect(Rect2(914, 384, 190, 82), Color("#6b452c"))
	for x in range(924, 1100, 24):
		draw_line(Vector2(x, 389), Vector2(x, 460), Color("#b27a47"), 16.0)
	draw_line(Vector2(914, 382), Vector2(1104, 382), Color("#493323"), 6.0)
	draw_line(Vector2(914, 466), Vector2(1104, 466), Color("#493323"), 6.0)
	# Split boards mark the damaged goal area.
	draw_line(Vector2(955, 402), Vector2(965, 421), Color("#493323"), 5.0)
	draw_line(Vector2(965, 421), Vector2(954, 443), Color("#493323"), 5.0)
	draw_line(Vector2(1024, 392), Vector2(1014, 414), Color("#493323"), 5.0)
	draw_line(Vector2(1014, 414), Vector2(1028, 438), Color("#493323"), 5.0)

	# Shelter and roof.
	draw_rect(Rect2(675, 242, 170, 116), Color("#8b5a36"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(656, 258), Vector2(760, 185), Vector2(864, 258)
	]), Color("#633f2a"))
	draw_rect(Rect2(742, 302, 38, 56), Color("#342b29"))
	draw_rect(Rect2(690, 276, 28, 25), Color("#b9e4dc"))

	# Rock.
	draw_circle(Vector2(284, 174), 40.0, Color("#657477"))
	draw_circle(Vector2(271, 163), 20.0, Color("#809193"))

	# Cove fire.
	for angle in [0.0, PI / 2.0, PI, PI * 1.5]:
		var offset := Vector2(cos(angle), sin(angle)) * 18.0
		draw_line(Vector2(450, 321) - offset, Vector2(450, 321) + offset, Color("#533927"), 7.0)
	draw_circle(Vector2(450, 316), 16.0, Color("#ef6b35"))
	draw_circle(Vector2(450, 311), 9.0, Color("#ffd067"))

	# Palms.
	_draw_palm(Vector2(185, 220), -0.18)
	_draw_palm(Vector2(898, 173), 0.15)
	_draw_palm(Vector2(230, 500), 0.1)


func _draw_palm(base: Vector2, lean: float) -> void:
	var top := base + Vector2(lean * 80.0, -72.0)
	draw_line(base, top, Color("#76502e"), 11.0)
	for angle in [-2.8, -2.25, -1.65, -1.0, -0.35, 0.2]:
		var tip := top + Vector2(cos(angle), sin(angle)) * 49.0
		draw_line(top, tip, Color("#276b45"), 12.0)
	draw_circle(top, 10.0, Color("#493923"))
