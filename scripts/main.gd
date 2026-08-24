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
@onready var cove_storage: CoveStorageChest = $InteractiveObjects/CoveStorage
@onready var construction_site: StorageShedConstructionSite = (
	$InteractiveObjects/StorageShedConstruction
)
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
@onready var cargo_view: ColorRect = $Interface/CargoView
@onready var cargo_details: Label = $Interface/CargoView/CargoDetails
@onready var cargo_choice_view: ColorRect = $Interface/CargoChoiceView
@onready var cargo_choice_title: Label = $Interface/CargoChoiceView/ChoiceTitle
@onready var cargo_choice_details: Label = $Interface/CargoChoiceView/ChoiceDetails
@onready var storage_view: ColorRect = $Interface/StorageView
@onready var storage_details: Label = $Interface/StorageView/StorageDetails
@onready var storage_result: Label = $Interface/StorageView/StorageResult
@onready var construction_view: ColorRect = $Interface/ConstructionView
@onready var construction_title: Label = (
	$Interface/ConstructionView/ConstructionTitle
)
@onready var construction_details: Label = (
	$Interface/ConstructionView/ConstructionDetails
)
@onready var construction_result: Label = (
	$Interface/ConstructionView/ConstructionResult
)
@onready var construction_controls: Label = (
	$Interface/ConstructionView/ConstructionControls
)
@onready var controls_help: Label = $Interface/Controls
@onready var waypoint_display: WaypointDisplay = $Interface/WaypointDisplay

const COVE_CAMERA_POSITION := Vector2(576.0, 324.0)
const WALKING_CONTROLS_TEXT := "WASD / ARROWS TO MOVE · E INTERACT · M CHART"
const SAILING_CONTROLS_TEXT := "W / UP SAIL · A / D TURN · S / DOWN BRAKE · M CHART"
const DOCKED_CONTROLS_TEXT := "E GO ASHORE · W / UP SAIL AWAY · M CHART"
const CHART_CONTROLS_TEXT := "M CLOSE · 1 COVE · 2 ISLAND · 3 PORT · X CLEAR"
const CARGO_CHOICE_CONTROLS_TEXT := "X LEAVE AT WRECK · 1 / 2 / 3 REPLACE CARGO SLOT"
const STORAGE_CONTROLS_TEXT := "1 / 2 / 3 SHIP TO STORAGE · 4 / 5 / 6 STORAGE TO SHIP · X CLOSE"
const STORAGE_RELEASE_CONTROLS_TEXT := "RELEASE E, X, 1-6, M, WASD / ARROW KEYS"
const CONSTRUCTION_READY_CONTROLS_TEXT := "E BUILD STORAGE SHED · X CLOSE"
const CONSTRUCTION_UNAVAILABLE_CONTROLS_TEXT := "E BUILD UNAVAILABLE · X CLOSE"
const CONSTRUCTION_COMPLETE_CONTROLS_TEXT := "X CLOSE · E CANNOT BUILD AGAIN"
const CONSTRUCTION_RELEASE_CONTROLS_TEXT := "RELEASE E, X, M, WASD / ARROW KEYS"
const RELEASE_CONTROLS_TEXT := "RELEASE WASD / ARROW KEYS"
const SHORE_RETURN_DISTANCE := 64.0

var _player_near_sign := false
var _player_near_resident := false
var _player_near_ship_entry := false
var _player_near_cove_storage := false
var _player_near_construction_site := false
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
var _pending_salvage_lot := ""
var _cargo_choice_open := false
var _cargo_choice_release_pending := false
var _prompt_refresh_after_navigation_release := false
var _last_cargo_action := "NOT_ATTEMPTED"
var _last_cargo_result := "NOT_ATTEMPTED"
var _cargo_kept_count := 0
var _cargo_left_count := 0
var _cargo_replaced_count := 0
var _cargo_choice_opened_count := 0
var _cargo_choice_resolution_count := 0
var _storage_view_open := false
var _storage_release_pending := false
var _storage_pressed_keys: Dictionary = {}
var _last_storage_action := "NOT_ATTEMPTED"
var _last_storage_result := "NOT_ATTEMPTED"
var _storage_open_count := 0
var _storage_close_count := 0
var _storage_stored_count := 0
var _storage_withdrawn_count := 0
var _storage_lists_saved_on_close := false
var _saved_ship_cargo_on_close: Array[String] = []
var _saved_cove_storage_on_close: Array[String] = []
var _saved_cove_storage_slots_on_close: Array[String] = []
var _persistence_ship_cargo: Array[String] = []
var _persistence_cove_storage: Array[String] = []
var _persistence_cove_storage_slots: Array[String] = []
var _storage_persistence_tracking := false
var _storage_returned_to_ship_after_save := false
var _storage_released_cove_dock_after_save := false
var _storage_sailed_after_save := false
var _storage_return_docked_after_save := false
var _storage_returned_ashore_after_save := false
var _storage_walked_back_after_return := false
var _storage_reopened_after_return := false
var _storage_persistence_holds := false
var _ship_lots_after_storage_sailing: Array[String] = []
var _cove_lots_after_storage_sailing: Array[String] = []
var _ship_lots_at_storage_return_dock: Array[String] = []
var _cove_lots_at_storage_return_dock: Array[String] = []
var _ship_lots_at_storage_reopen: Array[String] = []
var _cove_lots_at_storage_reopen: Array[String] = []
var _last_storage_transfer_evidence: Dictionary = {}
var _construction_view_open := false
var _construction_release_pending := false
var _construction_pressed_keys: Dictionary = {}
var _last_construction_action := "NOT_ATTEMPTED"
var _last_construction_result := "NOT_ATTEMPTED"
var _construction_open_count := 0
var _construction_close_count := 0
var _construction_held_input_count := 0
var _construction_blocked_input_count := 0
var _last_construction_attempt_evidence: Dictionary = {}
var _last_denied_construction_evidence: Dictionary = {}
var _successful_construction_evidence: Dictionary = {}
var _post_completion_attempt_evidence: Dictionary = {}
var _construction_persistence_tracking := false
var _construction_returned_to_ship := false
var _construction_released_cove_dock := false
var _construction_sailed_away := false
var _construction_return_docked := false
var _construction_returned_ashore := false
var _construction_walked_back := false
var _construction_finished_visible_after_return := false
var _construction_site_absent_after_return := false


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
	_update_cargo_view()
	_update_storage_view()
	_update_construction_view()
	travel_camera.global_position = COVE_CAMERA_POSITION
	interaction_prompt.hide()
	sign_message.hide()
	dialogue_box.hide()
	request_view.hide()
	cargo_choice_view.hide()
	storage_view.hide()
	construction_view.hide()
	sign.body_entered.connect(_on_sign_body_entered)
	sign.body_exited.connect(_on_sign_body_exited)
	resident.body_entered.connect(_on_resident_body_entered)
	resident.body_exited.connect(_on_resident_body_exited)
	cove_storage.body_entered.connect(_on_cove_storage_body_entered)
	cove_storage.body_exited.connect(_on_cove_storage_body_exited)
	construction_site.body_entered.connect(_on_construction_site_body_entered)
	construction_site.body_exited.connect(_on_construction_site_body_exited)
	ship_entry.body_entered.connect(_on_ship_entry_body_entered)
	ship_entry.body_exited.connect(_on_ship_entry_body_exited)
	damaged_dock_goal.body_entered.connect(_on_damaged_dock_goal_body_entered)


