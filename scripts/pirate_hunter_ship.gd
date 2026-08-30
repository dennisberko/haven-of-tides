class_name PirateHunterShip
extends "res://scripts/inspectable_target_ship.gd"

const HEAT_THRESHOLD := 2
const WARNING_DURATION := 1.5
const SPAWN_DISTANCE := 640.0
const CHASE_SPEED := 210.0
const ATTACK_RANGE := 260.0
const ATTACK_COOLDOWN := 2.4
const ESCAPE_DISTANCE := 860.0
const SEA_MARGIN := 120.0

var _warning_active := false
var _encounter_active := false
var _encounter_resolved := false
var _outcome := "ABSENT"
var _warning_remaining := 0.0
var _attack_cooldown_remaining := 0.0
var _active_time := 0.0
var _warning_count := 0
var _spawn_count := 0
var _chase_frame_count := 0
var _attack_request_count := 0
var _attack_hit_count := 0
var _escape_count := 0
var _defeat_count := 0
var _event_sequence := 0
var _warning_sequence := 0
var _spawn_sequence := 0
var _first_chase_sequence := 0
var _first_attack_sequence := 0
var _resolution_sequence := 0
var _distance_at_spawn := -1.0
var _closest_chase_distance := INF
var _last_distance := INF
var _total_chase_distance := 0.0
var _heat_at_warning := -1
var _heat_at_spawn := -1
var _heat_at_resolution := -1
var _last_below_threshold_evidence: Dictionary = {}
var _last_attack_evidence: Dictionary = {}
var _last_resolution_evidence: Dictionary = {}
var _paused_update_count := 0
var _paused_position := Vector2.ZERO
var _pause_position_recorded := false
var _pause_position_held := true
var _modal_paused_update_count := 0
var _modal_paused_position := Vector2.ZERO
var _modal_pause_position_recorded := false
var _modal_pause_position_held := true


func _ready() -> void:
	super._ready()
	route_enabled = false
	hide()


func _physics_process(delta: float) -> void:
	# Main owns encounter movement so that heat and the player ship have one
	# ordered update path. The inherited process still owns hit feedback.
	super._physics_process(delta)


func update_player_ship_state(
	player_ship_position: Vector2,
	player_aboard: bool,
	chart_closed: bool,
) -> void:
	super.update_player_ship_state(
		player_ship_position,
		player_aboard,
		chart_closed,
	)
	if not _encounter_active:
		hide()
		_inspection_available = false
		_boarding_prompt_available = false


func can_receive_broadside_damage(attack_choice: String) -> bool:
	return (
		_encounter_active
		and visible
		and super.can_receive_broadside_damage(attack_choice)
	)


func is_boarding_condition_ready() -> bool:
	# Phase 31 uses the existing naval fight. It does not add a hunter prize or
	# boarding flow.
	return false


func update_encounter(
	delta: float,
	world_heat: int,
	player_position: Vector2,
	player_aboard: bool,
	player_ship_operating: bool,
	modal_pause_active: bool,
	sea_bounds: Rect2,
) -> bool:
	if delta <= 0.0:
		return false
	if world_heat < HEAT_THRESHOLD:
		if _warning_active or _encounter_active:
			_warning_active = false
			_encounter_active = false
			_encounter_resolved = true
			_outcome = "HEAT COOLED"
			hide()
		_last_below_threshold_evidence = {
			"observed": true,
			"world_heat": world_heat,
			"heat_threshold": HEAT_THRESHOLD,
			"warning_active": _warning_active,
			"encounter_active": _encounter_active,
			"visual_visible": visible,
			"spawn_count": _spawn_count,
			"absent": (
				not _warning_active
				and not _encounter_active
				and not visible
			),
		}
		return false
	if _encounter_resolved:
		return false
	if not player_aboard or not player_ship_operating:
		if _warning_active or _encounter_active:
			_paused_update_count += 1
			if _pause_position_recorded:
				_pause_position_held = (
					_pause_position_held
					and global_position.is_equal_approx(_paused_position)
				)
			else:
				_paused_position = global_position
				_pause_position_recorded = true
			if modal_pause_active:
				_modal_paused_update_count += 1
				if _modal_pause_position_recorded:
					_modal_pause_position_held = (
						_modal_pause_position_held
						and global_position.is_equal_approx(
							_modal_paused_position
						)
					)
				else:
					_modal_paused_position = global_position
					_modal_pause_position_recorded = true
			else:
				_modal_pause_position_recorded = false
		return false
	_pause_position_recorded = false
	_modal_pause_position_recorded = false
	if not _warning_active and not _encounter_active:
		_begin_warning(world_heat)
		return false
	if _warning_active:
		_warning_remaining = maxf(0.0, _warning_remaining - delta)
		if is_zero_approx(_warning_remaining):
			_spawn(player_position, world_heat, sea_bounds)
		return false

	_active_time += delta
	_attack_cooldown_remaining = maxf(
		0.0,
		_attack_cooldown_remaining - delta,
	)
	var hull_state: Dictionary = get_hull_state()
	if bool(hull_state["disabled"]):
		_resolve("DEFEATED", world_heat)
		return false

	var distance_before := global_position.distance_to(player_position)
	var chase_direction := global_position.direction_to(player_position)
	var move_distance := minf(
		minf(CHASE_SPEED, get_current_speed()) * delta,
		distance_before,
	)
	if not chase_direction.is_zero_approx() and move_distance > 0.0:
		global_position += chase_direction * move_distance
		rotation = chase_direction.angle()
		_chase_frame_count += 1
		_total_chase_distance += move_distance
		if _first_chase_sequence == 0:
			_first_chase_sequence = _next_sequence()
		queue_redraw()
	var distance_after := global_position.distance_to(player_position)
	_closest_chase_distance = minf(_closest_chase_distance, distance_after)
	_last_distance = distance_after

	if _active_time >= 1.0 and distance_after >= ESCAPE_DISTANCE:
		_resolve("ESCAPED", world_heat)
		return false
	if (
		distance_after <= ATTACK_RANGE
		and is_zero_approx(_attack_cooldown_remaining)
	):
		_attack_cooldown_remaining = ATTACK_COOLDOWN
		_attack_request_count += 1
		if _first_attack_sequence == 0:
			_first_attack_sequence = _next_sequence()
		return true
	return false


