extends Node2D

enum RequestState {
	AVAILABLE,
	ACTIVE,
	GOAL_COMPLETE,
	COMPLETE,
}

const REQUEST_TITLE := "DAMAGED DOCK"
const REQUEST_ACTIVE_GOAL := "Inspect the damaged dock"
const REQUEST_RETURN_GOAL := "Return to Mara"

@onready var player = $Player
@onready var sign: CoveSign = $InteractiveObjects/Sign
@onready var resident = $InteractiveObjects/Resident
@onready var sea_area = $SeaArea
@onready var wreck_opportunity: WreckOpportunity = $WreckOpportunity
@onready var ship = $Ship
@onready var ship_entry: Area2D = $ShipAccess/EntryPoint
@onready var ship_standing_position: Marker2D = $Ship/StandingPosition
@onready var damaged_dock_return_position: Marker2D = $ShipAccess/DamagedDockReturnPosition
@onready var damaged_dock_goal: Area2D = $RequestAreas/DamagedDockGoal
@onready var travel_camera: Camera2D = $TravelCamera
@onready var interaction_prompt: Label = $Interface/InteractionPrompt
@onready var sign_message: Label = $Interface/SignMessage
@onready var dialogue_box: ColorRect = $Interface/DialogueBox
@onready var speaker_name: Label = $Interface/DialogueBox/SpeakerName
@onready var dialogue_text: Label = $Interface/DialogueBox/DialogueText
@onready var request_view: ColorRect = $Interface/RequestView
@onready var request_title: Label = $Interface/RequestView/RequestTitle
@onready var request_status: Label = $Interface/RequestView/RequestStatus
@onready var request_goal: Label = $Interface/RequestView/RequestGoal
@onready var controls_help: Label = $Interface/Controls
@onready var waypoint_display: WaypointDisplay = $Interface/WaypointDisplay

const COVE_CAMERA_POSITION := Vector2(576.0, 324.0)
const WALKING_CONTROLS_TEXT := "WASD / ARROWS TO MOVE · E INTERACT · M CHART"
const SAILING_CONTROLS_TEXT := "W / UP SAIL · A / D TURN · S / DOWN BRAKE · M CHART"
const DOCKED_CONTROLS_TEXT := "E GO ASHORE · W / UP SAIL AWAY · M CHART"
const CHART_CONTROLS_TEXT := "M CLOSE · 1 COVE · 2 ISLAND · 3 PORT · X CLEAR"
const RELEASE_CONTROLS_TEXT := "RELEASE WASD / ARROW KEYS"
const SHORE_RETURN_DISTANCE := 64.0

var _player_near_sign := false
var _player_near_resident := false
var _player_near_ship_entry := false
var _player_aboard_ship := false
var _interact_held := false
var _read_count := 0
var _dialogue_open := false
var _dialogue_line_index := -1
var _dialogue_lines := PackedStringArray()
var _request_state := RequestState.AVAILABLE
var _last_leave_allowed := false
var _available_dock_id := ""
var _player_shore_id := ""
var _player_near_ship_return := false
var _last_ship_docked := false
var _chart_release_pending := false
var _last_salvage_eligible := false
var _salvage_collection_position := Vector2.ZERO
var _salvage_sailed_after_collection := false
var _cove_docked_after_salvage := false
var _cove_ashore_after_salvage := false
var _cove_returned_to_ship_after_salvage := false
var _cove_dock_released_after_salvage := false
var _timber_lots_after_sailing := 0
var _timber_lots_at_cove_dock := 0
var _timber_lots_while_ashore := 0
var _timber_lots_after_return_to_ship := 0
var _timber_lots_after_cove_dock_release := 0