func _physics_process(_delta: float) -> void:
	_update_chart_release_pending()
	_update_cargo_choice_release_pending()
	_update_storage_release_pending()
	_update_construction_release_pending()
	waypoint_display.update_positions(
		ship.global_position,
		player.global_position,
		_player_aboard_ship,
	)
	_update_wreck_opportunity()
	_refresh_prompt_after_navigation_release()
	_update_cargo_view()
	_update_salvage_persistence()
	_update_storage_persistence()
	_update_construction_persistence()
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
		if (
			_storage_persistence_tracking
			and _last_ship_docked
			and not ship_docked
			and ship.last_dock_id == "cove"
		):
			_storage_released_cove_dock_after_save = true
		if (
			_construction_persistence_tracking
			and _last_ship_docked
			and not ship_docked
			and ship.last_dock_id == "cove"
		):
			_construction_released_cove_dock = true
		if _cargo_choice_open:
			controls_help.text = CARGO_CHOICE_CONTROLS_TEXT
		elif _cargo_choice_release_pending or ship.navigation_release_pending:
			controls_help.text = RELEASE_CONTROLS_TEXT
		elif waypoint_display.chart_visible:
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
	if _construction_view_open:
		_handle_construction_input(key_event)
		get_viewport().set_input_as_handled()
		return
	if _construction_release_pending:
		if not key_event.pressed:
			var released_key := _get_construction_key(key_event)
			if released_key != 0:
				_construction_pressed_keys.erase(released_key)
			if _key_matches(key_event, KEY_E):
				_interact_held = false
		get_viewport().set_input_as_handled()
		return
	if _storage_view_open:
		_handle_storage_input(key_event)
		get_viewport().set_input_as_handled()
		return
	if _storage_release_pending:
		if not key_event.pressed and _key_matches(key_event, KEY_E):
			_interact_held = false
		get_viewport().set_input_as_handled()
		return
	if _cargo_choice_open:
		_handle_cargo_choice_input(key_event)
		get_viewport().set_input_as_handled()
		return
	if _cargo_choice_release_pending:
		if not key_event.pressed and _key_matches(key_event, KEY_E):
			_interact_held = false
		get_viewport().set_input_as_handled()
		return
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

	if _can_open_construction_site():
		_open_construction_site()
		get_viewport().set_input_as_handled()
		return

	if _can_open_cove_storage():
		_open_cove_storage()
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


func _handle_construction_input(key_event: InputEventKey) -> void:
	var construction_key := _get_construction_key(key_event)
	if not key_event.pressed:
		if construction_key != 0:
			_construction_pressed_keys.erase(construction_key)
		if _key_matches(key_event, KEY_E):
			_interact_held = false
		return

	if construction_key == 0:
		_construction_blocked_input_count += 1
		_last_construction_action = "BLOCKED_WHILE_CONSTRUCTION_OPEN"
		_last_construction_result = "NO_CHANGE_CONSTRUCTION_MODAL_BLOCKED_INPUT"
		_update_construction_view()
		return
	if (
		key_event.echo
		or bool(_construction_pressed_keys.get(construction_key, false))
	):
		_construction_held_input_count += 1
		_last_construction_action = "HELD_CONSTRUCTION_KEY_%s" % (
			_construction_key_name(construction_key)
		)
		_last_construction_result = "NO_CHANGE_HELD_INPUT"
		_update_construction_view()
		return

	_construction_pressed_keys[construction_key] = true
	if construction_key == KEY_X:
		_close_construction_site()
		return
	_attempt_storage_shed_construction()


func _get_construction_key(key_event: InputEventKey) -> int:
	if _key_matches(key_event, KEY_E):
		return KEY_E
	if _key_matches(key_event, KEY_X):
		return KEY_X
	return 0


func _construction_key_name(key: int) -> String:
	return "E" if key == KEY_E else "X"


func _can_open_construction_site() -> bool:
	return (
		not _player_aboard_ship
		and (_player_shore_id.is_empty() or _player_shore_id == "cove")
		and _player_near_construction_site
		and not construction_site.completed
		and not _dialogue_open
		and not waypoint_display.chart_visible
		and not _chart_release_pending
		and not _cargo_choice_open
		and not _cargo_choice_release_pending
		and not _storage_view_open
		and not _storage_release_pending
		and not _construction_view_open
		and not _construction_release_pending
	)


func _open_construction_site() -> void:
	if not _can_open_construction_site():
		return

	_construction_view_open = true
	_construction_open_count += 1
	_construction_pressed_keys.clear()
	# The E press that opened this view remains guarded until its release arrives.
	_construction_pressed_keys[KEY_E] = true
	_last_construction_action = "OPEN_STORAGE_SHED_CONSTRUCTION"
	_last_construction_result = (
		"READY_TO_BUILD"
		if construction_site.is_construction_available(cove_storage)
		else "CONSTRUCTION_UNAVAILABLE"
	)
	player.movement_enabled = false
	ship.set_navigation_input_blocked(true)
	controls_help.text = (
		CONSTRUCTION_READY_CONTROLS_TEXT
		if construction_site.is_construction_available(cove_storage)
		else CONSTRUCTION_UNAVAILABLE_CONTROLS_TEXT
	)
	interaction_prompt.hide()
	sign_message.hide()
	_update_cargo_view()
	_update_construction_view()


func _close_construction_site() -> void:
	if not _construction_view_open:
		return

	_construction_view_open = false
	_construction_release_pending = true
	_construction_close_count += 1
	_last_construction_action = "CLOSE_STORAGE_SHED_CONSTRUCTION"
	_last_construction_result = "CONSTRUCTION_VIEW_CLOSED"
	construction_view.hide()
	player.movement_enabled = false
	ship.set_navigation_input_blocked(false)
	_prompt_refresh_after_navigation_release = true
	controls_help.text = CONSTRUCTION_RELEASE_CONTROLS_TEXT
	interaction_prompt.hide()
	_update_cargo_view()


func _attempt_storage_shed_construction() -> void:
	var ship_before: Array[String] = ship.get_cargo_lots()
	var storage_before: Array[String] = cove_storage.get_storage_slots()
	var world_before := _get_world_cargo_total()
	var consumed_before := construction_site.consumed_lot_count
	var completion_before := construction_site.completion_count
	_last_construction_action = "BUILD_STORAGE_SHED"
	var attempt: Dictionary = construction_site.attempt_construction(cove_storage)
	_last_construction_result = attempt["result"]
	var world_after := _get_world_cargo_total()
	var evidence := {
		"action": _last_construction_action,
		"result": _last_construction_result,
		"success": attempt["success"],
		"cost_lot_name": StorageShedConstructionSite.COST_LOT_NAME,
		"cost_lot_count": StorageShedConstructionSite.COST_LOT_COUNT,
		"ship_before": ship_before,
		"ship_after": ship.get_cargo_lots(),
		"storage_slots_before": storage_before,
		"storage_slots_after": cove_storage.get_storage_slots(),
		"stored_timber_before": attempt["stored_timber_before"],
		"stored_timber_after": attempt["stored_timber_after"],
		"world_total_before": world_before,
		"world_total_after": world_after,
		"consumed_this_attempt": attempt["consumed_count"],
		"consumed_total_before": consumed_before,
		"consumed_total_after": construction_site.consumed_lot_count,
		"completion_count_before": completion_before,
		"completion_count_after": construction_site.completion_count,
		"site_completed_before": attempt["was_completed"],
		"site_completed_after": attempt["is_completed"],
		"storage_only_counting": true,
		"ship_unchanged": ship_before == ship.get_cargo_lots(),
		"storage_changed_by_exact_cost": (
			world_before - world_after == int(attempt["consumed_count"])
		),
		"no_state_change": (
			ship_before == ship.get_cargo_lots()
			and storage_before == cove_storage.get_storage_slots()
			and completion_before == construction_site.completion_count
		),
	}
	_last_construction_attempt_evidence = evidence.duplicate(true)
	if bool(attempt["success"]):
		_successful_construction_evidence = evidence.duplicate(true)
		_construction_persistence_tracking = true
	elif bool(attempt["was_completed"]):
		_post_completion_attempt_evidence = evidence.duplicate(true)
	else:
		_last_denied_construction_evidence = evidence.duplicate(true)
	_update_cargo_view()
	_update_storage_view()
	_update_construction_view()
	controls_help.text = _get_context_controls_text()


