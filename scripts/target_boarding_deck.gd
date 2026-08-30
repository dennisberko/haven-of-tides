class_name TargetBoardingDeck
extends Node2D

const DECK_SIZE := Vector2(360.0, 180.0)
const WALK_MARGIN := Vector2(28.0, 28.0)
const ENTRY_LOCAL_POSITION := Vector2(122.0, 0.0)
const RETURN_LOCAL_POSITION := Vector2(-122.0, 0.0)
const DEFENDER_START_LOCAL_POSITION := Vector2(-32.0, 0.0)
const RETURN_RANGE := 44.0
const WALK_ACROSS_DISTANCE := 180.0

const PLAYER_HEALTH_MAX := 5
const DEFENDER_HEALTH_MAX := 3
const COASTAL_MERCHANT_TARGET_ID := "coastal_merchant"
const NAVAL_COURIER_TARGET_ID := "naval_courier"
const COASTAL_MERCHANT_MORALE_MAX := 2
const NAVAL_COURIER_MORALE_MAX := 4
const CUTLASS_DAMAGE := 1
const CUTLASS_MORALE_DAMAGE := 1
const DEFENDER_ATTACK_DAMAGE := 1
const PLAYER_CUTLASS_RANGE := 54.0
const DEFENDER_ATTACK_RANGE := 42.0
const DEFENDER_CHASE_RANGE := 180.0
const DEFENDER_MOVE_SPEED := 52.0
const DEFENDER_STOP_DISTANCE := 34.0
const DEFENDER_ATTACK_COOLDOWN := 1.25
const PLAYER_CUTLASS_COOLDOWN := 0.35
const COMBAT_FEEDBACK_DURATION := 0.75

var active := false
var active_target_id := ""
var active_target_name := ""
var active_hull := 0
var active_sails := 0

var player_health := PLAYER_HEALTH_MAX
var defender_health := DEFENDER_HEALTH_MAX
var defender_morale_profile := "COASTAL_MERCHANT_SURRENDER"
var defender_morale_max := COASTAL_MERCHANT_MORALE_MAX
var defender_morale := COASTAL_MERCHANT_MORALE_MAX
var defender_local_position := DEFENDER_START_LOCAL_POSITION
var defender_alive := true
var defender_surrendered := false
var fight_ended := false

var _cutlass_key_held := false
var _cutlass_cooldown_remaining := 0.0
var _defender_attack_cooldown_remaining := 0.0
var _player_feedback_remaining := 0.0
var _defender_feedback_remaining := 0.0
var _fight_feedback_remaining := 0.0
var _player_feedback_text := "READY"
var _defender_feedback_text := "DEFENDER READY"
var _fight_feedback_text := "DEFENDER CLOSING"
var _last_player_position := Vector2.ZERO
var _was_player_in_defender_range := false

var cutlass_attempt_count := 0
var cutlass_hit_count := 0
var cutlass_out_of_range_count := 0
var cutlass_held_input_count := 0
var cutlass_cooldown_rejection_count := 0
var cutlass_fight_ended_rejection_count := 0
var cutlass_damage_total := 0
var defender_move_frame_count := 0
var defender_movement_distance := 0.0
var defender_entered_range_count := 0
var defender_left_range_count := 0
var defender_attack_count := 0
var player_damage_total := 0
var player_damage_feedback_count := 0
var defender_damage_feedback_count := 0
var defender_defeat_count := 0
var defender_morale_damage_total := 0
var defender_last_morale_damage := 0
var defender_surrender_count := 0
var post_surrender_cutlass_rejection_count := 0
var _defender_position_at_surrender := Vector2.ZERO
var _defender_attack_count_at_surrender := 0
var _defender_move_frame_count_at_surrender := 0
var last_cutlass_evidence: Dictionary = {}
var last_defender_attack_evidence: Dictionary = {}
var last_surrender_evidence: Dictionary = {}
var last_post_surrender_cutlass_evidence: Dictionary = {}


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
	_reset_combat()
	show()
	queue_redraw()


func deactivate() -> void:
	active = false
	active_target_id = ""
	active_target_name = ""
	active_hull = 0
	active_sails = 0
	_cutlass_key_held = false
	hide()
	queue_redraw()


