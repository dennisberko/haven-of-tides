class_name FishingArea
extends Node2D

const AREA_ID := "shoal_fishing_area"
const FISH_LOT_NAME := "FISH LOT"
const FISH_PRICE_STATE := "NORMAL"
const FISHING_RANGE := 155.0
const FISHING_MAX_SPEED := 0.1
const VISUAL_RADIUS := 132.0
const SAILING_VIEWPORT_SIZE := Vector2(1152.0, 648.0)
const VISUAL_LOCAL_BOUNDS := Rect2(-170.0, -190.0, 340.0, 360.0)

var _ship_position := Vector2.ZERO
var _ship_speed := 0.0
var _ship_distance := INF
var _player_aboard_ship := false
var _captain_aboard := false
var _sailing_view_active := false
var _input_available := false
var _fishing_eligible := false
var _visual_on_screen := false
var _sailing_viewport_world_rect := Rect2()
var _catch_attempt_count := 0
var _successful_catch_count := 0
var _direct_keep_count := 0
var _choice_required_count := 0
var _discarded_catch_count := 0
var _replacement_keep_count := 0
var _displaced_cargo_discard_count := 0
var _held_input_count := 0
var _pending_catch_count := 0
var _last_catch_result := "NOT_ATTEMPTED"
var _last_catch_evidence: Dictionary = {}
var _last_choice_evidence: Dictionary = {}
var _last_held_input_evidence: Dictionary = {}
var _pending_cargo_snapshot: Array[String] = []


func _ready() -> void:
	hide()
	queue_redraw()


func update_state(
	ship_position: Vector2,
	ship_speed: float,
	player_aboard_ship: bool,
	captain_aboard: bool,
	sailing_view_active: bool,
	input_available: bool,
) -> void:
	_ship_position = ship_position
	_ship_speed = ship_speed
	_player_aboard_ship = player_aboard_ship
	_captain_aboard = captain_aboard
	_sailing_view_active = sailing_view_active
	_input_available = input_available
	_ship_distance = _ship_position.distance_to(global_position)
	_sailing_viewport_world_rect = Rect2(
		_ship_position - SAILING_VIEWPORT_SIZE * 0.5,
		SAILING_VIEWPORT_SIZE,
	)
	_visual_on_screen = (
		_sailing_view_active
		and _sailing_viewport_world_rect.intersects(
			Rect2(
				global_position + VISUAL_LOCAL_BOUNDS.position,
				VISUAL_LOCAL_BOUNDS.size,
			),
			true,
		)
	)
	_fishing_eligible = (
		_player_aboard_ship
		and _captain_aboard
		and _ship_distance <= FISHING_RANGE
		and absf(_ship_speed) <= FISHING_MAX_SPEED
		and _input_available
		and _pending_catch_count == 0
	)
	visible = _sailing_view_active


func is_fishing_eligible() -> bool:
	return _fishing_eligible


func can_receive_fishing_press() -> bool:
	return _fishing_eligible


func has_pending_catch() -> bool:
	return _pending_catch_count == 1


func get_interaction_prompt() -> String:
	if (
		not _sailing_view_active
		or not _player_aboard_ship
		or _ship_distance > FISHING_RANGE
		or not _input_available
		or _pending_catch_count > 0
	):
		return ""
	if not _captain_aboard:
		return "CAPTAIN MUST BE ABOARD TO FISH"
	if absf(_ship_speed) > FISHING_MAX_SPEED:
		return "STOP SHIP TO FISH"
	return "[E] CATCH ONE FISH LOT"


func try_catch_fish_lot(cargo_before: Array[String]) -> String:
	_catch_attempt_count += 1
	if not _fishing_eligible or _pending_catch_count > 0:
		_last_catch_result = "NO_CHANGE_INELIGIBLE"
		_last_catch_evidence = {
			"success": false,
			"result": _last_catch_result,
			"cargo_before": cargo_before.duplicate(),
			"cargo_after": cargo_before.duplicate(),
			"cargo_unchanged": true,
			"fresh_press_required": true,
		}
		return ""

	_successful_catch_count += 1
	_pending_catch_count = 1
	_pending_cargo_snapshot = cargo_before.duplicate()
	_last_catch_result = "CAUGHT_ONE_FISH_LOT"
	_last_catch_evidence = {
		"success": true,
		"result": _last_catch_result,
		"fish_lot_name": FISH_LOT_NAME,
		"cargo_before": cargo_before.duplicate(),
		"fresh_press_required": true,
		"generated_lot_count": 1,
	}
	return FISH_LOT_NAME


