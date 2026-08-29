extends Node2D

const ShipFoodState := preload("res://scripts/ship_food.gd")
const ShipDamageState := preload("res://scripts/ship_damage.gd")

const ACCELERATION := 140.0
const COAST_DECELERATION := 90.0
const BRAKE_DECELERATION := 260.0
const TOP_SPEED := 280.0
const TURN_SPEED := PI / 2.0
const HULL_CLEARANCE := 105.0
const DOCK_POSITION := Vector2(1070.0, 510.0)
const DOCK_ROTATION := PI
const DOCK_DEPARTURE_DISTANCE := 0.01
const DOCK_EXIT_CLEAR_Y := 655.0
const DOCK_EXIT_HALF_WIDTH := 45.0
const COVE_ENTRANCE_POSITION := Vector2(1070.0, 760.0)
const COVE_ENTRANCE_RADIUS := 110.0
const DOCK_DISTANCE_THRESHOLD := 70.0
const DOCK_MAX_SPEED := 12.0
const DOCK_MIN_ALIGNMENT := 0.92
const CARGO_LIMIT := 3
const TIMBER_LOT_NAME := "TIMBER LOT"
const REPAIR_COST_LOT_NAME := TIMBER_LOT_NAME
const REPAIR_COST_LOT_COUNT := 1
const FOOD_LOT_NAME := ShipFoodState.FOOD_LOT_NAME
const FOOD_USE_DISTANCE := ShipFoodState.DISTANCE_PER_USE
const STARTING_CARGO_LOTS := [
	"COVE MEDICINE LOT",
	FOOD_LOT_NAME,
]

@onready var damage_impact_sound: AudioStreamPlayer = $DamageImpactSound
const DOCK_IDS := ["cove", "island", "port"]
const DOCK_DEFINITIONS := {
	"cove": {
		"id": "cove",
		"name": "DAMAGED COVE DOCK",
		"approach_position": Vector2(1070.0, 760.0),
		"approach_heading": Vector2.UP,
		"snap_position": Vector2(1070.0, 510.0),
		"snap_rotation": PI,
		"shore_position": Vector2(894.0, 486.0),
		"shore_region": {
			"kind": "COVE_COLLISION",
			"center": Vector2.ZERO,
		},
	},
	"island": {
		"id": "island",
		"name": "TEST ISLAND DOCK",
		"approach_position": Vector2(1550.0, 1575.0),
		"approach_heading": Vector2.UP,
		"snap_position": Vector2(1550.0, 1575.0),
		"snap_rotation": PI,
		"shore_position": Vector2(1550.0, 1400.0),
		"shore_region": {
			"kind": "CIRCLE",
			"center": Vector2(1550.0, 1250.0),
			"radius": 150.0,
		},
	},
	"port": {
		"id": "port",
		"name": "TEST PORT DOCK",
		"approach_position": Vector2(2630.0, 785.0),
		"approach_heading": Vector2.UP,
		"snap_position": Vector2(2630.0, 785.0),
		"snap_rotation": PI,
		"shore_position": Vector2(2630.0, 630.0),
		"shore_region": {
			"kind": "RECTANGLE",
			"rect": Rect2(2420.0, 380.0, 420.0, 250.0),
		},
	},
}

var current_speed := 0.0
var sailing_velocity := Vector2.ZERO
var controls_enabled := false
var captain_aboard := false
var has_departed_dock := false
var at_damaged_dock := true
var is_docked := false
var current_dock_id := ""
var last_dock_id := ""
var last_collision_response := "NONE"
var navigation_input_blocked := false
var navigation_release_pending := false
var timber_lots := 0
var cargo_lots: Array[String] = [
	"COVE MEDICINE LOT",
	FOOD_LOT_NAME,
]

var _sea_bounds := Rect2()
var _island_center := Vector2.ZERO
var _island_radius := 0.0
var _port_land_rect := Rect2()
var _cove_shoreline := PackedVector2Array()
var _reef_center := Vector2.ZERO
var _reef_radius := 0.0
var _dock_exit_cleared := false
var _departure_input_armed := false
var _restore_controls_after_navigation_release := false
var _starting_used_slots := 0
var _max_used_slots_observed := 0
var _cargo_limit_never_exceeded := true
var _food_state = ShipFoodState.new()
var _damage_state = ShipDamageState.new()
var _repair_attempt_count := 0
var _repair_success_count := 0
var _repair_denied_attempt_count := 0
var _repair_consumed_timber_count := 0
var _last_repair_attempt_evidence: Dictionary = {}
var _successful_repair_evidence: Dictionary = {}
var _last_denied_repair_evidence: Dictionary = {}


func _ready() -> void:
	_starting_used_slots = cargo_lots.size()
	_record_cargo_usage()
	_configure_damage_impact_sound()
	queue_redraw()


func configure_sailing_area(
		sea_bounds: Rect2,
		island_center: Vector2,
		island_radius: float,
		port_land_rect: Rect2,
		cove_shoreline: PackedVector2Array,
		reef_center: Vector2,
		reef_radius: float,
) -> void:
	_sea_bounds = sea_bounds
	_island_center = island_center
	_island_radius = island_radius
	_port_land_rect = port_land_rect
	_cove_shoreline = cove_shoreline
	_reef_center = reef_center
	_reef_radius = reef_radius


func _configure_damage_impact_sound() -> void:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var sample_count := int(
		stream.mix_rate * ShipDamageState.IMPACT_SOUND_DURATION
	)
	var samples := PackedByteArray()
	samples.resize(sample_count * 2)
	for sample_index in range(sample_count):
		var time_seconds := float(sample_index) / float(stream.mix_rate)
		var envelope := 1.0 - float(sample_index) / float(sample_count)
		var tone := (
			sin(TAU * 115.0 * time_seconds)
			+ 0.45 * sin(TAU * 230.0 * time_seconds)
		)
		var sample_value := clampi(
			int(tone * envelope * 10500.0),
			-32768,
			32767,
		)
		samples.encode_s16(sample_index * 2, sample_value)
	stream.data = samples
	damage_impact_sound.stream = stream
	_damage_state.configure_sound(
		stream.get_class(),
		ShipDamageState.IMPACT_SOUND_DURATION,
	)


