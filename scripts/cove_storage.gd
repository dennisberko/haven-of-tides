class_name CoveStorageChest
extends Area2D

const ShipFoodState := preload("res://scripts/ship_food.gd")

const STORAGE_LIMIT := 3
const INTERACTION_RANGE := 58.0
const FOOD_LOT_NAME := ShipFoodState.FOOD_LOT_NAME
const STARTING_CARGO_SLOTS := [
	FOOD_LOT_NAME,
	FOOD_LOT_NAME,
	"",
]

var cargo_slots: Array[String] = [
	FOOD_LOT_NAME,
	FOOD_LOT_NAME,
	"",
]


func _ready() -> void:
	queue_redraw()


func get_storage_limit() -> int:
	return STORAGE_LIMIT


func get_cargo_lots() -> Array[String]:
	var lots: Array[String] = []
	for lot_name in cargo_slots:
		if not lot_name.is_empty():
			lots.append(lot_name)
	return lots


func get_storage_slots() -> Array[String]:
	return cargo_slots.duplicate()


func count_cargo_lot(lot_name: String) -> int:
	return cargo_slots.count(lot_name)


func consume_cargo_lots(lot_name: String, amount: int) -> Array[String]:
	var consumed_lots: Array[String] = []
	if lot_name.is_empty() or amount <= 0:
		return consumed_lots

	var matching_slots: Array[int] = []
	for slot_index in range(STORAGE_LIMIT):
		if cargo_slots[slot_index] == lot_name:
			matching_slots.append(slot_index)
			if matching_slots.size() == amount:
				break
	if matching_slots.size() != amount:
		return consumed_lots

	for slot_index in matching_slots:
		consumed_lots.append(cargo_slots[slot_index])
		cargo_slots[slot_index] = ""
	return consumed_lots


func get_first_free_slot_index() -> int:
	for slot_index in range(STORAGE_LIMIT):
		if cargo_slots[slot_index].is_empty():
			return slot_index
	return -1


func can_store_cargo_lot() -> bool:
	return get_first_free_slot_index() >= 0


func store_cargo_lot(lot_name: String) -> bool:
	if lot_name.is_empty() or not can_store_cargo_lot():
		return false
	cargo_slots[get_first_free_slot_index()] = lot_name
	return true


func remove_cargo_slot(slot_index: int) -> String:
	if (
		slot_index < 0
		or slot_index >= STORAGE_LIMIT
		or cargo_slots[slot_index].is_empty()
	):
		return ""
	var removed_lot := cargo_slots[slot_index]
	cargo_slots[slot_index] = ""
	return removed_lot


func restore_cargo_slot(slot_index: int, lot_name: String) -> bool:
	if (
		lot_name.is_empty()
		or slot_index < 0
		or slot_index >= STORAGE_LIMIT
		or not cargo_slots[slot_index].is_empty()
	):
		return false
	cargo_slots[slot_index] = lot_name
	return true


func get_playtest_state() -> Dictionary:
	return {
		"place_count": 1,
		"position": global_position,
		"interaction_range": INTERACTION_RANGE,
		"interaction_region_count": 1,
		"visible": visible and is_visible_in_tree(),
		"storage_limit": STORAGE_LIMIT,
		"storage_used_slots": get_cargo_lots().size(),
		"storage_free_slots": STORAGE_LIMIT - get_cargo_lots().size(),
		"storage_lots": get_cargo_lots(),
		"storage_slots": get_storage_slots(),
		"food_lot_name": FOOD_LOT_NAME,
		"starting_storage_slots": STARTING_CARGO_SLOTS.duplicate(),
		"starting_storage_lots": [FOOD_LOT_NAME, FOOD_LOT_NAME],
		"starting_storage_used_slots": 2,
		"starting_storage_free_slots": 1,
		"starting_storage_food_units": 2,
		"food_units": count_cargo_lot(FOOD_LOT_NAME),
		"phase_19_real_load_path": (
			"STORE SHIP SLOT 1 WITH [1], THEN WITHDRAW COVE SLOTS 1 AND 2 WITH [4] AND [5]"
		),
	}


func _draw() -> void:
	# One fixed chest and one name marker identify the cove storage place.
	draw_ellipse(Vector2(0.0, 19.0), 48.0, 13.0, Color("#12323c66"))
	draw_rect(Rect2(-43.0, -25.0, 86.0, 52.0), Color("#6b452c"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-47.0, -25.0),
		Vector2(-35.0, -42.0),
		Vector2(35.0, -42.0),
		Vector2(47.0, -25.0),
	]), Color("#b27a47"))
	draw_rect(Rect2(-7.0, -16.0, 14.0, 22.0), Color("#e2bf72"))
	draw_line(Vector2(-43.0, 0.0), Vector2(43.0, 0.0), Color("#493323"), 4.0)
	draw_line(Vector2(-48.0, 34.0), Vector2(48.0, 34.0), Color("#fff1c5"), 3.0)
	var font := ThemeDB.fallback_font
	draw_string(
		font,
		Vector2(-90.0, 58.0),
		"COVE STORAGE",
		HORIZONTAL_ALIGNMENT_CENTER,
		180.0,
		17,
		Color("#fff1c5"),
	)
