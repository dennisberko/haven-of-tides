extends RefCounted

const SOURCE_CARGO_LOT_NAME := "WEAPONS AND GUNPOWDER CARGO LOT"
const LOADED_CARGO_LOT_PREFIX := "LOADED AMMUNITION LOT · "
const AMMUNITION_UNITS_PER_LOT := 3
const SOURCE_CARGO_FIXED_PRICE := 2
const PORT_DOCK_ID := "port"

var load_attempt_count := 0
var load_success_count := 0
var load_denied_count := 0
var total_units_loaded := 0
var total_units_consumed := 0
var depleted_lot_count := 0
var defeat_loss_attempt_count := 0
var defeat_unit_loss_count := 0
var defeat_depleted_lot_count := 0
var last_load_evidence: Dictionary = {}
var successful_load_evidence: Dictionary = {}
var last_denied_load_evidence: Dictionary = {}
var last_consumption_evidence: Dictionary = {}
var last_defeat_loss_evidence: Dictionary = {}


func get_source_lot_count(cargo_lots: Array[String]) -> int:
	return cargo_lots.count(SOURCE_CARGO_LOT_NAME)


func get_loaded_lot_count(cargo_lots: Array[String]) -> int:
	var loaded_lot_count: int = 0
	for lot_name in cargo_lots:
		if get_lot_ammunition_units(lot_name) > 0:
			loaded_lot_count += 1
	return loaded_lot_count


func get_ammunition_units(cargo_lots: Array[String]) -> int:
	var unit_count: int = 0
	for lot_name in cargo_lots:
		unit_count += get_lot_ammunition_units(lot_name)
	return unit_count


func get_lot_ammunition_units(lot_name: String) -> int:
	if not lot_name.begins_with(LOADED_CARGO_LOT_PREFIX):
		return 0
	var unit_text: String = lot_name.trim_prefix(LOADED_CARGO_LOT_PREFIX)
	return maxi(0, unit_text.to_int())


func get_loaded_lot_name(unit_count: int) -> String:
	return "%s%d UNIT%s" % [
		LOADED_CARGO_LOT_PREFIX,
		unit_count,
		"" if unit_count == 1 else "S",
	]


func attempt_port_load(
	cargo_lots: Array[String],
	ship_is_docked: bool,
	current_dock_id: String,
) -> Dictionary:
	load_attempt_count += 1
	var cargo_before: Array[String] = cargo_lots.duplicate()
	var ammunition_before: int = get_ammunition_units(cargo_lots)
	var source_lot_count_before: int = get_source_lot_count(cargo_lots)
	var source_slot_index: int = cargo_lots.find(SOURCE_CARGO_LOT_NAME)
	var denial_reasons: PackedStringArray = PackedStringArray()
	if not ship_is_docked or current_dock_id != PORT_DOCK_ID:
		denial_reasons.append("SHIP MUST BE DOCKED AT PORT")
	if source_slot_index < 0:
		denial_reasons.append("NO WEAPONS AND GUNPOWDER CARGO LOT")
	if not denial_reasons.is_empty():
		load_denied_count += 1
		last_load_evidence = _build_load_evidence(
			false,
			cargo_before,
			cargo_lots,
			ammunition_before,
			source_lot_count_before,
			-1,
			"LOAD DENIED · %s" % " · ".join(denial_reasons),
		)
		last_denied_load_evidence = last_load_evidence.duplicate(true)
		return last_load_evidence.duplicate(true)

	cargo_lots[source_slot_index] = get_loaded_lot_name(
		AMMUNITION_UNITS_PER_LOT
	)
	load_success_count += 1
	total_units_loaded += AMMUNITION_UNITS_PER_LOT
	last_load_evidence = _build_load_evidence(
		true,
		cargo_before,
		cargo_lots,
		ammunition_before,
		source_lot_count_before,
		source_slot_index,
		"LOADED %d AMMUNITION · SAME CARGO SLOT" % (
			AMMUNITION_UNITS_PER_LOT
		),
	)
	successful_load_evidence = last_load_evidence.duplicate(true)
	return last_load_evidence.duplicate(true)