func _reset_combat() -> void:
	player_health = PLAYER_HEALTH_MAX
	defender_health = DEFENDER_HEALTH_MAX
	defender_morale_profile = _get_morale_profile(active_target_id)
	defender_morale_max = _get_morale_capacity(active_target_id)
	defender_morale = defender_morale_max
	defender_local_position = DEFENDER_START_LOCAL_POSITION
	defender_alive = true
	defender_surrendered = false
	fight_ended = false
	_cutlass_key_held = false
	_cutlass_cooldown_remaining = 0.0
	_defender_attack_cooldown_remaining = 0.6
	_player_feedback_remaining = 0.0
	_defender_feedback_remaining = 0.0
	_fight_feedback_remaining = 0.0
	_player_feedback_text = "READY"
	_defender_feedback_text = "DEFENDER READY"
	_fight_feedback_text = "DEFENDER CLOSING"
	_last_player_position = get_entry_position()
	_was_player_in_defender_range = false
	cutlass_attempt_count = 0
	cutlass_hit_count = 0
	cutlass_out_of_range_count = 0
	cutlass_held_input_count = 0
	cutlass_cooldown_rejection_count = 0
	cutlass_fight_ended_rejection_count = 0
	cutlass_damage_total = 0
	defender_move_frame_count = 0
	defender_movement_distance = 0.0
	defender_entered_range_count = 0
	defender_left_range_count = 0
	defender_attack_count = 0
	player_damage_total = 0
	player_damage_feedback_count = 0
	defender_damage_feedback_count = 0
	defender_defeat_count = 0
	defender_morale_damage_total = 0
	defender_last_morale_damage = 0
	defender_surrender_count = 0
	post_surrender_cutlass_rejection_count = 0
	_defender_position_at_surrender = Vector2.ZERO
	_defender_attack_count_at_surrender = 0
	_defender_move_frame_count_at_surrender = 0
	last_cutlass_evidence = {}
	last_defender_attack_evidence = {}
	last_surrender_evidence = {}
	last_post_surrender_cutlass_evidence = {}


func _get_morale_profile(target_id: String) -> String:
	if target_id == NAVAL_COURIER_TARGET_ID:
		return "NAVAL_COURIER_DEFEAT"
	return "COASTAL_MERCHANT_SURRENDER"


func _get_morale_capacity(target_id: String) -> int:
	if target_id == NAVAL_COURIER_TARGET_ID:
		return NAVAL_COURIER_MORALE_MAX
	return COASTAL_MERCHANT_MORALE_MAX


func _get_defeat_path_evidence() -> Dictionary:
	var fresh_hits_to_defeat: int = int(ceil(
		float(DEFENDER_HEALTH_MAX) / float(CUTLASS_DAMAGE)
	))
	var morale_after_defeat_hit := maxi(
		0,
		NAVAL_COURIER_MORALE_MAX
			- fresh_hits_to_defeat * CUTLASS_MORALE_DAMAGE,
	)
	var defeat_path_available := morale_after_defeat_hit > 0
	return {
		"available": defeat_path_available,
		"contract_holds": defeat_path_available,
		"target_id": NAVAL_COURIER_TARGET_ID,
		"morale_profile": "NAVAL_COURIER_DEFEAT",
		"defender_count": 1,
		"cutlass_system_count": 1,
		"cutlass_attack_type_count": 1,
		"cutlass_attack_type": "CUTLASS_SLASH",
		"health_system_count": 1,
		"morale_system_count": 1,
		"defender_health_max": DEFENDER_HEALTH_MAX,
		"defender_morale_max": NAVAL_COURIER_MORALE_MAX,
		"cutlass_damage": CUTLASS_DAMAGE,
		"morale_damage_per_hit": CUTLASS_MORALE_DAMAGE,
		"fresh_hits_to_defeat": fresh_hits_to_defeat,
		"health_after_defeat_hit": 0,
		"morale_after_defeat_hit": morale_after_defeat_hit,
		"surrenders_before_defeat": morale_after_defeat_hit <= 0,
		"same_combat_owner": true,
		"same_one_defender": true,
		"same_one_cutlass": true,
		"uses_same_health_system": true,
		"uses_same_morale_system": true,
		"no_extra_player_action": true,
	}


func update_combat(delta: float, player_position: Vector2) -> void:
	if not active:
		return
	_last_player_position = player_position
	_cutlass_cooldown_remaining = maxf(
		0.0,
		_cutlass_cooldown_remaining - delta,
	)
	_defender_attack_cooldown_remaining = maxf(
		0.0,
		_defender_attack_cooldown_remaining - delta,
	)
	_player_feedback_remaining = maxf(0.0, _player_feedback_remaining - delta)
	_defender_feedback_remaining = maxf(
		0.0,
		_defender_feedback_remaining - delta,
	)
	_fight_feedback_remaining = maxf(0.0, _fight_feedback_remaining - delta)

	if defender_alive and not defender_surrendered and not fight_ended:
		_update_defender_movement(delta, player_position)
		_update_defender_attack(player_position)
	_update_defender_range_tracking(player_position)
	queue_redraw()