func _handle_storage_input(key_event: InputEventKey) -> void:
	var storage_key := _get_storage_key(key_event)
	if not key_event.pressed:
		if storage_key != 0:
			_storage_pressed_keys.erase(storage_key)
		if _key_matches(key_event, KEY_E):
			_interact_held = false
		return

	if storage_key == 0:
		_last_storage_action = "BLOCKED_WHILE_STORAGE_OPEN"
		_last_storage_result = "NO_CHANGE_STORAGE_MODAL_BLOCKED_INPUT"
		_update_storage_view()
		return
	if key_event.echo or bool(_storage_pressed_keys.get(storage_key, false)):
		_last_storage_action = "HELD_STORAGE_KEY_%s" % _storage_key_name(storage_key)
		_last_storage_result = "NO_CHANGE_HELD_INPUT"
		_update_storage_view()
		return

	_storage_pressed_keys[storage_key] = true
	if storage_key == KEY_X:
		_close_cove_storage()
		return
	match storage_key:
		KEY_1:
			_store_ship_cargo_slot(0)
		KEY_2:
			_store_ship_cargo_slot(1)
		KEY_3:
			_store_ship_cargo_slot(2)
		KEY_4:
			_withdraw_cove_storage_slot(0)
		KEY_5:
			_withdraw_cove_storage_slot(1)
		KEY_6:
			_withdraw_cove_storage_slot(2)


func _get_storage_key(key_event: InputEventKey) -> int:
	if _key_matches(key_event, KEY_1):
		return KEY_1
	if _key_matches(key_event, KEY_2):
		return KEY_2
	if _key_matches(key_event, KEY_3):
		return KEY_3
	if _key_matches(key_event, KEY_4):
		return KEY_4
	if _key_matches(key_event, KEY_5):
		return KEY_5
	if _key_matches(key_event, KEY_6):
		return KEY_6
	if _key_matches(key_event, KEY_X):
		return KEY_X
	return 0


func _storage_key_name(key: int) -> String:
	match key:
		KEY_1:
			return "1"
		KEY_2:
			return "2"
		KEY_3:
			return "3"
		KEY_4:
			return "4"
		KEY_5:
			return "5"
		KEY_6:
			return "6"
	return "X"


func _can_open_cove_storage() -> bool:
	return (
		not _player_aboard_ship
		and _player_shore_id == "cove"
		and _player_near_cove_storage
		and not _dialogue_open
		and not waypoint_display.chart_visible
		and not _chart_release_pending
		and not _cargo_choice_open
		and not _cargo_choice_release_pending
		and not _storage_view_open
		and not _storage_release_pending
		and not _construction_view_open
		and not _construction_release_pending
	)


func _open_cove_storage() -> void:
	if not _can_open_cove_storage():
		return

	_storage_view_open = true
	_storage_open_count += 1
	_storage_pressed_keys.clear()
	_last_storage_action = "OPEN_COVE_STORAGE"
	_last_storage_result = "STORAGE_VIEW_OPENED"
	if (
		_storage_persistence_tracking
		and _storage_returned_ashore_after_save
		and _storage_walked_back_after_return
	):
		_storage_reopened_after_return = true
		_ship_lots_at_storage_reopen = ship.get_cargo_lots()
		_cove_lots_at_storage_reopen = cove_storage.get_cargo_lots()
		_storage_persistence_holds = _storage_matches_persistence_snapshot()
	player.movement_enabled = false
	ship.set_navigation_input_blocked(true)
	controls_help.text = STORAGE_CONTROLS_TEXT
	interaction_prompt.hide()
	sign_message.hide()
	_update_cargo_view()
	_update_storage_view()


func _close_cove_storage() -> void:
	if not _storage_view_open:
		return

	_saved_ship_cargo_on_close = ship.get_cargo_lots()
	_saved_cove_storage_on_close = cove_storage.get_cargo_lots()
	_saved_cove_storage_slots_on_close = cove_storage.get_storage_slots()
	_storage_lists_saved_on_close = true
	if (
		not _storage_persistence_tracking
		and _saved_cove_storage_on_close.has("TIMBER LOT")
	):
		_storage_persistence_tracking = true
		_persistence_ship_cargo = _saved_ship_cargo_on_close.duplicate()
		_persistence_cove_storage = _saved_cove_storage_on_close.duplicate()
		_persistence_cove_storage_slots = (
			_saved_cove_storage_slots_on_close.duplicate()
		)
		_storage_persistence_holds = true
	_storage_view_open = false
	_storage_release_pending = true
	_storage_close_count += 1
	_last_storage_action = "CLOSE_COVE_STORAGE"
	_last_storage_result = "SAVED_SHIP_AND_COVE_CARGO"
	storage_view.hide()
	player.movement_enabled = false
	ship.set_navigation_input_blocked(false)
	controls_help.text = STORAGE_RELEASE_CONTROLS_TEXT
	interaction_prompt.hide()
	_update_cargo_view()


func _store_ship_cargo_slot(slot_index: int) -> void:
	var ship_before: Array[String] = ship.get_cargo_lots()
	var storage_before: Array[String] = cove_storage.get_storage_slots()
	var world_before := _get_world_cargo_total()
	_last_storage_action = "STORE_SHIP_SLOT_%d" % (slot_index + 1)
	if slot_index < 0 or slot_index >= ship_before.size():
		_record_storage_action(
			"NO_CHANGE_EMPTY_SHIP_SLOT_%d" % (slot_index + 1),
			"",
			slot_index,
			-1,
			ship_before,
			storage_before,
			world_before,
		)
		return
	if not cove_storage.can_store_cargo_lot():
		_record_storage_action(
			"NO_CHANGE_COVE_STORAGE_FULL",
			ship_before[slot_index],
			slot_index,
			-1,
			ship_before,
			storage_before,
			world_before,
		)
		return

	var destination_slot: int = cove_storage.get_first_free_slot_index()
	var moved_lot: String = ship.remove_cargo_slot_for_storage(slot_index)
	if moved_lot.is_empty():
		_record_storage_action(
			"NO_CHANGE_SHIP_STATE",
			"",
			slot_index,
			destination_slot,
			ship_before,
			storage_before,
			world_before,
		)
		return
	if not cove_storage.store_cargo_lot(moved_lot):
		var restored: bool = ship.restore_cargo_slot_from_storage(
			slot_index,
			moved_lot,
		)
		_record_storage_action(
			(
				"ROLLED_BACK_COVE_STORAGE_STATE"
				if restored
				else "ATOMIC_TRANSFER_ROLLBACK_FAILED"
			),
			moved_lot,
			slot_index,
			destination_slot,
			ship_before,
			storage_before,
			world_before,
		)
		return

	_storage_stored_count += 1
	_record_storage_action(
		"STORED_%s_IN_COVE_SLOT_%d" % [
			_cargo_result_name(moved_lot),
			destination_slot + 1,
		],
		moved_lot,
		slot_index,
		destination_slot,
		ship_before,
		storage_before,
		world_before,
	)