func consume_for_accepted_broadside(cargo_lots: Array[String]) -> Dictionary:
	var cargo_before: Array[String] = cargo_lots.duplicate()
	var ammunition_before: int = get_ammunition_units(cargo_lots)
	var loaded_slot_index: int = -1
	var loaded_slot_units: int = 0
	for slot_index in range(cargo_lots.size()):
		var slot_units: int = get_lot_ammunition_units(cargo_lots[slot_index])
		if slot_units <= 0:
			continue
		loaded_slot_index = slot_index
		loaded_slot_units = slot_units
		break

	if loaded_slot_index < 0 or ammunition_before <= 0:
		last_consumption_evidence = {
			"success": false,
			"result": "AMMUNITION CONSUMPTION FAILED · NO LOADED UNIT",
			"ammunition_before": ammunition_before,
			"ammunition_after": ammunition_before,
			"ammunition_delta": 0,
			"cargo_before": cargo_before,
			"cargo_after": cargo_lots.duplicate(),
			"cargo_unchanged": cargo_before == cargo_lots,
			"cargo_slot_index": -1,
			"loaded_lot_removed": false,
		}
		return last_consumption_evidence.duplicate(true)

	var loaded_lot_removed: bool = loaded_slot_units == 1
	if loaded_lot_removed:
		cargo_lots.pop_at(loaded_slot_index)
		depleted_lot_count += 1
	else:
		cargo_lots[loaded_slot_index] = get_loaded_lot_name(
			loaded_slot_units - 1
		)
	total_units_consumed += 1
	var ammunition_after: int = get_ammunition_units(cargo_lots)
	last_consumption_evidence = {
		"success": true,
		"result": "USED 1 AMMUNITION",
		"ammunition_before": ammunition_before,
		"ammunition_after": ammunition_after,
		"ammunition_delta": ammunition_after - ammunition_before,
		"consumed_exactly_one": ammunition_after == ammunition_before - 1,
		"cargo_before": cargo_before,
		"cargo_after": cargo_lots.duplicate(),
		"cargo_slot_index": loaded_slot_index,
		"loaded_lot_units_before": loaded_slot_units,
		"loaded_lot_units_after": maxi(0, loaded_slot_units - 1),
		"loaded_lot_removed": loaded_lot_removed,
		"removed_only_when_empty": (
			not loaded_lot_removed or loaded_slot_units == 1
		),
	}
	return last_consumption_evidence.duplicate(true)


func consume_for_accepted_harpoon(cargo_lots: Array[String]) -> Dictionary:
	var evidence := consume_for_accepted_broadside(cargo_lots)
	evidence["consumer"] = "MONSTER_HARPOON"
	evidence["uses_same_loaded_ammunition_units"] = true
	last_consumption_evidence = evidence.duplicate(true)
	return evidence


func consume_for_accepted_long_guns(cargo_lots: Array[String]) -> Dictionary:
	var evidence := consume_for_accepted_broadside(cargo_lots)
	evidence["consumer"] = "LONG_GUNS_PURSUIT_ATTACK"
	evidence["uses_same_loaded_ammunition_units"] = true
	last_consumption_evidence = evidence.duplicate(true)
	return evidence


func apply_limited_defeat_loss(
	cargo_lots: Array[String],
	unit_loss: int,
	minimum_retained_cargo_lots: int,
) -> Dictionary:
	defeat_loss_attempt_count += 1
	var cargo_before: Array[String] = cargo_lots.duplicate()
	var ammunition_before := get_ammunition_units(cargo_lots)
	var loaded_slot_index := -1
	var loaded_slot_units := 0
	for slot_index in range(cargo_lots.size()):
		var slot_units := get_lot_ammunition_units(cargo_lots[slot_index])
		if slot_units <= 0:
			continue
		loaded_slot_index = slot_index
		loaded_slot_units = slot_units
		break

	var actual_unit_loss := mini(maxi(unit_loss, 0), loaded_slot_units)
	var would_remove_last_cargo_lot := (
		actual_unit_loss >= loaded_slot_units
		and cargo_lots.size() <= minimum_retained_cargo_lots
	)
	if (
		loaded_slot_index < 0
		or actual_unit_loss <= 0
		or would_remove_last_cargo_lot
	):
		last_defeat_loss_evidence = {
			"success": false,
			"result": (
				"DEFEAT AMMUNITION LOSS LIMITED · RETAIN LAST CARGO LOT"
				if would_remove_last_cargo_lot
				else "DEFEAT AMMUNITION LOSS UNAVAILABLE"
			),
			"requested_unit_loss": unit_loss,
			"actual_unit_loss": 0,
			"ammunition_before": ammunition_before,
			"ammunition_after": ammunition_before,
			"cargo_before": cargo_before,
			"cargo_after": cargo_lots.duplicate(),
			"minimum_retained_cargo_lots": minimum_retained_cargo_lots,
			"last_cargo_lot_retained": would_remove_last_cargo_lot,
			"no_state_change": true,
		}
		return last_defeat_loss_evidence.duplicate(true)

	var depleted_lot := actual_unit_loss >= loaded_slot_units
	if depleted_lot:
		cargo_lots.pop_at(loaded_slot_index)
		defeat_depleted_lot_count += 1
	else:
		cargo_lots[loaded_slot_index] = get_loaded_lot_name(
			loaded_slot_units - actual_unit_loss
		)
	defeat_unit_loss_count += actual_unit_loss
	var ammunition_after := get_ammunition_units(cargo_lots)
	last_defeat_loss_evidence = {
		"success": true,
		"result": "DEFEAT LOSS · -%d AMMUNITION" % actual_unit_loss,
		"requested_unit_loss": unit_loss,
		"actual_unit_loss": actual_unit_loss,
		"ammunition_before": ammunition_before,
		"ammunition_after": ammunition_after,
		"ammunition_delta": ammunition_after - ammunition_before,
		"cargo_before": cargo_before,
		"cargo_after": cargo_lots.duplicate(),
		"loaded_slot_index": loaded_slot_index,
		"loaded_lot_units_before": loaded_slot_units,
		"loaded_lot_units_after": maxi(0, loaded_slot_units - actual_unit_loss),
		"loaded_lot_removed": depleted_lot,
		"cargo_slot_loss": cargo_before.size() - cargo_lots.size(),
		"minimum_retained_cargo_lots": minimum_retained_cargo_lots,
		"cargo_retained": cargo_lots.size() >= minimum_retained_cargo_lots,
		"loss_matches_request": actual_unit_loss == unit_loss,
	}
	return last_defeat_loss_evidence.duplicate(true)