func _update_defender_movement(delta: float, player_position: Vector2) -> void:
	var player_local_position: Vector2 = to_local(player_position)
	var distance_before: float = defender_local_position.distance_to(
		player_local_position
	)
	if (
		distance_before > DEFENDER_STOP_DISTANCE
		and distance_before <= DEFENDER_CHASE_RANGE
	):
		var next_position: Vector2 = defender_local_position.move_toward(
			player_local_position,
			DEFENDER_MOVE_SPEED * delta,
		)
		var local_walk_rect := Rect2(
			-DECK_SIZE * 0.5 + WALK_MARGIN,
			DECK_SIZE - WALK_MARGIN * 2.0,
		)
		next_position = next_position.clamp(
			local_walk_rect.position,
			local_walk_rect.end,
		)
		var moved_distance: float = defender_local_position.distance_to(
			next_position
		)
		if moved_distance > 0.0:
			defender_local_position = next_position
			defender_move_frame_count += 1
			defender_movement_distance += moved_distance
			if _fight_feedback_remaining <= 0.0:
				_fight_feedback_text = "DEFENDER CLOSING"


func _update_defender_attack(player_position: Vector2) -> void:
	var distance_to_player: float = get_defender_position().distance_to(
		player_position
	)
	if (
		distance_to_player > DEFENDER_ATTACK_RANGE
		or _defender_attack_cooldown_remaining > 0.0
		or player_health <= 1
	):
		return
	var health_before := player_health
	player_health = maxi(1, player_health - DEFENDER_ATTACK_DAMAGE)
	var damage_done := health_before - player_health
	defender_attack_count += 1
	player_damage_total += damage_done
	player_damage_feedback_count += 1
	_defender_attack_cooldown_remaining = DEFENDER_ATTACK_COOLDOWN
	_player_feedback_remaining = COMBAT_FEEDBACK_DURATION
	_fight_feedback_remaining = COMBAT_FEEDBACK_DURATION
	_player_feedback_text = "PLAYER HIT · -%d HEALTH" % damage_done
	_fight_feedback_text = _player_feedback_text
	last_defender_attack_evidence = {
		"success": true,
		"attack_type": "CUTLASS_SLASH",
		"distance": distance_to_player,
		"attack_range": DEFENDER_ATTACK_RANGE,
		"player_health_before": health_before,
		"player_health_after": player_health,
		"damage": damage_done,
		"clear_player_damage_feedback": true,
		"player_not_defeated_in_phase": player_health >= 1,
	}


func _update_defender_range_tracking(player_position: Vector2) -> void:
	if not defender_alive or defender_surrendered or fight_ended:
		_was_player_in_defender_range = false
		return
	var in_range := (
		get_defender_position().distance_to(player_position)
		<= DEFENDER_ATTACK_RANGE
	)
	if in_range and not _was_player_in_defender_range:
		defender_entered_range_count += 1
	elif not in_range and _was_player_in_defender_range:
		defender_left_range_count += 1
	_was_player_in_defender_range = in_range