func _withdraw_cove_storage_slot(slot_index: int) -> void:
	var ship_before: Array[String] = ship.get_cargo_lots()
	var storage_before: Array[String] = cove_storage.get_storage_slots()
	var world_before := _get_world_cargo_total()
	_last_storage_action = "WITHDRAW_COVE_SLOT_%d" % (slot_index + 1)
	if (
		slot_index < 0
		or slot_index >= storage_before.size()
		or storage_before[slot_index].is_empty()
	):
		_record_storage_action(
			"NO_CHANGE_EMPTY_COVE_STORAGE_SLOT_%d" % (slot_index + 1),
			"",
			-1,
			slot_index,
			ship_before,
			storage_before,
			world_before,
		)
		return
	if not ship.can_keep_cargo_lot():
		_record_storage_action(
			"NO_CHANGE_SHIP_CARGO_FULL",
			storage_before[slot_index],
			-1,
			slot_index,
			ship_before,
			storage_before,
			world_before,
		)
		return

	var destination_slot: int = ship_before.size()
	var moved_lot: String = cove_storage.remove_cargo_slot(slot_index)
	if moved_lot.is_empty():
		_record_storage_action(
			"NO_CHANGE_COVE_STORAGE_STATE",
			"",
			destination_slot,
			slot_index,
			ship_before,
			storage_before,
			world_before,
		)
		return
	if not ship.keep_cargo_lot(moved_lot):
		var restored: bool = cove_storage.restore_cargo_slot(
			slot_index,
			moved_lot,
		)
		_record_storage_action(
			(
				"ROLLED_BACK_SHIP_CARGO_STATE"
				if restored
				else "ATOMIC_TRANSFER_ROLLBACK_FAILED"
			),
			moved_lot,
			destination_slot,
			slot_index,
			ship_before,
			storage_before,
			world_before,
		)
		return

	_storage_withdrawn_count += 1
	_record_storage_action(
		"WITHDREW_%s_TO_SHIP_SLOT_%d" % [
			_cargo_result_name(moved_lot),
			destination_slot + 1,
		],
		moved_lot,
		destination_slot,
		slot_index,
		ship_before,
		storage_before,
		world_before,
	)


func _record_storage_action(
	result: String,
	lot_name: String,
	ship_slot_index: int,
	storage_slot_index: int,
	ship_before: Array[String],
	storage_before: Array[String],
	world_before: int,
) -> void:
	_last_storage_result = result
	var ship_after: Array[String] = ship.get_cargo_lots()
	var storage_after: Array[String] = cove_storage.get_storage_slots()
	var world_after := _get_world_cargo_total()
	_last_storage_transfer_evidence = {
		"action": _last_storage_action,
		"result": result,
		"lot_name": lot_name,
		"ship_slot": ship_slot_index + 1 if ship_slot_index >= 0 else 0,
		"storage_slot": storage_slot_index + 1 if storage_slot_index >= 0 else 0,
		"ship_before": ship_before,
		"ship_after": ship_after,
		"storage_before": storage_before,
		"storage_after": storage_after,
		"ship_used_before": ship_before.size(),
		"ship_used_after": ship_after.size(),
		"storage_used_before": _count_occupied_storage_slots(storage_before),
		"storage_used_after": _count_occupied_storage_slots(storage_after),
		"world_total_before": world_before,
		"world_total_after": world_after,
		"world_conserved": world_before == world_after,
		"no_state_change": (
			ship_before == ship_after and storage_before == storage_after
		),
	}
	_update_cargo_view()
	_update_storage_view()


func _count_occupied_storage_slots(storage_slots: Array[String]) -> int:
	var count := 0
	for lot_name in storage_slots:
		if not lot_name.is_empty():
			count += 1
	return count


func _handle_cargo_choice_input(key_event: InputEventKey) -> void:
	if not key_event.pressed:
		if _key_matches(key_event, KEY_E):
			_interact_held = false
		return
	if key_event.echo:
		return
	if _key_matches(key_event, KEY_X):
		_leave_pending_salvage_at_wreck()
		return
	if _key_matches(key_event, KEY_1):
		_replace_cargo_with_pending_salvage(0)
	elif _key_matches(key_event, KEY_2):
		_replace_cargo_with_pending_salvage(1)
	elif _key_matches(key_event, KEY_3):
		_replace_cargo_with_pending_salvage(2)


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
	if (
		_storage_view_open
		or _storage_release_pending
		or _construction_view_open
		or _construction_release_pending
	):
		return
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
		_prompt_refresh_after_navigation_release = true
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


func _update_cargo_choice_release_pending() -> void:
	if not _cargo_choice_release_pending or _cargo_choice_open:
		return
	if _is_any_cargo_choice_guard_key_pressed():
		return

	_cargo_choice_release_pending = false
	ship.set_navigation_input_blocked(
		false,
		_player_aboard_ship and not ship.is_docked,
	)
	player.movement_enabled = not _player_aboard_ship and not _dialogue_open
	controls_help.text = RELEASE_CONTROLS_TEXT
	_update_interaction_prompt()


func _update_storage_release_pending() -> void:
	if not _storage_release_pending or _storage_view_open:
		return
	if _is_any_storage_guard_key_pressed():
		player.movement_enabled = false
		return

	_storage_release_pending = false
	_storage_pressed_keys.clear()
	player.movement_enabled = not _player_aboard_ship and not _dialogue_open
	controls_help.text = _get_context_controls_text()
	_update_interaction_prompt()


func _update_construction_release_pending() -> void:
	if not _construction_release_pending or _construction_view_open:
		return
	if _is_any_construction_guard_key_pressed():
		player.movement_enabled = false
		return

	_construction_release_pending = false
	_construction_pressed_keys.clear()
	player.movement_enabled = not _player_aboard_ship and not _dialogue_open
	controls_help.text = _get_context_controls_text()
	_update_interaction_prompt()


func _refresh_prompt_after_navigation_release() -> void:
	if not _prompt_refresh_after_navigation_release:
		return
	if (
		waypoint_display.chart_visible
		or _chart_release_pending
		or _cargo_choice_open
		or _cargo_choice_release_pending
		or _storage_view_open
		or _storage_release_pending
		or _construction_view_open
		or _construction_release_pending
		or ship.navigation_input_blocked
		or ship.navigation_release_pending
	):
		return

	_prompt_refresh_after_navigation_release = false
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


func _is_any_cargo_choice_guard_key_pressed() -> bool:
	return (
		_is_any_movement_key_pressed()
		or Input.is_key_pressed(KEY_E)
		or Input.is_key_pressed(KEY_M)
		or Input.is_key_pressed(KEY_X)
		or Input.is_key_pressed(KEY_1)
		or Input.is_key_pressed(KEY_2)
		or Input.is_key_pressed(KEY_3)
	)


func _is_any_storage_guard_key_pressed() -> bool:
	return (
		_is_any_movement_key_pressed()
		or Input.is_key_pressed(KEY_E)
		or Input.is_key_pressed(KEY_M)
		or Input.is_key_pressed(KEY_X)
		or Input.is_key_pressed(KEY_1)
		or Input.is_key_pressed(KEY_2)
		or Input.is_key_pressed(KEY_3)
		or Input.is_key_pressed(KEY_4)
		or Input.is_key_pressed(KEY_5)
		or Input.is_key_pressed(KEY_6)
	)


func _is_any_construction_guard_key_pressed() -> bool:
	return (
		_is_any_movement_key_pressed()
		or Input.is_key_pressed(KEY_E)
		or Input.is_key_pressed(KEY_M)
		or Input.is_key_pressed(KEY_X)
	)


func _get_context_controls_text() -> String:
	if _construction_view_open:
		if construction_site.completed:
			return CONSTRUCTION_COMPLETE_CONTROLS_TEXT
		if construction_site.is_construction_available(cove_storage):
			return CONSTRUCTION_READY_CONTROLS_TEXT
		return CONSTRUCTION_UNAVAILABLE_CONTROLS_TEXT
	if _construction_release_pending:
		return CONSTRUCTION_RELEASE_CONTROLS_TEXT
	if _storage_view_open:
		return STORAGE_CONTROLS_TEXT
	if _storage_release_pending:
		return STORAGE_RELEASE_CONTROLS_TEXT
	if _cargo_choice_open:
		return CARGO_CHOICE_CONTROLS_TEXT
	if _cargo_choice_release_pending or ship.navigation_release_pending:
		return RELEASE_CONTROLS_TEXT
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
		(
			_player_aboard_ship
			and not waypoint_display.chart_visible
			and not _cargo_choice_open
			and not _cargo_choice_release_pending
			and not _storage_view_open
			and not _storage_release_pending
			and not _construction_view_open
			and not _construction_release_pending
		),
		(
			not waypoint_display.chart_visible
			and not _cargo_choice_open
			and not _cargo_choice_release_pending
			and not _storage_view_open
			and not _storage_release_pending
			and not _construction_view_open
			and not _construction_release_pending
		),
	)