func record_held_press(cargo_lots: Array[String]) -> void:
	_held_input_count += 1
	_last_catch_result = "NO_CHANGE_HELD_INPUT"
	_last_held_input_evidence = {
		"result": _last_catch_result,
		"cargo_before": cargo_lots.duplicate(),
		"cargo_after": cargo_lots.duplicate(),
		"cargo_unchanged": true,
		"successful_catch_count_before": _successful_catch_count,
		"successful_catch_count_after": _successful_catch_count,
		"fresh_press_required": true,
	}


func resolve_direct_keep(cargo_after: Array[String]) -> bool:
	if not has_pending_catch():
		return false
	_pending_catch_count = 0
	_direct_keep_count += 1
	_last_catch_result = "KEPT_ONE_FISH_LOT"
	_last_catch_evidence.merge({
		"resolution": "DIRECT_KEEP",
		"cargo_after": cargo_after.duplicate(),
		"cargo_delta": cargo_after.size() - _pending_cargo_snapshot.size(),
		"fish_count_delta": (
			cargo_after.count(FISH_LOT_NAME)
			- _pending_cargo_snapshot.count(FISH_LOT_NAME)
		),
		"one_normal_cargo_slot_added": (
			cargo_after.size() == _pending_cargo_snapshot.size() + 1
			and cargo_after.count(FISH_LOT_NAME)
				== _pending_cargo_snapshot.count(FISH_LOT_NAME) + 1
		),
	}, true)
	_pending_cargo_snapshot.clear()
	return true


func record_choice_required() -> bool:
	if not has_pending_catch():
		return false
	_choice_required_count += 1
	_last_catch_result = "CARGO_CHOICE_REQUIRED_FISH_LOT"
	_last_choice_evidence = {
		"resolution": "PENDING",
		"result": _last_catch_result,
		"pending_lot": FISH_LOT_NAME,
		"cargo_before": _pending_cargo_snapshot.duplicate(),
		"cargo_after": _pending_cargo_snapshot.duplicate(),
		"cargo_unchanged_before_choice": true,
	}
	return true


func resolve_discard(cargo_after: Array[String]) -> bool:
	if not has_pending_catch():
		return false
	_pending_catch_count = 0
	_discarded_catch_count += 1
	_last_catch_result = "DISCARDED_FISH_LOT"
	_last_choice_evidence = {
		"resolution": "DISCARD_NEW_FISH",
		"result": _last_catch_result,
		"cargo_before": _pending_cargo_snapshot.duplicate(),
		"cargo_after": cargo_after.duplicate(),
		"cargo_unchanged": cargo_after == _pending_cargo_snapshot,
		"state_loss": cargo_after != _pending_cargo_snapshot,
	}
	_pending_cargo_snapshot.clear()
	return true


func resolve_replacement(
	discarded_lot: String,
	cargo_after: Array[String],
) -> bool:
	if not has_pending_catch() or discarded_lot.is_empty():
		return false
	_pending_catch_count = 0
	_replacement_keep_count += 1
	_displaced_cargo_discard_count += 1
	_last_catch_result = "KEPT_FISH_BY_REPLACING_%s" % _result_name(
		discarded_lot
	)
	_last_choice_evidence = {
		"resolution": "REPLACE_CARGO_SLOT",
		"result": _last_catch_result,
		"discarded_lot": discarded_lot,
		"kept_lot": FISH_LOT_NAME,
		"cargo_before": _pending_cargo_snapshot.duplicate(),
		"cargo_after": cargo_after.duplicate(),
		"cargo_slot_count_unchanged": (
			cargo_after.size() == _pending_cargo_snapshot.size()
		),
		"fish_kept": (
			cargo_after.count(FISH_LOT_NAME)
				== _pending_cargo_snapshot.count(FISH_LOT_NAME) + 1
		),
	}
	_pending_cargo_snapshot.clear()
	return true