func handle_cutlass_input(
	pressed: bool,
	echo: bool,
	player_position: Vector2,
) -> void:
	if not pressed:
		_cutlass_key_held = false
		return
	var state_before := _get_cutlass_state_snapshot()
	var distance_to_defender: float = player_position.distance_to(
		get_defender_position()
	)
	if echo or _cutlass_key_held:
		cutlass_held_input_count += 1
		last_cutlass_evidence = _make_cutlass_rejection_evidence(
			"HELD_KEY",
			distance_to_defender,
			state_before,
		)
		return
	_cutlass_key_held = true
	cutlass_attempt_count += 1
	if defender_surrendered:
		post_surrender_cutlass_rejection_count += 1
		_fight_feedback_text = "CUTLASS BLOCKED · SURRENDER"
		_fight_feedback_remaining = COMBAT_FEEDBACK_DURATION * 2.0
		last_cutlass_evidence = _make_cutlass_rejection_evidence(
			"SURRENDERED",
			distance_to_defender,
			state_before,
		)
		last_post_surrender_cutlass_evidence = (
			last_cutlass_evidence.duplicate(true)
		)
		queue_redraw()
		return
	if fight_ended or not defender_alive:
		cutlass_fight_ended_rejection_count += 1
		last_cutlass_evidence = _make_cutlass_rejection_evidence(
			"FIGHT_ENDED",
			distance_to_defender,
			state_before,
		)
		return
	if distance_to_defender > PLAYER_CUTLASS_RANGE:
		cutlass_out_of_range_count += 1
		_fight_feedback_text = "CUTLASS MISSED · MOVE CLOSER"
		_fight_feedback_remaining = COMBAT_FEEDBACK_DURATION
		last_cutlass_evidence = _make_cutlass_rejection_evidence(
			"OUT_OF_RANGE",
			distance_to_defender,
			state_before,
		)
		queue_redraw()
		return
	if _cutlass_cooldown_remaining > 0.0:
		cutlass_cooldown_rejection_count += 1
		last_cutlass_evidence = _make_cutlass_rejection_evidence(
			"CUTLASS_RECOVERY",
			distance_to_defender,
			state_before,
		)
		return

	var defender_health_before := defender_health
	var defender_morale_before := defender_morale
	defender_health = maxi(0, defender_health - CUTLASS_DAMAGE)
	defender_morale = maxi(0, defender_morale - CUTLASS_MORALE_DAMAGE)
	var damage_done := defender_health_before - defender_health
	var morale_damage_done := defender_morale_before - defender_morale
	cutlass_hit_count += 1
	cutlass_damage_total += damage_done
	defender_morale_damage_total += morale_damage_done
	defender_last_morale_damage = morale_damage_done
	defender_damage_feedback_count += 1
	_cutlass_cooldown_remaining = PLAYER_CUTLASS_COOLDOWN
	_defender_feedback_remaining = COMBAT_FEEDBACK_DURATION
	_fight_feedback_remaining = COMBAT_FEEDBACK_DURATION
	_defender_feedback_text = "HIT · -%d HEALTH · -%d MORALE" % [
		damage_done,
		morale_damage_done,
	]
	_fight_feedback_text = _defender_feedback_text
	if defender_morale == 0 and defender_health > 0:
		_surrender_defender(
			defender_health_before,
			defender_morale_before,
			damage_done,
			morale_damage_done,
		)
	elif defender_health == 0:
		defender_alive = false
		fight_ended = true
		defender_defeat_count += 1
		_fight_feedback_text = "DEFENDER DEFEATED · FIGHT ENDED"
		_fight_feedback_remaining = COMBAT_FEEDBACK_DURATION * 3.0
	last_cutlass_evidence = {
		"success": true,
		"result": (
			"DEFENDER_SURRENDERED"
			if defender_surrendered
			else "DEFENDER_DEFEATED" if fight_ended else "DEFENDER_HIT"
		),
		"attack_type": "CUTLASS_SLASH",
		"target_id": active_target_id,
		"morale_profile": defender_morale_profile,
		"defender_morale_max": defender_morale_max,
		"distance": distance_to_defender,
		"attack_range": PLAYER_CUTLASS_RANGE,
		"defender_health_before": defender_health_before,
		"defender_health_after": defender_health,
		"damage": damage_done,
		"defender_morale_before": defender_morale_before,
		"defender_morale_after": defender_morale,
		"morale_damage": morale_damage_done,
		"defender_defeated": not defender_alive,
		"defender_surrendered": defender_surrendered,
		"defender_alive": defender_alive,
		"fight_ended": fight_ended,
		"clear_defender_damage_feedback": true,
		"fresh_press_required": true,
	}
	queue_redraw()


func _surrender_defender(
	health_before: int,
	morale_before: int,
	health_damage: int,
	morale_damage: int,
) -> void:
	defender_surrendered = true
	fight_ended = true
	defender_surrender_count += 1
	_defender_position_at_surrender = defender_local_position
	_defender_attack_count_at_surrender = defender_attack_count
	_defender_move_frame_count_at_surrender = defender_move_frame_count
	_was_player_in_defender_range = false
	_defender_feedback_text = "MORALE BROKEN · SURRENDERED"
	_fight_feedback_text = "SURRENDER · FIGHT ENDED"
	_fight_feedback_remaining = COMBAT_FEEDBACK_DURATION * 3.0
	last_surrender_evidence = {
		"success": true,
		"result": "DEFENDER_SURRENDERED",
		"target_id": active_target_id,
		"morale_profile": defender_morale_profile,
		"defender_morale_max": defender_morale_max,
		"defender_health_before": health_before,
		"defender_health_after": defender_health,
		"health_damage": health_damage,
		"defender_morale_before": morale_before,
		"defender_morale_after": defender_morale,
		"morale_damage": morale_damage,
		"morale_reached_zero": defender_morale == 0,
		"health_above_zero": defender_health > 0,
		"defender_alive": defender_alive,
		"defender_surrendered": defender_surrendered,
		"hostile_defender_count": 0,
		"fight_ended": fight_ended,
		"fight_outcome": "SURRENDER",
		"attacks_stopped": true,
		"movement_stopped": true,
		"surrender_pose_visible": true,
		"defender_weapon_visible": false,
		"no_gore": true,
	}


