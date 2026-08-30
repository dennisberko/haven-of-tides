class_name ShipDamageState
extends RefCounted

const HULL_MAX := 100
const HULL_START := 100
const REEF_HIT_DAMAGE := 20
const FIXED_REPAIR_AMOUNT := 20
const HIT_COOLDOWN_DURATION := 1.0
const DAMAGE_FLASH_DURATION := 0.45
const IMPACT_SOUND_DURATION := 0.18
const REEF_COLLISION_SOURCE := "REEF"
const REEF_COLLISION_RESPONSE := "REEF_HIT_STOP"
const PIRATE_HUNTER_SOURCE := "PIRATE_HUNTER_BROADSIDE"
const PIRATE_HUNTER_HIT_DAMAGE := 20
const PIRATE_HUNTER_HULL_FLOOR := 0
const MONSTER_ATTACK_SOURCE := "BLACKWAKE_LEVIATHAN_CRUSHING_STRIKE"
const MONSTER_ATTACK_DAMAGE := PIRATE_HUNTER_HIT_DAMAGE
const MONSTER_ATTACK_HULL_FLOOR := 0
const DEFEAT_HULL_THRESHOLD := 0

var _hull_condition := HULL_START
var _hit_count := 0
var _contact_active := false
var _contact_clear_count := 0
var _repeated_contact_blocked_count := 0
var _cooldown_blocked_count := 0
var _cooldown_remaining := 0.0
var _flash_remaining := 0.0
var _flash_count := 0
var _sound_play_count := 0
var _sound_stream_kind := "NONE"
var _sound_duration := 0.0
var _repair_count := 0
var _total_hull_restored := 0
var _last_damage_event: Dictionary = {}
var _last_blocked_contact_evidence: Dictionary = {}
var _last_contact_clear_evidence: Dictionary = {}
var _last_repair_evidence: Dictionary = {}
var _pirate_hunter_hit_count := 0
var _pirate_hunter_blocked_hit_count := 0
var _last_pirate_hunter_hit_evidence: Dictionary = {}
var _monster_attack_hit_count := 0
var _monster_attack_blocked_hit_count := 0
var _last_monster_attack_hit_evidence: Dictionary = {}


func update_timers(delta: float) -> void:
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
	_flash_remaining = maxf(0.0, _flash_remaining - delta)


func try_reef_hit(
		cargo_snapshot: Array[String],
		food_progress: float,
		food_units: int,
) -> bool:
	if _contact_active:
		_repeated_contact_blocked_count += 1
		_record_blocked_contact(
			"CONTINUOUS_CONTACT_LATCH",
			cargo_snapshot,
			food_progress,
			food_units,
		)
		return false

	_contact_active = true
	if _cooldown_remaining > 0.0:
		_cooldown_blocked_count += 1
		_record_blocked_contact(
			"HIT_COOLDOWN",
			cargo_snapshot,
			food_progress,
			food_units,
		)
		return false

	var hull_before := _hull_condition
	_hull_condition = clampi(
		_hull_condition - REEF_HIT_DAMAGE,
		0,
		HULL_MAX,
	)
	_hit_count += 1
	_cooldown_remaining = HIT_COOLDOWN_DURATION
	_flash_remaining = DAMAGE_FLASH_DURATION
	_flash_count += 1
	_last_damage_event = {
		"event_count": _hit_count,
		"source": REEF_COLLISION_SOURCE,
		"collision_response": REEF_COLLISION_RESPONSE,
		"damage": hull_before - _hull_condition,
		"fixed_damage": REEF_HIT_DAMAGE,
		"hull_before": hull_before,
		"hull_after": _hull_condition,
		"cargo_before": cargo_snapshot.duplicate(),
		"cargo_after": cargo_snapshot.duplicate(),
		"cargo_unchanged": true,
		"food_progress_before": food_progress,
		"food_progress_after": food_progress,
		"food_progress_unchanged": true,
		"food_units_before": food_units,
		"food_units_after": food_units,
		"food_units_unchanged": true,
		"contact_latched": true,
		"cooldown_started": HIT_COOLDOWN_DURATION,
		"flash_started": DAMAGE_FLASH_DURATION,
	}
	return true