func get_playtest_state() -> Dictionary:
	var visual_world_rect := Rect2(
		global_position + VISUAL_LOCAL_BOUNDS.position,
		VISUAL_LOCAL_BOUNDS.size,
	)
	return {
		"system_count": 1,
		"owner_count": 1,
		"area_count": 1,
		"area_id": AREA_ID,
		"area_position": global_position,
		"area_visible": visible,
		"visual_radius": VISUAL_RADIUS,
		"visual_local_bounds": VISUAL_LOCAL_BOUNDS,
		"visual_world_rect": visual_world_rect,
		"visual_on_screen": _visual_on_screen,
		"sailing_view_active": _sailing_view_active,
		"sailing_viewport_world_rect": _sailing_viewport_world_rect,
		"fish_lot_name": FISH_LOT_NAME,
		"fish_type_count": 1,
		"fish_price_state": FISH_PRICE_STATE,
		"fishing_range": FISHING_RANGE,
		"fishing_max_speed": FISHING_MAX_SPEED,
		"ship_position": _ship_position,
		"ship_distance": _ship_distance,
		"ship_speed": absf(_ship_speed),
		"player_aboard_ship": _player_aboard_ship,
		"captain_aboard": _captain_aboard,
		"input_available": _input_available,
		"fishing_eligible": _fishing_eligible,
		"eligibility": {
			"player_aboard_ship": _player_aboard_ship,
			"captain_aboard": _captain_aboard,
			"inside_fishing_area": _ship_distance <= FISHING_RANGE,
			"ship_stopped": absf(_ship_speed) <= FISHING_MAX_SPEED,
			"input_available": _input_available,
			"no_pending_catch": _pending_catch_count == 0,
			"eligible": _fishing_eligible,
		},
		"interaction_prompt": get_interaction_prompt(),
		"catch_attempt_count": _catch_attempt_count,
		"successful_catch_count": _successful_catch_count,
		"direct_keep_count": _direct_keep_count,
		"choice_required_count": _choice_required_count,
		"discarded_catch_count": _discarded_catch_count,
		"replacement_keep_count": _replacement_keep_count,
		"displaced_cargo_discard_count": _displaced_cargo_discard_count,
		"held_input_count": _held_input_count,
		"pending_catch_count": _pending_catch_count,
		"last_catch_result": _last_catch_result,
		"last_catch_evidence": _last_catch_evidence.duplicate(true),
		"last_choice_evidence": _last_choice_evidence.duplicate(true),
		"last_held_input_evidence": _last_held_input_evidence.duplicate(true),
		"fresh_press_required": true,
		"one_lot_per_fresh_press": true,
		"catch_accounting_holds": (
			_successful_catch_count
			== _direct_keep_count
				+ _discarded_catch_count
				+ _replacement_keep_count
				+ _pending_catch_count
		),
		"separate_minigame_enabled": false,
		"fishing_upgrades_enabled": false,
		"rare_fish_enabled": false,
		"weather_effects_enabled": false,
		"time_effects_enabled": false,
		"monster_fishing_enabled": false,
	}


func _draw() -> void:
	draw_circle(Vector2.ZERO, VISUAL_RADIUS, Color("#2b97a658"))
	draw_arc(
		Vector2.ZERO,
		VISUAL_RADIUS,
		0.0,
		TAU,
		64,
		Color("#8de3d5"),
		6.0,
	)
	draw_arc(
		Vector2.ZERO,
		VISUAL_RADIUS - 18.0,
		0.0,
		TAU,
		64,
		Color("#d5fff0aa"),
		2.0,
	)
	for fish_position in [
		Vector2(-64.0, -34.0),
		Vector2(18.0, -62.0),
		Vector2(62.0, 8.0),
		Vector2(-25.0, 42.0),
		Vector2(-78.0, 69.0),
	]:
		_draw_fish(fish_position)
	var font := ThemeDB.fallback_font
	draw_rect(
		Rect2(Vector2(-150.0, -181.0), Vector2(300.0, 38.0)),
		Color("#0b3440e8"),
	)
	draw_string(
		font,
		Vector2(-140.0, -154.0),
		"FISHING AREA · STOP TO FISH",
		HORIZONTAL_ALIGNMENT_CENTER,
		280.0,
		19,
		Color("#e7fff5"),
	)


func _draw_fish(fish_position: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([
		fish_position + Vector2(-22.0, 0.0),
		fish_position + Vector2(-36.0, -11.0),
		fish_position + Vector2(-36.0, 11.0),
	]), Color("#f4d477"))
	draw_colored_polygon(PackedVector2Array([
		fish_position + Vector2(-20.0, 0.0),
		fish_position + Vector2(-8.0, -10.0),
		fish_position + Vector2(12.0, -9.0),
		fish_position + Vector2(24.0, 0.0),
		fish_position + Vector2(12.0, 9.0),
		fish_position + Vector2(-8.0, 10.0),
	]), Color("#f6e5a0"))
	draw_circle(fish_position + Vector2(13.0, -2.0), 2.5, Color("#16323a"))


func _result_name(lot_name: String) -> String:
	return lot_name.to_upper().replace(" ", "_")