func record_attack_result(evidence: Dictionary) -> void:
	_last_attack_evidence = evidence.duplicate(true)
	if bool(evidence.get("success", false)):
		_attack_hit_count += 1


func get_warning_text() -> String:
	if _warning_active:
		return "HUNTER WARNING · NAVAL SAILS ARE CLOSING · PREPARE TO FIGHT OR RUN"
	if _encounter_active:
		return "PIRATE HUNTER · CHASING · FIGHT OR OPEN THE DISTANCE TO %.0f" % (
			ESCAPE_DISTANCE
		)
	if _outcome == "ESCAPED":
		return "ESCAPE SUCCESS · HUNTER PURSUIT BROKEN · HEAT REMAINS"
	if _outcome == "DEFEATED":
		return "HUNTER DEFEATED · SEA ROUTE CLEAR · HEAT REMAINS"
	if _outcome == "HEAT COOLED":
		return "HUNTER STOOD DOWN · HEAT BELOW %d · SEA ROUTE CLEAR" % (
			HEAT_THRESHOLD
		)
	return ""


func is_warning_visible() -> bool:
	return _warning_active


func is_encounter_status_visible() -> bool:
	return _warning_active or _encounter_active or _encounter_resolved


func get_hunter_playtest_state() -> Dictionary:
	var inherited_state := super.get_playtest_state()
	return {
		"system_count": 1,
		"hunter_ship_count": 1,
		"target_id": target_id,
		"heat_threshold": HEAT_THRESHOLD,
		"warning_duration": WARNING_DURATION,
		"spawn_distance": SPAWN_DISTANCE,
		"chase_speed": CHASE_SPEED,
		"effective_chase_speed": minf(CHASE_SPEED, get_current_speed()),
		"attack_range": ATTACK_RANGE,
		"attack_cooldown": ATTACK_COOLDOWN,
		"escape_distance": ESCAPE_DISTANCE,
		"warning_active": _warning_active,
		"encounter_active": _encounter_active,
		"encounter_resolved": _encounter_resolved,
		"outcome": _outcome,
		"visual_visible": visible,
		"warning_remaining": _warning_remaining,
		"attack_cooldown_remaining": _attack_cooldown_remaining,
		"warning_count": _warning_count,
		"spawn_count": _spawn_count,
		"active_encounter_count": 1 if _encounter_active else 0,
		"chase_frame_count": _chase_frame_count,
		"attack_request_count": _attack_request_count,
		"attack_hit_count": _attack_hit_count,
		"escape_count": _escape_count,
		"defeat_count": _defeat_count,
		"warning_sequence": _warning_sequence,
		"spawn_sequence": _spawn_sequence,
		"first_chase_sequence": _first_chase_sequence,
		"first_attack_sequence": _first_attack_sequence,
		"resolution_sequence": _resolution_sequence,
		"warning_precedes_spawn": (
			_spawn_sequence == 0
			or (
				_warning_sequence > 0
				and _warning_sequence < _spawn_sequence
			)
		),
		"one_encounter_maximum": _spawn_count <= 1,
		"distance_at_spawn": _distance_at_spawn,
		"closest_chase_distance": _closest_chase_distance,
		"last_distance": _last_distance,
		"total_chase_distance": _total_chase_distance,
		"chase_closed_distance": (
			_chase_frame_count > 0
			and _closest_chase_distance < _distance_at_spawn
		),
		"heat_at_warning": _heat_at_warning,
		"heat_at_spawn": _heat_at_spawn,
		"heat_at_resolution": _heat_at_resolution,
		"heat_unchanged_by_warning_and_spawn": (
			_heat_at_spawn < 0 or _heat_at_spawn == _heat_at_warning
		),
		"heat_persisted_through_resolution": (
			_heat_at_resolution < 0 or _heat_at_resolution == _heat_at_spawn
		),
		"below_threshold_evidence": (
			_last_below_threshold_evidence.duplicate(true)
		),
		"last_attack_evidence": _last_attack_evidence.duplicate(true),
		"last_resolution_evidence": (
			_last_resolution_evidence.duplicate(true)
		),
		"paused_update_count": _paused_update_count,
		"pause_position_held": _pause_position_held,
		"modal_paused_update_count": _modal_paused_update_count,
		"modal_pause_position_held": _modal_pause_position_held,
		"modal_pause_evidence": {
			"update_count": _modal_paused_update_count,
			"held_position": _modal_paused_position,
			"position_held": _modal_pause_position_held,
		},
		"inspectable_target_state": inherited_state,
		"uses_existing_inspection_system": true,
		"uses_existing_broadside_system": true,
		"uses_existing_ammunition_system": true,
		"uses_existing_sail_damage_speed": true,
		"new_player_combat_action_count": 0,
		"hunter_fleet_ship_count": 0,
		"wanted_level_system_count": 0,
		"nation_rule_system_count": 0,
		"faction_rule_system_count": 0,
		"port_service_refusal_count": 0,
		"crew_injury_system_count": 1,
	}