func try_pirate_hunter_hit(
		cargo_snapshot: Array[String],
		food_progress: float,
		food_units: int,
) -> Dictionary:
	var hull_before := _hull_condition
	if hull_before <= PIRATE_HUNTER_HULL_FLOOR:
		_pirate_hunter_blocked_hit_count += 1
		_last_pirate_hunter_hit_evidence = {
			"success": false,
			"result": "HUNTER HIT BLOCKED · SHIP ALREADY DEFEATED",
			"source": PIRATE_HUNTER_SOURCE,
			"fixed_damage": PIRATE_HUNTER_HIT_DAMAGE,
			"hull_floor": PIRATE_HUNTER_HULL_FLOOR,
			"defeat_hull_threshold": DEFEAT_HULL_THRESHOLD,
			"hull_before": hull_before,
			"hull_after": _hull_condition,
			"hull_delta": 0,
			"damage": 0,
			"defeated_before": hull_before <= DEFEAT_HULL_THRESHOLD,
			"defeated_after": _hull_condition <= DEFEAT_HULL_THRESHOLD,
			"fixed_existing_hull_owner_used": true,
			"cargo_unchanged": true,
			"food_progress_unchanged": true,
			"food_units_unchanged": true,
			"no_state_change": true,
		}
		return _last_pirate_hunter_hit_evidence.duplicate(true)

	_hull_condition = maxi(
		PIRATE_HUNTER_HULL_FLOOR,
		_hull_condition - PIRATE_HUNTER_HIT_DAMAGE,
	)
	var defeat_triggered := (
		hull_before > DEFEAT_HULL_THRESHOLD
		and _hull_condition <= DEFEAT_HULL_THRESHOLD
	)
	_pirate_hunter_hit_count += 1
	_flash_remaining = DAMAGE_FLASH_DURATION
	_flash_count += 1
	_last_pirate_hunter_hit_evidence = {
		"success": true,
		"result": "HUNTER BROADSIDE HIT · -%d HULL" % (
			hull_before - _hull_condition
		),
		"source": PIRATE_HUNTER_SOURCE,
		"fixed_damage": PIRATE_HUNTER_HIT_DAMAGE,
		"hull_floor": PIRATE_HUNTER_HULL_FLOOR,
		"defeat_hull_threshold": DEFEAT_HULL_THRESHOLD,
		"hull_before": hull_before,
		"hull_after": _hull_condition,
		"hull_delta": _hull_condition - hull_before,
		"damage": hull_before - _hull_condition,
		"defeated_before": hull_before <= DEFEAT_HULL_THRESHOLD,
		"defeated_after": _hull_condition <= DEFEAT_HULL_THRESHOLD,
		"fixed_existing_hull_owner_used": true,
		"cargo_before": cargo_snapshot.duplicate(),
		"cargo_after": cargo_snapshot.duplicate(),
		"cargo_unchanged": true,
		"food_progress_before": food_progress,
		"food_progress_after": food_progress,
		"food_progress_unchanged": true,
		"food_units_before": food_units,
		"food_units_after": food_units,
		"food_units_unchanged": true,
		"crew_condition_changed": false,
		"phase_33_defeat_triggered": defeat_triggered,
	}
	return _last_pirate_hunter_hit_evidence.duplicate(true)


