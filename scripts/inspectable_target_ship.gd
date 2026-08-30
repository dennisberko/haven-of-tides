class_name InspectableTargetShip
extends Node2D

const VISIBILITY_RANGE := 900.0
const INSPECTION_RANGE := 250.0
const HULL_MAX := 100
const SAIL_MAX := 100
const ATTACK_HULL := "HULL"
const ATTACK_SAILS := "SAILS"
const ATTACK_CHOICES := [ATTACK_HULL, ATTACK_SAILS]
const HIT_FEEDBACK_DURATION := 0.55
const FULL_SAIL_SPEED := 320.0
const DAMAGED_SAIL_SPEED_75 := 240.0
const DAMAGED_SAIL_SPEED_50 := 170.0
const DAMAGED_SAIL_SPEED_25 := 100.0
const MINIMUM_SAIL_SPEED := 40.0
const CATCH_RANGE := 175.0
const CATCH_MINIMUM_CLOSING_DISTANCE := 25.0
const CATCH_MINIMUM_PLAYER_SAILING_DISTANCE := 40.0
const BOARDING_HULL_WEAK_THRESHOLD := 50
const BOARDING_SAIL_WEAK_THRESHOLD := 50
const BOARDING_ALONGSIDE_RANGE := 145.0

@export var target_id := "target_ship"
@export var display_name := "MERCHANT SHIP"
@export var owner_name := "UNKNOWN OWNER"
@export var flag_name := "UNKNOWN FLAG"
@export var ship_class := "UNKNOWN CLASS"
@export var likely_speed := "UNKNOWN SPEED"
@export var general_cargo_type := "GENERAL GOODS"
@export_enum("LOW", "MEDIUM", "HIGH") var threat_estimate := "LOW"
@export var peaceful := true
@export_range(0, 9, 1) var estimated_heat_cost := 0
@export var hull_color := Color("#b27a47")
@export var sail_color := Color("#f3dfb0")
@export var flag_color := Color("#d7b45a")
@export_group("Authored pursuit route")
@export var route_enabled := false
@export var route_start := Vector2.ZERO
@export var route_end := Vector2.ZERO

var _player_ship_position := Vector2.ZERO
var _previous_player_ship_position := Vector2.ZERO
var _has_player_ship_position := false
var _player_aboard := false
var _chart_closed := true
var _distance_to_player_ship := INF
var _inspection_available := false
var _hull_current := HULL_MAX
var _sail_current := SAIL_MAX
var _disabled := false
var _hit_feedback_remaining := 0.0
var _hit_count := 0
var _hull_hit_count := 0
var _sail_hit_count := 0
var _last_hit_side := "NONE"
var _last_hit_component := "NONE"
var _last_hit_damage := 0
var _last_hit_evidence: Dictionary = {}
var _route_toward_end := true
var _route_distance_travelled := 0.0
var _last_route_move_distance := 0.0
var _last_route_velocity := Vector2.ZERO
var _catch_start_distance := -1.0
var _closest_distance_after_sail_damage := INF
var _player_sailing_distance_after_sail_damage := 0.0
var _caught_after_sail_damage := false
var _catch_evidence: Dictionary = {}
var _boarding_prompt_available := false
var _boarding_active := false
var _boarding_begin_count := 0
var _boarding_finish_count := 0
var _boarding_victory_resolved := false
var _boarding_victory_resolution_count := 0
var _repeat_boarding_begin_blocked_count := 0
var _boarding_far_denial_observed := false
var _boarding_far_denial_count := 0
var _boarding_far_denial_distance := -1.0
var _boarding_anchor_position := Vector2.ZERO
var _boarding_anchor_rotation := 0.0
var _boarding_condition_at_begin: Dictionary = {}
var _last_boarding_begin_evidence: Dictionary = {}
var _last_boarding_finish_evidence: Dictionary = {}
var _last_boarding_victory_resolution_evidence: Dictionary = {}
var _last_repeat_boarding_block_evidence: Dictionary = {}


func _ready() -> void:
	if route_enabled and route_start.is_equal_approx(route_end):
		route_enabled = false
	if route_enabled:
		global_position = route_start
		_face_route_target()
	hide()
	queue_redraw()


