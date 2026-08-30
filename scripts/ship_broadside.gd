extends RefCounted

const SIDE_LEFT := "LEFT"
const SIDE_RIGHT := "RIGHT"
const VALID_SIDES := [SIDE_LEFT, SIDE_RIGHT]
const ATTACK_HULL := "HULL"
const ATTACK_SAILS := "SAILS"
const ATTACK_CHOICES := [ATTACK_HULL, ATTACK_SAILS]
const HULL_DAMAGE := 25
const SAIL_DAMAGE := 25
const RELOAD_DURATION := 0.9
const SHOT_FLASH_DURATION := 0.28
const AREA_NEAR_X := 62.0
const AREA_FAR_X := 330.0
const AREA_HALF_LENGTH := 145.0

var reload_remaining := 0.0
var shot_flash_remaining := 0.0
var attempt_count := 0
var shot_count := 0
var hit_count := 0
var miss_count := 0
var reload_rejected_count := 0
var unavailable_rejected_count := 0
var no_ammunition_rejected_count := 0
var side_shot_counts: Dictionary = {
	SIDE_LEFT: 0,
	SIDE_RIGHT: 0,
}
var last_fired_side := "NONE"
var last_result := "NO BROADSIDE ATTEMPT"
var last_attempt_evidence: Dictionary = {}
var last_successful_evidence: Dictionary = {}
var last_reload_rejected_evidence: Dictionary = {}


func update_timers(delta: float) -> bool:
	var reload_was_active: bool = reload_remaining > 0.0
	var flash_was_active: bool = shot_flash_remaining > 0.0
	reload_remaining = maxf(0.0, reload_remaining - delta)
	shot_flash_remaining = maxf(0.0, shot_flash_remaining - delta)
	return (
		reload_was_active != (reload_remaining > 0.0)
		or flash_was_active != (shot_flash_remaining > 0.0)
	)


func attempt_fire(
	side: String,
	firing_areas_active: bool,
	ammunition_units: int,
) -> Dictionary:
	attempt_count += 1
	var normalized_side: String = side.to_upper()
	var reload_before: float = reload_remaining
	var shot_count_before: int = shot_count
	var base_evidence: Dictionary = {
		"action": "FIRE_%s_BROADSIDE" % normalized_side,
		"side": normalized_side,
		"valid_side": VALID_SIDES.has(normalized_side),
		"firing_areas_active": firing_areas_active,
		"reload_before": reload_before,
		"reload_duration": RELOAD_DURATION,
		"shot_count_before": shot_count_before,
		"hull_damage": HULL_DAMAGE,
		"sail_damage": SAIL_DAMAGE,
		"attack_choices": ATTACK_CHOICES.duplicate(),
		"ammunition_before": ammunition_units,
		"ammunition_after": ammunition_units,
		"ammunition_delta": 0,
		"ammunition_consumed": false,
		"uses_ammunition": true,
		"normal_ammunition_cost": 1,
		"same_cost_for_all_attack_choices": true,
	}
	if not VALID_SIDES.has(normalized_side):
		unavailable_rejected_count += 1
		last_result = "NO SHOT · INVALID BROADSIDE"
		return _record_rejected(base_evidence, "INVALID_SIDE")
	if not firing_areas_active:
		unavailable_rejected_count += 1
		last_result = "NO SHOT · BROADSIDE UNAVAILABLE"
		return _record_rejected(base_evidence, "FIRING_AREAS_INACTIVE")
	if reload_remaining > 0.0:
		reload_rejected_count += 1
		last_result = "NO SHOT · RELOADING %.1f SECONDS" % reload_remaining
		var reload_evidence: Dictionary = _record_rejected(
			base_evidence,
			"RELOADING",
		)
		last_reload_rejected_evidence = reload_evidence.duplicate(true)
		return reload_evidence
	if ammunition_units <= 0:
		no_ammunition_rejected_count += 1
		last_result = "NO SHOT · NO AMMUNITION"
		return _record_rejected(base_evidence, "NO_AMMUNITION")

	shot_count += 1
	side_shot_counts[normalized_side] = int(side_shot_counts[normalized_side]) + 1
	last_fired_side = normalized_side
	reload_remaining = RELOAD_DURATION
	shot_flash_remaining = SHOT_FLASH_DURATION
	last_result = "%s BROADSIDE FIRED" % normalized_side
	var evidence: Dictionary = base_evidence.duplicate(true)
	evidence.merge({
		"success": true,
		"shot_fired": true,
		"rejection_reason": "NONE",
		"reload_after": reload_remaining,
		"shot_count_after": shot_count,
		"shot_count_delta": shot_count - shot_count_before,
		"reload_started": is_equal_approx(
			reload_remaining,
			RELOAD_DURATION,
		),
		"ammunition_after": ammunition_units - 1,
		"ammunition_delta": -1,
		"ammunition_consumed": true,
		"result": last_result,
	})
	last_attempt_evidence = evidence.duplicate(true)
	return evidence