func _get_cutlass_state_snapshot() -> Dictionary:
	return {
		"defender_health": defender_health,
		"defender_morale_profile": defender_morale_profile,
		"defender_morale_max": defender_morale_max,
		"defender_morale": defender_morale,
		"defender_alive": defender_alive,
		"defender_surrendered": defender_surrendered,
		"fight_ended": fight_ended,
		"defender_position": defender_local_position,
		"player_health": player_health,
		"defender_attack_count": defender_attack_count,
		"defender_move_frame_count": defender_move_frame_count,
		"cutlass_damage_total": cutlass_damage_total,
		"morale_damage_total": defender_morale_damage_total,
		"surrender_count": defender_surrender_count,
	}


func _make_cutlass_rejection_evidence(
	reason: String,
	distance_to_defender: float,
	state_before: Dictionary,
) -> Dictionary:
	var defender_position_before: Vector2 = state_before["defender_position"]
	var no_state_change := (
		int(state_before["defender_health"]) == defender_health
		and String(state_before["defender_morale_profile"])
			== defender_morale_profile
		and int(state_before["defender_morale_max"]) == defender_morale_max
		and int(state_before["defender_morale"]) == defender_morale
		and bool(state_before["defender_alive"]) == defender_alive
		and bool(state_before["defender_surrendered"]) == defender_surrendered
		and bool(state_before["fight_ended"]) == fight_ended
		and defender_position_before == defender_local_position
		and int(state_before["player_health"]) == player_health
		and int(state_before["defender_attack_count"]) == defender_attack_count
		and int(state_before["defender_move_frame_count"])
			== defender_move_frame_count
		and int(state_before["cutlass_damage_total"]) == cutlass_damage_total
		and int(state_before["morale_damage_total"])
			== defender_morale_damage_total
		and int(state_before["surrender_count"]) == defender_surrender_count
	)
	return {
		"success": false,
		"result": "NO_CUTLASS_DAMAGE",
		"rejection_reason": reason,
		"target_id": active_target_id,
		"morale_profile": defender_morale_profile,
		"defender_morale_max": defender_morale_max,
		"distance": distance_to_defender,
		"attack_range": PLAYER_CUTLASS_RANGE,
		"defender_health_before": state_before["defender_health"],
		"defender_health_after": defender_health,
		"defender_morale_before": state_before["defender_morale"],
		"defender_morale_after": defender_morale,
		"damage": 0,
		"morale_damage": 0,
		"defender_alive": defender_alive,
		"defender_surrendered": defender_surrendered,
		"fight_ended": fight_ended,
		"defender_position_before": defender_position_before,
		"defender_position_after": defender_local_position,
		"player_health_before": state_before["player_health"],
		"player_health_after": player_health,
		"cutlass_damage_total_before": state_before["cutlass_damage_total"],
		"cutlass_damage_total_after": cutlass_damage_total,
		"morale_damage_total_before": state_before["morale_damage_total"],
		"morale_damage_total_after": defender_morale_damage_total,
		"surrender_pose_count_before": (
			1 if bool(state_before["defender_surrendered"]) else 0
		),
		"surrender_pose_count_after": 1 if defender_surrendered else 0,
		"fight_outcome_before": (
			"SURRENDER"
			if bool(state_before["defender_surrendered"])
			else "DEFEAT" if not bool(state_before["defender_alive"]) else "ACTIVE"
		),
		"fight_outcome_after": (
			"SURRENDER"
			if defender_surrendered
			else "DEFEAT" if not defender_alive else "ACTIVE"
		),
		"no_state_change": no_state_change,
		"surrendered_defender_safe": (
			reason != "SURRENDERED" or no_state_change
		),
		"fresh_press_required": true,
	}


func get_entry_position() -> Vector2:
	return to_global(ENTRY_LOCAL_POSITION)


func get_return_position() -> Vector2:
	return to_global(RETURN_LOCAL_POSITION)