func _physics_process(delta: float) -> void:
	_update_route_movement(delta)
	if _hit_feedback_remaining > 0.0:
		_hit_feedback_remaining = maxf(0.0, _hit_feedback_remaining - delta)
		queue_redraw()


func update_player_ship_state(
	player_ship_position: Vector2,
	player_aboard: bool,
	chart_closed: bool,
) -> void:
	if (
		_has_player_ship_position
		and _sail_current < SAIL_MAX
		and player_aboard
	):
		_player_sailing_distance_after_sail_damage += (
			_previous_player_ship_position.distance_to(player_ship_position)
		)
	_previous_player_ship_position = player_ship_position
	_has_player_ship_position = true
	_player_ship_position = player_ship_position
	_player_aboard = player_aboard
	_chart_closed = chart_closed
	_distance_to_player_ship = global_position.distance_to(_player_ship_position)
	if _sail_current < SAIL_MAX:
		_closest_distance_after_sail_damage = minf(
			_closest_distance_after_sail_damage,
			_distance_to_player_ship,
		)
		_update_catch_evidence()
	var was_visible := visible
	var was_inspection_available := _inspection_available
	var was_boarding_prompt_available := _boarding_prompt_available
	visible = _player_aboard and _distance_to_player_ship <= VISIBILITY_RANGE
	_boarding_prompt_available = (
		visible
		and _chart_closed
		and is_boarding_condition_ready()
		and is_alongside_player_ship()
		and not _boarding_active
		and not _boarding_victory_resolved
	)
	# The Board action has priority over target inspection at the same position.
	_inspection_available = (
		visible
		and _chart_closed
		and _distance_to_player_ship <= INSPECTION_RANGE
		and not _boarding_prompt_available
	)
	if (
		is_boarding_condition_ready()
		and _player_aboard
		and _chart_closed
		and not is_alongside_player_ship()
		and not _boarding_active
		and not _boarding_victory_resolved
		and not _boarding_far_denial_observed
	):
		_boarding_far_denial_observed = true
		_boarding_far_denial_count += 1
		_boarding_far_denial_distance = _distance_to_player_ship
	if (
		was_visible != visible
		or was_inspection_available != _inspection_available
		or was_boarding_prompt_available != _boarding_prompt_available
	):
		queue_redraw()


func is_inspection_available() -> bool:
	return _inspection_available


func get_distance_to_player_ship() -> float:
	return _distance_to_player_ship


func is_boarding_condition_ready() -> bool:
	return (
		_hull_current > 0
		and (
			_hull_current <= BOARDING_HULL_WEAK_THRESHOLD
			or _sail_current <= BOARDING_SAIL_WEAK_THRESHOLD
		)
	)


func is_alongside_player_ship() -> bool:
	return _distance_to_player_ship <= BOARDING_ALONGSIDE_RANGE


func is_boarding_prompt_available() -> bool:
	return _boarding_prompt_available


func is_boarding_active() -> bool:
	return _boarding_active


func is_boarding_victory_resolved() -> bool:
	return _boarding_victory_resolved


func begin_boarding() -> Dictionary:
	var boarding_before: Dictionary = get_boarding_state()
	if _boarding_victory_resolved:
		_repeat_boarding_begin_blocked_count += 1
		_last_repeat_boarding_block_evidence = {
			"success": false,
			"result": "BOARDING VICTORY ALREADY RESOLVED",
			"rejection_reason": "TARGET_VICTORY_RESOLVED",
			"target_id": target_id,
			"resolved": true,
			"resolution_count": _boarding_victory_resolution_count,
			"begin_count_before": _boarding_begin_count,
			"begin_count_after": _boarding_begin_count,
			"prompt_available": _boarding_prompt_available,
			"no_state_change": true,
		}
		return _last_repeat_boarding_block_evidence.duplicate(true)
	if not _boarding_prompt_available or _boarding_active:
		return {
			"success": false,
			"result": "BOARDING UNAVAILABLE",
			"target_id": target_id,
			"boarding_before": boarding_before,
			"boarding_after": get_boarding_state(),
		}
	_boarding_active = true
	_boarding_prompt_available = false
	_inspection_available = false
	_boarding_begin_count += 1
	_boarding_anchor_position = global_position
	_boarding_anchor_rotation = rotation
	_boarding_condition_at_begin = {
		"hull_current": _hull_current,
		"sail_current": _sail_current,
	}
	_last_boarding_begin_evidence = {
		"success": true,
		"result": "BOARDED TARGET DECK",
		"target_id": target_id,
		"target_name": display_name,
		"hull_current": _hull_current,
		"sail_current": _sail_current,
		"hull_above_zero": _hull_current > 0,
		"condition_ready": is_boarding_condition_ready(),
		"distance_to_player_ship": _distance_to_player_ship,
		"alongside_range": BOARDING_ALONGSIDE_RANGE,
		"alongside": is_alongside_player_ship(),
		"route_anchor_position": _boarding_anchor_position,
		"route_anchor_rotation": _boarding_anchor_rotation,
		"route_frozen": true,
		"boarding_before": boarding_before,
	}
	queue_redraw()
	return _last_boarding_begin_evidence.duplicate(true)


