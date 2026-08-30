class_name TargetBoardingDeck
extends Node2D

const DECK_SIZE := Vector2(360.0, 180.0)
const WALK_MARGIN := Vector2(28.0, 28.0)
const ENTRY_LOCAL_POSITION := Vector2(122.0, 0.0)
const RETURN_LOCAL_POSITION := Vector2(-122.0, 0.0)
const RETURN_RANGE := 44.0
const WALK_ACROSS_DISTANCE := 180.0

var active := false
var active_target_id := ""
var active_target_name := ""
var active_hull := 0
var active_sails := 0


func _ready() -> void:
	hide()
	queue_redraw()


func activate(
	target_id: String,
	target_name: String,
	hull_condition: int,
	sail_condition: int,
) -> void:
	active = true
	active_target_id = target_id
	active_target_name = target_name
	active_hull = hull_condition
	active_sails = sail_condition
	show()
	queue_redraw()


func deactivate() -> void:
	active = false
	active_target_id = ""
	active_target_name = ""
	active_hull = 0
	active_sails = 0
	hide()
	queue_redraw()


func get_entry_position() -> Vector2:
	return to_global(ENTRY_LOCAL_POSITION)


func get_return_position() -> Vector2:
	return to_global(RETURN_LOCAL_POSITION)


func get_walk_region() -> Dictionary:
	return {
		"kind": "RECTANGLE",
		"rect": get_walk_rect(),
	}


func get_walk_rect() -> Rect2:
	var local_rect := Rect2(-DECK_SIZE * 0.5 + WALK_MARGIN, DECK_SIZE - WALK_MARGIN * 2.0)
	return Rect2(to_global(local_rect.position), local_rect.size)


func is_player_near_return(player_position: Vector2) -> bool:
	return active and player_position.distance_to(get_return_position()) <= RETURN_RANGE


func is_player_inside_bounds(player_position: Vector2) -> bool:
	return get_walk_rect().grow(0.1).has_point(player_position)


func get_playtest_state(player_position: Vector2) -> Dictionary:
	var walk_rect := get_walk_rect()
	return {
		"system_count": 1,
		"active": active,
		"visible": visible,
		"target_id": active_target_id,
		"target_name": active_target_name,
		"target_hull": active_hull,
		"target_sails": active_sails,
		"deck_size": DECK_SIZE,
		"compact": DECK_SIZE.x <= 400.0 and DECK_SIZE.y <= 200.0,
		"empty": true,
		"walk_rect": walk_rect,
		"entry_position": get_entry_position(),
		"return_position": get_return_position(),
		"return_range": RETURN_RANGE,
		"return_point_count": 1,
		"return_point_visible": active and visible,
		"player_near_return": is_player_near_return(player_position),
		"player_inside_bounds": is_player_inside_bounds(player_position),
		"walk_across_distance": WALK_ACROSS_DISTANCE,
		"defender_count": 0,
		"on_foot_combat_system_count": 0,
	}


func _draw() -> void:
	if not active:
		return
	var deck_rect := Rect2(-DECK_SIZE * 0.5, DECK_SIZE)
	draw_rect(deck_rect.grow(54.0), Color("#123d4c"), true)
	draw_rect(deck_rect.grow(24.0), Color("#247386"), true)
	draw_rect(deck_rect, Color("#7c5638"), true)
	for plank_x in range(-160, 181, 40):
		draw_line(
			Vector2(float(plank_x), -90.0),
			Vector2(float(plank_x), 90.0),
			Color("#4c3427"),
			3.0,
		)
	draw_rect(deck_rect, Color("#e1bd7a"), false, 7.0)
	draw_line(Vector2(-178.0, -58.0), Vector2(178.0, -58.0), Color("#d8d0b5"), 5.0)
	draw_line(Vector2(-178.0, 58.0), Vector2(178.0, 58.0), Color("#d8d0b5"), 5.0)
	draw_circle(RETURN_LOCAL_POSITION, RETURN_RANGE, Color("#f2c14f33"))
	draw_arc(RETURN_LOCAL_POSITION, RETURN_RANGE, 0.0, TAU, 40, Color("#f2c14f"), 5.0)
	draw_circle(RETURN_LOCAL_POSITION, 9.0, Color("#fff1c5"))
	var font: Font = ThemeDB.fallback_font
	draw_string(
		font,
		Vector2(-210.0, -138.0),
		"TARGET DECK · %s" % active_target_name,
		HORIZONTAL_ALIGNMENT_CENTER,
		420.0,
		23,
		Color("#fff1c5"),
	)
	draw_string(
		font,
		Vector2(-210.0, -108.0),
		"EMPTY BOARDING DECK · HULL %d · SAILS %d" % [
			active_hull,
			active_sails,
		],
		HORIZONTAL_ALIGNMENT_CENTER,
		420.0,
		16,
		Color("#d9f6ee"),
	)
	draw_string(
		font,
		Vector2(-194.0, 128.0),
		"RETURN POINT",
		HORIZONTAL_ALIGNMENT_LEFT,
		150.0,
		16,
		Color("#fff1c5"),
	)
