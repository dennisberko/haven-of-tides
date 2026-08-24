class_name StorageShedConstructionSite
extends Area2D

const BUILDING_NAME := "STORAGE SHED"
const COST_LOT_NAME := "TIMBER LOT"
const COST_LOT_COUNT := 1
const INTERACTION_RANGE := 64.0

@onready var interaction_range: CollisionShape2D = $InteractionRange
@onready var unbuilt_visual: Node2D = $UnbuiltSiteVisual
@onready var finished_visual: Node2D = $FinishedStorageShedVisual

var completed := false
var completion_count := 0
var consumed_lot_count := 0
var attempt_count := 0
var denied_attempt_count := 0
var repeat_attempt_count := 0
var last_result := "NOT_ATTEMPTED"


func _ready() -> void:
	_update_visual_state()


func get_stored_cost_lot_count(storage: CoveStorageChest) -> int:
	return storage.count_cargo_lot(COST_LOT_NAME)


func is_construction_available(storage: CoveStorageChest) -> bool:
	return (
		not completed
		and get_stored_cost_lot_count(storage) >= COST_LOT_COUNT
	)


func attempt_construction(storage: CoveStorageChest) -> Dictionary:
	attempt_count += 1
	var storage_before := storage.get_storage_slots()
	var timber_before := get_stored_cost_lot_count(storage)
	var was_completed := completed
	var consumed_lots: Array[String] = []

	if completed:
		repeat_attempt_count += 1
		last_result = "NO_CHANGE_ALREADY_COMPLETE"
	elif timber_before < COST_LOT_COUNT:
		denied_attempt_count += 1
		last_result = "NO_CHANGE_NOT_ENOUGH_COVE_STORED_TIMBER"
	else:
		consumed_lots = storage.consume_cargo_lots(
			COST_LOT_NAME,
			COST_LOT_COUNT,
		)
		if consumed_lots.size() != COST_LOT_COUNT:
			denied_attempt_count += 1
			last_result = "NO_CHANGE_ATOMIC_STORAGE_CONSUME_FAILED"
		else:
			completed = true
			completion_count += 1
			consumed_lot_count += consumed_lots.size()
			last_result = "BUILT_STORAGE_SHED"
			_update_visual_state()

	return {
		"result": last_result,
		"success": not was_completed and completed,
		"was_completed": was_completed,
		"is_completed": completed,
		"storage_slots_before": storage_before,
		"storage_slots_after": storage.get_storage_slots(),
		"stored_timber_before": timber_before,
		"stored_timber_after": get_stored_cost_lot_count(storage),
		"consumed_lots": consumed_lots,
		"consumed_count": consumed_lots.size(),
		"completion_count": completion_count,
	}


func get_playtest_state(storage: CoveStorageChest) -> Dictionary:
	var unbuilt_visible := unbuilt_visual.visible and unbuilt_visual.is_visible_in_tree()
	var finished_visible := finished_visual.visible and finished_visual.is_visible_in_tree()
	return {
		"building_name": BUILDING_NAME,
		"cost_lot_name": COST_LOT_NAME,
		"cost_lot_count": COST_LOT_COUNT,
		"fixed_cost_text": "%d %s" % [COST_LOT_COUNT, COST_LOT_NAME],
		"stored_cost_lot_count": get_stored_cost_lot_count(storage),
		"available": is_construction_available(storage),
		"completed": completed,
		"completion_count": completion_count,
		"consumed_lot_count": consumed_lot_count,
		"attempt_count": attempt_count,
		"denied_attempt_count": denied_attempt_count,
		"repeat_attempt_count": repeat_attempt_count,
		"last_result": last_result,
		"position": global_position,
		"interaction_range": INTERACTION_RANGE,
		"construction_site_node_count": 1,
		"interaction_region_count": 1,
		"unbuilt_visual_owner_count": 1,
		"finished_visual_owner_count": 1,
		"unbuilt_visual_visible": unbuilt_visible,
		"finished_visual_visible": finished_visible,
		"visible_visual_count": int(unbuilt_visible) + int(finished_visible),
		"visuals_exclusive": unbuilt_visible != finished_visible,
		"interaction_enabled": not interaction_range.disabled,
	}


func _update_visual_state() -> void:
	unbuilt_visual.visible = not completed
	finished_visual.visible = completed
	# Keep the one region active as a return-visit observer. Completed sites cannot
	# reopen because the main interaction gate also checks `completed`.
	interaction_range.set_deferred("disabled", false)
