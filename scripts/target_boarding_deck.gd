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
const CUTLASS_DAMAGE := 1
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
var defender_local_position := DEFENDER_START_LOCAL_POSITION
var defender_alive := true
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
var last_cutlass_evidence: Dictionary = {}
var last_defender_attack_evidence: Dictionary = {}


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
	defender_local_position = DEFENDER_START_LOCAL_POSITION
	defender_alive = true
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
	last_cutlass_evidence = {}
	last_defender_attack_evidence = {}


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

	if defender_alive and not fight_ended:
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
	if not defender_alive:
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
	var defender_health_before := defender_health
	var distance_to_defender: float = player_position.distance_to(
		get_defender_position()
	)
	if echo or _cutlass_key_held:
		cutlass_held_input_count += 1
		last_cutlass_evidence = _make_cutlass_rejection_evidence(
			"HELD_KEY",
			distance_to_defender,
			defender_health_before,
		)
		return
	_cutlass_key_held = true
	cutlass_attempt_count += 1
	if fight_ended or not defender_alive:
		cutlass_fight_ended_rejection_count += 1
		last_cutlass_evidence = _make_cutlass_rejection_evidence(
			"FIGHT_ENDED",
			distance_to_defender,
			defender_health_before,
		)
		return
	if distance_to_defender > PLAYER_CUTLASS_RANGE:
		cutlass_out_of_range_count += 1
		_fight_feedback_text = "CUTLASS MISSED · MOVE CLOSER"
		_fight_feedback_remaining = COMBAT_FEEDBACK_DURATION
		last_cutlass_evidence = _make_cutlass_rejection_evidence(
			"OUT_OF_RANGE",
			distance_to_defender,
			defender_health_before,
		)
		queue_redraw()
		return
	if _cutlass_cooldown_remaining > 0.0:
		cutlass_cooldown_rejection_count += 1
		last_cutlass_evidence = _make_cutlass_rejection_evidence(
			"CUTLASS_RECOVERY",
			distance_to_defender,
			defender_health_before,
		)
		return

	defender_health = maxi(0, defender_health - CUTLASS_DAMAGE)
	var damage_done := defender_health_before - defender_health
	cutlass_hit_count += 1
	cutlass_damage_total += damage_done
	defender_damage_feedback_count += 1
	_cutlass_cooldown_remaining = PLAYER_CUTLASS_COOLDOWN
	_defender_feedback_remaining = COMBAT_FEEDBACK_DURATION
	_fight_feedback_remaining = COMBAT_FEEDBACK_DURATION
	_defender_feedback_text = "DEFENDER HIT · -%d HEALTH" % damage_done
	_fight_feedback_text = _defender_feedback_text
	if defender_health == 0:
		defender_alive = false
		fight_ended = true
		defender_defeat_count += 1
		_fight_feedback_text = "DEFENDER DEFEATED · FIGHT ENDED"
		_fight_feedback_remaining = COMBAT_FEEDBACK_DURATION * 3.0
	last_cutlass_evidence = {
		"success": true,
		"result": "DEFENDER_DEFEATED" if fight_ended else "DEFENDER_HIT",
		"attack_type": "CUTLASS_SLASH",
		"distance": distance_to_defender,
		"attack_range": PLAYER_CUTLASS_RANGE,
		"defender_health_before": defender_health_before,
		"defender_health_after": defender_health,
		"damage": damage_done,
		"defender_defeated": fight_ended,
		"clear_defender_damage_feedback": true,
		"fresh_press_required": true,
	}
	queue_redraw()


func _make_cutlass_rejection_evidence(
	reason: String,
	distance_to_defender: float,
	health_before: int,
) -> Dictionary:
	return {
		"success": false,
		"result": "NO_CUTLASS_DAMAGE",
		"rejection_reason": reason,
		"distance": distance_to_defender,
		"attack_range": PLAYER_CUTLASS_RANGE,
		"defender_health_before": health_before,
		"defender_health_after": defender_health,
		"damage": 0,
		"no_state_change": health_before == defender_health,
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
		"hostile_defender_count": 1 if defender_alive else 0,
		"defender_position": defender_position,
		"defender_start_position": to_global(DEFENDER_START_LOCAL_POSITION),
		"player_position": player_position,
		"player_defender_distance": player_defender_distance,
		"player_health_max": PLAYER_HEALTH_MAX,
		"player_health_current": player_health,
		"defender_health_max": DEFENDER_HEALTH_MAX,
		"defender_health_current": defender_health,
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
		"defender_movement_stopped_after_defeat": not fight_ended or not defender_alive,
		"defender_attacks_stopped_after_defeat": not fight_ended or not defender_alive,
		"no_gore": true,
		"gore_effect_count": 0,
		"pistol_system_count": 0,
		"dodge_system_count": 0,
		"parry_system_count": 0,
		"officer_ability_system_count": 0,
		"surrender_system_count": 0,
		"morale_meter_count": 0,
		"surrendered_defender_count": 0,
		"surrender_pose_count": 0,
		"prize_action_system_count": 0,
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


func _draw_defender() -> void:
	if defender_alive:
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