func get_defender_position() -> Vector2:
	return to_global(defender_local_position)


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
	var defender_position := get_defender_position()
	var defeat_path_evidence := _get_defeat_path_evidence()
	var player_defender_distance := player_position.distance_to(
		defender_position
	)
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
		"empty": false,
		"walk_rect": walk_rect,
		"entry_position": get_entry_position(),
		"return_position": get_return_position(),
		"return_range": RETURN_RANGE,
		"return_point_count": 1,
		"return_point_visible": active and visible,
		"player_near_return": is_player_near_return(player_position),
		"player_inside_bounds": is_player_inside_bounds(player_position),
		"walk_across_distance": WALK_ACROSS_DISTANCE,
		"combat_owner_count": 1,
		"on_foot_combat_system_count": 1,
		"combat_active": active and not fight_ended,
		"fight_ended": fight_ended,
		"defender_count": 1,
		"alive_defender_count": 1 if defender_alive else 0,
		"hostile_defender_count": (
			1 if defender_alive and not defender_surrendered else 0
		),
		"defender_position": defender_position,
		"defender_start_position": to_global(DEFENDER_START_LOCAL_POSITION),
		"player_position": player_position,
		"player_defender_distance": player_defender_distance,
		"player_health_max": PLAYER_HEALTH_MAX,
		"player_health_current": player_health,
		"defender_health_max": DEFENDER_HEALTH_MAX,
		"defender_health_current": defender_health,
		"defender_morale_profile": defender_morale_profile,
		"selected_morale_profile": defender_morale_profile,
		"selected_morale_capacity": defender_morale_max,
		"defender_morale_max": defender_morale_max,
		"defender_morale_current": defender_morale,
		"health_meter_count": 2,
		"health_meters_visible": active and visible,
		"player_health_meter_text": "PLAYER %d/%d" % [
			player_health,
			PLAYER_HEALTH_MAX,
		],
		"defender_health_meter_text": "DEFENDER %d/%d" % [
			defender_health,
			DEFENDER_HEALTH_MAX,
		],
		"morale_meter_text": "MORALE %d/%d" % [
			defender_morale,
			defender_morale_max,
		],
		"cutlass_system_count": 1,
		"cutlass_attack_type_count": 1,
		"cutlass_attack_type": "CUTLASS_SLASH",
		"cutlass_key": "SPACE",
		"cutlass_fresh_press_required": true,
		"cutlass_range": PLAYER_CUTLASS_RANGE,
		"cutlass_damage": CUTLASS_DAMAGE,
		"cutlass_attempt_count": cutlass_attempt_count,
		"cutlass_hit_count": cutlass_hit_count,
		"cutlass_out_of_range_count": cutlass_out_of_range_count,
		"cutlass_held_input_count": cutlass_held_input_count,
		"cutlass_cooldown_rejection_count": cutlass_cooldown_rejection_count,
		"cutlass_fight_ended_rejection_count": (
			cutlass_fight_ended_rejection_count
		),
		"cutlass_damage_total": cutlass_damage_total,
		"cutlass_cooldown_remaining": _cutlass_cooldown_remaining,
		"last_cutlass_evidence": last_cutlass_evidence.duplicate(true),
		"defender_attack_system_count": 1,
		"defender_attack_type_count": 1,
		"defender_attack_type": "CUTLASS_SLASH",
		"defender_attack_range": DEFENDER_ATTACK_RANGE,
		"defender_attack_damage": DEFENDER_ATTACK_DAMAGE,
		"defender_attack_cooldown": DEFENDER_ATTACK_COOLDOWN,
		"defender_chase_range": DEFENDER_CHASE_RANGE,
		"defender_move_speed": DEFENDER_MOVE_SPEED,
		"defender_move_frame_count": defender_move_frame_count,
		"defender_movement_distance": defender_movement_distance,
		"defender_entered_range_count": defender_entered_range_count,
		"defender_left_range_count": defender_left_range_count,
		"player_in_defender_attack_range": (
			defender_alive
			and not defender_surrendered
			and not fight_ended
			and player_defender_distance <= DEFENDER_ATTACK_RANGE
		),
		"defender_attack_count": defender_attack_count,
		"player_damage_total": player_damage_total,
		"last_defender_attack_evidence": last_defender_attack_evidence.duplicate(true),
		"player_damage_feedback_count": player_damage_feedback_count,
		"player_damage_feedback_visible": _player_feedback_remaining > 0.0,
		"player_damage_feedback_text": _player_feedback_text,
		"defender_damage_feedback_count": defender_damage_feedback_count,
		"defender_damage_feedback_visible": _defender_feedback_remaining > 0.0,
		"defender_damage_feedback_text": _defender_feedback_text,
		"fight_feedback_visible": active,
		"fight_feedback_text": _fight_feedback_text,
		"defender_defeat_count": defender_defeat_count,
		"defender_movement_stopped_after_defeat": (
			defender_defeat_count == 0 or not defender_alive
		),
		"defender_attacks_stopped_after_defeat": (
			defender_defeat_count == 0 or not defender_alive
		),
		"no_gore": true,
		"gore_effect_count": 0,
		"pistol_system_count": 0,
		"dodge_system_count": 0,
		"parry_system_count": 0,
		"officer_ability_system_count": 0,
		"surrender_system_count": 1,
		"surrender_owner_count": 1,
		"morale_owner_count": 1,
		"morale_meter_count": 1,
		"morale_meter_visible": active and visible,
		"morale_damage_per_cutlass_hit": CUTLASS_MORALE_DAMAGE,
		"morale_damage_total": defender_morale_damage_total,
		"last_morale_damage": defender_last_morale_damage,
		"morale_reduces_with_defender_damage": (
			cutlass_hit_count == 0
			or defender_morale_damage_total == cutlass_damage_total
		),
		"surrender_count": defender_surrender_count,
		"surrendered_defender_count": 1 if defender_surrendered else 0,
		"defender_surrendered": defender_surrendered,
		"defender_alive_at_surrender": defender_surrendered and defender_alive,
		"defender_health_above_zero_at_surrender": (
			defender_surrendered and defender_health > 0
		),
		"surrender_before_health_zero": (
			not defender_surrendered or defender_health > 0
		),
		"surrender_timing_exact": (
			not defender_surrendered
			or (
				active_target_id == COASTAL_MERCHANT_TARGET_ID
				and defender_morale_profile
					== "COASTAL_MERCHANT_SURRENDER"
				and defender_morale_max == COASTAL_MERCHANT_MORALE_MAX
				and defender_health == 1
				and defender_morale == 0
				and defender_surrender_count == 1
				and cutlass_hit_count == 2
			)
		),
		"surrender_route_target_id": COASTAL_MERCHANT_TARGET_ID,
		"surrender_route_morale_max": COASTAL_MERCHANT_MORALE_MAX,
		"defeat_path_target_id": NAVAL_COURIER_TARGET_ID,
		"defeat_path_morale_max": NAVAL_COURIER_MORALE_MAX,
		"defeat_path_available": bool(defeat_path_evidence["available"]),
		"defeat_path_contract_holds": bool(
			defeat_path_evidence["contract_holds"]
		),
		"defeat_path_evidence": defeat_path_evidence,
		"last_surrender_evidence": last_surrender_evidence.duplicate(true),
		"fight_outcome": (
			"SURRENDER"
			if defender_surrendered
			else "DEFEAT" if not defender_alive else "ACTIVE"
		),
		"surrender_pose_count": 1 if defender_surrendered else 0,
		"surrender_pose_visible": active and visible and defender_surrendered,
		"defender_weapon_visible": defender_alive and not defender_surrendered,
		"defender_weapon_disabled_after_surrender": (
			not defender_surrendered
			or (fight_ended and defender_alive and defender_surrendered)
		),
		"defender_movement_stopped_after_surrender": (
			not defender_surrendered
			or (
				defender_local_position == _defender_position_at_surrender
				and defender_move_frame_count
					== _defender_move_frame_count_at_surrender
			)
		),
		"defender_attacks_stopped_after_surrender": (
			not defender_surrendered
			or defender_attack_count == _defender_attack_count_at_surrender
		),
		"post_surrender_cutlass_rejection_count": (
			post_surrender_cutlass_rejection_count
		),
		"last_post_surrender_cutlass_evidence": (
			last_post_surrender_cutlass_evidence.duplicate(true)
		),
		"post_surrender_cutlass_no_state_change": bool(
			last_post_surrender_cutlass_evidence.get("no_state_change", false)
		),
		"execution_system_count": 0,
		"ransom_system_count": 0,
		"prisoner_system_count": 0,
		"crew_trading_system_count": 0,
		"prize_action_system_count": 0,
		"relationship_reaction_count": 0,
		"reward_system_count": 0,
		"ship_capture_system_count": 0,
		"heat_change_count": 0,
		"crew_injury_system_count": 0,
		"player_defeat_system_count": 0,
		"defeat_recovery_system_count": 0,
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
	_draw_health_meter(Vector2(-160.0, -80.0), player_health, PLAYER_HEALTH_MAX, "PLAYER")
	_draw_health_meter(Vector2(48.0, -80.0), defender_health, DEFENDER_HEALTH_MAX, "DEFENDER")
	_draw_morale_meter(Vector2(48.0, 68.0))
	if _player_feedback_remaining > 0.0:
		draw_arc(
			to_local(_last_player_position),
			24.0,
			0.0,
			TAU,
			24,
			Color("#fff1c5"),
			4.0,
		)
	_draw_defender()
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
		"BOARDING FIGHT · HULL %d · SAILS %d" % [active_hull, active_sails],
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
	draw_string(
		font,
		Vector2(-36.0, 128.0),
		_fight_feedback_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		220.0,
		15,
		Color("#fff1c5"),
	)


