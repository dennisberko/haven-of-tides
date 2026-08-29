class_name TradeContact
extends Area2D

enum ContactKind {
	PORT_TRADER,
	COVE_BUYER,
}

const GOOD_NAME := "SPICE LOT"
const BUY_PRICE := 20
const SELL_PRICE := 30
const PORT_SHORE_ID := "port"
const COVE_SHORE_ID := "cove"

@export_enum("PORT TRADER", "COVE BUYER") var contact_kind: int = (
	ContactKind.PORT_TRADER
)


func is_port_trader() -> bool:
	return contact_kind == ContactKind.PORT_TRADER


func is_cove_buyer() -> bool:
	return contact_kind == ContactKind.COVE_BUYER


func get_display_name() -> String:
	return "PORT TRADER" if is_port_trader() else "COVE BUYER"


func get_shore_id() -> String:
	return PORT_SHORE_ID if is_port_trader() else COVE_SHORE_ID


func get_playtest_state() -> Dictionary:
	var interaction_range := 0.0
	var interaction_region_count := 0
	for child in get_children():
		if child is CollisionShape2D:
			interaction_region_count += 1
			var collision_shape := child as CollisionShape2D
			if collision_shape.shape is CircleShape2D:
				interaction_range = (
					collision_shape.shape as CircleShape2D
				).radius
	return {
		"contact_kind": ContactKind.keys()[contact_kind],
		"display_name": get_display_name(),
		"shore_id": get_shore_id(),
		"position": global_position,
		"visible": visible,
		"interaction_region_count": interaction_region_count,
		"interaction_range": interaction_range,
		"good_name": GOOD_NAME,
		"buy_price": BUY_PRICE,
		"sell_price": SELL_PRICE,
	}


func _draw() -> void:
	var coat_color := Color("#355f7a")
	var sign_text := "BUY"
	if is_cove_buyer():
		coat_color = Color("#7a4f68")
		sign_text = "SELL"

	# The table and one person make this contact clear in the small test world.
	_draw_ellipse_shape(Vector2(2.0, 25.0), 38.0, 12.0, Color("#12323c66"))
	draw_rect(Rect2(Vector2(-40.0, 8.0), Vector2(80.0, 24.0)), Color("#8a5d3b"))
	draw_rect(
		Rect2(Vector2(-40.0, 8.0), Vector2(80.0, 24.0)),
		Color("#493323"),
		false,
		3.0,
	)
	draw_rect(Rect2(Vector2(-15.0, -14.0), Vector2(30.0, 28.0)), coat_color)
	draw_circle(Vector2(0.0, -25.0), 11.0, Color("#e9b982"))
	draw_rect(Rect2(Vector2(-29.0, 12.0), Vector2(22.0, 14.0)), Color("#d79b56"))
	draw_rect(Rect2(Vector2(7.0, 12.0), Vector2(22.0, 14.0)), Color("#d79b56"))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-42.0, -48.0),
		sign_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		84.0,
		16,
		Color("#fff1c5"),
	)


func _draw_ellipse_shape(
	center: Vector2,
	radius_x: float,
	radius_y: float,
	color: Color,
) -> void:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(
			center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y)
		)
	draw_colored_polygon(points, color)