func try_monster_attack(
		cargo_snapshot: Array[String],
		food_progress: float,
		food_units: int,
) -> Dictionary:
	var hull_before := _hull_condition
	if hull_before <= MONSTER_ATTACK_HULL_FLOOR:
		_monster_attack_blocked_hit_count += 1
		_last_monster_attack_hit_evidence = {
			"success": false,
			"result": "MONSTER ATTACK BLOCKED · SHIP ALREADY DEFEATED",
			"source": MONSTER_ATTACK_SOURCE,
			"fixed_damage": MONSTER_ATTACK_DAMAGE,
			"hull_floor": MONSTER_ATTACK_HULL_FLOOR,
			"hull_before": hull_before,
			"hull_after": _hull_condition,
			"hull_delta": 0,
			"damage": 0,
			"fixed_existing_hull_owner_used": true,
			"cargo_unchanged": true,
			"food_progress_unchanged": true,
			"food_units_unchanged": true,
			"no_state_change": true,
		}
		return _last_monster_attack_hit_evidence.duplicate(true)

	_hull_condition = maxi(
		MONSTER_ATTACK_HULL_FLOOR,
		_hull_condition - MONSTER_ATTACK_DAMAGE,
	)
	_monster_attack_hit_count += 1
	_flash_remaining = DAMAGE_FLASH_DURATION
	_flash_count += 1
	_last_monster_attack_hit_evidence = {
		"success": true,
		"result": "MONSTER CRUSHING STRIKE · -%d HULL" % (
			hull_before - _hull_condition
		),
		"source": MONSTER_ATTACK_SOURCE,
		"fixed_damage": MONSTER_ATTACK_DAMAGE,
		"hull_floor": MONSTER_ATTACK_HULL_FLOOR,
		"hull_before": hull_before,
		"hull_after": _hull_condition,
		"hull_delta": _hull_condition - hull_before,
		"damage": hull_before - _hull_condition,
		"fixed_existing_hull_owner_used": true,
		"cargo_before": cargo_snapshot.duplicate(),
		"cargo_after": cargo_snapshot.duplicate(),
		"cargo_unchanged": true,
		"food_progress_before": food_progress,
		"food_progress_after": food_progress,
		"food_progress_unchanged": true,
		"food_units_before": food_units,
		"food_units_after": food_units,
		"food_units_unchanged": true,
		"crew_condition_changed": false,
		"phase_33_defeat_triggered": (
			hull_before > DEFEAT_HULL_THRESHOLD
			and _hull_condition <= DEFEAT_HULL_THRESHOLD
		),
	}
	return _last_monster_attack_hit_evidence.duplicate(true)


func clear_contact_after_movement_away(
		actual_distance: float,
		distance_before: float,
		distance_after: float,
		collision_clearance: float,
) -> bool:
	if (
		not _contact_active
		or actual_distance <= 0.0
		or distance_after <= collision_clearance
		or distance_after <= distance_before
	):
		return false

	_contact_active = false
	_contact_clear_count += 1
	_last_contact_clear_evidence = {
		"clear_count": _contact_clear_count,
		"actual_movement_distance": actual_distance,
		"distance_before": distance_before,
		"distance_after": distance_after,
		"collision_clearance": collision_clearance,
		"moved_away": true,
	}
	return true


func record_sound_play(stream_kind: String, duration: float) -> void:
	_sound_play_count += 1
	_sound_stream_kind = stream_kind
	_sound_duration = duration
	if not _last_damage_event.is_empty():
		_last_damage_event["sound_played"] = true
		_last_damage_event["sound_play_count"] = _sound_play_count
		_last_damage_event["sound_stream_kind"] = _sound_stream_kind
		_last_damage_event["sound_duration"] = _sound_duration


func record_pirate_hunter_sound_play(
	stream_kind: String,
	duration: float,
) -> void:
	_sound_play_count += 1
	_sound_stream_kind = stream_kind
	_sound_duration = duration
	if not _last_pirate_hunter_hit_evidence.is_empty():
		_last_pirate_hunter_hit_evidence["sound_played"] = true
		_last_pirate_hunter_hit_evidence["sound_play_count"] = (
			_sound_play_count
		)
		_last_pirate_hunter_hit_evidence["sound_stream_kind"] = (
			_sound_stream_kind
		)
		_last_pirate_hunter_hit_evidence["sound_duration"] = _sound_duration