func _draw_health_meter(
	meter_position: Vector2,
	current_health: int,
	max_health: int,
	label: String,
) -> void:
	var meter_size := Vector2(112.0, 12.0)
	var fill_width := meter_size.x * float(current_health) / float(max_health)
	draw_rect(Rect2(meter_position, meter_size), Color("#162c33"), true)
	draw_rect(
		Rect2(meter_position, Vector2(fill_width, meter_size.y)),
		Color("#d05a43"),
		true,
	)
	draw_rect(Rect2(meter_position, meter_size), Color("#fff1c5"), false, 2.0)
	var font: Font = ThemeDB.fallback_font
	draw_string(
		font,
		meter_position + Vector2(0.0, -5.0),
		"%s %d/%d" % [label, current_health, max_health],
		HORIZONTAL_ALIGNMENT_CENTER,
		meter_size.x,
		13,
		Color("#fff1c5"),
	)


func _draw_morale_meter(meter_position: Vector2) -> void:
	var meter_size := Vector2(112.0, 10.0)
	var fill_width := (
		meter_size.x * float(defender_morale) / float(defender_morale_max)
	)
	draw_rect(Rect2(meter_position, meter_size), Color("#162c33"), true)
	draw_rect(
		Rect2(meter_position, Vector2(fill_width, meter_size.y)),
		Color("#e1bd4f"),
		true,
	)
	draw_rect(Rect2(meter_position, meter_size), Color("#fff1c5"), false, 2.0)
	var font: Font = ThemeDB.fallback_font
	draw_string(
		font,
		meter_position + Vector2(0.0, -4.0),
		"MORALE %d/%d" % [defender_morale, defender_morale_max],
		HORIZONTAL_ALIGNMENT_CENTER,
		meter_size.x,
		12,
		Color("#fff1c5"),
	)