func _update_salvage_persistence() -> void:
	if ship.timber_lots != 1 or _salvage_collection_position == Vector2.ZERO:
		return
	if ship.global_position.distance_to(_salvage_collection_position) > 1.0:
		_salvage_sailed_after_collection = true
		_timber_lots_after_sailing = ship.timber_lots


func _update_storage_persistence() -> void:
	if not _storage_persistence_tracking:
		return
	if (
		_storage_released_cove_dock_after_save
		and _player_aboard_ship
		and not ship.is_docked
		and ship.global_position.distance_to(
			ship.get_dock_definition("cove")["snap_position"]
		) > 8.0
	):
		_storage_sailed_after_save = true
		_ship_lots_after_storage_sailing = ship.get_cargo_lots()
		_cove_lots_after_storage_sailing = cove_storage.get_cargo_lots()
		_storage_persistence_holds = _storage_matches_persistence_snapshot()


func _update_construction_persistence() -> void:
	if not _construction_persistence_tracking:
		return
	if (
		_construction_released_cove_dock
		and _player_aboard_ship
		and not ship.is_docked
		and ship.global_position.distance_to(
			ship.get_dock_definition("cove")["snap_position"]
		) > 250.0
	):
		_construction_sailed_away = true


func _storage_matches_persistence_snapshot() -> bool:
	return (
		ship.get_cargo_lots() == _persistence_ship_cargo
		and cove_storage.get_cargo_lots() == _persistence_cove_storage
		and cove_storage.get_storage_slots() == _persistence_cove_storage_slots
	)


func _get_world_cargo_total() -> int:
	return (
		ship.get_cargo_lots().size()
		+ wreck_opportunity.get_salvage_lots().size()
		+ cove_storage.get_cargo_lots().size()
	)


func _salvage_wreck() -> void:
	if not wreck_opportunity.is_salvage_eligible():
		wreck_opportunity.try_collect_timber_lot()
		_last_cargo_action = "SALVAGE_ATTEMPT"
		_last_cargo_result = "NO_CHANGE_INELIGIBLE"
		_update_interaction_prompt()
		return

	var salvage_lot := wreck_opportunity.get_next_salvage_lot()
	if salvage_lot.is_empty():
		_last_cargo_action = "SALVAGE_ATTEMPT"
		_last_cargo_result = "NO_CHANGE_WRECK_EMPTY"
		return
	if not ship.can_keep_cargo_lot():
		_open_cargo_choice(salvage_lot)
		return
	if not wreck_opportunity.can_take_next_salvage_lot(salvage_lot):
		_last_cargo_action = "KEEP_NEW_LOT"
		_last_cargo_result = "NO_CHANGE_WRECK_STATE"
		_update_interaction_prompt()
		return
	if not ship.keep_cargo_lot(salvage_lot):
		_last_cargo_action = "KEEP_NEW_LOT"
		_last_cargo_result = "NO_CHANGE_CARGO_FULL"
		return
	if not wreck_opportunity.take_next_salvage_lot(salvage_lot):
		ship.undo_last_kept_cargo_lot(salvage_lot)
		_last_cargo_action = "KEEP_NEW_LOT"
		_last_cargo_result = "ROLLED_BACK_WRECK_STATE"
		return

	_cargo_kept_count += 1
	_last_cargo_action = "KEEP_NEW_LOT"
	_last_cargo_result = "KEPT_%s" % _cargo_result_name(salvage_lot)
	_salvage_collection_position = ship.global_position
	_last_salvage_eligible = false
	_update_cargo_view()
	_update_interaction_prompt()


func _open_cargo_choice(salvage_lot: String) -> void:
	if (
		_cargo_choice_open
		or salvage_lot.is_empty()
		or not wreck_opportunity.mark_salvage_choice_pending(salvage_lot)
	):
		return
	_pending_salvage_lot = salvage_lot
	_cargo_choice_open = true
	_cargo_choice_opened_count += 1
	_last_cargo_action = "FULL_SHIP_SALVAGE_ATTEMPT"
	_last_cargo_result = "CARGO_CHOICE_REQUIRED"
	ship.set_navigation_input_blocked(true)
	player.movement_enabled = false
	controls_help.text = CARGO_CHOICE_CONTROLS_TEXT
	interaction_prompt.hide()
	_update_cargo_view()


func _leave_pending_salvage_at_wreck() -> void:
	if (
		not _cargo_choice_open
		or not wreck_opportunity.leave_salvage_lot_at_wreck(
			_pending_salvage_lot
		)
	):
		return
	_cargo_left_count += 1
	_cargo_choice_resolution_count += 1
	_last_cargo_action = "LEAVE_NEW_LOT"
	_last_cargo_result = "LEFT_%s_AT_WRECK" % _cargo_result_name(
		_pending_salvage_lot
	)
	_close_cargo_choice()


func _replace_cargo_with_pending_salvage(slot_index: int) -> void:
	if (
		not _cargo_choice_open
		or _pending_salvage_lot.is_empty()
		or wreck_opportunity.get_next_salvage_lot() != _pending_salvage_lot
	):
		return
	var removed_lot: String = ship.replace_cargo_slot(
		slot_index,
		_pending_salvage_lot,
	)
	if removed_lot.is_empty():
		_last_cargo_action = "REPLACE_CARGO_SLOT"
		_last_cargo_result = "NO_CHANGE_INVALID_SLOT"
		return
	if not wreck_opportunity.exchange_salvage_lot(
		_pending_salvage_lot,
		removed_lot,
	):
		ship.replace_cargo_slot(slot_index, removed_lot)
		_last_cargo_action = "REPLACE_CARGO_SLOT"
		_last_cargo_result = "ROLLED_BACK_WRECK_STATE"
		return

	_cargo_replaced_count += 1
	_cargo_choice_resolution_count += 1
	_last_cargo_action = "REPLACE_CARGO_SLOT_%d" % (slot_index + 1)
	_last_cargo_result = "REPLACED_%s_WITH_%s" % [
		_cargo_result_name(removed_lot),
		_cargo_result_name(_pending_salvage_lot),
	]
	_close_cargo_choice()


func _close_cargo_choice() -> void:
	_cargo_choice_open = false
	_cargo_choice_release_pending = true
	_prompt_refresh_after_navigation_release = true
	_pending_salvage_lot = ""
	cargo_choice_view.hide()
	controls_help.text = RELEASE_CONTROLS_TEXT
	_update_cargo_view()
	_update_interaction_prompt()


func _cargo_result_name(lot_name: String) -> String:
	return lot_name.to_upper().replace(" ", "_")


func _update_cargo_view() -> void:
	var cargo_lots: Array[String] = ship.get_cargo_lots()
	var cargo_lines := PackedStringArray([
		"CARGO · USED %d/%d · FREE %d" % [
			cargo_lots.size(),
			ship.get_cargo_limit(),
			ship.get_cargo_limit() - cargo_lots.size(),
		],
	])
	for slot_index in range(ship.get_cargo_limit()):
		var slot_text := "EMPTY"
		if slot_index < cargo_lots.size():
			slot_text = cargo_lots[slot_index]
		cargo_lines.append("SLOT %d  %s" % [slot_index + 1, slot_text])
	var wreck_lots := wreck_opportunity.get_salvage_lots()
	cargo_lines.append("WRECK  %d LOTS REMAIN" % wreck_lots.size())
	if _cargo_choice_open:
		cargo_lines.append("PENDING  %s" % _pending_salvage_lot)
	else:
		cargo_lines.append("PENDING  NONE")
	cargo_details.text = "\n".join(cargo_lines)
	if _storage_view_open or _construction_view_open:
		cargo_view.hide()
	else:
		cargo_view.show()

	if not _cargo_choice_open:
		cargo_choice_view.hide()
		return
	cargo_choice_title.text = "CARGO FULL · NEW %s" % _pending_salvage_lot
	var choice_lines := PackedStringArray()
	for slot_index in range(cargo_lots.size()):
		choice_lines.append(
			"[%d] REPLACE %s" % [slot_index + 1, cargo_lots[slot_index]]
		)
	choice_lines.append("[X] LEAVE %s AT WRECK" % _pending_salvage_lot)
	cargo_choice_details.text = "\n".join(choice_lines)
	cargo_choice_view.show()