func resolve_boarding_victory() -> Dictionary:
	if _boarding_victory_resolved:
		return {
			"success": false,
			"result": "BOARDING VICTORY ALREADY RESOLVED",
			"target_id": target_id,
			"resolution_count": _boarding_victory_resolution_count,
			"no_state_change": true,
		}
	if not _boarding_active:
		return {
			"success": false,
			"result": "NO ACTIVE BOARDING VICTORY",
			"target_id": target_id,
			"resolution_count": _boarding_victory_resolution_count,
			"no_state_change": true,
		}
	var condition_before := {
		"hull_current": _hull_current,
		"sail_current": _sail_current,
	}
	var route_position_before := global_position
	var route_rotation_before := rotation
	var route_enabled_before := route_enabled
	_boarding_victory_resolved = true
	_boarding_victory_resolution_count += 1
	_boarding_prompt_available = false
	_inspection_available = false
	_last_boarding_victory_resolution_evidence = {
		"success": true,
		"result": "BOARDING VICTORY RESOLVED",
		"target_id": target_id,
		"target_name": display_name,
		"resolved": _boarding_victory_resolved,
		"resolution_count": _boarding_victory_resolution_count,
		"boarding_active": _boarding_active,
		"prompt_available": _boarding_prompt_available,
		"begin_count": _boarding_begin_count,
		"condition_at_resolution": {
			"hull_current": _hull_current,
			"sail_current": _sail_current,
		},
		"condition_before_resolution": condition_before,
		"condition_unchanged_by_resolution": condition_before == {
			"hull_current": _hull_current,
			"sail_current": _sail_current,
		},
		"route_position_before_resolution": route_position_before,
		"route_position_after_resolution": global_position,
		"route_rotation_before_resolution": route_rotation_before,
		"route_rotation_after_resolution": rotation,
		"route_enabled_before_resolution": route_enabled_before,
		"route_enabled_after_resolution": route_enabled,
		"route_unchanged_by_resolution": (
			global_position.is_equal_approx(route_position_before)
			and is_equal_approx(rotation, route_rotation_before)
			and route_enabled == route_enabled_before
		),
		"route_anchor_position": _boarding_anchor_position,
		"route_anchor_rotation": _boarding_anchor_rotation,
		"route_still_frozen_until_return": _boarding_active,
		"repeat_boarding_blocked": true,
	}
	queue_redraw()
	return _last_boarding_victory_resolution_evidence.duplicate(true)


func finish_boarding() -> Dictionary:
	if not _boarding_active:
		return {
			"success": false,
			"result": "NO ACTIVE BOARDING",
			"target_id": target_id,
		}
	var condition_after := {
		"hull_current": _hull_current,
		"sail_current": _sail_current,
	}
	var route_stayed_fixed := (
		global_position.is_equal_approx(_boarding_anchor_position)
		and is_equal_approx(rotation, _boarding_anchor_rotation)
	)
	_boarding_active = false
	_boarding_finish_count += 1
	_last_boarding_finish_evidence = {
		"success": true,
		"result": "RETURNED TO PLAYER SHIP",
		"target_id": target_id,
		"target_name": display_name,
		"condition_before": _boarding_condition_at_begin.duplicate(true),
		"condition_after": condition_after.duplicate(true),
		"condition_unchanged": _boarding_condition_at_begin == condition_after,
		"hull_above_zero": _hull_current > 0,
		"route_anchor_position": _boarding_anchor_position,
		"route_position_at_return": global_position,
		"route_stayed_fixed": route_stayed_fixed,
		"victory_resolved": _boarding_victory_resolved,
		"victory_resolution_count": _boarding_victory_resolution_count,
		"repeat_boarding_blocked": _boarding_victory_resolved,
		"prompt_available_after_return": _boarding_prompt_available,
	}
	queue_redraw()
	return _last_boarding_finish_evidence.duplicate(true)


