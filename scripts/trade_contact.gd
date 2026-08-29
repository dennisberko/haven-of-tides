class_name TradeContact
extends Area2D

enum ContactKind {
	PORT_TRADER,
	COVE_BUYER,
}

enum PriceState {
	CHEAP,
	NORMAL,
	VALUABLE,
}

enum MarkKind {
	STOCK,
	DEMAND,
}

const GOOD_NAME := "SPICE LOT"
const CHEAP_PRICE := 20
const NORMAL_PRICE := 25
const VALUABLE_PRICE := 30
const FIXED_PRICES := {
	PriceState.CHEAP: CHEAP_PRICE,
	PriceState.NORMAL: NORMAL_PRICE,
	PriceState.VALUABLE: VALUABLE_PRICE,
}
const CONTACT_PRICE_STATES := {
	ContactKind.PORT_TRADER: PriceState.CHEAP,
	ContactKind.COVE_BUYER: PriceState.VALUABLE,
}
const PORT_SHORE_ID := "port"
const COVE_SHORE_ID := "cove"
const MARK_RETURN_VOYAGES := 2
const FILLED_MARK := "●"
const EMPTY_MARK := "○"

@export_enum("PORT TRADER", "COVE BUYER") var contact_kind: int = (
	ContactKind.PORT_TRADER
)
@export_range(1, 3, 1) var mark_capacity := 1

var _used_mark_return_voyages: Array[int] = []
var _mark_use_count := 0
var _mark_return_count := 0
var _mark_rollback_count := 0


func is_port_trader() -> bool:
	return contact_kind == ContactKind.PORT_TRADER


func is_cove_buyer() -> bool:
	return contact_kind == ContactKind.COVE_BUYER


func get_display_name() -> String:
	return "PORT TRADER" if is_port_trader() else "COVE BUYER"


func get_shore_id() -> String:
	return PORT_SHORE_ID if is_port_trader() else COVE_SHORE_ID


func get_mark_kind() -> int:
	return MarkKind.STOCK if is_port_trader() else MarkKind.DEMAND


func get_mark_kind_name() -> String:
	return String(MarkKind.keys()[get_mark_kind()])


func get_available_mark_count() -> int:
	return mark_capacity - _used_mark_return_voyages.size()


func get_used_mark_count() -> int:
	return _used_mark_return_voyages.size()


func is_trade_available() -> bool:
	return get_available_mark_count() > 0


func get_base_price_state() -> int:
	return int(CONTACT_PRICE_STATES[contact_kind])


func get_base_price_state_name() -> String:
	return String(PriceState.keys()[get_base_price_state()])


func get_price_state() -> int:
	if is_cove_buyer() and not is_trade_available():
		return PriceState.NORMAL
	return get_base_price_state()


func get_price_state_name() -> String:
	return String(PriceState.keys()[get_price_state()])


func get_fixed_price() -> int:
	return int(FIXED_PRICES[get_price_state()])


func get_money_delta() -> int:
	return -get_fixed_price() if is_port_trader() else get_fixed_price()


func get_money_preview(money_before: int) -> Dictionary:
	var money_delta := get_money_delta()
	return {
		"money_before": money_before,
		"money_after": money_before + money_delta,
		"money_delta": money_delta,
		"price_state": get_price_state_name(),
		"fixed_price": get_fixed_price(),
	}


func use_one_mark(completed_voyage: int) -> int:
	if not is_trade_available():
		return -1
	var due_voyage: int = completed_voyage + MARK_RETURN_VOYAGES
	_used_mark_return_voyages.append(due_voyage)
	_used_mark_return_voyages.sort()
	_mark_use_count += 1
	return due_voyage


func rollback_mark_use(due_voyage: int) -> bool:
	for index in range(_used_mark_return_voyages.size() - 1, -1, -1):
		if _used_mark_return_voyages[index] != due_voyage:
			continue
		_used_mark_return_voyages.remove_at(index)
		_mark_use_count -= 1
		_mark_rollback_count += 1
		return true
	return false


func restore_due_marks(completed_voyage: int) -> int:
	var restored_count := 0
	for index in range(_used_mark_return_voyages.size() - 1, -1, -1):
		if _used_mark_return_voyages[index] > completed_voyage:
			continue
		_used_mark_return_voyages.remove_at(index)
		restored_count += 1
	_mark_return_count += restored_count
	return restored_count


func get_mark_display() -> String:
	var marks := PackedStringArray()
	for index in range(mark_capacity):
		marks.append(
			FILLED_MARK if index < get_available_mark_count() else EMPTY_MARK
		)
	return " ".join(marks)


func get_mark_state(completed_voyage: int) -> Dictionary:
	var used_marks: Array[Dictionary] = []
	for due_voyage in _used_mark_return_voyages:
		used_marks.append({
			"due_voyage": due_voyage,
			"voyages_remaining": maxi(0, due_voyage - completed_voyage),
		})
	var next_return_voyage := -1
	var voyages_until_next_return := 0
	if not _used_mark_return_voyages.is_empty():
		next_return_voyage = _used_mark_return_voyages[0]
		voyages_until_next_return = maxi(
			0,
			next_return_voyage - completed_voyage,
		)
	return {
		"mark_kind": get_mark_kind_name(),
		"mark_capacity": mark_capacity,
		"marks_available": get_available_mark_count(),
		"marks_used": get_used_mark_count(),
		"mark_display": get_mark_display(),
		"used_marks": used_marks,
		"return_voyages": _used_mark_return_voyages.duplicate(),
		"next_return_voyage": next_return_voyage,
		"due_voyage": next_return_voyage,
		"voyages_until_next_return": voyages_until_next_return,
		"voyages_remaining": voyages_until_next_return,
		"completed_voyage": completed_voyage,
		"return_after_completed_voyages": MARK_RETURN_VOYAGES,
		"base_price_state": get_base_price_state_name(),
		"current_price_state": get_price_state_name(),
		"base_fixed_price": int(FIXED_PRICES[get_base_price_state()]),
		"current_fixed_price": get_fixed_price(),
		"trade_available": is_trade_available(),
		"mark_use_count": _mark_use_count,
		"mark_return_count": _mark_return_count,
		"mark_rollback_count": _mark_rollback_count,
	}


static func get_fixed_price_map() -> Dictionary:
	return {
		"CHEAP": CHEAP_PRICE,
		"NORMAL": NORMAL_PRICE,
		"VALUABLE": VALUABLE_PRICE,
	}


func get_playtest_state(completed_voyage: int = 0) -> Dictionary:
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
	var state := {
		"contact_kind": ContactKind.keys()[contact_kind],
		"display_name": get_display_name(),
		"shore_id": get_shore_id(),
		"position": global_position,
		"visible": visible,
		"interaction_region_count": interaction_region_count,
		"interaction_range": interaction_range,
		"good_name": GOOD_NAME,
		"shown_good_count": 1,
		"shown_good_state_count": 1,
		"base_price_state": get_base_price_state_name(),
		"price_state": get_price_state_name(),
		"current_price_state": get_price_state_name(),
		"price_state_index": get_price_state(),
		"fixed_price": get_fixed_price(),
		"current_fixed_price": get_fixed_price(),
		"fixed_price_map": get_fixed_price_map(),
		"state_fixed_for_contact_kind": is_port_trader() or is_trade_available(),
		"buy_price": CHEAP_PRICE,
		"sell_price": VALUABLE_PRICE,
	}
	state.merge(get_mark_state(completed_voyage), true)
	return state


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