func record_shot_result(result_evidence: Dictionary) -> Dictionary:
	if not bool(result_evidence.get("shot_fired", false)):
		last_attempt_evidence = result_evidence.duplicate(true)
		if String(result_evidence.get("rejection_reason", "")) == "RELOADING":
			last_reload_rejected_evidence = result_evidence.duplicate(true)
		return last_attempt_evidence.duplicate(true)
	if bool(result_evidence.get("target_hit", false)):
		hit_count += 1
		var attack_choice := String(
			result_evidence.get("attack_choice", ATTACK_HULL)
		)
		if bool(result_evidence.get("target_disabled", false)):
			last_result = "%s DISABLED %s · HULL 0/%d" % [
				result_evidence.get("side", "UNKNOWN"),
				result_evidence.get("target_name", "TARGET"),
				result_evidence.get("target_hull_max", 0),
			]
		elif attack_choice == ATTACK_SAILS:
			last_result = "%s HIT %s · -%d SAILS · SAILS %d/%d · SPEED %.0f" % [
				result_evidence.get("side", "UNKNOWN"),
				result_evidence.get("target_name", "TARGET"),
				SAIL_DAMAGE,
				result_evidence.get("target_sail_after", 0),
				result_evidence.get("target_sail_max", 0),
				result_evidence.get("target_speed_after", 0.0),
			]
		else:
			last_result = "%s HIT %s · -%d · HULL %d/%d" % [
				result_evidence.get("side", "UNKNOWN"),
				result_evidence.get("target_name", "TARGET"),
				HULL_DAMAGE,
				result_evidence.get("target_hull_after", 0),
				result_evidence.get("target_hull_max", 0),
			]
	else:
		miss_count += 1
		last_result = "%s BROADSIDE MISSED" % (
			result_evidence.get("side", "UNKNOWN")
		)
	result_evidence["result"] = last_result
	result_evidence["total_hit_count"] = hit_count
	result_evidence["total_miss_count"] = miss_count
	last_attempt_evidence = result_evidence.duplicate(true)
	last_successful_evidence = result_evidence.duplicate(true)
	return last_attempt_evidence.duplicate(true)


func get_local_area_corners(side: String) -> PackedVector2Array:
	if side == SIDE_LEFT:
		return PackedVector2Array([
			Vector2(-AREA_NEAR_X, -AREA_HALF_LENGTH),
			Vector2(-AREA_FAR_X, -AREA_HALF_LENGTH),
			Vector2(-AREA_FAR_X, AREA_HALF_LENGTH),
			Vector2(-AREA_NEAR_X, AREA_HALF_LENGTH),
		])
	return PackedVector2Array([
		Vector2(AREA_NEAR_X, -AREA_HALF_LENGTH),
		Vector2(AREA_FAR_X, -AREA_HALF_LENGTH),
		Vector2(AREA_FAR_X, AREA_HALF_LENGTH),
		Vector2(AREA_NEAR_X, AREA_HALF_LENGTH),
	])


func is_local_point_in_area(side: String, local_point: Vector2) -> bool:
	if absf(local_point.y) > AREA_HALF_LENGTH:
		return false
	if side == SIDE_LEFT:
		return local_point.x <= -AREA_NEAR_X and local_point.x >= -AREA_FAR_X
	if side == SIDE_RIGHT:
		return local_point.x >= AREA_NEAR_X and local_point.x <= AREA_FAR_X
	return false


func get_playtest_state() -> Dictionary:
	return {
		"system_count": 1,
		"left_side": SIDE_LEFT,
		"right_side": SIDE_RIGHT,
		"valid_sides": VALID_SIDES.duplicate(),
		"attack_choices": ATTACK_CHOICES.duplicate(),
		"attack_choice_count": ATTACK_CHOICES.size(),
		"hull_damage": HULL_DAMAGE,
		"sail_damage": SAIL_DAMAGE,
		"reload_duration": RELOAD_DURATION,
		"reload_remaining": reload_remaining,
		"ready": is_zero_approx(reload_remaining),
		"shot_flash_duration": SHOT_FLASH_DURATION,
		"shot_flash_remaining": shot_flash_remaining,
		"shot_flash_active": shot_flash_remaining > 0.0,
		"area_near_x": AREA_NEAR_X,
		"area_far_x": AREA_FAR_X,
		"area_half_length": AREA_HALF_LENGTH,
		"left_local_corners": get_local_area_corners(SIDE_LEFT),
		"right_local_corners": get_local_area_corners(SIDE_RIGHT),
		"attempt_count": attempt_count,
		"shot_count": shot_count,
		"hit_count": hit_count,
		"miss_count": miss_count,
		"reload_rejected_count": reload_rejected_count,
		"unavailable_rejected_count": unavailable_rejected_count,
		"no_ammunition_rejected_count": no_ammunition_rejected_count,
		"last_fired_side": last_fired_side,
		"left_shot_count": int(side_shot_counts[SIDE_LEFT]),
		"right_shot_count": int(side_shot_counts[SIDE_RIGHT]),
		"side_shot_counts": side_shot_counts.duplicate(),
		"last_result": last_result,
		"last_attempt_evidence": last_attempt_evidence.duplicate(true),
		"last_successful_evidence": last_successful_evidence.duplicate(true),
		"last_reload_rejected_evidence": (
			last_reload_rejected_evidence.duplicate(true)
		),
		"uses_ammunition": true,
		"normal_ammunition_cost": 1,
		"same_cost_for_all_attack_choices": true,
		"sail_damage_system_count": 1,
		"boarding_system_count": 0,
		"prize_action_system_count": 0,
		"heat_change_system_count": 0,
	}


func _record_rejected(
	base_evidence: Dictionary,
	reason: String,
) -> Dictionary:
	var evidence: Dictionary = base_evidence.duplicate(true)
	evidence.merge({
		"success": false,
		"shot_fired": false,
		"rejection_reason": reason,
		"reload_after": reload_remaining,
		"shot_count_after": shot_count,
		"shot_count_delta": 0,
		"reload_started": false,
		"target_hit": false,
		"target_hull_delta": 0,
		"target_sail_delta": 0,
		"target_speed_delta": 0.0,
		"result": last_result,
	})
	last_attempt_evidence = evidence.duplicate(true)
	return evidence