func can_receive_hull_damage() -> bool:
	return not _disabled and _hull_current > 0


func can_receive_sail_damage() -> bool:
	return not _disabled and _sail_current > 0


func can_receive_broadside_damage(attack_choice: String) -> bool:
	var normalized_choice := attack_choice.to_upper()
	if normalized_choice == ATTACK_HULL:
		return can_receive_hull_damage()
	if normalized_choice == ATTACK_SAILS:
		return can_receive_sail_damage()
	return false


func apply_broadside_hull_damage(damage: int, attack_side: String) -> Dictionary:
	return apply_broadside_damage(ATTACK_HULL, damage, attack_side)


func apply_broadside_damage(
	attack_choice: String,
	damage: int,
	attack_side: String,
) -> Dictionary:
	var normalized_choice := attack_choice.to_upper()
	var hull_before: int = _hull_current
	var sail_before: int = _sail_current
	var speed_before: float = get_current_speed()
	if (
		damage <= 0
		or not ATTACK_CHOICES.has(normalized_choice)
		or not can_receive_broadside_damage(normalized_choice)
	):
		return _build_no_damage_evidence(
			normalized_choice,
			attack_side,
			hull_before,
			sail_before,
			speed_before,
		)

	if normalized_choice == ATTACK_HULL:
		_hull_current = maxi(0, _hull_current - damage)
		_disabled = _hull_current == 0
		_hull_hit_count += 1
	else:
		_sail_current = maxi(0, _sail_current - damage)
		_sail_hit_count += 1
		if sail_before == SAIL_MAX:
			_catch_start_distance = _distance_to_player_ship
			_closest_distance_after_sail_damage = _distance_to_player_ship
			_player_sailing_distance_after_sail_damage = 0.0

	_hit_count += 1
	_last_hit_side = attack_side
	_last_hit_component = normalized_choice
	_last_hit_damage = (
		hull_before - _hull_current
		if normalized_choice == ATTACK_HULL
		else sail_before - _sail_current
	)
	_hit_feedback_remaining = HIT_FEEDBACK_DURATION
	var speed_after: float = get_current_speed()
	_last_hit_evidence = {
		"success": true,
		"target_id": target_id,
		"target_name": display_name,
		"attack_side": attack_side,
		"attack_choice": normalized_choice,
		"damage": _last_hit_damage,
		"hull_before": hull_before,
		"hull_after": _hull_current,
		"hull_max": HULL_MAX,
		"hull_delta": _hull_current - hull_before,
		"sail_before": sail_before,
		"sail_after": _sail_current,
		"sail_max": SAIL_MAX,
		"sail_delta": _sail_current - sail_before,
		"speed_before": speed_before,
		"speed_after": speed_after,
		"speed_delta": speed_after - speed_before,
		"speed_step_before": get_speed_step_for_condition(sail_before),
		"speed_step_after": get_speed_step(),
		"hull_unchanged": hull_before == _hull_current,
		"sails_unchanged": sail_before == _sail_current,
		"disabled": _disabled,
		"reached_zero_hull": _disabled and _hull_current == 0,
		"reached_zero_sails": _sail_current == 0,
		"zero_sails_keep_minimum_speed": (
			_sail_current != 0
			or is_equal_approx(speed_after, MINIMUM_SAIL_SPEED)
		),
		"sail_damage_does_not_disable_hull": (
			normalized_choice != ATTACK_SAILS or not _disabled
		),
		"hit_feedback_started": true,
		"result": _build_hit_result(normalized_choice),
	}
	_boarding_prompt_available = (
		_player_aboard
		and _chart_closed
		and is_boarding_condition_ready()
		and is_alongside_player_ship()
		and not _boarding_active
		and not _boarding_victory_resolved
	)
	queue_redraw()
	return _last_hit_evidence.duplicate(true)