func _ready() -> void:
	var sea_state: Dictionary = sea_area.get_playtest_state()
	ship.configure_sailing_area(
		sea_state["bounds"],
		sea_state["island_center"],
		sea_state["island_radius"],
		sea_state["port_land_rect"],
		sea_state["cove_shoreline"],
	)
	waypoint_display.configure(sea_state["bounds"], ship.get_dock_definitions())
	waypoint_display.update_positions(ship.global_position, player.global_position, false)
	var cove_dock: Dictionary = ship.get_dock_definition("cove")
	var port_dock: Dictionary = ship.get_dock_definition("port")
	wreck_opportunity.configure_route(
		cove_dock["approach_position"],
		port_dock["approach_position"],
	)
	_update_wreck_opportunity()
	travel_camera.global_position = COVE_CAMERA_POSITION
	interaction_prompt.hide()
	sign_message.hide()
	dialogue_box.hide()
	request_view.hide()
	sign.body_entered.connect(_on_sign_body_entered)
	sign.body_exited.connect(_on_sign_body_exited)
	resident.body_entered.connect(_on_resident_body_entered)
	resident.body_exited.connect(_on_resident_body_exited)
	ship_entry.body_entered.connect(_on_ship_entry_body_entered)
	ship_entry.body_exited.connect(_on_ship_entry_body_exited)
	damaged_dock_goal.body_entered.connect(_on_damaged_dock_goal_body_entered)


func _physics_process(_delta: float) -> void:
	_update_chart_release_pending()
	waypoint_display.update_positions(
		ship.global_position,
		player.global_position,
		_player_aboard_ship,
	)
	_update_wreck_opportunity()
	_update_salvage_persistence()
	if _player_aboard_ship:
		player.global_position = ship_standing_position.global_position
		travel_camera.global_position = ship.global_position
		var leave_allowed: bool = ship.can_leave_at_damaged_dock()
		var available_dock_id: String = ship.get_available_dock_id()
		var ship_docked: bool = ship.is_docked
		var salvage_eligible := wreck_opportunity.is_salvage_eligible()
		if (
			_last_ship_docked
			and not ship_docked
			and ship.last_dock_id == "cove"
			and ship.timber_lots == 1
		):
			_cove_dock_released_after_salvage = true
			_timber_lots_after_cove_dock_release = ship.timber_lots
		if waypoint_display.chart_visible:
			controls_help.text = CHART_CONTROLS_TEXT
		elif _chart_release_pending:
			controls_help.text = RELEASE_CONTROLS_TEXT
		elif ship_docked:
			controls_help.text = DOCKED_CONTROLS_TEXT
		elif controls_help.text != SAILING_CONTROLS_TEXT:
			controls_help.text = SAILING_CONTROLS_TEXT
		if (
			leave_allowed != _last_leave_allowed
			or available_dock_id != _available_dock_id
			or ship_docked != _last_ship_docked
			or salvage_eligible != _last_salvage_eligible
		):
			_last_leave_allowed = leave_allowed
			_available_dock_id = available_dock_id
			_last_ship_docked = ship_docked
			_last_salvage_eligible = salvage_eligible
			_update_interaction_prompt()
	elif not _player_shore_id.is_empty():
		travel_camera.global_position = player.global_position
		var dock_definition: Dictionary = ship.get_current_dock_definition()
		var near_return := false
		if not dock_definition.is_empty():
			near_return = player.global_position.distance_to(
				dock_definition["shore_position"]
			) <= SHORE_RETURN_DISTANCE
		if near_return != _player_near_ship_return:
			_player_near_ship_return = near_return
			_update_interaction_prompt()
	else:
		travel_camera.global_position = COVE_CAMERA_POSITION


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if _handle_chart_input(key_event):
		get_viewport().set_input_as_handled()
		return
	if _chart_release_pending:
		if (
			not key_event.pressed
			and (key_event.physical_keycode == KEY_E or key_event.keycode == KEY_E)
		):
			_interact_held = false
		get_viewport().set_input_as_handled()
		return
	if key_event.physical_keycode != KEY_E and key_event.keycode != KEY_E:
		return
	if not key_event.pressed:
		_interact_held = false
		return
	if key_event.echo or _interact_held:
		return

	_interact_held = true
	if _dialogue_open:
		_advance_dialogue()
		get_viewport().set_input_as_handled()
		return

	if _player_aboard_ship:
		if ship.is_docked:
			_go_ashore()
		elif not ship.get_available_dock_id().is_empty():
			_dock_ship()
		elif wreck_opportunity.can_receive_salvage_press():
			_salvage_wreck()
		elif ship.can_leave_at_damaged_dock():
			_leave_ship_at_damaged_dock()
		get_viewport().set_input_as_handled()
		return

	if not _player_shore_id.is_empty() and _player_near_ship_return:
		_return_to_ship()
		get_viewport().set_input_as_handled()
		return

	if _player_near_resident:
		_start_dialogue()
		get_viewport().set_input_as_handled()
		return

	if _player_near_ship_entry:
		_enter_ship()
		get_viewport().set_input_as_handled()
		return

	if _player_near_sign:
		_read_sign()
		get_viewport().set_input_as_handled()