func record_monster_attack_sound_play(
	stream_kind: String,
	duration: float,
) -> void:
	_sound_play_count += 1
	_sound_stream_kind = stream_kind
	_sound_duration = duration
	if not _last_monster_attack_hit_evidence.is_empty():
		_last_monster_attack_hit_evidence["sound_played"] = true
		_last_monster_attack_hit_evidence["sound_play_count"] = (
			_sound_play_count
		)
		_last_monster_attack_hit_evidence["sound_stream_kind"] = (
			_sound_stream_kind
		)
		_last_monster_attack_hit_evidence["sound_duration"] = _sound_duration


func record_pirate_hunter_crew_result(combat_evidence: Dictionary) -> void:
	if _last_pirate_hunter_hit_evidence.is_empty():
		return
	for key in [
		"crew_condition_before",
		"crew_condition_after",
		"crew_condition_changed",
		"crew_injury_applied",
		"crew_injury_threshold",
		"crew_injury_threshold_reached",
		"crew_hits_toward_next_injury",
		"sailing_top_speed_before",
		"sailing_top_speed_after",
		"phase_33_defeat_triggered",
	]:
		_last_pirate_hunter_hit_evidence[key] = combat_evidence.get(key)


func record_monster_attack_crew_result(combat_evidence: Dictionary) -> void:
	if _last_monster_attack_hit_evidence.is_empty():
		return
	for key in [
		"crew_condition_before",
		"crew_condition_after",
		"crew_condition_changed",
		"crew_injury_applied",
		"crew_fixed_injury_amount",
		"sailing_top_speed_before",
		"sailing_top_speed_after",
		"phase_33_defeat_triggered",
	]:
		_last_monster_attack_hit_evidence[key] = combat_evidence.get(key)


func configure_sound(stream_kind: String, duration: float) -> void:
	_sound_stream_kind = stream_kind
	_sound_duration = duration


func is_flash_active() -> bool:
	return _flash_remaining > 0.0


func get_hull_condition() -> int:
	return _hull_condition


func apply_fixed_repair() -> Dictionary:
	var hull_before := _hull_condition
	var hit_count_before := _hit_count
	var repair_count_before := _repair_count
	if hull_before >= HULL_MAX:
		return {
			"success": false,
			"result": "HULL_IS_FULL",
			"fixed_repair_amount": FIXED_REPAIR_AMOUNT,
			"hull_before": hull_before,
			"hull_after": _hull_condition,
			"hull_restored": 0,
			"hit_count_before": hit_count_before,
			"hit_count_after": _hit_count,
			"repair_count_before": repair_count_before,
			"repair_count_after": _repair_count,
			"no_state_change": true,
		}

	_hull_condition = mini(
		HULL_MAX,
		_hull_condition + FIXED_REPAIR_AMOUNT,
	)
	var hull_restored := _hull_condition - hull_before
	_repair_count += 1
	_total_hull_restored += hull_restored
	_last_repair_evidence = {
		"success": true,
		"result": "HULL_REPAIRED",
		"fixed_repair_amount": FIXED_REPAIR_AMOUNT,
		"hull_before": hull_before,
		"hull_after": _hull_condition,
		"hull_restored": hull_restored,
		"hull_capped_at_max": _hull_condition == HULL_MAX,
		"hit_count_before": hit_count_before,
		"hit_count_after": _hit_count,
		"hit_state_unchanged": hit_count_before == _hit_count,
		"repair_count_before": repair_count_before,
		"repair_count_after": _repair_count,
		"one_repair_recorded": _repair_count == repair_count_before + 1,
	}
	return _last_repair_evidence.duplicate(true)