func get_hull_state() -> Dictionary:
	return {
		"hull_current": _hull_current,
		"hull_max": HULL_MAX,
		"hull_ratio": float(_hull_current) / float(HULL_MAX),
		"disabled": _disabled,
		"can_receive_hull_damage": can_receive_hull_damage(),
		"hit_count": _hull_hit_count,
		"total_hit_count": _hit_count,
		"hull_hit_count": _hull_hit_count,
		"last_hit_side": _last_hit_side,
		"last_hit_component": _last_hit_component,
		"last_hit_damage": _last_hit_damage,
		"hit_feedback_duration": HIT_FEEDBACK_DURATION,
		"hit_feedback_remaining": _hit_feedback_remaining,
		"hit_feedback_active": _hit_feedback_remaining > 0.0,
		"hull_condition_visible": visible,
		"hull_condition_text": (
			"DISABLED · HULL 0 / %d" % HULL_MAX
			if _disabled
			else "HULL %d / %d" % [_hull_current, HULL_MAX]
		),
		"disabled_visual_visible": visible and _disabled,
		"last_hit_evidence": _last_hit_evidence.duplicate(true),
	}


func get_sail_state() -> Dictionary:
	return {
		"owner_count": 1,
		"sail_current": _sail_current,
		"sail_max": SAIL_MAX,
		"sail_ratio": float(_sail_current) / float(SAIL_MAX),
		"can_receive_sail_damage": can_receive_sail_damage(),
		"sail_hit_count": _sail_hit_count,
		"current_speed": get_current_speed(),
		"full_speed": FULL_SAIL_SPEED,
		"minimum_speed": MINIMUM_SAIL_SPEED,
		"speed_step": get_speed_step(),
		"speed_step_count": 5,
		"speed_steps": [
			FULL_SAIL_SPEED,
			DAMAGED_SAIL_SPEED_75,
			DAMAGED_SAIL_SPEED_50,
			DAMAGED_SAIL_SPEED_25,
			MINIMUM_SAIL_SPEED,
		],
		"sail_condition_text": "SAILS %d / %d" % [_sail_current, SAIL_MAX],
		"speed_text": "SPEED %.0f · STEP %d / 4" % [
			get_current_speed(),
			get_speed_step(),
		],
		"route_enabled": route_enabled,
		"route_start": route_start,
		"route_end": route_end,
		"route_distance_travelled": _route_distance_travelled,
		"last_route_move_distance": _last_route_move_distance,
		"last_route_velocity": _last_route_velocity,
		"moving": _last_route_move_distance > 0.0,
		"moves_at_zero_sails": (
			not route_enabled
			or _sail_current != 0
			or _last_route_move_distance > 0.0
		),
		"caught_after_sail_damage": _caught_after_sail_damage,
		"catch_evidence": _catch_evidence.duplicate(true),
		"sail_repair_system_count": 0,
	}


func get_condition_state() -> Dictionary:
	return {
		"target_id": target_id,
		"hull": get_hull_state(),
		"sails": get_sail_state(),
	}