func _handle_chart_input(key_event: InputEventKey) -> bool:
	if not key_event.pressed or key_event.echo:
		return false

	if _key_matches(key_event, KEY_M):
		if _dialogue_open:
			return false
		_set_chart_visible(not waypoint_display.chart_visible)
		return true

	if not waypoint_display.chart_visible:
		return false

	if _key_matches(key_event, KEY_1):
		waypoint_display.select_location("cove")
	elif _key_matches(key_event, KEY_2):
		waypoint_display.select_location("island")
	elif _key_matches(key_event, KEY_3):
		waypoint_display.select_location("port")
	elif _key_matches(key_event, KEY_X):
		waypoint_display.clear_location()
	else:
		return true
	return true


func _key_matches(key_event: InputEventKey, key: Key) -> bool:
	return key_event.physical_keycode == key or key_event.keycode == key


func _set_chart_visible(visible: bool) -> void:
	waypoint_display.set_chart_visible(visible)
	_interact_held = false
	if visible:
		_chart_release_pending = false
		player.movement_enabled = false
		ship.set_navigation_input_blocked(true)
		controls_help.text = CHART_CONTROLS_TEXT
		interaction_prompt.hide()
	else:
		_chart_release_pending = true
		player.movement_enabled = false
		ship.set_navigation_input_blocked(
			false,
			_player_aboard_ship and not ship.is_docked,
		)
		controls_help.text = RELEASE_CONTROLS_TEXT
		_update_interaction_prompt()


func _update_chart_release_pending() -> void:
	if not _chart_release_pending or waypoint_display.chart_visible:
		return
	if _is_any_movement_key_pressed():
		player.movement_enabled = false
		return

	_chart_release_pending = false
	player.movement_enabled = not _player_aboard_ship and not _dialogue_open
	controls_help.text = _get_context_controls_text()
	_update_interaction_prompt()


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


func _get_context_controls_text() -> String:
	if _player_aboard_ship:
		if ship.is_docked:
			return DOCKED_CONTROLS_TEXT
		return SAILING_CONTROLS_TEXT
	return WALKING_CONTROLS_TEXT


func _update_wreck_opportunity() -> void:
	wreck_opportunity.update_state(
		ship.global_position,
		ship.get_forward_direction(),
		ship.current_speed,
		_player_aboard_ship,
		ship.captain_aboard,
		ship.has_departed_dock,
		waypoint_display.selected_location_id,
		_player_aboard_ship and not waypoint_display.chart_visible,
		not waypoint_display.chart_visible,
	)


func _update_salvage_persistence() -> void:
	if ship.timber_lots != 1 or _salvage_collection_position == Vector2.ZERO:
		return
	if ship.global_position.distance_to(_salvage_collection_position) > 1.0:
		_salvage_sailed_after_collection = true
		_timber_lots_after_sailing = ship.timber_lots


func _salvage_wreck() -> void:
	if not wreck_opportunity.is_salvage_eligible():
		wreck_opportunity.try_collect_timber_lot()
		_update_interaction_prompt()
		return
	if not ship.can_accept_salvaged_timber_lot():
		return
	if not wreck_opportunity.try_collect_timber_lot():
		_update_interaction_prompt()
		return
	if not ship.add_salvaged_timber_lot():
		return
	_salvage_collection_position = ship.global_position
	_last_salvage_eligible = false
	_update_interaction_prompt()


