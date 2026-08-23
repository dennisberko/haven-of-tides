extends Node2D

const SEA_BOUNDS := Rect2(-400.0, -400.0, 3600.0, 3000.0)
const SEA_BACKGROUND := Rect2(-1100.0, -1100.0, 5000.0, 4400.0)
const TEST_ISLAND_CENTER := Vector2(1550.0, 1250.0)
const TEST_ISLAND_RADIUS := 220.0
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

	# One empty-sea test island gives the ship a clear land boundary.
	draw_circle(TEST_ISLAND_CENTER, TEST_ISLAND_RADIUS + 34.0, Color("#55b8b380"))
	draw_circle(TEST_ISLAND_CENTER, TEST_ISLAND_RADIUS, Color("#e2bf72"))
	draw_circle(TEST_ISLAND_CENTER + Vector2(0, 10), 176.0, Color("#65a85a"))
	draw_circle(TEST_ISLAND_CENTER + Vector2(-68, -52), 38.0, Color("#657477"))
	draw_circle(TEST_ISLAND_CENTER + Vector2(82, 61), 26.0, Color("#809193"))

	# The sea-edge line makes the movement limit visible.
	draw_rect(SEA_BOUNDS, Color("#d8eee8a0"), false, 8.0)