func get_boarding_state() -> Dictionary:
	var hull_weak := (
		_hull_current > 0
		and _hull_current <= BOARDING_HULL_WEAK_THRESHOLD
	)
	var sails_weak := _sail_current <= BOARDING_SAIL_WEAK_THRESHOLD
	return {
		"owner_count": 1,
		"target_id": target_id,
		"hull_current": _hull_current,
		"sail_current": _sail_current,
		"hull_weak_threshold": BOARDING_HULL_WEAK_THRESHOLD,
		"sail_weak_threshold": BOARDING_SAIL_WEAK_THRESHOLD,
		"hull_weak": hull_weak,
		"sails_weak": sails_weak,
		"condition_ready": is_boarding_condition_ready(),
		"condition_rule_is_hull_or_sails": true,
		"hull_above_zero_required": true,
		"hull_above_zero": _hull_current > 0,
		"distance_to_player_ship": _distance_to_player_ship,
		"alongside_range": BOARDING_ALONGSIDE_RANGE,
		"alongside": is_alongside_player_ship(),
		"prompt_available": _boarding_prompt_available,
		"victory_resolved": _boarding_victory_resolved,
		"victory_resolution_count": _boarding_victory_resolution_count,
		"resolved_target_has_no_prompt": (
			not _boarding_victory_resolved or not _boarding_prompt_available
		),
		"repeat_boarding_blocked": _boarding_victory_resolved,
		"repeat_boarding_begin_blocked_count": (
			_repeat_boarding_begin_blocked_count
		),
		"last_victory_resolution_evidence": (
			_last_boarding_victory_resolution_evidence.duplicate(true)
		),
		"last_repeat_boarding_block_evidence": (
			_last_repeat_boarding_block_evidence.duplicate(true)
		),
		"resolution_preserved_condition_and_route": (
			not _boarding_victory_resolved
			or (
				bool(_last_boarding_victory_resolution_evidence.get(
					"condition_unchanged_by_resolution",
					false,
				))
				and bool(_last_boarding_victory_resolution_evidence.get(
					"route_unchanged_by_resolution",
					false,
				))
			)
		),
		"prompt_requires_condition_and_position": (
			not _boarding_prompt_available
			or (is_boarding_condition_ready() and is_alongside_player_ship())
		),
		"active": _boarding_active,
		"route_frozen": _boarding_active,
		"route_anchor_position": _boarding_anchor_position,
		"route_anchor_rotation": _boarding_anchor_rotation,
		"route_stable_while_boarding": (
			not _boarding_active
			or (
				global_position.is_equal_approx(_boarding_anchor_position)
				and is_equal_approx(rotation, _boarding_anchor_rotation)
			)
		),
		"far_denial_observed": _boarding_far_denial_observed,
		"far_denial_count": _boarding_far_denial_count,
		"far_denial_distance": _boarding_far_denial_distance,
		"far_denial_has_no_prompt": (
			not _boarding_far_denial_observed
			or _boarding_far_denial_distance > BOARDING_ALONGSIDE_RANGE
		),
		"begin_count": _boarding_begin_count,
		"finish_count": _boarding_finish_count,
		"condition_at_begin": _boarding_condition_at_begin.duplicate(true),
		"last_begin_evidence": _last_boarding_begin_evidence.duplicate(true),
		"last_finish_evidence": _last_boarding_finish_evidence.duplicate(true),
	}


func get_current_speed() -> float:
	if _disabled:
		return 0.0
	if _sail_current >= 100:
		return FULL_SAIL_SPEED
	if _sail_current >= 75:
		return DAMAGED_SAIL_SPEED_75
	if _sail_current >= 50:
		return DAMAGED_SAIL_SPEED_50
	if _sail_current >= 25:
		return DAMAGED_SAIL_SPEED_25
	return MINIMUM_SAIL_SPEED


func get_speed_step() -> int:
	return get_speed_step_for_condition(_sail_current)


func get_speed_step_for_condition(sail_condition: int) -> int:
	if sail_condition >= 100:
		return 4
	if sail_condition >= 75:
		return 3
	if sail_condition >= 50:
		return 2
	if sail_condition >= 25:
		return 1
	return 0


func get_estimate_state() -> Dictionary:
	return {
		"target_id": target_id,
		"display_name": display_name,
		"owner_estimate": owner_name,
		"flag_estimate": flag_name,
		"ship_class_estimate": ship_class,
		"likely_speed_estimate": likely_speed,
		"general_cargo_type_estimate": general_cargo_type,
		"threat_estimate": threat_estimate,
		"peaceful_estimate": peaceful,
		"estimated_heat_cost": estimated_heat_cost,
		"all_values_are_estimates": true,
	}


func get_playtest_state() -> Dictionary:
	var estimate: Dictionary = get_estimate_state()
	return {
		"target_id": target_id,
		"display_name": display_name,
		"position": global_position,
		"player_ship_position": _player_ship_position,
		"distance_to_player_ship": _distance_to_player_ship,
		"visibility_range": VISIBILITY_RANGE,
		"inspection_range": INSPECTION_RANGE,
		"visual_visible": visible,
		"player_aboard": _player_aboard,
		"chart_closed": _chart_closed,
		"inspection_available": _inspection_available,
		"estimate": estimate,
		"hull": get_hull_state(),
		"sails": get_sail_state(),
		"condition_owner_count": 1,
		"attack_choices": ATTACK_CHOICES.duplicate(),
		"attack_choice_count": ATTACK_CHOICES.size(),
		"boarding": get_boarding_state(),
		"boarding_system_count": 1,
		"boarding_victory_resolved": _boarding_victory_resolved,
		"boarding_victory_resolution_count": (
			_boarding_victory_resolution_count
		),
		"repeat_boarding_blocked": _boarding_victory_resolved,
		"repeat_boarding_begin_blocked_count": (
			_repeat_boarding_begin_blocked_count
		),
		"crew_injury_system_count": 0,
		"special_ammunition_type_count": 0,
		"permanent_module_count": 0,
	}