func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = (
		enabled
		and not is_docked
		and not navigation_input_blocked
		and not navigation_release_pending
	)
	if not controls_enabled:
		current_speed = 0.0
		sailing_velocity = Vector2.ZERO


func set_navigation_input_blocked(
	blocked: bool,
	restore_controls_after_release := false,
) -> void:
	navigation_input_blocked = blocked
	navigation_release_pending = not blocked
	_restore_controls_after_navigation_release = (
		restore_controls_after_release and not is_docked
	)
	controls_enabled = false
	current_speed = 0.0
	sailing_velocity = Vector2.ZERO
	# A chart transition must always require a fresh dock-departure press.
	_departure_input_armed = false


func set_captain_aboard(aboard: bool) -> void:
	captain_aboard = aboard
	if not captain_aboard:
		_departure_input_armed = false
		set_controls_enabled(false)


func can_leave_at_damaged_dock() -> bool:
	return (
		controls_enabled
		and captain_aboard
		and at_damaged_dock
		and not is_docked
		and not has_departed_dock
		and is_zero_approx(current_speed)
	)


func is_at_cove_entrance() -> bool:
	return global_position.distance_to(COVE_ENTRANCE_POSITION) <= COVE_ENTRANCE_RADIUS


func get_forward_direction() -> Vector2:
	return Vector2.UP.rotated(rotation)


func can_accept_salvaged_timber_lot() -> bool:
	return can_keep_cargo_lot() and not cargo_lots.has(TIMBER_LOT_NAME)


func add_salvaged_timber_lot() -> bool:
	if not can_accept_salvaged_timber_lot():
		return false
	return keep_cargo_lot(TIMBER_LOT_NAME)


func can_keep_cargo_lot() -> bool:
	return cargo_lots.size() < CARGO_LIMIT


func keep_cargo_lot(lot_name: String) -> bool:
	if lot_name.is_empty() or not can_keep_cargo_lot():
		return false
	cargo_lots.append(lot_name)
	_sync_cargo_state()
	return true


func undo_last_kept_cargo_lot(lot_name: String) -> bool:
	if cargo_lots.is_empty() or cargo_lots.back() != lot_name:
		return false
	cargo_lots.pop_back()
	_sync_cargo_state()
	return true


func replace_cargo_slot(slot_index: int, new_lot_name: String) -> String:
	if (
		new_lot_name.is_empty()
		or slot_index < 0
		or slot_index >= cargo_lots.size()
	):
		return ""
	var removed_lot := cargo_lots[slot_index]
	cargo_lots[slot_index] = new_lot_name
	_sync_cargo_state()
	return removed_lot