func get_playtest_state(cargo_lots: Array[String]) -> Dictionary:
	var ammunition_units: int = get_ammunition_units(cargo_lots)
	return {
		"system_count": 1,
		"source_cargo_lot_name": SOURCE_CARGO_LOT_NAME,
		"loaded_cargo_lot_prefix": LOADED_CARGO_LOT_PREFIX,
		"units_per_loaded_lot": AMMUNITION_UNITS_PER_LOT,
		"source_cargo_fixed_price": SOURCE_CARGO_FIXED_PRICE,
		"source_lot_count": get_source_lot_count(cargo_lots),
		"loaded_lot_count": get_loaded_lot_count(cargo_lots),
		"ammunition_units": ammunition_units,
		"low_ammunition_warning": ammunition_units == 2,
		"no_ammunition_warning": ammunition_units == 0,
		"load_attempt_count": load_attempt_count,
		"load_success_count": load_success_count,
		"load_denied_count": load_denied_count,
		"total_units_loaded": total_units_loaded,
		"total_units_consumed": total_units_consumed,
		"depleted_lot_count": depleted_lot_count,
		"defeat_loss_attempt_count": defeat_loss_attempt_count,
		"defeat_unit_loss_count": defeat_unit_loss_count,
		"defeat_depleted_lot_count": defeat_depleted_lot_count,
		"cargo_lot_consumed_only_when_ammunition_reaches_zero": true,
		"last_load_evidence": last_load_evidence.duplicate(true),
		"successful_load_evidence": successful_load_evidence.duplicate(true),
		"last_denied_load_evidence": last_denied_load_evidence.duplicate(true),
		"last_consumption_evidence": (
			last_consumption_evidence.duplicate(true)
		),
		"last_defeat_loss_evidence": (
			last_defeat_loss_evidence.duplicate(true)
		),
		"ammunition_type_count": 1,
		"free_ammunition_at_sea_count": 0,
		"cannon_upgrade_count": 0,
		"prize_cannon_count": 0,
		"crew_ammunition_task_count": 0,
	}


func _build_load_evidence(
	success: bool,
	cargo_before: Array[String],
	cargo_after: Array[String],
	ammunition_before: int,
	source_lot_count_before: int,
	converted_slot_index: int,
	result: String,
) -> Dictionary:
	var ammunition_after: int = get_ammunition_units(cargo_after)
	var source_lot_count_after: int = get_source_lot_count(cargo_after)
	return {
		"success": success,
		"action": "LOAD_AMMUNITION_AT_PORT",
		"result": result,
		"cargo_before": cargo_before,
		"cargo_after": cargo_after.duplicate(),
		"cargo_slot_count_before": cargo_before.size(),
		"cargo_slot_count_after": cargo_after.size(),
		"cargo_slot_count_unchanged": cargo_before.size() == cargo_after.size(),
		"converted_slot_index": converted_slot_index,
		"source_lot_count_before": source_lot_count_before,
		"source_lot_count_after": source_lot_count_after,
		"source_lot_delta": source_lot_count_after - source_lot_count_before,
		"ammunition_before": ammunition_before,
		"ammunition_after": ammunition_after,
		"ammunition_delta": ammunition_after - ammunition_before,
		"loaded_exactly_three": (
			not success
			or ammunition_after
				== ammunition_before + AMMUNITION_UNITS_PER_LOT
		),
		"same_cargo_slot": (
			not success or cargo_before.size() == cargo_after.size()
		),
		"one_source_lot_converted": (
			not success or source_lot_count_after == source_lot_count_before - 1
		),
	}