func _update_route_movement(delta: float) -> void:
	_last_route_move_distance = 0.0
	_last_route_velocity = Vector2.ZERO
	if not route_enabled or _disabled or _boarding_active or delta <= 0.0:
		return
	var route_target: Vector2 = route_end if _route_toward_end else route_start
	if global_position.is_equal_approx(route_target):
		_route_toward_end = not _route_toward_end
		route_target = route_end if _route_toward_end else route_start
	var direction := global_position.direction_to(route_target)
	if direction.is_zero_approx():
		return
	var move_distance := minf(
		get_current_speed() * delta,
		global_position.distance_to(route_target),
	)
	global_position += direction * move_distance
	rotation = direction.angle()
	_last_route_move_distance = move_distance
	_last_route_velocity = direction * get_current_speed()
	_route_distance_travelled += move_distance
	queue_redraw()


func _face_route_target() -> void:
	var route_target: Vector2 = route_end if _route_toward_end else route_start
	var direction := global_position.direction_to(route_target)
	if not direction.is_zero_approx():
		rotation = direction.angle()


func _update_catch_evidence() -> void:
	if _caught_after_sail_damage or _catch_start_distance < 0.0 or _disabled:
		return
	var closing_distance := (
		_catch_start_distance - _closest_distance_after_sail_damage
	)
	if (
		_hull_current > 0
		and _distance_to_player_ship <= CATCH_RANGE
		and closing_distance >= CATCH_MINIMUM_CLOSING_DISTANCE
		and _player_sailing_distance_after_sail_damage
			>= CATCH_MINIMUM_PLAYER_SAILING_DISTANCE
	):
		_caught_after_sail_damage = true
		_catch_evidence = {
			"success": true,
			"result": "CAUGHT AFTER SAIL DAMAGE",
			"target_id": target_id,
			"sail_condition": _sail_current,
			"hull_condition": _hull_current,
			"target_speed": get_current_speed(),
			"catch_distance": _distance_to_player_ship,
			"catch_range": CATCH_RANGE,
			"distance_at_first_sail_hit": _catch_start_distance,
			"closest_distance": _closest_distance_after_sail_damage,
			"closing_distance": closing_distance,
			"player_sailing_distance_after_sail_damage": (
				_player_sailing_distance_after_sail_damage
			),
			"hull_remained_above_zero": _hull_current > 0,
		}
		queue_redraw()


func _build_no_damage_evidence(
	attack_choice: String,
	attack_side: String,
	hull_before: int,
	sail_before: int,
	speed_before: float,
) -> Dictionary:
	return {
		"success": false,
		"target_id": target_id,
		"target_name": display_name,
		"attack_side": attack_side,
		"attack_choice": attack_choice,
		"damage": 0,
		"hull_before": hull_before,
		"hull_after": _hull_current,
		"hull_max": HULL_MAX,
		"hull_delta": 0,
		"sail_before": sail_before,
		"sail_after": _sail_current,
		"sail_max": SAIL_MAX,
		"sail_delta": 0,
		"speed_before": speed_before,
		"speed_after": get_current_speed(),
		"speed_delta": 0.0,
		"disabled": _disabled,
		"result": "NO TARGET CONDITION CHANGE",
	}


func _build_hit_result(attack_choice: String) -> String:
	if attack_choice == ATTACK_SAILS:
		return "TARGET HIT · -%d SAILS · SPEED %.0f" % [
			_last_hit_damage,
			get_current_speed(),
		]
	if _disabled:
		return "TARGET DISABLED"
	return "TARGET HIT · -%d HULL" % _last_hit_damage