func get_playtest_state() -> Dictionary:
	return {
		"owner_count": 1,
		"hull_current": _hull_condition,
		"hull_max": HULL_MAX,
		"hull_start": HULL_START,
		"reef_hit_damage": REEF_HIT_DAMAGE,
		"hit_count": _hit_count,
		"last_damage_event": _last_damage_event.duplicate(true),
		"contact_active": _contact_active,
		"contact_clear_count": _contact_clear_count,
		"last_contact_clear_evidence": (
			_last_contact_clear_evidence.duplicate(true)
		),
		"repeated_contact_blocked_count": (
			_repeated_contact_blocked_count
		),
		"cooldown_blocked_count": _cooldown_blocked_count,
		"last_blocked_contact_evidence": (
			_last_blocked_contact_evidence.duplicate(true)
		),
		"cooldown_duration": HIT_COOLDOWN_DURATION,
		"cooldown_remaining": _cooldown_remaining,
		"flash_active": is_flash_active(),
		"flash_count": _flash_count,
		"flash_duration": DAMAGE_FLASH_DURATION,
		"flash_remaining": _flash_remaining,
		"sound_play_count": _sound_play_count,
		"sound_stream_kind": _sound_stream_kind,
		"sound_duration": _sound_duration,
		"collision_source": REEF_COLLISION_SOURCE,
		"collision_response": REEF_COLLISION_RESPONSE,
		"fixed_repair_amount": FIXED_REPAIR_AMOUNT,
		"repair_count": _repair_count,
		"total_hull_restored": _total_hull_restored,
		"last_repair_evidence": _last_repair_evidence.duplicate(true),
		"continuous_contact_requires_exit": true,
		"contact_reset_requires_actual_movement_away": true,
		"has_defeat_behavior": false,
		"supports_defeat_threshold": true,
		"has_recovery_behavior": false,
		"has_repair_behavior": true,
		"repair_changes_hit_state": false,
		"repair_resets_contact_latch": false,
		"repair_resets_cooldown": false,
		"pirate_hunter_source": PIRATE_HUNTER_SOURCE,
		"pirate_hunter_fixed_damage": PIRATE_HUNTER_HIT_DAMAGE,
		"pirate_hunter_hull_floor": PIRATE_HUNTER_HULL_FLOOR,
		"defeat_hull_threshold": DEFEAT_HULL_THRESHOLD,
		"pirate_hunter_hit_count": _pirate_hunter_hit_count,
		"pirate_hunter_blocked_hit_count": (
			_pirate_hunter_blocked_hit_count
		),
		"last_pirate_hunter_hit_evidence": (
			_last_pirate_hunter_hit_evidence.duplicate(true)
		),
		"pirate_hunter_uses_existing_hull_owner": true,
		"monster_attack_source": MONSTER_ATTACK_SOURCE,
		"monster_attack_fixed_damage": MONSTER_ATTACK_DAMAGE,
		"monster_attack_hull_floor": MONSTER_ATTACK_HULL_FLOOR,
		"monster_attack_hit_count": _monster_attack_hit_count,
		"monster_attack_blocked_hit_count": (
			_monster_attack_blocked_hit_count
		),
		"last_monster_attack_hit_evidence": (
			_last_monster_attack_hit_evidence.duplicate(true)
		),
		"monster_attack_uses_existing_hull_owner": true,
		"crew_injury_system_count": 1,
	}


func _record_blocked_contact(
		reason: String,
		cargo_snapshot: Array[String],
		food_progress: float,
		food_units: int,
) -> void:
	_last_blocked_contact_evidence = {
		"reason": reason,
		"source": REEF_COLLISION_SOURCE,
		"collision_response": REEF_COLLISION_RESPONSE,
		"cargo_before": cargo_snapshot.duplicate(),
		"cargo_after": cargo_snapshot.duplicate(),
		"cargo_unchanged": true,
		"food_progress_before": food_progress,
		"food_progress_after": food_progress,
		"food_progress_unchanged": true,
		"food_units_before": food_units,
		"food_units_after": food_units,
		"food_units_unchanged": true,
		"cooldown_remaining": _cooldown_remaining,
		"contact_latched": _contact_active,
	}