func _update_storage_view() -> void:
	var ship_lots: Array[String] = ship.get_cargo_lots()
	var storage_lots: Array[String] = cove_storage.get_cargo_lots()
	var storage_slots: Array[String] = cove_storage.get_storage_slots()
	var lines := PackedStringArray([
		"SHIP CARGO · USED %d/%d · FREE %d" % [
			ship_lots.size(),
			ship.get_cargo_limit(),
			ship.get_cargo_limit() - ship_lots.size(),
		],
	])
	for slot_index in range(ship.get_cargo_limit()):
		var ship_lot_name := "EMPTY"
		if slot_index < ship_lots.size():
			ship_lot_name = ship_lots[slot_index]
		lines.append("[%d] SLOT %d  %s" % [
			slot_index + 1,
			slot_index + 1,
			ship_lot_name,
		])
	lines.append("")
	lines.append("COVE STORAGE · USED %d/%d · FREE %d" % [
		storage_lots.size(),
		cove_storage.get_storage_limit(),
		cove_storage.get_storage_limit() - storage_lots.size(),
	])
	for slot_index in range(cove_storage.get_storage_limit()):
		var storage_lot_name := "EMPTY"
		if not storage_slots[slot_index].is_empty():
			storage_lot_name = storage_slots[slot_index]
		lines.append("[%d] SLOT %d  %s" % [
			slot_index + 4,
			slot_index + 1,
			storage_lot_name,
		])
	storage_details.text = "\n".join(lines)
	storage_result.text = _last_storage_result.replace("_", " ")
	if _storage_view_open:
		storage_view.show()
	else:
		storage_view.hide()


func _update_construction_view() -> void:
	var site_state := construction_site.get_playtest_state(cove_storage)
	construction_title.text = site_state["building_name"]
	construction_details.text = (
		"FIXED COST · %s\nCOVE-STORED TIMBER · %d/%d" % [
			site_state["fixed_cost_text"],
			site_state["stored_cost_lot_count"],
			site_state["cost_lot_count"],
		]
	)
	if site_state["completed"]:
		construction_result.text = "CONSTRUCTION COMPLETE"
		construction_controls.text = "[X] CLOSE · E CANNOT BUILD AGAIN"
	elif site_state["available"]:
		construction_result.text = "READY TO BUILD"
		construction_controls.text = "[E] BUILD STORAGE SHED · [X] CLOSE"
	else:
		construction_result.text = "CONSTRUCTION UNAVAILABLE"
		construction_controls.text = "[E] BUILD UNAVAILABLE · [X] CLOSE"
	if _construction_view_open:
		construction_view.show()
	else:
		construction_view.hide()


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


func _on_cove_storage_body_entered(body: Node2D) -> void:
	if body != player:
		return

	_player_near_cove_storage = true
	if _storage_returned_ashore_after_save:
		_storage_walked_back_after_return = true
	_update_interaction_prompt()


func _on_cove_storage_body_exited(body: Node2D) -> void:
	if body != player:
		return

	_player_near_cove_storage = false
	_update_interaction_prompt()


func _on_construction_site_body_entered(body: Node2D) -> void:
	if body != player:
		return

	_player_near_construction_site = true
	if _construction_returned_ashore:
		_construction_walked_back = true
		var site_state := construction_site.get_playtest_state(cove_storage)
		_construction_finished_visible_after_return = (
			site_state["finished_visual_visible"]
		)
		_construction_site_absent_after_return = (
			not site_state["unbuilt_visual_visible"]
		)
	_update_interaction_prompt()


func _on_construction_site_body_exited(body: Node2D) -> void:
	if body != player:
		return

	_player_near_construction_site = false
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
	if (
		_storage_view_open
		or _storage_release_pending
		or _construction_view_open
		or _construction_release_pending
	):
		return
	_read_count += 1
	sign_message.text = sign.interaction_message
	sign_message.show()


func _enter_ship() -> void:
	if (
		_player_aboard_ship
		or not _player_near_ship_entry
		or _storage_view_open
		or _storage_release_pending
		or _construction_view_open
		or _construction_release_pending
	):
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
	if (
		not _player_aboard_ship
		or not ship.can_leave_at_damaged_dock()
		or _storage_view_open
		or _storage_release_pending
		or _construction_view_open
		or _construction_release_pending
	):
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
	if (
		not _player_aboard_ship
		or ship.is_docked
		or _storage_view_open
		or _storage_release_pending
		or _construction_view_open
		or _construction_release_pending
	):
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
	if dock_id == "cove" and _storage_sailed_after_save:
		_storage_return_docked_after_save = true
		_ship_lots_at_storage_return_dock = ship.get_cargo_lots()
		_cove_lots_at_storage_return_dock = cove_storage.get_cargo_lots()
		_storage_persistence_holds = _storage_matches_persistence_snapshot()
	if dock_id == "cove" and _construction_sailed_away:
		_construction_return_docked = true
	controls_help.text = DOCKED_CONTROLS_TEXT
	_update_interaction_prompt()


func _go_ashore() -> void:
	if (
		not _player_aboard_ship
		or not ship.is_docked
		or _storage_view_open
		or _storage_release_pending
		or _construction_view_open
		or _construction_release_pending
	):
		return

	var definition: Dictionary = ship.get_current_dock_definition()
	if definition.is_empty():
		return

	_player_aboard_ship = false
	_player_shore_id = String(definition["id"])
	if _player_shore_id == "cove" and ship.timber_lots == 1:
		_cove_ashore_after_salvage = true
		_timber_lots_while_ashore = ship.timber_lots
	if _player_shore_id == "cove" and _storage_return_docked_after_save:
		_storage_returned_ashore_after_save = true
		_storage_persistence_holds = _storage_matches_persistence_snapshot()
	if _player_shore_id == "cove" and _construction_return_docked:
		_construction_returned_ashore = true
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
	if (
		_player_shore_id.is_empty()
		or not _player_near_ship_return
		or _storage_view_open
		or _storage_release_pending
		or _construction_view_open
		or _construction_release_pending
	):
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
	if returning_shore_id == "cove" and _storage_persistence_tracking:
		_storage_returned_to_ship_after_save = true
		_storage_persistence_holds = _storage_matches_persistence_snapshot()
	if returning_shore_id == "cove" and _construction_persistence_tracking:
		_construction_returned_to_ship = true
	_last_ship_docked = true
	controls_help.text = DOCKED_CONTROLS_TEXT
	_update_interaction_prompt()