func remove_cargo_slot_for_storage(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= cargo_lots.size():
		return ""
	var removed_lot: String = String(cargo_lots.pop_at(slot_index))
	_sync_cargo_state()
	return removed_lot


func remove_cargo_lot(lot_name: String) -> bool:
	var slot_index := cargo_lots.find(lot_name)
	if lot_name.is_empty() or slot_index < 0:
		return false
	cargo_lots.pop_at(slot_index)
	_sync_cargo_state()
	return true


func restore_cargo_slot_from_storage(slot_index: int, lot_name: String) -> bool:
	if (
		lot_name.is_empty()
		or cargo_lots.size() >= CARGO_LIMIT
		or slot_index < 0
		or slot_index > cargo_lots.size()
	):
		return false
	cargo_lots.insert(slot_index, lot_name)
	_sync_cargo_state()
	return true


func get_cargo_lots() -> Array[String]:
	return cargo_lots.duplicate()


func get_cargo_limit() -> int:
	return CARGO_LIMIT


func get_food_units() -> int:
	return cargo_lots.count(FOOD_LOT_NAME)


func get_food_playtest_state() -> Dictionary:
	return _food_state.get_playtest_state(get_food_units())


func get_damage_playtest_state() -> Dictionary:
	return _damage_state.get_playtest_state()


func get_repair_playtest_state() -> Dictionary:
	var damage_state: Dictionary = get_damage_playtest_state()
	var hull_current := int(damage_state["hull_current"])
	var hull_max := int(damage_state["hull_max"])
	var preview_hull_after := mini(
		hull_max,
		hull_current + ShipDamageState.FIXED_REPAIR_AMOUNT,
	)
	var denial_reasons := PackedStringArray()
	if not captain_aboard:
		denial_reasons.append("CAPTAIN MUST BE ABOARD")
	if not is_docked:
		denial_reasons.append("SHIP MUST BE DOCKED")
	if hull_current >= hull_max:
		denial_reasons.append("HULL IS FULL")
	if timber_lots < REPAIR_COST_LOT_COUNT:
		denial_reasons.append("NEED 1 TIMBER LOT IN SHIP CARGO")
	var available := denial_reasons.is_empty()
	return {
		"system_count": 1,
		"available": available,
		"denial_reasons": denial_reasons,
		"status_text": (
			"READY · PRESS R TO CONFIRM"
			if available
			else "DISABLED · %s" % " · ".join(denial_reasons)
		),
		"fixed_repair_amount": ShipDamageState.FIXED_REPAIR_AMOUNT,
		"cost_lot_name": REPAIR_COST_LOT_NAME,
		"cost_lot_count": REPAIR_COST_LOT_COUNT,
		"fixed_cost_text": "1 TIMBER LOT",
		"uses_money": false,
		"hull_before_preview": hull_current,
		"hull_after_preview": preview_hull_after,
		"hull_gain_preview": preview_hull_after - hull_current,
		"preview_text": "%d -> %d (+%d)" % [
			hull_current,
			preview_hull_after,
			preview_hull_after - hull_current,
		],
		"captain_aboard": captain_aboard,
		"ship_is_docked": is_docked,
		"current_dock_id": current_dock_id,
		"ship_timber_count": timber_lots,
		"attempt_count": _repair_attempt_count,
		"success_count": _repair_success_count,
		"denied_attempt_count": _repair_denied_attempt_count,
		"consumed_timber_count": _repair_consumed_timber_count,
		"damage_owner_count": damage_state["owner_count"],
		"damage_hit_count": damage_state["hit_count"],
		"damage_repair_count": damage_state["repair_count"],
		"last_repair_attempt_evidence": (
			_last_repair_attempt_evidence.duplicate(true)
		),
		"successful_repair_evidence": (
			_successful_repair_evidence.duplicate(true)
		),
		"last_denied_repair_evidence": (
			_last_denied_repair_evidence.duplicate(true)
		),
		"manual_confirmation_required": true,
		"automatic_repair_count": 0,
	}


func attempt_docked_hull_repair() -> Dictionary:
	_repair_attempt_count += 1
	var captain_aboard_before := captain_aboard
	var ship_is_docked_before := is_docked
	var current_dock_id_before := current_dock_id
	var cargo_before: Array[String] = get_cargo_lots()
	var damage_before: Dictionary = get_damage_playtest_state()
	var repair_state_before: Dictionary = get_repair_playtest_state()
	var repair_success_count_before := _repair_success_count
	var denial_reasons: PackedStringArray = repair_state_before["denial_reasons"]
	if not bool(repair_state_before["available"]):
		_repair_denied_attempt_count += 1
		return _record_repair_attempt(
			false,
			"REPAIR DENIED · %s" % " · ".join(denial_reasons),
			denial_reasons,
			cargo_before,
			damage_before,
			repair_success_count_before,
			captain_aboard_before,
			ship_is_docked_before,
			current_dock_id_before,
		)

	var timber_slot := cargo_before.find(REPAIR_COST_LOT_NAME)
	if timber_slot < 0 or not remove_cargo_lot(REPAIR_COST_LOT_NAME):
		_repair_denied_attempt_count += 1
		return _record_repair_attempt(
			false,
			"REPAIR DENIED · TIMBER CARGO DID NOT CHANGE",
			PackedStringArray(["TIMBER CARGO DID NOT CHANGE"]),
			cargo_before,
			damage_before,
			repair_success_count_before,
			captain_aboard_before,
			ship_is_docked_before,
			current_dock_id_before,
		)

	var damage_repair: Dictionary = _damage_state.apply_fixed_repair()
	if not bool(damage_repair["success"]):
		var cargo_rollback_succeeded := restore_cargo_slot_from_storage(
			timber_slot,
			REPAIR_COST_LOT_NAME,
		)
		_repair_denied_attempt_count += 1
		return _record_repair_attempt(
			false,
			(
				"REPAIR DENIED · HULL DID NOT CHANGE · CARGO RESTORED"
				if cargo_rollback_succeeded
				else "REPAIR ERROR · CARGO ROLLBACK FAILED"
			),
			PackedStringArray(["HULL DID NOT CHANGE"]),
			cargo_before,
			damage_before,
			repair_success_count_before,
			captain_aboard_before,
			ship_is_docked_before,
			current_dock_id_before,
			cargo_rollback_succeeded,
		)

	_repair_success_count += 1
	_repair_consumed_timber_count += REPAIR_COST_LOT_COUNT
	return _record_repair_attempt(
		true,
		"REPAIRED HULL · +%d" % damage_repair["hull_restored"],
		PackedStringArray(),
		cargo_before,
		damage_before,
		repair_success_count_before,
		captain_aboard_before,
		ship_is_docked_before,
		current_dock_id_before,
	)


func _record_repair_attempt(
	success: bool,
	result: String,
	denial_reasons: PackedStringArray,
	cargo_before: Array[String],
	damage_before: Dictionary,
	repair_success_count_before: int,
	captain_aboard_before: bool,
	ship_is_docked_before: bool,
	current_dock_id_before: String,
	cargo_rollback_succeeded: bool = false,
) -> Dictionary:
	var cargo_after: Array[String] = get_cargo_lots()
	var damage_after: Dictionary = get_damage_playtest_state()
	var expected_cargo_after: Array[String] = cargo_before.duplicate()
	expected_cargo_after.erase(REPAIR_COST_LOT_NAME)
	var exactly_one_timber_removed := (
		cargo_before.count(REPAIR_COST_LOT_NAME)
			- cargo_after.count(REPAIR_COST_LOT_NAME)
			== REPAIR_COST_LOT_COUNT
	)
	var other_cargo_unchanged := (
		_get_non_timber_lots(cargo_before) == _get_non_timber_lots(cargo_after)
	)
	var no_state_change: bool = (
		cargo_before == cargo_after
		and damage_before["hull_current"] == damage_after["hull_current"]
		and damage_before["repair_count"] == damage_after["repair_count"]
		and damage_before["hit_count"] == damage_after["hit_count"]
	)
	var expected_hull_after := mini(
		int(damage_before["hull_max"]),
		int(damage_before["hull_current"])
			+ ShipDamageState.FIXED_REPAIR_AMOUNT,
	)
	var expected_hull_delta := (
		expected_hull_after - int(damage_before["hull_current"])
	)
	var evidence := {
		"action": "REPAIR_HULL",
		"result": result,
		"success": success,
		"attempt_number": _repair_attempt_count,
		"denial_reasons": denial_reasons,
		"captain_aboard_before": captain_aboard_before,
		"captain_aboard_after": captain_aboard,
		"captain_state_unchanged": captain_aboard_before == captain_aboard,
		"ship_is_docked_before": ship_is_docked_before,
		"ship_is_docked_after": is_docked,
		"current_dock_id_before": current_dock_id_before,
		"current_dock_id_after": current_dock_id,
		"dock_state_unchanged": (
			ship_is_docked_before == is_docked
			and current_dock_id_before == current_dock_id
		),
		"fixed_repair_amount": ShipDamageState.FIXED_REPAIR_AMOUNT,
		"cost_lot_name": REPAIR_COST_LOT_NAME,
		"cost_lot_count": REPAIR_COST_LOT_COUNT,
		"cargo_before": cargo_before,
		"cargo_after": cargo_after,
		"expected_cargo_after": expected_cargo_after,
		"cargo_matches_exact_cost": cargo_after == expected_cargo_after,
		"timber_before": cargo_before.count(REPAIR_COST_LOT_NAME),
		"timber_after": cargo_after.count(REPAIR_COST_LOT_NAME),
		"exactly_one_timber_removed": exactly_one_timber_removed,
		"other_cargo_unchanged": other_cargo_unchanged,
		"hull_before": damage_before["hull_current"],
		"hull_after": damage_after["hull_current"],
		"hull_delta": (
			int(damage_after["hull_current"])
			- int(damage_before["hull_current"])
		),
		"expected_hull_after": expected_hull_after,
		"expected_hull_delta": expected_hull_delta,
		"hull_matches_fixed_capped_repair": (
			int(damage_after["hull_current"]) == expected_hull_after
		),
		"hull_capped_at_max": (
			int(damage_after["hull_current"]) == int(damage_after["hull_max"])
		),
		"damage_owner_count_before": damage_before["owner_count"],
		"damage_owner_count_after": damage_after["owner_count"],
		"damage_owner_unchanged": (
			damage_before["owner_count"] == damage_after["owner_count"]
		),
		"reef_hit_count_before": damage_before["hit_count"],
		"reef_hit_count_after": damage_after["hit_count"],
		"reef_hit_state_unchanged": (
			damage_before["hit_count"] == damage_after["hit_count"]
			and damage_before["last_damage_event"]
				== damage_after["last_damage_event"]
		),
		"contact_latch_unchanged": (
			damage_before["contact_active"] == damage_after["contact_active"]
		),
		"cooldown_unchanged": is_equal_approx(
			float(damage_before["cooldown_remaining"]),
			float(damage_after["cooldown_remaining"]),
		),
		"damage_repair_count_before": damage_before["repair_count"],
		"damage_repair_count_after": damage_after["repair_count"],
		"repair_success_count_before": repair_success_count_before,
		"repair_success_count_after": _repair_success_count,
		"one_action_one_repair": (
			success
			and int(damage_after["repair_count"])
				== int(damage_before["repair_count"]) + 1
			and _repair_success_count == repair_success_count_before + 1
		),
		"cargo_rollback_succeeded": cargo_rollback_succeeded,
		"no_state_change": no_state_change,
		"denied_no_state_change": not success and no_state_change,
		"transaction_atomic": (
			(
				exactly_one_timber_removed
				and other_cargo_unchanged
				and cargo_after == expected_cargo_after
				and int(damage_after["hull_current"])
					== expected_hull_after
				and int(damage_after["hull_current"])
					- int(damage_before["hull_current"])
					== expected_hull_delta
			)
			if success
			else no_state_change
		),
		"manual_confirmation_required": true,
		"automatic_repair": false,
	}
	_last_repair_attempt_evidence = evidence.duplicate(true)
	if success:
		_successful_repair_evidence = evidence.duplicate(true)
	else:
		_last_denied_repair_evidence = evidence.duplicate(true)
	return evidence


func _get_non_timber_lots(cargo: Array[String]) -> Array[String]:
	var other_lots: Array[String] = []
	for lot_name in cargo:
		if lot_name != REPAIR_COST_LOT_NAME:
			other_lots.append(lot_name)
	return other_lots


func _get_cargo_slot_lot_counts() -> PackedInt32Array:
	var lot_counts := PackedInt32Array()
	lot_counts.resize(cargo_lots.size())
	lot_counts.fill(1)
	return lot_counts


func _sync_cargo_state() -> void:
	timber_lots = cargo_lots.count(TIMBER_LOT_NAME)
	_food_state.sync_food_units(get_food_units())
	_record_cargo_usage()
	queue_redraw()


func _record_cargo_usage() -> void:
	_max_used_slots_observed = maxi(_max_used_slots_observed, cargo_lots.size())
	_cargo_limit_never_exceeded = (
		_cargo_limit_never_exceeded and cargo_lots.size() <= CARGO_LIMIT
	)


func get_available_dock_id() -> String:
	for dock_id in DOCK_IDS:
		var metrics := get_dock_eligibility(dock_id)
		if metrics["eligible"]:
			return dock_id
	return ""


func get_dock_eligibility(dock_id: String) -> Dictionary:
	if not DOCK_DEFINITIONS.has(dock_id):
		return {}

	var definition: Dictionary = DOCK_DEFINITIONS[dock_id]
	var approach_position: Vector2 = definition["approach_position"]
	var approach_heading: Vector2 = definition["approach_heading"]
	var distance := global_position.distance_to(approach_position)
	var speed := absf(current_speed)
	var alignment := get_forward_direction().dot(approach_heading.normalized())
	var close_enough := distance <= DOCK_DISTANCE_THRESHOLD
	var slow_enough := speed <= DOCK_MAX_SPEED
	var aligned := alignment >= DOCK_MIN_ALIGNMENT
	var operating := controls_enabled and captain_aboard and not is_docked
	var rejection_reasons := PackedStringArray()
	if not operating:
		rejection_reasons.append("SHIP_NOT_UNDER_SAILING_CONTROL")
	if not close_enough:
		rejection_reasons.append("TOO_FAR")
	if not slow_enough:
		rejection_reasons.append("TOO_FAST")
	if not aligned:
		rejection_reasons.append("WRONG_HEADING")

	return {
		"dock_id": dock_id,
		"dock_name": definition["name"],
		"distance": distance,
		"speed": speed,
		"alignment": alignment,
		"heading_error_degrees": rad_to_deg(acos(clampf(alignment, -1.0, 1.0))),
		"distance_threshold": DOCK_DISTANCE_THRESHOLD,
		"max_speed": DOCK_MAX_SPEED,
		"min_alignment": DOCK_MIN_ALIGNMENT,
		"close_enough": close_enough,
		"slow_enough": slow_enough,
		"aligned": aligned,
		"operating": operating,
		"eligible": operating and close_enough and slow_enough and aligned,
		"rejection_reasons": rejection_reasons,
	}


func dock_at_available() -> String:
	var dock_id := get_available_dock_id()
	if dock_id.is_empty():
		return ""

	var definition: Dictionary = DOCK_DEFINITIONS[dock_id]
	global_position = definition["snap_position"]
	rotation = definition["snap_rotation"]
	current_speed = 0.0
	sailing_velocity = Vector2.ZERO
	controls_enabled = false
	is_docked = true
	current_dock_id = dock_id
	last_dock_id = dock_id
	at_damaged_dock = dock_id == "cove"
	_dock_exit_cleared = dock_id != "cove"
	_departure_input_armed = false
	last_collision_response = "DOCKED_%s" % dock_id.to_upper()
	queue_redraw()
	return dock_id


func get_current_dock_definition() -> Dictionary:
	if current_dock_id.is_empty() or not DOCK_DEFINITIONS.has(current_dock_id):
		return {}
	return (DOCK_DEFINITIONS[current_dock_id] as Dictionary).duplicate(true)


func get_dock_definition(dock_id: String) -> Dictionary:
	if not DOCK_DEFINITIONS.has(dock_id):
		return {}
	return (DOCK_DEFINITIONS[dock_id] as Dictionary).duplicate(true)


func get_dock_definitions() -> Array:
	var definitions := []
	for dock_id in DOCK_IDS:
		definitions.append((DOCK_DEFINITIONS[dock_id] as Dictionary).duplicate(true))
	return definitions


func _release_current_dock() -> void:
	if not is_docked or not captain_aboard:
		return

	var departing_dock_id := current_dock_id
	is_docked = false
	current_dock_id = ""
	controls_enabled = true
	current_speed = 0.0
	sailing_velocity = Vector2.ZERO
	if departing_dock_id == "cove":
		at_damaged_dock = true
		_dock_exit_cleared = false
	else:
		at_damaged_dock = false
		_dock_exit_cleared = true
	last_collision_response = "RELEASED_%s" % departing_dock_id.to_upper()
	queue_redraw()


func _physics_process(delta: float) -> void:
	var flash_was_active: bool = _damage_state.is_flash_active()
	_damage_state.update_timers(delta)
	if flash_was_active or _damage_state.is_flash_active():
		queue_redraw()

	if navigation_input_blocked:
		current_speed = 0.0
		sailing_velocity = Vector2.ZERO
		controls_enabled = false
		_departure_input_armed = false
		return

	if navigation_release_pending:
		current_speed = 0.0
		sailing_velocity = Vector2.ZERO
		controls_enabled = false
		_departure_input_armed = false
		if not _is_any_movement_key_pressed():
			navigation_release_pending = false
			controls_enabled = (
				_restore_controls_after_navigation_release
				and captain_aboard
				and not is_docked
			)
		return

	var throttle_pressed := (
		Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	)
	if is_docked:
		current_speed = 0.0
		sailing_velocity = Vector2.ZERO
		if captain_aboard:
			if not throttle_pressed:
				_departure_input_armed = true
			elif _departure_input_armed:
				_departure_input_armed = false
				_release_current_dock()
		return

	if not controls_enabled:
		return

	var brake_pressed := (
		Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	)
	var turn_input := float(
		Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
	) - float(
		Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
	)

	if _dock_exit_cleared:
		rotation = wrapf(rotation + turn_input * TURN_SPEED * delta, -PI, PI)
	else:
		# The ship must first move straight out of the damaged dock corridor.
		rotation = DOCK_ROTATION

	if throttle_pressed:
		current_speed = move_toward(current_speed, TOP_SPEED, ACCELERATION * delta)
	elif brake_pressed:
		current_speed = move_toward(current_speed, 0.0, BRAKE_DECELERATION * delta)
	else:
		current_speed = move_toward(current_speed, 0.0, COAST_DECELERATION * delta)

	sailing_velocity = get_forward_direction() * current_speed
	_move_with_sailing_limits(delta)


func _is_any_movement_key_pressed() -> bool:
	return (
		Input.is_key_pressed(KEY_W)
		or Input.is_key_pressed(KEY_A)
		or Input.is_key_pressed(KEY_S)
		or Input.is_key_pressed(KEY_D)
		or Input.is_key_pressed(KEY_UP)
		or Input.is_key_pressed(KEY_LEFT)
		or Input.is_key_pressed(KEY_DOWN)
		or Input.is_key_pressed(KEY_RIGHT)
	)


func _move_with_sailing_limits(delta: float) -> void:
	if sailing_velocity.is_zero_approx() or _sea_bounds.size.is_zero_approx():
		return

	var movement_start := global_position
	var proposed_position := global_position + sailing_velocity * delta
	var minimum := _sea_bounds.position + Vector2.ONE * HULL_CLEARANCE
	var maximum := _sea_bounds.end - Vector2.ONE * HULL_CLEARANCE
	var bounded_position := proposed_position.clamp(minimum, maximum)
	if not bounded_position.is_equal_approx(proposed_position):
		global_position = bounded_position
		var edge_move_distance := movement_start.distance_to(global_position)
		_record_actual_sailing_movement(edge_move_distance)
		_update_reef_contact_after_movement(
			movement_start,
			edge_move_distance,
		)
		_stop_at_land("SEA_EDGE_STOP")
		return

	if _collides_with_reef(proposed_position):
		_handle_reef_collision()
		return

	var island_clearance := _island_radius + HULL_CLEARANCE
	var island_offset := proposed_position - _island_center
	if island_offset.length() < island_clearance:
		var safe_direction := island_offset.normalized()
		if safe_direction.is_zero_approx():
			safe_direction = -get_forward_direction()
		global_position = _island_center + safe_direction * island_clearance
		var island_move_distance := movement_start.distance_to(global_position)
		_record_actual_sailing_movement(island_move_distance)
		_update_reef_contact_after_movement(
			movement_start,
			island_move_distance,
		)
		_stop_at_land("ISLAND_STOP")
		return

	if _collides_with_port_land(proposed_position):
		_stop_at_land("PORT_STOP")
		return

	if (
		_collides_with_cove_shore(proposed_position)
		and not _is_in_damaged_dock_exit(proposed_position)
	):
		_stop_at_land("COVE_SHORE_STOP")
		return

	global_position = proposed_position
	var actual_move_distance := movement_start.distance_to(global_position)
	_record_actual_sailing_movement(actual_move_distance)
	_update_reef_contact_after_movement(
		movement_start,
		actual_move_distance,
	)
	_update_dock_exit_state()
	last_collision_response = "NONE"


func _record_actual_sailing_movement(actual_distance: float) -> void:
	if actual_distance <= 0.0:
		return
	var cargo_at_movement_start := get_cargo_lots()
	var food_units_before := get_food_units()
	var zero_food_distance_before: float = (
		_food_state.get_playtest_state(food_units_before)[
			"zero_food_sailing_distance"
		]
	)
	var due_use_count: int = _food_state.record_sailing_movement(
		actual_distance,
		food_units_before,
	)
	if food_units_before <= 0:
		_food_state.record_zero_food_movement(
			actual_distance,
			cargo_at_movement_start,
			get_cargo_lots(),
			controls_enabled,
			captain_aboard,
		)
		return

	for use_index in range(due_use_count):
		var cargo_before_use := get_cargo_lots()
		if not remove_cargo_lot(FOOD_LOT_NAME):
			_food_state.record_failed_food_use(cargo_before_use)
			break
		_food_state.record_food_use(
			cargo_before_use,
			get_cargo_lots(),
			actual_distance,
			due_use_count,
			use_index + 1,
		)

	var food_state_after: Dictionary = get_food_playtest_state()
	var new_zero_food_distance := float(
		food_state_after["zero_food_sailing_distance"]
	) - zero_food_distance_before
	if new_zero_food_distance > 0.0 and get_food_units() <= 0:
		var cargo_after_food_use := get_cargo_lots()
		_food_state.record_zero_food_movement(
			new_zero_food_distance,
			cargo_after_food_use,
			cargo_after_food_use,
			controls_enabled,
			captain_aboard,
		)


func _stop_at_land(response: String) -> void:
	current_speed = 0.0
	sailing_velocity = Vector2.ZERO
	last_collision_response = response


func _update_dock_exit_state() -> void:
	var outward_separation := global_position.y - DOCK_POSITION.y
	if at_damaged_dock and outward_separation > DOCK_DEPARTURE_DISTANCE:
		has_departed_dock = true
		at_damaged_dock = false
		queue_redraw()

	if not _dock_exit_cleared and global_position.y >= DOCK_EXIT_CLEAR_Y:
		_dock_exit_cleared = true


func _is_in_damaged_dock_exit(proposed_position: Vector2) -> bool:
	return (
		not _dock_exit_cleared
		and absf(proposed_position.x - DOCK_POSITION.x) <= DOCK_EXIT_HALF_WIDTH
		and proposed_position.y >= DOCK_POSITION.y
		and proposed_position.y <= DOCK_EXIT_CLEAR_Y + HULL_CLEARANCE
	)


func _collides_with_port_land(proposed_position: Vector2) -> bool:
	if not _port_land_rect.has_area():
		return false
	var closest_point := proposed_position.clamp(
		_port_land_rect.position,
		_port_land_rect.end,
	)
	return (
		_port_land_rect.has_point(proposed_position)
		or proposed_position.distance_to(closest_point) < HULL_CLEARANCE
	)


func _collides_with_reef(proposed_position: Vector2) -> bool:
	if _reef_radius <= 0.0:
		return false
	return (
		proposed_position.distance_to(_reef_center)
		< _reef_radius + HULL_CLEARANCE
	)


func _handle_reef_collision() -> void:
	var food_state: Dictionary = get_food_playtest_state()
	var damage_applied: bool = _damage_state.try_reef_hit(
		get_cargo_lots(),
		float(food_state["progress_distance"]),
		get_food_units(),
	)
	if damage_applied:
		damage_impact_sound.play()
		_damage_state.record_sound_play(
			damage_impact_sound.stream.get_class(),
			ShipDamageState.IMPACT_SOUND_DURATION,
		)
	_stop_at_land(ShipDamageState.REEF_COLLISION_RESPONSE)
	queue_redraw()


func _update_reef_contact_after_movement(
		movement_start: Vector2,
		actual_distance: float,
) -> void:
	var reef_clearance := _reef_radius + HULL_CLEARANCE
	_damage_state.clear_contact_after_movement_away(
		actual_distance,
		movement_start.distance_to(_reef_center),
		global_position.distance_to(_reef_center),
		reef_clearance,
	)


func _collides_with_cove_shore(proposed_position: Vector2) -> bool:
	if _cove_shoreline.size() < 3:
		return false
	if Geometry2D.is_point_in_polygon(proposed_position, _cove_shoreline):
		return true

	for index in range(_cove_shoreline.size()):
		var segment_start := _cove_shoreline[index]
		var segment_end := _cove_shoreline[(index + 1) % _cove_shoreline.size()]
		var closest_point := Geometry2D.get_closest_point_to_segment(
			proposed_position,
			segment_start,
			segment_end,
		)
		if proposed_position.distance_to(closest_point) < HULL_CLEARANCE:
			return true

	return false


func get_playtest_state() -> Dictionary:
	var eligibility := {}
	for dock_id in DOCK_IDS:
		eligibility[dock_id] = get_dock_eligibility(dock_id)
	var current_definition := get_current_dock_definition()
	var food_state: Dictionary = get_food_playtest_state()
	var damage_state: Dictionary = get_damage_playtest_state()
	var repair_state: Dictionary = get_repair_playtest_state()
	var fixed_pose := false
	if not current_definition.is_empty():
		fixed_pose = (
			global_position.is_equal_approx(current_definition["snap_position"])
			and is_equal_approx(rotation, float(current_definition["snap_rotation"]))
			and is_zero_approx(current_speed)
			and sailing_velocity.is_zero_approx()
		)

	return {
		"position": global_position,
		"rotation_radians": rotation,
		"rotation_degrees": rad_to_deg(rotation),
		"heading": get_forward_direction(),
		"current_speed": current_speed,
		"velocity": sailing_velocity,
		"acceleration": ACCELERATION,
		"coast_deceleration": COAST_DECELERATION,
		"brake_deceleration": BRAKE_DECELERATION,
		"top_speed": TOP_SPEED,
		"turn_speed": TURN_SPEED,
		"controls_enabled": controls_enabled,
		"captain_aboard": captain_aboard,
		"has_departed_dock": has_departed_dock,
		"at_damaged_dock": at_damaged_dock,
		"leave_allowed": can_leave_at_damaged_dock(),
		"steering_locked": not _dock_exit_cleared,
		"dock_exit_cleared": _dock_exit_cleared,
		"dock_exit_progress": maxf(0.0, global_position.y - DOCK_POSITION.y),
		"dock_exit_clear_y": DOCK_EXIT_CLEAR_Y,
		"at_cove_entrance": is_at_cove_entrance(),
		"damaged_dock_position": DOCK_POSITION,
		"cove_entrance_position": COVE_ENTRANCE_POSITION,
		"cove_entrance_radius": COVE_ENTRANCE_RADIUS,
		"sea_bounds": _sea_bounds,
		"island_center": _island_center,
		"island_radius": _island_radius,
		"reef_center": _reef_center,
		"reef_radius": _reef_radius,
		"reef_collision_clearance": _reef_radius + HULL_CLEARANCE,
		"port_land_rect": _port_land_rect,
		"cove_shoreline": _cove_shoreline,
		"collision_radius": HULL_CLEARANCE,
		"hull_clearance": HULL_CLEARANCE,
		"last_collision_response": last_collision_response,
		"dock_count": DOCK_IDS.size(),
		"dock_ids": DOCK_IDS.duplicate(),
		"dock_names": [
			DOCK_DEFINITIONS["cove"]["name"],
			DOCK_DEFINITIONS["island"]["name"],
			DOCK_DEFINITIONS["port"]["name"],
		],
		"dock_definitions": get_dock_definitions(),
		"dock_thresholds": {
			"distance": DOCK_DISTANCE_THRESHOLD,
			"max_speed": DOCK_MAX_SPEED,
			"min_alignment": DOCK_MIN_ALIGNMENT,
		},
		"dock_eligibility": eligibility,
		"available_dock_id": get_available_dock_id(),
		"is_docked": is_docked,
		"current_dock_id": current_dock_id,
		"last_dock_id": last_dock_id,
		"fixed_dock_pose": fixed_pose,
		"departure_input_armed": _departure_input_armed,
		"navigation_input_blocked": navigation_input_blocked,
		"navigation_release_pending": navigation_release_pending,
		"cargo_limit": CARGO_LIMIT,
		"cargo_used_slots": cargo_lots.size(),
		"cargo_free_slots": CARGO_LIMIT - cargo_lots.size(),
		"cargo_lots": get_cargo_lots(),
		"starting_cargo_lots": STARTING_CARGO_LOTS.duplicate(),
		"starting_cargo_used_slots": _starting_used_slots,
		"all_but_one_slot_full_at_start": (
			_starting_used_slots == CARGO_LIMIT - 1
		),
		"each_cargo_lot_uses_one_slot": true,
		"cargo_slot_lot_counts": _get_cargo_slot_lot_counts(),
		"max_used_slots_observed": _max_used_slots_observed,
		"cargo_limit_never_exceeded": _cargo_limit_never_exceeded,
		"timber_lots": timber_lots,
		"has_salvaged_timber": timber_lots > 0,
		"food_state_owner_count": food_state["owner_count"],
		"food_lot_name": FOOD_LOT_NAME,
		"food_use_distance": FOOD_USE_DISTANCE,
		"food_units": food_state["food_units"],
		"food_source_cargo_count": get_food_units(),
		"food_progress_distance": food_state["progress_distance"],
		"food_distance_to_next_use": food_state["distance_to_next_use"],
		"food_total_sailing_distance": food_state["total_sailing_distance"],
		"food_total_units_used": food_state["total_units_used"],
		"food_last_use_evidence": food_state["last_use_evidence"],
		"food_zero_sailing_distance": (
			food_state["zero_food_sailing_distance"]
		),
		"food_last_zero_movement_evidence": (
			food_state["last_zero_food_movement_evidence"]
		),
		"food_status": food_state["status"],
		"food_low_warning": food_state["low_food_warning"],
		"food_no_warning": food_state["no_food_warning"],
		"food_progress_debt_while_empty": (
			food_state["progress_debt_while_empty"]
		),
		"food_sailing_continues_without_food": (
			food_state["sailing_continues_without_food"]
		),
		"food_failed_use_count": food_state["failed_use_count"],
		"ship_food": food_state,
		"damage_state_owner_count": damage_state["owner_count"],
		"hull_current": damage_state["hull_current"],
		"hull_max": damage_state["hull_max"],
		"hull_start": damage_state["hull_start"],
		"reef_hit_damage": damage_state["reef_hit_damage"],
		"reef_hit_count": damage_state["hit_count"],
		"last_damage_event": damage_state["last_damage_event"],
		"reef_contact_active": damage_state["contact_active"],
		"reef_contact_clear_count": damage_state["contact_clear_count"],
		"reef_repeated_contact_blocked_count": (
			damage_state["repeated_contact_blocked_count"]
		),
		"reef_cooldown_remaining": damage_state["cooldown_remaining"],
		"reef_cooldown_duration": damage_state["cooldown_duration"],
		"damage_flash_active": damage_state["flash_active"],
		"damage_flash_count": damage_state["flash_count"],
		"damage_flash_duration": damage_state["flash_duration"],
		"damage_flash_remaining": damage_state["flash_remaining"],
		"damage_sound_player_count": 1 if damage_impact_sound != null else 0,
		"damage_sound_stream_present": damage_impact_sound.stream != null,
		"damage_sound_stream_kind": damage_state["sound_stream_kind"],
		"damage_sound_play_count": damage_state["sound_play_count"],
		"damage_sound_duration": damage_state["sound_duration"],
		"ship_damage": damage_state,
		"repair_system_count": repair_state["system_count"],
		"repair_available": repair_state["available"],
		"repair_denial_reasons": repair_state["denial_reasons"],
		"repair_status_text": repair_state["status_text"],
		"repair_fixed_amount": repair_state["fixed_repair_amount"],
		"repair_cost_lot_name": repair_state["cost_lot_name"],
		"repair_cost_lot_count": repair_state["cost_lot_count"],
		"repair_preview_text": repair_state["preview_text"],
		"repair_hull_before_preview": repair_state["hull_before_preview"],
		"repair_hull_after_preview": repair_state["hull_after_preview"],
		"repair_hull_gain_preview": repair_state["hull_gain_preview"],
		"repair_attempt_count": repair_state["attempt_count"],
		"repair_success_count": repair_state["success_count"],
		"repair_denied_attempt_count": repair_state["denied_attempt_count"],
		"repair_consumed_timber_count": repair_state["consumed_timber_count"],
		"repair_last_attempt_evidence": (
			repair_state["last_repair_attempt_evidence"]
		),
		"repair_successful_evidence": repair_state["successful_repair_evidence"],
		"repair_last_denied_evidence": (
			repair_state["last_denied_repair_evidence"]
		),
		"ship_repair": repair_state,
		"restore_controls_after_navigation_release": (
			_restore_controls_after_navigation_release
		),
		"controls": {
			"forward": "W_OR_UP",
			"turn_left": "A_OR_LEFT",
			"turn_right": "D_OR_RIGHT",
			"brake": "S_OR_DOWN",
			"dock_or_ashore": "E",
			"salvage": "E",
			"repair": "R",
		},
	}


func _draw() -> void:
	# The one ship, viewed from above.
	draw_ellipse(Vector2(5, 8), 48.0, 99.0, Color("#12323c66"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-31, -86), Vector2(31, -86), Vector2(47, 35),
		Vector2(0, 94), Vector2(-47, 35),
	]), Color("#493323"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-23, -72), Vector2(23, -72), Vector2(34, 31),
		Vector2(0, 77), Vector2(-34, 31),
	]), Color("#b27a47"))

	# Deck details make the ship direction and standing position clear.
	draw_line(Vector2(-25, -38), Vector2(25, -38), Color("#6b452c"), 5.0)
	draw_line(Vector2(-30, 18), Vector2(30, 18), Color("#6b452c"), 5.0)
	draw_circle(Vector2(0, -12), 8.0, Color("#342b29"))
	draw_line(Vector2(0, -12), Vector2(18, -47), Color("#e8d2a2"), 4.0)
	# Each cargo lot has one fixed deck position. Timber keeps its Phase 10 stack.
	for slot_index in range(cargo_lots.size()):
		var lot_name := cargo_lots[slot_index]
		var cargo_y := 28.0 + float(slot_index) * 15.0
		if lot_name == TIMBER_LOT_NAME:
			for timber_offset in [-4.0, 4.0]:
				draw_line(
					Vector2(-25.0, cargo_y + timber_offset),
					Vector2(25.0, cargo_y + timber_offset),
					Color("#d69b5d"),
					7.0,
				)
		else:
			var cargo_color := Color("#d9c27a")
			if lot_name.contains("MEDICINE"):
				cargo_color = Color("#b75b5b")
			elif lot_name.contains("FOOD"):
				cargo_color = Color("#d7b45a")
			elif lot_name.contains("SPICE"):
				cargo_color = Color("#c77b3d")
			draw_rect(
				Rect2(Vector2(-24.0, cargo_y - 6.0), Vector2(48.0, 12.0)),
				cargo_color,
			)
			draw_rect(
				Rect2(Vector2(-24.0, cargo_y - 6.0), Vector2(48.0, 12.0)),
				Color("#493323"),
				false,
				2.0,
			)

	# The gangplank is visible when the ship is at the damaged cove dock.
	if at_damaged_dock:
		draw_line(Vector2(176, 24), Vector2(39, 24), Color("#493323"), 18.0)
		draw_line(Vector2(176, 24), Vector2(39, 24), Color("#b27a47"), 11.0)

	# A reef hit gives one short, high-contrast flash on the whole ship.
	if _damage_state.is_flash_active():
		draw_colored_polygon(PackedVector2Array([
			Vector2(-35, -91), Vector2(35, -91), Vector2(52, 39),
			Vector2(0, 101), Vector2(-52, 39),
		]), Color("#fff2d0b8"))
		draw_arc(Vector2.ZERO, 104.0, 0.0, TAU, 40, Color("#ff4b3ee8"), 9.0)