func _on_sign_body_entered(body: Node2D) -> void:
	if body != player:
		return

	_player_near_sign = true
	_update_interaction_prompt()


func _on_sign_body_exited(body: Node2D) -> void:
	if body != player:
		return

	_player_near_sign = false
	sign_message.hide()
	_update_interaction_prompt()


func _on_resident_body_entered(body: Node2D) -> void:
	if body != player:
		return

	_player_near_resident = true
	_update_interaction_prompt()


func _on_resident_body_exited(body: Node2D) -> void:
	if body != player:
		return

	_player_near_resident = false
	_update_interaction_prompt()


func _on_ship_entry_body_entered(body: Node2D) -> void:
	if body != player or _player_aboard_ship:
		return

	_player_near_ship_entry = true
	_update_interaction_prompt()


func _on_ship_entry_body_exited(body: Node2D) -> void:
	if body != player:
		return

	_player_near_ship_entry = false
	_update_interaction_prompt()


func _on_damaged_dock_goal_body_entered(body: Node2D) -> void:
	if body != player or _request_state != RequestState.ACTIVE:
		return

	_request_state = RequestState.GOAL_COMPLETE
	_update_request_view()


func _read_sign() -> void:
	_read_count += 1
	sign_message.text = sign.interaction_message
	sign_message.show()


func _enter_ship() -> void:
	if _player_aboard_ship or not _player_near_ship_entry:
		return

	_player_aboard_ship = true
	ship.set_captain_aboard(true)
	ship.set_controls_enabled(true)
	player.enter_ship(ship_standing_position.global_position)
	_last_leave_allowed = ship.can_leave_at_damaged_dock()
	_available_dock_id = ship.get_available_dock_id()
	_last_ship_docked = ship.is_docked
	controls_help.text = SAILING_CONTROLS_TEXT
	sign_message.hide()
	_update_interaction_prompt()


func _leave_ship_at_damaged_dock() -> void:
	if not _player_aboard_ship or not ship.can_leave_at_damaged_dock():
		return

	_player_aboard_ship = false
	ship.set_controls_enabled(false)
	ship.set_captain_aboard(false)
	_player_near_ship_entry = true
	player.leave_ship(damaged_dock_return_position.global_position)
	_last_leave_allowed = false
	_available_dock_id = ""
	_last_ship_docked = false
	controls_help.text = WALKING_CONTROLS_TEXT
	_update_interaction_prompt()


func _dock_ship() -> void:
	if not _player_aboard_ship or ship.is_docked:
		return

	var dock_id: String = ship.dock_at_available()
	if dock_id.is_empty():
		return

	_available_dock_id = ""
	_last_leave_allowed = false
	_last_ship_docked = true
	if dock_id == "cove" and ship.timber_lots == 1:
		_cove_docked_after_salvage = true
		_timber_lots_at_cove_dock = ship.timber_lots
	controls_help.text = DOCKED_CONTROLS_TEXT
	_update_interaction_prompt()


func _go_ashore() -> void:
	if not _player_aboard_ship or not ship.is_docked:
		return

	var definition: Dictionary = ship.get_current_dock_definition()
	if definition.is_empty():
		return

	_player_aboard_ship = false
	_player_shore_id = String(definition["id"])
	if _player_shore_id == "cove" and ship.timber_lots == 1:
		_cove_ashore_after_salvage = true
		_timber_lots_while_ashore = ship.timber_lots
	_player_near_ship_return = true
	ship.set_captain_aboard(false)
	player.go_ashore(
		definition["shore_position"],
		_player_shore_id,
		definition["shore_region"],
	)
	controls_help.text = WALKING_CONTROLS_TEXT
	_update_interaction_prompt()