func _start_dialogue() -> void:
	if (
		_storage_view_open
		or _storage_release_pending
		or _construction_view_open
		or _construction_release_pending
	):
		return
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
	if (
		_dialogue_open
		or waypoint_display.chart_visible
		or _chart_release_pending
		or _cargo_choice_open
		or _cargo_choice_release_pending
		or _storage_view_open
		or _storage_release_pending
		or _construction_view_open
		or _construction_release_pending
		or ship.navigation_release_pending
	):
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
			var next_salvage_lot := wreck_opportunity.get_next_salvage_lot()
			if next_salvage_lot == "TIMBER LOT":
				interaction_prompt.text = "[E] SALVAGE ONE TIMBER LOT"
			else:
				interaction_prompt.text = "[E] SALVAGE %s" % next_salvage_lot
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

	if _can_open_construction_site():
		interaction_prompt.text = "[E] OPEN STORAGE SHED SITE"
		interaction_prompt.show()
		return

	if _can_open_cove_storage():
		interaction_prompt.text = "[E] OPEN COVE STORAGE"
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
	var storage_state: Dictionary = cove_storage.get_playtest_state()
	var construction_state: Dictionary = construction_site.get_playtest_state(
		cove_storage
	)
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
		"cargo_limit": ship_state["cargo_limit"],
		"cargo_used_slots": ship_state["cargo_used_slots"],
		"cargo_free_slots": ship_state["cargo_free_slots"],
		"cargo_lots": ship_state["cargo_lots"],
		"cargo_total_lots_in_world": (
			ship_state["cargo_used_slots"]
			+ wreck_state["wreck_salvage_lot_count"]
			+ storage_state["storage_used_slots"]
		),
		"cargo_deliberately_consumed_lots": (
			construction_state["consumed_lot_count"]
		),
		"cargo_accounted_total_including_consumed": (
			ship_state["cargo_used_slots"]
			+ wreck_state["wreck_salvage_lot_count"]
			+ storage_state["storage_used_slots"]
			+ construction_state["consumed_lot_count"]
		),
		"cargo_initial_total_lots_in_world": (
			ship_state["starting_cargo_used_slots"]
			+ wreck_state["wreck_initial_salvage_lot_count"]
		),
		"cargo_lot_conservation_holds": (
			ship_state["cargo_used_slots"]
			+ wreck_state["wreck_salvage_lot_count"]
			+ storage_state["storage_used_slots"]
			+ construction_state["consumed_lot_count"]
			== ship_state["starting_cargo_used_slots"]
			+ wreck_state["wreck_initial_salvage_lot_count"]
		),
		"cargo_conservation_including_consumed_holds": (
			ship_state["cargo_used_slots"]
			+ wreck_state["wreck_salvage_lot_count"]
			+ storage_state["storage_used_slots"]
			+ construction_state["consumed_lot_count"]
			== ship_state["starting_cargo_used_slots"]
			+ wreck_state["wreck_initial_salvage_lot_count"]
		),
		"cargo_unaccounted_loss_count": (
			ship_state["starting_cargo_used_slots"]
			+ wreck_state["wreck_initial_salvage_lot_count"]
			- ship_state["cargo_used_slots"]
			- wreck_state["wreck_salvage_lot_count"]
			- storage_state["storage_used_slots"]
			- construction_state["consumed_lot_count"]
		),
		"cargo_world_total_includes_cove_storage": true,
		"cove_storage_place_count": storage_state["place_count"],
		"cove_storage_position": storage_state["position"],
		"cove_storage_interaction_range": storage_state["interaction_range"],
		"cove_storage_visible": storage_state["visible"],
		"storage_chest_position": storage_state["position"],
		"storage_chest_range": storage_state["interaction_range"],
		"storage_chest_visible": storage_state["visible"],
		"storage_chest_interaction_region_count": (
			storage_state["interaction_region_count"]
		),
		"cove_storage_distance_from_ship_return": (
			cove_storage.global_position.distance_to(
				ship.get_dock_definition("cove")["shore_position"]
			)
		),
		"cove_storage_outside_ship_return_range": (
			cove_storage.global_position.distance_to(
				ship.get_dock_definition("cove")["shore_position"]
			) > SHORE_RETURN_DISTANCE + storage_state["interaction_range"]
		),
		"player_near_cove_storage": _player_near_cove_storage,
		"storage_prompt_visible": (
			interaction_prompt.visible
			and interaction_prompt.text == "[E] OPEN COVE STORAGE"
		),
		"storage_prompt_text": (
			interaction_prompt.text
			if interaction_prompt.visible
			and interaction_prompt.text == "[E] OPEN COVE STORAGE"
			else ""
		),
		"storage_limit": storage_state["storage_limit"],
		"storage_used_slots": storage_state["storage_used_slots"],
		"storage_free_slots": storage_state["storage_free_slots"],
		"storage_lots": storage_state["storage_lots"],
		"storage_slots": storage_state["storage_slots"],
		"storage_view_open": _storage_view_open,
		"storage_view_visible": storage_view.visible,
		"storage_view_text": (
			"%s\n%s\n%s" % [
				$Interface/StorageView/StorageTitle.text,
				storage_details.text,
				storage_result.text,
			]
			if storage_view.visible
			else ""
		),
		"storage_transfer_controls": {
			"ship_to_storage": "1_OR_2_OR_3",
			"storage_to_ship": "4_OR_5_OR_6",
			"close": "X",
			"visible_text": STORAGE_CONTROLS_TEXT,
		},
		"last_storage_action": _last_storage_action,
		"last_storage_result": _last_storage_result,
		"last_storage_transfer_evidence": _last_storage_transfer_evidence.duplicate(true),
		"storage_stored_count": _storage_stored_count,
		"storage_withdrawn_count": _storage_withdrawn_count,
		"storage_open_count": _storage_open_count,
		"storage_close_count": _storage_close_count,
		"storage_release_pending": _storage_release_pending,
		"storage_input_blocked": (
			(_storage_view_open or _storage_release_pending)
			and not player_state["movement_enabled"]
		),
		"storage_modal_blocks": {
			"walking": _storage_view_open and not player_state["movement_enabled"],
			"chart": _storage_view_open and not waypoint_state["chart_visible"],
			"ship_return": _storage_view_open,
			"dialogue": _storage_view_open and not _dialogue_open,
			"storage_reopen": _storage_view_open,
			"other_interactions": _storage_view_open,
		},
		"storage_lists_saved_on_close": _storage_lists_saved_on_close,
		"saved_ship_cargo_on_storage_close": _saved_ship_cargo_on_close.duplicate(),
		"saved_cove_storage_on_close": _saved_cove_storage_on_close.duplicate(),
		"saved_cove_storage_slots_on_close": (
			_saved_cove_storage_slots_on_close.duplicate()
		),
		"storage_persistence": {
			"tracking": _storage_persistence_tracking,
			"saved_ship_snapshot": _persistence_ship_cargo.duplicate(),
			"saved_storage_snapshot": _persistence_cove_storage.duplicate(),
			"saved_storage_slot_snapshot": (
				_persistence_cove_storage_slots.duplicate()
			),
			"returned_to_ship_after_save": _storage_returned_to_ship_after_save,
			"released_cove_dock_after_save": _storage_released_cove_dock_after_save,
			"sailed_after_save": _storage_sailed_after_save,
			"ship_lots_after_sailing": _ship_lots_after_storage_sailing.duplicate(),
			"storage_lots_after_sailing": _cove_lots_after_storage_sailing.duplicate(),
			"return_docked_after_save": _storage_return_docked_after_save,
			"ship_lots_at_return_dock": _ship_lots_at_storage_return_dock.duplicate(),
			"storage_lots_at_return_dock": _cove_lots_at_storage_return_dock.duplicate(),
			"returned_ashore_after_save": _storage_returned_ashore_after_save,
			"walked_back_to_storage": _storage_walked_back_after_return,
			"reopened_after_return": _storage_reopened_after_return,
			"ship_lots_at_reopen": _ship_lots_at_storage_reopen.duplicate(),
			"storage_lots_at_reopen": _cove_lots_at_storage_reopen.duplicate(),
			"cargo_lists_unchanged_through_reopen": _storage_persistence_holds,
		},
		"construction_site_count": construction_state["construction_site_node_count"],
		"construction_site_position": construction_state["position"],
		"construction_site_interaction_range": construction_state["interaction_range"],
		"construction_site_interaction_region_count": (
			construction_state["interaction_region_count"]
		),
		"construction_site_interaction_enabled": (
			construction_state["interaction_enabled"]
		),
		"construction_building_name": construction_state["building_name"],
		"construction_cost_lot_name": construction_state["cost_lot_name"],
		"construction_cost_lot_count": construction_state["cost_lot_count"],
		"construction_fixed_cost_text": construction_state["fixed_cost_text"],
		"construction_cove_stored_timber_count": (
			construction_state["stored_cost_lot_count"]
		),
		"construction_ship_timber_count": ship_state["timber_lots"],
		"construction_counts_cove_storage_only": true,
		"construction_available": construction_state["available"],
		"construction_complete": construction_state["completed"],
		"construction_completion_count": construction_state["completion_count"],
		"construction_consumed_timber_count": (
			construction_state["consumed_lot_count"]
		),
		"construction_attempt_count": construction_state["attempt_count"],
		"construction_denied_attempt_count": (
			construction_state["denied_attempt_count"]
		),
		"construction_post_completion_attempt_count": (
			construction_state["repeat_attempt_count"]
		),
		"construction_last_site_result": construction_state["last_result"],
		"construction_unbuilt_visual_owner_count": (
			construction_state["unbuilt_visual_owner_count"]
		),
		"finished_storage_shed_visual_owner_count": (
			construction_state["finished_visual_owner_count"]
		),
		"construction_site_visible": construction_state["unbuilt_visual_visible"],
		"finished_storage_shed_visible": (
			construction_state["finished_visual_visible"]
		),
		"construction_visible_visual_count": (
			construction_state["visible_visual_count"]
		),
		"construction_visuals_never_overlap": construction_state["visuals_exclusive"],
		"player_near_construction_site": _player_near_construction_site,
		"construction_prompt_visible": (
			interaction_prompt.visible
			and interaction_prompt.text == "[E] OPEN STORAGE SHED SITE"
		),
		"construction_prompt_text": (
			interaction_prompt.text
			if interaction_prompt.visible
			and interaction_prompt.text == "[E] OPEN STORAGE SHED SITE"
			else ""
		),
		"construction_view_open": _construction_view_open,
		"construction_view_visible": construction_view.visible,
		"construction_view_title": construction_title.text,
		"construction_view_details": construction_details.text,
		"construction_view_status": construction_result.text,
		"construction_view_controls": construction_controls.text,
		"construction_view_text": (
			"%s\n%s\n%s\n%s" % [
				construction_title.text,
				construction_details.text,
				construction_result.text,
				construction_controls.text,
			]
			if construction_view.visible
			else ""
		),
		"construction_controls": {
			"build": "E",
			"close": "X",
			"ready_text": CONSTRUCTION_READY_CONTROLS_TEXT,
			"unavailable_text": CONSTRUCTION_UNAVAILABLE_CONTROLS_TEXT,
			"complete_text": CONSTRUCTION_COMPLETE_CONTROLS_TEXT,
		},
		"last_construction_action": _last_construction_action,
		"last_construction_result": _last_construction_result,
		"last_construction_attempt_evidence": (
			_last_construction_attempt_evidence.duplicate(true)
		),
		"last_denied_construction_evidence": (
			_last_denied_construction_evidence.duplicate(true)
		),
		"successful_construction_evidence": (
			_successful_construction_evidence.duplicate(true)
		),
		"post_completion_attempt_evidence": (
			_post_completion_attempt_evidence.duplicate(true)
		),
		"construction_open_count": _construction_open_count,
		"construction_close_count": _construction_close_count,
		"construction_held_input_count": _construction_held_input_count,
		"construction_blocked_input_count": _construction_blocked_input_count,
		"construction_release_pending": _construction_release_pending,
		"construction_input_blocked": (
			(_construction_view_open or _construction_release_pending)
			and not player_state["movement_enabled"]
		),
		"construction_release_guard_keys": (
			"E_X_M_WASD_AND_ARROW_KEYS"
		),
		"construction_modal_blocks": {
			"walking": (
				_construction_view_open and not player_state["movement_enabled"]
			),
			"chart": (
				_construction_view_open and not waypoint_state["chart_visible"]
			),
			"dialogue": _construction_view_open and not _dialogue_open,
			"ship_return": _construction_view_open,
			"storage": _construction_view_open and not _storage_view_open,
			"salvage": _construction_view_open,
			"docking": _construction_view_open,
			"other_interactions": _construction_view_open,
		},
		"construction_does_not_increase_storage_capacity": (
			storage_state["storage_limit"] == CoveStorageChest.STORAGE_LIMIT
		),
		"construction_persistence": {
			"tracking": _construction_persistence_tracking,
			"returned_to_ship": _construction_returned_to_ship,
			"released_cove_dock": _construction_released_cove_dock,
			"sailed_away": _construction_sailed_away,
			"return_docked": _construction_return_docked,
			"returned_ashore": _construction_returned_ashore,
			"walked_back_to_building": _construction_walked_back,
			"finished_shed_visible_after_return": (
				_construction_finished_visible_after_return
			),
			"construction_site_absent_after_return": (
				_construction_site_absent_after_return
			),
			"completion_count_after_return": (
				construction_state["completion_count"]
			),
		},
		"starting_cargo_lots": ship_state["starting_cargo_lots"],
		"all_but_one_slot_full_at_start": (
			ship_state["all_but_one_slot_full_at_start"]
		),
		"max_used_slots_observed": ship_state["max_used_slots_observed"],
		"cargo_limit_never_exceeded": ship_state["cargo_limit_never_exceeded"],
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
			ship_state["navigation_release_pending"]
			or _chart_release_pending
			or _cargo_choice_release_pending
			or _storage_release_pending
			or _construction_release_pending
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
		"wreck_salvage_lots": wreck_state["wreck_salvage_lots"],
		"wreck_salvage_lot_count": wreck_state["wreck_salvage_lot_count"],
		"wreck_initial_salvage_lots": wreck_state["wreck_initial_salvage_lots"],
		"wreck_initial_salvage_lot_count": (
			wreck_state["wreck_initial_salvage_lot_count"]
		),
		"wreck_has_more_lots_than_ship_limit_at_start": (
			wreck_state["wreck_initial_salvage_lot_count"]
			> ship_state["cargo_limit"]
		),
		"next_salvage_lot": wreck_state["next_salvage_lot"],
		"salvage_range": wreck_state["salvage_range"],
		"salvage_max_speed": wreck_state["salvage_max_speed"],
		"salvage_eligibility": wreck_state["salvage_eligibility"],
		"salvage_eligible": wreck_state["salvage_eligible"],
		"salvage_prompt_visible": (
			interaction_prompt.visible
			and interaction_prompt.text.begins_with("[E] SALVAGE")
		),
		"salvage_prompt_text": (
			interaction_prompt.text
			if interaction_prompt.visible
			and interaction_prompt.text.begins_with("[E] SALVAGE")
			else ""
		),
		"cargo_view_visible": cargo_view.visible,
		"cargo_view_text": cargo_details.text,
		"pending_salvage_lot": _pending_salvage_lot,
		"pending_salvage_lot_still_at_wreck": (
			_pending_salvage_lot.is_empty()
			or wreck_state["next_salvage_lot"] == _pending_salvage_lot
		),
		"cargo_choice_open": _cargo_choice_open,
		"cargo_choice_prompt_visible": cargo_choice_view.visible,
		"cargo_choice_prompt_text": (
			"%s\n%s" % [cargo_choice_title.text, cargo_choice_details.text]
			if cargo_choice_view.visible
			else ""
		),
		"cargo_choice_prompt": {
			"visible": cargo_choice_view.visible,
			"title": cargo_choice_title.text,
			"text": cargo_choice_details.text,
			"controls": CARGO_CHOICE_CONTROLS_TEXT,
		},
		"cargo_choice_navigation_blocked": (
			_cargo_choice_open and ship_state["navigation_input_blocked"]
		),
		"cargo_choice_chart_blocked": _cargo_choice_open,
		"cargo_choice_docking_blocked": _cargo_choice_open,
		"cargo_choice_other_interactions_blocked": _cargo_choice_open,
		"cargo_choice_release_pending": _cargo_choice_release_pending,
		"last_cargo_action": _last_cargo_action,
		"last_cargo_result": _last_cargo_result,
		"cargo_kept_count": _cargo_kept_count,
		"cargo_left_count": _cargo_left_count,
		"cargo_replaced_count": _cargo_replaced_count,
		"cargo_choice_opened_count": _cargo_choice_opened_count,
		"cargo_choice_resolution_count": _cargo_choice_resolution_count,
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
