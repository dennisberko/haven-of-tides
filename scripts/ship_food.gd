class_name ShipFoodState
extends RefCounted

const FOOD_LOT_NAME := "VOYAGE FOOD LOT"
const DISTANCE_PER_USE := 600.0

var _progress_distance := 0.0
var _total_sailing_distance := 0.0
var _zero_food_sailing_distance := 0.0
var _total_units_used := 0
var _failed_use_count := 0
var _last_movement_distance := 0.0
var _last_due_use_count := 0
var _last_use_evidence: Dictionary = {}
var _last_zero_food_movement_evidence: Dictionary = {}


func sync_food_units(food_units: int) -> void:
	if food_units <= 0:
		_progress_distance = 0.0


func record_sailing_movement(actual_distance: float, food_units: int) -> int:
	if actual_distance <= 0.0:
		return 0

	_last_movement_distance = actual_distance
	_total_sailing_distance += actual_distance
	_last_due_use_count = 0
	if food_units <= 0:
		_progress_distance = 0.0
		_zero_food_sailing_distance += actual_distance
		return 0

	var accumulated_distance := _progress_distance + actual_distance
	var threshold_count := floori(accumulated_distance / DISTANCE_PER_USE)
	var due_use_count := mini(threshold_count, food_units)
	_last_due_use_count = due_use_count
	if due_use_count >= food_units and threshold_count >= food_units:
		_zero_food_sailing_distance += maxf(
			0.0,
			accumulated_distance - float(food_units) * DISTANCE_PER_USE,
		)
		_progress_distance = 0.0
	else:
		_progress_distance = fmod(
			accumulated_distance,
			DISTANCE_PER_USE,
		)
	return due_use_count


func record_food_use(
	cargo_before: Array[String],
	cargo_after: Array[String],
	actual_movement_distance: float,
	due_use_count: int,
	use_number_in_movement: int,
) -> void:
	_total_units_used += 1
	var food_units_before := cargo_before.count(FOOD_LOT_NAME)
	var food_units_after := cargo_after.count(FOOD_LOT_NAME)
	var other_cargo_before := _get_other_cargo(cargo_before)
	var other_cargo_after := _get_other_cargo(cargo_after)
	_last_use_evidence = {
		"success": true,
		"food_lot_name": FOOD_LOT_NAME,
		"distance_per_use": DISTANCE_PER_USE,
		"actual_movement_distance": actual_movement_distance,
		"due_use_count_in_movement": due_use_count,
		"use_number_in_movement": use_number_in_movement,
		"cargo_before": cargo_before.duplicate(),
		"cargo_after": cargo_after.duplicate(),
		"cargo_count_before": cargo_before.size(),
		"cargo_count_after": cargo_after.size(),
		"food_units_before": food_units_before,
		"food_units_after": food_units_after,
		"other_cargo_before": other_cargo_before,
		"other_cargo_after": other_cargo_after,
		"other_cargo_unchanged": other_cargo_before == other_cargo_after,
		"removed_exactly_one_food_lot": (
			food_units_before - food_units_after == 1
			and cargo_before.size() - cargo_after.size() == 1
		),
		"progress_after": _progress_distance,
		"total_units_used_after": _total_units_used,
	}


func record_failed_food_use(cargo_snapshot: Array[String]) -> void:
	_failed_use_count += 1
	_last_use_evidence = {
		"success": false,
		"food_lot_name": FOOD_LOT_NAME,
		"cargo_before": cargo_snapshot.duplicate(),
		"cargo_after": cargo_snapshot.duplicate(),
		"removed_exactly_one_food_lot": false,
	}


func record_zero_food_movement(
	actual_distance: float,
	cargo_before: Array[String],
	cargo_after: Array[String],
	controls_enabled: bool,
	captain_aboard: bool,
) -> void:
	if actual_distance <= 0.0:
		return
	_last_zero_food_movement_evidence = {
		"actual_movement_distance": actual_distance,
		"cargo_before": cargo_before.duplicate(),
		"cargo_after": cargo_after.duplicate(),
		"cargo_unchanged": cargo_before == cargo_after,
		"food_units_before": cargo_before.count(FOOD_LOT_NAME),
		"food_units_after": cargo_after.count(FOOD_LOT_NAME),
		"controls_enabled": controls_enabled,
		"captain_aboard": captain_aboard,
		"sailing_continued": (
			actual_distance > 0.0
			and controls_enabled
			and captain_aboard
			and cargo_before == cargo_after
		),
	}


func get_playtest_state(food_units: int) -> Dictionary:
	var distance_to_next_use := 0.0
	if food_units > 0:
		distance_to_next_use = maxf(
			0.0,
			DISTANCE_PER_USE - _progress_distance,
		)
	var status := "SUPPLY READY"
	if food_units == 1:
		status = "LOW FOOD"
	elif food_units <= 0:
		status = "NO FOOD · SAILING CONTINUES"
	return {
		"owner_count": 1,
		"food_lot_name": FOOD_LOT_NAME,
		"distance_per_use": DISTANCE_PER_USE,
		"food_units": food_units,
		"progress_distance": _progress_distance,
		"distance_to_next_use": distance_to_next_use,
		"total_sailing_distance": _total_sailing_distance,
		"zero_food_sailing_distance": _zero_food_sailing_distance,
		"total_units_used": _total_units_used,
		"failed_use_count": _failed_use_count,
		"last_movement_distance": _last_movement_distance,
		"last_due_use_count": _last_due_use_count,
		"last_use_evidence": _last_use_evidence.duplicate(true),
		"last_zero_food_movement_evidence": (
			_last_zero_food_movement_evidence.duplicate(true)
		),
		"status": status,
		"low_food_warning": food_units == 1,
		"no_food_warning": food_units <= 0,
		"sailing_continues_without_food": true,
		"progress_debt_while_empty": 0.0,
		"uses_actual_moved_distance_only": true,
	}


func _get_other_cargo(cargo: Array[String]) -> Array[String]:
	var other_cargo: Array[String] = []
	for lot_name in cargo:
		if lot_name != FOOD_LOT_NAME:
			other_cargo.append(lot_name)
	return other_cargo