func _draw() -> void:
	# The long hull, mast, sails, and flag make each target a clear sea ship.
	var active_hull_color: Color = hull_color
	var active_sail_color: Color = sail_color
	if _disabled:
		active_hull_color = hull_color.darkened(0.68)
		active_sail_color = sail_color.darkened(0.7)
	else:
		active_sail_color = sail_color.darkened(
			0.55 * (1.0 - float(_sail_current) / float(SAIL_MAX))
		)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-54.0, -20.0),
		Vector2(38.0, -24.0),
		Vector2(63.0, 0.0),
		Vector2(38.0, 24.0),
		Vector2(-54.0, 20.0),
		Vector2(-68.0, 0.0),
	]), active_hull_color)
	draw_polyline(PackedVector2Array([
		Vector2(-54.0, -20.0),
		Vector2(38.0, -24.0),
		Vector2(63.0, 0.0),
		Vector2(38.0, 24.0),
		Vector2(-54.0, 20.0),
		Vector2(-68.0, 0.0),
		Vector2(-54.0, -20.0),
	]), Color("#2e2926"), 4.0)
	draw_line(Vector2(-6.0, -46.0), Vector2(-6.0, 45.0), Color("#493323"), 6.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-3.0, -40.0),
		Vector2(43.0, -4.0),
		Vector2(-3.0, -4.0),
	]), active_sail_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9.0, 4.0),
		Vector2(29.0, 36.0),
		Vector2(-9.0, 36.0),
	]), active_sail_color.darkened(0.12))
	draw_line(Vector2(-35.0, -18.0), Vector2(-35.0, -47.0), Color("#493323"), 4.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-33.0, -46.0),
		Vector2(-10.0, -39.0),
		Vector2(-33.0, -32.0),
	]), flag_color)

	var font: Font = ThemeDB.fallback_font
	var hull_text: String = "HULL %d / %d" % [_hull_current, HULL_MAX]
	var hull_text_color: Color = Color("#fff1c5")
	if _disabled:
		hull_text = "DISABLED · HULL 0 / %d" % HULL_MAX
		hull_text_color = Color("#ff806e")
		draw_line(Vector2(-55.0, -35.0), Vector2(55.0, 35.0), hull_text_color, 8.0)
		draw_line(Vector2(-55.0, 35.0), Vector2(55.0, -35.0), hull_text_color, 8.0)
	draw_string(font, Vector2(-110.0, 82.0), hull_text, HORIZONTAL_ALIGNMENT_CENTER, 220.0, 15, hull_text_color)
	draw_string(font, Vector2(-110.0, 103.0), "SAILS %d / %d" % [_sail_current, SAIL_MAX], HORIZONTAL_ALIGNMENT_CENTER, 220.0, 15, Color("#d9f6ee"))
	draw_string(font, Vector2(-110.0, 124.0), "SPEED %.0f · STEP %d/4" % [get_current_speed(), get_speed_step()], HORIZONTAL_ALIGNMENT_CENTER, 220.0, 14, Color("#79d8e8"))
	if _caught_after_sail_damage:
		draw_string(font, Vector2(-110.0, 145.0), "CAUGHT · HULL ABOVE ZERO", HORIZONTAL_ALIGNMENT_CENTER, 220.0, 14, Color("#8ef0a8"))
	if is_boarding_condition_ready():
		draw_string(
			font,
			Vector2(-110.0, 166.0),
			(
				"PRIZES CLAIMED · BOARDING RESOLVED"
				if _boarding_victory_resolved
				else (
					"BOARDING READY · ALONGSIDE"
					if _boarding_prompt_available
					else "BOARDING READY · CLOSE THE DISTANCE"
				)
			),
			HORIZONTAL_ALIGNMENT_CENTER,
			220.0,
			14,
			Color("#f2c14f"),
		)
	if _hit_feedback_remaining > 0.0:
		draw_arc(Vector2.ZERO, 82.0, 0.0, TAU, 48, Color("#ff4b3e"), 9.0)
		draw_string(
			font,
			Vector2(-110.0, 187.0),
			("DISABLED" if _disabled else "HIT · -%d %s" % [_last_hit_damage, _last_hit_component]),
			HORIZONTAL_ALIGNMENT_CENTER,
			220.0,
			18,
			Color("#ff806e"),
		)

	if not _inspection_available or _boarding_prompt_available:
		return
	draw_arc(Vector2.ZERO, 90.0, 0.0, TAU, 48, Color("#fff1c5"), 4.0)
	draw_string(
		font,
		Vector2(-110.0, -104.0),
		"%s · E INSPECT" % display_name,
		HORIZONTAL_ALIGNMENT_CENTER,
		220.0,
		16,
		Color("#fff1c5"),
	)