func _return_to_ship() -> void:
	if _player_shore_id.is_empty() or not _player_near_ship_return:
		return
	if not ship.is_docked or ship.current_dock_id != _player_shore_id:
		return

	var returning_shore_id := _player_shore_id
	_player_aboard_ship = true
	_player_shore_id = ""
	_player_near_ship_return = false
	player.enter_ship(ship_standing_position.global_position)
	ship.set_captain_aboard(true)
	if returning_shore_id == "cove" and ship.timber_lots == 1:
		_cove_returned_to_ship_after_salvage = true
		_timber_lots_after_return_to_ship = ship.timber_lots
	_last_ship_docked = true
	controls_help.text = DOCKED_CONTROLS_TEXT
	_update_interaction_prompt()


func _start_dialogue() -> void:
	_dialogue_lines = _get_resident_dialogue()
	if _dialogue_lines.is_empty():
		return

	if _request_state == RequestState.AVAILABLE:
		_request_state = RequestState.ACTIVE
		_update_request_view()

	_dialogue_open = true
	_dialogue_line_index = 0
	player.movement_enabled = false
	sign_message.hide()
	interaction_prompt.hide()
	speaker_name.text = resident.display_name
	dialogue_text.text = _dialogue_lines[_dialogue_line_index]
	dialogue_box.show()


func _advance_dialogue() -> void:
	_dialogue_line_index += 1
	if _dialogue_line_index >= _dialogue_lines.size():
		_close_dialogue()
		return

	dialogue_text.text = _dialogue_lines[_dialogue_line_index]


func _close_dialogue() -> void:
	var finished_request := _request_state == RequestState.GOAL_COMPLETE
	_dialogue_open = false
	_dialogue_line_index = -1
	_dialogue_lines = PackedStringArray()
	player.movement_enabled = true
	dialogue_box.hide()
	if finished_request:
		_request_state = RequestState.COMPLETE
		_update_request_view()
	_update_interaction_prompt()


func _get_resident_dialogue() -> PackedStringArray:
	match _request_state:
		RequestState.AVAILABLE:
			return resident.request_offer_dialogue
		RequestState.ACTIVE:
			return resident.request_active_dialogue
		RequestState.GOAL_COMPLETE:
			return resident.request_report_dialogue
		RequestState.COMPLETE:
			return resident.request_complete_dialogue

	return PackedStringArray()


func _update_request_view() -> void:
	if _request_state == RequestState.AVAILABLE:
		request_view.hide()
		return

	request_title.text = REQUEST_TITLE
	request_view.show()
	match _request_state:
		RequestState.ACTIVE:
			request_status.text = "ACTIVE REQUEST"
			request_goal.text = REQUEST_ACTIVE_GOAL
		RequestState.GOAL_COMPLETE:
			request_status.text = "GOAL COMPLETE"
			request_goal.text = REQUEST_RETURN_GOAL
		RequestState.COMPLETE:
			request_status.text = "REQUEST COMPLETE"
			request_goal.text = "Dock inspected for Mara"


func _update_interaction_prompt() -> void:
	if _dialogue_open or waypoint_display.chart_visible or _chart_release_pending:
		interaction_prompt.hide()
		return

	if _player_aboard_ship:
		if ship.is_docked:
			var current_dock: Dictionary = ship.get_current_dock_definition()
			interaction_prompt.text = "[E] GO ASHORE AT %s" % current_dock["name"]
			interaction_prompt.show()
		elif not _available_dock_id.is_empty():
			var available_definition: Dictionary = ship.get_dock_definition(_available_dock_id)
			interaction_prompt.text = "[E] DOCK AT %s" % available_definition["name"]
			interaction_prompt.show()
		elif wreck_opportunity.is_salvage_eligible():
			interaction_prompt.text = "[E] SALVAGE ONE TIMBER LOT"
			interaction_prompt.show()
		elif ship.can_leave_at_damaged_dock():
			interaction_prompt.text = "[E] LEAVE SHIP AT DOCK"
			interaction_prompt.show()
		else:
			interaction_prompt.hide()
		return

	if not _player_shore_id.is_empty() and _player_near_ship_return:
		interaction_prompt.text = "[E] RETURN TO SHIP"
		interaction_prompt.show()
		return

	if _player_near_resident:
		interaction_prompt.text = "[E] TALK TO %s" % resident.display_name.to_upper()
		interaction_prompt.show()
		return

	if _player_near_ship_entry:
		interaction_prompt.text = "[E] ENTER SHIP"
		interaction_prompt.show()
		return

	if _player_near_sign:
		interaction_prompt.text = "[E] READ SIGN"
		interaction_prompt.show()
		return

	interaction_prompt.hide()