func _begin_warning(world_heat: int) -> void:
	_warning_active = true
	_outcome = "WARNING"
	_warning_remaining = WARNING_DURATION
	_warning_count += 1
	_heat_at_warning = world_heat
	_warning_sequence = _next_sequence()
	hide()


func _spawn(
	player_position: Vector2,
	world_heat: int,
	sea_bounds: Rect2,
) -> void:
	_warning_active = false
	_encounter_active = true
	_outcome = "CHASING"
	_spawn_count += 1
	_heat_at_spawn = world_heat
	global_position = _choose_spawn_position(player_position, sea_bounds)
	_distance_at_spawn = global_position.distance_to(player_position)
	_closest_chase_distance = _distance_at_spawn
	_last_distance = _distance_at_spawn
	_spawn_sequence = _next_sequence()
	queue_redraw()


func _resolve(result: String, world_heat: int) -> void:
	_encounter_active = false
	_encounter_resolved = true
	_outcome = result
	_heat_at_resolution = world_heat
	_resolution_sequence = _next_sequence()
	if result == "ESCAPED":
		_escape_count += 1
		hide()
	else:
		_defeat_count += 1
	_last_resolution_evidence = {
		"outcome": result,
		"world_heat": world_heat,
		"distance_to_player": _last_distance,
		"hunter_hull": get_hull_state()["hull_current"],
		"warning_count": _warning_count,
		"spawn_count": _spawn_count,
		"attack_hit_count": _attack_hit_count,
		"resolution_sequence": _resolution_sequence,
		"stable": _encounter_resolved and not _encounter_active,
	}


func _choose_spawn_position(
	player_position: Vector2,
	sea_bounds: Rect2,
) -> Vector2:
	var minimum := sea_bounds.position + Vector2.ONE * SEA_MARGIN
	var maximum := sea_bounds.end - Vector2.ONE * SEA_MARGIN
	var candidates: Array[Vector2] = [
		player_position + Vector2(SPAWN_DISTANCE, 0.0),
		player_position + Vector2(-SPAWN_DISTANCE, 0.0),
		player_position + Vector2(0.0, SPAWN_DISTANCE),
		player_position + Vector2(0.0, -SPAWN_DISTANCE),
	]
	var chosen: Vector2 = player_position
	var chosen_distance := -1.0
	for candidate in candidates:
		var bounded: Vector2 = candidate.clamp(minimum, maximum)
		var distance := bounded.distance_to(player_position)
		if distance > chosen_distance:
			chosen = bounded
			chosen_distance = distance
	return chosen


func _next_sequence() -> int:
	_event_sequence += 1
	return _event_sequence