func _draw_defender() -> void:
	if defender_surrendered:
		var font: Font = ThemeDB.fallback_font
		draw_circle(
			defender_local_position + Vector2(0.0, 13.0),
			12.0,
			Color("#12323c66"),
		)
		draw_circle(
			defender_local_position + Vector2(0.0, 4.0),
			15.0,
			Color("#567080"),
		)
		draw_circle(
			defender_local_position + Vector2(0.0, -8.0),
			9.0,
			Color("#c89b6d"),
		)
		draw_line(
			defender_local_position + Vector2(-8.0, -1.0),
			defender_local_position + Vector2(-17.0, -18.0),
			Color("#c89b6d"),
			4.0,
		)
		draw_line(
			defender_local_position + Vector2(8.0, -1.0),
			defender_local_position + Vector2(17.0, -18.0),
			Color("#c89b6d"),
			4.0,
		)
		draw_string(
			font,
			defender_local_position + Vector2(-56.0, 38.0),
			"SURRENDERED",
			HORIZONTAL_ALIGNMENT_CENTER,
			112.0,
			14,
			Color("#d9f6ee"),
		)
	elif defender_alive:
		draw_circle(
			defender_local_position + Vector2(0.0, 13.0),
			12.0,
			Color("#12323c66"),
		)
		draw_circle(defender_local_position, 15.0, Color("#3f6280"))
		draw_circle(
			defender_local_position + Vector2(0.0, -11.0),
			9.0,
			Color("#c89b6d"),
		)
		draw_line(
			defender_local_position + Vector2(12.0, -2.0),
			defender_local_position + Vector2(26.0, -14.0),
			Color("#e8eef0"),
			4.0,
		)
		if _defender_feedback_remaining > 0.0:
			draw_arc(
				defender_local_position,
				24.0,
				0.0,
				TAU,
				24,
				Color("#fff1c5"),
				4.0,
			)
	else:
		var font: Font = ThemeDB.fallback_font
		draw_circle(defender_local_position, 18.0, Color("#24313b"))
		draw_string(
			font,
			defender_local_position + Vector2(-44.0, 34.0),
			"DEFEATED",
			HORIZONTAL_ALIGNMENT_CENTER,
			88.0,
			14,
			Color("#d9f6ee"),
		)