func get_playtest_state() -> Dictionary:
	var ship_state: Dictionary = ship.get_playtest_state()
	var player_state: Dictionary = player.get_playtest_state()
	var waypoint_state: Dictionary = waypoint_display.get_playtest_state()
	var wreck_state: Dictionary = wreck_opportunity.get_playtest_state()
	var camera_target := "COVE"
	if _player_aboard_ship:
		camera_target = "SHIP"
	elif not _player_shore_id.is_empty():
		camera_target = "PLAYER_ASHORE"
	return {
		"player_position": player.position,
		"sign_position": sign.position,
		"resident_position": resident.position,
		"ship_position": ship.global_position,
		"ship_rotation_radians": ship_state["rotation_radians"],
		"ship_rotation_degrees": ship_state["rotation_degrees"],
		"ship_heading": ship_state["heading"],
		"ship_speed": ship_state["current_speed"],
		"ship_velocity": ship_state["velocity"],
		"ship_acceleration": ship_state["acceleration"],
		"ship_coast_deceleration": ship_state["coast_deceleration"],
		"ship_brake_deceleration": ship_state["brake_deceleration"],
		"ship_top_speed": ship_state["top_speed"],
		"ship_turn_speed": ship_state["turn_speed"],
		"ship_controls": ship_state["controls"],
		"ship_controls_enabled": ship_state["controls_enabled"],
		"ship_captain_aboard": ship_state["captain_aboard"],
		"ship_timber_lots": ship_state["timber_lots"],
		"ship_has_departed_dock": ship_state["has_departed_dock"],
		"ship_at_damaged_dock": ship_state["at_damaged_dock"],
		"ship_leave_allowed": ship_state["leave_allowed"],
		"ship_at_cove_entrance": ship_state["at_cove_entrance"],
		"damaged_dock_position": ship_state["damaged_dock_position"],
		"cove_entrance_position": ship_state["cove_entrance_position"],
		"cove_entrance_radius": ship_state["cove_entrance_radius"],
		"sea_bounds": ship_state["sea_bounds"],
		"test_island_center": ship_state["island_center"],
		"test_island_radius": ship_state["island_radius"],
		"port_land_rect": ship_state["port_land_rect"],
		"port_walking_rect": sea_area.get_playtest_state()["port_walking_rect"],
		"ship_collision_radius": ship_state["collision_radius"],
		"ship_collision_response": ship_state["last_collision_response"],
		"ship_steering_locked": ship_state["steering_locked"],
		"ship_dock_exit_cleared": ship_state["dock_exit_cleared"],
		"ship_dock_exit_progress": ship_state["dock_exit_progress"],
		"ship_dock_exit_clear_y": ship_state["dock_exit_clear_y"],
		"ship_hull_clearance": ship_state["hull_clearance"],
		"cove_shoreline": ship_state["cove_shoreline"],
		"dock_count": ship_state["dock_count"],
		"dock_ids": ship_state["dock_ids"],
		"dock_names": ship_state["dock_names"],
		"dock_definitions": ship_state["dock_definitions"],
		"dock_thresholds": ship_state["dock_thresholds"],
		"dock_eligibility": ship_state["dock_eligibility"],
		"available_dock_id": ship_state["available_dock_id"],
		"ship_is_docked": ship_state["is_docked"],
		"current_dock_id": ship_state["current_dock_id"],
		"last_dock_id": ship_state["last_dock_id"],
		"ship_fixed_dock_pose": ship_state["fixed_dock_pose"],
		"ship_departure_input_armed": ship_state["departure_input_armed"],
		"navigation_input_blocked": ship_state["navigation_input_blocked"],
		"navigation_release_pending": ship_state["navigation_release_pending"],
		"walking_release_pending": _chart_release_pending,
		"chart_input_blocked": (
			waypoint_state["chart_visible"]
			and ship_state["navigation_input_blocked"]
			and not player_state["movement_enabled"]
		),
		"input_release_pending": (
			ship_state["navigation_release_pending"] or _chart_release_pending
		),
		"camera_position": travel_camera.global_position,
		"camera_target": camera_target,
		"ship_entry_position": ship_entry.global_position,
		"ship_standing_position": ship_standing_position.global_position,
		"damaged_dock_return_position": damaged_dock_return_position.global_position,
		"player_near_sign": _player_near_sign,
		"player_near_resident": _player_near_resident,
		"player_near_ship_entry": _player_near_ship_entry,
		"player_aboard_ship": _player_aboard_ship,
		"player_control_mode": player_state["control_mode"],
		"player_movement_enabled": player_state["movement_enabled"],
		"player_shore_id": _player_shore_id,
		"player_near_ship_return": _player_near_ship_return,
		"shore_return_distance": SHORE_RETURN_DISTANCE,
		"player_shore_region_kind": player_state["shore_region_kind"],
		"player_shore_region_center": player_state["shore_region_center"],
		"player_shore_region_radius": player_state["shore_region_radius"],
		"player_shore_region_rect": player_state["shore_region_rect"],
		"prompt_visible": interaction_prompt.visible,
		"prompt_text": interaction_prompt.text,
		"message_visible": sign_message.visible,
		"message_text": sign_message.text,
		"read_count": _read_count,
		"dialogue_open": _dialogue_open,
		"dialogue_line_index": _dialogue_line_index,
		"speaker_name": speaker_name.text,
		"dialogue_text": dialogue_text.text,
		"request_state": RequestState.keys()[_request_state],
		"request_view_visible": request_view.visible,
		"request_title": request_title.text,
		"request_status": request_status.text,
		"request_goal": request_goal.text,
		"chart_visible": waypoint_state["chart_visible"],
		"known_location_count": waypoint_state["known_location_count"],
		"known_location_ids": waypoint_state["known_location_ids"],
		"known_locations": waypoint_state["known_locations"],
		"selected_waypoint_id": waypoint_state["selected_location_id"],
		"selected_waypoint_marker_count": waypoint_state["selected_marker_count"],
		"chart_selected_marker_count": waypoint_state["chart_selected_marker_count"],
		"sailing_direction_marker_count": waypoint_state["sailing_direction_marker_count"],
		"waypoint_target_position": waypoint_state["target_position"],
		"waypoint_direction_vector": waypoint_state["direction_vector"],
		"waypoint_direction_angle_radians": waypoint_state["direction_angle_radians"],
		"waypoint_direction_angle_degrees": waypoint_state["direction_angle_degrees"],
		"chart_ship_position": waypoint_state["ship_position"],
		"chart_player_position": waypoint_state["player_position"],
		"chart_sailing_input_blocked": (
			waypoint_state["chart_visible"]
			and ship_state["navigation_input_blocked"]
		),
		"wreck_count": wreck_state["wreck_count"],
		"wreck_id": wreck_state["wreck_id"],
		"wreck_position": wreck_state["wreck_position"],
		"wreck_direct_route_start": wreck_state["direct_route_start"],
		"wreck_direct_route_end": wreck_state["direct_route_end"],
		"wreck_direct_route_offset": wreck_state["direct_route_offset"],
		"wreck_direct_route_progress": wreck_state["wreck_direct_route_progress"],
		"wreck_route_acquire_range": wreck_state["route_acquire_range"],
		"wreck_route_departure_range": wreck_state["route_departure_range"],
		"wreck_early_visibility_range": wreck_state["early_visibility_range"],
		"wreck_range_visibility_active": wreck_state["range_visibility_active"],
		"wreck_current_visibility": wreck_state["current_visibility"],
		"wreck_early_visible": wreck_state["early_visible"],
		"wreck_visual_visible": wreck_state["visual_visible"],
		"wreck_sailing_view_active": wreck_state["sailing_view_active"],
		"wreck_sailing_viewport_size": wreck_state["sailing_viewport_size"],
		"wreck_sailing_viewport_world_rect": wreck_state["sailing_viewport_world_rect"],
		"wreck_visual_local_bounds": wreck_state["wreck_visual_local_bounds"],
		"wreck_visual_world_rect": wreck_state["wreck_visual_world_rect"],
		"wreck_visual_on_screen": wreck_state["wreck_visual_on_screen"],
		"wreck_on_screen": wreck_state["on_screen"],
		"wreck_near_marker_range": wreck_state["near_marker_range"],
		"wreck_near_marker_visible": wreck_state["near_marker_visible"],
		"wreck_near_marker_count": wreck_state["near_marker_count"],
		"wreck_reached_range": wreck_state["reached_range"],
		"ship_distance_to_wreck": wreck_state["ship_distance"],
		"ship_direct_route_offset": wreck_state["ship_direct_route_offset"],
		"ship_direct_route_progress": wreck_state["ship_direct_route_progress"],
		"ship_distance_to_port": wreck_state["port_distance"],
		"wreck_port_waypoint_selected": wreck_state["port_waypoint_selected"],
		"wreck_started_toward_port": wreck_state["started_toward_port"],
		"wreck_direct_route_acquired": wreck_state["direct_route_acquired"],
		"wreck_seen_before_passing": wreck_state["seen_before_passing"],
		"wreck_sailing_toward_wreck": wreck_state["sailing_toward_wreck"],
		"wreck_left_direct_route": wreck_state["left_direct_route"],
		"wreck_reached": wreck_state["reached"],
		"wreck_reached_after_course_change": wreck_state["reached_after_course_change"],
		"wreck_distance_to_port_at_reach": wreck_state["distance_to_port_at_reach"],
		"wreck_returning_to_port": wreck_state["returning_to_port"],
		"wreck_route_state": wreck_state["route_state"],
		"wreck_known_chart_location": wreck_state["known_chart_location"],
		"wreck_chart_marker_count": wreck_state["chart_marker_count"],
		"salvage_range": wreck_state["salvage_range"],
		"salvage_max_speed": wreck_state["salvage_max_speed"],
		"salvage_eligibility": wreck_state["salvage_eligibility"],
		"salvage_eligible": wreck_state["salvage_eligible"],
		"salvage_prompt_visible": (
			interaction_prompt.visible
			and interaction_prompt.text == "[E] SALVAGE ONE TIMBER LOT"
		),
		"salvage_prompt_text": (
			interaction_prompt.text
			if interaction_prompt.visible
			and interaction_prompt.text == "[E] SALVAGE ONE TIMBER LOT"
			else ""
		),
		"wreck_empty": wreck_state["wreck_empty"],
		"successful_salvage_collection_count": (
			wreck_state["successful_collection_count"]
		),
		"salvage_last_result": wreck_state["last_salvage_result"],
		"salvage_repeat_result": wreck_state["repeat_salvage_result"],
		"salvage_persistence": {
			"sailed_after_collection": _salvage_sailed_after_collection,
			"timber_lots_after_sailing": _timber_lots_after_sailing,
			"cove_docked_after_salvage": _cove_docked_after_salvage,
			"timber_lots_at_cove_dock": _timber_lots_at_cove_dock,
			"went_ashore_at_cove": _cove_ashore_after_salvage,
			"timber_lots_while_ashore": _timber_lots_while_ashore,
			"returned_to_ship_at_cove": _cove_returned_to_ship_after_salvage,
			"timber_lots_after_return": _timber_lots_after_return_to_ship,
			"released_cove_dock": _cove_dock_released_after_salvage,
			"timber_lots_after_dock_release": (
				_timber_lots_after_cove_dock_release
			),
			"ship_is_docked": ship_state["is_docked"],
			"current_dock_id": ship_state["current_dock_id"],
			"last_dock_id": ship_state["last_dock_id"],
		},
	}
