extends Node2D

const SEA_BOUNDS := Rect2(-400.0, -400.0, 3600.0, 3000.0)
const SEA_BACKGROUND := Rect2(-1100.0, -1100.0, 5000.0, 4400.0)
const TEST_ISLAND_CENTER := Vector2(1550.0, 1250.0)
const TEST_ISLAND_RADIUS := 220.0
const TEST_REEF_CENTER := Vector2(1070.0, 1050.0)
const TEST_REEF_RADIUS := 86.0
const PORT_LAND_RECT := Rect2(2320.0, 240.0, 620.0, 440.0)
const PORT_WALKING_RECT := Rect2(2420.0, 380.0, 420.0, 250.0)
var cove_shoreline := PackedVector2Array([
	Vector2(64, 158), Vector2(178, 76), Vector2(451, 48),
	Vector2(817, 64), Vector2(1048, 174), Vector2(1090, 366),
	Vector2(1018, 548), Vector2(774, 598), Vector2(302, 590),
	Vector2(100, 494), Vector2(48, 314),
])


func _ready() -> void:
	queue_redraw()


func get_playtest_state() -> Dictionary:
	return {
		"bounds": SEA_BOUNDS,
		"island_center": TEST_ISLAND_CENTER,
		"island_radius": TEST_ISLAND_RADIUS,
		"reef_count": 1,
		"reef_center": TEST_REEF_CENTER,
		"reef_radius": TEST_REEF_RADIUS,
		"reef_visible": visible,
		"reef_visual_count": 1,
		"reef_visual_bounds": Rect2(
			TEST_REEF_CENTER - Vector2.ONE * TEST_REEF_RADIUS,
			Vector2.ONE * TEST_REEF_RADIUS * 2.0,
		),
		"reef_authored_on_initial_straight_route": true,
		"port_land_rect": PORT_LAND_RECT,
		"port_walking_rect": PORT_WALKING_RECT,
		"cove_shoreline": cove_shoreline,
	}


func _draw() -> void:
	draw_rect(SEA_BACKGROUND, Color("#13788b"))
	for y in range(int(SEA_BACKGROUND.position.y + 40.0), int(SEA_BACKGROUND.end.y), 84):
		for x in range(int(SEA_BACKGROUND.position.x + 30.0), int(SEA_BACKGROUND.end.x), 168):
			draw_line(
				Vector2(x, y),
				Vector2(x + 72, y - 16),
				Color("#48a8aa70"),
				3.0,
			)

	# One authored reef is visible on the straight route out of the cove.
	draw_circle(TEST_REEF_CENTER, TEST_REEF_RADIUS + 18.0, Color("#7cd0cf55"))
	draw_arc(
		TEST_REEF_CENTER,
		TEST_REEF_RADIUS + 14.0,
		0.0,
		TAU,
		40,
		Color("#c5f0e3b0"),
		5.0,
	)
	draw_circle(TEST_REEF_CENTER + Vector2(-37.0, 12.0), 35.0, Color("#657477"))
	draw_circle(TEST_REEF_CENTER + Vector2(18.0, -22.0), 43.0, Color("#809193"))
	draw_circle(TEST_REEF_CENTER + Vector2(45.0, 31.0), 27.0, Color("#56656a"))
	draw_circle(TEST_REEF_CENTER + Vector2(1.0, 27.0), 31.0, Color("#708287"))
	draw_arc(
		TEST_REEF_CENTER,
		TEST_REEF_RADIUS,
		0.0,
		TAU,
		40,
		Color("#263f46"),
		4.0,
	)

	# One empty-sea test island gives the ship a clear land boundary.
	draw_circle(TEST_ISLAND_CENTER, TEST_ISLAND_RADIUS + 34.0, Color("#55b8b380"))
	draw_circle(TEST_ISLAND_CENTER, TEST_ISLAND_RADIUS, Color("#e2bf72"))
	draw_circle(TEST_ISLAND_CENTER + Vector2(0, 10), 176.0, Color("#65a85a"))
	draw_circle(TEST_ISLAND_CENTER + Vector2(-68, -52), 38.0, Color("#657477"))
	draw_circle(TEST_ISLAND_CENTER + Vector2(82, 61), 26.0, Color("#809193"))

	# One small south-facing dock gives the test island a safe shore point.
	draw_rect(Rect2(1522.0, 1428.0, 56.0, 132.0), Color("#6b452c"))
	for y in range(1438, 1554, 22):
		draw_line(Vector2(1528.0, y), Vector2(1572.0, y), Color("#b27a47"), 9.0)
	draw_rect(Rect2(1508.0, 1548.0, 84.0, 14.0), Color("#493323"))

	# The only test port is one compact land area with one south-facing dock.
	draw_rect(PORT_LAND_RECT.grow(26.0), Color("#55b8b380"))
	draw_rect(PORT_LAND_RECT, Color("#e2bf72"))
	draw_rect(PORT_LAND_RECT.grow(-38.0), Color("#65a85a"))
	draw_rect(Rect2(2460.0, 330.0, 300.0, 150.0), Color("#8b5a36"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(2435.0, 345.0), Vector2(2610.0, 250.0), Vector2(2785.0, 345.0),
	]), Color("#633f2a"))
	draw_rect(Rect2(2598.0, 415.0, 42.0, 65.0), Color("#342b29"))
	draw_rect(Rect2(2602.0, 620.0, 56.0, 130.0), Color("#6b452c"))
	for y in range(630, 742, 22):
		draw_line(Vector2(2608.0, y), Vector2(2652.0, y), Color("#b27a47"), 9.0)
	draw_rect(Rect2(2588.0, 738.0, 84.0, 14.0), Color("#493323"))

	# Small bright strips mark the three dock approach areas.
	draw_arc(Vector2(1070.0, 760.0), 70.0, 0.0, TAU, 32, Color("#fff1c580"), 5.0)
	draw_arc(Vector2(1550.0, 1575.0), 70.0, 0.0, TAU, 32, Color("#fff1c580"), 5.0)
	draw_arc(Vector2(2630.0, 785.0), 70.0, 0.0, TAU, 32, Color("#fff1c580"), 5.0)

	# The sea-edge line makes the movement limit visible.
	draw_rect(SEA_BOUNDS, Color("#d8eee8a0"), false, 8.0)
