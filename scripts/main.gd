extends Node2D

const TradeContact := preload("res://scripts/trade_contact.gd")
const PortConditionState := preload("res://scripts/port_condition.gd")
const TradeJournalState := preload("res://scripts/trade_journal.gd")
const ShipFoodState := preload("res://scripts/ship_food.gd")
const ShipAmmunitionState := preload("res://scripts/ship_ammunition.gd")
const InspectableTargetShipState := preload(
	"res://scripts/inspectable_target_ship.gd"
)
const TargetBoardingDeckState := preload(
	"res://scripts/target_boarding_deck.gd"
)
const PrizeActionState := preload("res://scripts/prize_actions.gd")
const WorldHeatState := preload("res://scripts/world_heat.gd")
const PirateHunterShipState := preload("res://scripts/pirate_hunter_ship.gd")
const DefeatRecoveryState := preload("res://scripts/defeat_recovery.gd")
const FishingAreaState := preload("res://scripts/fishing_area.gd")
const WeatherAreaState := preload("res://scripts/weather_area.gd")
const RuinExplorationState := preload("res://scripts/ruin_exploration.gd")
const StoryClueState := preload("res://scripts/story_clue.gd")
const MonsterHuntState := preload("res://scripts/monster_hunt.gd")
const ShipModuleLoadoutState := preload("res://scripts/ship_module_loadout.gd")
const DayNightCycleState := preload("res://scripts/day_night_cycle.gd")

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
@onready var port_trader = $InteractiveObjects/PortTrader
@onready var cove_buyer = $InteractiveObjects/CoveBuyer
@onready var sea_area = $SeaArea
@onready var cove = $Cove
@onready var day_night_cycle: DayNightCycleState = $DayNightCycle
@onready var wreck_opportunity: WreckOpportunity = $WreckOpportunity
@onready var fishing_area: FishingAreaState = $FishingArea
@onready var weather_area: WeatherAreaState = $WeatherArea
@onready var ruin_exploration: RuinExplorationState = $RuinExploration
@onready var story_clue: StoryClueState = $StoryClue
@onready var monster_hunt: MonsterHuntState = $MonsterHunt
@onready var ship_module_loadout: ShipModuleLoadoutState = (
	$InteractiveObjects/ShipModuleBench
)
@onready var inspection_targets: Array[InspectableTargetShipState] = [
	$InspectableShips/CoastalMerchant,
	$InspectableShips/NavalCourier,
	$InspectableShips/PirateHunter,
]
@onready var pirate_hunter: PirateHunterShipState = (
	$InspectableShips/PirateHunter
)
@onready var target_boarding_deck: TargetBoardingDeckState = $TargetBoardingDeck
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
@onready var relationship_view: ColorRect = $Interface/RelationshipView
@onready var relationship_details: Label = (
	$Interface/RelationshipView/RelationshipDetails
)
@onready var cove_time_view: ColorRect = $Interface/CoveTimeView
@onready var cove_time_title: Label = $Interface/CoveTimeView/TimeTitle
@onready var cove_time_status: Label = $Interface/CoveTimeView/TimeStatus
@onready var cargo_view: ColorRect = $Interface/CargoView
@onready var cargo_details: Label = $Interface/CargoView/CargoDetails
@onready var money_view: ColorRect = $Interface/MoneyView
@onready var money_details: Label = $Interface/MoneyView/MoneyDetails
@onready var heat_view: ColorRect = $Interface/HeatView
@onready var heat_title: Label = $Interface/HeatView/HeatTitle
@onready var heat_meter: ProgressBar = $Interface/HeatView/HeatMeter
@onready var heat_status: Label = $Interface/HeatView/HeatStatus
@onready var pirate_hunter_view: ColorRect = $Interface/PirateHunterView
@onready var pirate_hunter_status: Label = (
	$Interface/PirateHunterView/HunterStatus
)
@onready var food_view: ColorRect = $Interface/FoodView
@onready var food_title: Label = $Interface/FoodView/FoodTitle
@onready var food_status: Label = $Interface/FoodView/FoodStatus
@onready var food_details: Label = $Interface/FoodView/FoodDetails
@onready var hull_view: ColorRect = $Interface/HullView
@onready var hull_title: Label = $Interface/HullView/HullTitle
@onready var hull_meter: ProgressBar = $Interface/HullView/HullMeter
@onready var hull_status: Label = $Interface/HullView/HullStatus
@onready var crew_view: ColorRect = $Interface/CrewView
@onready var crew_title: Label = $Interface/CrewView/CrewTitle
@onready var crew_meter: ProgressBar = $Interface/CrewView/CrewMeter
@onready var crew_status: Label = $Interface/CrewView/CrewStatus
@onready var repair_view: ColorRect = $Interface/RepairView
@onready var repair_title: Label = $Interface/RepairView/RepairTitle
@onready var repair_cost: Label = $Interface/RepairView/RepairCost
@onready var repair_preview: Label = $Interface/RepairView/RepairPreview
@onready var repair_status: Label = $Interface/RepairView/RepairStatus
@onready var repair_result: Label = $Interface/RepairView/RepairResult
@onready var repair_controls: Label = $Interface/RepairView/RepairControls
@onready var target_inspection_view: ColorRect = $Interface/TargetInspectionView
@onready var inspection_title: Label = (
	$Interface/TargetInspectionView/InspectionTitle
)
@onready var inspection_target_name: Label = (
	$Interface/TargetInspectionView/InspectionTarget
)
@onready var inspection_details: Label = (
	$Interface/TargetInspectionView/InspectionDetails
)
@onready var inspection_controls: Label = (
	$Interface/TargetInspectionView/InspectionControls
)
@onready var broadside_view: ColorRect = $Interface/BroadsideView
@onready var broadside_title: Label = $Interface/BroadsideView/BroadsideTitle
@onready var broadside_areas: Label = $Interface/BroadsideView/BroadsideAreas
@onready var broadside_result: Label = $Interface/BroadsideView/BroadsideResult
@onready var ammunition_view: ColorRect = $Interface/AmmunitionView
@onready var ammunition_title: Label = $Interface/AmmunitionView/AmmunitionTitle
@onready var ammunition_status: Label = $Interface/AmmunitionView/AmmunitionStatus
@onready var ammunition_cargo: Label = $Interface/AmmunitionView/AmmunitionCargo
@onready var target_combat_view: ColorRect = $Interface/TargetCombatView
@onready var target_combat_title: Label = (
	$Interface/TargetCombatView/CombatTitle
)
@onready var attack_choices: Label = $Interface/TargetCombatView/AttackChoices
@onready var target_hull_value: Label = (
	$Interface/TargetCombatView/TargetHullValue
)
@onready var target_hull_meter: ProgressBar = (
	$Interface/TargetCombatView/TargetHullMeter
)
@onready var target_sail_value: Label = (
	$Interface/TargetCombatView/TargetSailValue
)
@onready var target_sail_meter: ProgressBar = (
	$Interface/TargetCombatView/TargetSailMeter
)
@onready var target_speed: Label = $Interface/TargetCombatView/TargetSpeed
@onready var target_route: Label = $Interface/TargetCombatView/TargetRoute
@onready var catch_status: Label = $Interface/TargetCombatView/CatchStatus
@onready var prize_view: ColorRect = $Interface/PrizeView
@onready var prize_title: Label = $Interface/PrizeView/PrizeTitle
@onready var prize_status: Label = $Interface/PrizeView/PrizeStatus
@onready var prize_details: Label = $Interface/PrizeView/PrizeDetails
@onready var prize_result: Label = $Interface/PrizeView/PrizeResult
@onready var prize_controls: Label = $Interface/PrizeView/PrizeControls
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
@onready var trade_view: ColorRect = $Interface/TradeView
@onready var trade_title: Label = $Interface/TradeView/TradeTitle
@onready var trade_details: Label = $Interface/TradeView/TradeDetails
@onready var trade_result: Label = $Interface/TradeView/TradeResult
@onready var trade_controls: Label = $Interface/TradeView/TradeControls
@onready var journal_view: ColorRect = $Interface/TradeJournalView
@onready var journal_title: Label = $Interface/TradeJournalView/JournalTitle
@onready var journal_status: Label = $Interface/TradeJournalView/JournalStatus
@onready var journal_details: Label = $Interface/TradeJournalView/JournalDetails
@onready var journal_controls: Label = $Interface/TradeJournalView/JournalControls
@onready var defeat_result_view: ColorRect = $Interface/DefeatResultView
@onready var defeat_result_title: Label = (
	$Interface/DefeatResultView/DefeatTitle
)
@onready var defeat_result_details: Label = (
	$Interface/DefeatResultView/DefeatDetails
)
@onready var defeat_result_controls: Label = (
	$Interface/DefeatResultView/DefeatControls
)
@onready var weather_view: ColorRect = $Interface/WeatherView
@onready var weather_title: Label = $Interface/WeatherView/WeatherTitle
@onready var weather_status: Label = $Interface/WeatherView/WeatherStatus
@onready var monster_hunt_view: ColorRect = $Interface/MonsterHuntView
@onready var monster_hunt_title: Label = (
	$Interface/MonsterHuntView/MonsterTitle
)
@onready var monster_hunt_status: Label = (
	$Interface/MonsterHuntView/MonsterStatus
)
@onready var monster_hunt_result: Label = (
	$Interface/MonsterHuntView/MonsterResult
)
@onready var ship_module_view: ColorRect = $Interface/ShipModuleView
@onready var ship_module_title: Label = $Interface/ShipModuleView/ModuleTitle
@onready var ship_module_status: Label = $Interface/ShipModuleView/ModuleStatus
@onready var ship_module_details: Label = $Interface/ShipModuleView/ModuleDetails
@onready var ship_module_result: Label = $Interface/ShipModuleView/ModuleResult
@onready var ship_module_controls: Label = $Interface/ShipModuleView/ModuleControls
@onready var controls_help: Label = $Interface/Controls
@onready var waypoint_display: WaypointDisplay = $Interface/WaypointDisplay

const COVE_CAMERA_POSITION := Vector2(576.0, 324.0)
const WALKING_CONTROLS_TEXT := "WASD / ARROWS TO MOVE · E INTERACT · M CHART · J JOURNAL"
const SAILING_CONTROLS_TEXT := "W / UP SAIL · A / D TURN · S / DOWN BRAKE · H HULL · K SAILS · Q LEFT · F RIGHT · P PURSUIT · V HARPOON · E ACTION · T WEATHER · M CHART · J JOURNAL"
const DOCKED_CONTROLS_TEXT := "E GO ASHORE · R REPAIR · W / UP SAIL AWAY · M CHART · J JOURNAL"
const CHART_CONTROLS_TEXT := "M CLOSE · 1 COVE · 2 ISLAND · 3 PORT · X CLEAR"
const CHART_STORY_CONTROLS_TEXT := (
	"M CLOSE · 1 COVE · 2 ISLAND · 3 PORT · 4 CLUE · X CLEAR"
)
const CARGO_CHOICE_CONTROLS_TEXT := "X LEAVE AT WRECK · 1 / 2 / 3 / 4 REPLACE CARGO SLOT"
const FISHING_CARGO_CHOICE_CONTROLS_TEXT := (
	"X DISCARD CAUGHT FISH · 1 / 2 / 3 / 4 REPLACE CARGO SLOT"
)
const RUIN_CARGO_CHOICE_CONTROLS_TEXT := (
	"X LEAVE TREASURE IN RUIN · 1 / 2 / 3 / 4 REPLACE CARGO SLOT"
)
const STORY_CLUE_CARGO_CHOICE_CONTROLS_TEXT := (
	"X LEAVE MAP FRAGMENT IN RUIN · 1 / 2 / 3 / 4 REPLACE CARGO SLOT"
)
const MONSTER_HUNT_CARGO_CHOICE_CONTROLS_TEXT := (
	"1 / 2 / 3 / 4 REPLACE CARGO SLOT · MONSTER PART MUST BE KEPT"
)
const MODULE_CONTROLS_TEXT := (
	"1 CARGO RACKS · 2 LONG GUNS · 3 FISHING GEAR · X CLOSE"
)
const MODULE_RELEASE_CONTROLS_TEXT := (
	"RELEASE E, X, 1-3, P, M, WASD / ARROW KEYS"
)
const STORAGE_CONTROLS_TEXT := "1 / 2 / 3 / 0 SHIP TO STORAGE · 4 / 5 / 6 STORAGE TO SHIP · X CLOSE"
const STORAGE_RELEASE_CONTROLS_TEXT := "RELEASE E, X, 0-6, M, WASD / ARROW KEYS"
const CONSTRUCTION_READY_CONTROLS_TEXT := "E BUILD STORAGE SHED · X CLOSE"
const CONSTRUCTION_UNAVAILABLE_CONTROLS_TEXT := "E BUILD UNAVAILABLE · X CLOSE"
const CONSTRUCTION_COMPLETE_CONTROLS_TEXT := "X CLOSE · E CANNOT BUILD AGAIN"
const CONSTRUCTION_RELEASE_CONTROLS_TEXT := "RELEASE E, X, M, WASD / ARROW KEYS"
const TRADE_BUY_CONTROLS_TEXT := (
	"E BUY SPICE · B BUY WEAPONS AND GUNPOWDER · "
	+ "L LOAD AMMUNITION · C SELL CANNONS · G SELL TREASURE · X CLOSE"
)
const TRADE_SELL_CONTROLS_TEXT := "E SELL SPICE · F SELL FISH · X CLOSE"
const TRADE_RELEASE_CONTROLS_TEXT := (
	"RELEASE E, B, L, C, F, G, X, M, 1-6, WASD / ARROW KEYS"
)
const JOURNAL_CONTROLS_TEXT := "J OR X CLOSE"
const JOURNAL_RELEASE_CONTROLS_TEXT := "RELEASE J, X, E, M, 1-6, WASD / ARROW KEYS"
const DEFEAT_RESULT_CONTROLS_TEXT := "X CONTINUE TO RECOVERY"
const DEFEAT_RELEASE_CONTROLS_TEXT := (
	"RELEASE X, E, M, J, R, Q, F, V, P, H, K, SPACE, 1-6, WASD / ARROW KEYS"
)
const RELEASE_CONTROLS_TEXT := "RELEASE WASD / ARROW KEYS"
const BOARDING_DECK_CONTROLS_TEXT := (
	"WASD / ARROWS TO WALK · SPACE CUTLASS · GOLD POINT + E RETURN"
)
const PRIZE_CONTROLS_TEXT := (
	"1 CARGO · 2 CANNONS · 3 REPAIR MATERIALS · 4 TRADE RECORDS · X CLOSE"
)
const SHORE_RETURN_DISTANCE := 64.0
const STARTING_MONEY := 25
const PRIZE_CANNON_CARGO_SALE_PRICE := 15
const CARGO_SOURCE_WRECK := "WRECK"
const CARGO_SOURCE_FISHING := "FISHING"
const CARGO_SOURCE_RUIN := "RUIN"
const CARGO_SOURCE_STORY_CLUE := "STORY_CLUE"
const CARGO_SOURCE_MONSTER_HUNT := "MONSTER_HUNT"
const HEAT_PERSISTENCE_PATH := "user://haven_of_tides_phase30_heat.cfg"
const HEAT_PERSISTENCE_SECTION := "phase30_heat"
const HEAT_PERSISTENCE_KEY := "payload"
const HEAT_PERSISTENCE_FORMAT := "HAVEN_OF_TIDES_PHASE30_HEAT"
const HEAT_PERSISTENCE_VERSION := 1

var _player_near_sign := false
var _player_near_resident := false
var _player_near_ship_entry := false
var _player_near_cove_storage := false
var _player_near_construction_site := false
var _player_near_port_trader := false
var _player_near_cove_buyer := false
var _player_near_ship_module_bench := false
var _player_aboard_ship := false
var _interact_held := false
var _read_count := 0
var _dialogue_open := false
var _dialogue_line_index := -1
var _dialogue_lines := PackedStringArray()
var _dialogue_kind := ""
var _request_state := RequestState.AVAILABLE
var _last_leave_allowed := false
var _available_dock_id := ""
var _player_shore_id := ""
var _player_near_ship_return := false
var _last_ship_docked := false
var _chart_release_pending := false
var _weather_toggle_held := false
var _last_salvage_eligible := false
var _last_fishing_prompt := ""
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
var _pending_cargo_lot := ""
var _pending_cargo_source := ""
var _cargo_choice_open := false
var _cargo_choice_release_pending := false
var _prompt_refresh_after_navigation_release := false
var _last_cargo_action := "NOT_ATTEMPTED"
var _last_cargo_result := "NOT_ATTEMPTED"
var _last_story_load_atomic_evidence: Dictionary = {}
var _last_story_cleanup_atomic_evidence: Dictionary = {}
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
var money := STARTING_MONEY
var _trade_view_open := false
var _trade_release_pending := false
var _trade_pressed_keys: Dictionary = {}
var _active_trade_contact
var _last_trade_action := "NOT_ATTEMPTED"
var _last_trade_result := "NOT_ATTEMPTED"
var _trade_open_count := 0
var _trade_close_count := 0
var _trade_purchase_attempt_count := 0
var _trade_sale_attempt_count := 0
var _trade_bought_lot_count := 0
var _trade_sold_lot_count := 0
var _fish_sale_attempt_count := 0
var _fish_sold_lot_count := 0
var _fish_sold_unit_count := 0
var _fish_sale_denied_count := 0
var _fish_money_earned := 0
var _treasure_sale_attempt_count := 0
var _treasure_sold_lot_count := 0
var _treasure_sale_denied_count := 0
var _treasure_money_earned := 0
var _trade_denied_purchase_count := 0
var _trade_denied_sale_count := 0
var _trade_held_input_count := 0
var _trade_blocked_input_count := 0
var _ammunition_supply_purchase_attempt_count := 0
var _ammunition_supply_purchase_success_count := 0
var _ammunition_supply_purchase_denied_count := 0
var _ammunition_supply_purchased_lot_count := 0
var _ammunition_supply_money_spent := 0
var _last_ammunition_supply_purchase_evidence: Dictionary = {}
var _successful_ammunition_supply_purchase_evidence: Dictionary = {}
var _last_denied_ammunition_supply_purchase_evidence: Dictionary = {}
var _last_ammunition_load_evidence: Dictionary = {}
var _last_held_ammunition_trade_evidence: Dictionary = {}
var _last_trade_attempt_evidence: Dictionary = {}
var _successful_purchase_evidence: Dictionary = {}
var _successful_sale_evidence: Dictionary = {}
var _last_fish_sale_evidence: Dictionary = {}
var _successful_fish_sale_evidence: Dictionary = {}
var _last_treasure_sale_evidence: Dictionary = {}
var _successful_treasure_sale_evidence: Dictionary = {}
var _last_held_treasure_trade_evidence: Dictionary = {}
var _trade_purchase_money_snapshot := 0
var _trade_purchase_cargo_snapshot: Array[String] = []
var _trade_returned_to_ship_at_port := false
var _trade_sailed_from_port := false
var _trade_cove_docked := false
var _trade_cove_ashore := false
var _trade_persistence_holds := false
var completed_voyages := 0
var _voyage_departure_dock_id := ""
var _voyage_departure_count := 0
var _same_dock_arrival_count := 0
var _last_completed_voyage_evidence: Dictionary = {}
var _port_condition = PortConditionState.new()
var _last_port_condition_update_evidence: Dictionary = {}
var _trade_journal = TradeJournalState.new()
var _journal_view_open := false
var _journal_release_pending := false
var _journal_pressed_keys: Dictionary = {}
var _journal_open_count := 0
var _journal_close_count := 0
var _journal_held_input_count := 0
var _journal_blocked_input_count := 0
var _last_journal_action := "NOT_ATTEMPTED"
var _journal_remote_raw_snapshot_before_voyage: Dictionary = {}
var _journal_remote_raw_snapshot_after_voyage: Dictionary = {}
var _journal_remote_raw_snapshot_unchanged := false
var _journal_remote_unchanged_voyage_count := 0
var _journal_remote_last_completed_voyage := -1
var _journal_before_return_market_snapshot: Dictionary = {}
var _journal_before_return_market_status := "UNKNOWN"
var _journal_before_return_market_voyage := -1
var _journal_before_return_market_unchanged := false
var _journal_return_market_snapshot_before_refresh: Dictionary = {}
var _journal_return_market_snapshot_after_refresh: Dictionary = {}
var _journal_return_market_refresh_count := 0
var _journal_return_market_refresh_recorded := false
var _damage_last_seen_hit_count := 0
var _damage_snapshot_initial: Dictionary = {}
var _damage_snapshot_at_hit: Dictionary = {}
var _damage_snapshot_at_dock: Dictionary = {}
var _damage_snapshot_ashore: Dictionary = {}
var _damage_snapshot_return: Dictionary = {}
var _damage_snapshot_release: Dictionary = {}
var _repair_key_held := false
var _repair_held_input_count := 0
var _last_repair_action := "NOT_ATTEMPTED"
var _last_repair_result := "NO REPAIR ATTEMPT"
var _last_repair_attempt_evidence: Dictionary = {}
var _successful_repair_evidence: Dictionary = {}
var _last_denied_repair_evidence: Dictionary = {}
var _last_held_repair_evidence: Dictionary = {}
var _repair_snapshot_success: Dictionary = {}
var _repair_snapshot_ashore: Dictionary = {}
var _repair_snapshot_return: Dictionary = {}
var _repair_snapshot_release: Dictionary = {}
var _near_inspection_target: InspectableTargetShipState
var _active_inspection_target: InspectableTargetShipState
var _target_inspection_view_open := false
var _target_inspection_open_count := 0
var _target_inspection_auto_close_count := 0
var _inspected_target_ids: Array[String] = []
var _last_inspection_estimate: Dictionary = {}
var _last_inspection_view_text := ""
var _last_inspection_close_reason := "NOT_CLOSED"
var _last_auto_closed_target_id := ""
var _last_auto_close_distance := -1.0
var _broadside_pressed_keys: Dictionary = {}
var _broadside_held_input_count := 0
var _last_broadside_result := "NO BROADSIDE ATTEMPT"
var _last_broadside_attempt_evidence: Dictionary = {}
var _successful_broadside_evidence: Dictionary = {}
var _pirate_hunter_defeat_broadside_evidence: Dictionary = {}
var _reload_rejected_broadside_evidence: Dictionary = {}
var _inactive_rejected_broadside_evidence: Dictionary = {}
var _zero_ammunition_rejected_broadside_evidence: Dictionary = {}
var _held_rejected_broadside_evidence: Dictionary = {}
var _selected_attack_choice := InspectableTargetShipState.ATTACK_HULL
var _attack_choice_pressed_keys: Dictionary = {}
var _attack_choice_selection_count := 0
var _attack_choice_held_input_count := 0
var _attack_choice_blocked_input_count := 0
var _last_attack_choice_evidence: Dictionary = {}
var _last_attacked_target_id := ""
var _near_boarding_target: InspectableTargetShipState
var _active_boarding_target: InspectableTargetShipState
var _player_on_target_deck := false
var _player_near_boarding_return := false
var _boarding_attempt_count := 0
var _boarding_success_count := 0
var _boarding_return_count := 0
var _boarding_held_interaction_count := 0
var _boarding_blocked_input_count := 0
var _boarding_walk_distance := 0.0
var _boarding_furthest_distance := 0.0
var _boarding_walked_across_deck := false
var _boarding_deck_bounds_held := true
var _boarding_walk_start_position := Vector2.ZERO
var _boarding_previous_player_position := Vector2.ZERO
var _last_boarded_target_id := ""
var _last_boarding_attempt_evidence: Dictionary = {}
var _successful_boarding_evidence: Dictionary = {}
var _last_held_boarding_evidence: Dictionary = {}
var _last_boarding_return_evidence: Dictionary = {}
var _boarding_conservation_before: Dictionary = {}
var _boarding_conservation_after: Dictionary = {}
var _boarding_state_conservation_holds := false
var _prize_actions = PrizeActionState.new()
var _prize_opened_for_current_boarding := false
var _prize_returned_to_player_ship := false
var _prize_pressed_keys: Dictionary = {}
var _prize_held_close_count := 0
var _prize_close_evidence: Dictionary = {}
var _prize_persistence_evidence: Dictionary = {}
var _prize_trigger_fight_outcome := "NONE"
var _prize_target_resolution_evidence: Dictionary = {}
var _prize_cannon_sale_count := 0
var _prize_cannon_money_earned := 0
var _last_prize_cannon_sale_evidence: Dictionary = {}
var _world_heat = WorldHeatState.new()
var _last_inspection_heat_preview: Dictionary = {}
var _heat_before_last_ammunition_load := 0
var _heat_after_last_ammunition_load := 0
var _heat_persistence_save_count := 0
var _heat_persistence_load_count := 0
var _heat_persistence_cleanup_count := 0
var _heat_persistence_startup_load_attempted := false
var _heat_persistence_startup_restored := false
var _last_heat_persistence_payload: Dictionary = {}
var _last_heat_file_save_evidence: Dictionary = {}
var _last_heat_file_load_evidence: Dictionary = {}
var _last_heat_file_cleanup_evidence: Dictionary = {}
var _pirate_hunter_sea_bounds := Rect2()
var _crew_full_view_evidence: Dictionary = {}
var _crew_injury_view_evidence: Dictionary = {}
var _crew_restoration_view_evidence: Dictionary = {}
var _last_crew_combat_context_evidence: Dictionary = {}
var _last_crew_injury_context_evidence: Dictionary = {}
var _last_crew_dock_context_evidence: Dictionary = {}
var _last_crew_restoration_context_evidence: Dictionary = {}
var _defeat_recovery = DefeatRecoveryState.new()
var _defeat_pressed_keys: Dictionary = {}
var _last_defeat_modal_input_evidence: Dictionary = {}
var _defeat_release_cleanup_count := 0
var _defeat_release_cleanup_evidence: Dictionary = {}
var _defeat_start_input_cleanup_evidence: Dictionary = {}
var _harpoon_pressed := false
var _last_monster_attack_evidence: Dictionary = {}
var _module_pressed_keys: Dictionary = {}
var _pursuit_pressed := false
var _last_pursuit_target_id := ""
var _last_pursuit_attack_evidence: Dictionary = {}
var _module_initial_departure_started := false
var _cove_module_departure_release_observed := false
var _last_module_departure_flow_evidence: Dictionary = {}


func _ready() -> void:
	var sea_state: Dictionary = sea_area.get_playtest_state()
	_pirate_hunter_sea_bounds = sea_state["bounds"]
	ship.configure_sailing_area(
		sea_state["bounds"],
		sea_state["island_center"],
		sea_state["island_radius"],
		sea_state["port_land_rect"],
		sea_state["cove_shoreline"],
		sea_state["reef_center"],
		sea_state["reef_radius"],
	)
	waypoint_display.configure(sea_state["bounds"], ship.get_dock_definitions())
	_load_story_clue_persistence("STARTUP")
	_sync_story_clue_chart()
	resident.load_relationship_progress("STARTUP")
	cove.set_time_state(day_night_cycle.get_time_state())
	resident.record_day_night_state(day_night_cycle.get_time_state(), {})
	waypoint_display.update_positions(ship.global_position, player.global_position, false)
	var cove_dock: Dictionary = ship.get_dock_definition("cove")
	var port_dock: Dictionary = ship.get_dock_definition("port")
	wreck_opportunity.configure_route(
		cove_dock["approach_position"],
		port_dock["approach_position"],
	)
	_load_world_heat_persistence("STARTUP")
	_update_wreck_opportunity()
	_update_weather_area()
	_update_fishing_area()
	_update_ruin_exploration()
	_update_story_clue()
	_update_monster_hunt(0.0)
	_update_cargo_view()
	_update_storage_view()
	_update_construction_view()
	_update_money_view()
	_update_heat_view()
	_update_pirate_hunter_view()
	_update_food_view()
	_update_hull_view()
	_update_crew_view()
	_update_repair_view()
	_update_target_inspection()
	_update_boarding_deck_state()
	_update_broadside_view()
	_update_ammunition_view()
	_update_target_combat_view()
	_update_prize_view()
	_update_trade_view()
	_update_trade_journal_view()
	_update_defeat_result_view()
	_update_weather_view()
	_update_monster_hunt_view()
	_update_ship_module_view()
	_update_relationship_view()
	_update_day_night_view()
	ship.set_module_departure_ready(false)
	travel_camera.global_position = COVE_CAMERA_POSITION
	interaction_prompt.hide()
	sign_message.hide()
	dialogue_box.hide()
	request_view.hide()
	cargo_choice_view.hide()
	storage_view.hide()
	construction_view.hide()
	trade_view.hide()
	journal_view.hide()
	food_view.hide()
	hull_view.hide()
	crew_view.hide()
	repair_view.hide()
	pirate_hunter_view.hide()
	target_inspection_view.hide()
	broadside_view.hide()
	ammunition_view.hide()
	target_combat_view.hide()
	prize_view.hide()
	defeat_result_view.hide()
	weather_view.hide()
	monster_hunt_view.hide()
	ship_module_view.hide()
	sign.body_entered.connect(_on_sign_body_entered)
	sign.body_exited.connect(_on_sign_body_exited)
	resident.body_entered.connect(_on_resident_body_entered)
	resident.body_exited.connect(_on_resident_body_exited)
	cove_storage.body_entered.connect(_on_cove_storage_body_entered)
	cove_storage.body_exited.connect(_on_cove_storage_body_exited)
	construction_site.body_entered.connect(_on_construction_site_body_entered)
	construction_site.body_exited.connect(_on_construction_site_body_exited)
	port_trader.body_entered.connect(_on_port_trader_body_entered)
	port_trader.body_exited.connect(_on_port_trader_body_exited)
	cove_buyer.body_entered.connect(_on_cove_buyer_body_entered)
	cove_buyer.body_exited.connect(_on_cove_buyer_body_exited)
	ship_module_loadout.body_entered.connect(_on_ship_module_bench_body_entered)
	ship_module_loadout.body_exited.connect(_on_ship_module_bench_body_exited)
	ship_entry.body_entered.connect(_on_ship_entry_body_entered)
	ship_entry.body_exited.connect(_on_ship_entry_body_exited)
	damaged_dock_goal.body_entered.connect(_on_damaged_dock_goal_body_entered)
	_capture_damage_checkpoint("INITIAL")


func _physics_process(delta: float) -> void:
	ship_module_loadout.update_timers(delta)
	_update_ship_module_release_pending()
	_update_cove_module_departure_after_exit()
	_update_defeat_release_guard()
	_update_chart_release_pending()
	_update_cargo_choice_release_pending()
	_update_storage_release_pending()
	_update_construction_release_pending()
	_update_trade_release_pending()
	_update_journal_release_pending()
	waypoint_display.update_positions(
		ship.global_position,
		player.global_position,
		_player_aboard_ship,
	)
	_update_wreck_opportunity()
	_update_weather_area()
	_update_fishing_area()
	_update_ruin_exploration()
	_update_story_clue()
	_update_monster_hunt(delta)
	_update_pirate_hunter(delta)
	_update_target_inspection()
	_update_boarding_deck_state(delta)
	_refresh_prompt_after_navigation_release()
	_update_cargo_view()
	_update_money_view()
	_update_heat_view()
	_update_pirate_hunter_view()
	_update_food_view()
	_update_hull_view()
	_update_crew_view()
	_update_repair_view()
	_update_broadside_view()
	_update_ammunition_view()
	_update_target_combat_view()
	_update_prize_view()
	_update_damage_hit_checkpoint()
	_update_trade_view()
	_update_trade_journal_view()
	_update_defeat_result_view()
	_update_weather_view()
	_update_monster_hunt_view()
	_update_ship_module_view()
	_update_day_night_view()
	_update_salvage_persistence()
	_update_storage_persistence()
	_update_construction_persistence()
	_update_trade_persistence()
	if _player_on_target_deck:
		travel_camera.global_position = player.global_position
		controls_help.text = (
			PRIZE_CONTROLS_TEXT
			if _prize_actions.screen_open
			else BOARDING_DECK_CONTROLS_TEXT
		)
	elif _player_aboard_ship:
		player.global_position = ship_standing_position.global_position
		travel_camera.global_position = ship.global_position
		if ship.has_departed_dock and not _module_initial_departure_started:
			_module_initial_departure_started = true
			_begin_cove_module_voyage("INITIAL_COVE_DEPARTURE")
		var leave_allowed: bool = ship.can_leave_at_damaged_dock()
		var available_dock_id: String = ship.get_available_dock_id()
		var ship_docked: bool = ship.is_docked
		var salvage_eligible := wreck_opportunity.is_salvage_eligible()
		var fishing_prompt: String = fishing_area.get_interaction_prompt()
		if _last_ship_docked and not ship_docked:
			_record_voyage_departure(String(ship.last_dock_id))
			_capture_damage_checkpoint("RELEASE")
			_capture_repair_checkpoint("RELEASE")
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
		if _defeat_recovery.is_result_open():
			controls_help.text = DEFEAT_RESULT_CONTROLS_TEXT
		elif _defeat_recovery.is_release_guard_pending():
			controls_help.text = DEFEAT_RELEASE_CONTROLS_TEXT
		elif _journal_view_open:
			controls_help.text = JOURNAL_CONTROLS_TEXT
		elif _journal_release_pending:
			controls_help.text = JOURNAL_RELEASE_CONTROLS_TEXT
		elif _cargo_choice_open:
			controls_help.text = _get_cargo_choice_controls_text()
		elif _cargo_choice_release_pending or ship.navigation_release_pending:
			controls_help.text = RELEASE_CONTROLS_TEXT
		elif waypoint_display.chart_visible:
			controls_help.text = _get_chart_controls_text()
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
			or fishing_prompt != _last_fishing_prompt
		):
			_last_leave_allowed = leave_allowed
			_available_dock_id = available_dock_id
			_last_ship_docked = ship_docked
			_last_salvage_eligible = salvage_eligible
			_last_fishing_prompt = fishing_prompt
			_update_interaction_prompt()
	elif not _player_shore_id.is_empty():
		travel_camera.global_position = player.global_position
		var dock_definition: Dictionary = ship.get_current_dock_definition()
		var near_return := false
		if not dock_definition.is_empty() and not ruin_exploration.is_inside():
			near_return = player.global_position.distance_to(
				dock_definition["shore_position"]
			) <= SHORE_RETURN_DISTANCE
		if near_return != _player_near_ship_return:
			_player_near_ship_return = near_return
			_update_interaction_prompt()
		if ruin_exploration.is_inside():
			controls_help.text = (
				"WASD / ARROWS TO WALK · E INTERACT WITH RUIN FINDS OR EXIT"
			)
	else:
		travel_camera.global_position = COVE_CAMERA_POSITION


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if _key_matches(key_event, KEY_T) and not key_event.pressed:
		_weather_toggle_held = false
	if _key_matches(key_event, KEY_V) and not key_event.pressed:
		_harpoon_pressed = false
	if _key_matches(key_event, KEY_P) and not key_event.pressed:
		_pursuit_pressed = false
	if _defeat_recovery.is_result_open():
		_handle_defeat_result_input(key_event)
		get_viewport().set_input_as_handled()
		return
	if _defeat_recovery.is_release_guard_pending():
		_handle_defeat_release_input(key_event)
		get_viewport().set_input_as_handled()
		return
	if ship_module_loadout.is_selection_open():
		_handle_ship_module_input(key_event)
		get_viewport().set_input_as_handled()
		return
	if ship_module_loadout.is_release_pending():
		if key_event.pressed and not key_event.echo:
			ship_module_loadout.record_release_guard_input(
				_key_event_name(key_event),
				ship.get_cargo_lots().size(),
			)
		if not key_event.pressed:
			var released_module_key := _get_ship_module_key(key_event)
			if released_module_key != 0:
				_module_pressed_keys.erase(released_module_key)
			if _key_matches(key_event, KEY_E):
				_interact_held = false
		get_viewport().set_input_as_handled()
		return
	if _key_matches(key_event, KEY_R) and not key_event.pressed:
		_repair_key_held = false
	var released_broadside_side: String = _get_broadside_side(key_event)
	if not key_event.pressed and not released_broadside_side.is_empty():
		_broadside_pressed_keys.erase(released_broadside_side)
	var requested_attack_choice: String = _get_attack_choice(key_event)
	if not key_event.pressed and not requested_attack_choice.is_empty():
		_attack_choice_pressed_keys.erase(requested_attack_choice)
	if _player_on_target_deck:
		_handle_boarding_deck_input(key_event)
		get_viewport().set_input_as_handled()
		return
	if (
		not requested_attack_choice.is_empty()
		and _is_attack_choice_input_blocked()
	):
		_handle_blocked_attack_choice_input(key_event, requested_attack_choice)
		get_viewport().set_input_as_handled()
		return
	if _journal_view_open:
		_handle_trade_journal_input(key_event)
		get_viewport().set_input_as_handled()
		return
	if _journal_release_pending:
		if not key_event.pressed:
			var released_key := _get_journal_key(key_event)
			if released_key != 0:
				_journal_pressed_keys.erase(released_key)
			if _key_matches(key_event, KEY_E):
				_interact_held = false
		get_viewport().set_input_as_handled()
		return
	if _trade_view_open:
		_handle_trade_input(key_event)
		get_viewport().set_input_as_handled()
		return
	if _trade_release_pending:
		if not key_event.pressed:
			var released_key := _get_trade_key(key_event)
			if released_key != 0:
				_trade_pressed_keys.erase(released_key)
			if _key_matches(key_event, KEY_E):
				_interact_held = false
		get_viewport().set_input_as_handled()
		return
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
	if (
		story_clue.is_interaction_release_pending()
		and _key_matches(key_event, KEY_E)
	):
		if not key_event.pressed:
			_interact_held = false
			story_clue.release_interaction_guard()
			_update_story_clue()
			_update_interaction_prompt()
		elif not key_event.echo:
			story_clue.record_held_or_guarded_interaction(
				"FRAGMENT_RELEASE_GUARD",
				ship.get_cargo_lots(),
			)
		get_viewport().set_input_as_handled()
		return
	if (
		ruin_exploration.is_transition_release_pending()
		and _key_matches(key_event, KEY_E)
	):
		if not key_event.pressed:
			_interact_held = false
			ruin_exploration.release_transition_guard()
			_update_ruin_exploration()
			_update_interaction_prompt()
		elif not key_event.echo:
			ruin_exploration.record_held_or_guarded_interaction(
				"TRANSITION_RELEASE_GUARD",
				ship.get_cargo_lots(),
			)
		get_viewport().set_input_as_handled()
		return
	if (
		_target_inspection_view_open
		and _key_matches(key_event, KEY_E)
	):
		# Inspection stays open until range closes it. E cannot trigger another
		# world action while the inspection prompt is hidden.
		if not key_event.pressed:
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
	if _key_matches(key_event, KEY_J):
		if key_event.pressed and not key_event.echo and _can_open_trade_journal():
			_open_trade_journal()
			get_viewport().set_input_as_handled()
		return
	if _key_matches(key_event, KEY_V):
		_handle_monster_harpoon_input(key_event)
		get_viewport().set_input_as_handled()
		return
	if _key_matches(key_event, KEY_P):
		_handle_pursuit_input(key_event)
		get_viewport().set_input_as_handled()
		return
	if not _get_broadside_side(key_event).is_empty():
		_handle_broadside_input(key_event)
		get_viewport().set_input_as_handled()
		return
	if not requested_attack_choice.is_empty():
		_handle_attack_choice_input(key_event, requested_attack_choice)
		get_viewport().set_input_as_handled()
		return
	if _key_matches(key_event, KEY_R):
		_handle_repair_input(key_event)
		get_viewport().set_input_as_handled()
		return
	if _key_matches(key_event, KEY_T):
		_handle_weather_toggle_input(key_event)
		get_viewport().set_input_as_handled()
		return
	if key_event.physical_keycode != KEY_E and key_event.keycode != KEY_E:
		return
	if not key_event.pressed:
		_interact_held = false
		return
	if key_event.echo or _interact_held:
		if _dialogue_open or _player_near_resident:
			resident.record_held_talk_input(_get_request_state_name())
		elif _can_board_nearby_target():
			_record_held_boarding_interaction("BOARD")
		elif fishing_area.can_receive_fishing_press():
			fishing_area.record_held_press(ship.get_cargo_lots())
		elif story_clue.is_near_fragment():
			story_clue.record_held_or_guarded_interaction(
				"MAP_FRAGMENT",
				ship.get_cargo_lots(),
			)
		elif ruin_exploration.is_near_tool_gate():
			ruin_exploration.record_held_or_guarded_interaction(
				"TOOL_GATE",
				ship.get_cargo_lots(),
			)
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
		elif _can_board_nearby_target():
			_board_nearby_target()
		elif _can_inspect_nearby_target():
			_open_target_inspection()
		elif fishing_area.can_receive_fishing_press():
			_fish_in_area()
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

	if ruin_exploration.is_inside():
		if story_clue.can_take_fragment():
			_take_story_clue_fragment()
		elif ruin_exploration.can_take_treasure():
			_take_ruin_treasure()
		elif ruin_exploration.can_interact_tool_gate():
			_open_ruin_tool_gate()
		elif ruin_exploration.can_exit():
			_exit_ruin()
		get_viewport().set_input_as_handled()
		return

	if _can_enter_ruin():
		_enter_ruin()
		get_viewport().set_input_as_handled()
		return

	if _can_open_trade_contact():
		_open_trade_contact()
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

	if _can_open_ship_module_bench():
		_open_ship_module_bench()
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


func _handle_defeat_result_input(key_event: InputEventKey) -> void:
	var is_close_key := _key_matches(key_event, KEY_X)
	if not key_event.pressed:
		_clear_defeat_held_key_state(key_event, "RESULT_OPEN")
		return
	if key_event.echo:
		return
	if not is_close_key:
		_defeat_recovery.record_blocked_input()
		_last_defeat_modal_input_evidence = {
			"action": "BLOCKED_DURING_DEFEAT_RESULT",
			"physical_keycode": key_event.physical_keycode,
			"keycode": key_event.keycode,
			"result_screen_open": true,
			"no_world_action": true,
		}
		return
	if bool(_defeat_pressed_keys.get("X", false)):
		_defeat_recovery.record_blocked_input()
		return
	_defeat_pressed_keys["X"] = true
	if not _defeat_recovery.close_result_screen():
		return
	defeat_result_view.hide()
	ship.set_navigation_input_blocked(false, false)
	player.movement_enabled = false
	controls_help.text = DEFEAT_RELEASE_CONTROLS_TEXT
	interaction_prompt.hide()


func _handle_defeat_release_input(key_event: InputEventKey) -> void:
	if key_event.pressed:
		return
	_clear_defeat_held_key_state(key_event, "RELEASE_GUARD")


func _clear_defeat_held_key_state(
	key_event: InputEventKey,
	context: String,
) -> void:
	var key_name := ""
	var state_before := _get_defeat_held_action_state()
	if _key_matches(key_event, KEY_X):
		key_name = "X"
		_defeat_pressed_keys.erase("X")
	elif _key_matches(key_event, KEY_E):
		key_name = "E"
		_interact_held = false
	elif _key_matches(key_event, KEY_R):
		key_name = "R"
		_repair_key_held = false
	elif _key_matches(key_event, KEY_V):
		key_name = "V"
		_harpoon_pressed = false
	elif _key_matches(key_event, KEY_P):
		key_name = "P"
		_pursuit_pressed = false
	else:
		var broadside_side := _get_broadside_side(key_event)
		if not broadside_side.is_empty():
			key_name = "Q" if broadside_side == "LEFT" else "F"
			_broadside_pressed_keys.erase(broadside_side)
		else:
			var attack_choice := _get_attack_choice(key_event)
			if not attack_choice.is_empty():
				key_name = (
					"H"
					if attack_choice == InspectableTargetShipState.ATTACK_HULL
					else "K"
				)
				_attack_choice_pressed_keys.erase(attack_choice)
	if key_name.is_empty():
		return
	_defeat_release_cleanup_count += 1
	var state_after := _get_defeat_held_action_state()
	_defeat_release_cleanup_evidence[key_name] = {
		"key": key_name,
		"context": context,
		"state_before": state_before,
		"state_after": state_after,
		"key_held_after_release": bool(state_after.get(key_name, false)),
		"release_cleared_key_state": not bool(state_after.get(key_name, false)),
		"cleanup_number": _defeat_release_cleanup_count,
	}


func _clear_all_defeat_held_action_state(context: String) -> void:
	var state_before := _get_defeat_held_action_state()
	_defeat_pressed_keys.clear()
	_interact_held = false
	_repair_key_held = false
	_harpoon_pressed = false
	_pursuit_pressed = false
	_broadside_pressed_keys.clear()
	_attack_choice_pressed_keys.clear()
	_defeat_start_input_cleanup_evidence = {
		"context": context,
		"state_before": state_before,
		"state_after": _get_defeat_held_action_state(),
		"all_action_keys_clear": not _has_stale_defeat_action_key_state(),
	}


func _get_defeat_held_action_state() -> Dictionary:
	return {
		"X": bool(_defeat_pressed_keys.get("X", false)),
		"E": _interact_held,
		"R": _repair_key_held,
		"V": _harpoon_pressed,
		"P": _pursuit_pressed,
		"Q": bool(_broadside_pressed_keys.get("LEFT", false)),
		"F": bool(_broadside_pressed_keys.get("RIGHT", false)),
		"H": bool(_attack_choice_pressed_keys.get(
			InspectableTargetShipState.ATTACK_HULL,
			false,
		)),
		"K": bool(_attack_choice_pressed_keys.get(
			InspectableTargetShipState.ATTACK_SAILS,
			false,
		)),
	}


func _has_stale_defeat_action_key_state() -> bool:
	var held_state := _get_defeat_held_action_state()
	return (
		bool(held_state["R"])
		or bool(held_state["Q"])
		or bool(held_state["F"])
		or bool(held_state["H"])
		or bool(held_state["K"])
		or bool(held_state["P"])
	)


func _update_defeat_release_guard() -> void:
	if not _defeat_recovery.is_release_guard_pending():
		return
	if _is_any_defeat_guard_key_pressed():
		player.movement_enabled = false
		return
	if not _defeat_recovery.complete_release_guard():
		return
	_defeat_pressed_keys.clear()
	player.movement_enabled = not _player_aboard_ship and not _dialogue_open
	controls_help.text = _get_context_controls_text()
	_update_interaction_prompt()


func _update_defeat_result_view() -> void:
	defeat_result_title.text = "SHIP DEFEATED · SAFE RETURN"
	defeat_result_details.text = _defeat_recovery.get_result_text()
	defeat_result_controls.text = "[X] CONTINUE TO RECOVERY"
	defeat_result_view.visible = _defeat_recovery.is_result_open()


func _handle_boarding_deck_input(key_event: InputEventKey) -> void:
	if _prize_actions.screen_open:
		_handle_prize_screen_input(key_event)
		return
	if _key_matches(key_event, KEY_SPACE):
		target_boarding_deck.handle_cutlass_input(
			key_event.pressed,
			key_event.echo,
			player.global_position,
		)
		return
	if _key_matches(key_event, KEY_E):
		if not key_event.pressed:
			_interact_held = false
			return
		if key_event.echo or _interact_held:
			_record_held_boarding_interaction("RETURN")
			return
		_interact_held = true
		if _player_near_boarding_return:
			_return_from_target_deck()
		return
	if not key_event.pressed or key_event.echo:
		return
	if _is_boarding_incompatible_key(key_event):
		_boarding_blocked_input_count += 1


func _handle_prize_screen_input(key_event: InputEventKey) -> void:
	var prize_type := _get_prize_type_for_key(key_event)
	var prize_key := "X" if _key_matches(key_event, KEY_X) else prize_type
	if prize_key.is_empty():
		if key_event.pressed and not key_event.echo:
			_boarding_blocked_input_count += 1
		return
	if not key_event.pressed:
		_prize_pressed_keys.erase(prize_key)
		return
	if key_event.echo or bool(_prize_pressed_keys.get(prize_key, false)):
		if prize_key == "X":
			_prize_held_close_count += 1
		else:
			_prize_actions.record_held_input(
				prize_type,
				ship.get_cargo_lots(),
				_trade_journal.get_entry_snapshot(),
			)
		return
	_prize_pressed_keys[prize_key] = true
	if prize_key == "X":
		_close_prize_screen()
		return
	_attempt_prize_selection(prize_type)


func _get_prize_type_for_key(key_event: InputEventKey) -> String:
	if _key_matches(key_event, KEY_1):
		return PrizeActionState.PRIZE_CARGO
	if _key_matches(key_event, KEY_2):
		return PrizeActionState.PRIZE_CANNONS
	if _key_matches(key_event, KEY_3):
		return PrizeActionState.PRIZE_REPAIR_MATERIALS
	if _key_matches(key_event, KEY_4):
		return PrizeActionState.PRIZE_TRADE_RECORDS
	return ""


func _attempt_prize_selection(prize_type: String) -> void:
	if not _prize_actions.can_attempt_selection(prize_type):
		return
	var cargo_before: Array[String] = ship.get_cargo_lots()
	var journal_before: Dictionary = (
		_trade_journal.get_playtest_state(completed_voyages)
	)
	if _prize_actions.actions_remaining <= 0:
		_prize_actions.record_denied_selection(
			prize_type,
			"NO PRIZE ACTIONS REMAIN",
			cargo_before,
			journal_before,
		)
		return
	if _prize_actions.selected_prize_types.has(prize_type):
		_prize_actions.record_denied_selection(
			prize_type,
			"PRIZE ALREADY TAKEN",
			cargo_before,
			journal_before,
		)
		return
	var cargo_lot_name: String = _prize_actions.get_cargo_lot_name(prize_type)
	if not cargo_lot_name.is_empty() and not ship.can_keep_cargo_lot():
		_prize_actions.record_denied_selection(
			prize_type,
			"NO FREE SHIP CARGO SLOT",
			cargo_before,
			journal_before,
		)
		return
	if not cargo_lot_name.is_empty():
		if not ship.keep_cargo_lot(cargo_lot_name):
			_prize_actions.record_denied_selection(
				prize_type,
				"CARGO PRIZE DID NOT LOAD",
				cargo_before,
				journal_before,
			)
			return
	else:
		_record_local_port_market_in_journal(
			TradeJournalState.PRIZE_TRADE_RECORDS_SOURCE
		)
	var cargo_after: Array[String] = ship.get_cargo_lots()
	var journal_after: Dictionary = (
		_trade_journal.get_playtest_state(completed_voyages)
	)
	_prize_actions.record_successful_selection(
		prize_type,
		cargo_before,
		cargo_after,
		journal_before,
		journal_after,
	)
	_update_cargo_view()
	_update_trade_journal_view()
	_update_prize_view()


func _close_prize_screen() -> void:
	_prize_close_evidence = _prize_actions.close_screen()
	prize_view.hide()
	player.movement_enabled = true
	controls_help.text = BOARDING_DECK_CONTROLS_TEXT
	_update_interaction_prompt()


func _is_boarding_incompatible_key(key_event: InputEventKey) -> bool:
	for keycode in [
		KEY_M,
		KEY_J,
		KEY_Q,
		KEY_F,
		KEY_H,
		KEY_K,
		KEY_R,
		KEY_B,
		KEY_L,
		KEY_C,
		KEY_X,
		KEY_1,
		KEY_2,
		KEY_3,
		KEY_4,
		KEY_5,
		KEY_6,
	]:
		if _key_matches(key_event, keycode):
			return true
	return false


func _record_held_boarding_interaction(action: String) -> void:
	_boarding_held_interaction_count += 1
	_last_held_boarding_evidence = {
		"success": false,
		"result": "NO BOARDING ACTION · RELEASE E",
		"rejection_reason": "HELD_KEY",
		"requested_action": action,
		"fresh_press_required": true,
		"board_count_before": _boarding_success_count,
		"board_count_after": _boarding_success_count,
		"return_count_before": _boarding_return_count,
		"return_count_after": _boarding_return_count,
		"player_on_target_deck": _player_on_target_deck,
		"no_state_change": true,
	}


func _get_broadside_side(key_event: InputEventKey) -> String:
	if _key_matches(key_event, KEY_Q):
		return "LEFT"
	if _key_matches(key_event, KEY_F):
		return "RIGHT"
	return ""


func _handle_broadside_input(key_event: InputEventKey) -> void:
	var side: String = _get_broadside_side(key_event)
	if side.is_empty():
		return
	if not key_event.pressed:
		_broadside_pressed_keys.erase(side)
		return
	if key_event.echo or bool(_broadside_pressed_keys.get(side, false)):
		_broadside_held_input_count += 1
		var held_broadside_state: Dictionary = (
			ship.get_broadside_playtest_state()
		)
		var held_target_hulls: Dictionary = _get_target_hull_snapshots()
		var held_target_conditions: Dictionary = (
			_get_target_condition_snapshots()
		)
		_last_broadside_result = (
			"NO SHOT · RELEASE %s BROADSIDE KEY" % (
				"Q" if side == "LEFT" else "F"
			)
		)
		_held_rejected_broadside_evidence = {
			"success": false,
			"shot_fired": false,
			"rejection_reason": "HELD_KEY",
			"side": side,
			"result": _last_broadside_result,
			"ammunition_before": held_broadside_state["ammunition_units"],
			"ammunition_after": held_broadside_state["ammunition_units"],
			"ammunition_delta": 0,
			"shot_count_before": held_broadside_state["shot_count"],
			"shot_count_after": held_broadside_state["shot_count"],
			"world_heat_before": _world_heat.get_current_heat(),
			"world_heat_after": _world_heat.get_current_heat(),
			"world_heat_delta": 0,
			"target_hulls_before": held_target_hulls,
			"target_hulls_after": held_target_hulls.duplicate(true),
			"target_conditions_before": held_target_conditions,
			"target_conditions_after": (
				held_target_conditions.duplicate(true)
			),
			"attack_choice": _selected_attack_choice,
			"no_shot_no_ammunition_use": true,
			"no_shot_no_target_damage": true,
			"no_shot_no_condition_change": true,
			"no_shot_no_heat_change": true,
			"fresh_press_required": true,
		}
		_update_broadside_view()
		_update_ammunition_view()
		return
	_broadside_pressed_keys[side] = true
	_attempt_broadside_attack(side)


func _handle_pursuit_input(key_event: InputEventKey) -> void:
	if not key_event.pressed:
		_pursuit_pressed = false
		return
	var target_sails := _get_target_condition_values()
	if key_event.echo or _pursuit_pressed:
		ship_module_loadout.record_held_pursuit(
			ship.get_ammunition_units(),
			target_sails,
		)
		_update_target_combat_view()
		return
	_pursuit_pressed = true
	_attempt_long_guns_pursuit_attack()


func _attempt_long_guns_pursuit_attack() -> void:
	var target: InspectableTargetShipState = _get_pursuit_target()
	var target_id := ""
	var target_name := ""
	var target_distance := INF
	var target_forward_dot := -1.0
	if target != null:
		target_id = target.target_id
		target_name = target.display_name
		var target_offset: Vector2 = target.global_position - ship.global_position
		target_distance = target_offset.length()
		if not target_offset.is_zero_approx():
			target_forward_dot = ship.get_forward_direction().dot(
				target_offset.normalized()
			)
	var preflight: Dictionary = ship_module_loadout.try_begin_pursuit_attack(
		_is_pursuit_input_available(),
		ship.get_ammunition_units(),
		target_id,
		target_name,
		target_distance,
		target_forward_dot,
	)
	if not bool(preflight.get("success", false)):
		_update_target_combat_view()
		_update_ammunition_view()
		return
	var ammunition_evidence: Dictionary = ship.consume_ammunition_for_long_guns()
	var target_evidence: Dictionary = {}
	var heat_evidence: Dictionary = {}
	if bool(ammunition_evidence.get("success", false)) and target != null:
		target_evidence = target.apply_broadside_damage(
			InspectableTargetShipState.ATTACK_SAILS,
			ShipModuleLoadoutState.PURSUIT_SAIL_DAMAGE,
			"PURSUIT_LONG_GUNS",
		)
		if bool(target_evidence.get("success", false)):
			heat_evidence = _world_heat.record_successful_hit(
				target.target_id,
				target.peaceful,
				target.estimated_heat_cost,
			)
			_last_attacked_target_id = target.target_id
			_last_pursuit_target_id = target.target_id
	_last_pursuit_attack_evidence = ship_module_loadout.resolve_pursuit_attack(
		preflight,
		ammunition_evidence,
		target_evidence,
		heat_evidence,
	)
	_update_cargo_view()
	_update_ammunition_view()
	_update_target_combat_view()
	_update_heat_view()
	_update_target_inspection()
	_update_interaction_prompt()


func _is_pursuit_input_available() -> bool:
	return (
		_player_aboard_ship
		and ship.controls_enabled
		and ship.captain_aboard
		and not ship.is_docked
		and not _player_on_target_deck
		and not _defeat_recovery.is_result_open()
		and not _defeat_recovery.is_release_guard_pending()
		and not waypoint_display.chart_visible
		and not _chart_release_pending
		and not _cargo_choice_open
		and not _cargo_choice_release_pending
		and not _storage_view_open
		and not _storage_release_pending
		and not _construction_view_open
		and not _construction_release_pending
		and not _trade_view_open
		and not _trade_release_pending
		and not _journal_view_open
		and not _journal_release_pending
		and not ship_module_loadout.is_selection_open()
		and not ship_module_loadout.is_release_pending()
		and not _target_inspection_view_open
		and not ship.navigation_input_blocked
		and not ship.navigation_release_pending
	)


func _get_pursuit_target() -> InspectableTargetShipState:
	var nearest_target: InspectableTargetShipState = null
	var nearest_distance := INF
	for target in inspection_targets:
		if not target.visible or not target.can_receive_sail_damage():
			continue
		var sail_state: Dictionary = target.get_sail_state()
		if not bool(sail_state.get("route_enabled", false)):
			continue
		var offset: Vector2 = target.global_position - ship.global_position
		var distance := offset.length()
		if distance > ShipModuleLoadoutState.PURSUIT_RANGE:
			continue
		if offset.is_zero_approx():
			continue
		var forward_dot: float = ship.get_forward_direction().dot(
			offset.normalized()
		)
		if forward_dot < ShipModuleLoadoutState.PURSUIT_MIN_FORWARD_DOT:
			continue
		if distance < nearest_distance:
			nearest_target = target
			nearest_distance = distance
	return nearest_target


func _get_attack_choice(key_event: InputEventKey) -> String:
	if _key_matches(key_event, KEY_H):
		return InspectableTargetShipState.ATTACK_HULL
	if _key_matches(key_event, KEY_K):
		return InspectableTargetShipState.ATTACK_SAILS
	return ""


func _is_attack_choice_input_blocked() -> bool:
	return (
		_defeat_recovery.is_result_open()
		or _defeat_recovery.is_release_guard_pending()
		or _player_on_target_deck
		or not _player_aboard_ship
		or ship.is_docked
		or ship.navigation_input_blocked
		or ship.navigation_release_pending
		or waypoint_display.chart_visible
		or _chart_release_pending
		or _cargo_choice_open
		or _cargo_choice_release_pending
		or _storage_view_open
		or _storage_release_pending
		or _construction_view_open
		or _construction_release_pending
		or _trade_view_open
		or _trade_release_pending
		or _journal_view_open
		or _journal_release_pending
		or _dialogue_open
	)


func _handle_attack_choice_input(
	key_event: InputEventKey,
	attack_choice: String,
) -> void:
	if not key_event.pressed:
		_attack_choice_pressed_keys.erase(attack_choice)
		return
	if (
		key_event.echo
		or bool(_attack_choice_pressed_keys.get(attack_choice, false))
	):
		_attack_choice_held_input_count += 1
		_last_attack_choice_evidence = {
			"success": false,
			"result": "NO CHANGE · RELEASE ATTACK CHOICE KEY",
			"rejection_reason": "HELD_KEY",
			"requested_choice": attack_choice,
			"selected_before": _selected_attack_choice,
			"selected_after": _selected_attack_choice,
			"fresh_press_required": true,
		}
		return
	_attack_choice_pressed_keys[attack_choice] = true
	var selected_before: String = _selected_attack_choice
	_selected_attack_choice = attack_choice
	_attack_choice_selection_count += 1
	_last_attack_choice_evidence = {
		"success": true,
		"result": "SELECTED %s" % attack_choice,
		"requested_choice": attack_choice,
		"selected_before": selected_before,
		"selected_after": _selected_attack_choice,
		"fresh_press_required": true,
		"modal_guard_passed": true,
	}
	_update_target_combat_view()


func _handle_blocked_attack_choice_input(
	key_event: InputEventKey,
	attack_choice: String,
) -> void:
	if not key_event.pressed:
		_attack_choice_pressed_keys.erase(attack_choice)
		return
	if key_event.echo:
		return
	_attack_choice_blocked_input_count += 1
	_last_attack_choice_evidence = {
		"success": false,
		"result": "NO CHANGE · ATTACK CHOICE UNAVAILABLE",
		"rejection_reason": "INACTIVE_OR_MODAL",
		"requested_choice": attack_choice,
		"selected_before": _selected_attack_choice,
		"selected_after": _selected_attack_choice,
		"fresh_press_required": true,
		"modal_guard_passed": false,
	}


func _handle_trade_journal_input(key_event: InputEventKey) -> void:
	var journal_key := _get_journal_key(key_event)
	if not key_event.pressed:
		if journal_key != 0:
			_journal_pressed_keys.erase(journal_key)
		if _key_matches(key_event, KEY_E):
			_interact_held = false
		return

	if journal_key == 0:
		_journal_blocked_input_count += 1
		_last_journal_action = "BLOCKED_WHILE_JOURNAL_OPEN"
		return
	if key_event.echo or bool(_journal_pressed_keys.get(journal_key, false)):
		_journal_held_input_count += 1
		_last_journal_action = "HELD_JOURNAL_CLOSE_KEY"
		return

	_journal_pressed_keys[journal_key] = true
	_close_trade_journal()


func _get_journal_key(key_event: InputEventKey) -> int:
	if _key_matches(key_event, KEY_J):
		return KEY_J
	if _key_matches(key_event, KEY_X):
		return KEY_X
	return 0


func _can_open_trade_journal() -> bool:
	return (
		not _player_on_target_deck
		and not _dialogue_open
		and not waypoint_display.chart_visible
		and not _chart_release_pending
		and not _cargo_choice_open
		and not _cargo_choice_release_pending
		and not _storage_view_open
		and not _storage_release_pending
		and not _construction_view_open
		and not _construction_release_pending
		and not _trade_view_open
		and not _trade_release_pending
		and not _journal_view_open
		and not _journal_release_pending
		and not ship.navigation_release_pending
	)


func _open_trade_journal() -> void:
	if not _can_open_trade_journal():
		return
	_journal_view_open = true
	_journal_open_count += 1
	_journal_pressed_keys.clear()
	# The opening J press must be released before J can close the screen.
	_journal_pressed_keys[KEY_J] = true
	_last_journal_action = "OPEN_TRADE_JOURNAL"
	player.movement_enabled = false
	ship.set_navigation_input_blocked(true)
	controls_help.text = JOURNAL_CONTROLS_TEXT
	interaction_prompt.hide()
	sign_message.hide()
	_update_cargo_view()
	_update_trade_journal_view()


func _close_trade_journal() -> void:
	if not _journal_view_open:
		return
	_journal_view_open = false
	_journal_release_pending = true
	_journal_close_count += 1
	_last_journal_action = "CLOSE_TRADE_JOURNAL"
	journal_view.hide()
	player.movement_enabled = false
	# Keep navigation blocked until every journal guard key is released.
	ship.set_navigation_input_blocked(true)
	_prompt_refresh_after_navigation_release = true
	controls_help.text = JOURNAL_RELEASE_CONTROLS_TEXT
	interaction_prompt.hide()
	_update_cargo_view()


func _record_local_port_market_in_journal(source: String) -> void:
	var condition_state: Dictionary = (
		_port_condition.get_playtest_state(completed_voyages)
	)
	var spice_state: Dictionary = port_trader.get_mark_state(completed_voyages)
	var goods: Array = _port_condition.get_market_goods()
	goods.append({
		"good_name": TradeContact.GOOD_NAME,
		"cargo_lot_name": TradeContact.GOOD_NAME,
		"base_price_state": spice_state["base_price_state"],
		"base_fixed_price": spice_state["base_fixed_price"],
		"current_price_state": spice_state["current_price_state"],
		"current_fixed_price": spice_state["current_fixed_price"],
	})
	var spice_stock_mark := {
		"good_name": TradeContact.GOOD_NAME,
		"mark_kind": spice_state["mark_kind"],
		"mark_display": spice_state["mark_display"],
		"marks_available": spice_state["marks_available"],
		"mark_capacity": spice_state["mark_capacity"],
		"marks_used": spice_state["marks_used"],
		"used_marks": spice_state["used_marks"],
		"return_voyages": spice_state["return_voyages"],
		"next_return_voyage": spice_state["next_return_voyage"],
		"voyages_until_next_return": (
			spice_state["voyages_until_next_return"]
		),
		"return_after_completed_voyages": (
			spice_state["return_after_completed_voyages"]
		),
	}
	var condition_snapshot := {
		"name": condition_state["name"],
		"state": condition_state["state"],
		"active": condition_state["active"],
		"ended": condition_state["ended"],
		"effects": (
			"TIMBER, FOOD, AND MEDICINE ARE VALUABLE"
			if condition_state["active"]
			else "EFFECTS ENDED · BASE PRICE STATES RESTORED"
		),
		"affected_good_names": condition_state["affected_good_names"],
		"start_voyage": condition_state["start_voyage"],
		"end_voyage": condition_state["end_voyage"],
		"remaining_voyages": condition_state["remaining_voyages"],
	}
	var before_record := _trade_journal.get_entry_snapshot()
	var was_return_refresh := (
		source == TradeJournalState.LOCAL_MARKET_OPEN_SOURCE
		and not _journal_return_market_refresh_recorded
		and not _journal_before_return_market_snapshot.is_empty()
		and _journal_before_return_market_status == TradeJournalState.OLD_STATUS
		and before_record == _journal_before_return_market_snapshot
	)
	if not _trade_journal.record_local_port_market(
		goods,
		spice_stock_mark,
		condition_snapshot,
		completed_voyages,
		source,
	):
		return
	if was_return_refresh:
		_journal_return_market_snapshot_before_refresh = before_record.duplicate(true)
		_journal_return_market_snapshot_after_refresh = (
			_trade_journal.get_entry_snapshot()
		)
		_journal_return_market_refresh_count += 1
		_journal_return_market_refresh_recorded = true
	_update_trade_journal_view()


func _update_trade_journal_view() -> void:
	var journal_state: Dictionary = (
		_trade_journal.get_playtest_state(completed_voyages)
	)
	journal_title.text = "TRADE JOURNAL"
	journal_controls.text = "[J] OR [X] CLOSE"
	if not bool(journal_state["known"]):
		journal_status.text = "PORT MARKET · UNKNOWN"
		journal_details.text = (
			"NO SAVED PORT MARKET VISIT\n\n"
			+ "PRICES · UNKNOWN\n"
			+ "SPICE STOCK · UNKNOWN\n"
			+ "PORT CONDITION · UNKNOWN\n\n"
			+ "SAVED MARKET VIEW ONLY · NO LIVE DATA"
		)
	else:
		journal_status.text = "PORT MARKET · %s" % journal_state["status"]
		var lines := PackedStringArray([
			"SEEN VOYAGE %d · CURRENT VOYAGE %d · AGE %d" % [
				journal_state["seen_voyage"],
				journal_state["current_voyage"],
				journal_state["age"],
			],
			"LAST PORT MARKET VIEW · SAVED INFORMATION",
			"",
		])
		for good in journal_state["goods"]:
			lines.append("%s · %s · %d COINS · BASE %s · %d" % [
				good["good_name"],
				good["current_price_state"],
				good["current_fixed_price"],
				good["base_price_state"],
				good["base_fixed_price"],
			])
		var stock_mark: Dictionary = journal_state["spice_stock_mark"]
		lines.append("")
		lines.append("SPICE STOCK · %s · AVAILABLE %d/%d · USED %d" % [
			stock_mark["mark_display"],
			stock_mark["marks_available"],
			stock_mark["mark_capacity"],
			stock_mark["marks_used"],
		])
		if stock_mark["return_voyages"].is_empty():
			lines.append(
				"SPICE RETURN VOYAGES · NONE · ALL MARKS AVAILABLE"
			)
		else:
			var return_strings := PackedStringArray()
			for return_voyage in stock_mark["return_voyages"]:
				return_strings.append(str(return_voyage))
			lines.append(
				"SPICE RETURN VOYAGES · %s · NEXT %d · SAVED REMAINING %d" % [
					", ".join(return_strings),
					stock_mark["next_return_voyage"],
					stock_mark["voyages_until_next_return"],
				]
			)
		var condition: Dictionary = journal_state["condition"]
		lines.append("")
		lines.append("KNOWN CONDITION · %s · %s" % [
			condition["name"],
			condition["state"],
		])
		lines.append("EFFECTS · %s" % condition["effects"])
		lines.append("START VOYAGE %d · END VOYAGE %d · SAVED REMAINING %d" % [
			condition["start_voyage"],
			condition["end_voyage"],
			condition["remaining_voyages"],
		])
		lines.append("")
		lines.append("SAVED MARKET VIEW ONLY · NO LIVE DATA · NO TRADE ADVICE")
		journal_details.text = "\n".join(lines)
	if _journal_view_open:
		journal_view.show()
	else:
		journal_view.hide()


func _handle_trade_input(key_event: InputEventKey) -> void:
	var trade_key := _get_trade_key(key_event)
	if not key_event.pressed:
		if trade_key != 0:
			_trade_pressed_keys.erase(trade_key)
		if _key_matches(key_event, KEY_E):
			_interact_held = false
		return

	if trade_key == 0:
		_trade_blocked_input_count += 1
		_last_trade_action = "BLOCKED_WHILE_TRADE_OPEN"
		_last_trade_result = "NO CHANGE · TRADE VIEW BLOCKED INPUT"
		_update_trade_view()
		return
	if key_event.echo or bool(_trade_pressed_keys.get(trade_key, false)):
		_trade_held_input_count += 1
		_last_trade_action = "HELD_TRADE_KEY_%s" % (
			_get_trade_key_name(trade_key)
		)
		_last_trade_result = "NO CHANGE · RELEASE THE KEY FIRST"
		if (
			trade_key == KEY_B
			or trade_key == KEY_L
			or trade_key == KEY_C
			or trade_key == KEY_F
			or trade_key == KEY_G
		):
			var held_cargo: Array[String] = ship.get_cargo_lots()
			var held_ammunition: int = ship.get_ammunition_units()
			var held_spice_mark: Dictionary = (
				port_trader.get_mark_state(completed_voyages)
			)
			_last_held_ammunition_trade_evidence = {
				"action": _last_trade_action,
				"key": _get_trade_key_name(trade_key),
				"result": _last_trade_result,
				"money_before": money,
				"money_after": money,
				"cargo_before": held_cargo,
				"cargo_after": held_cargo.duplicate(),
				"ammunition_before": held_ammunition,
				"ammunition_after": held_ammunition,
				"world_heat_before": _world_heat.get_current_heat(),
				"world_heat_after": _world_heat.get_current_heat(),
				"spice_mark_before": held_spice_mark,
				"spice_mark_after": held_spice_mark.duplicate(true),
				"no_state_change": true,
				"fresh_press_required": true,
			}
			if trade_key == KEY_G:
				_last_held_treasure_trade_evidence = (
					_last_held_ammunition_trade_evidence.duplicate(true)
				)
		_update_trade_view()
		return

	_trade_pressed_keys[trade_key] = true
	if trade_key == KEY_X:
		_close_trade_contact()
		return
	if trade_key == KEY_C:
		if _active_trade_contact != null and _active_trade_contact.is_port_trader():
			_attempt_prize_cannon_cargo_sale()
		else:
			_trade_blocked_input_count += 1
			_last_trade_action = "SELL_PRIZE_CANNONS_BLOCKED_AT_COVE"
			_last_trade_result = "PRIZE CANNONS SELL AT PORT ONLY"
			_update_trade_view()
		return
	if trade_key == KEY_B:
		if _active_trade_contact != null and _active_trade_contact.is_port_trader():
			_attempt_ammunition_supply_purchase()
		else:
			_trade_blocked_input_count += 1
			_last_trade_action = "BUY_AMMUNITION_SUPPLY_BLOCKED_AT_COVE"
			_last_trade_result = "SHIP SUPPLY AVAILABLE AT PORT ONLY"
			_update_trade_view()
		return
	if trade_key == KEY_L:
		if _active_trade_contact != null and _active_trade_contact.is_port_trader():
			_attempt_ammunition_load()
		else:
			_trade_blocked_input_count += 1
			_last_trade_action = "LOAD_AMMUNITION_BLOCKED_AT_COVE"
			_last_trade_result = "AMMUNITION LOADING AVAILABLE AT PORT ONLY"
			_update_trade_view()
		return
	if trade_key == KEY_F:
		if _active_trade_contact != null and _active_trade_contact.is_cove_buyer():
			_attempt_fish_sale()
		else:
			_trade_blocked_input_count += 1
			_last_trade_action = "SELL_FISH_BLOCKED_AT_PORT"
			_last_trade_result = "FISH SALES AVAILABLE AT COVE ONLY"
			_update_trade_view()
		return
	if trade_key == KEY_G:
		if _active_trade_contact != null and _active_trade_contact.is_port_trader():
			_attempt_treasure_sale()
		else:
			_trade_blocked_input_count += 1
			_last_trade_action = "SELL_RUIN_TREASURE_BLOCKED_AT_COVE"
			_last_trade_result = "RUIN TREASURE SALES AVAILABLE AT PORT ONLY"
			_update_trade_view()
		return
	if _active_trade_contact != null and _active_trade_contact.is_port_trader():
		_attempt_trade_purchase()
	else:
		_attempt_trade_sale()


func _get_trade_key(key_event: InputEventKey) -> int:
	if _key_matches(key_event, KEY_E):
		return KEY_E
	if _key_matches(key_event, KEY_X):
		return KEY_X
	if _key_matches(key_event, KEY_B):
		return KEY_B
	if _key_matches(key_event, KEY_L):
		return KEY_L
	if _key_matches(key_event, KEY_C):
		return KEY_C
	if _key_matches(key_event, KEY_F):
		return KEY_F
	if _key_matches(key_event, KEY_G):
		return KEY_G
	return 0


func _get_trade_key_name(trade_key: int) -> String:
	match trade_key:
		KEY_E:
			return "E"
		KEY_B:
			return "B"
		KEY_L:
			return "L"
		KEY_C:
			return "C"
		KEY_F:
			return "F"
		KEY_G:
			return "G"
		KEY_X:
			return "X"
	return "UNKNOWN"


func _get_near_trade_contact():
	if (
		_player_near_port_trader
		and _player_shore_id == TradeContact.PORT_SHORE_ID
	):
		return port_trader
	if (
		_player_near_cove_buyer
		and (_player_shore_id.is_empty() or _player_shore_id == TradeContact.COVE_SHORE_ID)
	):
		return cove_buyer
	return null


func _can_open_trade_contact() -> bool:
	return (
		not _player_aboard_ship
		and _get_near_trade_contact() != null
		and not _dialogue_open
		and not waypoint_display.chart_visible
		and not _chart_release_pending
		and not _cargo_choice_open
		and not _cargo_choice_release_pending
		and not _storage_view_open
		and not _storage_release_pending
		and not _construction_view_open
		and not _construction_release_pending
		and not _trade_view_open
		and not _trade_release_pending
		and not _journal_view_open
		and not _journal_release_pending
	)


func _open_trade_contact() -> void:
	if not _can_open_trade_contact():
		return

	_active_trade_contact = _get_near_trade_contact()
	if _active_trade_contact == null:
		return
	if _active_trade_contact.is_port_trader():
		_record_local_port_market_in_journal(
			TradeJournalState.LOCAL_MARKET_OPEN_SOURCE
		)
	_trade_view_open = true
	_trade_open_count += 1
	_trade_pressed_keys.clear()
	# The E press that opens the view cannot also complete a trade.
	_trade_pressed_keys[KEY_E] = true
	_last_trade_action = "OPEN_%s" % _active_trade_contact.get_display_name().replace(" ", "_")
	_last_trade_result = (
		"READY · %s ONE LOT" % (
			"BUY" if _active_trade_contact.is_port_trader() else "SELL"
		)
		if _active_trade_contact.is_trade_available()
		else "UNAVAILABLE · NO %s MARKS" % (
			_active_trade_contact.get_mark_kind_name()
		)
	)
	player.movement_enabled = false
	ship.set_navigation_input_blocked(true)
	controls_help.text = (
		TRADE_BUY_CONTROLS_TEXT
		if _active_trade_contact.is_port_trader()
		else TRADE_SELL_CONTROLS_TEXT
	)
	interaction_prompt.hide()
	sign_message.hide()
	_update_cargo_view()
	_update_money_view()
	_update_trade_view()


func _close_trade_contact() -> void:
	if not _trade_view_open:
		return

	_trade_view_open = false
	_trade_release_pending = true
	_trade_close_count += 1
	_last_trade_action = "CLOSE_TRADE_VIEW"
	_last_trade_result = "TRADE VIEW CLOSED"
	trade_view.hide()
	player.movement_enabled = false
	ship.set_navigation_input_blocked(false)
	_prompt_refresh_after_navigation_release = true
	controls_help.text = TRADE_RELEASE_CONTROLS_TEXT
	interaction_prompt.hide()
	_update_cargo_view()
	_update_money_view()


func _attempt_trade_purchase() -> void:
	if (
		not _trade_view_open
		or _active_trade_contact == null
		or not _active_trade_contact.is_port_trader()
	):
		return

	_trade_purchase_attempt_count += 1
	_last_trade_action = "BUY_ONE_%s" % TradeContact.GOOD_NAME.replace(" ", "_")
	var money_before := money
	var cargo_before: Array[String] = ship.get_cargo_lots()
	var mark_state_before: Dictionary = (
		_active_trade_contact.get_mark_state(completed_voyages)
	)
	var fixed_price: int = _active_trade_contact.get_fixed_price()
	var money_preview: Dictionary = _active_trade_contact.get_money_preview(
		money_before
	)
	var denial_reasons := PackedStringArray()
	if not _active_trade_contact.is_trade_available():
		denial_reasons.append("NO STOCK MARKS")
	if money < fixed_price:
		denial_reasons.append("NEED %d COINS" % fixed_price)
	if not ship.can_keep_cargo_lot():
		denial_reasons.append("NO FREE SHIP CARGO SLOT")
	if not denial_reasons.is_empty():
		_trade_denied_purchase_count += 1
		_last_trade_result = "PURCHASE DENIED · %s" % " · ".join(denial_reasons)
		_record_trade_attempt(
			money_before,
			cargo_before,
			mark_state_before,
			money_preview,
			false,
		)
		return

	var due_voyage: int = _active_trade_contact.use_one_mark(completed_voyages)
	if due_voyage < 0:
		_trade_denied_purchase_count += 1
		_last_trade_result = "PURCHASE DENIED · STOCK MARK DID NOT CHANGE"
		_record_trade_attempt(
			money_before,
			cargo_before,
			mark_state_before,
			money_preview,
			false,
		)
		return

	if not ship.keep_cargo_lot(TradeContact.GOOD_NAME):
		var rollback_succeeded: bool = (
			_active_trade_contact.rollback_mark_use(due_voyage)
		)
		_trade_denied_purchase_count += 1
		_last_trade_result = (
			"PURCHASE DENIED · CARGO FAILED · STOCK MARK ROLLED BACK"
			if rollback_succeeded
			else "PURCHASE ERROR · STOCK MARK ROLLBACK FAILED"
		)
		_record_trade_attempt(
			money_before,
			cargo_before,
			mark_state_before,
			money_preview,
			false,
			due_voyage,
			rollback_succeeded,
		)
		return

	money -= fixed_price
	_trade_bought_lot_count += 1
	_trade_purchase_money_snapshot = money
	_trade_purchase_cargo_snapshot = ship.get_cargo_lots()
	_trade_persistence_holds = true
	_last_trade_result = "BOUGHT 1 %s · PAID %d COINS" % [
		TradeContact.GOOD_NAME,
		fixed_price,
	]
	_record_trade_attempt(
		money_before,
		cargo_before,
		mark_state_before,
		money_preview,
		true,
		due_voyage,
	)
	_record_local_port_market_in_journal(
		TradeJournalState.LOCAL_PURCHASE_SOURCE
	)
	_successful_purchase_evidence = _last_trade_attempt_evidence.duplicate(true)


func _attempt_ammunition_supply_purchase() -> void:
	if (
		not _trade_view_open
		or _active_trade_contact == null
		or not _active_trade_contact.is_port_trader()
	):
		return

	_ammunition_supply_purchase_attempt_count += 1
	_last_trade_action = "BUY_WEAPONS_AND_GUNPOWDER_CARGO_LOT"
	var money_before: int = money
	var cargo_before: Array[String] = ship.get_cargo_lots()
	var ammunition_before: int = ship.get_ammunition_units()
	var spice_mark_before: Dictionary = (
		_active_trade_contact.get_mark_state(completed_voyages)
	)
	var denial_reasons := PackedStringArray()
	if not ship.is_docked or ship.current_dock_id != TradeContact.PORT_SHORE_ID:
		denial_reasons.append("SHIP MUST BE DOCKED AT PORT")
	if money < ShipAmmunitionState.SOURCE_CARGO_FIXED_PRICE:
		denial_reasons.append(
			"NEED %d COINS" % ShipAmmunitionState.SOURCE_CARGO_FIXED_PRICE
		)
	if not ship.can_keep_cargo_lot():
		denial_reasons.append("NO FREE SHIP CARGO SLOT")
	if not denial_reasons.is_empty():
		_ammunition_supply_purchase_denied_count += 1
		_last_trade_result = "SUPPLY PURCHASE DENIED · %s" % (
			" · ".join(denial_reasons)
		)
		_record_ammunition_supply_purchase(
			false,
			money_before,
			cargo_before,
			ammunition_before,
			spice_mark_before,
		)
		return

	if not ship.keep_cargo_lot(ShipAmmunitionState.SOURCE_CARGO_LOT_NAME):
		_ammunition_supply_purchase_denied_count += 1
		_last_trade_result = "SUPPLY PURCHASE DENIED · CARGO DID NOT CHANGE"
		_record_ammunition_supply_purchase(
			false,
			money_before,
			cargo_before,
			ammunition_before,
			spice_mark_before,
		)
		return

	money -= ShipAmmunitionState.SOURCE_CARGO_FIXED_PRICE
	_ammunition_supply_purchase_success_count += 1
	_ammunition_supply_purchased_lot_count += 1
	_ammunition_supply_money_spent += (
		ShipAmmunitionState.SOURCE_CARGO_FIXED_PRICE
	)
	_last_trade_result = "BOUGHT 1 %s · PAID %d COINS" % [
		ShipAmmunitionState.SOURCE_CARGO_LOT_NAME,
		ShipAmmunitionState.SOURCE_CARGO_FIXED_PRICE,
	]
	_record_ammunition_supply_purchase(
		true,
		money_before,
		cargo_before,
		ammunition_before,
		spice_mark_before,
	)
	_successful_ammunition_supply_purchase_evidence = (
		_last_ammunition_supply_purchase_evidence.duplicate(true)
	)


func _record_ammunition_supply_purchase(
	success: bool,
	money_before: int,
	cargo_before: Array[String],
	ammunition_before: int,
	spice_mark_before: Dictionary,
) -> void:
	var cargo_after: Array[String] = ship.get_cargo_lots()
	var ammunition_after: int = ship.get_ammunition_units()
	var spice_mark_after: Dictionary = (
		_active_trade_contact.get_mark_state(completed_voyages)
	)
	var money_delta: int = money - money_before
	var cargo_delta: int = cargo_after.size() - cargo_before.size()
	var spice_state_unchanged: bool = _trade_mark_resources_equal(
		spice_mark_before,
		spice_mark_after,
	)
	_last_ammunition_supply_purchase_evidence = {
		"success": success,
		"action": _last_trade_action,
		"result": _last_trade_result,
		"source_cargo_lot_name": ShipAmmunitionState.SOURCE_CARGO_LOT_NAME,
		"fixed_price": ShipAmmunitionState.SOURCE_CARGO_FIXED_PRICE,
		"price_is_visible_fixed_ship_supply_price": true,
		"separate_from_spice_trade_route": true,
		"money_before": money_before,
		"money_after": money,
		"money_delta": money_delta,
		"cargo_before": cargo_before,
		"cargo_after": cargo_after,
		"cargo_delta": cargo_delta,
		"ammunition_before": ammunition_before,
		"ammunition_after": ammunition_after,
		"ammunition_delta": ammunition_after - ammunition_before,
		"source_purchase_does_not_load_ammunition": (
			ammunition_after == ammunition_before
		),
		"spice_mark_before": spice_mark_before,
		"spice_mark_after": spice_mark_after,
		"spice_marks_and_price_state_unchanged": spice_state_unchanged,
		"transaction_atomic": (
			(
				success
				and money_delta
					== -ShipAmmunitionState.SOURCE_CARGO_FIXED_PRICE
				and cargo_delta == 1
				and cargo_after.count(
					ShipAmmunitionState.SOURCE_CARGO_LOT_NAME
				) == cargo_before.count(
					ShipAmmunitionState.SOURCE_CARGO_LOT_NAME
				) + 1
				and spice_state_unchanged
			)
			or (
				not success
				and money_delta == 0
				and cargo_after == cargo_before
				and ammunition_after == ammunition_before
				and spice_state_unchanged
			)
		),
		"money_not_negative": money >= 0,
		"cargo_limit_not_exceeded": (
			cargo_after.size() <= ship.get_cargo_limit()
		),
	}
	if not success:
		_last_denied_ammunition_supply_purchase_evidence = (
			_last_ammunition_supply_purchase_evidence.duplicate(true)
		)
	_update_cargo_view()
	_update_money_view()
	_update_ammunition_view()
	_update_trade_view()


func _attempt_ammunition_load() -> void:
	if (
		not _trade_view_open
		or _active_trade_contact == null
		or not _active_trade_contact.is_port_trader()
	):
		return

	_last_trade_action = "LOAD_AMMUNITION_AT_PORT"
	var money_before: int = money
	_heat_before_last_ammunition_load = _world_heat.get_current_heat()
	var spice_mark_before: Dictionary = (
		_active_trade_contact.get_mark_state(completed_voyages)
	)
	var evidence: Dictionary = ship.load_ammunition_at_port()
	_heat_after_last_ammunition_load = _world_heat.get_current_heat()
	var spice_mark_after: Dictionary = (
		_active_trade_contact.get_mark_state(completed_voyages)
	)
	var spice_state_unchanged: bool = _trade_mark_resources_equal(
		spice_mark_before,
		spice_mark_after,
	)
	var load_transaction_atomic: bool = (
		(
			bool(evidence["success"])
			and bool(evidence["loaded_exactly_three"])
			and bool(evidence["same_cargo_slot"])
			and bool(evidence["one_source_lot_converted"])
			and money == money_before
			and spice_state_unchanged
			and _heat_before_last_ammunition_load
				== _heat_after_last_ammunition_load
		)
		or (
			not bool(evidence["success"])
			and evidence["cargo_before"] == evidence["cargo_after"]
			and int(evidence["ammunition_before"])
				== int(evidence["ammunition_after"])
			and money == money_before
			and spice_state_unchanged
			and _heat_before_last_ammunition_load
				== _heat_after_last_ammunition_load
		)
	)
	evidence.merge({
		"money_before": money_before,
		"money_after": money,
		"money_delta": money - money_before,
		"money_unchanged": money == money_before,
		"spice_mark_before": spice_mark_before,
		"spice_mark_after": spice_mark_after,
		"spice_marks_and_price_state_unchanged": spice_state_unchanged,
		"conversion_is_cargo_neutral": bool(
			evidence["cargo_slot_count_unchanged"]
		),
		"world_heat_before": _heat_before_last_ammunition_load,
		"world_heat_after": _heat_after_last_ammunition_load,
		"world_heat_unchanged": (
			_heat_before_last_ammunition_load
				== _heat_after_last_ammunition_load
		),
		"transaction_atomic": load_transaction_atomic,
	}, true)
	_last_ammunition_load_evidence = evidence.duplicate(true)
	_last_trade_result = String(evidence["result"])
	_update_cargo_view()
	_update_money_view()
	_update_ammunition_view()
	_update_trade_view()


func _attempt_prize_cannon_cargo_sale() -> void:
	if (
		not _trade_view_open
		or _active_trade_contact == null
		or not _active_trade_contact.is_port_trader()
	):
		return
	var money_before := money
	var cargo_before: Array[String] = ship.get_cargo_lots()
	var spice_mark_before: Dictionary = (
		port_trader.get_mark_state(completed_voyages)
	)
	var cannon_lot_name := PrizeActionState.CANNON_CARGO_LOT_NAME
	var success := cargo_before.has(cannon_lot_name)
	_last_trade_action = "SELL_PRIZE_CANNONS_AS_CARGO"
	if success:
		success = ship.remove_cargo_lot(cannon_lot_name)
	if success:
		money += PRIZE_CANNON_CARGO_SALE_PRICE
		_prize_cannon_sale_count += 1
		_prize_cannon_money_earned += PRIZE_CANNON_CARGO_SALE_PRICE
		_last_trade_result = "SOLD PRIZE CANNONS CARGO · +%d COINS" % (
			PRIZE_CANNON_CARGO_SALE_PRICE
		)
	else:
		_last_trade_result = "CANNON CARGO SALE DENIED · NO PRIZE CANNONS"
	var cargo_after: Array[String] = ship.get_cargo_lots()
	var spice_mark_after: Dictionary = (
		port_trader.get_mark_state(completed_voyages)
	)
	_last_prize_cannon_sale_evidence = {
		"success": success,
		"result": _last_trade_result,
		"cargo_lot_name": cannon_lot_name,
		"sellable_as_cargo": true,
		"usable_cannons_kept_as_module": false,
		"fixed_sale_price": PRIZE_CANNON_CARGO_SALE_PRICE,
		"money_before": money_before,
		"money_after": money,
		"money_delta": money - money_before,
		"cargo_before": cargo_before,
		"cargo_after": cargo_after,
		"cargo_delta": cargo_after.size() - cargo_before.size(),
		"spice_mark_before": spice_mark_before,
		"spice_mark_after": spice_mark_after,
		"spice_state_unchanged": spice_mark_before == spice_mark_after,
		"transaction_atomic": (
			(
				success
				and money - money_before == PRIZE_CANNON_CARGO_SALE_PRICE
				and cargo_after.size() == cargo_before.size() - 1
				and cargo_after.count(cannon_lot_name)
					== cargo_before.count(cannon_lot_name) - 1
				and spice_mark_before == spice_mark_after
			)
			or (
				not success
				and money == money_before
				and cargo_after == cargo_before
				and spice_mark_before == spice_mark_after
			)
		),
	}
	_update_cargo_view()
	_update_money_view()
	_update_trade_view()


func _attempt_trade_sale() -> void:
	if (
		not _trade_view_open
		or _active_trade_contact == null
		or not _active_trade_contact.is_cove_buyer()
	):
		return

	_trade_sale_attempt_count += 1
	_last_trade_action = "SELL_ONE_%s" % TradeContact.GOOD_NAME.replace(" ", "_")
	var money_before := money
	var cargo_before: Array[String] = ship.get_cargo_lots()
	var mark_state_before: Dictionary = (
		_active_trade_contact.get_mark_state(completed_voyages)
	)
	# Capture the active Valuable price before the demand mark changes the state.
	var fixed_price: int = _active_trade_contact.get_fixed_price()
	var money_preview: Dictionary = _active_trade_contact.get_money_preview(
		money_before
	)
	var denial_reasons := PackedStringArray()
	if not _active_trade_contact.is_trade_available():
		denial_reasons.append("NO DEMAND MARKS")
	if not cargo_before.has(TradeContact.GOOD_NAME):
		denial_reasons.append("NO %s IN SHIP CARGO" % TradeContact.GOOD_NAME)
	if not denial_reasons.is_empty():
		_trade_denied_sale_count += 1
		_last_trade_result = "SALE DENIED · %s" % " · ".join(denial_reasons)
		_record_trade_attempt(
			money_before,
			cargo_before,
			mark_state_before,
			money_preview,
			false,
		)
		return

	var due_voyage: int = _active_trade_contact.use_one_mark(completed_voyages)
	if due_voyage < 0:
		_trade_denied_sale_count += 1
		_last_trade_result = "SALE DENIED · DEMAND MARK DID NOT CHANGE"
		_record_trade_attempt(
			money_before,
			cargo_before,
			mark_state_before,
			money_preview,
			false,
		)
		return

	if not ship.remove_cargo_lot(TradeContact.GOOD_NAME):
		var rollback_succeeded: bool = (
			_active_trade_contact.rollback_mark_use(due_voyage)
		)
		_trade_denied_sale_count += 1
		_last_trade_result = (
			"SALE DENIED · CARGO FAILED · DEMAND MARK ROLLED BACK"
			if rollback_succeeded
			else "SALE ERROR · DEMAND MARK ROLLBACK FAILED"
		)
		_record_trade_attempt(
			money_before,
			cargo_before,
			mark_state_before,
			money_preview,
			false,
			due_voyage,
			rollback_succeeded,
		)
		return

	money += fixed_price
	_trade_sold_lot_count += 1
	_last_trade_result = "SOLD 1 %s · RECEIVED %d COINS" % [
		TradeContact.GOOD_NAME,
		fixed_price,
	]
	_record_trade_attempt(
		money_before,
		cargo_before,
		mark_state_before,
		money_preview,
		true,
		due_voyage,
	)
	_successful_sale_evidence = _last_trade_attempt_evidence.duplicate(true)


func _get_fish_money_preview(
	money_before: int,
	lot_name: String = FishingAreaState.FISH_LOT_NAME,
) -> Dictionary:
	var unit_count := (
		FishingAreaState.LARGE_CATCH_FISH_UNITS
		if lot_name == FishingAreaState.LARGE_FISH_LOT_NAME
		else 1
	)
	var sale_price := TradeContact.NORMAL_PRICE * unit_count
	return {
		"money_before": money_before,
		"money_after": money_before + sale_price,
		"money_delta": sale_price,
		"price_state": String(
			TradeContact.PriceState.keys()[TradeContact.PriceState.NORMAL]
		),
		"fixed_price": sale_price,
		"unit_fixed_price": TradeContact.NORMAL_PRICE,
		"fish_units": unit_count,
		"lot_name": lot_name,
	}


func _get_treasure_money_preview(money_before: int) -> Dictionary:
	return {
		"money_before": money_before,
		"money_after": money_before + TradeContact.NORMAL_PRICE,
		"money_delta": TradeContact.NORMAL_PRICE,
		"price_state": String(
			TradeContact.PriceState.keys()[TradeContact.PriceState.NORMAL]
		),
		"fixed_price": TradeContact.NORMAL_PRICE,
	}


func _attempt_treasure_sale() -> void:
	if (
		not _trade_view_open
		or _active_trade_contact == null
		or not _active_trade_contact.is_port_trader()
	):
		return

	_trade_sale_attempt_count += 1
	_treasure_sale_attempt_count += 1
	_last_trade_action = "SELL_ONE_%s" % (
		RuinExplorationState.TREASURE_LOT_NAME.replace(" ", "_")
	)
	var money_before := money
	var cargo_before: Array[String] = ship.get_cargo_lots()
	var port_mark_before: Dictionary = (
		_active_trade_contact.get_mark_state(completed_voyages)
	)
	var cove_mark_before: Dictionary = (
		cove_buyer.get_mark_state(completed_voyages)
	)
	var money_preview := _get_treasure_money_preview(money_before)
	var success := cargo_before.has(RuinExplorationState.TREASURE_LOT_NAME)
	if success:
		success = ship.remove_cargo_lot(
			RuinExplorationState.TREASURE_LOT_NAME
		)
	if success:
		money += int(money_preview["money_delta"])
		_treasure_sold_lot_count += 1
		_treasure_money_earned += int(money_preview["money_delta"])
		_last_trade_result = (
			"SOLD 1 RUIN TREASURE LOT · NORMAL · RECEIVED %d COINS"
			% money_preview["fixed_price"]
		)
	else:
		_treasure_sale_denied_count += 1
		_last_trade_result = (
			"TREASURE SALE DENIED · NO RUIN TREASURE LOT IN SHIP CARGO"
		)

	var cargo_after: Array[String] = ship.get_cargo_lots()
	var port_mark_after: Dictionary = (
		_active_trade_contact.get_mark_state(completed_voyages)
	)
	var cove_mark_after: Dictionary = (
		cove_buyer.get_mark_state(completed_voyages)
	)
	_last_treasure_sale_evidence = {
		"success": success,
		"action": _last_trade_action,
		"result": _last_trade_result,
		"treasure_lot_name": RuinExplorationState.TREASURE_LOT_NAME,
		"price_state": money_preview["price_state"],
		"fixed_sale_price": money_preview["fixed_price"],
		"canonical_normal_price": TradeContact.NORMAL_PRICE,
		"fixed_price_map": TradeContact.get_fixed_price_map(),
		"uses_canonical_normal_fixed_price": (
			RuinExplorationState.TREASURE_PRICE_STATE
				== money_preview["price_state"]
			and int(money_preview["fixed_price"]) == TradeContact.NORMAL_PRICE
			and int(TradeContact.get_fixed_price_map()["NORMAL"])
				== TradeContact.NORMAL_PRICE
		),
		"money_preview_before": money_preview["money_before"],
		"money_preview_after": money_preview["money_after"],
		"money_preview_delta": money_preview["money_delta"],
		"money_before": money_before,
		"money_after": money,
		"money_delta": money - money_before,
		"cargo_before": cargo_before,
		"cargo_after": cargo_after,
		"cargo_delta": cargo_after.size() - cargo_before.size(),
		"treasure_count_delta": (
			cargo_after.count(RuinExplorationState.TREASURE_LOT_NAME)
			- cargo_before.count(RuinExplorationState.TREASURE_LOT_NAME)
		),
		"port_spice_mark_before": port_mark_before,
		"port_spice_mark_after": port_mark_after,
		"port_spice_mark_unchanged": _trade_mark_resources_equal(
			port_mark_before,
			port_mark_after,
		),
		"cove_spice_mark_before": cove_mark_before,
		"cove_spice_mark_after": cove_mark_after,
		"cove_spice_mark_unchanged": _trade_mark_resources_equal(
			cove_mark_before,
			cove_mark_after,
		),
		"fresh_press_required": true,
		"preview_matches_actual": (
			(not success)
			or (
				money == int(money_preview["money_after"])
				and money - money_before == int(money_preview["money_delta"])
			)
		),
		"transaction_atomic": (
			(
				success
				and money - money_before == TradeContact.NORMAL_PRICE
				and cargo_after.size() == cargo_before.size() - 1
				and cargo_after.count(
					RuinExplorationState.TREASURE_LOT_NAME
				) == cargo_before.count(
					RuinExplorationState.TREASURE_LOT_NAME
				) - 1
				and _trade_mark_resources_equal(
					port_mark_before,
					port_mark_after,
				)
				and _trade_mark_resources_equal(
					cove_mark_before,
					cove_mark_after,
				)
			)
			or (
				not success
				and money == money_before
				and cargo_after == cargo_before
				and _trade_mark_resources_equal(
					port_mark_before,
					port_mark_after,
				)
				and _trade_mark_resources_equal(
					cove_mark_before,
					cove_mark_after,
				)
			)
		),
	}
	if success:
		_successful_treasure_sale_evidence = (
			_last_treasure_sale_evidence.duplicate(true)
		)
	ruin_exploration.record_sale(_last_treasure_sale_evidence)
	_update_cargo_view()
	_update_money_view()
	_update_trade_view()


func _attempt_fish_sale() -> void:
	if (
		not _trade_view_open
		or _active_trade_contact == null
		or not _active_trade_contact.is_cove_buyer()
	):
		return

	_trade_sale_attempt_count += 1
	_fish_sale_attempt_count += 1
	var fish_lot_name := (
		FishingAreaState.LARGE_FISH_LOT_NAME
		if ship.get_cargo_lots().has(FishingAreaState.LARGE_FISH_LOT_NAME)
		else FishingAreaState.FISH_LOT_NAME
	)
	_last_trade_action = "SELL_ONE_%s" % fish_lot_name.replace(
		" ",
		"_",
	)
	var money_before := money
	var sold_fish_units_before := _fish_sold_unit_count
	var cargo_before: Array[String] = ship.get_cargo_lots()
	var mark_state_before: Dictionary = (
		_active_trade_contact.get_mark_state(completed_voyages)
	)
	var money_preview := _get_fish_money_preview(money_before, fish_lot_name)
	var success := cargo_before.has(fish_lot_name)
	if success:
		success = ship.remove_cargo_lot(fish_lot_name)
	if success:
		money += int(money_preview["money_delta"])
		_fish_sold_lot_count += 1
		_fish_sold_unit_count += int(money_preview["fish_units"])
		_fish_money_earned += int(money_preview["money_delta"])
		_last_trade_result = "SOLD 1 %s · %d FISH · RECEIVED %d COINS" % [
			fish_lot_name,
			money_preview["fish_units"],
			money_preview["fixed_price"],
		]
	else:
		_fish_sale_denied_count += 1
		_last_trade_result = "FISH SALE DENIED · NO FISH LOT IN SHIP CARGO"

	var cargo_after: Array[String] = ship.get_cargo_lots()
	var mark_state_after: Dictionary = (
		_active_trade_contact.get_mark_state(completed_voyages)
	)
	_last_fish_sale_evidence = {
		"success": success,
		"action": _last_trade_action,
		"result": _last_trade_result,
		"fish_lot_name": fish_lot_name,
		"fish_units": money_preview["fish_units"],
		"sold_fish_units_before": sold_fish_units_before,
		"sold_fish_units_after": _fish_sold_unit_count,
		"sold_fish_unit_delta": (
			_fish_sold_unit_count - sold_fish_units_before
		),
		"price_state": money_preview["price_state"],
		"fixed_sale_price": money_preview["fixed_price"],
		"canonical_normal_price": TradeContact.NORMAL_PRICE,
		"fixed_price_map": TradeContact.get_fixed_price_map(),
		"uses_canonical_normal_fixed_price": (
			FishingAreaState.FISH_PRICE_STATE == money_preview["price_state"]
			and int(money_preview["unit_fixed_price"])
				== TradeContact.NORMAL_PRICE
			and int(TradeContact.get_fixed_price_map()["NORMAL"])
				== TradeContact.NORMAL_PRICE
		),
		"money_preview_before": money_preview["money_before"],
		"money_preview_after": money_preview["money_after"],
		"money_preview_delta": money_preview["money_delta"],
		"money_before": money_before,
		"money_after": money,
		"money_delta": money - money_before,
		"cargo_before": cargo_before,
		"cargo_after": cargo_after,
		"cargo_delta": cargo_after.size() - cargo_before.size(),
		"fish_count_delta": (
			cargo_after.count(fish_lot_name)
			- cargo_before.count(fish_lot_name)
		),
		"cove_spice_mark_before": mark_state_before,
		"cove_spice_mark_after": mark_state_after,
		"spice_demand_unchanged": _trade_mark_resources_equal(
			mark_state_before,
			mark_state_after,
		),
		"fresh_press_required": true,
		"preview_matches_actual": (
			(not success)
			or (
				money == int(money_preview["money_after"])
				and money - money_before
					== int(money_preview["money_delta"])
			)
		),
		"transaction_atomic": (
			(
				success
				and money - money_before == int(money_preview["money_delta"])
				and _fish_sold_unit_count - sold_fish_units_before
					== int(money_preview["fish_units"])
				and cargo_after.size() == cargo_before.size() - 1
				and cargo_after.count(fish_lot_name)
					== cargo_before.count(fish_lot_name) - 1
				and _trade_mark_resources_equal(
					mark_state_before,
					mark_state_after,
				)
			)
			or (
				not success
				and money == money_before
				and _fish_sold_unit_count == sold_fish_units_before
				and cargo_after == cargo_before
				and _trade_mark_resources_equal(
					mark_state_before,
					mark_state_after,
				)
			)
		),
	}
	if success:
		_successful_fish_sale_evidence = _last_fish_sale_evidence.duplicate(true)
	_update_cargo_view()
	_update_money_view()
	_update_trade_view()


func _record_trade_attempt(
	money_before: int,
	cargo_before: Array[String],
	mark_state_before: Dictionary,
	money_preview: Dictionary,
	success: bool,
	consumed_due_voyage: int = -1,
	rollback_succeeded: bool = false,
) -> void:
	var cargo_after: Array[String] = ship.get_cargo_lots()
	var mark_state_after: Dictionary = (
		_active_trade_contact.get_mark_state(completed_voyages)
	)
	var preview_matches_actual := (
		money == int(money_preview["money_after"])
		and money - money_before == int(money_preview["money_delta"])
	)
	var money_unchanged := money == money_before
	var cargo_unchanged := cargo_after == cargo_before
	var marks_unchanged := _trade_mark_resources_equal(
		mark_state_before,
		mark_state_after,
	)
	var expected_cargo_delta := (
		1 if _active_trade_contact.is_port_trader() else -1
	)
	var successful_changes_hold := (
		money - money_before == int(money_preview["money_delta"])
		and cargo_after.size() - cargo_before.size() == expected_cargo_delta
		and int(mark_state_after["marks_available"])
			== int(mark_state_before["marks_available"]) - 1
		and int(mark_state_after["marks_used"])
			== int(mark_state_before["marks_used"]) + 1
	)
	_last_trade_attempt_evidence = {
		"action": _last_trade_action,
		"result": _last_trade_result,
		"success": success,
		"good_name": TradeContact.GOOD_NAME,
		"price_state": money_preview["price_state"],
		"price_state_before": money_preview["price_state"],
		"price_state_after": mark_state_after["current_price_state"],
		"fixed_price": money_preview["fixed_price"],
		"fixed_price_before": money_preview["fixed_price"],
		"fixed_price_after": mark_state_after["current_fixed_price"],
		"fixed_price_map": TradeContact.get_fixed_price_map(),
		"buy_price": TradeContact.get_fixed_price_map()["CHEAP"],
		"sell_price": TradeContact.get_fixed_price_map()["VALUABLE"],
		"money_preview_before": money_preview["money_before"],
		"money_preview_after": money_preview["money_after"],
		"money_preview_delta": money_preview["money_delta"],
		"money_before": money_before,
		"money_after": money,
		"cargo_before": cargo_before,
		"cargo_after": cargo_after,
		"money_delta": money - money_before,
		"cargo_delta": cargo_after.size() - cargo_before.size(),
		"completed_voyage": completed_voyages,
		"mark_kind": mark_state_before["mark_kind"],
		"mark_capacity": mark_state_before["mark_capacity"],
		"marks_available_before": mark_state_before["marks_available"],
		"marks_available_after": mark_state_after["marks_available"],
		"marks_used_before": mark_state_before["marks_used"],
		"marks_used_after": mark_state_after["marks_used"],
		"mark_return_voyages_before": mark_state_before["return_voyages"],
		"mark_return_voyages_after": mark_state_after["return_voyages"],
		"due_voyage": consumed_due_voyage,
		"expected_due_voyage": (
			completed_voyages + TradeContact.MARK_RETURN_VOYAGES
			if success
			else -1
		),
		"due_voyage_is_use_voyage_plus_two": (
			not success
			or consumed_due_voyage
				== completed_voyages + TradeContact.MARK_RETURN_VOYAGES
		),
		"matching_mark_consumed": (
			not success
			or (
				int(mark_state_after["marks_available"])
					== int(mark_state_before["marks_available"]) - 1
				and int(mark_state_after["marks_used"])
					== int(mark_state_before["marks_used"]) + 1
			)
		),
		"rollback_succeeded": rollback_succeeded,
		"preview_matches_actual": success and preview_matches_actual,
		"successful_preview_requirement_holds": (
			not success or preview_matches_actual
		),
		"no_state_change": money_unchanged and cargo_unchanged and marks_unchanged,
		"denied_no_state_change": (
			not success and money_unchanged and cargo_unchanged and marks_unchanged
		),
		"transaction_atomic": (
			successful_changes_hold
			if success
			else money_unchanged and cargo_unchanged and marks_unchanged
		),
		"money_not_negative": money >= 0,
		"cargo_limit_not_exceeded": cargo_after.size() <= ship.get_cargo_limit(),
	}
	_update_cargo_view()
	_update_money_view()
	_update_trade_view()


func _trade_mark_resources_equal(before: Dictionary, after: Dictionary) -> bool:
	return (
		before["mark_kind"] == after["mark_kind"]
		and before["mark_capacity"] == after["mark_capacity"]
		and before["marks_available"] == after["marks_available"]
		and before["marks_used"] == after["marks_used"]
		and before["return_voyages"] == after["return_voyages"]
		and before["current_price_state"] == after["current_price_state"]
		and before["current_fixed_price"] == after["current_fixed_price"]
	)


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
		and not _trade_view_open
		and not _trade_release_pending
		and not _journal_view_open
		and not _journal_release_pending
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
		KEY_0:
			_store_ship_cargo_slot(3)
		KEY_4:
			_withdraw_cove_storage_slot(0)
		KEY_5:
			_withdraw_cove_storage_slot(1)
		KEY_6:
			_withdraw_cove_storage_slot(2)


func _get_storage_key(key_event: InputEventKey) -> int:
	if _key_matches(key_event, KEY_0):
		return KEY_0
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
		KEY_0:
			return "0"
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


func _handle_ship_module_input(key_event: InputEventKey) -> void:
	var module_key := _get_ship_module_key(key_event)
	if not key_event.pressed:
		if module_key != 0:
			_module_pressed_keys.erase(module_key)
		if _key_matches(key_event, KEY_E):
			_interact_held = false
		return
	if module_key == 0:
		ship_module_loadout.record_blocked_input(
			_key_event_name(key_event),
			ship.get_cargo_lots().size(),
		)
		_update_ship_module_view()
		return
	if key_event.echo or bool(_module_pressed_keys.get(module_key, false)):
		if module_key != KEY_X:
			ship_module_loadout.record_held_selection(
				_get_ship_module_id_for_key(module_key),
				ship.get_cargo_lots().size(),
			)
		_update_ship_module_view()
		return
	_module_pressed_keys[module_key] = true
	if module_key == KEY_X:
		_close_ship_module_bench()
		return
	var module_id := _get_ship_module_id_for_key(module_key)
	ship_module_loadout.select_module(module_id, ship.get_cargo_lots().size())
	_update_ship_module_view()
	_update_cargo_view()


func _get_ship_module_key(key_event: InputEventKey) -> int:
	if _key_matches(key_event, KEY_1):
		return KEY_1
	if _key_matches(key_event, KEY_2):
		return KEY_2
	if _key_matches(key_event, KEY_3):
		return KEY_3
	if _key_matches(key_event, KEY_X):
		return KEY_X
	return 0


func _get_ship_module_id_for_key(module_key: int) -> String:
	match module_key:
		KEY_1:
			return ShipModuleLoadoutState.MODULE_CARGO_RACKS
		KEY_2:
			return ShipModuleLoadoutState.MODULE_LONG_GUNS
		KEY_3:
			return ShipModuleLoadoutState.MODULE_FISHING_GEAR
	return ShipModuleLoadoutState.MODULE_NONE


func _key_event_name(key_event: InputEventKey) -> String:
	var keycode := key_event.physical_keycode
	if keycode == 0:
		keycode = key_event.keycode
	return OS.get_keycode_string(keycode)


func _can_open_ship_module_bench() -> bool:
	return (
		not _player_aboard_ship
		and (_player_shore_id.is_empty() or _player_shore_id == "cove")
		and _player_near_ship_module_bench
		and not _dialogue_open
		and not waypoint_display.chart_visible
		and not _chart_release_pending
		and not _cargo_choice_open
		and not _cargo_choice_release_pending
		and not _storage_view_open
		and not _storage_release_pending
		and not _construction_view_open
		and not _construction_release_pending
		and not _trade_view_open
		and not _trade_release_pending
		and not _journal_view_open
		and not _journal_release_pending
		and not ship_module_loadout.is_selection_open()
		and not ship_module_loadout.is_release_pending()
	)


func _open_ship_module_bench() -> void:
	if not _can_open_ship_module_bench():
		return
	if not ship_module_loadout.open_selection(ship.get_cargo_lots().size()):
		return
	_module_pressed_keys.clear()
	player.movement_enabled = false
	ship.set_navigation_input_blocked(true)
	controls_help.text = MODULE_CONTROLS_TEXT
	interaction_prompt.hide()
	_update_ship_module_view()
	_update_cargo_view()


func _close_ship_module_bench() -> void:
	if not ship_module_loadout.close_selection():
		return
	player.movement_enabled = false
	ship.set_navigation_input_blocked(false)
	controls_help.text = MODULE_RELEASE_CONTROLS_TEXT
	interaction_prompt.hide()
	_update_ship_module_view()


func _update_ship_module_release_pending() -> void:
	if not ship_module_loadout.is_release_pending():
		return
	if _is_any_ship_module_guard_key_pressed():
		return
	ship_module_loadout.release_guard()
	_module_pressed_keys.clear()
	_interact_held = false
	player.movement_enabled = true
	controls_help.text = _get_context_controls_text()
	_update_ship_module_view()
	_update_interaction_prompt()


func _prepare_ship_module_for_cove_departure() -> bool:
	var activation: Dictionary = ship_module_loadout.prepare_for_cove_departure(
		ship.get_cargo_lots().size()
	)
	if not bool(activation.get("success", false)):
		ship.set_module_departure_ready(false)
		_update_ship_module_view()
		return false
	var limit_change: Dictionary = ship.set_cargo_limit(
		ship_module_loadout.get_active_cargo_limit()
	)
	var ready := bool(limit_change.get("success", false))
	ship.set_module_departure_ready(ready)
	_update_ship_module_view()
	_update_cargo_view()
	return ready


func _update_ship_module_view() -> void:
	ship_module_title.text = "SHIP MODULE BENCH · ONE SLOT"
	ship_module_status.text = "ACTIVE · %s · NEXT · %s" % [
		ship_module_loadout.get_active_module_name(),
		ship_module_loadout.get_pending_module_name(),
	]
	var cargo_racks_marker := " >" if (
		ship_module_loadout.get_pending_module()
			== ShipModuleLoadoutState.MODULE_CARGO_RACKS
	) else ""
	var long_guns_marker := " >" if (
		ship_module_loadout.get_pending_module()
			== ShipModuleLoadoutState.MODULE_LONG_GUNS
	) else ""
	var fishing_gear_marker := " >" if (
		ship_module_loadout.get_pending_module()
			== ShipModuleLoadoutState.MODULE_FISHING_GEAR
	) else ""
	ship_module_details.text = (
		"[1]%s CARGO RACKS · CARGO LIMIT 4\n"
		+ "[2]%s LONG GUNS · [P] FORWARD PURSUIT SAIL ATTACK\n"
		+ "[3]%s FISHING GEAR · ONE LARGE CATCH NEXT COVE VOYAGE\n\n"
		+ "SHIP CARGO · %d/%d · ONE SLOT · ONE CHOICE"
	) % [
		cargo_racks_marker,
		long_guns_marker,
		fishing_gear_marker,
		ship.get_cargo_lots().size(),
		ship.get_cargo_limit(),
	]
	ship_module_result.text = ship_module_loadout.get_selection_result()
	ship_module_controls.text = (
		MODULE_RELEASE_CONTROLS_TEXT
		if ship_module_loadout.is_release_pending()
		else "[1] CARGO RACKS · [2] LONG GUNS · [3] FISHING GEAR · [X] CLOSE"
	)
	ship_module_view.visible = ship_module_loadout.is_selection_open()


func _can_open_cove_storage() -> bool:
	return (
		not _player_aboard_ship
		and (_player_shore_id.is_empty() or _player_shore_id == "cove")
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
		and not _trade_view_open
		and not _trade_release_pending
		and not _journal_view_open
		and not _journal_release_pending
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
	_update_food_view()


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
	if _key_matches(key_event, KEY_E):
		if _pending_cargo_source == CARGO_SOURCE_RUIN:
			ruin_exploration.record_held_or_guarded_interaction(
				"TREASURE_CHOICE_HELD_E",
				ship.get_cargo_lots(),
			)
		elif _pending_cargo_source == CARGO_SOURCE_STORY_CLUE:
			story_clue.record_held_or_guarded_interaction(
				"FRAGMENT_CHOICE_HELD_E",
				ship.get_cargo_lots(),
			)
		return
	if key_event.echo:
		return
	if _key_matches(key_event, KEY_X):
		_leave_or_discard_pending_cargo_lot()
		return
	if _key_matches(key_event, KEY_1):
		_replace_cargo_with_pending_lot(0)
	elif _key_matches(key_event, KEY_2):
		_replace_cargo_with_pending_lot(1)
	elif _key_matches(key_event, KEY_3):
		_replace_cargo_with_pending_lot(2)
	elif _key_matches(key_event, KEY_4):
		_replace_cargo_with_pending_lot(3)


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
	elif _key_matches(key_event, KEY_4):
		waypoint_display.select_story_location()
	elif _key_matches(key_event, KEY_X):
		waypoint_display.clear_location()
	else:
		return true
	return true


func _key_matches(key_event: InputEventKey, key: Key) -> bool:
	return key_event.physical_keycode == key or key_event.keycode == key


func _get_chart_controls_text() -> String:
	if story_clue.is_story_location_unlocked():
		return CHART_STORY_CONTROLS_TEXT
	return CHART_CONTROLS_TEXT


func _set_chart_visible(visible: bool) -> void:
	if (
		_defeat_recovery.is_result_open()
		or _defeat_recovery.is_release_guard_pending()
		or _storage_view_open
		or _storage_release_pending
		or _construction_view_open
		or _construction_release_pending
		or _trade_view_open
		or _trade_release_pending
		or _journal_view_open
		or _journal_release_pending
		or ship_module_loadout.is_selection_open()
		or ship_module_loadout.is_release_pending()
	):
		return
	waypoint_display.set_chart_visible(visible)
	_interact_held = false
	if visible:
		_chart_release_pending = false
		player.movement_enabled = false
		ship.set_navigation_input_blocked(true)
		controls_help.text = _get_chart_controls_text()
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


func _update_trade_release_pending() -> void:
	if not _trade_release_pending or _trade_view_open:
		return
	if _is_any_trade_guard_key_pressed():
		player.movement_enabled = false
		return

	_trade_release_pending = false
	_trade_pressed_keys.clear()
	player.movement_enabled = not _player_aboard_ship and not _dialogue_open
	controls_help.text = _get_context_controls_text()
	_update_interaction_prompt()


func _update_journal_release_pending() -> void:
	if not _journal_release_pending or _journal_view_open:
		return
	if _is_any_journal_guard_key_pressed():
		player.movement_enabled = false
		return

	_journal_release_pending = false
	_journal_pressed_keys.clear()
	ship.set_navigation_input_blocked(
		false,
		_player_aboard_ship and not ship.is_docked,
	)
	player.movement_enabled = not _player_aboard_ship and not _dialogue_open
	controls_help.text = _get_context_controls_text()
	_update_interaction_prompt()


func _refresh_prompt_after_navigation_release() -> void:
	if not _prompt_refresh_after_navigation_release:
		return
	if (
		waypoint_display.chart_visible
		or _defeat_recovery.is_result_open()
		or _defeat_recovery.is_release_guard_pending()
		or _chart_release_pending
		or _cargo_choice_open
		or _cargo_choice_release_pending
		or _storage_view_open
		or _storage_release_pending
		or _construction_view_open
		or _construction_release_pending
		or _trade_view_open
		or _trade_release_pending
		or _journal_view_open
		or _journal_release_pending
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
		or Input.is_key_pressed(KEY_V)
		or Input.is_key_pressed(KEY_P)
		or Input.is_key_pressed(KEY_X)
		or Input.is_key_pressed(KEY_1)
		or Input.is_key_pressed(KEY_2)
		or Input.is_key_pressed(KEY_3)
		or Input.is_key_pressed(KEY_4)
	)


func _is_any_ship_module_guard_key_pressed() -> bool:
	return (
		_is_any_movement_key_pressed()
		or Input.is_key_pressed(KEY_E)
		or Input.is_key_pressed(KEY_M)
		or Input.is_key_pressed(KEY_P)
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
		or Input.is_key_pressed(KEY_0)
	)


func _is_any_construction_guard_key_pressed() -> bool:
	return (
		_is_any_movement_key_pressed()
		or Input.is_key_pressed(KEY_E)
		or Input.is_key_pressed(KEY_M)
		or Input.is_key_pressed(KEY_X)
	)


func _is_any_trade_guard_key_pressed() -> bool:
	return (
		_is_any_movement_key_pressed()
		or Input.is_key_pressed(KEY_E)
		or Input.is_key_pressed(KEY_B)
		or Input.is_key_pressed(KEY_L)
		or Input.is_key_pressed(KEY_C)
		or Input.is_key_pressed(KEY_F)
		or Input.is_key_pressed(KEY_G)
		or Input.is_key_pressed(KEY_M)
		or Input.is_key_pressed(KEY_X)
		or Input.is_key_pressed(KEY_1)
		or Input.is_key_pressed(KEY_2)
		or Input.is_key_pressed(KEY_3)
		or Input.is_key_pressed(KEY_4)
		or Input.is_key_pressed(KEY_5)
		or Input.is_key_pressed(KEY_6)
	)


func _is_any_journal_guard_key_pressed() -> bool:
	return (
		_is_any_movement_key_pressed()
		or Input.is_key_pressed(KEY_J)
		or Input.is_key_pressed(KEY_X)
		or Input.is_key_pressed(KEY_E)
		or Input.is_key_pressed(KEY_M)
		or Input.is_key_pressed(KEY_1)
		or Input.is_key_pressed(KEY_2)
		or Input.is_key_pressed(KEY_3)
		or Input.is_key_pressed(KEY_4)
		or Input.is_key_pressed(KEY_5)
		or Input.is_key_pressed(KEY_6)
	)


func _is_any_defeat_guard_key_pressed() -> bool:
	return (
		_is_any_movement_key_pressed()
		or Input.is_key_pressed(KEY_X)
		or Input.is_key_pressed(KEY_E)
		or Input.is_key_pressed(KEY_M)
		or Input.is_key_pressed(KEY_J)
		or Input.is_key_pressed(KEY_R)
		or Input.is_key_pressed(KEY_V)
		or Input.is_key_pressed(KEY_P)
		or Input.is_key_pressed(KEY_Q)
		or Input.is_key_pressed(KEY_F)
		or Input.is_key_pressed(KEY_H)
		or Input.is_key_pressed(KEY_K)
		or Input.is_key_pressed(KEY_SPACE)
		or Input.is_key_pressed(KEY_1)
		or Input.is_key_pressed(KEY_2)
		or Input.is_key_pressed(KEY_3)
		or Input.is_key_pressed(KEY_4)
		or Input.is_key_pressed(KEY_5)
		or Input.is_key_pressed(KEY_6)
	)


func _get_context_controls_text() -> String:
	if _defeat_recovery.is_result_open():
		return DEFEAT_RESULT_CONTROLS_TEXT
	if _defeat_recovery.is_release_guard_pending():
		return DEFEAT_RELEASE_CONTROLS_TEXT
	if _player_on_target_deck:
		return (
			PRIZE_CONTROLS_TEXT
			if _prize_actions.screen_open
			else BOARDING_DECK_CONTROLS_TEXT
		)
	if ship_module_loadout.is_selection_open():
		return MODULE_CONTROLS_TEXT
	if ship_module_loadout.is_release_pending():
		return MODULE_RELEASE_CONTROLS_TEXT
	if _journal_view_open:
		return JOURNAL_CONTROLS_TEXT
	if _journal_release_pending:
		return JOURNAL_RELEASE_CONTROLS_TEXT
	if _trade_view_open:
		return (
			TRADE_BUY_CONTROLS_TEXT
			if _active_trade_contact != null and _active_trade_contact.is_port_trader()
			else TRADE_SELL_CONTROLS_TEXT
		)
	if _trade_release_pending:
		return TRADE_RELEASE_CONTROLS_TEXT
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
		return _get_cargo_choice_controls_text()
	if _cargo_choice_release_pending or ship.navigation_release_pending:
		return RELEASE_CONTROLS_TEXT
	if ruin_exploration.is_inside():
		return "WASD / ARROWS TO WALK · E INTERACT WITH RUIN FINDS OR EXIT"
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
			and not _defeat_recovery.is_result_open()
			and not _defeat_recovery.is_release_guard_pending()
			and not waypoint_display.chart_visible
			and not _cargo_choice_open
			and not _cargo_choice_release_pending
			and not _storage_view_open
			and not _storage_release_pending
			and not _construction_view_open
			and not _construction_release_pending
			and not _trade_view_open
			and not _trade_release_pending
			and not _journal_view_open
			and not _journal_release_pending
		),
		(
			not _defeat_recovery.is_result_open()
			and not _defeat_recovery.is_release_guard_pending()
			and not waypoint_display.chart_visible
			and not _cargo_choice_open
			and not _cargo_choice_release_pending
			and not _storage_view_open
			and not _storage_release_pending
			and not _construction_view_open
			and not _construction_release_pending
			and not _trade_view_open
			and not _trade_release_pending
			and not _journal_view_open
			and not _journal_release_pending
		),
	)


func _update_fishing_area() -> void:
	fishing_area.configure_fishing_gear(
		ship_module_loadout.is_fishing_gear_active(),
		ship_module_loadout.get_active_voyage_serial(),
	)
	var world_input_available: bool = (
		_player_aboard_ship
		and ship.controls_enabled
		and not ship.is_docked
		and not _player_on_target_deck
		and not _defeat_recovery.is_result_open()
		and not _defeat_recovery.is_release_guard_pending()
		and not waypoint_display.chart_visible
		and not _chart_release_pending
		and not _cargo_choice_open
		and not _cargo_choice_release_pending
		and not _storage_view_open
		and not _storage_release_pending
		and not _construction_view_open
		and not _construction_release_pending
		and not _trade_view_open
		and not _trade_release_pending
		and not _journal_view_open
		and not _journal_release_pending
		and not _target_inspection_view_open
		and not ship.navigation_input_blocked
		and not ship.navigation_release_pending
	)
	fishing_area.update_state(
		ship.global_position,
		ship.current_speed,
		_player_aboard_ship,
		ship.captain_aboard,
		_player_aboard_ship and not _player_on_target_deck,
		world_input_available,
		weather_area.is_fishing_blocked(),
	)


func _update_ruin_exploration() -> void:
	var prompt_before := ruin_exploration.get_interaction_prompt()
	ruin_exploration.update_state(
		player.global_position,
		_player_shore_id,
		player.movement_enabled,
	)
	if ruin_exploration.get_interaction_prompt() != prompt_before:
		_update_interaction_prompt()


func _update_story_clue() -> void:
	var prompt_before := story_clue.get_interaction_prompt()
	story_clue.update_state(
		player.global_position,
		ruin_exploration.is_inside(),
		ruin_exploration.is_tool_gate_open(),
	)
	if story_clue.get_interaction_prompt() != prompt_before:
		_update_interaction_prompt()


func _update_monster_hunt(delta: float) -> void:
	var modal_pause_active := (
		_defeat_recovery.is_result_open()
		or _defeat_recovery.is_release_guard_pending()
		or waypoint_display.chart_visible
		or _chart_release_pending
		or _cargo_choice_open
		or _cargo_choice_release_pending
		or _storage_view_open
		or _storage_release_pending
		or _construction_view_open
		or _construction_release_pending
		or _trade_view_open
		or _trade_release_pending
		or _journal_view_open
		or _journal_release_pending
		or _target_inspection_view_open
	)
	var input_available := _is_monster_harpoon_input_available()
	var attack_requested := monster_hunt.update_encounter(
		delta,
		ship.global_position,
		_player_aboard_ship,
		ship.captain_aboard,
		_player_aboard_ship and not _player_on_target_deck,
		input_available,
		story_clue.is_story_location_unlocked(),
		weather_area.is_storm_active(),
		modal_pause_active,
	)
	if attack_requested:
		var money_before := money
		var target_conditions_before := _get_target_condition_snapshots()
		var story_before: Dictionary = story_clue.get_playtest_state()
		var evidence: Dictionary = ship.apply_monster_attack()
		var target_conditions_after := _get_target_condition_snapshots()
		var story_after: Dictionary = story_clue.get_playtest_state()
		evidence.merge({
			"money_before": money_before,
			"money_after": money,
			"money_unchanged": money_before == money,
			"target_conditions_before": target_conditions_before,
			"target_conditions_after": target_conditions_after,
			"target_conditions_unchanged": (
				target_conditions_before == target_conditions_after
			),
			"story_clue_before": story_before,
			"story_clue_after": story_after,
			"story_clue_unchanged": story_before == story_after,
			"weather_state": (
				WeatherAreaState.WEATHER_STORM
				if weather_area.is_storm_active()
				else WeatherAreaState.WEATHER_CLEAR
			),
			"one_clear_monster_attack": true,
			"only_expected_ship_and_crew_costs_changed": (
				bool(evidence.get(
					"hull_changed_only_by_fixed_monster_damage",
					false,
				))
				and bool(evidence.get(
					"crew_changed_only_by_fixed_monster_injury",
					false,
				))
				and bool(evidence.get(
					"unrelated_ship_resources_unchanged",
					false,
				))
				and money_before == money
				and target_conditions_before == target_conditions_after
				and story_before == story_after
			),
		}, true)
		_last_monster_attack_evidence = evidence.duplicate(true)
		_last_crew_combat_context_evidence = evidence.duplicate(true)
		if bool(evidence.get("crew_injury_applied", false)):
			_last_crew_injury_context_evidence = evidence.duplicate(true)
		monster_hunt.record_attack_result(evidence)
	_update_monster_return_state()


func _is_monster_harpoon_input_available() -> bool:
	return (
		_player_aboard_ship
		and ship.captain_aboard
		and ship.controls_enabled
		and not ship.is_docked
		and not _player_on_target_deck
		and not _defeat_recovery.is_result_open()
		and not _defeat_recovery.is_release_guard_pending()
		and not waypoint_display.chart_visible
		and not _chart_release_pending
		and not _cargo_choice_open
		and not _cargo_choice_release_pending
		and not _storage_view_open
		and not _storage_release_pending
		and not _construction_view_open
		and not _construction_release_pending
		and not _trade_view_open
		and not _trade_release_pending
		and not _journal_view_open
		and not _journal_release_pending
		and not _target_inspection_view_open
		and not ship.navigation_input_blocked
		and not ship.navigation_release_pending
	)


func _handle_monster_harpoon_input(key_event: InputEventKey) -> void:
	if not key_event.pressed:
		_harpoon_pressed = false
		return
	var context := _get_monster_hunt_context()
	if key_event.echo or _harpoon_pressed:
		monster_hunt.record_held_harpoon(
			ship.get_ammunition_units(),
			context,
		)
		_update_monster_hunt_view()
		return
	_harpoon_pressed = true
	_attempt_monster_harpoon(context)


func _attempt_monster_harpoon(context_before: Dictionary) -> void:
	var preflight := monster_hunt.try_begin_harpoon(
		_is_monster_harpoon_input_available(),
		ship.get_ammunition_units(),
		context_before,
	)
	if not bool(preflight.get("success", false)):
		_update_monster_hunt_view()
		return
	var ammunition_evidence: Dictionary = ship.consume_ammunition_for_harpoon()
	var result: Dictionary = monster_hunt.resolve_accepted_harpoon(
		preflight,
		ammunition_evidence,
		_get_monster_hunt_context(),
	)
	if bool(result.get("defeated_now", false)):
		_award_monster_part()
	_update_cargo_view()
	_update_ammunition_view()
	_update_monster_hunt_view()


func _award_monster_part() -> void:
	if not monster_hunt.has_pending_part():
		return
	var cargo_before: Array[String] = ship.get_cargo_lots()
	if not ship.can_keep_cargo_lot():
		if not _open_cargo_choice(
			MonsterHuntState.PART_LOT_NAME,
			CARGO_SOURCE_MONSTER_HUNT,
		):
			_last_cargo_action = "MONSTER_PART_REWARD"
			_last_cargo_result = "NO_CHANGE_CHOICE_NOT_OPENED"
		return
	if not ship.keep_cargo_lot(MonsterHuntState.PART_LOT_NAME):
		_last_cargo_action = "KEEP_MONSTER_PART"
		_last_cargo_result = "NO_CHANGE_CARGO_FULL"
		return
	if not monster_hunt.resolve_direct_keep(
		cargo_before,
		ship.get_cargo_lots(),
	):
		ship.undo_last_kept_cargo_lot(MonsterHuntState.PART_LOT_NAME)
		_last_cargo_action = "KEEP_MONSTER_PART"
		_last_cargo_result = "ROLLED_BACK_MONSTER_HUNT_STATE"
		return
	_cargo_kept_count += 1
	_last_cargo_action = "KEEP_MONSTER_PART"
	_last_cargo_result = "KEPT_ONE_BLACKWAKE_MONSTER_PART_LOT"


func _get_monster_hunt_context() -> Dictionary:
	var damage_state: Dictionary = ship.get_damage_playtest_state()
	var crew_state: Dictionary = ship.get_crew_condition_playtest_state()
	return {
		"ship_position": ship.global_position,
		"ship_speed": ship.current_speed,
		"ship_is_docked": ship.is_docked,
		"captain_aboard": ship.captain_aboard,
		"cargo_lots": ship.get_cargo_lots(),
		"cargo_used_slots": ship.get_cargo_lots().size(),
		"cargo_limit": ship.get_cargo_limit(),
		"ammunition_units": ship.get_ammunition_units(),
		"hull_current": damage_state["hull_current"],
		"crew_condition": crew_state["condition"],
		"money": money,
		"story_location_unlocked": story_clue.is_story_location_unlocked(),
		"weather_storm_active": weather_area.is_storm_active(),
		"world_heat": _world_heat.get_current_heat(),
	}


func _update_monster_return_state() -> void:
	var at_cove: bool = (
		(ship.is_docked and ship.current_dock_id == "cove")
		or (not _player_aboard_ship and _player_shore_id == "cove")
	)
	var returned_now := monster_hunt.record_return_to_cove(
		ship.get_cargo_lots(),
		at_cove,
	)
	if not returned_now:
		return
	var monster_state: Dictionary = monster_hunt.get_playtest_state(
		ship.get_cargo_lots(),
		cove_storage.get_cargo_lots(),
	)
	resident.record_important_voyage_event(
		CoveResident.IMPORTANT_EVENT_ID,
		CoveResident.IMPORTANT_EVENT_NAME,
		monster_state["last_return_evidence"],
	)


func _update_monster_hunt_view() -> void:
	var monster_state: Dictionary = monster_hunt.get_playtest_state(
		ship.get_cargo_lots(),
		cove_storage.get_cargo_lots(),
	)
	monster_hunt_title.text = monster_hunt.get_hud_title()
	monster_hunt_status.text = monster_hunt.get_hud_status(
		ship.get_ammunition_units()
	)
	monster_hunt_result.text = monster_hunt.get_hud_result()
	monster_hunt_view.visible = (
		bool(monster_state["visual_on_screen"])
		and _player_aboard_ship
		and not _player_on_target_deck
		and not waypoint_display.chart_visible
		and not _cargo_choice_open
		and not _storage_view_open
		and not _construction_view_open
		and not _trade_view_open
		and not _journal_view_open
		and not _defeat_recovery.is_result_open()
	)


func _update_weather_area() -> void:
	weather_area.update_state(
		ship.global_position,
		_player_aboard_ship and not _player_on_target_deck,
	)
	ship.set_weather_turn_multiplier(
		weather_area.get_turn_multiplier(),
		weather_area.is_ship_inside_active_storm(),
	)
	if weather_area.needs_ship_response_record():
		weather_area.record_ship_response(
			ship.get_base_turn_speed(),
			ship.get_turn_speed(),
			_get_weather_context(),
		)
	if weather_area.needs_turn_input_response_record(
		ship.get_turn_input_frame_count()
	):
		weather_area.record_turn_input_response(
			ship.get_last_turn_response_evidence()
		)


func _get_weather_context() -> Dictionary:
	var damage_state: Dictionary = ship.get_damage_playtest_state()
	return {
		"ship_position": ship.global_position,
		"ship_rotation": ship.rotation,
		"ship_speed": ship.current_speed,
		"ship_top_speed": ship.get_top_speed(),
		"cargo_lots": ship.get_cargo_lots(),
		"money": money,
		"hull_current": damage_state["hull_current"],
		"hull_max": damage_state["hull_max"],
	}


func _is_weather_toggle_available() -> bool:
	return (
		_player_aboard_ship
		and ship.captain_aboard
		and ship.controls_enabled
		and not ship.is_docked
		and not _player_on_target_deck
		and not _defeat_recovery.is_result_open()
		and not _defeat_recovery.is_release_guard_pending()
		and not waypoint_display.chart_visible
		and not _chart_release_pending
		and not _cargo_choice_open
		and not _cargo_choice_release_pending
		and not _storage_view_open
		and not _storage_release_pending
		and not _construction_view_open
		and not _construction_release_pending
		and not _trade_view_open
		and not _trade_release_pending
		and not _journal_view_open
		and not _journal_release_pending
		and not _target_inspection_view_open
		and not ship.navigation_input_blocked
		and not ship.navigation_release_pending
	)


func _handle_weather_toggle_input(key_event: InputEventKey) -> void:
	if not key_event.pressed:
		_weather_toggle_held = false
		return
	var weather_context := _get_weather_context()
	if key_event.echo or _weather_toggle_held:
		weather_area.record_held_toggle(weather_context)
		return
	_weather_toggle_held = true
	weather_area.try_toggle_weather(
		_is_weather_toggle_available(),
		weather_context,
	)
	_update_weather_area()
	_update_fishing_area()
	_update_weather_view()
	_update_interaction_prompt()


func _update_weather_view() -> void:
	weather_title.text = weather_area.get_hud_title()
	weather_status.text = weather_area.get_hud_status()
	weather_view.visible = (
		_player_aboard_ship
		and not _player_on_target_deck
		and not _defeat_recovery.is_result_open()
		and not waypoint_display.chart_visible
		and not _cargo_choice_open
		and not _storage_view_open
		and not _construction_view_open
		and not _trade_view_open
		and not _journal_view_open
	)


func _update_pirate_hunter(delta: float) -> void:
	var player_ship_operating: bool = (
		_player_aboard_ship
		and not _player_on_target_deck
		and not ship.is_docked
		and not ship.navigation_input_blocked
		and not ship.navigation_release_pending
	)
	var modal_pause_active: bool = (
		_defeat_recovery.is_result_open()
		or _defeat_recovery.is_release_guard_pending()
		or waypoint_display.chart_visible
		or _chart_release_pending
		or _cargo_choice_open
		or _cargo_choice_release_pending
		or _storage_view_open
		or _storage_release_pending
		or _construction_view_open
		or _construction_release_pending
		or _trade_view_open
		or _trade_release_pending
		or _journal_view_open
		or _journal_release_pending
	)
	var attack_requested := pirate_hunter.update_encounter(
		delta,
		_world_heat.get_current_heat(),
		ship.global_position,
		_player_aboard_ship,
		player_ship_operating,
		modal_pause_active,
		_pirate_hunter_sea_bounds,
	)
	if attack_requested:
		var heat_before := _world_heat.get_current_heat()
		var target_conditions_before := _get_target_condition_snapshots()
		var crew_before: Dictionary = ship.get_crew_condition_playtest_state()
		var evidence: Dictionary = ship.apply_pirate_hunter_broadside()
		var defeat_triggered := _defeat_recovery.should_begin_from_naval_damage(
			evidence
		)
		var heat_after := _world_heat.get_current_heat()
		var target_conditions_after := _get_target_condition_snapshots()
		var crew_after: Dictionary = ship.get_crew_condition_playtest_state()
		evidence.merge({
			"world_heat_before": heat_before,
			"world_heat_after": heat_after,
			"world_heat_unchanged": heat_before == heat_after,
			"target_conditions_before": target_conditions_before,
			"target_conditions_after": target_conditions_after,
			"target_conditions_unchanged": (
				target_conditions_before == target_conditions_after
			),
			"crew_condition_before_context": crew_before["condition"],
			"crew_condition_after_context": crew_after["condition"],
			"only_expected_combat_state_changed": (
				bool(evidence.get("unrelated_ship_resources_unchanged", false))
				and heat_before == heat_after
				and target_conditions_before == target_conditions_after
				and bool(evidence.get(
					"hull_changed_only_by_fixed_hunter_damage",
					false,
				))
			),
			"phase_33_defeat_triggered": defeat_triggered,
		}, true)
		_last_crew_combat_context_evidence = evidence.duplicate(true)
		if bool(evidence.get("crew_injury_applied", false)):
			_last_crew_injury_context_evidence = evidence.duplicate(true)
		pirate_hunter.record_attack_result(evidence)
		if defeat_triggered:
			_begin_ship_defeat(evidence)


func _begin_ship_defeat(damage_evidence: Dictionary) -> void:
	if not _defeat_recovery.should_begin_from_naval_damage(damage_evidence):
		return
	var cove_storage_before: Array[String] = cove_storage.get_cargo_lots()
	var cove_storage_slots_before: Array[String] = cove_storage.get_storage_slots()
	var money_before := money
	var hunter_resolution: Dictionary = pirate_hunter.resolve_player_defeat(
		_world_heat.get_current_heat()
	)
	var return_evidence: Dictionary = ship.return_to_cove_after_defeat(
		DefeatRecoveryState.FIXED_CARGO_LOT_LOSS,
		DefeatRecoveryState.FIXED_AMMUNITION_UNIT_LOSS,
		DefeatRecoveryState.MINIMUM_RETAINED_CARGO_LOTS,
	)
	var cove_departure_observed_before_defeat := (
		_cove_module_departure_release_observed
	)
	_cove_module_departure_release_observed = false
	return_evidence.merge({
		"main_cove_departure_observed_before_defeat": (
			cove_departure_observed_before_defeat
		),
		"main_cove_departure_observed_after_defeat": (
			_cove_module_departure_release_observed
		),
		"all_pending_module_departure_state_cleared": (
			not ship.is_module_departure_ready()
			and not ship.is_module_departure_exit_pending()
			and not _cove_module_departure_release_observed
		),
	}, true)
	var cove_storage_after: Array[String] = cove_storage.get_cargo_lots()
	var cove_storage_slots_after: Array[String] = cove_storage.get_storage_slots()
	var defeat_evidence: Dictionary = _defeat_recovery.begin_defeat(
		damage_evidence,
		return_evidence,
		hunter_resolution,
		cove_storage_before,
		cove_storage_after,
		cove_storage_slots_before,
		cove_storage_slots_after,
		money_before,
		money,
	)
	if defeat_evidence.is_empty():
		return
	if _target_inspection_view_open:
		_close_target_inspection("PLAYER_DEFEAT")
	_player_on_target_deck = false
	_player_shore_id = ""
	_player_near_ship_return = false
	_player_aboard_ship = true
	ship.set_captain_aboard(true)
	ship.set_navigation_input_blocked(true)
	player.enter_ship(ship_standing_position.global_position)
	player.movement_enabled = false
	_available_dock_id = ""
	_last_leave_allowed = false
	_last_ship_docked = true
	_clear_all_defeat_held_action_state("DEFEAT_START")
	controls_help.text = DEFEAT_RESULT_CONTROLS_TEXT
	interaction_prompt.hide()
	_update_cargo_view()
	_update_money_view()
	_update_hull_view()
	_update_crew_view()
	_update_repair_view()
	_update_pirate_hunter_view()
	_update_defeat_result_view()


func _update_target_inspection() -> void:
	var inspection_context_available: bool = (
		not _player_on_target_deck
		and not _defeat_recovery.is_result_open()
		and not _defeat_recovery.is_release_guard_pending()
		and _player_aboard_ship
		and not ship.is_docked
		and not waypoint_display.chart_visible
		and not _chart_release_pending
		and not _cargo_choice_open
		and not _cargo_choice_release_pending
		and not _storage_view_open
		and not _storage_release_pending
		and not _construction_view_open
		and not _construction_release_pending
		and not _trade_view_open
		and not _trade_release_pending
		and not _journal_view_open
		and not _journal_release_pending
	)
	var previous_near_target: InspectableTargetShipState = (
		_near_inspection_target
	)
	var previous_near_boarding_target: InspectableTargetShipState = (
		_near_boarding_target
	)
	_near_inspection_target = null
	_near_boarding_target = null
	var nearest_distance: float = INF
	var nearest_boarding_distance: float = INF
	for target in inspection_targets:
		target.update_player_ship_state(
			ship.global_position,
			_player_aboard_ship and not ship.is_docked,
			inspection_context_available,
		)
		if (
			target.is_boarding_prompt_available()
			and target.get_distance_to_player_ship() < nearest_boarding_distance
		):
			_near_boarding_target = target
			nearest_boarding_distance = target.get_distance_to_player_ship()
		if (
			target.is_inspection_available()
			and target.get_distance_to_player_ship() < nearest_distance
		):
			_near_inspection_target = target
			nearest_distance = target.get_distance_to_player_ship()

	if _target_inspection_view_open:
		if _active_inspection_target == null:
			_close_target_inspection("TARGET_UNAVAILABLE")
		elif (
			_active_inspection_target.get_distance_to_player_ship()
			> InspectableTargetShipState.INSPECTION_RANGE
		):
			_close_target_inspection("SAILED_OUT_OF_RANGE")
		elif not _active_inspection_target.is_inspection_available():
			_close_target_inspection("INSPECTION_CONTEXT_CLOSED")
		else:
			_update_target_inspection_view()

	if (
		previous_near_target != _near_inspection_target
		or previous_near_boarding_target != _near_boarding_target
	):
		_update_interaction_prompt()


func _can_inspect_nearby_target() -> bool:
	return (
		_near_inspection_target != null
		and _near_boarding_target == null
		and not _target_inspection_view_open
		and _player_aboard_ship
		and not ship.is_docked
		and not waypoint_display.chart_visible
		and not _chart_release_pending
		and not _cargo_choice_open
		and not _cargo_choice_release_pending
		and not _trade_view_open
		and not _trade_release_pending
		and not _journal_view_open
		and not _journal_release_pending
	)


func _can_board_nearby_target() -> bool:
	return (
		_near_boarding_target != null
		and _near_boarding_target.is_boarding_prompt_available()
		and not _player_on_target_deck
		and _player_aboard_ship
		and not ship.is_docked
		and not waypoint_display.chart_visible
		and not _chart_release_pending
		and not _cargo_choice_open
		and not _cargo_choice_release_pending
		and not _storage_view_open
		and not _storage_release_pending
		and not _construction_view_open
		and not _construction_release_pending
		and not _trade_view_open
		and not _trade_release_pending
		and not _journal_view_open
		and not _journal_release_pending
		and not _target_inspection_view_open
	)


func _board_nearby_target() -> void:
	_boarding_attempt_count += 1
	if not _can_board_nearby_target():
		_last_boarding_attempt_evidence = {
			"success": false,
			"result": "BOARDING UNAVAILABLE",
			"board_count": _boarding_success_count,
		}
		return
	var target: InspectableTargetShipState = _near_boarding_target
	var target_condition_before: Dictionary = target.get_condition_state()
	_boarding_conservation_before = _capture_boarding_conservation_snapshot(target)
	var target_begin_evidence: Dictionary = target.begin_boarding()
	if not bool(target_begin_evidence.get("success", false)):
		_last_boarding_attempt_evidence = target_begin_evidence.duplicate(true)
		return
	_active_boarding_target = target
	_last_boarded_target_id = target.target_id
	_boarding_success_count += 1
	_player_on_target_deck = true
	_player_aboard_ship = false
	_player_shore_id = ""
	_player_near_ship_return = false
	_player_near_boarding_return = false
	_boarding_walk_distance = 0.0
	_boarding_furthest_distance = 0.0
	_boarding_walked_across_deck = false
	_boarding_deck_bounds_held = true
	_prize_opened_for_current_boarding = false
	_prize_returned_to_player_ship = false
	_prize_pressed_keys.clear()
	_prize_held_close_count = 0
	_prize_close_evidence = {}
	_prize_persistence_evidence = {}
	_prize_trigger_fight_outcome = "NONE"
	_prize_target_resolution_evidence = {}
	ship.set_navigation_input_blocked(true)
	ship.set_captain_aboard(false)
	_broadside_pressed_keys.clear()
	_attack_choice_pressed_keys.clear()
	target_boarding_deck.activate(
		target.target_id,
		target.display_name,
		int(target_condition_before["hull"]["hull_current"]),
		int(target_condition_before["sails"]["sail_current"]),
	)
	var deck_entry: Vector2 = target_boarding_deck.get_entry_position()
	player.go_ashore(
		deck_entry,
		"target_deck",
		target_boarding_deck.get_walk_region(),
	)
	_boarding_walk_start_position = player.global_position
	_boarding_previous_player_position = player.global_position
	_boarding_deck_bounds_held = (
		_boarding_deck_bounds_held
		and target_boarding_deck.is_player_inside_bounds(player.global_position)
	)
	controls_help.text = BOARDING_DECK_CONTROLS_TEXT
	interaction_prompt.hide()
	_last_boarding_attempt_evidence = {
		"success": true,
		"result": "BOARDED %s" % target.display_name,
		"target_id": target.target_id,
		"target_name": target.display_name,
		"target_condition_before": target_condition_before.duplicate(true),
		"target_hull_above_zero": (
			int(target_condition_before["hull"]["hull_current"]) > 0
		),
		"target_begin_evidence": target_begin_evidence.duplicate(true),
		"fresh_press_required": true,
		"deck_entry_position": deck_entry,
		"deck_walk_rect": target_boarding_deck.get_walk_rect(),
		"ship_position": ship.global_position,
		"ship_controls_blocked": ship.navigation_input_blocked,
	}
	_successful_boarding_evidence = (
		_last_boarding_attempt_evidence.duplicate(true)
	)
	_update_target_inspection_view()
	_update_broadside_view()
	_update_ammunition_view()
	_update_target_combat_view()
	_update_interaction_prompt()


func _update_boarding_deck_state(delta: float = 0.0) -> void:
	if not _player_on_target_deck:
		return
	target_boarding_deck.update_combat(delta, player.global_position)
	var combat_state: Dictionary = target_boarding_deck.get_playtest_state(
		player.global_position
	)
	if bool(combat_state["fight_ended"]) and not _prize_opened_for_current_boarding:
		_open_prize_screen_after_victory()
	var movement_distance := _boarding_previous_player_position.distance_to(
		player.global_position
	)
	if movement_distance > 0.0:
		_boarding_walk_distance += movement_distance
		_boarding_furthest_distance = maxf(
			_boarding_furthest_distance,
			_boarding_walk_start_position.distance_to(player.global_position),
		)
		_boarding_walked_across_deck = (
			_boarding_walked_across_deck
			or _boarding_furthest_distance
				>= TargetBoardingDeckState.WALK_ACROSS_DISTANCE
		)
	_boarding_previous_player_position = player.global_position
	_boarding_deck_bounds_held = (
		_boarding_deck_bounds_held
		and target_boarding_deck.is_player_inside_bounds(player.global_position)
	)
	var near_return := target_boarding_deck.is_player_near_return(
		player.global_position
	)
	if near_return != _player_near_boarding_return:
		_player_near_boarding_return = near_return
		_update_interaction_prompt()


func _open_prize_screen_after_victory() -> void:
	if _active_boarding_target == null:
		return
	var damage_state: Dictionary = ship.get_damage_playtest_state()
	var combat_state: Dictionary = target_boarding_deck.get_playtest_state(
		player.global_position
	)
	_prize_returned_to_player_ship = false
	_prize_trigger_fight_outcome = String(combat_state["fight_outcome"])
	_prize_pressed_keys.clear()
	_prize_close_evidence = {}
	_prize_persistence_evidence = {}
	var open_evidence: Dictionary = _prize_actions.open_for_victory(
		_active_boarding_target.target_id,
		_active_boarding_target.display_name,
		int(damage_state["hull_current"]),
		int(damage_state["hull_max"]),
		ship.get_cargo_lots(),
		_trade_journal.get_entry_snapshot(),
	)
	if not bool(open_evidence.get("success", false)):
		return
	_prize_target_resolution_evidence = (
		_active_boarding_target.resolve_boarding_victory()
	)
	if not bool(_prize_target_resolution_evidence.get("success", false)):
		_prize_actions.close_screen()
		return
	_prize_opened_for_current_boarding = true
	player.movement_enabled = false
	interaction_prompt.hide()
	controls_help.text = PRIZE_CONTROLS_TEXT
	_update_prize_view()


func _return_from_target_deck() -> void:
	if (
		not _player_on_target_deck
		or not _player_near_boarding_return
		or _active_boarding_target == null
		or _prize_actions.screen_open
	):
		return
	var target: InspectableTargetShipState = _active_boarding_target
	var target_finish_evidence: Dictionary = target.finish_boarding()
	_boarding_return_count += 1
	_player_on_target_deck = false
	_player_near_boarding_return = false
	target_boarding_deck.deactivate()
	_player_aboard_ship = true
	_player_shore_id = ""
	_player_near_ship_return = false
	player.enter_ship(ship_standing_position.global_position)
	ship.set_captain_aboard(true)
	ship.set_navigation_input_blocked(false, true)
	_prize_returned_to_player_ship = true
	_boarding_conservation_after = _capture_boarding_conservation_snapshot(target)
	_boarding_state_conservation_holds = _boarding_return_state_holds(
		_boarding_conservation_before,
		_boarding_conservation_after,
	)
	_prize_persistence_evidence = _prize_actions.get_playtest_state(
		ship.get_cargo_lots(),
		_trade_journal.get_entry_snapshot(),
		_prize_returned_to_player_ship,
	)
	_last_boarding_return_evidence = {
		"success": true,
		"result": "RETURNED TO PLAYER SHIP",
		"target_id": target.target_id,
		"target_name": target.display_name,
		"target_finish_evidence": target_finish_evidence.duplicate(true),
		"walk_distance": _boarding_walk_distance,
		"furthest_distance_from_entry": _boarding_furthest_distance,
		"walked_across_deck": _boarding_walked_across_deck,
		"return_point_used": true,
		"captain_aboard": ship.captain_aboard,
		"player_aboard_ship": _player_aboard_ship,
		"player_control_mode": player.get_playtest_state()["control_mode"],
		"ship_controls_restore_requested": true,
		"state_before": _boarding_conservation_before.duplicate(true),
		"state_after": _boarding_conservation_after.duplicate(true),
		"state_conservation_holds": _boarding_state_conservation_holds,
		"prize_persistence": _prize_persistence_evidence.duplicate(true),
		"prize_persistence_holds": bool(
			_prize_persistence_evidence["persistence_after_return_holds"]
		),
		"fresh_press_required": true,
	}
	_active_boarding_target = null
	controls_help.text = RELEASE_CONTROLS_TEXT
	_update_target_inspection()
	_update_broadside_view()
	_update_ammunition_view()
	_update_target_combat_view()
	_update_interaction_prompt()


func _capture_boarding_conservation_snapshot(
	target: InspectableTargetShipState,
) -> Dictionary:
	var condition: Dictionary = target.get_condition_state()
	var heat_state: Dictionary = _world_heat.get_playtest_state()
	return {
		"money": money,
		"cargo_lots": ship.get_cargo_lots(),
		"ammunition_units": ship.get_ammunition_units(),
		"player_ship_hull": ship.get_damage_playtest_state()["hull_current"],
		"completed_voyages": completed_voyages,
		"target_id": target.target_id,
		"target_hull": condition["hull"]["hull_current"],
		"target_sails": condition["sails"]["sail_current"],
		"target_disabled": condition["hull"]["disabled"],
		"trade_bought_lot_count": _trade_bought_lot_count,
		"trade_sold_lot_count": _trade_sold_lot_count,
		"port_trade_mark": port_trader.get_mark_state(completed_voyages),
		"cove_trade_mark": cove_buyer.get_mark_state(completed_voyages),
		"trade_journal_entry": _trade_journal.get_entry_snapshot(),
		"trade_journal_prize_update_count": int(
			_trade_journal.get_playtest_state(completed_voyages)[
				"prize_trade_records_update_count"
			]
		),
		"world_heat": heat_state["current_heat"],
		"heat_change_count": heat_state["first_peaceful_hit_count"],
	}


func _boarding_return_state_holds(
	state_before: Dictionary,
	state_after: Dictionary,
) -> bool:
	var expected_cargo: Array = (state_before["cargo_lots"] as Array).duplicate()
	expected_cargo.append_array(_prize_actions.awarded_cargo_lots)
	var journal_holds: bool = (
		(
			int(state_after["trade_journal_prize_update_count"])
			== int(state_before["trade_journal_prize_update_count"]) + 1
			and not (state_after["trade_journal_entry"] as Dictionary).is_empty()
		)
		if _prize_actions.trade_records_taken
		else (
			state_after["trade_journal_entry"] == state_before["trade_journal_entry"]
			and state_after["trade_journal_prize_update_count"]
				== state_before["trade_journal_prize_update_count"]
		)
	)
	return (
		state_after["money"] == state_before["money"]
		and state_after["cargo_lots"] == expected_cargo
		and state_after["ammunition_units"] == state_before["ammunition_units"]
		and state_after["player_ship_hull"] == state_before["player_ship_hull"]
		and state_after["completed_voyages"] == state_before["completed_voyages"]
		and state_after["target_id"] == state_before["target_id"]
		and state_after["target_hull"] == state_before["target_hull"]
		and state_after["target_sails"] == state_before["target_sails"]
		and state_after["target_disabled"] == state_before["target_disabled"]
		and state_after["trade_bought_lot_count"]
			== state_before["trade_bought_lot_count"]
		and state_after["trade_sold_lot_count"]
			== state_before["trade_sold_lot_count"]
		and state_after["port_trade_mark"] == state_before["port_trade_mark"]
		and state_after["cove_trade_mark"] == state_before["cove_trade_mark"]
		and state_after["world_heat"] == state_before["world_heat"]
		and state_after["heat_change_count"]
			== state_before["heat_change_count"]
		and journal_holds
	)


func _open_target_inspection() -> void:
	if not _can_inspect_nearby_target():
		return
	_active_inspection_target = _near_inspection_target
	_target_inspection_view_open = true
	_target_inspection_open_count += 1
	_last_inspection_close_reason = "OPEN"
	var target_id: String = _active_inspection_target.target_id
	if not _inspected_target_ids.has(target_id):
		_inspected_target_ids.append(target_id)
	_last_inspection_estimate = _get_target_inspection_estimate(
		_active_inspection_target
	)
	_last_inspection_heat_preview = (
		(_last_inspection_estimate["heat_preview"] as Dictionary).duplicate(true)
	)
	interaction_prompt.hide()
	_update_target_inspection_view()


func _close_target_inspection(reason: String) -> void:
	if not _target_inspection_view_open:
		return
	if _active_inspection_target != null:
		_last_auto_closed_target_id = _active_inspection_target.target_id
		_last_auto_close_distance = (
			_active_inspection_target.get_distance_to_player_ship()
		)
	_target_inspection_view_open = false
	_last_inspection_close_reason = reason
	if reason == "SAILED_OUT_OF_RANGE":
		_target_inspection_auto_close_count += 1
	_active_inspection_target = null
	target_inspection_view.hide()
	_update_interaction_prompt()


func _update_target_inspection_view() -> void:
	if not _target_inspection_view_open or _active_inspection_target == null:
		target_inspection_view.hide()
		return
	var estimate: Dictionary = _get_target_inspection_estimate(
		_active_inspection_target
	)
	_last_inspection_estimate = estimate.duplicate(true)
	_last_inspection_heat_preview = (
		(estimate["heat_preview"] as Dictionary).duplicate(true)
	)
	var peaceful_text := "YES" if bool(estimate["peaceful_estimate"]) else "NO"
	var heat_preview: Dictionary = estimate["heat_preview"]
	var heat_cost := int(heat_preview["estimated_heat_increase"])
	var heat_text := "+%d" % heat_cost
	var heat_rule_text := "NOT PEACEFUL"
	if bool(estimate["peaceful_estimate"]):
		heat_rule_text = (
			"FIRST HIT ALREADY COUNTED"
			if bool(heat_preview["first_hit_already_recorded"])
			else "FIRST SUCCESSFUL HIT"
		)
	var choice_text := "%s RISK · %s" % [
		estimate["threat_estimate"],
		(
			"PEACEFUL · HEAT EXPECTED"
			if bool(estimate["peaceful_estimate"])
			else "NOT PEACEFUL · NO HEAT EXPECTED"
		),
	]
	inspection_title.text = "TARGET INSPECTION · ALL VALUES ESTIMATED"
	inspection_target_name.text = "TARGET ESTIMATE · %s" % (
		estimate["display_name"]
	)
	inspection_details.text = (
		"ALL VALUES BELOW ARE ESTIMATES\n"
		+ "OWNER ESTIMATE · %s\n" % estimate["owner_estimate"]
		+ "FLAG ESTIMATE · %s\n" % estimate["flag_estimate"]
		+ "SHIP CLASS ESTIMATE · %s\n" % estimate["ship_class_estimate"]
		+ "LIKELY SPEED ESTIMATE · %s\n" % estimate["likely_speed_estimate"]
		+ "GENERAL CARGO TYPE ESTIMATE · %s\n" % (
			estimate["general_cargo_type_estimate"]
		)
		+ "THREAT ESTIMATE · %s\n" % estimate["threat_estimate"]
		+ "PEACEFUL ESTIMATE · %s\n" % peaceful_text
		+ "HEAT COST ESTIMATE · %s · %s\n" % [
			heat_text,
			heat_rule_text,
		]
		+ "WORLD HEAT PREVIEW · %d -> %d (%s) · NOT APPLIED\n" % [
			heat_preview["heat_before"],
			heat_preview["heat_after"],
			heat_text,
		]
		+ "ATTACK CHOICE ESTIMATE · %s" % choice_text
	)
	inspection_controls.text = (
		"[H] HULL · [K] SAILS · [Q] LEFT · [F] RIGHT · SAIL OUT TO CLOSE"
	)
	_last_inspection_view_text = "%s\n%s\n%s\n%s" % [
		inspection_title.text,
		inspection_target_name.text,
		inspection_details.text,
		inspection_controls.text,
	]
	target_inspection_view.show()


func _get_target_inspection_estimate(
	target: InspectableTargetShipState,
) -> Dictionary:
	var estimate: Dictionary = target.get_estimate_state().duplicate(true)
	var heat_preview: Dictionary = _world_heat.get_attack_preview(
		target.target_id,
		bool(estimate["peaceful_estimate"]),
		int(estimate["estimated_heat_cost"]),
	)
	estimate["heat_preview"] = heat_preview.duplicate(true)
	estimate["estimated_heat_increase"] = heat_preview[
		"estimated_heat_increase"
	]
	estimate["world_heat_before_attack"] = heat_preview["heat_before"]
	estimate["world_heat_after_attack"] = heat_preview["heat_after"]
	return estimate


func _attempt_broadside_attack(side: String) -> void:
	var world_heat_before := _world_heat.get_current_heat()
	var target_hulls_before: Dictionary = _get_target_hull_snapshots()
	var target_conditions_before: Dictionary = _get_target_condition_snapshots()
	var target_values_before: Dictionary = _get_target_condition_values()
	var evidence: Dictionary = ship.attempt_broadside(side)
	evidence["attack_choice"] = _selected_attack_choice
	evidence["target_hulls_before"] = target_hulls_before.duplicate(true)
	evidence["target_conditions_before"] = (
		target_conditions_before.duplicate(true)
	)
	evidence["target_condition_values_before"] = (
		target_values_before.duplicate(true)
	)
	evidence["selected_side_world_corners"] = (
		ship.get_broadside_area_world_corners(side)
	)
	evidence["left_side_world_corners"] = (
		ship.get_broadside_area_world_corners("LEFT")
	)
	evidence["right_side_world_corners"] = (
		ship.get_broadside_area_world_corners("RIGHT")
	)
	if not bool(evidence["shot_fired"]):
		var rejected_hulls_after: Dictionary = _get_target_hull_snapshots()
		var rejected_conditions_after: Dictionary = (
			_get_target_condition_snapshots()
		)
		var rejected_values_after: Dictionary = _get_target_condition_values()
		evidence["target_hulls_after"] = rejected_hulls_after.duplicate(true)
		evidence["target_conditions_after"] = (
			rejected_conditions_after.duplicate(true)
		)
		evidence["target_condition_values_after"] = (
			rejected_values_after.duplicate(true)
		)
		evidence["target_hulls_unchanged"] = (
			target_hulls_before == rejected_hulls_after
		)
		evidence["target_hit"] = false
		evidence["target_hull_delta"] = 0
		evidence["target_sail_delta"] = 0
		evidence["target_speed_delta"] = 0.0
		evidence["no_shot_no_target_damage"] = (
			target_hulls_before == rejected_hulls_after
		)
		evidence["no_shot_no_condition_change"] = (
			target_values_before == rejected_values_after
		)
		evidence["world_heat_before"] = world_heat_before
		evidence["world_heat_after"] = _world_heat.get_current_heat()
		evidence["world_heat_delta"] = 0
		evidence["no_shot_no_heat_change"] = true
		_last_broadside_attempt_evidence = ship.record_broadside_result(
			evidence
		)
		_last_broadside_result = String(
			_last_broadside_attempt_evidence["result"]
		)
		if String(evidence["rejection_reason"]) == "RELOADING":
			_reload_rejected_broadside_evidence = (
				_last_broadside_attempt_evidence.duplicate(true)
			)
		elif String(evidence["rejection_reason"]) == "NO_AMMUNITION":
			_zero_ammunition_rejected_broadside_evidence = (
				_last_broadside_attempt_evidence.duplicate(true)
			)
		elif String(evidence["rejection_reason"]) == "FIRING_AREAS_INACTIVE":
			_inactive_rejected_broadside_evidence = (
				_last_broadside_attempt_evidence.duplicate(true)
			)
		_update_cargo_view()
		_update_broadside_view()
		_update_ammunition_view()
		_update_target_combat_view()
		_update_heat_view()
		return

	var heat_evidence: Dictionary = {
		"success": false,
		"result": "NO SUCCESSFUL TARGET HIT · HEAT UNCHANGED",
		"successful_target_hit": false,
		"heat_before": world_heat_before,
		"heat_after": world_heat_before,
		"heat_delta": 0,
	}
	var target: InspectableTargetShipState = _get_broadside_target(
		side,
		_selected_attack_choice,
	)
	if target == null:
		evidence.merge({
			"target_hit": false,
			"target_id": "",
			"target_name": "NO TARGET",
			"target_in_selected_side_area": false,
			"target_hull_before": -1,
			"target_hull_after": -1,
			"target_hull_max": InspectableTargetShipState.HULL_MAX,
			"target_hull_delta": 0,
			"target_sail_before": -1,
			"target_sail_after": -1,
			"target_sail_max": InspectableTargetShipState.SAIL_MAX,
			"target_sail_delta": 0,
			"target_speed_before": -1.0,
			"target_speed_after": -1.0,
			"target_speed_delta": 0.0,
			"target_disabled": false,
			"hit_feedback_started": false,
		})
	else:
		var target_hull_before: Dictionary = target.get_hull_state()
		var target_sail_before: Dictionary = target.get_sail_state()
		var target_local_position: Vector2 = ship.to_local(
			target.global_position
		)
		var selected_damage: int = (
			int(evidence["sail_damage"])
			if _selected_attack_choice
				== InspectableTargetShipState.ATTACK_SAILS
			else int(evidence["hull_damage"])
		)
		var hit_evidence: Dictionary = target.apply_broadside_damage(
			_selected_attack_choice,
			selected_damage,
			side,
		)
		if bool(hit_evidence["success"]):
			heat_evidence = _world_heat.record_successful_hit(
				target.target_id,
				target.peaceful,
				target.estimated_heat_cost,
			)
		_last_attacked_target_id = target.target_id
		evidence.merge({
			"target_hit": bool(hit_evidence["success"]),
			"target_id": target.target_id,
			"target_name": target.display_name,
			"target_world_position": target.global_position,
			"target_local_position": target_local_position,
			"target_in_selected_side_area": ship.is_world_point_in_broadside(
				side,
				target.global_position,
			),
			"target_hull_before": target_hull_before["hull_current"],
			"target_hull_after": hit_evidence["hull_after"],
			"target_hull_max": hit_evidence["hull_max"],
			"target_hull_delta": hit_evidence["hull_delta"],
			"target_sail_before": target_sail_before["sail_current"],
			"target_sail_after": hit_evidence["sail_after"],
			"target_sail_max": hit_evidence["sail_max"],
			"target_sail_delta": hit_evidence["sail_delta"],
			"target_speed_before": hit_evidence["speed_before"],
			"target_speed_after": hit_evidence["speed_after"],
			"target_speed_delta": hit_evidence["speed_delta"],
			"target_speed_step_before": hit_evidence["speed_step_before"],
			"target_speed_step_after": hit_evidence["speed_step_after"],
			"target_disabled": hit_evidence["disabled"],
			"hit_feedback_started": hit_evidence.get(
				"hit_feedback_started",
				false,
			),
			"target_hit_evidence": hit_evidence.duplicate(true),
		})

	var target_hulls_after: Dictionary = _get_target_hull_snapshots()
	var target_conditions_after: Dictionary = _get_target_condition_snapshots()
	var target_values_after: Dictionary = _get_target_condition_values()
	var changed_target_ids: Array[String] = []
	for target_id in target_hulls_before:
		if target_hulls_before[target_id] != target_hulls_after[target_id]:
			changed_target_ids.append(String(target_id))
	evidence["target_hulls_after"] = target_hulls_after.duplicate(true)
	evidence["target_conditions_after"] = target_conditions_after.duplicate(true)
	evidence["target_condition_values_after"] = target_values_after.duplicate(true)
	evidence["heat_evidence"] = heat_evidence.duplicate(true)
	evidence["world_heat_before"] = world_heat_before
	evidence["world_heat_after"] = _world_heat.get_current_heat()
	evidence["world_heat_delta"] = (
		_world_heat.get_current_heat() - world_heat_before
	)
	evidence["heat_changes_only_on_successful_peaceful_hit"] = (
		int(evidence["world_heat_delta"]) == 0
		or (
			bool(evidence["target_hit"])
			and bool(heat_evidence.get("peaceful", false))
			and bool(heat_evidence.get("first_successful_hit", false))
		)
	)
	evidence["changed_target_ids"] = changed_target_ids.duplicate()
	evidence["only_selected_target_hull_changed"] = (
		(changed_target_ids.is_empty() and not bool(evidence["target_hit"]))
		or (
			changed_target_ids.size() == 1
			and changed_target_ids[0] == String(evidence["target_id"])
			and bool(evidence["target_in_selected_side_area"])
		)
	)
	evidence["target_damage_requires_selected_side_area"] = (
		not bool(evidence["target_hit"])
		or bool(evidence["target_in_selected_side_area"])
	)
	evidence["target_hull_damage_matches_fixed_amount"] = (
		not bool(evidence["target_hit"])
		or _selected_attack_choice
			!= InspectableTargetShipState.ATTACK_HULL
		or int(evidence["target_hull_delta"]) == -int(evidence["hull_damage"])
	)
	evidence["target_sail_damage_matches_fixed_amount"] = (
		not bool(evidence["target_hit"])
		or _selected_attack_choice
			!= InspectableTargetShipState.ATTACK_SAILS
		or int(evidence["target_sail_delta"]) == -int(evidence["sail_damage"])
	)
	evidence["selected_condition_only_changed"] = (
		not bool(evidence["target_hit"])
		or (
			_selected_attack_choice == InspectableTargetShipState.ATTACK_HULL
			and int(evidence["target_hull_delta"]) < 0
			and int(evidence["target_sail_delta"]) == 0
		)
		or (
			_selected_attack_choice == InspectableTargetShipState.ATTACK_SAILS
			and int(evidence["target_sail_delta"]) < 0
			and int(evidence["target_hull_delta"]) == 0
		)
	)
	_last_broadside_attempt_evidence = ship.record_broadside_result(evidence)
	_last_broadside_result = String(
		_last_broadside_attempt_evidence["result"]
	)
	if bool(evidence["target_hit"]) and bool(
		heat_evidence.get("peaceful", false)
	):
		if int(evidence["world_heat_delta"]) > 0:
			_last_broadside_result += " · HEAT +%d" % (
				evidence["world_heat_delta"]
			)
		else:
			_last_broadside_result += " · HEAT UNCHANGED · FIRST HIT COUNTED"
		_last_broadside_attempt_evidence["result"] = _last_broadside_result
	_successful_broadside_evidence = (
		_last_broadside_attempt_evidence.duplicate(true)
	)
	if (
		String(_last_broadside_attempt_evidence.get("target_id", ""))
			== pirate_hunter.target_id
		and bool(_last_broadside_attempt_evidence.get("shot_fired", false))
		and bool(_last_broadside_attempt_evidence.get("target_hit", false))
		and bool(_last_broadside_attempt_evidence.get(
			"target_disabled",
			false,
		))
		and bool(_last_broadside_attempt_evidence.get(
			"ammunition_consumed",
			false,
		))
	):
		_pirate_hunter_defeat_broadside_evidence = (
			_last_broadside_attempt_evidence.duplicate(true)
		)
	_update_cargo_view()
	_update_broadside_view()
	_update_ammunition_view()
	_update_target_combat_view()
	_update_heat_view()
	_update_target_inspection()
	_update_interaction_prompt()


func _get_broadside_target(
	side: String,
	attack_choice: String,
) -> InspectableTargetShipState:
	var nearest_target: InspectableTargetShipState = null
	var nearest_distance: float = INF
	for target in inspection_targets:
		if not target.can_receive_broadside_damage(attack_choice):
			continue
		if not ship.is_world_point_in_broadside(side, target.global_position):
			continue
		var distance: float = ship.global_position.distance_to(
			target.global_position
		)
		if distance < nearest_distance:
			nearest_target = target
			nearest_distance = distance
	return nearest_target


func _get_target_hull_snapshots() -> Dictionary:
	var snapshots: Dictionary = {}
	for target in inspection_targets:
		snapshots[target.target_id] = target.get_hull_state().duplicate(true)
	return snapshots


func _get_target_condition_snapshots() -> Dictionary:
	var snapshots: Dictionary = {}
	for target in inspection_targets:
		snapshots[target.target_id] = target.get_condition_state().duplicate(true)
	return snapshots


func _get_target_condition_values() -> Dictionary:
	var snapshots: Dictionary = {}
	for target in inspection_targets:
		var condition: Dictionary = target.get_condition_state()
		snapshots[target.target_id] = {
			"hull_current": condition["hull"]["hull_current"],
			"sail_current": condition["sails"]["sail_current"],
			"current_speed": condition["sails"]["current_speed"],
			"disabled": condition["hull"]["disabled"],
		}
	return snapshots


func _update_broadside_view() -> void:
	var broadside_state: Dictionary = ship.get_broadside_playtest_state()
	if not bool(broadside_state["reload_ready"]):
		broadside_title.text = "BROADSIDE · RELOADING %.1f" % (
			broadside_state["reload_remaining"]
		)
	elif int(broadside_state["ammunition_units"]) <= 0:
		broadside_title.text = "BROADSIDE · NO AMMUNITION"
	else:
		broadside_title.text = "BROADSIDE · READY"
	if bool(broadside_state["firing_areas_active"]):
		broadside_areas.text = (
			"TARGET %s · [Q] LEFT · [F] RIGHT" % _selected_attack_choice
		)
	else:
		broadside_areas.text = "FIRING AREAS INACTIVE WHILE DOCKED OR ASHORE"
	broadside_result.text = _last_broadside_result
	broadside_view.visible = _player_aboard_ship


func _update_ammunition_view() -> void:
	var ammunition_state: Dictionary = ship.get_ammunition_playtest_state()
	var ammunition_units: int = int(ammunition_state["ammunition_units"])
	ammunition_title.text = "AMMUNITION · %d" % ammunition_units
	if ammunition_units == 0:
		ammunition_status.text = "NO AMMUNITION · BROADSIDE / HARPOON BLOCKED"
	elif ammunition_units == 2:
		ammunition_status.text = "LOW AMMUNITION"
	else:
		ammunition_status.text = "AMMUNITION READY"
	ammunition_cargo.text = "LOADED CARGO LOTS · %d · 1 SLOT EACH" % (
		ammunition_state["loaded_lot_count"]
	)
	ammunition_view.visible = _player_aboard_ship and not ship.is_docked


func _update_target_combat_view() -> void:
	var target: InspectableTargetShipState = _get_target_combat_display_target()
	if target == null:
		target_combat_title.text = "TARGET · NO VISIBLE SHIP"
		attack_choices.text = _get_attack_choices_text()
		target_hull_value.text = "HULL · -- / --"
		target_hull_meter.value = 0.0
		target_sail_value.text = "SAILS · -- / --"
		target_sail_meter.value = 0.0
		target_speed.text = "SPEED · -- · STEP -- · PLAYER TOP %.0f" % (
			ship.get_top_speed()
		)
		target_route.text = "AUTHORED ROUTE · NO VISIBLE TARGET"
		catch_status.text = "CHASE · FIND A TARGET"
		target_combat_view.visible = _player_aboard_ship and not ship.is_docked
		return

	var hull_state: Dictionary = target.get_hull_state()
	var sail_state: Dictionary = target.get_sail_state()
	target_combat_title.text = "TARGET · %s" % target.display_name
	attack_choices.text = _get_attack_choices_text()
	target_hull_value.text = "HULL · %d / %d" % [
		hull_state["hull_current"],
		hull_state["hull_max"],
	]
	target_hull_meter.max_value = float(hull_state["hull_max"])
	target_hull_meter.value = float(hull_state["hull_current"])
	target_sail_value.text = "SAILS · %d / %d" % [
		sail_state["sail_current"],
		sail_state["sail_max"],
	]
	target_sail_meter.max_value = float(sail_state["sail_max"])
	target_sail_meter.value = float(sail_state["sail_current"])
	target_speed.text = "SPEED · %.0f · STEP %d/4 · PLAYER TOP %.0f" % [
		sail_state["current_speed"],
		sail_state["speed_step"],
		ship.get_top_speed(),
	]
	target_route.text = "AUTHORED ROUTE · %s · DISTANCE %.0f" % [
		"MOVING" if bool(sail_state["moving"]) else "TURNING",
		target.get_distance_to_player_ship(),
	]
	var catch_evidence: Dictionary = sail_state["catch_evidence"]
	var boarding_state: Dictionary = target.get_boarding_state()
	if bool(boarding_state["prompt_available"]):
		catch_status.text = "BOARDING READY · ALONGSIDE · HULL %d > 0" % (
			hull_state["hull_current"]
		)
	elif bool(boarding_state["condition_ready"]):
		catch_status.text = "BOARDING READY · CLOSE TO %.0f · HULL %d > 0" % [
			boarding_state["alongside_range"],
			hull_state["hull_current"],
		]
	elif bool(sail_state["caught_after_sail_damage"]):
		catch_status.text = "CAUGHT · DISTANCE %.0f · HULL %d > 0" % [
			catch_evidence["catch_distance"],
			hull_state["hull_current"],
		]
	elif int(sail_state["sail_current"]) < int(sail_state["sail_max"]):
		catch_status.text = "CHASE · SAILS DAMAGED · CLOSE TO %.0f" % (
			InspectableTargetShipState.CATCH_RANGE
		)
	else:
		catch_status.text = "CHASE · TARGET FASTER · DAMAGE SAILS TO CATCH"
	target_combat_view.visible = _player_aboard_ship and not ship.is_docked


func _update_prize_view() -> void:
	var prize_state: Dictionary = _prize_actions.get_playtest_state(
		ship.get_cargo_lots(),
		_trade_journal.get_entry_snapshot(),
		_prize_returned_to_player_ship,
	)
	prize_title.text = "VICTORY PRIZES · %s" % (
		_prize_actions.active_target_name
	)
	prize_status.text = "PRIZE ACTIONS · %d / %d REMAIN" % [
		prize_state["actions_remaining"],
		prize_state["action_limit"],
	]
	var low_hull_text := (
		"LOW HULL · ACTION LIMIT REDUCED TO %d"
			% PrizeActionState.LOW_HULL_ACTION_LIMIT
		if bool(prize_state["low_hull_reduction_applied"])
		else "HULL READY · STANDARD %d ACTION LIMIT"
			% PrizeActionState.DEFAULT_ACTION_LIMIT
	)
	var lines := PackedStringArray([
		"CHOOSE LIMITED PRIZES · EACH SUCCESS USES 1 ACTION",
		low_hull_text,
		"SHIP CARGO SPACE · %d FREE OF %d" % [
			ship.get_cargo_limit() - ship.get_cargo_lots().size(),
			ship.get_cargo_limit(),
		],
		"",
	])
	for prize_type in PrizeActionState.PRIZE_TYPES:
		var taken: bool = _prize_actions.selected_prize_types.has(prize_type)
		lines.append("[%s] %s · %s" % [
			PrizeActionState.PRIZE_KEYS[prize_type],
			PrizeActionState.PRIZE_DISPLAY_NAMES[prize_type],
			"TAKEN" if taken else "AVAILABLE",
		])
	prize_details.text = "\n".join(lines)
	prize_result.text = _prize_actions.last_result
	prize_controls.text = (
		"[1] CARGO · [2] CANNONS · [3] REPAIR · "
		+ "[4] TRADE RECORDS · [X] CLOSE"
	)
	prize_view.visible = _prize_actions.screen_open


func _get_attack_choices_text() -> String:
	var pursuit_text := (
		" · [P] PURSUIT SAIL ATTACK"
		if ship_module_loadout.is_long_guns_active()
		else " · PURSUIT REQUIRES LONG GUNS"
	)
	if _selected_attack_choice == InspectableTargetShipState.ATTACK_SAILS:
		return "[H] HULL · [K] > SAILS <" + pursuit_text
	return "[H] > HULL < · [K] SAILS" + pursuit_text


func _get_target_combat_display_target() -> InspectableTargetShipState:
	if not _last_attacked_target_id.is_empty():
		for target in inspection_targets:
			if target.target_id == _last_attacked_target_id and target.visible:
				return target
	if _active_inspection_target != null and _active_inspection_target.visible:
		return _active_inspection_target
	var nearest_target: InspectableTargetShipState = null
	var nearest_distance := INF
	for target in inspection_targets:
		if not target.visible:
			continue
		var distance: float = target.get_distance_to_player_ship()
		if distance < nearest_distance:
			nearest_target = target
			nearest_distance = distance
	return nearest_target


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


func _update_trade_persistence() -> void:
	if _trade_bought_lot_count <= _trade_sold_lot_count:
		return
	if (
		_player_aboard_ship
		and not ship.is_docked
		and ship.last_dock_id == TradeContact.PORT_SHORE_ID
		and ship.global_position.distance_to(
			ship.get_dock_definition(TradeContact.PORT_SHORE_ID)["snap_position"]
		) > 8.0
	):
		_trade_sailed_from_port = true
		_trade_persistence_holds = _trade_purchase_state_persists()


func _storage_matches_persistence_snapshot() -> bool:
	var current_ship_cargo: Array[String] = ship.get_cargo_lots()
	return (
		_get_non_food_lots(current_ship_cargo)
			== _get_non_food_lots(_persistence_ship_cargo)
		and current_ship_cargo.count(ShipFoodState.FOOD_LOT_NAME)
			<= _persistence_ship_cargo.count(ShipFoodState.FOOD_LOT_NAME)
		and cove_storage.get_cargo_lots() == _persistence_cove_storage
		and cove_storage.get_storage_slots() == _persistence_cove_storage_slots
	)


func _trade_purchase_state_persists() -> bool:
	var current_cargo: Array[String] = ship.get_cargo_lots()
	return (
		money == _trade_purchase_money_snapshot
		and _get_non_food_lots(current_cargo)
			== _get_non_food_lots(_trade_purchase_cargo_snapshot)
		and current_cargo.count(ShipFoodState.FOOD_LOT_NAME)
			<= _trade_purchase_cargo_snapshot.count(
				ShipFoodState.FOOD_LOT_NAME
			)
	)


func _get_non_food_lots(cargo: Array[String]) -> Array[String]:
	var non_food_lots: Array[String] = []
	for lot_name in cargo:
		if lot_name != ShipFoodState.FOOD_LOT_NAME:
			non_food_lots.append(lot_name)
	return non_food_lots


func _get_world_cargo_total() -> int:
	return (
		ship.get_cargo_lots().size()
		+ wreck_opportunity.get_salvage_lots().size()
		+ cove_storage.get_cargo_lots().size()
	)


func _can_enter_ruin() -> bool:
	return (
		not _player_aboard_ship
		and _player_shore_id == "island"
		and not _dialogue_open
		and not waypoint_display.chart_visible
		and not _chart_release_pending
		and not _cargo_choice_open
		and not _cargo_choice_release_pending
		and not _storage_view_open
		and not _storage_release_pending
		and not _construction_view_open
		and not _construction_release_pending
		and not _trade_view_open
		and not _trade_release_pending
		and not _journal_view_open
		and not _journal_release_pending
		and ruin_exploration.can_enter()
	)


func _enter_ruin() -> void:
	if not _can_enter_ruin():
		return
	if not ruin_exploration.try_enter(ship.get_cargo_lots()):
		return
	_player_near_ship_return = false
	player.go_ashore(
		RuinExplorationState.RUIN_ENTRY_POSITION,
		"ruin",
		ruin_exploration.get_walking_region(),
	)
	controls_help.text = "WASD / ARROWS TO WALK · E INTERACT"
	_update_ruin_exploration()
	_update_story_clue()
	_update_interaction_prompt()


func _exit_ruin() -> void:
	if not ruin_exploration.is_inside():
		return
	if not ruin_exploration.try_exit(ship.get_cargo_lots()):
		return
	var island_definition: Dictionary = ship.get_dock_definition("island")
	player.go_ashore(
		RuinExplorationState.ISLAND_RETURN_POSITION,
		"island",
		island_definition["shore_region"],
	)
	_player_near_ship_return = false
	controls_help.text = WALKING_CONTROLS_TEXT
	_update_ruin_exploration()
	_update_story_clue()
	_update_interaction_prompt()


func _take_ruin_treasure() -> void:
	if not ruin_exploration.can_take_treasure():
		return
	var cargo_before: Array[String] = ship.get_cargo_lots()
	if not ship.can_keep_cargo_lot():
		_open_cargo_choice(
			RuinExplorationState.TREASURE_LOT_NAME,
			CARGO_SOURCE_RUIN,
		)
		return
	if not ship.keep_cargo_lot(RuinExplorationState.TREASURE_LOT_NAME):
		_last_cargo_action = "KEEP_RUIN_TREASURE"
		_last_cargo_result = "NO_CHANGE_CARGO_FULL"
		return
	if not ruin_exploration.collect_direct(
		cargo_before,
		ship.get_cargo_lots(),
	):
		ship.undo_last_kept_cargo_lot(RuinExplorationState.TREASURE_LOT_NAME)
		_last_cargo_action = "KEEP_RUIN_TREASURE"
		_last_cargo_result = "ROLLED_BACK_RUIN_STATE"
		return
	_cargo_kept_count += 1
	_last_cargo_action = "KEEP_RUIN_TREASURE"
	_last_cargo_result = "KEPT_ONE_RUIN_TREASURE_LOT"
	_update_cargo_view()
	_update_ruin_exploration()
	_update_interaction_prompt()


func _open_ruin_tool_gate() -> void:
	if not ruin_exploration.can_interact_tool_gate():
		return
	ruin_exploration.try_open_tool_gate(ship.get_cargo_lots(), money)
	_update_ruin_exploration()
	_update_story_clue()
	_update_interaction_prompt()


func _take_story_clue_fragment() -> void:
	if not story_clue.can_take_fragment():
		return
	var cargo_before: Array[String] = ship.get_cargo_lots()
	if not ship.can_keep_cargo_lot():
		_open_cargo_choice(
			StoryClueState.FRAGMENT_LOT_NAME,
			CARGO_SOURCE_STORY_CLUE,
		)
		return
	if not ship.keep_cargo_lot(StoryClueState.FRAGMENT_LOT_NAME):
		_last_cargo_action = "KEEP_STORY_MAP_FRAGMENT"
		_last_cargo_result = "NO_CHANGE_CARGO_FULL"
		return
	if not story_clue.collect_direct(cargo_before, ship.get_cargo_lots()):
		ship.undo_last_kept_cargo_lot(StoryClueState.FRAGMENT_LOT_NAME)
		_last_cargo_action = "KEEP_STORY_MAP_FRAGMENT"
		_last_cargo_result = "ROLLED_BACK_STORY_CLUE_STATE"
		return
	_cargo_kept_count += 1
	_last_cargo_action = "KEEP_STORY_MAP_FRAGMENT"
	_last_cargo_result = "KEPT_ONE_TORN_MAP_FRAGMENT"
	_sync_story_clue_chart()
	_update_cargo_view()
	_update_story_clue()
	_update_interaction_prompt()


func _fish_in_area() -> void:
	if not fishing_area.can_receive_fishing_press():
		return

	var cargo_before: Array[String] = ship.get_cargo_lots()
	var fish_lot: String = fishing_area.try_catch_fish_lot(cargo_before)
	if fish_lot.is_empty():
		_last_cargo_action = "FISHING_ATTEMPT"
		_last_cargo_result = fishing_area.get_last_catch_result()
		_update_interaction_prompt()
		return

	if not ship.can_keep_cargo_lot():
		if not _open_cargo_choice(fish_lot, CARGO_SOURCE_FISHING):
			fishing_area.resolve_discard(ship.get_cargo_lots())
			_last_cargo_action = "FULL_SHIP_FISHING_ATTEMPT"
			_last_cargo_result = "NO_CHANGE_CHOICE_NOT_OPENED"
		return

	if not ship.keep_cargo_lot(fish_lot):
		fishing_area.resolve_discard(ship.get_cargo_lots())
		_last_cargo_action = "KEEP_CAUGHT_FISH"
		_last_cargo_result = "NO_CHANGE_CARGO_FULL"
		return
	if not fishing_area.resolve_direct_keep(ship.get_cargo_lots()):
		ship.undo_last_kept_cargo_lot(fish_lot)
		_last_cargo_action = "KEEP_CAUGHT_FISH"
		_last_cargo_result = "ROLLED_BACK_FISHING_STATE"
		return

	_cargo_kept_count += 1
	_last_cargo_action = "KEEP_CAUGHT_FISH"
	_last_cargo_result = "KEPT_ONE_%s" % _cargo_result_name(fish_lot)
	_update_cargo_view()
	_update_interaction_prompt()


func _salvage_wreck() -> void:
	if (
		_trade_view_open
		or _trade_release_pending
		or _journal_view_open
		or _journal_release_pending
	):
		return
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
		_open_cargo_choice(salvage_lot, CARGO_SOURCE_WRECK)
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
	_defeat_recovery.record_existing_salvage_recovery(
		salvage_lot,
		ship.get_cargo_lots(),
		ship.timber_lots,
		ship.get_cargo_limit(),
	)
	_update_cargo_view()
	_update_interaction_prompt()


func _open_cargo_choice(cargo_lot: String, cargo_source: String) -> bool:
	if (
		_cargo_choice_open
		or cargo_lot.is_empty()
		or not [
			CARGO_SOURCE_WRECK,
			CARGO_SOURCE_FISHING,
			CARGO_SOURCE_RUIN,
			CARGO_SOURCE_STORY_CLUE,
			CARGO_SOURCE_MONSTER_HUNT,
		].has(cargo_source)
	):
		return false
	if (
		cargo_source == CARGO_SOURCE_WRECK
		and not wreck_opportunity.mark_salvage_choice_pending(cargo_lot)
	):
		return false
	if (
		cargo_source == CARGO_SOURCE_FISHING
		and (
			not fishing_area.is_fish_cargo_lot(cargo_lot)
			or not fishing_area.record_choice_required()
		)
	):
		return false
	if (
		cargo_source == CARGO_SOURCE_RUIN
		and (
			cargo_lot != RuinExplorationState.TREASURE_LOT_NAME
			or not ruin_exploration.begin_treasure_choice(
				ship.get_cargo_lots()
			)
		)
	):
		return false
	if (
		cargo_source == CARGO_SOURCE_STORY_CLUE
		and (
			cargo_lot != StoryClueState.FRAGMENT_LOT_NAME
			or not story_clue.begin_fragment_choice(
				ship.get_cargo_lots()
			)
		)
	):
		return false
	if (
		cargo_source == CARGO_SOURCE_MONSTER_HUNT
		and (
			cargo_lot != MonsterHuntState.PART_LOT_NAME
			or not monster_hunt.begin_part_choice(ship.get_cargo_lots())
		)
	):
		return false
	_pending_cargo_lot = cargo_lot
	_pending_cargo_source = cargo_source
	_cargo_choice_open = true
	_cargo_choice_opened_count += 1
	_last_cargo_action = "FULL_SHIP_%s_ATTEMPT" % cargo_source
	_last_cargo_result = "CARGO_CHOICE_REQUIRED"
	ship.set_navigation_input_blocked(true)
	player.movement_enabled = false
	controls_help.text = _get_cargo_choice_controls_text()
	interaction_prompt.hide()
	_update_cargo_view()
	return true


func _leave_or_discard_pending_cargo_lot() -> void:
	if not _cargo_choice_open or _pending_cargo_lot.is_empty():
		return
	if _pending_cargo_source == CARGO_SOURCE_MONSTER_HUNT:
		var blocked_evidence: Dictionary = monster_hunt.record_blocked_leave(
			ship.get_cargo_lots()
		)
		if blocked_evidence.is_empty():
			return
		_last_cargo_action = "MONSTER_PART_REPLACEMENT_REQUIRED"
		_last_cargo_result = String(blocked_evidence["result"])
		_update_cargo_view()
		return
	var resolved := false
	if _pending_cargo_source == CARGO_SOURCE_WRECK:
		resolved = wreck_opportunity.leave_salvage_lot_at_wreck(
			_pending_cargo_lot
		)
	elif _pending_cargo_source == CARGO_SOURCE_FISHING:
		resolved = fishing_area.resolve_discard(ship.get_cargo_lots())
	elif _pending_cargo_source == CARGO_SOURCE_RUIN:
		resolved = ruin_exploration.leave_treasure_in_place(
			ship.get_cargo_lots()
		)
	elif _pending_cargo_source == CARGO_SOURCE_STORY_CLUE:
		resolved = story_clue.leave_fragment_in_place(
			ship.get_cargo_lots()
		)
	if not resolved:
		return
	_cargo_left_count += 1
	_cargo_choice_resolution_count += 1
	if _pending_cargo_source == CARGO_SOURCE_WRECK:
		_last_cargo_action = "LEAVE_NEW_LOT"
		_last_cargo_result = "LEFT_%s_AT_WRECK" % _cargo_result_name(
			_pending_cargo_lot
		)
	elif _pending_cargo_source == CARGO_SOURCE_FISHING:
		_last_cargo_action = "DISCARD_NEW_FISH_LOT"
		_last_cargo_result = "DISCARDED_FISH_LOT_CARGO_UNCHANGED"
	elif _pending_cargo_source == CARGO_SOURCE_RUIN:
		_last_cargo_action = "LEAVE_RUIN_TREASURE_IN_PLACE"
		_last_cargo_result = "LEFT_RUIN_TREASURE_IN_PLACE_CARGO_UNCHANGED"
	elif _pending_cargo_source == CARGO_SOURCE_STORY_CLUE:
		_last_cargo_action = "LEAVE_STORY_MAP_FRAGMENT_IN_PLACE"
		_last_cargo_result = "LEFT_MAP_FRAGMENT_IN_RUIN_CARGO_UNCHANGED"
	_close_cargo_choice()


func _replace_cargo_with_pending_lot(slot_index: int) -> void:
	if not _cargo_choice_open or _pending_cargo_lot.is_empty():
		return
	if (
		_pending_cargo_source == CARGO_SOURCE_WRECK
		and wreck_opportunity.get_next_salvage_lot() != _pending_cargo_lot
	):
		return
	if (
		_pending_cargo_source == CARGO_SOURCE_FISHING
		and not fishing_area.has_pending_catch()
	):
		return
	if (
		_pending_cargo_source == CARGO_SOURCE_RUIN
		and not ruin_exploration.has_pending_treasure_choice()
	):
		return
	if (
		_pending_cargo_source == CARGO_SOURCE_STORY_CLUE
		and not story_clue.has_pending_fragment_choice()
	):
		return
	if (
		_pending_cargo_source == CARGO_SOURCE_MONSTER_HUNT
		and not monster_hunt.has_pending_part_choice()
	):
		return
	var removed_lot: String = ship.replace_cargo_slot(
		slot_index,
		_pending_cargo_lot,
	)
	if removed_lot.is_empty():
		_last_cargo_action = "REPLACE_CARGO_SLOT"
		_last_cargo_result = "NO_CHANGE_INVALID_SLOT"
		return
	var source_resolved := false
	if _pending_cargo_source == CARGO_SOURCE_WRECK:
		source_resolved = wreck_opportunity.exchange_salvage_lot(
			_pending_cargo_lot,
			removed_lot,
		)
	elif _pending_cargo_source == CARGO_SOURCE_FISHING:
		source_resolved = fishing_area.resolve_replacement(
			removed_lot,
			ship.get_cargo_lots(),
		)
	elif _pending_cargo_source == CARGO_SOURCE_RUIN:
		source_resolved = ruin_exploration.collect_by_replacement(
			removed_lot,
			ship.get_cargo_lots(),
		)
	elif _pending_cargo_source == CARGO_SOURCE_STORY_CLUE:
		source_resolved = story_clue.collect_by_replacement(
			removed_lot,
			ship.get_cargo_lots(),
		)
	elif _pending_cargo_source == CARGO_SOURCE_MONSTER_HUNT:
		source_resolved = monster_hunt.resolve_replacement(
			removed_lot,
			ship.get_cargo_lots(),
		)
	if not source_resolved:
		ship.replace_cargo_slot(slot_index, removed_lot)
		_last_cargo_action = "REPLACE_CARGO_SLOT"
		_last_cargo_result = "ROLLED_BACK_CARGO_SOURCE_STATE"
		return

	_cargo_replaced_count += 1
	_cargo_choice_resolution_count += 1
	_last_cargo_action = "REPLACE_CARGO_SLOT_%d" % (slot_index + 1)
	_last_cargo_result = "REPLACED_%s_WITH_%s" % [
		_cargo_result_name(removed_lot),
		_cargo_result_name(_pending_cargo_lot),
	]
	if _pending_cargo_source == CARGO_SOURCE_WRECK:
		_defeat_recovery.record_existing_salvage_recovery(
			_pending_cargo_lot,
			ship.get_cargo_lots(),
			ship.timber_lots,
			ship.get_cargo_limit(),
		)
	elif _pending_cargo_source == CARGO_SOURCE_STORY_CLUE:
		_sync_story_clue_chart()
		_update_story_clue()
	elif _pending_cargo_source == CARGO_SOURCE_MONSTER_HUNT:
		_update_monster_hunt_view()
	_close_cargo_choice()


func _close_cargo_choice() -> void:
	_cargo_choice_open = false
	_cargo_choice_release_pending = true
	_prompt_refresh_after_navigation_release = true
	_pending_cargo_lot = ""
	_pending_cargo_source = ""
	cargo_choice_view.hide()
	controls_help.text = RELEASE_CONTROLS_TEXT
	_update_cargo_view()
	_update_interaction_prompt()


func _cargo_result_name(lot_name: String) -> String:
	return lot_name.to_upper().replace(" ", "_")


func _get_cargo_choice_controls_text() -> String:
	if _pending_cargo_source == CARGO_SOURCE_FISHING:
		return FISHING_CARGO_CHOICE_CONTROLS_TEXT
	if _pending_cargo_source == CARGO_SOURCE_RUIN:
		return RUIN_CARGO_CHOICE_CONTROLS_TEXT
	if _pending_cargo_source == CARGO_SOURCE_STORY_CLUE:
		return STORY_CLUE_CARGO_CHOICE_CONTROLS_TEXT
	if _pending_cargo_source == CARGO_SOURCE_MONSTER_HUNT:
		return MONSTER_HUNT_CARGO_CHOICE_CONTROLS_TEXT
	return CARGO_CHOICE_CONTROLS_TEXT


func _update_cargo_view() -> void:
	var cargo_lots: Array[String] = ship.get_cargo_lots()
	var cargo_lines := PackedStringArray([
		"CARGO · USED %d/%d · FREE %d" % [
			cargo_lots.size(),
			ship.get_cargo_limit(),
			ship.get_cargo_limit() - cargo_lots.size(),
		],
		"MODULE SLOT · %s · NEXT %s" % [
			ship_module_loadout.get_active_module_name(),
			ship_module_loadout.get_pending_module_name(),
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
		cargo_lines.append("PENDING  %s · %s" % [
			_pending_cargo_lot,
			_pending_cargo_source,
		])
	else:
		cargo_lines.append("PENDING  NONE")
	cargo_details.text = "\n".join(cargo_lines)
	if (
		_player_on_target_deck
		or _storage_view_open
		or _construction_view_open
		or _trade_view_open
		or _journal_view_open
		or ship_module_loadout.is_selection_open()
	):
		cargo_view.hide()
	else:
		cargo_view.show()

	if not _cargo_choice_open:
		cargo_choice_view.hide()
		return
	cargo_choice_title.text = "CARGO FULL · NEW %s" % _pending_cargo_lot
	var choice_lines := PackedStringArray()
	for slot_index in range(cargo_lots.size()):
		choice_lines.append(
			"[%d] REPLACE %s" % [slot_index + 1, cargo_lots[slot_index]]
		)
	if _pending_cargo_source == CARGO_SOURCE_WRECK:
		choice_lines.append("[X] LEAVE %s AT WRECK" % _pending_cargo_lot)
	elif _pending_cargo_source == CARGO_SOURCE_FISHING:
		choice_lines.append(
			"[X] DISCARD CAUGHT %s · CARGO UNCHANGED" % _pending_cargo_lot
		)
	elif _pending_cargo_source == CARGO_SOURCE_STORY_CLUE:
		choice_lines.append(
			"[X] LEAVE %s IN RUIN · CLUE NOT RECORDED" % (
				_pending_cargo_lot
			)
		)
	elif _pending_cargo_source == CARGO_SOURCE_MONSTER_HUNT:
		choice_lines.append(
			"CHOOSE A NUMBERED CARGO SLOT · %s CANNOT BE LEFT" % (
				_pending_cargo_lot
			)
		)
	else:
		choice_lines.append(
			"[X] LEAVE %s IN RUIN · TREASURE STAYS" % _pending_cargo_lot
		)
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
		var ship_slot_key := "0" if slot_index == 3 else str(slot_index + 1)
		lines.append("[%s] SLOT %d  %s" % [
			ship_slot_key,
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


func _update_money_view() -> void:
	money_details.text = "MONEY · %d COINS" % money
	if _player_on_target_deck:
		money_view.hide()
	else:
		money_view.show()


func _update_heat_view() -> void:
	var heat_state: Dictionary = _world_heat.get_playtest_state()
	var current_heat := int(heat_state["current_heat"])
	heat_meter.min_value = 0.0
	heat_meter.max_value = float(maxi(
		int(heat_state["display_max_heat"]),
		current_heat,
	))
	heat_meter.value = float(current_heat)
	heat_title.text = "WORLD HEAT · %d · HUNTER AT %d" % [
		current_heat,
		PirateHunterShipState.HEAT_THRESHOLD,
	]
	heat_status.text = String(heat_state["last_result"])
	heat_view.show()


func _update_pirate_hunter_view() -> void:
	pirate_hunter_status.text = pirate_hunter.get_warning_text()
	pirate_hunter_view.visible = (
		_player_aboard_ship
		and pirate_hunter.is_encounter_status_visible()
	)


func _update_food_view() -> void:
	var food_state: Dictionary = ship.get_food_playtest_state()
	var food_units := int(food_state["food_units"])
	food_title.text = "SHIP FOOD · %d UNIT%s" % [
		food_units,
		"" if food_units == 1 else "S",
	]
	food_status.text = String(food_state["status"])
	if food_units > 0:
		food_details.text = (
			"NEXT USE · %.1f / %.1f DISTANCE\n"
			+ "DISTANCE UNTIL NEXT USE · %.1f"
		) % [
			food_state["progress_distance"],
			food_state["distance_per_use"],
			food_state["distance_to_next_use"],
		]
	else:
		food_details.text = (
			"NEXT USE · WAITING FOR FOOD\n"
			+ "ZERO-FOOD SAILING · %.1f DISTANCE"
		) % food_state["zero_food_sailing_distance"]
	food_view.visible = _player_aboard_ship


func _update_hull_view() -> void:
	var damage_state: Dictionary = ship.get_damage_playtest_state()
	var hull_current := int(damage_state["hull_current"])
	var hull_max := int(damage_state["hull_max"])
	hull_meter.min_value = 0.0
	hull_meter.max_value = float(hull_max)
	hull_meter.value = float(hull_current)
	hull_title.text = "HULL CONDITION · %d / %d" % [
		hull_current,
		hull_max,
	]
	if int(damage_state["hit_count"]) > 0:
		var last_damage_event: Dictionary = damage_state["last_damage_event"]
		hull_status.text = "LAST REEF HIT · -%d · %d / %d" % [
			last_damage_event.get("damage", damage_state["reef_hit_damage"]),
			hull_current,
			hull_max,
		]
	else:
		hull_status.text = "REEF DAMAGE · %d PER HIT" % (
			damage_state["reef_hit_damage"]
		)
	hull_view.visible = _player_aboard_ship


func _update_crew_view() -> void:
	var crew_state: Dictionary = ship.get_crew_condition_playtest_state()
	var condition := int(crew_state["condition"])
	var condition_max := int(crew_state["condition_max"])
	crew_meter.min_value = 0.0
	crew_meter.max_value = float(condition_max)
	crew_meter.value = float(condition)
	crew_title.text = "CREW CONDITION · %d / %d" % [
		condition,
		condition_max,
	]
	crew_status.text = String(crew_state["status_text"])
	crew_view.visible = _player_aboard_ship
	var view_evidence := {
		"visible": crew_view.visible,
		"title": crew_title.text,
		"status": crew_status.text,
		"full_text": "%s\n%s" % [crew_title.text, crew_status.text],
		"meter_value": crew_meter.value,
		"meter_max": crew_meter.max_value,
		"condition": condition,
		"condition_max": condition_max,
		"low": crew_state["low"],
		"base_sailing_top_speed": crew_state["base_sailing_top_speed"],
		"effective_sailing_top_speed": (
			crew_state["effective_sailing_top_speed"]
		),
	}
	if (
		crew_view.visible
		and int(crew_state["injury_count"]) == 0
		and int(crew_state["restoration_count"]) == 0
		and _crew_full_view_evidence.is_empty()
	):
		_crew_full_view_evidence = view_evidence.duplicate(true)
	elif crew_view.visible and bool(crew_state["low"]):
		view_evidence["injury_evidence"] = (
			(crew_state["last_injury_evidence"] as Dictionary).duplicate(true)
		)
		_crew_injury_view_evidence = view_evidence.duplicate(true)
	elif crew_view.visible and int(crew_state["restoration_count"]) > 0:
		view_evidence["restoration_evidence"] = (
			(
				crew_state["last_safe_dock_restoration_evidence"]
				as Dictionary
			).duplicate(true)
		)
		_crew_restoration_view_evidence = view_evidence.duplicate(true)


func _update_repair_view() -> void:
	var repair_state: Dictionary = ship.get_repair_playtest_state()
	repair_title.text = "DOCKED HULL REPAIR"
	repair_cost.text = "FIXED COST · %s · NO MONEY" % (
		repair_state["fixed_cost_text"]
	)
	repair_preview.text = "PREVIEW · %s" % repair_state["preview_text"]
	repair_status.text = String(repair_state["status_text"])
	repair_result.text = _last_repair_result
	repair_controls.text = (
		"[R] CONFIRM REPAIR"
		if bool(repair_state["available"])
		else "[R] REPAIR DISABLED"
	)
	repair_view.visible = _player_aboard_ship and ship.is_docked


func _handle_repair_input(key_event: InputEventKey) -> void:
	if not key_event.pressed:
		_repair_key_held = false
		return

	if key_event.echo or _repair_key_held:
		_repair_held_input_count += 1
		_last_repair_action = "HELD_REPAIR_KEY"
		_last_repair_result = "NO CHANGE · RELEASE R BEFORE ANOTHER REPAIR"
		var damage_state: Dictionary = ship.get_damage_playtest_state()
		var repair_state: Dictionary = ship.get_repair_playtest_state()
		var cargo_snapshot: Array[String] = ship.get_cargo_lots()
		_last_held_repair_evidence = {
			"action": _last_repair_action,
			"result": _last_repair_result,
			"echo": key_event.echo,
			"hull_before": damage_state["hull_current"],
			"hull_after": damage_state["hull_current"],
			"cargo_before": cargo_snapshot,
			"cargo_after": cargo_snapshot.duplicate(),
			"money_before": money,
			"money_after": money,
			"repair_attempt_count_before": repair_state["attempt_count"],
			"repair_attempt_count_after": repair_state["attempt_count"],
			"repair_success_count_before": repair_state["success_count"],
			"repair_success_count_after": repair_state["success_count"],
			"no_state_change": true,
			"fresh_press_required": true,
		}
		_update_repair_view()
		return

	_repair_key_held = true
	_attempt_docked_hull_repair()


func _attempt_docked_hull_repair() -> void:
	var money_before := money
	var evidence: Dictionary = ship.attempt_docked_hull_repair()
	evidence["money_before"] = money_before
	evidence["money_after"] = money
	evidence["money_delta"] = money - money_before
	evidence["money_unchanged"] = money == money_before
	evidence["uses_money"] = false
	_last_repair_action = String(evidence["action"])
	_last_repair_result = String(evidence["result"])
	_last_repair_attempt_evidence = evidence.duplicate(true)
	if bool(evidence["success"]):
		_successful_repair_evidence = evidence.duplicate(true)
		_defeat_recovery.record_existing_repair_recovery(evidence)
		_repair_snapshot_ashore = {}
		_repair_snapshot_return = {}
		_repair_snapshot_release = {}
	else:
		_last_denied_repair_evidence = evidence.duplicate(true)
	_update_cargo_view()
	_update_money_view()
	_update_hull_view()
	_update_repair_view()
	if bool(evidence["success"]):
		_capture_repair_checkpoint("SUCCESS")


func _capture_repair_checkpoint(checkpoint: String) -> void:
	if _successful_repair_evidence.is_empty():
		return
	_update_repair_view()
	var damage_state: Dictionary = ship.get_damage_playtest_state()
	var repair_state: Dictionary = ship.get_repair_playtest_state()
	var snapshot := {
		"checkpoint": checkpoint,
		"hull_current": damage_state["hull_current"],
		"damage_owner_count": damage_state["owner_count"],
		"reef_hit_count": damage_state["hit_count"],
		"damage_repair_count": damage_state["repair_count"],
		"repair_success_count": repair_state["success_count"],
		"repair_consumed_timber_count": repair_state["consumed_timber_count"],
		"cargo_lots": ship.get_cargo_lots(),
		"ship_timber_count": ship.timber_lots,
		"money": money,
		"ship_is_docked": ship.is_docked,
		"current_dock_id": ship.current_dock_id,
		"last_dock_id": ship.last_dock_id,
		"player_aboard_ship": _player_aboard_ship,
		"player_shore_id": _player_shore_id,
		"repair_view_visible": repair_view.visible,
	}
	match checkpoint:
		"SUCCESS":
			_repair_snapshot_success = snapshot
		"ASHORE":
			_repair_snapshot_ashore = snapshot
		"RETURN":
			_repair_snapshot_return = snapshot
		"RELEASE":
			_repair_snapshot_release = snapshot


func _repair_checkpoint_matches_success(checkpoint: Dictionary) -> bool:
	return (
		not _repair_snapshot_success.is_empty()
		and not checkpoint.is_empty()
		and checkpoint["hull_current"]
			== _repair_snapshot_success["hull_current"]
		and checkpoint["damage_owner_count"]
			== _repair_snapshot_success["damage_owner_count"]
		and checkpoint["reef_hit_count"]
			== _repair_snapshot_success["reef_hit_count"]
		and checkpoint["repair_success_count"]
			== _repair_snapshot_success["repair_success_count"]
		and checkpoint["damage_repair_count"]
			== _repair_snapshot_success["damage_repair_count"]
	)


func _update_damage_hit_checkpoint() -> void:
	var damage_state: Dictionary = ship.get_damage_playtest_state()
	var hit_count := int(damage_state["hit_count"])
	if hit_count <= _damage_last_seen_hit_count:
		return

	_damage_last_seen_hit_count = hit_count
	_damage_snapshot_at_dock = {}
	_damage_snapshot_ashore = {}
	_damage_snapshot_return = {}
	_damage_snapshot_release = {}
	_capture_damage_checkpoint("HIT")


func _capture_damage_checkpoint(checkpoint: String) -> void:
	_update_hull_view()
	var damage_state: Dictionary = ship.get_damage_playtest_state()
	var food_state: Dictionary = ship.get_food_playtest_state()
	var snapshot := {
		"checkpoint": checkpoint,
		"hull_current": damage_state["hull_current"],
		"hull_max": damage_state["hull_max"],
		"reef_hit_count": damage_state["hit_count"],
		"reef_contact_active": damage_state["contact_active"],
		"reef_cooldown_remaining": damage_state["cooldown_remaining"],
		"last_damage_event": (
			(damage_state["last_damage_event"] as Dictionary).duplicate(true)
		),
		"ship_is_docked": ship.is_docked,
		"current_dock_id": ship.current_dock_id,
		"last_dock_id": ship.last_dock_id,
		"player_aboard_ship": _player_aboard_ship,
		"player_shore_id": _player_shore_id,
		"hull_view_visible": hull_view.visible,
		"hull_meter_value": hull_meter.value,
		"food_units": food_state["food_units"],
		"food_progress_distance": food_state["progress_distance"],
		"cargo_lots": ship.get_cargo_lots(),
	}
	match checkpoint:
		"INITIAL":
			_damage_snapshot_initial = snapshot
		"HIT":
			_damage_snapshot_at_hit = snapshot
		"DOCK":
			_damage_snapshot_at_dock = snapshot
		"ASHORE":
			_damage_snapshot_ashore = snapshot
		"RETURN":
			_damage_snapshot_return = snapshot
		"RELEASE":
			_damage_snapshot_release = snapshot


func _damage_checkpoint_matches_hit(checkpoint: Dictionary) -> bool:
	return (
		not _damage_snapshot_at_hit.is_empty()
		and not checkpoint.is_empty()
		and checkpoint["hull_current"]
			== _damage_snapshot_at_hit["hull_current"]
		and checkpoint["reef_hit_count"]
			== _damage_snapshot_at_hit["reef_hit_count"]
	)


func _update_trade_view() -> void:
	if _active_trade_contact == null:
		trade_title.text = "TRADE"
		trade_details.text = "ONE GOOD · FIXED PRICES"
		trade_result.text = _last_trade_result
		trade_controls.text = "[X] CLOSE"
	else:
		var cargo_lots: Array[String] = ship.get_cargo_lots()
		var used_slots := cargo_lots.size()
		var free_slots: int = ship.get_cargo_limit() - used_slots
		var ammunition_state: Dictionary = ship.get_ammunition_playtest_state()
		var contact_state: Dictionary = (
			_active_trade_contact.get_mark_state(completed_voyages)
		)
		var price_state: String = String(contact_state["current_price_state"])
		var fixed_price: int = int(contact_state["current_fixed_price"])
		var money_preview: Dictionary = _active_trade_contact.get_money_preview(money)
		var fish_sale_lot_name := (
			FishingAreaState.LARGE_FISH_LOT_NAME
			if cargo_lots.has(FishingAreaState.LARGE_FISH_LOT_NAME)
			else FishingAreaState.FISH_LOT_NAME
		)
		var fish_money_preview := _get_fish_money_preview(
			money,
			fish_sale_lot_name,
		)
		var treasure_money_preview := _get_treasure_money_preview(money)
		var money_delta: int = int(money_preview["money_delta"])
		var money_delta_text := (
			"+%d" % money_delta if money_delta > 0 else "%d" % money_delta
		)
		var mark_return_text := "ALL MARKS AVAILABLE"
		if int(contact_state["marks_used"]) > 0:
			mark_return_text = "VOYAGE %d · %d VOYAGES REMAIN" % [
				contact_state["next_return_voyage"],
				contact_state["voyages_until_next_return"],
			]
		var preview_text := "%d -> %d (%s)" % [
			money_preview["money_before"],
			money_preview["money_after"],
			money_delta_text,
		]
		if not bool(contact_state["trade_available"]):
			preview_text = "UNAVAILABLE · NO %s MARKS" % contact_state["mark_kind"]
		trade_title.text = _active_trade_contact.get_display_name()
		if _active_trade_contact.is_port_trader():
			var condition_state: Dictionary = (
				_port_condition.get_playtest_state(completed_voyages)
			)
			var port_lines := PackedStringArray([
				"PORT CONDITION · %s · %s" % [
					condition_state["name"],
					condition_state["state"],
				],
				"START VOYAGE %d · END VOYAGE %d · %d COMPLETED VOYAGES REMAIN" % [
					condition_state["start_voyage"],
					condition_state["end_voyage"],
					condition_state["remaining_voyages"],
				],
				(
					"MARKET EFFECTS · THREE GOODS ARE VALUABLE"
					if condition_state["active"]
					else "MARKET EFFECTS ENDED · BASE STATES RESTORED"
				),
			])
			for condition_good in condition_state["affected_goods"]:
				port_lines.append(
					"%s · %s · %d COINS · BASE %s · %d" % [
						condition_good["good_name"],
						condition_good["current_price_state"],
						condition_good["current_fixed_price"],
						condition_good["base_price_state"],
						condition_good["base_fixed_price"],
					]
				)
			port_lines.append("")
			port_lines.append("SPICE LOT TRADE · CONDITION DOES NOT CHANGE THIS GOOD")
			port_lines.append("%s · %s · %d COINS" % [
				TradeContact.GOOD_NAME,
				price_state,
				fixed_price,
			])
			port_lines.append("STOCK MARKS · %s · %d/%d" % [
				contact_state["mark_display"],
				contact_state["marks_available"],
				contact_state["mark_capacity"],
			])
			port_lines.append("MARK RETURN · %s" % mark_return_text)
			port_lines.append("VOYAGES COMPLETE · %d" % completed_voyages)
			port_lines.append("BUY PREVIEW · %s" % preview_text)
			port_lines.append("SHIP CARGO · %d/%d · FREE %d" % [
				used_slots,
				ship.get_cargo_limit(),
				free_slots,
			])
			port_lines.append("TRADE · %s" % (
				"AVAILABLE" if contact_state["trade_available"] else "UNAVAILABLE"
			))
			port_lines.append("")
			port_lines.append(
				"SHIP SUPPLY · SEPARATE FROM SPICE PRICE AND MARKS"
			)
			port_lines.append("[B] %s · FIXED %d COINS" % [
				ShipAmmunitionState.SOURCE_CARGO_LOT_NAME,
				ShipAmmunitionState.SOURCE_CARGO_FIXED_PRICE,
			])
			port_lines.append(
				"SOURCE CARGO LOTS IN SHIP · %d" % (
					ammunition_state["source_lot_count"]
				)
			)
			port_lines.append(
				"[L] LOAD 1 SOURCE LOT · 3 AMMUNITION · SAME SLOT"
			)
			port_lines.append("AMMUNITION · %d · LOADED CARGO LOTS %d" % [
				ammunition_state["ammunition_units"],
				ammunition_state["loaded_lot_count"],
			])
			port_lines.append("")
			port_lines.append("PRIZE CANNONS · SELLABLE CARGO · FIXED %d COINS" % (
				PRIZE_CANNON_CARGO_SALE_PRICE
			))
			port_lines.append("[C] SELL 1 %s · HELD CARGO %d" % [
				PrizeActionState.CANNON_CARGO_LOT_NAME,
				cargo_lots.count(PrizeActionState.CANNON_CARGO_LOT_NAME),
			])
			port_lines.append(
				(
					"RUIN TREASURE SALE · %s · NORMAL · %d COINS · HELD %d · "
					+ "TREASURE SELL PREVIEW · %d -> %d (+%d) · "
					+ "[G] SELL ONE RUIN TREASURE LOT"
				) % [
					RuinExplorationState.TREASURE_LOT_NAME,
					TradeContact.NORMAL_PRICE,
					cargo_lots.count(RuinExplorationState.TREASURE_LOT_NAME),
					treasure_money_preview["money_before"],
					treasure_money_preview["money_after"],
					treasure_money_preview["money_delta"],
				]
			)
			trade_details.text = "\n".join(port_lines)
			trade_controls.text = (
				"[E] %s · [B] SUPPLY · [L] LOAD · [C] CANNONS · [G] TREASURE · [X] CLOSE" % (
					"BUY SPICE" if contact_state["trade_available"]
					else "SPICE UNAVAILABLE"
				)
			)
		else:
			trade_details.text = (
				"COVE MARKET · NO PORT CONDITION\n"
				+ "%s · %s · %d COINS\n"
				+ "DEMAND MARKS · %s · %d/%d\n"
				+ "MARK RETURN · %s\n"
				+ "VOYAGES COMPLETE · %d\n"
				+ "SELL PREVIEW · %s\n"
				+ "SHIP CARGO · %d/%d · %s %d LOT\n"
				+ "SPICE TRADE · %s\n\n"
				+ "FISH CATCH SALE · SEPARATE FROM SPICE DEMAND\n"
				+ "%s · %s · %d COINS · HELD %d\n"
				+ "FISH SELL PREVIEW · %d -> %d (+%d)\n"
				+ "[F] SELL ONE %s"
			) % [
				TradeContact.GOOD_NAME,
				price_state,
				fixed_price,
				contact_state["mark_display"],
				contact_state["marks_available"],
				contact_state["mark_capacity"],
				mark_return_text,
				completed_voyages,
				preview_text,
				used_slots,
				ship.get_cargo_limit(),
				TradeContact.GOOD_NAME,
				cargo_lots.count(TradeContact.GOOD_NAME),
				"AVAILABLE" if contact_state["trade_available"] else "UNAVAILABLE",
				fish_sale_lot_name,
				FishingAreaState.FISH_PRICE_STATE,
				fish_money_preview["fixed_price"],
				cargo_lots.count(fish_sale_lot_name),
				fish_money_preview["money_before"],
				fish_money_preview["money_after"],
				fish_money_preview["money_delta"],
				fish_sale_lot_name,
			]
			trade_controls.text = (
				"[E] SELL SPICE · [F] SELL FISH · [X] CLOSE"
				if contact_state["trade_available"]
				else "[E] SPICE UNAVAILABLE · [F] SELL FISH · [X] CLOSE"
			)
		trade_result.text = _last_trade_result
	if _trade_view_open:
		trade_view.show()
	else:
		trade_view.hide()


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


func _on_port_trader_body_entered(body: Node2D) -> void:
	if body != player:
		return
	_player_near_port_trader = true
	_update_interaction_prompt()


func _on_port_trader_body_exited(body: Node2D) -> void:
	if body != player:
		return
	_player_near_port_trader = false
	_update_interaction_prompt()


func _on_cove_buyer_body_entered(body: Node2D) -> void:
	if body != player:
		return
	_player_near_cove_buyer = true
	_update_interaction_prompt()


func _on_cove_buyer_body_exited(body: Node2D) -> void:
	if body != player:
		return
	_player_near_cove_buyer = false
	_update_interaction_prompt()


func _on_ship_module_bench_body_entered(body: Node2D) -> void:
	if body != player:
		return
	_player_near_ship_module_bench = true
	_update_interaction_prompt()


func _on_ship_module_bench_body_exited(body: Node2D) -> void:
	if body != player:
		return
	_player_near_ship_module_bench = false
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
		or _trade_view_open
		or _trade_release_pending
		or _journal_view_open
		or _journal_release_pending
		or ship_module_loadout.is_selection_open()
		or ship_module_loadout.is_release_pending()
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
		or _trade_view_open
		or _trade_release_pending
		or _journal_view_open
		or _journal_release_pending
	):
		return

	if not _prepare_ship_module_for_cove_departure():
		_update_interaction_prompt()
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
		or _trade_view_open
		or _trade_release_pending
		or _journal_view_open
		or _journal_release_pending
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
		or _trade_view_open
		or _trade_release_pending
		or _journal_view_open
		or _journal_release_pending
	):
		return

	var heat_before := _world_heat.get_current_heat()
	var target_conditions_before := _get_target_condition_snapshots()
	var crew_before: Dictionary = ship.get_crew_condition_playtest_state()
	var dock_id: String = ship.dock_at_available()
	if dock_id.is_empty():
		return
	if dock_id == "cove" and _cove_module_departure_release_observed:
		_cove_module_departure_release_observed = false
		_last_module_departure_flow_evidence = {
			"success": false,
			"context": "COVE_DEPARTURE_ABORTED_BY_REDOCK",
			"result": "COVE DEPARTURE ABORTED · MODULE CHOICE NOT STARTED",
			"ship_is_docked": ship.is_docked,
			"at_damaged_dock": ship.at_damaged_dock,
			"departure_ready": ship.is_module_departure_ready(),
			"exit_pending": ship.is_module_departure_exit_pending(),
			"same_dock_abort_safe": true,
		}
	var heat_after := _world_heat.get_current_heat()
	var target_conditions_after := _get_target_condition_snapshots()
	var crew_after: Dictionary = ship.get_crew_condition_playtest_state()
	var crew_dock_evidence: Dictionary = (
		(crew_after["last_dock_evidence"] as Dictionary).duplicate(true)
	)
	crew_dock_evidence.merge({
		"world_heat_before": heat_before,
		"world_heat_after": heat_after,
		"world_heat_unchanged": heat_before == heat_after,
		"target_conditions_before": target_conditions_before,
		"target_conditions_after": target_conditions_after,
		"target_conditions_unchanged": (
			target_conditions_before == target_conditions_after
		),
		"crew_condition_before_context": crew_before["condition"],
		"crew_condition_after_context": crew_after["condition"],
		"only_crew_condition_and_dock_state_changed": (
			bool(crew_dock_evidence.get(
				"unrelated_ship_state_unchanged",
				false,
			))
			and heat_before == heat_after
			and target_conditions_before == target_conditions_after
		),
		"phase_33_recovery_triggered": false,
	}, true)
	_available_dock_id = ""
	_last_leave_allowed = false
	_last_ship_docked = true
	_complete_voyage_on_arrival(dock_id)
	crew_dock_evidence["world_heat_after_normal_dock_rules"] = (
		_world_heat.get_current_heat()
	)
	crew_dock_evidence["normal_dock_heat_rule_evidence"] = (
		_last_completed_voyage_evidence.duplicate(true)
	)
	crew_dock_evidence["crew_restoration_heat_unchanged_before_dock_rules"] = (
		heat_before == heat_after
	)
	_last_crew_dock_context_evidence = crew_dock_evidence.duplicate(true)
	if bool(crew_dock_evidence.get("restored", false)):
		_last_crew_restoration_context_evidence = (
			crew_dock_evidence.duplicate(true)
		)
	if bool(_last_completed_voyage_evidence.get("counted", false)):
		_save_world_heat_persistence("COMPLETED_VOYAGE_DOCK")
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
	if (
		dock_id == TradeContact.COVE_SHORE_ID
		and _trade_sailed_from_port
		and _trade_bought_lot_count > _trade_sold_lot_count
	):
		_trade_cove_docked = true
		_trade_persistence_holds = _trade_purchase_state_persists()
	controls_help.text = DOCKED_CONTROLS_TEXT
	_capture_damage_checkpoint("DOCK")
	_update_crew_view()
	_update_repair_view()
	_update_interaction_prompt()


func _record_voyage_departure(dock_id: String) -> void:
	if dock_id.is_empty():
		return
	if dock_id == "cove":
		if (
			_voyage_departure_dock_id == "cove"
			and bool(_last_module_departure_flow_evidence.get(
				"departure_token_consumed_after_exit",
				false,
			))
		):
			_cove_module_departure_release_observed = false
			return
		_cove_module_departure_release_observed = true
		_last_module_departure_flow_evidence = {
			"success": true,
			"context": "DOCKED_COVE_RELEASE_OBSERVED",
			"result": "COVE RELEASED · MODULE TOKEN HELD THROUGH EXIT",
			"departure_ready": ship.is_module_departure_ready(),
			"exit_pending": ship.is_module_departure_exit_pending(),
			"at_damaged_dock": ship.at_damaged_dock,
			"module_begin_deferred_until_exit": true,
		}
		if (
			not ship.is_module_departure_ready()
			or not ship.is_module_departure_exit_pending()
		):
			ship.set_controls_enabled(false)
			ship.clear_module_departure_state("COVE_RELEASE_INVALID")
			_cove_module_departure_release_observed = false
			_last_module_departure_flow_evidence["success"] = false
			_last_module_departure_flow_evidence["result"] = (
				"COVE RELEASE INVALID · SHIP CONTROLS STOPPED"
			)
			_last_module_departure_flow_evidence[
				"failure_stopped_ship_controls"
			] = not ship.controls_enabled
		return
	_voyage_departure_dock_id = dock_id
	_voyage_departure_count += 1


func _update_cove_module_departure_after_exit() -> void:
	if not ship.is_module_departure_exit_pending():
		return
	if ship.is_docked:
		_cove_module_departure_release_observed = false
		return
	if ship.at_damaged_dock:
		return
	var success := _begin_cove_module_voyage("DOCKED_COVE_EXIT")
	_cove_module_departure_release_observed = false
	if not success:
		return
	_voyage_departure_dock_id = "cove"
	_voyage_departure_count += 1
	_last_module_departure_flow_evidence[
		"voyage_departure_recorded_after_exit"
	] = true
	_last_module_departure_flow_evidence["voyage_departure_count"] = (
		_voyage_departure_count
	)


func _begin_cove_module_voyage(context: String) -> bool:
	var departure_ready_before: bool = ship.is_module_departure_ready()
	var exit_pending_before: bool = ship.is_module_departure_exit_pending()
	var at_damaged_dock_before: bool = ship.at_damaged_dock
	if not departure_ready_before or at_damaged_dock_before:
		ship.set_controls_enabled(false)
		if exit_pending_before:
			ship.clear_module_departure_state("MODULE_START_PREFLIGHT_FAILED")
		_last_module_departure_flow_evidence = {
			"success": false,
			"context": context,
			"result": (
				"MODULE START BLOCKED · DEPARTURE TOKEN NOT READY"
				if not departure_ready_before
				else "MODULE START BLOCKED · COVE EXIT NOT CLEAR"
			),
			"departure_ready_before": departure_ready_before,
			"exit_pending_before": exit_pending_before,
			"at_damaged_dock_before": at_damaged_dock_before,
			"failure_stopped_ship_controls": not ship.controls_enabled,
		}
		return false
	var start_evidence: Dictionary = ship_module_loadout.begin_cove_voyage()
	var success := bool(start_evidence.get("success", false))
	var clear_reason := (
		"%s_MODULE_START" % context
		if success
		else "%s_MODULE_START_FAILED" % context
	)
	var token_evidence: Dictionary = ship.clear_module_departure_state(
		clear_reason
	)
	if not success:
		ship.set_controls_enabled(false)
	_last_module_departure_flow_evidence = start_evidence.duplicate(true)
	_last_module_departure_flow_evidence.merge({
		"context": context,
		"departure_ready_before": departure_ready_before,
		"exit_pending_before": exit_pending_before,
		"at_damaged_dock_before": at_damaged_dock_before,
		"departure_ready_after": ship.is_module_departure_ready(),
		"exit_pending_after": ship.is_module_departure_exit_pending(),
		"departure_token_consumed": (
			success
			and departure_ready_before
			and not ship.is_module_departure_ready()
		),
		"departure_token_consumed_after_exit": (
			success
			and not at_damaged_dock_before
			and bool(token_evidence.get("token_consumed_after_exit", false))
		),
		"token_cleared_on_failed_start": (
			not success
			and departure_ready_before
			and not ship.is_module_departure_ready()
		),
		"token_evidence": token_evidence.duplicate(true),
		"failure_stopped_ship_controls": (
			success or not ship.controls_enabled
		),
	}, true)
	_update_fishing_area()
	return success


func _complete_voyage_on_arrival(dock_id: String) -> void:
	var world_heat_before_arrival := _world_heat.get_current_heat()
	var origin_dock_id := _voyage_departure_dock_id
	_voyage_departure_dock_id = ""
	if origin_dock_id.is_empty():
		_last_completed_voyage_evidence = {
			"counted": false,
			"condition_updated": false,
			"origin_dock_id": origin_dock_id,
			"destination_dock_id": dock_id,
			"completed_voyage_before": completed_voyages,
			"completed_voyage_after": completed_voyages,
			"port_condition_before": (
				_port_condition.get_playtest_state(completed_voyages)
			),
			"port_condition_after": (
				_port_condition.get_playtest_state(completed_voyages)
			),
			"world_heat_before": world_heat_before_arrival,
			"world_heat_after": _world_heat.get_current_heat(),
			"world_heat_unchanged": (
				world_heat_before_arrival == _world_heat.get_current_heat()
			),
			"reason": "NO_RECORDED_DEPARTURE",
		}
		_update_day_night_on_voyage_arrival()
		return
	if origin_dock_id == dock_id:
		_same_dock_arrival_count += 1
		_last_completed_voyage_evidence = {
			"counted": false,
			"condition_updated": false,
			"origin_dock_id": origin_dock_id,
			"destination_dock_id": dock_id,
			"completed_voyage_before": completed_voyages,
			"completed_voyage_after": completed_voyages,
			"port_condition_before": (
				_port_condition.get_playtest_state(completed_voyages)
			),
			"port_condition_after": (
				_port_condition.get_playtest_state(completed_voyages)
			),
			"world_heat_before": world_heat_before_arrival,
			"world_heat_after": _world_heat.get_current_heat(),
			"world_heat_unchanged": (
				world_heat_before_arrival == _world_heat.get_current_heat()
			),
			"reason": "SAME_DOCK_ARRIVAL",
		}
		_update_day_night_on_voyage_arrival()
		return

	var journal_raw_before_completion := _trade_journal.get_entry_snapshot()
	var record_remote_journal_evidence := (
		_trade_journal.is_known()
		and dock_id != TradeContact.PORT_SHORE_ID
	)
	var completed_voyage_before := completed_voyages
	var port_condition_before: Dictionary = (
		_port_condition.get_playtest_state(completed_voyage_before)
	)
	completed_voyages += 1
	var heat_transition: Dictionary = _world_heat.record_completed_voyage(
		completed_voyages
	)
	var port_marks_before: Dictionary = (
		port_trader.get_mark_state(completed_voyage_before)
	)
	var cove_marks_before: Dictionary = (
		cove_buyer.get_mark_state(completed_voyage_before)
	)
	var port_marks_before_condition_update: Dictionary = (
		port_trader.get_mark_state(completed_voyages)
	)
	var cove_marks_before_condition_update: Dictionary = (
		cove_buyer.get_mark_state(completed_voyages)
	)
	var condition_transition: Dictionary = (
		_port_condition.update_completed_voyage(completed_voyages)
	)
	var port_marks_after_condition_update: Dictionary = (
		port_trader.get_mark_state(completed_voyages)
	)
	var cove_marks_after_condition_update: Dictionary = (
		cove_buyer.get_mark_state(completed_voyages)
	)
	var port_spice_marks_unchanged := _trade_mark_resources_equal(
		port_marks_before_condition_update,
		port_marks_after_condition_update,
	)
	var cove_contact_unchanged := _trade_mark_resources_equal(
		cove_marks_before_condition_update,
		cove_marks_after_condition_update,
	)
	_last_port_condition_update_evidence = {
		"completed_voyage": completed_voyages,
		"transition": condition_transition,
		"condition_before": port_condition_before,
		"condition_after": (
			_port_condition.get_playtest_state(completed_voyages)
		),
		"port_spice_marks_before": port_marks_before_condition_update,
		"port_spice_marks_after": port_marks_after_condition_update,
		"port_spice_marks_unchanged": port_spice_marks_unchanged,
		"cove_contact_before": cove_marks_before_condition_update,
		"cove_contact_after": cove_marks_after_condition_update,
		"cove_contact_unchanged": cove_contact_unchanged,
		"condition_update_scope_holds": (
			port_spice_marks_unchanged and cove_contact_unchanged
		),
	}
	var port_marks_returned: int = (
		port_trader.restore_due_marks(completed_voyages)
	)
	var cove_marks_returned: int = (
		cove_buyer.restore_due_marks(completed_voyages)
	)
	_last_completed_voyage_evidence = {
		"counted": true,
		"condition_updated": true,
		"origin_dock_id": origin_dock_id,
		"destination_dock_id": dock_id,
		"completed_voyage_before": completed_voyage_before,
		"completed_voyage_after": completed_voyages,
		"port_condition_before": port_condition_before,
		"port_condition_after": (
			_port_condition.get_playtest_state(completed_voyages)
		),
		"port_condition_update": (
			_last_port_condition_update_evidence.duplicate(true)
		),
		"port_marks_before": port_marks_before,
		"port_marks_after": port_trader.get_mark_state(completed_voyages),
		"port_marks_returned": port_marks_returned,
		"cove_marks_before": cove_marks_before,
		"cove_marks_after": cove_buyer.get_mark_state(completed_voyages),
		"cove_marks_returned": cove_marks_returned,
		"world_heat_before": world_heat_before_arrival,
		"world_heat_after": _world_heat.get_current_heat(),
		"world_heat_transition": heat_transition.duplicate(true),
		"world_heat_held_when_voyage_had_peaceful_attack": (
			not bool(heat_transition[
				"peaceful_attack_during_completed_voyage"
			])
			or int(heat_transition["heat_before"])
				== int(heat_transition["heat_after"])
		),
	}
	_update_day_night_on_voyage_arrival()
	var journal_raw_after_completion := _trade_journal.get_entry_snapshot()
	if record_remote_journal_evidence:
		_journal_remote_raw_snapshot_before_voyage = (
			journal_raw_before_completion.duplicate(true)
		)
		_journal_remote_raw_snapshot_after_voyage = (
			journal_raw_after_completion.duplicate(true)
		)
		_journal_remote_raw_snapshot_unchanged = (
			journal_raw_before_completion == journal_raw_after_completion
		)
		if _journal_remote_raw_snapshot_unchanged:
			_journal_remote_unchanged_voyage_count += 1
		_journal_remote_last_completed_voyage = completed_voyages
	if dock_id == TradeContact.PORT_SHORE_ID and _trade_journal.is_known():
		_journal_before_return_market_snapshot = (
			journal_raw_after_completion.duplicate(true)
		)
		_journal_before_return_market_status = (
			_trade_journal.get_status(completed_voyages)
		)
		_journal_before_return_market_voyage = completed_voyages
		_journal_before_return_market_unchanged = (
			journal_raw_before_completion == journal_raw_after_completion
			and _journal_before_return_market_status
				== TradeJournalState.OLD_STATUS
		)
		_journal_return_market_refresh_recorded = false
	_update_heat_view()
	_update_trade_journal_view()


func _update_day_night_on_voyage_arrival() -> void:
	var transition_evidence: Dictionary = day_night_cycle.record_voyage_arrival(
		_last_completed_voyage_evidence
	)
	_last_completed_voyage_evidence["day_night_transition"] = (
		transition_evidence.duplicate(true)
	)
	var time_state := day_night_cycle.get_time_state()
	var cove_updated: bool = cove.set_time_state(time_state)
	var resident_evidence: Dictionary = resident.record_day_night_state(
		time_state,
		transition_evidence,
	)
	_last_completed_voyage_evidence["day_night_cove_palette_updated"] = (
		cove_updated
	)
	_last_completed_voyage_evidence["day_night_resident_evidence"] = (
		resident_evidence.duplicate(true)
	)
	_update_day_night_view()


func _go_ashore() -> void:
	if (
		not _player_aboard_ship
		or not ship.is_docked
		or _storage_view_open
		or _storage_release_pending
		or _construction_view_open
		or _construction_release_pending
		or _trade_view_open
		or _trade_release_pending
		or _journal_view_open
		or _journal_release_pending
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
	if (
		_player_shore_id == TradeContact.COVE_SHORE_ID
		and _trade_cove_docked
		and _trade_bought_lot_count > _trade_sold_lot_count
	):
		_trade_cove_ashore = true
		_trade_persistence_holds = _trade_purchase_state_persists()
	_player_near_ship_return = true
	ship.set_captain_aboard(false)
	player.go_ashore(
		definition["shore_position"],
		_player_shore_id,
		definition["shore_region"],
	)
	if _player_shore_id == "cove" and story_clue.is_fragment_acquired():
		story_clue.record_return_to_cove(
			ship.get_cargo_lots(),
			cove_storage.get_cargo_lots(),
		)
		_save_story_clue_persistence("COVE_RETURN_AUTOSAVE")
		_sync_story_clue_chart()
	controls_help.text = WALKING_CONTROLS_TEXT
	_capture_damage_checkpoint("ASHORE")
	_capture_repair_checkpoint("ASHORE")
	_update_interaction_prompt()


func _return_to_ship() -> void:
	if (
		_player_shore_id.is_empty()
		or not _player_near_ship_return
		or _storage_view_open
		or _storage_release_pending
		or _construction_view_open
		or _construction_release_pending
		or _trade_view_open
		or _trade_release_pending
		or _journal_view_open
		or _journal_release_pending
	):
		return
	if not ship.is_docked or ship.current_dock_id != _player_shore_id:
		return

	var returning_shore_id := _player_shore_id
	if returning_shore_id == "cove":
		if not _prepare_ship_module_for_cove_departure():
			_update_interaction_prompt()
			return
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
	if returning_shore_id == "island":
		ruin_exploration.record_return_to_ship(ship.get_cargo_lots())
	if (
		returning_shore_id == TradeContact.PORT_SHORE_ID
		and _trade_bought_lot_count > _trade_sold_lot_count
	):
		_trade_returned_to_ship_at_port = true
		_trade_persistence_holds = _trade_purchase_state_persists()
	_last_ship_docked = true
	controls_help.text = DOCKED_CONTROLS_TEXT
	_capture_damage_checkpoint("RETURN")
	_capture_repair_checkpoint("RETURN")
	_update_interaction_prompt()


func _start_dialogue() -> void:
	if (
		_storage_view_open
		or _storage_release_pending
		or _construction_view_open
		or _construction_release_pending
		or _trade_view_open
		or _trade_release_pending
		or _journal_view_open
		or _journal_release_pending
	):
		return
	var normal_dialogue := _get_resident_dialogue()
	var talk_evidence: Dictionary = resident.begin_talk(
		normal_dialogue,
		_get_request_state_name(),
	)
	if not bool(talk_evidence.get("success", false)):
		return
	_dialogue_lines = talk_evidence["dialogue_lines"]
	_dialogue_kind = String(talk_evidence["dialogue_kind"])

	if (
		_dialogue_kind == CoveResident.NORMAL_DIALOGUE_KIND
		and _request_state == RequestState.AVAILABLE
	):
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
	var finished_request := (
		_dialogue_kind == CoveResident.NORMAL_DIALOGUE_KIND
		and _request_state == RequestState.GOAL_COMPLETE
	)
	resident.finish_talk(_get_request_state_name())
	_dialogue_open = false
	_dialogue_line_index = -1
	_dialogue_lines = PackedStringArray()
	_dialogue_kind = ""
	player.movement_enabled = true
	dialogue_box.hide()
	if finished_request:
		_request_state = RequestState.COMPLETE
		var relationship_evidence: Dictionary = (
			resident.complete_relationship_from_request(
				REQUEST_TITLE,
				"GOAL_COMPLETE",
				"COMPLETE",
			)
		)
		if bool(relationship_evidence.get("success", false)):
			ruin_exploration.award_exploration_tool_from_request(
				REQUEST_TITLE,
				"GOAL_COMPLETE",
				"COMPLETE",
				ship.get_cargo_lots(),
				money,
			)
		else:
			_request_state = RequestState.GOAL_COMPLETE
		_update_request_view()
	_update_relationship_view()
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


func _get_request_state_name() -> String:
	return RequestState.keys()[_request_state]


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
			var resident_state: Dictionary = resident.get_playtest_state()
			request_goal.text = "Dock inspected · Received RUIN PRY BAR\n%s" % (
				resident_state["relationship_result_text"]
			)


func _update_relationship_view() -> void:
	var resident_state: Dictionary = resident.get_playtest_state()
	relationship_details.text = "MARA RELATIONSHIP · %d" % int(
		resident_state["relationship_value"]
	)
	relationship_view.show()


func _update_day_night_view() -> void:
	var time_state := day_night_cycle.get_time_state()
	cove_time_title.text = "COVE TIME · %s" % time_state
	cove_time_status.text = resident.get_night_scene_status_text()
	var player_at_cove := (
		not _player_aboard_ship
		and not _player_on_target_deck
		and (_player_shore_id.is_empty() or _player_shore_id == "cove")
	)
	if player_at_cove:
		cove_time_view.show()
	else:
		cove_time_view.hide()


func save_relationship_progress() -> Dictionary:
	var evidence: Dictionary = resident.save_relationship_progress(
		"PUBLIC_GAME_SAVE"
	)
	_update_relationship_view()
	return evidence


func load_relationship_progress() -> Dictionary:
	var evidence: Dictionary = resident.load_relationship_progress(
		"PUBLIC_GAME_LOAD"
	)
	_update_relationship_view()
	_update_request_view()
	return evidence


func inspect_relationship_progress_save() -> Dictionary:
	return resident.inspect_relationship_save()


func reset_relationship_progress_runtime_for_mcp() -> Dictionary:
	var evidence: Dictionary = resident.reset_relationship_runtime_for_mcp()
	_update_relationship_view()
	_update_request_view()
	return evidence


func cleanup_relationship_progress_for_mcp() -> Dictionary:
	var evidence: Dictionary = resident.cleanup_relationship_save_for_mcp()
	_update_relationship_view()
	_update_request_view()
	return evidence


func _update_interaction_prompt() -> void:
	if _player_on_target_deck:
		if _prize_actions.screen_open:
			interaction_prompt.hide()
		elif _player_near_boarding_return:
			interaction_prompt.text = "[E] RETURN TO PLAYER SHIP"
			interaction_prompt.show()
		else:
			interaction_prompt.hide()
		return
	if (
		_defeat_recovery.is_result_open()
		or _defeat_recovery.is_release_guard_pending()
		or _dialogue_open
		or waypoint_display.chart_visible
		or _chart_release_pending
		or _cargo_choice_open
		or _cargo_choice_release_pending
		or _storage_view_open
		or _storage_release_pending
		or _construction_view_open
		or _construction_release_pending
		or _trade_view_open
		or _trade_release_pending
		or _journal_view_open
		or _journal_release_pending
		or story_clue.is_interaction_release_pending()
		or ruin_exploration.is_transition_release_pending()
		or _target_inspection_view_open
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
		elif _can_board_nearby_target():
			interaction_prompt.text = "[E] BOARD %s" % (
				_near_boarding_target.display_name
			)
			interaction_prompt.show()
		elif _can_inspect_nearby_target():
			interaction_prompt.text = "[E] INSPECT %s" % (
				_near_inspection_target.display_name
			)
			interaction_prompt.show()
		elif not fishing_area.get_interaction_prompt().is_empty():
			interaction_prompt.text = fishing_area.get_interaction_prompt()
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

	var story_prompt := story_clue.get_interaction_prompt()
	if not story_prompt.is_empty():
		interaction_prompt.text = story_prompt
		interaction_prompt.show()
		return

	var ruin_prompt := ruin_exploration.get_interaction_prompt()
	if not ruin_prompt.is_empty():
		interaction_prompt.text = ruin_prompt
		interaction_prompt.show()
		return

	if not _player_shore_id.is_empty() and _player_near_ship_return:
		interaction_prompt.text = (
			"SHIP NEEDS A MODULE · USE THE COVE BENCH"
			if (
				_player_shore_id == "cove"
				and not ship_module_loadout.has_pending_selection()
			)
			else "[E] RETURN TO SHIP"
		)
		interaction_prompt.show()
		return

	if _can_open_trade_contact():
		interaction_prompt.text = "[E] TRADE WITH %s" % (
			_get_near_trade_contact().get_display_name()
		)
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

	if _can_open_ship_module_bench():
		interaction_prompt.text = ship_module_loadout.get_interaction_prompt()
		interaction_prompt.show()
		return

	if _player_near_resident:
		interaction_prompt.text = "[E] TALK TO %s" % resident.display_name.to_upper()
		interaction_prompt.show()
		return

	if _player_near_ship_entry:
		interaction_prompt.text = (
			"SHIP NEEDS A MODULE · USE THE COVE BENCH"
			if not ship_module_loadout.has_pending_selection()
			else "[E] ENTER SHIP"
		)
		interaction_prompt.show()
		return

	if _player_near_sign:
		interaction_prompt.text = "[E] READ SIGN"
		interaction_prompt.show()
		return

	interaction_prompt.hide()


func save_story_clue_persistence() -> Dictionary:
	return _save_story_clue_persistence("PUBLIC_GAME_SAVE")


func load_story_clue_persistence() -> Dictionary:
	return _load_story_clue_persistence("PUBLIC_GAME_LOAD")


func cleanup_story_clue_persistence_for_mcp() -> Dictionary:
	var physical_before := _get_story_fragment_physical_state()
	var story_state_before: Dictionary = story_clue.get_playtest_state()
	var ship_before: Array[String] = ship.get_cargo_lots()
	var storage_before: Array[String] = cove_storage.get_storage_slots()
	var file_before: Dictionary = story_clue.inspect_persistence_file()
	var save_file_existed_before := FileAccess.file_exists(
		StoryClueState.SAVE_PATH
	)
	var chart_before: Dictionary = waypoint_display.get_playtest_state()
	var global_state_before_cleanup: Dictionary = get_playtest_state()
	var global_story_cargo_accounting_before: Dictionary = (
		global_state_before_cleanup["story_cargo_accounting"]
	)
	var last_load_evidence: Dictionary = (
		story_state_before["last_load_evidence"]
	)
	var last_load_payload: Dictionary = last_load_evidence.get(
		"payload",
		{},
	)
	var valid_persisted_absent_load_case := (
		bool(story_state_before["fragment_acquired"])
		and int(physical_before["cargo_fragment_count"]) == 0
		and int(physical_before["total_physical_fragment_count"]) == 0
		and int(story_state_before["persisted_fragment_absent_count"]) == 1
		and not bool(story_state_before["fragment_in_cargo_at_save"])
		and int(story_state_before["load_count"]) > 0
		and bool(last_load_evidence.get("success", false))
		and not bool(last_load_payload.get(
			"fragment_in_existing_cargo",
			true,
		))
	)
	if bool(physical_before["pending_fragment_transaction"]):
		var pending_physical_after := _get_story_fragment_physical_state()
		var pending_story_state_after := story_clue.get_playtest_state()
		var pending_file_after := story_clue.inspect_persistence_file()
		var pending_chart_after := waypoint_display.get_playtest_state()
		_last_story_cleanup_atomic_evidence = {
			"success": false,
			"result": "STORY CLUE CLEANUP DENIED",
			"reason": "PENDING_FRAGMENT_TRANSACTION",
			"physical_before": physical_before,
			"physical_after": pending_physical_after,
			"state_unchanged": (
				physical_before == pending_physical_after
				and story_state_before == pending_story_state_after
				and file_before == pending_file_after
				and ship_before == ship.get_cargo_lots()
				and storage_before == cove_storage.get_storage_slots()
				and chart_before == pending_chart_after
			),
			"file_before": file_before,
			"file_after": pending_file_after,
			"file_unchanged": file_before == pending_file_after,
			"save_file_existed_before": save_file_existed_before,
			"save_file_exists_after": FileAccess.file_exists(
				StoryClueState.SAVE_PATH
			),
			"save_file_unchanged": (
				save_file_existed_before
					== FileAccess.file_exists(StoryClueState.SAVE_PATH)
			),
			"ship_cargo_unchanged": ship_before == ship.get_cargo_lots(),
			"storage_cargo_unchanged": (
				storage_before == cove_storage.get_storage_slots()
			),
			"chart_unchanged": chart_before == pending_chart_after,
			"pending_transaction_rejected": true,
			"irreversible_change_started": false,
			"ship_fragment_coverage": true,
			"cove_storage_fragment_coverage": true,
		}
		return _last_story_cleanup_atomic_evidence.duplicate(true)

	var unsupported_fragment_owner_or_removal := (
		bool(story_state_before["fragment_acquired"])
		and int(physical_before["cargo_fragment_count"]) == 0
		and not valid_persisted_absent_load_case
	)
	if unsupported_fragment_owner_or_removal:
		var unsupported_physical_after := _get_story_fragment_physical_state()
		var unsupported_story_state_after := story_clue.get_playtest_state()
		var unsupported_file_after := story_clue.inspect_persistence_file()
		var unsupported_chart_after := waypoint_display.get_playtest_state()
		_last_story_cleanup_atomic_evidence = {
			"success": false,
			"result": "STORY CLUE CLEANUP DENIED",
			"reason": "UNSUPPORTED_FRAGMENT_OWNER_OR_REMOVAL",
			"unsupported_fragment_owner_or_removal_rejected": true,
			"valid_persisted_absent_load_case": false,
			"irreversible_change_started": false,
			"physical_before": physical_before,
			"physical_after": unsupported_physical_after,
			"story_state_before": story_state_before,
			"story_state_after": unsupported_story_state_after,
			"story_state_unchanged": (
				story_state_before == unsupported_story_state_after
			),
			"file_before": file_before,
			"file_after": unsupported_file_after,
			"file_unchanged": file_before == unsupported_file_after,
			"save_file_existed_before": save_file_existed_before,
			"save_file_exists_after": FileAccess.file_exists(
				StoryClueState.SAVE_PATH
			),
			"save_file_unchanged": (
				save_file_existed_before
					== FileAccess.file_exists(StoryClueState.SAVE_PATH)
			),
			"ship_cargo_before": ship_before,
			"ship_cargo_after": ship.get_cargo_lots(),
			"ship_cargo_unchanged": ship_before == ship.get_cargo_lots(),
			"storage_cargo_before": storage_before,
			"storage_cargo_after": cove_storage.get_storage_slots(),
			"storage_cargo_unchanged": (
				storage_before == cove_storage.get_storage_slots()
			),
			"chart_before": chart_before,
			"chart_after": unsupported_chart_after,
			"chart_unchanged": chart_before == unsupported_chart_after,
			"global_story_cargo_accounting_before": (
				global_story_cargo_accounting_before.duplicate(true)
			),
			"state_file_cargo_and_chart_unchanged": (
				physical_before == unsupported_physical_after
				and story_state_before == unsupported_story_state_after
				and file_before == unsupported_file_after
				and ship_before == ship.get_cargo_lots()
				and storage_before == cove_storage.get_storage_slots()
				and chart_before == unsupported_chart_after
			),
			"state_unchanged": (
				physical_before == unsupported_physical_after
				and story_state_before == unsupported_story_state_after
				and file_before == unsupported_file_after
				and ship_before == ship.get_cargo_lots()
				and storage_before == cove_storage.get_storage_slots()
				and chart_before == unsupported_chart_after
			),
			"ship_fragment_coverage": true,
			"cove_storage_fragment_coverage": true,
		}
		return _last_story_cleanup_atomic_evidence.duplicate(true)

	var predicted_physical_delta := (
		1
		- int(physical_before["world_fragment_count"])
		- int(physical_before["cargo_fragment_count"])
	)
	var predicted_accounted_total_after_cleanup := (
		int(global_story_cargo_accounting_before["accounted_total"])
		+ predicted_physical_delta
		- int(story_state_before["persisted_fragment_absent_count"])
	)
	var predicted_expected_total_after_cleanup := int(
		global_story_cargo_accounting_before["expected_total"]
	)
	var cleanup_accounting_preflight_holds := (
		predicted_accounted_total_after_cleanup
			== predicted_expected_total_after_cleanup
	)
	if not cleanup_accounting_preflight_holds:
		var preflight_physical_after := _get_story_fragment_physical_state()
		var preflight_story_state_after := story_clue.get_playtest_state()
		var preflight_file_after := story_clue.inspect_persistence_file()
		var preflight_chart_after := waypoint_display.get_playtest_state()
		_last_story_cleanup_atomic_evidence = {
			"success": false,
			"result": "STORY CLUE CLEANUP DENIED",
			"reason": "GLOBAL_STORY_CARGO_ACCOUNTING_PREFLIGHT_FAILED",
			"irreversible_change_started": false,
			"valid_persisted_absent_load_case": (
				valid_persisted_absent_load_case
			),
			"physical_before": physical_before,
			"physical_after": preflight_physical_after,
			"save_file_existed_before": save_file_existed_before,
			"save_file_exists_after": FileAccess.file_exists(
				StoryClueState.SAVE_PATH
			),
			"save_file_unchanged": (
				save_file_existed_before
					== FileAccess.file_exists(StoryClueState.SAVE_PATH)
			),
			"global_story_cargo_accounting_before": (
				global_story_cargo_accounting_before.duplicate(true)
			),
			"predicted_physical_delta": predicted_physical_delta,
			"predicted_accounted_total_after_cleanup": (
				predicted_accounted_total_after_cleanup
			),
			"predicted_expected_total_after_cleanup": (
				predicted_expected_total_after_cleanup
			),
			"cleanup_accounting_preflight_holds": false,
			"state_file_cargo_and_chart_unchanged": (
				physical_before == preflight_physical_after
				and story_state_before == preflight_story_state_after
				and file_before == preflight_file_after
				and ship_before == ship.get_cargo_lots()
				and storage_before == cove_storage.get_storage_slots()
				and chart_before == preflight_chart_after
			),
			"state_unchanged": (
				physical_before == preflight_physical_after
				and story_state_before == preflight_story_state_after
				and file_before == preflight_file_after
				and ship_before == ship.get_cargo_lots()
				and storage_before == cove_storage.get_storage_slots()
				and chart_before == preflight_chart_after
			),
		}
		return _last_story_cleanup_atomic_evidence.duplicate(true)

	var ship_removals: Array[Dictionary] = []
	var storage_removals: Array[Dictionary] = []
	for slot_index in range(ship_before.size() - 1, -1, -1):
		if ship_before[slot_index] != StoryClueState.FRAGMENT_LOT_NAME:
			continue
		var removed_ship_lot: String = ship.remove_cargo_slot_for_storage(
			slot_index
		)
		if removed_ship_lot == StoryClueState.FRAGMENT_LOT_NAME:
			ship_removals.append({
				"slot_index": slot_index,
				"lot_name": removed_ship_lot,
			})
	for slot_index in range(storage_before.size()):
		if storage_before[slot_index] != StoryClueState.FRAGMENT_LOT_NAME:
			continue
		var removed_storage_lot := cove_storage.remove_cargo_slot(slot_index)
		if removed_storage_lot == StoryClueState.FRAGMENT_LOT_NAME:
			storage_removals.append({
				"slot_index": slot_index,
				"lot_name": removed_storage_lot,
			})
	var cargo_clear := _count_story_fragments_in_cargo_owners() == 0
	if not cargo_clear:
		var removal_rollback_holds := _restore_story_fragment_cargo_removals(
			ship_removals,
			storage_removals,
		)
		_last_story_cleanup_atomic_evidence = {
			"success": false,
			"result": "STORY CLUE CLEANUP DENIED",
			"reason": "CARGO_FRAGMENT_REMOVE_FAILED",
			"physical_before": physical_before,
			"physical_after": _get_story_fragment_physical_state(),
			"cargo_rollback_holds": removal_rollback_holds,
			"irreversible_change_started": false,
			"ship_fragment_coverage": true,
			"cove_storage_fragment_coverage": true,
		}
		return _last_story_cleanup_atomic_evidence.duplicate(true)

	var owner_evidence := story_clue.cleanup_persistence_for_mcp()
	if not bool(owner_evidence["success"]):
		var owner_failure_rollback_holds := (
			_restore_story_fragment_cargo_removals(
				ship_removals,
				storage_removals,
			)
		)
		_last_story_cleanup_atomic_evidence = {
			"success": false,
			"result": "STORY CLUE CLEANUP FAILED",
			"reason": owner_evidence["result"],
			"owner_evidence": owner_evidence,
			"physical_before": physical_before,
			"physical_after": _get_story_fragment_physical_state(),
			"cargo_rollback_holds": owner_failure_rollback_holds,
			"irreversible_change_started": false,
			"ship_fragment_coverage": true,
			"cove_storage_fragment_coverage": true,
		}
		return _last_story_cleanup_atomic_evidence.duplicate(true)

	_sync_story_clue_chart()
	_update_story_clue()
	_update_cargo_view()
	_update_interaction_prompt()
	var physical_after := _get_story_fragment_physical_state()
	var unrelated_ship_cargo_unchanged := (
		_get_non_story_fragment_lots(ship_before)
			== _get_non_story_fragment_lots(ship.get_cargo_lots())
	)
	var unrelated_storage_cargo_unchanged := (
		_get_non_story_fragment_lots(storage_before)
			== _get_non_story_fragment_lots(cove_storage.get_storage_slots())
	)
	var global_state_after_cleanup: Dictionary = get_playtest_state()
	var global_story_cargo_accounting: Dictionary = (
		global_state_after_cleanup["story_cargo_accounting"]
	)
	var replacement_discard_ledger_preserved := bool(
		owner_evidence.get(
			"displaced_cargo_accounting_preserved",
			false,
		)
	)
	var cleanup_invariants_hold := (
		int(physical_after["total_physical_fragment_count"]) == 1
		and int(physical_after["world_fragment_count"]) == 1
		and int(physical_after["cargo_fragment_count"]) == 0
		and unrelated_ship_cargo_unchanged
		and unrelated_storage_cargo_unchanged
		and replacement_discard_ledger_preserved
		and bool(global_story_cargo_accounting["holds"])
	)
	var valid_persisted_absent_cleanup_holds := (
		not valid_persisted_absent_load_case
		or (
			int(physical_before["total_physical_fragment_count"]) == 0
			and int(physical_after["world_fragment_count"]) == 1
			and int(physical_after["cargo_fragment_count"]) == 0
			and int(global_story_cargo_accounting["accounted_total"])
				== predicted_accounted_total_after_cleanup
			and bool(global_story_cargo_accounting["holds"])
		)
	)
	_last_story_cleanup_atomic_evidence = {
		"success": true,
		"result": "PHASE 38 STORY CLUE CLEANUP COMPLETE",
		"reason": "CLEAN",
		"irreversible_change_started": true,
		"irreversible_change_committed": true,
		"postcommit_invariants_hold": cleanup_invariants_hold,
		"cleanup_accounting_preflight_holds": (
			cleanup_accounting_preflight_holds
		),
		"predicted_physical_delta": predicted_physical_delta,
		"predicted_accounted_total_after_cleanup": (
			predicted_accounted_total_after_cleanup
		),
		"predicted_expected_total_after_cleanup": (
			predicted_expected_total_after_cleanup
		),
		"preflight_prediction_matches_actual": (
			int(global_story_cargo_accounting["accounted_total"])
				== predicted_accounted_total_after_cleanup
			and int(global_story_cargo_accounting["expected_total"])
				== predicted_expected_total_after_cleanup
		),
		"valid_persisted_absent_load_case": (
			valid_persisted_absent_load_case
		),
		"valid_persisted_absent_cleanup_observed": (
			valid_persisted_absent_load_case
		),
		"valid_persisted_absent_cleanup_holds": (
			valid_persisted_absent_cleanup_holds
		),
		"owner_evidence": owner_evidence,
		"physical_before": physical_before,
		"physical_after": physical_after,
		"ship_fragment_removal_count": ship_removals.size(),
		"storage_fragment_removal_count": storage_removals.size(),
		"ship_fragment_coverage": true,
		"cove_storage_fragment_coverage": true,
		"pending_transaction_rejected": false,
		"one_physical_fragment_after_cleanup": (
			int(physical_after["total_physical_fragment_count"]) == 1
		),
		"unrelated_ship_cargo_unchanged": unrelated_ship_cargo_unchanged,
		"unrelated_storage_cargo_unchanged": (
			unrelated_storage_cargo_unchanged
		),
		"cargo_accounting_consistent": (
			bool(global_story_cargo_accounting["holds"])
		),
		"global_story_cargo_accounting_after_cleanup": (
			global_story_cargo_accounting.duplicate(true)
		),
		"global_accounted_cargo_total_after_cleanup": (
			global_story_cargo_accounting["accounted_total"]
		),
		"global_expected_cargo_total_after_cleanup": (
			global_story_cargo_accounting["expected_total"]
		),
		"replacement_discard_ledger_preserved": (
			replacement_discard_ledger_preserved
		),
		"replacement_then_cleanup_sequence_observed": bool(
			owner_evidence.get(
				"replacement_then_cleanup_sequence_observed",
				false,
			)
		),
		"replacement_then_cleanup_accounting_holds": (
			bool(owner_evidence.get(
				"replacement_then_cleanup_ledger_holds",
				false,
			))
			and bool(global_story_cargo_accounting["holds"])
		),
	}
	return _last_story_cleanup_atomic_evidence.duplicate(true)


func _save_story_clue_persistence(reason: String) -> Dictionary:
	var at_cove_save_boundary: bool = (
		(_player_shore_id == "cove" and not _player_aboard_ship)
		or (
			ship.is_docked
			and ship.current_dock_id == "cove"
			and _voyage_departure_dock_id.is_empty()
		)
	)
	if not at_cove_save_boundary:
		return {
			"success": false,
			"result": "STORY CLUE SAVE DENIED",
			"reason": "NOT_AT_COVE_SAVE_BOUNDARY",
			"path": StoryClueState.SAVE_PATH,
			"save_reason": reason,
		}
	return story_clue.save_persistence(
		ship.get_cargo_lots(),
		cove_storage.get_cargo_lots(),
		reason,
	)


func _load_story_clue_persistence(reason: String) -> Dictionary:
	var at_safe_load_boundary: bool = (
		reason == "STARTUP"
		or (
			_player_shore_id == "cove"
			and not _player_aboard_ship
		)
		or (
			ship.is_docked
			and ship.current_dock_id == "cove"
			and _voyage_departure_dock_id.is_empty()
		)
	)
	if not at_safe_load_boundary:
		return {
			"success": false,
			"result": "STORY CLUE LOAD DENIED",
			"reason": "UNSAFE_LIVE_RESTORE_BOUNDARY",
			"path": StoryClueState.SAVE_PATH,
			"load_reason": reason,
		}
	var file_inspection := story_clue.inspect_persistence_file()
	var physical_before := _get_story_fragment_physical_state()
	var restoration_attempted := false
	var restoration_added := false
	var restoration_target := "NONE"
	var saved_fragment_expected := false
	if bool(file_inspection["valid"]):
		var payload: Dictionary = file_inspection["payload"]
		saved_fragment_expected = bool(
			payload["fragment_in_existing_cargo"]
		)
	if (
		bool(file_inspection["valid"])
		and saved_fragment_expected
		and int(physical_before["cargo_fragment_count"]) == 0
		and not bool(physical_before["pending_fragment_transaction"])
	):
		if ship.can_keep_cargo_lot():
			restoration_attempted = true
			restoration_target = "SHIP"
			restoration_added = ship.keep_cargo_lot(
				StoryClueState.FRAGMENT_LOT_NAME
			)
		elif cove_storage.can_store_cargo_lot():
			restoration_attempted = true
			restoration_target = "COVE_STORAGE"
			restoration_added = cove_storage.store_cargo_lot(
				StoryClueState.FRAGMENT_LOT_NAME
			)
	var physical_after_add := _get_story_fragment_physical_state()
	var physical_context := {
		"cargo_fragment_count_before": physical_before["cargo_fragment_count"],
		"cargo_fragment_count_after": physical_after_add["cargo_fragment_count"],
		"fragment_found_in_cove_storage": (
			int(physical_before["storage_fragment_count"]) == 1
		),
		"pending_fragment_transaction": (
			physical_before["pending_fragment_transaction"]
		),
		"restoration_attempted": restoration_attempted,
		"restoration_added": restoration_added,
		"restoration_succeeded": restoration_added,
		"restoration_target": restoration_target,
	}
	var evidence := story_clue.load_persistence(reason, physical_context)
	var rollback_holds := true
	if not bool(evidence["success"]) and restoration_added:
		if restoration_target == "SHIP":
			rollback_holds = ship.remove_cargo_lot(
				StoryClueState.FRAGMENT_LOT_NAME
			)
		elif restoration_target == "COVE_STORAGE":
			var storage_slot := cove_storage.get_storage_slots().find(
				StoryClueState.FRAGMENT_LOT_NAME
			)
			rollback_holds = (
				storage_slot >= 0
				and cove_storage.remove_cargo_slot(storage_slot)
					== StoryClueState.FRAGMENT_LOT_NAME
			)
	_sync_story_clue_chart()
	_update_cargo_view()
	var physical_final := _get_story_fragment_physical_state()
	_last_story_load_atomic_evidence = {
		"success": bool(evidence["success"]),
		"result": evidence["result"],
		"reason": evidence["reason"],
		"file_inspection": file_inspection,
		"owner_evidence": evidence,
		"physical_before": physical_before,
		"physical_after_add": physical_after_add,
		"physical_final": physical_final,
		"restoration_attempted": restoration_attempted,
		"restoration_added": restoration_added,
		"restoration_target": restoration_target,
		"existing_fragment_satisfied_load": (
			bool(evidence["success"])
			and int(physical_before["cargo_fragment_count"]) == 1
			and not restoration_added
		),
		"storage_fragment_satisfied_load": (
			bool(evidence["success"])
			and int(physical_before["storage_fragment_count"]) == 1
			and not restoration_added
		),
		"no_slot_rejection": bool(evidence.get(
			"no_slot_rejection",
			false,
		)),
		"failed_add_rolled_back": (
			not restoration_added
			or bool(evidence["success"])
			or rollback_holds
		),
		"one_physical_fragment_after_success": (
			not bool(evidence["success"])
			or (
				saved_fragment_expected
				and int(physical_final["total_physical_fragment_count"])
					== 1
			)
		),
		"expected_physical_fragment_count_after_success": int(
			saved_fragment_expected
		),
		"physical_fragment_count_matches_saved_presence": (
			not bool(evidence["success"])
			or int(physical_final["total_physical_fragment_count"])
				== int(saved_fragment_expected)
		),
		"valid_absent_fragment_load_case_observed": (
			bool(evidence["success"]) and not saved_fragment_expected
		),
		"valid_absent_fragment_load_case_holds": (
			not bool(evidence["success"])
			or saved_fragment_expected
			or (
				int(physical_final["total_physical_fragment_count"]) == 0
				and not restoration_attempted
				and not restoration_added
			)
		),
		"atomic_story_and_physical_commit": (
			(
				bool(evidence["success"])
				and int(physical_final["total_physical_fragment_count"])
					== int(saved_fragment_expected)
			)
			or (
				not bool(evidence["success"])
				and rollback_holds
			)
		),
	}
	return _last_story_load_atomic_evidence.duplicate(true)


func _sync_story_clue_chart() -> void:
	waypoint_display.set_story_clue_content(
		story_clue.get_clue_entries(),
		story_clue.get_location_definition(),
		story_clue.is_story_location_unlocked(),
	)


func _count_story_fragments_in_cargo_owners() -> int:
	return (
		ship.get_cargo_lots().count(StoryClueState.FRAGMENT_LOT_NAME)
		+ cove_storage.count_cargo_lot(StoryClueState.FRAGMENT_LOT_NAME)
	)


func _get_story_fragment_physical_state() -> Dictionary:
	var story_state: Dictionary = story_clue.get_playtest_state()
	var ship_fragment_count: int = ship.get_cargo_lots().count(
		StoryClueState.FRAGMENT_LOT_NAME
	)
	var storage_fragment_count := cove_storage.count_cargo_lot(
		StoryClueState.FRAGMENT_LOT_NAME
	)
	var world_fragment_count := int(story_state["world_fragment_lot_count"])
	var main_pending_fragment_choice := (
		_cargo_choice_open
		and _pending_cargo_source == CARGO_SOURCE_STORY_CLUE
		and _pending_cargo_lot == StoryClueState.FRAGMENT_LOT_NAME
	)
	var owner_pending_fragment_choice := (
		story_clue.has_pending_fragment_choice()
	)
	var pending_fragment_transaction := (
		main_pending_fragment_choice or owner_pending_fragment_choice
	)
	return {
		"ship_fragment_count": ship_fragment_count,
		"storage_fragment_count": storage_fragment_count,
		"cargo_fragment_count": (
			ship_fragment_count + storage_fragment_count
		),
		"world_fragment_count": world_fragment_count,
		"pending_fragment_transaction": pending_fragment_transaction,
		"main_pending_fragment_choice": main_pending_fragment_choice,
		"owner_pending_fragment_choice": owner_pending_fragment_choice,
		"pending_is_same_world_fragment": pending_fragment_transaction,
		"total_physical_fragment_count": (
			ship_fragment_count
			+ storage_fragment_count
			+ world_fragment_count
		),
	}


func _restore_story_fragment_cargo_removals(
	ship_removals: Array[Dictionary],
	storage_removals: Array[Dictionary],
) -> bool:
	var restored_all := true
	for removal_index in range(ship_removals.size() - 1, -1, -1):
		var removal: Dictionary = ship_removals[removal_index]
		restored_all = (
			ship.restore_cargo_slot_from_storage(
				int(removal["slot_index"]),
				String(removal["lot_name"]),
			)
			and restored_all
		)
	for removal in storage_removals:
		restored_all = (
			cove_storage.restore_cargo_slot(
				int(removal["slot_index"]),
				String(removal["lot_name"]),
			)
			and restored_all
		)
	return restored_all


func _get_non_story_fragment_lots(cargo_lots: Array[String]) -> Array[String]:
	var other_lots: Array[String] = []
	for lot_name in cargo_lots:
		if lot_name.is_empty() or lot_name == StoryClueState.FRAGMENT_LOT_NAME:
			continue
		other_lots.append(lot_name)
	return other_lots


func save_world_heat_persistence() -> Dictionary:
	return _save_world_heat_persistence("PUBLIC_GAME_SAVE")


func load_world_heat_persistence() -> Dictionary:
	return _load_world_heat_persistence("PUBLIC_GAME_LOAD")


func cleanup_world_heat_persistence_for_mcp() -> Dictionary:
	var file_existed_before := FileAccess.file_exists(HEAT_PERSISTENCE_PATH)
	var remove_error := OK
	if file_existed_before:
		remove_error = DirAccess.remove_absolute(
			ProjectSettings.globalize_path(HEAT_PERSISTENCE_PATH)
		)
	var file_exists_after := FileAccess.file_exists(HEAT_PERSISTENCE_PATH)
	var success := remove_error == OK and not file_exists_after
	if success and file_existed_before:
		_heat_persistence_cleanup_count += 1
	_last_heat_file_cleanup_evidence = {
		"success": success,
		"result": (
			"PHASE 30 HEAT FILE REMOVED"
			if success and file_existed_before
			else (
				"PHASE 30 HEAT FILE ALREADY ABSENT"
				if success
				else "PHASE 30 HEAT FILE REMOVE FAILED"
			)
		),
		"path": HEAT_PERSISTENCE_PATH,
		"only_exact_heat_file_targeted": true,
		"file_existed_before": file_existed_before,
		"file_exists_after": file_exists_after,
		"remove_error": remove_error,
		"cleanup_count": _heat_persistence_cleanup_count,
	}
	return _last_heat_file_cleanup_evidence.duplicate(true)


func _save_world_heat_persistence(reason: String) -> Dictionary:
	var heat_snapshot: Dictionary = _world_heat.get_save_data()
	var stable_dock: bool = (
		ship.is_docked
		and not ship.current_dock_id.is_empty()
		and _voyage_departure_dock_id.is_empty()
		and not bool(heat_snapshot["peaceful_attack_in_current_voyage"])
	)
	if not stable_dock:
		_last_heat_file_save_evidence = {
			"success": false,
			"result": "WORLD HEAT FILE SAVE DENIED",
			"reason": "NOT_AT_STABLE_POST_VOYAGE_DOCK",
			"path": HEAT_PERSISTENCE_PATH,
			"save_reason": reason,
			"state_before": heat_snapshot,
			"file_exists_after": FileAccess.file_exists(
				HEAT_PERSISTENCE_PATH
			),
			"save_count": _heat_persistence_save_count,
		}
		return _last_heat_file_save_evidence.duplicate(true)

	var payload := {
		"format": HEAT_PERSISTENCE_FORMAT,
		"version": HEAT_PERSISTENCE_VERSION,
		"saved_at_stable_dock": true,
		"saved_completed_voyage": completed_voyages,
		"saved_dock_id": ship.current_dock_id,
		"world_heat": heat_snapshot.duplicate(true),
	}
	var validation: Dictionary = _validate_heat_persistence_payload(payload)
	if not bool(validation["valid"]):
		_last_heat_file_save_evidence = {
			"success": false,
			"result": "WORLD HEAT FILE SAVE DENIED",
			"reason": validation["reason"],
			"path": HEAT_PERSISTENCE_PATH,
			"save_reason": reason,
			"state_before": heat_snapshot,
			"file_exists_after": FileAccess.file_exists(
				HEAT_PERSISTENCE_PATH
			),
			"save_count": _heat_persistence_save_count,
		}
		return _last_heat_file_save_evidence.duplicate(true)

	var config := ConfigFile.new()
	config.set_value(
		HEAT_PERSISTENCE_SECTION,
		HEAT_PERSISTENCE_KEY,
		payload.duplicate(true),
	)
	var save_error := config.save(HEAT_PERSISTENCE_PATH)
	var verification: Dictionary = _read_heat_persistence_file()
	var success := save_error == OK and bool(verification["valid"])
	if success:
		_heat_persistence_save_count += 1
		_last_heat_persistence_payload = payload.duplicate(true)
	_last_heat_file_save_evidence = {
		"success": success,
		"result": (
			"WORLD HEAT FILE SAVED"
			if success
			else "WORLD HEAT FILE SAVE FAILED"
		),
		"reason": (
			"SAVED"
			if success
			else (
				"CONFIG_SAVE_ERROR_%d" % save_error
				if save_error != OK
				else verification["reason"]
			)
		),
		"path": HEAT_PERSISTENCE_PATH,
		"save_reason": reason,
		"save_error": save_error,
		"file_exists_after": FileAccess.file_exists(HEAT_PERSISTENCE_PATH),
		"written_payload": payload.duplicate(true),
		"verified_payload": verification.get("payload", {}).duplicate(true),
		"full_file_validation": verification.duplicate(true),
		"stable_post_voyage_dock": stable_dock,
		"world_heat_at_save": heat_snapshot["current_heat"],
		"peaceful_target_ids_at_save": (
			(heat_snapshot["peaceful_target_ids_hit"] as Array).duplicate()
		),
		"current_voyage_attack_flag_at_save": (
			heat_snapshot["peaceful_attack_in_current_voyage"]
		),
		"saved_completed_voyage": completed_voyages,
		"saved_dock_id": ship.current_dock_id,
		"save_count": _heat_persistence_save_count,
		"external_save_file_count": (
			1 if FileAccess.file_exists(HEAT_PERSISTENCE_PATH) else 0
		),
	}
	return _last_heat_file_save_evidence.duplicate(true)


func _load_world_heat_persistence(reason: String) -> Dictionary:
	if reason == "STARTUP":
		_heat_persistence_startup_load_attempted = true
	var heat_before: Dictionary = _world_heat.get_save_data()
	var unrelated_before: Dictionary = _capture_non_heat_persistence_state()
	var safe_restore_boundary: bool = (
		reason == "STARTUP"
		or (
			ship.is_docked
			and not ship.current_dock_id.is_empty()
			and _voyage_departure_dock_id.is_empty()
			and not bool(heat_before[
				"peaceful_attack_in_current_voyage"
			])
		)
	)
	if not safe_restore_boundary:
		_last_heat_file_load_evidence = {
			"success": false,
			"result": "WORLD HEAT FILE LOAD DENIED",
			"reason": "UNSAFE_LIVE_RESTORE_BOUNDARY",
			"path": HEAT_PERSISTENCE_PATH,
			"load_reason": reason,
			"world_heat_before": heat_before,
			"world_heat_after": _world_heat.get_save_data(),
			"world_heat_unchanged": heat_before == _world_heat.get_save_data(),
			"unrelated_state_before": unrelated_before,
			"unrelated_state_after": _capture_non_heat_persistence_state(),
			"unrelated_state_unchanged": (
				unrelated_before == _capture_non_heat_persistence_state()
			),
			"load_count": _heat_persistence_load_count,
		}
		return _last_heat_file_load_evidence.duplicate(true)
	var file_read: Dictionary = _read_heat_persistence_file()
	if not bool(file_read["valid"]):
		_last_heat_file_load_evidence = {
			"success": false,
			"result": "WORLD HEAT FILE NOT LOADED",
			"reason": file_read["reason"],
			"path": HEAT_PERSISTENCE_PATH,
			"load_reason": reason,
			"file_read": file_read.duplicate(true),
			"world_heat_before": heat_before,
			"world_heat_after": _world_heat.get_save_data(),
			"world_heat_unchanged": heat_before == _world_heat.get_save_data(),
			"unrelated_state_before": unrelated_before,
			"unrelated_state_after": _capture_non_heat_persistence_state(),
			"unrelated_state_unchanged": (
				unrelated_before == _capture_non_heat_persistence_state()
			),
			"load_count": _heat_persistence_load_count,
		}
		return _last_heat_file_load_evidence.duplicate(true)

	var payload: Dictionary = file_read["payload"]
	var saved_heat: Dictionary = payload["world_heat"]
	var heat_load_evidence: Dictionary = _world_heat.load_save_data(
		saved_heat,
		_get_known_peaceful_target_ids(),
		completed_voyages,
	)
	if not bool(heat_load_evidence["success"]):
		_last_heat_file_load_evidence = {
			"success": false,
			"result": "WORLD HEAT FILE LOAD DENIED",
			"reason": heat_load_evidence["reason"],
			"path": HEAT_PERSISTENCE_PATH,
			"load_reason": reason,
			"file_read": file_read.duplicate(true),
			"world_heat_before": heat_before,
			"world_heat_after": _world_heat.get_save_data(),
			"world_heat_owner_load_evidence": heat_load_evidence,
			"world_heat_unchanged": heat_before == _world_heat.get_save_data(),
			"unrelated_state_before": unrelated_before,
			"unrelated_state_after": _capture_non_heat_persistence_state(),
			"unrelated_state_unchanged": (
				unrelated_before == _capture_non_heat_persistence_state()
			),
			"load_count": _heat_persistence_load_count,
		}
		return _last_heat_file_load_evidence.duplicate(true)

	_heat_persistence_load_count += 1
	if reason == "STARTUP":
		_heat_persistence_startup_restored = true
	_last_heat_persistence_payload = payload.duplicate(true)
	var loaded_heat: Dictionary = _world_heat.get_save_data()
	var loaded_first_hit_previews: Dictionary = {}
	var loaded_first_hit_identity_blocks_duplicate_heat := true
	for target in inspection_targets:
		if not (loaded_heat["peaceful_target_ids_hit"] as Array).has(
			target.target_id
		):
			continue
		var preview: Dictionary = _world_heat.get_attack_preview(
			target.target_id,
			target.peaceful,
			target.estimated_heat_cost,
		)
		loaded_first_hit_previews[target.target_id] = preview.duplicate(true)
		loaded_first_hit_identity_blocks_duplicate_heat = (
			loaded_first_hit_identity_blocks_duplicate_heat
			and bool(preview["first_hit_already_recorded"])
			and int(preview["estimated_heat_increase"]) == 0
		)
	var unrelated_after: Dictionary = _capture_non_heat_persistence_state()
	_last_heat_file_load_evidence = {
		"success": true,
		"result": "WORLD HEAT FILE LOADED",
		"reason": "LOADED_AND_REBASED",
		"path": HEAT_PERSISTENCE_PATH,
		"load_reason": reason,
		"file_read": file_read.duplicate(true),
		"requested_payload": payload.duplicate(true),
		"world_heat_before": heat_before,
		"world_heat_loaded": loaded_heat,
		"world_heat_owner_load_evidence": heat_load_evidence.duplicate(true),
		"heat_value_restored": (
			loaded_heat["current_heat"] == saved_heat["current_heat"]
		),
		"first_hit_identity_restored": (
			loaded_heat["peaceful_target_ids_hit"]
				== saved_heat["peaceful_target_ids_hit"]
		),
		"loaded_first_hit_previews": loaded_first_hit_previews,
		"loaded_first_hit_identity_blocks_duplicate_heat": (
			loaded_first_hit_identity_blocks_duplicate_heat
		),
		"current_voyage_attack_flag_restored": (
			loaded_heat["peaceful_attack_in_current_voyage"]
				== saved_heat["peaceful_attack_in_current_voyage"]
		),
		"saved_voyage_cursor": saved_heat["last_completed_voyage"],
		"rebased_voyage_cursor": loaded_heat["last_completed_voyage"],
		"voyage_cursor_rebased_to_current_world": (
			loaded_heat["last_completed_voyage"] == completed_voyages
		),
		"rebased_snapshot_equality_holds": (
			heat_load_evidence["rebased_snapshot_equality_holds"]
		),
		"heat_accounting_holds_after_load": (
			loaded_heat["current_heat"]
				== loaded_heat["total_heat_added"]
					- loaded_heat["total_heat_removed_by_voyage_decay"]
		),
		"unrelated_state_before": unrelated_before,
		"unrelated_state_after": unrelated_after,
		"unrelated_state_unchanged": unrelated_before == unrelated_after,
		"completed_voyages_not_loaded_from_heat_file": true,
		"departure_state_not_loaded_from_heat_file": true,
		"load_count": _heat_persistence_load_count,
		"startup_restored": _heat_persistence_startup_restored,
		"external_save_file_count": 1,
	}
	_update_heat_view()
	return _last_heat_file_load_evidence.duplicate(true)


func _read_heat_persistence_file() -> Dictionary:
	if not FileAccess.file_exists(HEAT_PERSISTENCE_PATH):
		return {
			"valid": false,
			"reason": "FILE_NOT_FOUND",
			"path": HEAT_PERSISTENCE_PATH,
			"file_found": false,
			"load_error": ERR_FILE_NOT_FOUND,
		}
	var config := ConfigFile.new()
	var load_error := config.load(HEAT_PERSISTENCE_PATH)
	if load_error != OK:
		return {
			"valid": false,
			"reason": "CONFIG_LOAD_ERROR_%d" % load_error,
			"path": HEAT_PERSISTENCE_PATH,
			"file_found": true,
			"load_error": load_error,
		}
	var sections := config.get_sections()
	if sections.size() != 1 or sections[0] != HEAT_PERSISTENCE_SECTION:
		return {
			"valid": false,
			"reason": "INVALID_CONFIG_SECTIONS",
			"path": HEAT_PERSISTENCE_PATH,
			"file_found": true,
			"load_error": load_error,
		}
	var section_keys := config.get_section_keys(HEAT_PERSISTENCE_SECTION)
	if section_keys.size() != 1 or section_keys[0] != HEAT_PERSISTENCE_KEY:
		return {
			"valid": false,
			"reason": "INVALID_CONFIG_KEYS",
			"path": HEAT_PERSISTENCE_PATH,
			"file_found": true,
			"load_error": load_error,
		}
	var payload_value = config.get_value(
		HEAT_PERSISTENCE_SECTION,
		HEAT_PERSISTENCE_KEY,
	)
	if typeof(payload_value) != TYPE_DICTIONARY:
		return {
			"valid": false,
			"reason": "INVALID_PAYLOAD_TYPE",
			"path": HEAT_PERSISTENCE_PATH,
			"file_found": true,
			"load_error": load_error,
		}
	var payload: Dictionary = payload_value
	var validation: Dictionary = _validate_heat_persistence_payload(payload)
	return {
		"valid": validation["valid"],
		"reason": validation["reason"],
		"path": HEAT_PERSISTENCE_PATH,
		"file_found": true,
		"load_error": load_error,
		"payload": payload.duplicate(true),
		"payload_validation": validation.duplicate(true),
		"exact_section_and_key_contract": true,
	}


func _validate_heat_persistence_payload(payload: Dictionary) -> Dictionary:
	var required_keys := [
		"format",
		"version",
		"saved_at_stable_dock",
		"saved_completed_voyage",
		"saved_dock_id",
		"world_heat",
	]
	if payload.size() != required_keys.size():
		return {"valid": false, "reason": "UNEXPECTED_ROOT_FIELD_COUNT"}
	for required_key in required_keys:
		if not payload.has(required_key):
			return {
				"valid": false,
				"reason": "MISSING_%s" % String(required_key).to_upper(),
			}
	if typeof(payload["format"]) != TYPE_STRING:
		return {"valid": false, "reason": "INVALID_TYPE_FORMAT"}
	if typeof(payload["version"]) != TYPE_INT:
		return {"valid": false, "reason": "INVALID_TYPE_VERSION"}
	if typeof(payload["saved_at_stable_dock"]) != TYPE_BOOL:
		return {"valid": false, "reason": "INVALID_TYPE_STABLE_DOCK"}
	if typeof(payload["saved_completed_voyage"]) != TYPE_INT:
		return {"valid": false, "reason": "INVALID_TYPE_SAVED_VOYAGE"}
	if typeof(payload["saved_dock_id"]) != TYPE_STRING:
		return {"valid": false, "reason": "INVALID_TYPE_SAVED_DOCK_ID"}
	if typeof(payload["world_heat"]) != TYPE_DICTIONARY:
		return {"valid": false, "reason": "INVALID_TYPE_WORLD_HEAT"}
	if payload["format"] != HEAT_PERSISTENCE_FORMAT:
		return {"valid": false, "reason": "INVALID_FORMAT"}
	if payload["version"] != HEAT_PERSISTENCE_VERSION:
		return {"valid": false, "reason": "UNSUPPORTED_VERSION"}
	if not payload["saved_at_stable_dock"]:
		return {"valid": false, "reason": "UNSTABLE_SAVE_BOUNDARY"}
	if payload["saved_completed_voyage"] < 0:
		return {"valid": false, "reason": "NEGATIVE_SAVED_VOYAGE"}
	if (
		payload["saved_dock_id"].is_empty()
		or ship.get_dock_definition(payload["saved_dock_id"]).is_empty()
	):
		return {"valid": false, "reason": "UNKNOWN_SAVED_DOCK_ID"}
	var saved_heat: Dictionary = payload["world_heat"]
	var heat_validation: Dictionary = _world_heat.validate_save_data(
		saved_heat,
		_get_known_peaceful_target_ids(),
	)
	if not bool(heat_validation["valid"]):
		return {
			"valid": false,
			"reason": "WORLD_HEAT_%s" % heat_validation["reason"],
		}
	if saved_heat["last_completed_voyage"] != payload["saved_completed_voyage"]:
		return {"valid": false, "reason": "SAVED_VOYAGE_CURSOR_MISMATCH"}
	if completed_voyages > saved_heat["completed_voyage_update_count"]:
		return {
			"valid": false,
			"reason": "CURRENT_WORLD_VOYAGE_CANNOT_REBASE_SNAPSHOT",
		}
	if saved_heat["peaceful_attack_in_current_voyage"]:
		return {"valid": false, "reason": "UNSAFE_CURRENT_VOYAGE_FLAG"}
	var known_heat_costs: Dictionary = _get_known_peaceful_target_heat_costs()
	var expected_total_heat_added := 0
	for target_id in saved_heat["peaceful_target_ids_hit"]:
		expected_total_heat_added += known_heat_costs[target_id]
	if saved_heat["total_heat_added"] != expected_total_heat_added:
		return {"valid": false, "reason": "TARGET_HEAT_ACCOUNTING_MISMATCH"}
	return {
		"valid": true,
		"reason": "VALID",
		"known_peaceful_target_ids": _get_known_peaceful_target_ids(),
		"world_heat_validation": heat_validation.duplicate(true),
	}


func _get_known_peaceful_target_ids() -> Array[String]:
	var peaceful_target_ids: Array[String] = []
	for target in inspection_targets:
		if target.peaceful:
			peaceful_target_ids.append(target.target_id)
	return peaceful_target_ids


func _get_known_peaceful_target_heat_costs() -> Dictionary:
	var peaceful_target_heat_costs: Dictionary = {}
	for target in inspection_targets:
		if target.peaceful:
			peaceful_target_heat_costs[target.target_id] = (
				maxi(0, target.estimated_heat_cost)
			)
	return peaceful_target_heat_costs


func _capture_non_heat_persistence_state() -> Dictionary:
	return {
		"completed_voyages": completed_voyages,
		"voyage_departure_dock_id": _voyage_departure_dock_id,
		"voyage_departure_count": _voyage_departure_count,
		"same_dock_arrival_count": _same_dock_arrival_count,
		"last_completed_voyage_evidence": (
			_last_completed_voyage_evidence.duplicate(true)
		),
		"money": money,
		"cargo_lots": ship.get_cargo_lots(),
		"ammunition_units": ship.get_ammunition_units(),
		"port_trade_mark": port_trader.get_mark_state(completed_voyages),
		"cove_trade_mark": cove_buyer.get_mark_state(completed_voyages),
		"port_condition": _port_condition.get_playtest_state(
			completed_voyages
		),
		"target_conditions": _get_target_condition_snapshots(),
		"ship_is_docked": ship.is_docked,
		"ship_current_dock_id": ship.current_dock_id,
		"ship_last_dock_id": ship.last_dock_id,
	}


func get_playtest_state() -> Dictionary:
	var ship_state: Dictionary = ship.get_playtest_state()
	var food_state: Dictionary = ship.get_food_playtest_state()
	var damage_state: Dictionary = ship.get_damage_playtest_state()
	var crew_state: Dictionary = ship.get_crew_condition_playtest_state()
	var repair_state: Dictionary = ship.get_repair_playtest_state()
	var sea_state: Dictionary = sea_area.get_playtest_state()
	var player_state: Dictionary = player.get_playtest_state()
	var waypoint_state: Dictionary = waypoint_display.get_playtest_state()
	var wreck_state: Dictionary = wreck_opportunity.get_playtest_state()
	var fishing_state: Dictionary = fishing_area.get_playtest_state()
	var weather_state: Dictionary = weather_area.get_playtest_state()
	var ruin_state: Dictionary = ruin_exploration.get_playtest_state()
	var story_state: Dictionary = story_clue.get_playtest_state()
	var monster_state: Dictionary = monster_hunt.get_playtest_state(
		ship.get_cargo_lots(),
		cove_storage.get_cargo_lots(),
	)
	var resident_state: Dictionary = resident.get_playtest_state()
	var day_night_state: Dictionary = day_night_cycle.get_playtest_state()
	var cove_state: Dictionary = cove.get_playtest_state()
	var cove_time_view_text := "%s\n%s" % [
		cove_time_title.text,
		cove_time_status.text,
	]
	var ship_module_view_text := "%s\n%s\n%s\n%s\n%s" % [
		ship_module_title.text,
		ship_module_status.text,
		ship_module_details.text,
		ship_module_result.text,
		ship_module_controls.text,
	]
	var module_state: Dictionary = ship_module_loadout.get_playtest_state(
		ship.get_cargo_lots().size(),
		ship.get_cargo_limit(),
		ship_module_view.visible,
		ship_module_view_text if ship_module_view.visible else "",
		_player_near_ship_module_bench,
	)
	var story_physical_state: Dictionary = (
		_get_story_fragment_physical_state()
	)
	var storage_state: Dictionary = cove_storage.get_playtest_state()
	var construction_state: Dictionary = construction_site.get_playtest_state(
		cove_storage
	)
	var port_trader_state: Dictionary = (
		port_trader.get_playtest_state(completed_voyages)
	)
	var cove_buyer_state: Dictionary = (
		cove_buyer.get_playtest_state(completed_voyages)
	)
	var port_condition_state: Dictionary = (
		_port_condition.get_playtest_state(completed_voyages)
	)
	var journal_state: Dictionary = (
		_trade_journal.get_playtest_state(completed_voyages)
	)
	var heat_state: Dictionary = _world_heat.get_playtest_state()
	var hunter_state: Dictionary = pirate_hunter.get_hunter_playtest_state()
	var defeat_state: Dictionary = _defeat_recovery.get_playtest_state()
	var journal_good_names: Array = []
	var journal_current_price_states := {}
	var journal_current_fixed_prices := {}
	var journal_base_price_states := {}
	var journal_base_fixed_prices := {}
	for journal_good in journal_state["goods"]:
		var journal_good_name := String(journal_good["good_name"])
		journal_good_names.append(journal_good_name)
		journal_current_price_states[journal_good_name] = (
			journal_good["current_price_state"]
		)
		journal_current_fixed_prices[journal_good_name] = (
			journal_good["current_fixed_price"]
		)
		journal_base_price_states[journal_good_name] = (
			journal_good["base_price_state"]
		)
		journal_base_fixed_prices[journal_good_name] = (
			journal_good["base_fixed_price"]
		)
	var journal_view_full_text := (
		"%s\n%s\n%s\n%s" % [
			journal_title.text,
			journal_status.text,
			journal_details.text,
			journal_controls.text,
		]
		if journal_view.visible
		else ""
	)
	var journal_visible_text_matches_saved_goods := (
		bool(journal_state["known"]) and journal_view.visible
	)
	for journal_good in journal_state["goods"]:
		journal_visible_text_matches_saved_goods = (
			journal_visible_text_matches_saved_goods
			and journal_view_full_text.contains(
				"%s · %s · %d COINS · BASE %s · %d" % [
					journal_good["good_name"],
					journal_good["current_price_state"],
					journal_good["current_fixed_price"],
					journal_good["base_price_state"],
					journal_good["base_fixed_price"],
				]
			)
		)
	var journal_visible_text_matches_saved_mark := false
	var journal_visible_text_matches_saved_condition := false
	if bool(journal_state["known"]) and journal_view.visible:
		var saved_mark: Dictionary = journal_state["spice_stock_mark"]
		var saved_condition: Dictionary = journal_state["condition"]
		journal_visible_text_matches_saved_mark = (
			journal_view_full_text.contains(
				"SPICE STOCK · %s · AVAILABLE %d/%d · USED %d" % [
					saved_mark["mark_display"],
					saved_mark["marks_available"],
					saved_mark["mark_capacity"],
					saved_mark["marks_used"],
				]
			)
		)
		journal_visible_text_matches_saved_condition = (
			journal_view_full_text.contains(
				"KNOWN CONDITION · %s · %s" % [
					saved_condition["name"],
					saved_condition["state"],
				]
			)
			and journal_view_full_text.contains(
				"EFFECTS · %s" % saved_condition["effects"]
			)
			and journal_view_full_text.contains(
				"START VOYAGE %d · END VOYAGE %d · SAVED REMAINING %d" % [
					saved_condition["start_voyage"],
					saved_condition["end_voyage"],
					saved_condition["remaining_voyages"],
				]
			)
		)
	var condition_cargo_lot_names: Array = (
		port_condition_state["affected_cargo_lot_names"]
	)
	var trade_view_full_text := (
		"%s\n%s\n%s\n%s" % [
			trade_title.text,
			trade_details.text,
			trade_result.text,
			trade_controls.text,
		]
		if trade_view.visible
		else ""
	)
	var visible_port_condition_text := ""
	if (
		_trade_view_open
		and _active_trade_contact == port_trader
		and trade_view.visible
	):
		visible_port_condition_text = trade_view_full_text
	var visible_cove_trade_text := ""
	if (
		_trade_view_open
		and _active_trade_contact == cove_buyer
		and trade_view.visible
	):
		visible_cove_trade_text = trade_view_full_text
	var active_trade_preview := {}
	if _active_trade_contact != null:
		active_trade_preview = _active_trade_contact.get_money_preview(money)
	var fish_money_preview := _get_fish_money_preview(money)
	var large_fish_money_preview := _get_fish_money_preview(
		money,
		FishingAreaState.LARGE_FISH_LOT_NAME,
	)
	var treasure_money_preview := _get_treasure_money_preview(money)
	var food_view_full_text := "%s\n%s\n%s" % [
		food_title.text,
		food_status.text,
		food_details.text,
	]
	var hull_view_full_text := "%s\n%s" % [
		hull_title.text,
		hull_status.text,
	]
	var crew_view_full_text := "%s\n%s" % [
		crew_title.text,
		crew_status.text,
	]
	var heat_view_full_text := "%s\n%s" % [
		heat_title.text,
		heat_status.text,
	]
	var repair_view_full_text := "%s\n%s\n%s\n%s\n%s\n%s" % [
		repair_title.text,
		repair_cost.text,
		repair_preview.text,
		repair_status.text,
		repair_result.text,
		repair_controls.text,
	]
	var ammunition_state: Dictionary = ship.get_ammunition_playtest_state()
	var ammunition_view_full_text: String = "%s\n%s\n%s" % [
		ammunition_title.text,
		ammunition_status.text,
		ammunition_cargo.text,
	]
	var defeat_result_view_full_text := "%s\n%s\n%s" % [
		defeat_result_title.text,
		defeat_result_details.text,
		defeat_result_controls.text,
	]
	var repair_view_rect := repair_view.get_global_rect()
	var heat_view_rect := heat_view.get_global_rect()
	var hull_view_rect := hull_view.get_global_rect()
	var crew_view_rect := crew_view.get_global_rect()
	var food_view_rect := food_view.get_global_rect()
	var controls_help_rect := controls_help.get_global_rect()
	var weather_view_text := "%s\n%s" % [
		weather_title.text,
		weather_status.text,
	]
	var monster_hunt_view_text := "%s\n%s\n%s" % [
		monster_hunt_title.text,
		monster_hunt_status.text,
		monster_hunt_result.text,
	]
	var physical_cargo_total: int = int(
		ship_state["cargo_used_slots"]
		+ wreck_state["wreck_salvage_lot_count"]
		+ storage_state["storage_used_slots"]
		+ fishing_state["pending_catch_count"]
		+ ruin_state["physical_treasure_lot_count"]
		+ story_state["world_fragment_lot_count"]
		+ monster_state["world_part_lot_count"]
	)
	var initial_physical_cargo_total: int = int(
		ship_state["starting_cargo_used_slots"]
		+ wreck_state["wreck_initial_salvage_lot_count"]
		+ storage_state["starting_storage_used_slots"]
		+ ruin_state["initial_treasure_lot_count"]
		+ story_state["initial_fragment_lot_count"]
	)
	var accounted_cargo_total: int = int(
		physical_cargo_total
		+ construction_state["consumed_lot_count"]
		+ _trade_sold_lot_count
		+ food_state["total_units_used"]
		+ repair_state["consumed_timber_count"]
		+ ammunition_state["depleted_lot_count"]
		+ defeat_state["total_cargo_slot_loss_count"]
		+ _prize_cannon_sale_count
		+ _fish_sold_lot_count
		+ fishing_state["discarded_catch_count"]
		+ fishing_state["displaced_cargo_discard_count"]
		+ _treasure_sold_lot_count
		+ ruin_state["displaced_cargo_discard_count"]
		+ story_state["displaced_cargo_discard_count"]
		+ story_state["persisted_fragment_absent_count"]
		+ monster_state["part_displaced_cargo_discard_count"]
	)
	var expected_cargo_total: int = (
		initial_physical_cargo_total
		+ _trade_bought_lot_count
		+ _ammunition_supply_purchased_lot_count
		+ _prize_actions.get_awarded_cargo_lot_count()
		+ fishing_state["successful_catch_count"]
		+ monster_state["part_generation_count"]
	)
	var expected_money: int = (
		STARTING_MONEY
		- _trade_bought_lot_count * TradeContact.CHEAP_PRICE
		+ _trade_sold_lot_count * TradeContact.VALUABLE_PRICE
		- _ammunition_supply_money_spent
		+ _prize_cannon_money_earned
		+ _fish_money_earned
		+ _treasure_sold_lot_count * TradeContact.NORMAL_PRICE
	)
	var ammunition_load_state: Dictionary = ammunition_state["last_load_evidence"]
	var ammunition_conversion_cargo_delta: int = 0
	if not ammunition_load_state.is_empty():
		ammunition_conversion_cargo_delta = int(
			ammunition_load_state["cargo_slot_count_after"]
		) - int(ammunition_load_state["cargo_slot_count_before"])
	var target_ship_states: Array[Dictionary] = []
	var target_ship_ids: Array[String] = []
	var target_hull_states: Dictionary = {}
	var target_sail_states: Dictionary = {}
	var target_condition_states: Dictionary = {}
	var target_boarding_states: Dictionary = {}
	var routed_target_ids: Array[String] = []
	var caught_target_ids: Array[String] = []
	var disabled_target_ids: Array[String] = []
	var boarding_ready_target_ids: Array[String] = []
	var boarding_prompt_target_ids: Array[String] = []
	var boarding_far_denial_target_ids: Array[String] = []
	var boarding_active_target_ids: Array[String] = []
	var boarding_resolved_target_ids: Array[String] = []
	var boarding_unresolved_target_ids: Array[String] = []
	var boarding_prompt_contract_holds := true
	var boarding_far_denial_holds := true
	var boarding_state_owner_count_holds := true
	var boarding_resolved_no_repeat_prompt_holds := true
	var boarding_each_target_resolves_at_most_once := true
	var boarding_resolution_preserves_route_condition := true
	var boarding_last_far_denial_distance := -1.0
	for target in inspection_targets:
		target_ship_states.append(target.get_playtest_state())
		target_ship_ids.append(target.target_id)
		var target_hull_state: Dictionary = target.get_hull_state()
		var target_sail_state: Dictionary = target.get_sail_state()
		target_hull_states[target.target_id] = target_hull_state.duplicate(true)
		target_sail_states[target.target_id] = target_sail_state.duplicate(true)
		target_condition_states[target.target_id] = (
			target.get_condition_state().duplicate(true)
		)
		var target_boarding_state: Dictionary = target.get_boarding_state()
		target_boarding_states[target.target_id] = (
			target_boarding_state.duplicate(true)
		)
		if bool(target_sail_state["route_enabled"]):
			routed_target_ids.append(target.target_id)
		if bool(target_sail_state["caught_after_sail_damage"]):
			caught_target_ids.append(target.target_id)
		if bool(target_hull_state["disabled"]):
			disabled_target_ids.append(target.target_id)
		if bool(target_boarding_state["condition_ready"]):
			boarding_ready_target_ids.append(target.target_id)
		if bool(target_boarding_state["prompt_available"]):
			boarding_prompt_target_ids.append(target.target_id)
		if bool(target_boarding_state["far_denial_observed"]):
			boarding_far_denial_target_ids.append(target.target_id)
			boarding_last_far_denial_distance = maxf(
				boarding_last_far_denial_distance,
				float(target_boarding_state["far_denial_distance"]),
			)
		if bool(target_boarding_state["active"]):
			boarding_active_target_ids.append(target.target_id)
		if bool(target_boarding_state["victory_resolved"]):
			boarding_resolved_target_ids.append(target.target_id)
		else:
			boarding_unresolved_target_ids.append(target.target_id)
		boarding_prompt_contract_holds = (
			boarding_prompt_contract_holds
			and bool(target_boarding_state["prompt_requires_condition_and_position"])
		)
		boarding_far_denial_holds = (
			boarding_far_denial_holds
			and bool(target_boarding_state["far_denial_has_no_prompt"])
		)
		boarding_state_owner_count_holds = (
			boarding_state_owner_count_holds
			and int(target_boarding_state["owner_count"]) == 1
		)
		boarding_resolved_no_repeat_prompt_holds = (
			boarding_resolved_no_repeat_prompt_holds
			and bool(target_boarding_state["resolved_target_has_no_prompt"])
			and (
				not bool(target_boarding_state["victory_resolved"])
				or bool(target_boarding_state["repeat_boarding_blocked"])
			)
		)
		boarding_each_target_resolves_at_most_once = (
			boarding_each_target_resolves_at_most_once
			and int(target_boarding_state["victory_resolution_count"]) <= 1
		)
		boarding_resolution_preserves_route_condition = (
			boarding_resolution_preserves_route_condition
			and bool(target_boarding_state[
				"resolution_preserved_condition_and_route"
			])
		)
	var broadside_state: Dictionary = ship.get_broadside_playtest_state()
	var broadside_view_text: String = "%s\n%s\n%s" % [
		broadside_title.text,
		broadside_areas.text,
		broadside_result.text,
	]
	var target_combat_view_text: String = "%s\n%s\n%s\n%s\n%s\n%s\n%s" % [
		target_combat_title.text,
		attack_choices.text,
		target_hull_value.text,
		target_sail_value.text,
		target_speed.text,
		target_route.text,
		catch_status.text,
	]
	var active_inspection_estimate: Dictionary = (
		_get_target_inspection_estimate(_active_inspection_target)
		if _active_inspection_target != null
		else _last_inspection_estimate.duplicate(true)
	)
	var active_inspection_heat_preview: Dictionary = (
		(active_inspection_estimate.get(
			"heat_preview",
			{},
		) as Dictionary).duplicate(true)
	)
	var target_inspection_view_text := ""
	if target_inspection_view.visible:
		target_inspection_view_text = "%s\n%s\n%s\n%s" % [
			inspection_title.text,
			inspection_target_name.text,
			inspection_details.text,
			inspection_controls.text,
		]
	var estimate_labels_visible := target_inspection_view.visible
	for required_label in [
		"ALL VALUES BELOW ARE ESTIMATES",
		"TARGET ESTIMATE",
		"OWNER ESTIMATE",
		"FLAG ESTIMATE",
		"SHIP CLASS ESTIMATE",
		"LIKELY SPEED ESTIMATE",
		"GENERAL CARGO TYPE ESTIMATE",
		"THREAT ESTIMATE",
		"PEACEFUL ESTIMATE",
		"HEAT COST ESTIMATE",
		"ATTACK CHOICE ESTIMATE",
	]:
		estimate_labels_visible = (
			estimate_labels_visible
			and target_inspection_view_text.contains(required_label)
		)
	var camera_target := "COVE"
	if _player_on_target_deck:
		camera_target = "TARGET_DECK"
	elif _player_aboard_ship:
		camera_target = "SHIP"
	elif ruin_exploration.is_inside():
		camera_target = "RUIN"
	elif not _player_shore_id.is_empty():
		camera_target = "PLAYER_ASHORE"
	var boarding_deck_state: Dictionary = target_boarding_deck.get_playtest_state(
		player.global_position
	)
	var prize_state: Dictionary = _prize_actions.get_playtest_state(
		ship.get_cargo_lots(),
		_trade_journal.get_entry_snapshot(),
		_prize_returned_to_player_ship,
	)
	var prize_screen_counts_by_target: Dictionary = (
		prize_state["screen_open_counts_by_target"]
	)
	var resolved_targets_have_one_prize_screen_max: bool = true
	for resolved_target_id in boarding_resolved_target_ids:
		resolved_targets_have_one_prize_screen_max = (
			resolved_targets_have_one_prize_screen_max
			and int(prize_screen_counts_by_target.get(resolved_target_id, 0)) == 1
		)
	var two_distinct_targets_one_victory_each_eligible: bool = (
		target_ship_ids.size() == 2
		and boarding_each_target_resolves_at_most_once
	)
	for target_id in target_ship_ids:
		two_distinct_targets_one_victory_each_eligible = (
			two_distinct_targets_one_victory_each_eligible
			and int(prize_screen_counts_by_target.get(target_id, 0)) <= 1
		)
	var prize_view_text := ""
	if prize_view.visible:
		prize_view_text = "%s\n%s\n%s\n%s\n%s" % [
			prize_title.text,
			prize_status.text,
			prize_details.text,
			prize_result.text,
			prize_controls.text,
		]
	var prize_view_shows_four_types := prize_view.visible
	for visible_prize_text in [
		"[1] CAPTURED CARGO",
		"[2] USABLE CANNONS · SELLABLE CARGO",
		"[3] REPAIR MATERIALS · TIMBER LOT",
		"[4] TRADE RECORDS · PORT JOURNAL ENTRY",
	]:
		prize_view_shows_four_types = (
			prize_view_shows_four_types
			and prize_view_text.contains(visible_prize_text)
		)
	var boarding_prompt_visible := (
		interaction_prompt.visible
		and interaction_prompt.text.begins_with("[E] BOARD ")
	)
	var boarding_return_prompt_visible := (
		interaction_prompt.visible
		and interaction_prompt.text == "[E] RETURN TO PLAYER SHIP"
	)
	var last_boarding_finish_evidence: Dictionary = (
		_last_boarding_return_evidence.get("target_finish_evidence", {})
	)
	var boarding_target_route_stable := bool(
		last_boarding_finish_evidence.get("route_stayed_fixed", false)
	)
	if boarding_active_target_ids.size() == 1:
		var active_boarding_state: Dictionary = target_boarding_states.get(
			boarding_active_target_ids[0],
			{},
		)
		boarding_target_route_stable = bool(
			active_boarding_state.get("route_stable_while_boarding", false)
		)
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
		"ship_base_top_speed": ship_state["base_top_speed"],
		"ship_turn_speed": ship_state["turn_speed"],
		"ship_base_turn_speed": ship_state["base_turn_speed"],
		"ship_weather_turn_multiplier": (
			ship_state["weather_turn_multiplier"]
		),
		"ship_weather_control_effect_active": (
			ship_state["weather_control_effect_active"]
		),
		"ship_weather_control_update_count": (
			ship_state["weather_control_update_count"]
		),
		"ship_last_weather_control_evidence": (
			ship_state["last_weather_control_evidence"]
		),
		"ship_turn_input_frame_count": ship_state["turn_input_frame_count"],
		"ship_last_turn_response_evidence": (
			ship_state["last_turn_response_evidence"]
		),
		"crew_condition_system_count": crew_state["system_count"],
		"crew_condition_owner_count": crew_state["owner_count"],
		"crew_condition_aggregate_value_count": (
			crew_state["aggregate_value_count"]
		),
		"crew_condition_exactly_one_aggregate_value": (
			int(crew_state["system_count"]) == 1
			and int(crew_state["owner_count"]) == 1
			and int(crew_state["aggregate_value_count"]) == 1
		),
		"crew_condition": crew_state["condition"],
		"crew_condition_max": crew_state["condition_max"],
		"crew_condition_start": crew_state["condition_start"],
		"crew_condition_full": crew_state["full"],
		"crew_condition_low": crew_state["low"],
		"crew_low_condition_threshold": crew_state["low_condition_threshold"],
		"crew_successful_naval_hits_per_injury": (
			crew_state["successful_naval_hits_per_injury"]
		),
		"crew_fixed_injury_amount": crew_state["fixed_injury_amount"],
		"crew_successful_naval_damage_count": (
			crew_state["successful_naval_damage_count"]
		),
		"crew_hits_toward_next_injury": (
			crew_state["hits_toward_next_injury"]
		),
		"crew_injury_count": crew_state["injury_count"],
		"crew_last_naval_damage_evidence": (
			(crew_state["last_naval_damage_evidence"] as Dictionary).duplicate(
				true
			)
		),
		"crew_last_injury_evidence": (
			(crew_state["last_injury_evidence"] as Dictionary).duplicate(true)
		),
		"crew_last_combat_context_evidence": (
			_last_crew_combat_context_evidence.duplicate(true)
		),
		"crew_last_injury_context_evidence": (
			_last_crew_injury_context_evidence.duplicate(true)
		),
		"crew_injury_uses_fixed_threshold": (
			_last_crew_injury_context_evidence.is_empty()
			or (
				bool(_last_crew_injury_context_evidence.get(
					"crew_injury_threshold_reached",
					false,
				))
				and int(_last_crew_injury_context_evidence.get(
					"crew_injury_threshold",
					0,
				)) == int(crew_state["successful_naval_hits_per_injury"])
			)
		),
		"crew_last_combat_conservation_holds": (
			_last_crew_combat_context_evidence.is_empty()
			or (
				bool(_last_crew_combat_context_evidence.get(
					"cargo_unchanged",
					false,
				))
				and bool(_last_crew_combat_context_evidence.get(
					"ammunition_unchanged",
					false,
				))
				and bool(_last_crew_combat_context_evidence.get(
					"food_units_unchanged",
					false,
				))
				and bool(_last_crew_combat_context_evidence.get(
					"food_progress_unchanged",
					false,
				))
				and bool(_last_crew_combat_context_evidence.get(
					"world_heat_unchanged",
					false,
				))
				and bool(_last_crew_combat_context_evidence.get(
					"target_conditions_unchanged",
					false,
				))
				and bool(_last_crew_combat_context_evidence.get(
					"hull_changed_only_by_fixed_hunter_damage",
					false,
				))
			)
		),
		"crew_affected_action": crew_state["affected_action"],
		"crew_affected_action_count": crew_state["affected_action_count"],
		"crew_exactly_one_action_reduced": (
			int(crew_state["affected_action_count"]) == 1
			and String(crew_state["affected_action"]) == "SAILING_TOP_SPEED"
		),
		"crew_normal_sailing_top_speed": (
			crew_state["normal_sailing_top_speed"]
		),
		"crew_low_sailing_top_speed": crew_state["low_sailing_top_speed"],
		"crew_effective_sailing_top_speed": (
			crew_state["effective_sailing_top_speed"]
		),
		"crew_low_speed_multiplier": crew_state["low_speed_multiplier"],
		"crew_action_matches_ship_top_speed": is_equal_approx(
			float(crew_state["effective_sailing_top_speed"]),
			float(ship_state["top_speed"]),
		),
		"crew_safe_dock_ids": crew_state["safe_dock_ids"],
		"crew_safe_dock_count": crew_state["safe_dock_count"],
		"crew_automatic_safe_dock_restoration": (
			crew_state["automatic_safe_dock_restoration"]
		),
		"crew_restoration_attempt_count": (
			crew_state["restoration_attempt_count"]
		),
		"crew_restoration_count": crew_state["restoration_count"],
		"crew_last_dock_context_evidence": (
			_last_crew_dock_context_evidence.duplicate(true)
		),
		"crew_last_restoration_context_evidence": (
			_last_crew_restoration_context_evidence.duplicate(true)
		),
		"crew_last_restoration_conservation_holds": (
			_last_crew_restoration_context_evidence.is_empty()
			or (
				bool(_last_crew_restoration_context_evidence.get(
					"unrelated_ship_state_unchanged",
					false,
				))
				and bool(_last_crew_restoration_context_evidence.get(
					"world_heat_unchanged",
					false,
				))
				and bool(_last_crew_restoration_context_evidence.get(
					"target_conditions_unchanged",
					false,
				))
			)
		),
		"crew_last_restoration_restored_action": (
			_last_crew_restoration_context_evidence.is_empty()
			or bool(_last_crew_restoration_context_evidence.get(
				"action_restored_to_normal",
				false,
			))
		),
		"crew_condition_view_count": get_tree().get_nodes_in_group(
			"crew_condition_view"
		).size(),
		"crew_condition_view_visible": crew_view.visible,
		"crew_condition_view_should_be_visible": _player_aboard_ship,
		"crew_condition_view_visibility_matches_aboard": (
			crew_view.visible == _player_aboard_ship
		),
		"crew_condition_view_text": (
			crew_view_full_text if crew_view.visible else ""
		),
		"crew_condition_view_title": crew_title.text,
		"crew_condition_view_status": crew_status.text,
		"crew_condition_meter_value": crew_meter.value,
		"crew_condition_meter_max": crew_meter.max_value,
		"crew_condition_meter_matches_state": (
			is_equal_approx(crew_meter.value, float(crew_state["condition"]))
			and is_equal_approx(
				crew_meter.max_value,
				float(crew_state["condition_max"]),
			)
		),
		"crew_condition_view_overlaps_hull_view": (
			crew_view_rect.intersects(hull_view_rect)
		),
		"crew_condition_view_overlaps_food_view": (
			crew_view_rect.intersects(food_view_rect)
		),
		"crew_condition_view_overlaps_controls": (
			crew_view_rect.intersects(controls_help_rect)
		),
		"crew_full_view_evidence": _crew_full_view_evidence.duplicate(true),
		"crew_injury_view_evidence": (
			_crew_injury_view_evidence.duplicate(true)
		),
		"crew_restoration_view_evidence": (
			_crew_restoration_view_evidence.duplicate(true)
		),
		"crew_low_action_change_visible": (
			_crew_injury_view_evidence.is_empty()
			or (
				String(_crew_injury_view_evidence.get("status", "")).contains(
					"SAILING TOP SPEED 280 -> 224"
				)
				and float(_crew_injury_view_evidence.get(
					"effective_sailing_top_speed",
					0.0,
				)) < float(_crew_injury_view_evidence.get(
					"base_sailing_top_speed",
					0.0,
				))
			)
		),
		"crew_restored_action_visible": (
			_crew_restoration_view_evidence.is_empty()
			or (
				String(_crew_restoration_view_evidence.get(
					"status",
					"",
				)).contains("RESTORED AT")
				and is_equal_approx(
					float(_crew_restoration_view_evidence.get(
						"effective_sailing_top_speed",
						0.0,
					)),
					float(_crew_restoration_view_evidence.get(
						"base_sailing_top_speed",
						-1.0,
					)),
				)
			)
		),
		"crew_individual_member_count": (
			crew_state["individual_crew_member_count"]
		),
		"crew_officer_injury_count": crew_state["officer_injury_count"],
		"crew_wage_system_count": crew_state["wage_system_count"],
		"crew_mutiny_system_count": crew_state["mutiny_system_count"],
		"crew_schedule_system_count": crew_state["crew_schedule_system_count"],
		"crew_recruitment_market_count": crew_state["recruitment_market_count"],
		"crew_separate_injury_type_count": (
			crew_state["separate_injury_type_count"]
		),
		"crew_medical_supply_system_count": (
			crew_state["medical_supply_system_count"]
		),
		"crew_new_task_count": crew_state["new_crew_task_count"],
		"crew_forbidden_feature_count": (
			int(crew_state["individual_crew_member_count"])
			+ int(crew_state["officer_injury_count"])
			+ int(crew_state["wage_system_count"])
			+ int(crew_state["mutiny_system_count"])
			+ int(crew_state["crew_schedule_system_count"])
			+ int(crew_state["recruitment_market_count"])
			+ int(crew_state["separate_injury_type_count"])
			+ int(crew_state["medical_supply_system_count"])
			+ int(crew_state["new_crew_task_count"])
		),
		"phase_33_player_defeat_detection_count": (
			defeat_state["defeat_detection_count"]
		),
		"phase_33_encounter_end_on_player_defeat_count": (
			defeat_state["encounter_end_count"]
		),
		"phase_33_forced_safe_return_count": (
			defeat_state["forced_safe_return_count"]
		),
		"defeat_last_ship_return_evidence": (
			(ship_state["last_defeat_return_evidence"] as Dictionary).duplicate(true)
		),
		"defeat_return_clears_module_departure_ready": (
			(ship_state["last_defeat_return_evidence"] as Dictionary).is_empty()
			or bool((ship_state["last_defeat_return_evidence"] as Dictionary).get(
				"fresh_cove_selection_required_after_defeat",
				false,
			))
		),
		"defeat_return_clears_all_module_departure_state": (
			(ship_state["last_defeat_return_evidence"] as Dictionary).is_empty()
			or (
				bool((ship_state["last_defeat_return_evidence"] as Dictionary).get(
					"fresh_cove_selection_required_after_defeat",
					false,
				))
				and bool((ship_state["last_defeat_return_evidence"] as Dictionary).get(
					"module_departure_pending_exit_cleared",
					false,
				))
			)
		),
		"phase_33_defeat_cargo_loss_count": (
			defeat_state["cargo_lot_loss_count"]
		),
		"phase_33_defeat_ammunition_loss_count": (
			defeat_state["ammunition_unit_loss_count"]
		),
		"phase_33_defeat_money_loss_count": (
			defeat_state["money_loss_count"]
		),
		"phase_33_defeat_result_screen_count": (
			defeat_state["result_screen_open_count"]
		),
		"phase_33_salvage_recovery_trigger_count": (
			defeat_state["salvage_recovery_count"]
		),
		"phase_33_recovery_behavior_count": (
			defeat_state["repair_recovery_count"]
		),
		"phase_33_feature_count": (
			defeat_state["system_count"]
		),
		"defeat_recovery_state": defeat_state.duplicate(true),
		"defeat_state_owner_count": defeat_state["owner_count"],
		"defeat_flow_state": defeat_state["flow_state"],
		"defeat_hull_threshold": defeat_state["defeat_hull_threshold"],
		"defeat_supported_naval_damage_source": (
			defeat_state["supported_naval_damage_source"]
		),
		"defeat_safe_return_dock_id": defeat_state["safe_return_dock_id"],
		"defeat_fixed_cargo_lot_loss": defeat_state["fixed_cargo_lot_loss"],
		"defeat_fixed_ammunition_unit_loss": (
			defeat_state["fixed_ammunition_unit_loss"]
		),
		"defeat_minimum_retained_cargo_lots": (
			defeat_state["minimum_retained_cargo_lots"]
		),
		"defeat_result_screen_count": get_tree().get_nodes_in_group(
			"defeat_result_screen"
		).size(),
		"defeat_result_screen_visible": defeat_result_view.visible,
		"defeat_result_screen_text": (
			defeat_result_view_full_text if defeat_result_view.visible else ""
		),
		"defeat_result_screen_lists_actual_state": (
			not defeat_result_view.visible
			or (
				defeat_result_details.text == _defeat_recovery.get_result_text()
				and defeat_result_view_full_text.contains("CARGO LOST")
				and defeat_result_view_full_text.contains("AMMUNITION LOST")
				and defeat_result_view_full_text.contains("MONEY RETAINED")
				and defeat_result_view_full_text.contains("HULL RETAINED DAMAGED")
				and defeat_result_view_full_text.contains("CREW RETAINED INJURED")
				and defeat_result_view_full_text.contains("COVE STORAGE · UNCHANGED")
			)
		),
		"defeat_result_modal_blocks": {
			"sailing": defeat_result_view.visible
				and ship_state["navigation_input_blocked"],
			"chart": defeat_result_view.visible
				and not waypoint_state["chart_visible"],
			"attack": defeat_result_view.visible,
			"pursuit": defeat_result_view.visible,
			"boarding": defeat_result_view.visible,
			"world_interaction": defeat_result_view.visible,
			"walking": defeat_result_view.visible
				and not player_state["movement_enabled"],
		},
		"defeat_result_release_guard_pending": (
			defeat_state["release_guard_pending"]
		),
		"defeat_result_blocked_input_count": defeat_state["blocked_input_count"],
		"defeat_last_modal_input_evidence": (
			_last_defeat_modal_input_evidence.duplicate(true)
		),
		"defeat_held_action_state": _get_defeat_held_action_state(),
		"defeat_pursuit_input_clear": not _pursuit_pressed,
		"defeat_release_controls_include_pursuit": (
			not defeat_state["release_guard_pending"]
			or DEFEAT_RELEASE_CONTROLS_TEXT.contains(", P,")
		),
		"defeat_release_cleanup_count": _defeat_release_cleanup_count,
		"defeat_release_cleanup_evidence": (
			_defeat_release_cleanup_evidence.duplicate(true)
		),
		"defeat_start_input_cleanup_evidence": (
			_defeat_start_input_cleanup_evidence.duplicate(true)
		),
		"defeat_fresh_actions_clear_of_stale_phase_33_state": (
			not _has_stale_defeat_action_key_state()
		),
		"defeat_last_evidence": (
			(defeat_state["last_defeat_evidence"] as Dictionary).duplicate(true)
		),
		"defeat_repair_material_boundary_evidence": (
			ship_state["defeat_repair_material_boundary_evidence"]
		),
		"defeat_normal_prepared_path_evidence": (
			ship_state["defeat_normal_prepared_path_evidence"]
		),
		"defeat_existing_salvage_recovery_used": (
			defeat_state["existing_salvage_recovery_used"]
		),
		"defeat_existing_repair_recovery_used": (
			defeat_state["existing_repair_recovery_used"]
		),
		"ship_controls": ship_state["controls"],
		"ship_module_system_count": module_state["system_count"],
		"ship_module_owner_count": module_state["owner_count"],
		"ship_module_slot_count": module_state["module_slot_count"],
		"ship_module_choice_count": module_state["module_choice_count"],
		"ship_module_ids": module_state["module_ids"],
		"ship_module_names": module_state["module_names"],
		"ship_module_pending": module_state["pending_module"],
		"ship_module_pending_name": module_state["pending_module_name"],
		"ship_module_active": module_state["active_module"],
		"ship_module_active_name": module_state["active_module_name"],
		"ship_module_has_pending_selection": (
			module_state["has_pending_selection"]
		),
		"ship_module_has_active_selection": (
			module_state["has_active_selection"]
		),
		"ship_module_fresh_selection_required_for_next_cove_voyage": (
			module_state["fresh_selection_required_for_next_cove_voyage"]
		),
		"ship_module_cove_boarding_requires_prepared_selection": (
			module_state["cove_boarding_requires_prepared_selection"]
		),
		"ship_module_mutual_exclusivity_holds": (
			module_state["mutual_exclusivity_holds"]
		),
		"ship_module_exactly_one_active_when_selected": (
			module_state["exactly_one_active_when_selected"]
		),
		"ship_module_view_count": get_tree().get_nodes_in_group(
			"ship_module_view"
		).size(),
		"ship_module_view_visible": module_state["view_visible"],
		"ship_module_view_text": module_state["view_text"],
		"ship_module_player_near_bench": module_state["player_near_station"],
		"ship_module_selection_open": module_state["selection_open"],
		"ship_module_release_pending": (
			module_state["selection_release_pending"]
		),
		"ship_module_selection_attempt_count": (
			module_state["selection_attempt_count"]
		),
		"ship_module_selection_success_count": (
			module_state["selection_success_count"]
		),
		"ship_module_selection_denied_count": (
			module_state["selection_denied_count"]
		),
		"ship_module_selection_held_input_count": (
			module_state["selection_held_input_count"]
		),
		"ship_module_blocked_input_count": module_state["blocked_input_count"],
		"ship_module_release_guard_input_count": (
			module_state["release_guard_input_count"]
		),
		"ship_module_last_release_guard_evidence": (
			module_state["last_release_guard_evidence"]
		),
		"ship_module_release_guard_blocks_world_input": (
			not module_state["selection_release_pending"]
			or (
				not player_state["movement_enabled"]
				and not waypoint_state["chart_visible"]
				and not ship_state["navigation_input_blocked"]
			)
		),
		"ship_module_fresh_selection_press_required": (
			module_state["fresh_selection_press_required"]
		),
		"ship_module_last_selection_evidence": (
			module_state["last_selection_evidence"]
		),
		"ship_module_last_held_selection_evidence": (
			module_state["last_held_selection_evidence"]
		),
		"ship_module_activation_count": module_state["activation_count"],
		"ship_module_prepared_for_cove_departure": (
			module_state["prepared_for_cove_departure"]
		),
		"ship_module_last_activation_evidence": (
			module_state["last_activation_evidence"]
		),
		"ship_module_active_voyage_serial": (
			module_state["active_voyage_serial"]
		),
		"ship_module_cove_voyage_start_count": (
			module_state["cove_voyage_start_count"]
		),
		"ship_module_last_voyage_start_evidence": (
			module_state["last_voyage_start_evidence"]
		),
		"ship_module_last_departure_flow_evidence": (
			_last_module_departure_flow_evidence.duplicate(true)
		),
		"ship_module_departure_ready": ship_state["module_departure_ready"],
		"ship_module_departure_exit_pending": (
			ship_state["module_departure_exit_pending"]
		),
		"ship_module_departure_release_observed": (
			_cove_module_departure_release_observed
		),
		"ship_module_departure_exit_release_count": (
			ship_state["module_departure_exit_release_count"]
		),
		"ship_module_departure_token_consumed_count": (
			ship_state["module_departure_token_consumed_count"]
		),
		"ship_module_departure_exit_abort_count": (
			ship_state["module_departure_exit_abort_count"]
		),
		"ship_module_last_departure_exit_evidence": (
			ship_state["last_module_departure_exit_evidence"]
		),
		"ship_module_departure_exit_state_consistent": (
			ship_state["module_departure_exit_state_consistent"]
		),
		"ship_module_token_held_until_damaged_dock_clear": (
			ship_state["module_departure_token_held_until_damaged_dock_clear"]
		),
		"ship_module_token_consumed_after_exit_holds": (
			_last_module_departure_flow_evidence.is_empty()
			or not bool(_last_module_departure_flow_evidence.get(
				"success",
				false,
			))
			or (
				String(_last_module_departure_flow_evidence.get(
					"context",
					"",
				)) == "DOCKED_COVE_RELEASE_OBSERVED"
				and ship_state["module_departure_ready"]
				and ship_state["module_departure_exit_pending"]
			)
			or bool(_last_module_departure_flow_evidence.get(
				"departure_token_consumed_after_exit",
				false,
			))
		),
		"ship_module_cargo_racks_active": module_state["cargo_racks_active"],
		"ship_module_long_guns_active": module_state["long_guns_active"],
		"ship_module_fishing_gear_active": module_state["fishing_gear_active"],
		"ship_module_base_cargo_limit": module_state["base_cargo_limit"],
		"ship_module_cargo_rack_limit": module_state["cargo_rack_limit"],
		"ship_module_cargo_rack_bonus_slots": (
			module_state["cargo_rack_bonus_slots"]
		),
		"ship_module_cargo_limit_matches_active": (
			module_state["cargo_limit_matches_active_module"]
		),
		"ship_module_cargo_capacity_safe": (
			module_state["cargo_capacity_safe"]
		),
		"ship_module_cargo_racks_add_space": (
			module_state["cargo_racks_add_space"]
		),
		"ship_module_long_guns_add_no_cargo_space": (
			module_state["long_guns_add_no_cargo_space"]
		),
		"ship_module_fishing_gear_adds_no_cargo_space": (
			module_state["fishing_gear_adds_no_cargo_space"]
		),
		"ship_module_pursuit_attack_option_count": (
			module_state["pursuit_attack_option_count"]
		),
		"ship_module_pursuit_attack_key": module_state["pursuit_attack_key"],
		"ship_module_pursuit_attack_available": (
			module_state["pursuit_attack_available"]
		),
		"ship_module_pursuit_fixed_sail_damage": (
			module_state["pursuit_fixed_sail_damage"]
		),
		"ship_module_pursuit_reload_remaining": (
			module_state["pursuit_reload_remaining"]
		),
		"ship_module_pursuit_attempt_count": (
			module_state["pursuit_attempt_count"]
		),
		"ship_module_pursuit_shot_count": module_state["pursuit_shot_count"],
		"ship_module_pursuit_hit_count": module_state["pursuit_hit_count"],
		"ship_module_pursuit_held_input_count": (
			module_state["pursuit_held_input_count"]
		),
		"ship_module_last_pursuit_result": module_state["last_pursuit_result"],
		"ship_module_last_pursuit_evidence": (
			module_state["last_pursuit_evidence"]
		),
		"ship_module_last_held_pursuit_evidence": (
			module_state["last_held_pursuit_evidence"]
		),
		"ship_module_last_pursuit_target_id": _last_pursuit_target_id,
		"ship_module_last_pursuit_attack_evidence": (
			_last_pursuit_attack_evidence.duplicate(true)
		),
		"ship_module_selected_visible_in_ship_view": (
			cargo_details.text.contains(
				"MODULE SLOT · %s" % module_state["active_module_name"]
			)
		),
		"ship_module_excluded_features": {
			"more_module_slots": module_state["extra_module_slot_count"],
			"module_levels": module_state["module_levels_count"],
			"large_upgrade_tree": module_state["large_upgrade_tree_count"],
			"passive_percentage_bonuses": (
				module_state["passive_percentage_bonus_count"]
			),
			"ship_cosmetics": module_state["ship_cosmetic_count"],
			"more_owned_ships": module_state["more_owned_ship_count"],
			"resident_reactions": module_state["resident_reaction_count"],
			"relationship_progress": module_state["relationship_progress_count"],
		},
		"ship_controls_enabled": ship_state["controls_enabled"],
		"ship_captain_aboard": ship_state["captain_aboard"],
		"cargo_limit": ship_state["cargo_limit"],
		"cargo_used_slots": ship_state["cargo_used_slots"],
		"cargo_free_slots": ship_state["cargo_free_slots"],
		"cargo_lots": ship_state["cargo_lots"],
		"cargo_total_lots_in_world": physical_cargo_total,
		"cargo_deliberately_consumed_lots": (
			construction_state["consumed_lot_count"]
			+ food_state["total_units_used"]
			+ repair_state["consumed_timber_count"]
			+ ammunition_state["depleted_lot_count"]
			+ defeat_state["total_cargo_slot_loss_count"]
		),
		"cargo_construction_consumed_lots": (
			construction_state["consumed_lot_count"]
		),
		"cargo_food_consumed_lots": food_state["total_units_used"],
		"cargo_repair_consumed_lots": repair_state["consumed_timber_count"],
		"cargo_ammunition_depleted_lots": ammunition_state["depleted_lot_count"],
		"cargo_defeat_lost_lots": defeat_state["total_cargo_slot_loss_count"],
		"cargo_ammunition_source_purchased_lots": (
			_ammunition_supply_purchased_lot_count
		),
		"cargo_accounted_total_including_consumed": accounted_cargo_total,
		"cargo_accounted_total_including_consumed_and_sold": accounted_cargo_total,
		"cargo_initial_total_lots_in_world": initial_physical_cargo_total,
		"cargo_expected_total_including_bought": expected_cargo_total,
		"cargo_prize_awarded_lots": (
			_prize_actions.get_awarded_cargo_lot_count()
		),
		"cargo_prize_cannon_sold_lots": _prize_cannon_sale_count,
		"cargo_lot_conservation_holds": accounted_cargo_total == expected_cargo_total,
		"cargo_conservation_including_consumed_holds": (
			accounted_cargo_total == expected_cargo_total
		),
		"cargo_unaccounted_loss_count": expected_cargo_total - accounted_cargo_total,
		"cargo_world_total_includes_cove_storage": true,
		"food_state_owner_count": food_state["owner_count"],
		"food_view_count": get_tree().get_nodes_in_group(
			"ship_food_view"
		).size(),
		"food_lot_name": food_state["food_lot_name"],
		"food_use_distance": food_state["distance_per_use"],
		"food_units": food_state["food_units"],
		"food_source_cargo_count": ship.get_cargo_lots().count(
			ShipFoodState.FOOD_LOT_NAME
		),
		"food_units_match_source_cargo": (
			int(food_state["food_units"])
			== ship.get_cargo_lots().count(ShipFoodState.FOOD_LOT_NAME)
		),
		"food_each_lot_uses_one_ship_cargo_slot": true,
		"food_progress_distance": food_state["progress_distance"],
		"food_distance_to_next_use": food_state["distance_to_next_use"],
		"food_total_sailing_distance": food_state["total_sailing_distance"],
		"food_total_units_used": food_state["total_units_used"],
		"food_last_use_evidence": food_state["last_use_evidence"],
		"food_last_use_cargo_before": (
			(food_state["last_use_evidence"] as Dictionary).get(
				"cargo_before",
				[],
			)
		),
		"food_last_use_cargo_after": (
			(food_state["last_use_evidence"] as Dictionary).get(
				"cargo_after",
				[],
			)
		),
		"food_last_use_removed_exactly_one": (
			(food_state["last_use_evidence"] as Dictionary).get(
				"removed_exactly_one_food_lot",
				false,
			)
		),
		"food_other_cargo_not_consumed": (
			(food_state["last_use_evidence"] as Dictionary).is_empty()
			or bool((food_state["last_use_evidence"] as Dictionary).get(
				"other_cargo_unchanged",
				false,
			))
		),
		"food_zero_sailing_distance": (
			food_state["zero_food_sailing_distance"]
		),
		"food_last_zero_movement_evidence": (
			food_state["last_zero_food_movement_evidence"]
		),
		"food_sailing_after_empty_observed": (
			bool((food_state[
				"last_zero_food_movement_evidence"
			] as Dictionary).get("sailing_continued", false))
		),
		"food_sailing_continues_without_food": (
			food_state["sailing_continues_without_food"]
		),
		"food_progress_debt_while_empty": (
			food_state["progress_debt_while_empty"]
		),
		"food_progress_is_zero_when_empty": (
			int(food_state["food_units"]) > 0
			or is_zero_approx(float(food_state["progress_distance"]))
		),
		"food_failed_use_count": food_state["failed_use_count"],
		"food_progress_uses_actual_moved_distance_only": (
			food_state["uses_actual_moved_distance_only"]
		),
		"food_dock_snap_distance_counted": false,
		"food_walking_distance_counted": false,
		"food_rotation_distance_counted": false,
		"food_blocked_input_distance_counted": false,
		"food_status": food_state["status"],
		"food_low_warning": food_state["low_food_warning"],
		"food_no_warning": food_state["no_food_warning"],
		"food_view_visible": food_view.visible,
		"food_view_should_be_visible": _player_aboard_ship,
		"food_view_visibility_matches_aboard": (
			food_view.visible == _player_aboard_ship
		),
		"food_view_title": food_title.text,
		"food_view_status": food_status.text,
		"food_view_details": food_details.text,
		"food_view_text": food_view_full_text if food_view.visible else "",
		"food_sea_view_visible": food_view.visible,
		"food_sea_view_status": food_status.text,
		"food_sea_view_text": (
			food_view_full_text if food_view.visible else ""
		),
		"food_view_text_has_units": food_view_full_text.contains(
			"SHIP FOOD · %d UNIT%s" % [
				food_state["food_units"],
				"" if int(food_state["food_units"]) == 1 else "S",
			]
		),
		"food_view_text_has_next_use": food_view_full_text.contains("NEXT USE"),
		"food_view_text_has_exact_progress": (
			int(food_state["food_units"]) <= 0
			or food_view_full_text.contains(
				"NEXT USE · %.1f / %.1f DISTANCE" % [
					food_state["progress_distance"],
					food_state["distance_per_use"],
				]
			)
		),
		"food_view_text_has_exact_distance_to_next_use": (
			int(food_state["food_units"]) <= 0
			or food_view_full_text.contains(
				"DISTANCE UNTIL NEXT USE · %.1f" % (
					food_state["distance_to_next_use"]
				)
			)
		),
		"food_view_text_has_low_warning": (
			not bool(food_state["low_food_warning"])
			or food_view_full_text.contains("LOW FOOD")
		),
		"food_view_text_has_no_food_warning": (
			not bool(food_state["no_food_warning"])
			or (
				food_view_full_text.contains("NO FOOD")
				and food_view_full_text.contains("SAILING CONTINUES")
			)
		),
		"food_real_input_load_ship_starting_slots": (
			ship_state["starting_cargo_lots"]
		),
		"food_real_input_load_storage_starting_slots": (
			storage_state["starting_storage_slots"]
		),
		"food_real_input_load_keys": "1_THEN_4_THEN_5",
		"food_three_unit_load_possible_without_debug_mutation": (
			ship_state["starting_cargo_lots"]
				== ["COVE MEDICINE LOT", ShipFoodState.FOOD_LOT_NAME]
			and storage_state["starting_storage_slots"]
				== [
					ShipFoodState.FOOD_LOT_NAME,
					ShipFoodState.FOOD_LOT_NAME,
					"",
				]
		),
		"food_ship_starting_units": (
			(ship_state["starting_cargo_lots"] as Array).count(
				ShipFoodState.FOOD_LOT_NAME
			)
		),
		"food_storage_starting_units": (
			storage_state["starting_storage_food_units"]
		),
		"food_total_starting_loadable_units": 3,
		"food_storage_starts_with_exact_two_and_one_empty": (
			storage_state["starting_storage_slots"]
				== [
					ShipFoodState.FOOD_LOT_NAME,
					ShipFoodState.FOOD_LOT_NAME,
					"",
				]
		),
		"food_crew_hunger_system_count": 0,
		"food_crew_injury_system_count": 0,
		"food_spoilage_system_count": 0,
		"food_fast_travel_cost_system_count": 0,
		"food_hard_voyage_limit_system_count": 0,
		"ship_repair_system_count": repair_state["system_count"],
		"ship_hull_damage_system_count": damage_state["owner_count"],
		"damage_state_owner_count": damage_state["owner_count"],
		"hull_current": damage_state["hull_current"],
		"hull_max": damage_state["hull_max"],
		"hull_start": damage_state["hull_start"],
		"reef_hit_damage": damage_state["reef_hit_damage"],
		"reef_hit_count": damage_state["hit_count"],
		"last_damage_event": damage_state["last_damage_event"],
		"reef_contact_active": damage_state["contact_active"],
		"reef_contact_clear_count": damage_state["contact_clear_count"],
		"reef_last_contact_clear_evidence": (
			damage_state["last_contact_clear_evidence"]
		),
		"reef_repeated_contact_blocked_count": (
			damage_state["repeated_contact_blocked_count"]
		),
		"reef_cooldown_blocked_count": damage_state["cooldown_blocked_count"],
		"reef_last_blocked_contact_evidence": (
			damage_state["last_blocked_contact_evidence"]
		),
		"reef_cooldown_duration": damage_state["cooldown_duration"],
		"reef_cooldown_remaining": damage_state["cooldown_remaining"],
		"reef_continuous_contact_requires_exit": (
			damage_state["continuous_contact_requires_exit"]
		),
		"reef_contact_reset_requires_actual_movement_away": (
			damage_state["contact_reset_requires_actual_movement_away"]
		),
		"damage_flash_active": damage_state["flash_active"],
		"damage_flash_count": damage_state["flash_count"],
		"damage_flash_duration": damage_state["flash_duration"],
		"damage_flash_remaining": damage_state["flash_remaining"],
		"damage_sound_player_count": ship_state["damage_sound_player_count"],
		"damage_sound_stream_present": ship_state["damage_sound_stream_present"],
		"damage_sound_stream_kind": damage_state["sound_stream_kind"],
		"damage_sound_play_count": damage_state["sound_play_count"],
		"damage_sound_duration": damage_state["sound_duration"],
		"damage_collision_source": damage_state["collision_source"],
		"damage_collision_response": damage_state["collision_response"],
		"ship_damage": damage_state,
		"reef_count": sea_state["reef_count"],
		"reef_center": sea_state["reef_center"],
		"reef_radius": sea_state["reef_radius"],
		"reef_visible": sea_state["reef_visible"],
		"reef_visual_count": sea_state["reef_visual_count"],
		"reef_visual_bounds": sea_state["reef_visual_bounds"],
		"reef_authored_on_initial_straight_route": (
			sea_state["reef_authored_on_initial_straight_route"]
		),
		"hull_view_count": get_tree().get_nodes_in_group(
			"ship_hull_view"
		).size(),
		"hull_view_visible": hull_view.visible,
		"hull_view_should_be_visible": _player_aboard_ship,
		"hull_view_visibility_matches_aboard": (
			hull_view.visible == _player_aboard_ship
		),
		"hull_view_text": hull_view_full_text if hull_view.visible else "",
		"hull_view_title": hull_title.text,
		"hull_view_status": hull_status.text,
		"hull_meter_count": 1 if hull_meter is ProgressBar else 0,
		"hull_meter_node_class": hull_meter.get_class(),
		"hull_meter_min_value": hull_meter.min_value,
		"hull_meter_max_value": hull_meter.max_value,
		"hull_meter_value": hull_meter.value,
		"hull_meter_show_percentage": hull_meter.show_percentage,
		"hull_meter_matches_damage_state": (
			is_equal_approx(
				hull_meter.value,
				float(damage_state["hull_current"]),
			)
			and is_equal_approx(
				hull_meter.max_value,
				float(damage_state["hull_max"]),
			)
		),
		"hull_view_overlaps_food_view": hull_view.get_global_rect().intersects(
			food_view.get_global_rect()
		),
		"damage_snapshot_initial": _damage_snapshot_initial.duplicate(true),
		"damage_snapshot_at_hit": _damage_snapshot_at_hit.duplicate(true),
		"damage_snapshot_at_dock": _damage_snapshot_at_dock.duplicate(true),
		"damage_snapshot_ashore": _damage_snapshot_ashore.duplicate(true),
		"damage_snapshot_return": _damage_snapshot_return.duplicate(true),
		"damage_snapshot_release": _damage_snapshot_release.duplicate(true),
		"damage_hull_persists_at_dock": _damage_checkpoint_matches_hit(
			_damage_snapshot_at_dock
		),
		"damage_hull_persists_ashore": _damage_checkpoint_matches_hit(
			_damage_snapshot_ashore
		),
		"damage_hull_persists_on_return": _damage_checkpoint_matches_hit(
			_damage_snapshot_return
		),
		"damage_hull_persists_after_release": _damage_checkpoint_matches_hit(
			_damage_snapshot_release
		),
		"damage_persistence_holds": (
			_damage_checkpoint_matches_hit(_damage_snapshot_at_dock)
			and _damage_checkpoint_matches_hit(_damage_snapshot_ashore)
			and _damage_checkpoint_matches_hit(_damage_snapshot_return)
			and _damage_checkpoint_matches_hit(_damage_snapshot_release)
		),
		"ship_sail_damage_system_count": 1,
		"ship_crew_injury_system_count": crew_state["system_count"],
		"ship_naval_attack_system_count": 1,
		"broadside_system_count": broadside_state["system_count"],
		"broadside_left_control": broadside_state["left_control"],
		"broadside_right_control": broadside_state["right_control"],
		"broadside_valid_sides": broadside_state["valid_sides"],
		"broadside_attack_choices": broadside_state["attack_choices"],
		"broadside_attack_choice_count": broadside_state["attack_choice_count"],
		"selected_attack_choice": _selected_attack_choice,
		"attack_choice_hull_key": "H",
		"attack_choice_sails_key": "K",
		"attack_choice_selection_count": _attack_choice_selection_count,
		"attack_choice_held_input_count": _attack_choice_held_input_count,
		"attack_choice_blocked_input_count": _attack_choice_blocked_input_count,
		"attack_choice_fresh_press_required": true,
		"attack_choice_modal_guard": true,
		"last_attack_choice_evidence": (
			_last_attack_choice_evidence.duplicate(true)
		),
		"broadside_firing_areas_active": (
			broadside_state["firing_areas_active"]
		),
		"broadside_firing_areas_visible_before_shot": (
			broadside_state["firing_areas_visible_before_shot"]
		),
		"broadside_left_world_corners": (
			broadside_state["left_world_corners"]
		),
		"broadside_right_world_corners": (
			broadside_state["right_world_corners"]
		),
		"broadside_area_near_x": broadside_state["area_near_x"],
		"broadside_area_far_x": broadside_state["area_far_x"],
		"broadside_area_half_length": broadside_state["area_half_length"],
		"broadside_hull_damage": broadside_state["hull_damage"],
		"broadside_sail_damage": broadside_state["sail_damage"],
		"broadside_reload_duration": broadside_state["reload_duration"],
		"broadside_reload_remaining": broadside_state["reload_remaining"],
		"broadside_ready": broadside_state["ready"],
		"broadside_attempt_count": broadside_state["attempt_count"],
		"broadside_shot_count": broadside_state["shot_count"],
		"broadside_hit_count": broadside_state["hit_count"],
		"broadside_miss_count": broadside_state["miss_count"],
		"broadside_left_shot_count": broadside_state["left_shot_count"],
		"broadside_right_shot_count": broadside_state["right_shot_count"],
		"broadside_reload_rejected_count": (
			broadside_state["reload_rejected_count"]
		),
		"broadside_no_ammunition_rejected_count": (
			broadside_state["no_ammunition_rejected_count"]
		),
		"broadside_held_input_count": _broadside_held_input_count,
		"broadside_last_result": _last_broadside_result,
		"broadside_last_attempt_evidence": (
			_last_broadside_attempt_evidence.duplicate(true)
		),
		"broadside_successful_evidence": (
			_successful_broadside_evidence.duplicate(true)
		),
		"broadside_reload_rejected_evidence": (
			_reload_rejected_broadside_evidence.duplicate(true)
		),
		"broadside_inactive_rejected_evidence": (
			_inactive_rejected_broadside_evidence.duplicate(true)
		),
		"broadside_zero_ammunition_rejected_evidence": (
			_zero_ammunition_rejected_broadside_evidence.duplicate(true)
		),
		"broadside_held_rejected_evidence": (
			_held_rejected_broadside_evidence.duplicate(true)
		),
		"broadside_ship_state": broadside_state,
		"broadside_view_count": get_tree().get_nodes_in_group(
			"broadside_view"
		).size(),
		"broadside_view_visible": broadside_view.visible,
		"broadside_view_text": (
			broadside_view_text if broadside_view.visible else ""
		),
		"broadside_view_shows_left_and_right": (
			broadside_view_text.contains("[Q] LEFT")
			and broadside_view_text.contains("[F] RIGHT")
		),
		"broadside_view_shows_reload": (
			broadside_view_text.contains("BROADSIDE · READY")
			or broadside_view_text.contains("BROADSIDE · RELOADING")
			or broadside_view_text.contains("BROADSIDE · NO AMMUNITION")
		),
		"target_hull_states": target_hull_states,
		"target_sail_states": target_sail_states,
		"target_condition_states": target_condition_states,
		"target_boarding_states": target_boarding_states,
		"boarding_system_count": 1,
		"boarding_state_owner_count_per_target": 1,
		"boarding_state_owner_count_holds": boarding_state_owner_count_holds,
		"boarding_hull_weak_threshold": (
			InspectableTargetShipState.BOARDING_HULL_WEAK_THRESHOLD
		),
		"boarding_sail_weak_threshold": (
			InspectableTargetShipState.BOARDING_SAIL_WEAK_THRESHOLD
		),
		"boarding_alongside_range": (
			InspectableTargetShipState.BOARDING_ALONGSIDE_RANGE
		),
		"boarding_condition_rule": "HULL_OR_SAILS_WEAK",
		"boarding_ready_target_ids": boarding_ready_target_ids,
		"boarding_ready_target_count": boarding_ready_target_ids.size(),
		"boarding_prompt_target_ids": boarding_prompt_target_ids,
		"boarding_prompt_target_count": boarding_prompt_target_ids.size(),
		"boarding_prompt_visible": boarding_prompt_visible,
		"boarding_prompt_text": (
			interaction_prompt.text if boarding_prompt_visible else ""
		),
		"boarding_prompt_count": 1 if boarding_prompt_visible else 0,
		"boarding_prompt_node_count": get_tree().get_nodes_in_group(
			"target_boarding_prompt"
		).size(),
		"boarding_exactly_one_prompt_when_visible": (
			not boarding_prompt_visible
			or (
				get_tree().get_nodes_in_group("target_boarding_prompt").size()
					== 1
			)
		),
		"boarding_selected_prompt_target_id": (
			_near_boarding_target.target_id
			if boarding_prompt_visible and _near_boarding_target != null
			else ""
		),
		"boarding_target_visual_prompt_count": 0,
		"boarding_prompt_contract_holds": boarding_prompt_contract_holds,
		"boarding_nonweak_target_has_no_board_prompt": (
			boarding_prompt_contract_holds
		),
		"boarding_prompt_has_priority_over_inspection": (
			not boarding_prompt_visible
			or not _can_inspect_nearby_target()
		),
		"boarding_far_denial_target_ids": boarding_far_denial_target_ids,
		"boarding_far_denial_target_count": (
			boarding_far_denial_target_ids.size()
		),
		"boarding_last_far_denial_distance": (
			boarding_last_far_denial_distance
		),
		"boarding_far_denial_holds": boarding_far_denial_holds,
		"boarding_weak_far_target_has_no_board_prompt": (
			boarding_far_denial_holds
		),
		"boarding_active_target_ids": boarding_active_target_ids,
		"boarding_active_target_count": boarding_active_target_ids.size(),
		"boarding_resolved_target_ids": boarding_resolved_target_ids,
		"boarding_resolved_target_count": boarding_resolved_target_ids.size(),
		"boarding_unresolved_target_ids": boarding_unresolved_target_ids,
		"boarding_unresolved_target_count": (
			boarding_unresolved_target_ids.size()
		),
		"boarding_resolved_no_repeat_prompt_holds": (
			boarding_resolved_no_repeat_prompt_holds
		),
		"boarding_each_target_resolves_at_most_once": (
			boarding_each_target_resolves_at_most_once
		),
		"boarding_resolution_preserves_route_condition": (
			boarding_resolution_preserves_route_condition
		),
		"boarding_attempt_count": _boarding_attempt_count,
		"boarding_success_count": _boarding_success_count,
		"boarding_return_count": _boarding_return_count,
		"boarding_held_interaction_count": _boarding_held_interaction_count,
		"boarding_blocked_input_count": _boarding_blocked_input_count,
		"boarding_fresh_press_required": true,
		"boarding_last_attempt_evidence": (
			_last_boarding_attempt_evidence.duplicate(true)
		),
		"boarding_successful_evidence": (
			_successful_boarding_evidence.duplicate(true)
		),
		"boarding_last_held_evidence": (
			_last_held_boarding_evidence.duplicate(true)
		),
		"boarding_last_return_evidence": (
			_last_boarding_return_evidence.duplicate(true)
		),
		"player_on_target_deck": _player_on_target_deck,
		"player_near_boarding_return": _player_near_boarding_return,
		"boarding_return_prompt_visible": boarding_return_prompt_visible,
		"boarding_return_prompt_text": (
			interaction_prompt.text if boarding_return_prompt_visible else ""
		),
		"boarding_deck_state": boarding_deck_state,
		"boarding_deck_active": boarding_deck_state["active"],
		"boarding_deck_visible": boarding_deck_state["visible"],
		"boarding_deck_compact": boarding_deck_state["compact"],
		"boarding_deck_empty": boarding_deck_state["empty"],
		"boarding_deck_size": boarding_deck_state["deck_size"],
		"boarding_deck_walk_rect": boarding_deck_state["walk_rect"],
		"boarding_deck_entry_position": boarding_deck_state["entry_position"],
		"boarding_deck_return_position": boarding_deck_state["return_position"],
		"boarding_deck_return_range": boarding_deck_state["return_range"],
		"boarding_deck_return_point_count": (
			boarding_deck_state["return_point_count"]
		),
		"boarding_deck_return_point_visible": (
			boarding_deck_state["return_point_visible"]
		),
		"boarding_player_inside_deck_bounds": (
			boarding_deck_state["player_inside_bounds"]
		),
		"boarding_walk_distance": _boarding_walk_distance,
		"boarding_furthest_distance_from_entry": _boarding_furthest_distance,
		"boarding_walk_across_distance": (
			TargetBoardingDeckState.WALK_ACROSS_DISTANCE
		),
		"boarding_walked_across_deck": _boarding_walked_across_deck,
		"boarding_deck_bounds_held": _boarding_deck_bounds_held,
		"boarding_last_target_id": _last_boarded_target_id,
		"boarding_conservation_before": (
			_boarding_conservation_before.duplicate(true)
		),
		"boarding_conservation_after": (
			_boarding_conservation_after.duplicate(true)
		),
		"boarding_state_conservation_holds": (
			_boarding_state_conservation_holds
		),
		"prize_action_state": prize_state,
		"prize_action_system_count": prize_state["system_count"],
		"prize_action_owner_count": prize_state["owner_count"],
		"prize_screen_open": prize_state["screen_open"],
		"prize_screen_open_count": prize_state["screen_open_count"],
		"prize_screen_open_counts_by_target": (
			prize_state["screen_open_counts_by_target"]
		),
		"prize_current_target_screen_open_count": (
			prize_state["current_target_screen_open_count"]
		),
		"prize_screen_close_count": prize_state["screen_close_count"],
		"prize_screen_opens_once_per_victory": (
			prize_state["opens_once_per_victory"]
		),
		"prize_screen_opened_after_fight_victory": (
			not _prize_opened_for_current_boarding
			or (
				bool(boarding_deck_state["fight_ended"])
				and _prize_trigger_fight_outcome in ["SURRENDER", "DEFEAT"]
			)
		),
		"prize_trigger_fight_outcome": _prize_trigger_fight_outcome,
		"prize_target_resolution_evidence": (
			_prize_target_resolution_evidence.duplicate(true)
		),
		"prize_opens_for_surrender_or_defeat": true,
		"prize_resolved_target_cannot_prompt_again": (
			boarding_resolved_no_repeat_prompt_holds
		),
		"prize_resolved_target_cannot_open_second_screen": (
			resolved_targets_have_one_prize_screen_max
		),
		"prize_two_distinct_targets_one_victory_each_eligible": (
			two_distinct_targets_one_victory_each_eligible
		),
		"prize_view_count": get_tree().get_nodes_in_group(
			"prize_action_screen"
		).size(),
		"prize_view_visible": prize_view.visible,
		"prize_view_text": prize_view_text,
		"prize_view_shows_exactly_four_types": prize_view_shows_four_types,
		"prize_view_shows_action_limit_before_choice": (
			prize_view.visible
			and prize_view_text.contains("PRIZE ACTIONS")
			and prize_view_text.contains("EACH SUCCESS USES 1 ACTION")
		),
		"prize_type_count": prize_state["prize_type_count"],
		"prize_types": prize_state["prize_types"],
		"prize_action_limit": prize_state["action_limit"],
		"prize_actions_remaining": prize_state["actions_remaining"],
		"prize_actions_used": prize_state["actions_used"],
		"prize_action_limit_prevents_all_four": (
			prize_state["action_limit_prevents_taking_all_four"]
		),
		"prize_low_hull_threshold_percent": (
			prize_state["low_hull_threshold_percent"]
		),
		"prize_low_hull_action_limit": prize_state["low_hull_action_limit"],
		"prize_low_hull_reduction_applied": (
			prize_state["low_hull_reduction_applied"]
		),
		"prize_low_hull_reduces_action_limit": (
			prize_state["low_hull_reduces_action_limit"]
		),
		"prize_selected_types": prize_state["selected_prize_types"],
		"prize_selected_count": prize_state["selected_prize_count"],
		"prize_awarded_cargo_lots": prize_state["awarded_cargo_lots"],
		"prize_awarded_cargo_lot_count": (
			prize_state["awarded_cargo_lot_count"]
		),
		"prize_current_victory_awarded_cargo_lot_count": (
			prize_state["current_victory_awarded_cargo_lot_count"]
		),
		"prize_cumulative_awarded_cargo_lot_count": (
			prize_state["cumulative_awarded_cargo_lot_count"]
		),
		"prize_cargo_lot_name": prize_state["cargo_prize_lot_name"],
		"prize_cannon_cargo_lot_name": prize_state["cannon_cargo_lot_name"],
		"prize_cannon_is_usable": prize_state["cannon_is_usable"],
		"prize_cannon_is_sellable_cargo": (
			prize_state["cannon_is_sellable_cargo"]
		),
		"prize_cannon_sale_price": PRIZE_CANNON_CARGO_SALE_PRICE,
		"prize_cannon_sale_count": _prize_cannon_sale_count,
		"prize_cannon_money_earned": _prize_cannon_money_earned,
		"prize_last_cannon_sale_evidence": (
			_last_prize_cannon_sale_evidence.duplicate(true)
		),
		"prize_repair_material_lot_name": (
			prize_state["repair_material_cargo_lot_name"]
		),
		"prize_repair_material_uses_existing_timber": (
			prize_state["repair_material_uses_existing_timber"]
		),
		"prize_trade_records_taken": prize_state["trade_records_taken"],
		"prize_trade_records_update_one_port_entry": (
			prize_state["trade_records_update_one_port_entry"]
		),
		"prize_successful_selection_count": (
			prize_state["successful_selection_count"]
		),
		"prize_denied_selection_count": (
			prize_state["denied_selection_count"]
		),
		"prize_exhausted_rejection_count": (
			prize_state["exhausted_rejection_count"]
		),
		"prize_cargo_full_rejection_count": (
			prize_state["cargo_full_rejection_count"]
		),
		"prize_held_input_count": prize_state["held_input_count"],
		"prize_held_close_count": _prize_held_close_count,
		"prize_last_result": prize_state["last_result"],
		"prize_last_open_evidence": (
			prize_state["last_open_evidence"].duplicate(true)
		),
		"prize_last_selection_evidence": (
			prize_state["last_selection_evidence"].duplicate(true)
		),
		"prize_last_denied_selection_evidence": (
			prize_state["last_denied_selection_evidence"].duplicate(true)
		),
		"prize_last_held_input_evidence": (
			prize_state["last_held_input_evidence"].duplicate(true)
		),
		"prize_close_evidence": _prize_close_evidence.duplicate(true),
		"prize_returned_to_player_ship": _prize_returned_to_player_ship,
		"prize_selected_prizes_persist": (
			prize_state["selected_prizes_persist"]
		),
		"prize_trade_records_persist": prize_state["trade_records_persist"],
		"prize_persistence_after_return_holds": (
			prize_state["persistence_after_return_holds"]
		),
		"prize_ship_capture_system_count": (
			prize_state["ship_capture_system_count"]
		),
		"prize_ransom_system_count": prize_state["ransom_system_count"],
		"prize_prisoner_system_count": prize_state["prisoner_system_count"],
		"prize_cannon_module_system_count": (
			prize_state["cannon_module_system_count"]
		),
		"prize_story_clue_system_count": (
			prize_state["story_clue_system_count"]
		),
		"prize_crew_injury_system_count": (
			prize_state["crew_injury_system_count"]
		),
		"prize_heat_change_count": prize_state["heat_change_count"],
		"boarding_target_hull_above_zero_at_entry": bool(
			_successful_boarding_evidence.get("target_hull_above_zero", false)
		),
		"boarding_target_condition_unchanged_on_return": bool(
			last_boarding_finish_evidence.get("condition_unchanged", false)
		),
		"boarding_target_route_stable_on_deck": (
			boarding_target_route_stable
		),
		"boarding_navigation_blocked_on_deck": (
			not _player_on_target_deck or ship.navigation_input_blocked
		),
		"boarding_broadside_blocked_on_deck": (
			not _player_on_target_deck or not ship.are_broadside_firing_areas_active()
		),
		"boarding_chart_blocked_on_deck": (
			not _player_on_target_deck or not waypoint_display.chart_visible
		),
		"boarding_persistent_hud_hidden_on_deck": (
			not _player_on_target_deck
			or (not cargo_view.visible and not money_view.visible)
		),
		"boarding_combat_owner_count": boarding_deck_state["combat_owner_count"],
		"boarding_defender_count": boarding_deck_state["defender_count"],
		"boarding_alive_defender_count": (
			boarding_deck_state["alive_defender_count"]
		),
		"boarding_hostile_defender_count": (
			boarding_deck_state["hostile_defender_count"]
		),
		"boarding_on_foot_combat_system_count": (
			boarding_deck_state["on_foot_combat_system_count"]
		),
		"boarding_combat_active": boarding_deck_state["combat_active"],
		"boarding_fight_ended": boarding_deck_state["fight_ended"],
		"boarding_player_health_max": boarding_deck_state["player_health_max"],
		"boarding_player_health_current": (
			boarding_deck_state["player_health_current"]
		),
		"boarding_defender_health_max": (
			boarding_deck_state["defender_health_max"]
		),
		"boarding_defender_health_current": (
			boarding_deck_state["defender_health_current"]
		),
		"boarding_health_meter_count": boarding_deck_state["health_meter_count"],
		"boarding_health_meters_visible": (
			boarding_deck_state["health_meters_visible"]
		),
		"boarding_player_health_meter_text": (
			boarding_deck_state["player_health_meter_text"]
		),
		"boarding_defender_health_meter_text": (
			boarding_deck_state["defender_health_meter_text"]
		),
		"boarding_combat_player_position": boarding_deck_state["player_position"],
		"boarding_defender_position": boarding_deck_state["defender_position"],
		"boarding_defender_start_position": (
			boarding_deck_state["defender_start_position"]
		),
		"boarding_player_defender_distance": (
			boarding_deck_state["player_defender_distance"]
		),
		"boarding_cutlass_system_count": boarding_deck_state["cutlass_system_count"],
		"boarding_cutlass_attack_type_count": (
			boarding_deck_state["cutlass_attack_type_count"]
		),
		"boarding_cutlass_attack_type": boarding_deck_state["cutlass_attack_type"],
		"boarding_cutlass_key": boarding_deck_state["cutlass_key"],
		"boarding_cutlass_fresh_press_required": (
			boarding_deck_state["cutlass_fresh_press_required"]
		),
		"boarding_cutlass_range": boarding_deck_state["cutlass_range"],
		"boarding_cutlass_damage": boarding_deck_state["cutlass_damage"],
		"boarding_cutlass_attempt_count": (
			boarding_deck_state["cutlass_attempt_count"]
		),
		"boarding_cutlass_hit_count": boarding_deck_state["cutlass_hit_count"],
		"boarding_cutlass_out_of_range_count": (
			boarding_deck_state["cutlass_out_of_range_count"]
		),
		"boarding_cutlass_held_input_count": (
			boarding_deck_state["cutlass_held_input_count"]
		),
		"boarding_cutlass_cooldown_rejection_count": (
			boarding_deck_state["cutlass_cooldown_rejection_count"]
		),
		"boarding_cutlass_fight_ended_rejection_count": (
			boarding_deck_state["cutlass_fight_ended_rejection_count"]
		),
		"boarding_cutlass_damage_total": (
			boarding_deck_state["cutlass_damage_total"]
		),
		"boarding_cutlass_cooldown_remaining": (
			boarding_deck_state["cutlass_cooldown_remaining"]
		),
		"boarding_last_cutlass_evidence": (
			boarding_deck_state["last_cutlass_evidence"].duplicate(true)
		),
		"boarding_defender_attack_system_count": (
			boarding_deck_state["defender_attack_system_count"]
		),
		"boarding_defender_attack_type_count": (
			boarding_deck_state["defender_attack_type_count"]
		),
		"boarding_defender_attack_type": (
			boarding_deck_state["defender_attack_type"]
		),
		"boarding_defender_attack_range": (
			boarding_deck_state["defender_attack_range"]
		),
		"boarding_defender_attack_damage": (
			boarding_deck_state["defender_attack_damage"]
		),
		"boarding_defender_attack_cooldown": (
			boarding_deck_state["defender_attack_cooldown"]
		),
		"boarding_defender_chase_range": (
			boarding_deck_state["defender_chase_range"]
		),
		"boarding_defender_move_speed": boarding_deck_state["defender_move_speed"],
		"boarding_defender_move_frame_count": (
			boarding_deck_state["defender_move_frame_count"]
		),
		"boarding_defender_movement_distance": (
			boarding_deck_state["defender_movement_distance"]
		),
		"boarding_defender_entered_range_count": (
			boarding_deck_state["defender_entered_range_count"]
		),
		"boarding_defender_left_range_count": (
			boarding_deck_state["defender_left_range_count"]
		),
		"boarding_player_in_defender_attack_range": (
			boarding_deck_state["player_in_defender_attack_range"]
		),
		"boarding_defender_attack_count": (
			boarding_deck_state["defender_attack_count"]
		),
		"boarding_player_damage_total": boarding_deck_state["player_damage_total"],
		"boarding_last_defender_attack_evidence": (
			boarding_deck_state["last_defender_attack_evidence"].duplicate(true)
		),
		"boarding_player_damage_feedback_count": (
			boarding_deck_state["player_damage_feedback_count"]
		),
		"boarding_player_damage_feedback_visible": (
			boarding_deck_state["player_damage_feedback_visible"]
		),
		"boarding_player_damage_feedback_text": (
			boarding_deck_state["player_damage_feedback_text"]
		),
		"boarding_defender_damage_feedback_count": (
			boarding_deck_state["defender_damage_feedback_count"]
		),
		"boarding_defender_damage_feedback_visible": (
			boarding_deck_state["defender_damage_feedback_visible"]
		),
		"boarding_defender_damage_feedback_text": (
			boarding_deck_state["defender_damage_feedback_text"]
		),
		"boarding_fight_feedback_visible": (
			boarding_deck_state["fight_feedback_visible"]
		),
		"boarding_fight_feedback_text": boarding_deck_state["fight_feedback_text"],
		"boarding_defender_defeat_count": (
			boarding_deck_state["defender_defeat_count"]
		),
		"boarding_defender_movement_stopped_after_defeat": (
			boarding_deck_state["defender_movement_stopped_after_defeat"]
		),
		"boarding_defender_attacks_stopped_after_defeat": (
			boarding_deck_state["defender_attacks_stopped_after_defeat"]
		),
		"boarding_no_gore": boarding_deck_state["no_gore"],
		"boarding_gore_effect_count": boarding_deck_state["gore_effect_count"],
		"boarding_pistol_system_count": boarding_deck_state["pistol_system_count"],
		"boarding_dodge_system_count": boarding_deck_state["dodge_system_count"],
		"boarding_parry_system_count": boarding_deck_state["parry_system_count"],
		"boarding_officer_ability_system_count": (
			boarding_deck_state["officer_ability_system_count"]
		),
		"boarding_surrender_system_count": (
			boarding_deck_state["surrender_system_count"]
		),
		"boarding_surrender_owner_count": (
			boarding_deck_state["surrender_owner_count"]
		),
		"boarding_morale_owner_count": boarding_deck_state["morale_owner_count"],
		"boarding_morale_meter_count": boarding_deck_state["morale_meter_count"],
		"boarding_morale_meter_visible": (
			boarding_deck_state["morale_meter_visible"]
		),
		"boarding_defender_morale_max": boarding_deck_state["defender_morale_max"],
		"boarding_defender_morale_current": (
			boarding_deck_state["defender_morale_current"]
		),
		"boarding_defender_morale_profile": (
			boarding_deck_state["defender_morale_profile"]
		),
		"boarding_selected_morale_profile": (
			boarding_deck_state["selected_morale_profile"]
		),
		"boarding_selected_morale_capacity": (
			boarding_deck_state["selected_morale_capacity"]
		),
		"boarding_morale_meter_text": boarding_deck_state["morale_meter_text"],
		"boarding_morale_damage_per_cutlass_hit": (
			boarding_deck_state["morale_damage_per_cutlass_hit"]
		),
		"boarding_morale_damage_total": (
			boarding_deck_state["morale_damage_total"]
		),
		"boarding_last_morale_damage": boarding_deck_state["last_morale_damage"],
		"boarding_morale_reduces_with_defender_damage": (
			boarding_deck_state["morale_reduces_with_defender_damage"]
		),
		"boarding_surrender_count": boarding_deck_state["surrender_count"],
		"boarding_surrendered_defender_count": (
			boarding_deck_state["surrendered_defender_count"]
		),
		"boarding_defender_surrendered": (
			boarding_deck_state["defender_surrendered"]
		),
		"boarding_defender_alive_at_surrender": (
			boarding_deck_state["defender_alive_at_surrender"]
		),
		"boarding_defender_health_above_zero_at_surrender": (
			boarding_deck_state["defender_health_above_zero_at_surrender"]
		),
		"boarding_surrender_before_health_zero": (
			boarding_deck_state["surrender_before_health_zero"]
		),
		"boarding_surrender_timing_exact": (
			boarding_deck_state["surrender_timing_exact"]
		),
		"boarding_surrender_route_target_id": (
			boarding_deck_state["surrender_route_target_id"]
		),
		"boarding_surrender_route_morale_max": (
			boarding_deck_state["surrender_route_morale_max"]
		),
		"boarding_defeat_path_target_id": (
			boarding_deck_state["defeat_path_target_id"]
		),
		"boarding_defeat_path_morale_max": (
			boarding_deck_state["defeat_path_morale_max"]
		),
		"boarding_defeat_path_available": (
			boarding_deck_state["defeat_path_available"]
		),
		"boarding_defeat_path_contract_holds": (
			boarding_deck_state["defeat_path_contract_holds"]
		),
		"boarding_defeat_path_evidence": (
			boarding_deck_state["defeat_path_evidence"].duplicate(true)
		),
		"boarding_last_surrender_evidence": (
			boarding_deck_state["last_surrender_evidence"].duplicate(true)
		),
		"boarding_fight_outcome": boarding_deck_state["fight_outcome"],
		"boarding_surrender_pose_count": (
			boarding_deck_state["surrender_pose_count"]
		),
		"boarding_surrender_pose_visible": (
			boarding_deck_state["surrender_pose_visible"]
		),
		"boarding_defender_weapon_visible": (
			boarding_deck_state["defender_weapon_visible"]
		),
		"boarding_defender_weapon_disabled_after_surrender": (
			boarding_deck_state["defender_weapon_disabled_after_surrender"]
		),
		"boarding_defender_movement_stopped_after_surrender": (
			boarding_deck_state["defender_movement_stopped_after_surrender"]
		),
		"boarding_defender_attacks_stopped_after_surrender": (
			boarding_deck_state["defender_attacks_stopped_after_surrender"]
		),
		"boarding_post_surrender_cutlass_rejection_count": (
			boarding_deck_state["post_surrender_cutlass_rejection_count"]
		),
		"boarding_last_post_surrender_cutlass_evidence": (
			boarding_deck_state["last_post_surrender_cutlass_evidence"].duplicate(true)
		),
		"boarding_post_surrender_cutlass_no_state_change": (
			boarding_deck_state["post_surrender_cutlass_no_state_change"]
		),
		"boarding_execution_system_count": (
			boarding_deck_state["execution_system_count"]
		),
		"boarding_ransom_system_count": boarding_deck_state["ransom_system_count"],
		"boarding_prisoner_system_count": (
			boarding_deck_state["prisoner_system_count"]
		),
		"boarding_crew_trading_system_count": (
			boarding_deck_state["crew_trading_system_count"]
		),
		"boarding_prize_action_system_count": (
			boarding_deck_state["prize_action_system_count"]
		),
		"boarding_relationship_reaction_count": (
			boarding_deck_state["relationship_reaction_count"]
		),
		"boarding_ship_capture_system_count": (
			boarding_deck_state["ship_capture_system_count"]
		),
		"boarding_reward_system_count": (
			boarding_deck_state["reward_system_count"]
		),
		"boarding_heat_change_count": boarding_deck_state["heat_change_count"],
		"boarding_crew_injury_system_count": (
			boarding_deck_state["crew_injury_system_count"]
		),
		"boarding_player_defeat_system_count": (
			boarding_deck_state["player_defeat_system_count"]
		),
		"boarding_defeat_recovery_system_count": (
			boarding_deck_state["defeat_recovery_system_count"]
		),
		"target_hull_max": InspectableTargetShipState.HULL_MAX,
		"target_sail_max": InspectableTargetShipState.SAIL_MAX,
		"target_sail_state_owner_count_per_target": 1,
		"target_full_sail_speed": InspectableTargetShipState.FULL_SAIL_SPEED,
		"target_minimum_sail_speed": (
			InspectableTargetShipState.MINIMUM_SAIL_SPEED
		),
		"target_speed_steps": [320.0, 240.0, 170.0, 100.0, 40.0],
		"routed_target_ids": routed_target_ids,
		"routed_target_count": routed_target_ids.size(),
		"routed_target_faster_than_player_top_speed": (
			InspectableTargetShipState.FULL_SAIL_SPEED
				> float(ship_state["top_speed"])
		),
		"caught_target_ids": caught_target_ids,
		"caught_target_count": caught_target_ids.size(),
		"disabled_target_ids": disabled_target_ids,
		"disabled_target_count": disabled_target_ids.size(),
		"target_hit_feedback_duration": (
			InspectableTargetShipState.HIT_FEEDBACK_DURATION
		),
		"target_combat_view_count": get_tree().get_nodes_in_group(
			"target_combat_view"
		).size(),
		"target_combat_view_visible": target_combat_view.visible,
		"target_combat_view_text": (
			target_combat_view_text if target_combat_view.visible else ""
		),
		"target_combat_view_selected_state_visible": (
			target_combat_view_text.contains("> HULL <")
			or target_combat_view_text.contains("> SAILS <")
		),
		"target_combat_view_has_exact_hull_and_sails": (
			target_combat_view_text.contains("HULL ·")
			and target_combat_view_text.contains("SAILS ·")
		),
		"target_combat_view_has_speed_step": (
			target_combat_view_text.contains("SPEED ·")
			and target_combat_view_text.contains("STEP")
		),
		"target_combat_hull_meter_value": target_hull_meter.value,
		"target_combat_hull_meter_max": target_hull_meter.max_value,
		"target_combat_sail_meter_value": target_sail_meter.value,
		"target_combat_sail_meter_max": target_sail_meter.max_value,
		"target_combat_catch_status": catch_status.text,
		"broadside_uses_ammunition": broadside_state["uses_ammunition"],
		"broadside_normal_ammunition_cost": (
			broadside_state["normal_ammunition_cost"]
		),
		"broadside_same_cost_for_both_attack_choices": (
			broadside_state["same_cost_for_all_attack_choices"]
		),
		"broadside_ammunition_system_count": ammunition_state["system_count"],
		"ammunition_system_count": ammunition_state["system_count"],
		"ammunition_type_count": ammunition_state["ammunition_type_count"],
		"ammunition_units": ammunition_state["ammunition_units"],
		"ammunition_units_per_loaded_lot": (
			ammunition_state["units_per_loaded_lot"]
		),
		"ammunition_source_cargo_lot_name": (
			ammunition_state["source_cargo_lot_name"]
		),
		"ammunition_loaded_cargo_lot_prefix": (
			ammunition_state["loaded_cargo_lot_prefix"]
		),
		"ammunition_source_cargo_fixed_price": (
			ammunition_state["source_cargo_fixed_price"]
		),
		"ammunition_source_lot_count": ammunition_state["source_lot_count"],
		"ammunition_loaded_lot_count": ammunition_state["loaded_lot_count"],
		"ammunition_low_warning": ammunition_state["low_ammunition_warning"],
		"ammunition_no_warning": ammunition_state["no_ammunition_warning"],
		"ammunition_total_units_loaded": ammunition_state["total_units_loaded"],
		"ammunition_total_units_consumed": (
			ammunition_state["total_units_consumed"]
		),
		"ammunition_depleted_lot_count": ammunition_state["depleted_lot_count"],
		"ammunition_cargo_lot_consumed_only_at_zero": (
			ammunition_state[
				"cargo_lot_consumed_only_when_ammunition_reaches_zero"
			]
		),
		"ammunition_load_attempt_count": ammunition_state["load_attempt_count"],
		"ammunition_load_success_count": ammunition_state["load_success_count"],
		"ammunition_load_denied_count": ammunition_state["load_denied_count"],
		"ammunition_last_load_evidence": ammunition_state["last_load_evidence"],
		"ammunition_successful_load_evidence": (
			ammunition_state["successful_load_evidence"]
		),
		"ammunition_last_denied_load_evidence": (
			ammunition_state["last_denied_load_evidence"]
		),
		"ammunition_last_consumption_evidence": (
			ammunition_state["last_consumption_evidence"]
		),
		"ammunition_main_last_load_evidence": (
			_last_ammunition_load_evidence.duplicate(true)
		),
		"ammunition_supply_purchase_key": "B",
		"ammunition_port_load_key": "L",
		"ammunition_trade_keys_use_fresh_press_guard": true,
		"ammunition_trade_release_guard_includes_b_and_l": (
			TRADE_RELEASE_CONTROLS_TEXT.contains("B")
			and TRADE_RELEASE_CONTROLS_TEXT.contains("L")
		),
		"ammunition_last_held_trade_evidence": (
			_last_held_ammunition_trade_evidence.duplicate(true)
		),
		"ammunition_supply_purchase_attempt_count": (
			_ammunition_supply_purchase_attempt_count
		),
		"ammunition_supply_purchase_success_count": (
			_ammunition_supply_purchase_success_count
		),
		"ammunition_supply_purchase_denied_count": (
			_ammunition_supply_purchase_denied_count
		),
		"ammunition_supply_purchased_lot_count": (
			_ammunition_supply_purchased_lot_count
		),
		"ammunition_supply_money_spent": _ammunition_supply_money_spent,
		"ammunition_last_supply_purchase_evidence": (
			_last_ammunition_supply_purchase_evidence.duplicate(true)
		),
		"ammunition_successful_supply_purchase_evidence": (
			_successful_ammunition_supply_purchase_evidence.duplicate(true)
		),
		"ammunition_last_denied_supply_purchase_evidence": (
			_last_denied_ammunition_supply_purchase_evidence.duplicate(true)
		),
		"ammunition_view_count": get_tree().get_nodes_in_group(
			"ship_ammunition_view"
		).size(),
		"ammunition_view_visible": ammunition_view.visible,
		"ammunition_view_text": (
			ammunition_view_full_text if ammunition_view.visible else ""
		),
		"ammunition_view_exact_count_visible": (
			not ammunition_view.visible
			or ammunition_view_full_text.contains(
				"AMMUNITION · %d" % ammunition_state["ammunition_units"]
			)
		),
		"ammunition_view_low_warning_exactly_at_two": (
			(ammunition_status.text == "LOW AMMUNITION")
			== (int(ammunition_state["ammunition_units"]) == 2)
		),
		"ammunition_view_zero_block_visible": (
			int(ammunition_state["ammunition_units"]) != 0
			or ammunition_status.text.contains("BROADSIDES BLOCKED")
		),
		"ammunition_loaded_lot_uses_one_cargo_slot": true,
		"ammunition_conversion_is_cargo_neutral": true,
		"ammunition_free_at_sea_count": (
			ammunition_state["free_ammunition_at_sea_count"]
		),
		"ammunition_cannon_upgrade_count": (
			ammunition_state["cannon_upgrade_count"]
		),
		"ammunition_prize_cannon_count": ammunition_state["prize_cannon_count"],
		"ammunition_crew_task_count": (
			ammunition_state["crew_ammunition_task_count"]
		),
		"broadside_sail_damage_system_count": (
			broadside_state["sail_damage_system_count"]
		),
		"broadside_boarding_system_count": (
			broadside_state["boarding_system_count"]
		),
		"broadside_prize_action_system_count": (
			broadside_state["prize_action_system_count"]
		),
		"broadside_heat_change_system_count": (
			broadside_state["heat_change_system_count"]
		),
		"ship_defeat_system_count": defeat_state["system_count"],
		"ship_recovery_system_count": defeat_state["system_count"],
		"repair_system_count": repair_state["system_count"],
		"repair_available": repair_state["available"],
		"repair_denial_reasons": repair_state["denial_reasons"],
		"repair_status_text": repair_state["status_text"],
		"repair_fixed_amount": repair_state["fixed_repair_amount"],
		"repair_cost_lot_name": repair_state["cost_lot_name"],
		"repair_cost_lot_count": repair_state["cost_lot_count"],
		"repair_fixed_cost_text": repair_state["fixed_cost_text"],
		"repair_uses_money": repair_state["uses_money"],
		"repair_hull_before_preview": repair_state["hull_before_preview"],
		"repair_hull_after_preview": repair_state["hull_after_preview"],
		"repair_hull_gain_preview": repair_state["hull_gain_preview"],
		"repair_preview_text": repair_state["preview_text"],
		"repair_ship_timber_count": repair_state["ship_timber_count"],
		"repair_requires_captain_aboard": true,
		"repair_requires_docked_ship": true,
		"repair_manual_confirmation_required": (
			repair_state["manual_confirmation_required"]
		),
		"repair_confirmation_key": "R",
		"repair_attempt_count": repair_state["attempt_count"],
		"repair_success_count": repair_state["success_count"],
		"repair_denied_attempt_count": repair_state["denied_attempt_count"],
		"repair_consumed_timber_count": repair_state["consumed_timber_count"],
		"repair_damage_owner_count": repair_state["damage_owner_count"],
		"repair_damage_hit_count": repair_state["damage_hit_count"],
		"repair_damage_repair_count": repair_state["damage_repair_count"],
		"repair_key_held": _repair_key_held,
		"repair_held_input_count": _repair_held_input_count,
		"repair_fresh_press_required": true,
		"repair_last_action": _last_repair_action,
		"repair_last_result": _last_repair_result,
		"repair_last_attempt_evidence": (
			_last_repair_attempt_evidence.duplicate(true)
		),
		"repair_successful_evidence": (
			_successful_repair_evidence.duplicate(true)
		),
		"repair_last_denied_evidence": (
			_last_denied_repair_evidence.duplicate(true)
		),
		"repair_last_held_evidence": (
			_last_held_repair_evidence.duplicate(true)
		),
		"repair_ship_state": repair_state,
		"repair_view_count": get_tree().get_nodes_in_group(
			"ship_repair_view"
		).size(),
		"repair_view_visible": repair_view.visible,
		"repair_view_should_be_visible": (
			_player_aboard_ship and ship.is_docked
		),
		"repair_view_visibility_matches_docked_aboard": (
			repair_view.visible == (_player_aboard_ship and ship.is_docked)
		),
		"repair_view_title": repair_title.text,
		"repair_view_cost": repair_cost.text,
		"repair_view_preview": repair_preview.text,
		"repair_view_status": repair_status.text,
		"repair_view_result": repair_result.text,
		"repair_view_controls": repair_controls.text,
		"repair_view_text": (
			repair_view_full_text if repair_view.visible else ""
		),
		"repair_view_text_has_fixed_cost": repair_view_full_text.contains(
			"FIXED COST · 1 TIMBER LOT · NO MONEY"
		),
		"repair_view_text_has_preview": repair_view_full_text.contains(
			"PREVIEW · %s" % repair_state["preview_text"]
		),
		"repair_view_text_has_availability": repair_view_full_text.contains(
			String(repair_state["status_text"])
		),
		"repair_view_rect": repair_view_rect,
		"repair_view_below_hull_view": (
			repair_view_rect.position.y
				>= hull_view_rect.position.y + hull_view_rect.size.y
		),
		"repair_view_gap_below_hull": (
			repair_view_rect.position.y
				- (hull_view_rect.position.y + hull_view_rect.size.y)
		),
		"repair_view_overlaps_hull_view": (
			repair_view_rect.intersects(hull_view_rect)
		),
		"repair_view_overlaps_food_view": (
			repair_view_rect.intersects(food_view_rect)
		),
		"repair_view_overlaps_controls": (
			repair_view_rect.intersects(controls_help_rect)
		),
		"repair_snapshot_success": _repair_snapshot_success.duplicate(true),
		"repair_snapshot_ashore": _repair_snapshot_ashore.duplicate(true),
		"repair_snapshot_return": _repair_snapshot_return.duplicate(true),
		"repair_snapshot_release": _repair_snapshot_release.duplicate(true),
		"repair_hull_persists_ashore": _repair_checkpoint_matches_success(
			_repair_snapshot_ashore
		),
		"repair_hull_persists_on_return": _repair_checkpoint_matches_success(
			_repair_snapshot_return
		),
		"repair_hull_persists_after_release": _repair_checkpoint_matches_success(
			_repair_snapshot_release
		),
		"repair_persistence_holds": (
			_repair_checkpoint_matches_success(_repair_snapshot_ashore)
			and _repair_checkpoint_matches_success(_repair_snapshot_return)
			and _repair_checkpoint_matches_success(_repair_snapshot_release)
		),
		"repair_during_combat_system_count": 0,
		"repair_price_system_count": 0,
		"sail_repair_system_count": 0,
		"repair_workshop_bonus_system_count": 0,
		"automatic_repair_system_count": repair_state["automatic_repair_count"],
		"target_inspection_system_count": 1,
		"target_ship_count": inspection_targets.size(),
		"target_ship_ids": target_ship_ids,
		"target_ship_states": target_ship_states,
		"target_ship_estimates_are_distinct": (
			inspection_targets.size() >= 2
			and inspection_targets[0].get_estimate_state()
				!= inspection_targets[1].get_estimate_state()
		),
		"target_inspection_range": InspectableTargetShipState.INSPECTION_RANGE,
		"target_visibility_range": InspectableTargetShipState.VISIBILITY_RANGE,
		"near_inspection_target_id": (
			_near_inspection_target.target_id
			if _near_inspection_target != null
			else ""
		),
		"target_inspection_available": _can_inspect_nearby_target(),
		"target_inspection_prompt_visible": (
			interaction_prompt.visible
			and interaction_prompt.text.begins_with("[E] INSPECT")
		),
		"target_inspection_prompt_text": (
			interaction_prompt.text
			if interaction_prompt.visible
			and interaction_prompt.text.begins_with("[E] INSPECT")
			else ""
		),
		"target_inspection_view_open": _target_inspection_view_open,
		"target_inspection_view_visible": target_inspection_view.visible,
		"target_inspection_view_count": get_tree().get_nodes_in_group(
			"target_inspection_view"
		).size(),
		"target_inspection_view_text": target_inspection_view_text,
		"target_inspection_last_view_text": _last_inspection_view_text,
		"target_inspection_active_target_id": (
			_active_inspection_target.target_id
			if _active_inspection_target != null
			else ""
		),
		"target_inspection_active_estimate": active_inspection_estimate,
		"target_inspection_all_estimate_labels_visible": (
			estimate_labels_visible
		),
		"target_inspection_open_count": _target_inspection_open_count,
		"target_inspection_auto_close_count": (
			_target_inspection_auto_close_count
		),
		"target_inspection_last_close_reason": _last_inspection_close_reason,
		"target_inspection_last_auto_closed_target_id": (
			_last_auto_closed_target_id
		),
		"target_inspection_last_auto_close_distance": (
			_last_auto_close_distance
		),
		"target_inspection_auto_close_was_out_of_range": (
			_last_inspection_close_reason == "SAILED_OUT_OF_RANGE"
			and _last_auto_close_distance
				> InspectableTargetShipState.INSPECTION_RANGE
		),
		"target_inspection_inspected_target_ids": (
			_inspected_target_ids.duplicate()
		),
		"target_inspection_distinct_targets_inspected": (
			_inspected_target_ids.size() >= 2
		),
		"target_inspection_navigation_remains_enabled": (
			not _target_inspection_view_open
			or not ship.navigation_input_blocked
		),
		"target_inspection_changes_heat": false,
		"target_inspection_estimated_heat_not_applied": (
			_last_inspection_heat_preview.is_empty()
			or bool(_last_inspection_heat_preview.get(
				"preview_does_not_apply_heat",
				false,
			))
		),
		"target_inspection_peaceful_marker_visible": (
			target_inspection_view.visible
			and target_inspection_view_text.contains(
				"PEACEFUL ESTIMATE · YES"
			)
		),
		"target_inspection_peaceful_marker_matches_target": (
			not target_inspection_view.visible
			or target_inspection_view_text.contains(
				"PEACEFUL ESTIMATE · %s" % (
					"YES"
					if bool(active_inspection_estimate.get(
						"peaceful_estimate",
						false,
					))
					else "NO"
				)
			)
		),
		"target_inspection_exact_heat_estimate_visible": (
			target_inspection_view.visible
			and target_inspection_view_text.contains("HEAT COST ESTIMATE · +")
			and target_inspection_view_text.contains("WORLD HEAT PREVIEW ·")
			and target_inspection_view_text.contains("NOT APPLIED")
		),
		"target_inspection_exact_heat_estimate_matches_preview": (
			not target_inspection_view.visible
			or (
				not active_inspection_heat_preview.is_empty()
				and target_inspection_view_text.contains(
					"WORLD HEAT PREVIEW · %d -> %d (+%d)" % [
						active_inspection_heat_preview["heat_before"],
						active_inspection_heat_preview["heat_after"],
						active_inspection_heat_preview[
							"estimated_heat_increase"
						],
					]
				)
			)
		),
		"target_inspection_last_heat_preview": (
			_last_inspection_heat_preview.duplicate(true)
		),
		"active_heat_system_count": heat_state["system_count"],
		"world_heat": heat_state.duplicate(true),
		"world_heat_value": heat_state["current_heat"],
		"world_heat_step": heat_state["heat_step"],
		"world_heat_accounting_holds": heat_state["heat_accounting_holds"],
		"world_heat_changes_only_for_phase_events": (
			bool(heat_state["heat_accounting_holds"])
			and int(heat_state["current_heat"])
				== int(heat_state["total_heat_added"])
					- int(heat_state[
						"total_heat_removed_by_voyage_decay"
					])
		),
		"world_heat_meter_count": get_tree().get_nodes_in_group(
			"world_heat_view"
		).size(),
		"world_heat_one_full_world_meter": (
			int(heat_state["system_count"]) == 1
			and int(heat_state["meter_count"]) == 1
			and String(heat_state["scope"]) == "FULL_WORLD"
			and get_tree().get_nodes_in_group("world_heat_view").size() == 1
		),
		"world_heat_view_visible": heat_view.visible,
		"world_heat_view_text": heat_view_full_text,
		"world_heat_view_rect": heat_view_rect,
		"world_heat_meter_value": heat_meter.value,
		"world_heat_meter_max": heat_meter.max_value,
		"world_heat_view_matches_state": (
			heat_view_full_text.contains(
				"WORLD HEAT · %d" % heat_state["current_heat"]
			)
			and is_equal_approx(
				heat_meter.value,
				float(heat_state["current_heat"]),
			)
		),
		"world_heat_first_hit_matches_shown_amount": (
			heat_state["all_first_hits_matched_shown_amount"]
		),
		"world_heat_later_same_ship_hit_added_no_heat": (
			heat_state["all_repeat_hits_added_no_heat"]
		),
		"world_heat_last_load_before": _heat_before_last_ammunition_load,
		"world_heat_last_load_after": _heat_after_last_ammunition_load,
		"world_heat_persists_through_ammunition_load": (
			_last_ammunition_load_evidence.is_empty()
			or _heat_before_last_ammunition_load
				== _heat_after_last_ammunition_load
		),
		"heat_persistence_boundary_count": 1,
		"heat_persistence_path": HEAT_PERSISTENCE_PATH,
		"heat_persistence_format": HEAT_PERSISTENCE_FORMAT,
		"heat_persistence_version": HEAT_PERSISTENCE_VERSION,
		"heat_persistence_file_exists": FileAccess.file_exists(
			HEAT_PERSISTENCE_PATH
		),
		"heat_persistence_external_save_file_count": (
			1 if FileAccess.file_exists(HEAT_PERSISTENCE_PATH) else 0
		),
		"heat_persistence_save_count": _heat_persistence_save_count,
		"heat_persistence_load_count": _heat_persistence_load_count,
		"heat_persistence_cleanup_count": _heat_persistence_cleanup_count,
		"heat_persistence_startup_load_attempted": (
			_heat_persistence_startup_load_attempted
		),
		"heat_persistence_startup_restored": (
			_heat_persistence_startup_restored
		),
		"heat_persistence_last_payload": (
			_last_heat_persistence_payload.duplicate(true)
		),
		"heat_persistence_last_save_evidence": (
			_last_heat_file_save_evidence.duplicate(true)
		),
		"heat_persistence_last_load_evidence": (
			_last_heat_file_load_evidence.duplicate(true)
		),
		"heat_persistence_last_cleanup_evidence": (
			_last_heat_file_cleanup_evidence.duplicate(true)
		),
		"world_heat_owner_load_count": heat_state["load_count"],
		"heat_persistence_owner_load_counts_match": (
			int(heat_state["load_count"]) == _heat_persistence_load_count
		),
		"world_heat_last_owner_load_evidence": (
			(heat_state["last_load_evidence"] as Dictionary).duplicate(true)
		),
		"world_heat_persists_through_game_restart": (
			_last_heat_file_load_evidence.is_empty()
			or (
				bool(_last_heat_file_load_evidence.get("success", false))
				and bool(_last_heat_file_load_evidence.get(
					"rebased_snapshot_equality_holds",
					false,
				))
				and bool(_last_heat_file_load_evidence.get(
					"heat_value_restored",
					false,
				))
				and bool(_last_heat_file_load_evidence.get(
					"first_hit_identity_restored",
					false,
				))
				and bool(_last_heat_file_load_evidence.get(
					"loaded_first_hit_identity_blocks_duplicate_heat",
					false,
				))
				and bool(_last_heat_file_load_evidence.get(
					"current_voyage_attack_flag_restored",
					false,
				))
				and bool(_last_heat_file_load_evidence.get(
					"voyage_cursor_rebased_to_current_world",
					false,
				))
				and bool(_last_heat_file_load_evidence.get(
					"heat_accounting_holds_after_load",
					false,
				))
				and bool(_last_heat_file_load_evidence.get(
					"unrelated_state_unchanged",
					false,
				))
			)
		),
		"heat_persistence_startup_file_missing_is_clean": (
			_heat_persistence_startup_load_attempted
			and not _heat_persistence_startup_restored
			and String(_last_heat_file_load_evidence.get(
				"reason",
				"",
			)) == "FILE_NOT_FOUND"
			and bool(_last_heat_file_load_evidence.get(
				"world_heat_unchanged",
				false,
			))
			and bool(_last_heat_file_load_evidence.get(
				"unrelated_state_unchanged",
				false,
			))
		),
		"heat_persistence_no_unrelated_state_rollback": (
			_last_heat_file_load_evidence.is_empty()
			or bool(_last_heat_file_load_evidence.get(
				"unrelated_state_unchanged",
				false,
			))
		),
		"world_heat_last_dock_follows_voyage_rule": (
			_last_completed_voyage_evidence.is_empty()
			or (
				not bool(_last_completed_voyage_evidence.get("counted", false))
				and int(_last_completed_voyage_evidence.get(
					"world_heat_before",
					0,
				)) == int(_last_completed_voyage_evidence.get(
					"world_heat_after",
					0,
				))
			)
			or bool((_last_completed_voyage_evidence.get(
				"world_heat_transition",
				{},
			) as Dictionary).get(
				"decayed_exactly_one_step_when_possible",
				false,
			))
		),
		"world_heat_last_voyage_evidence": (
			(heat_state["last_voyage_evidence"] as Dictionary).duplicate(true)
		),
		"world_heat_decays_one_step_after_safe_voyage": (
			int(heat_state["voyage_decay_count"]) == 0
			or bool((heat_state["last_voyage_evidence"] as Dictionary).get(
				"decayed_exactly_one_step_when_possible",
				false,
			))
		),
		"world_heat_pirate_hunter_system_count": (
			hunter_state["system_count"]
		),
		"pirate_hunter_system_count": hunter_state["system_count"],
		"pirate_hunter_ship_count": get_tree().get_nodes_in_group(
			"pirate_hunter"
		).size(),
		"pirate_hunter_exactly_one_ship": (
			int(hunter_state["hunter_ship_count"]) == 1
			and get_tree().get_nodes_in_group("pirate_hunter").size() == 1
		),
		"pirate_hunter_heat_threshold": hunter_state["heat_threshold"],
		"pirate_hunter_current_heat": heat_state["current_heat"],
		"pirate_hunter_below_threshold_evidence": (
			(hunter_state["below_threshold_evidence"] as Dictionary).duplicate(
				true
			)
		),
		"pirate_hunter_absent_below_threshold": bool(
			(hunter_state["below_threshold_evidence"] as Dictionary).get(
				"absent",
				false,
			)
		),
		"pirate_hunter_warning_view_count": get_tree().get_nodes_in_group(
			"pirate_hunter_view"
		).size(),
		"pirate_hunter_warning_view_visible": pirate_hunter_view.visible,
		"pirate_hunter_warning_view_text": (
			pirate_hunter_status.text if pirate_hunter_view.visible else ""
		),
		"pirate_hunter_warning_active": hunter_state["warning_active"],
		"pirate_hunter_warning_count": hunter_state["warning_count"],
		"pirate_hunter_spawn_count": hunter_state["spawn_count"],
		"pirate_hunter_warning_sequence": hunter_state["warning_sequence"],
		"pirate_hunter_spawn_sequence": hunter_state["spawn_sequence"],
		"pirate_hunter_warning_precedes_arrival": (
			hunter_state["warning_precedes_spawn"]
		),
		"pirate_hunter_event_order_holds": (
			int(hunter_state["spawn_sequence"]) == 0
			or (
				int(hunter_state["warning_sequence"])
					< int(hunter_state["spawn_sequence"])
				and (
					int(hunter_state["first_chase_sequence"]) == 0
					or int(hunter_state["spawn_sequence"])
						< int(hunter_state["first_chase_sequence"])
				)
				and (
					int(hunter_state["first_attack_sequence"]) == 0
					or int(hunter_state["first_chase_sequence"])
						< int(hunter_state["first_attack_sequence"])
				)
			)
		),
		"pirate_hunter_active_encounter_count": (
			hunter_state["active_encounter_count"]
		),
		"pirate_hunter_one_encounter_maximum": (
			hunter_state["one_encounter_maximum"]
		),
		"pirate_hunter_encounter_active": hunter_state["encounter_active"],
		"pirate_hunter_encounter_resolved": (
			hunter_state["encounter_resolved"]
		),
		"pirate_hunter_outcome": hunter_state["outcome"],
		"pirate_hunter_chase_frame_count": (
			hunter_state["chase_frame_count"]
		),
		"pirate_hunter_total_chase_distance": (
			hunter_state["total_chase_distance"]
		),
		"pirate_hunter_chase_closed_distance": (
			hunter_state["chase_closed_distance"]
		),
		"pirate_hunter_distance_at_spawn": hunter_state["distance_at_spawn"],
		"pirate_hunter_closest_chase_distance": (
			hunter_state["closest_chase_distance"]
		),
		"pirate_hunter_attack_request_count": (
			hunter_state["attack_request_count"]
		),
		"pirate_hunter_attack_hit_count": hunter_state["attack_hit_count"],
		"pirate_hunter_last_attack_evidence": (
			(hunter_state["last_attack_evidence"] as Dictionary).duplicate(true)
		),
		"pirate_hunter_fixed_attack_damage": (
			damage_state["pirate_hunter_fixed_damage"]
		),
		"pirate_hunter_uses_fixed_existing_hull_path": (
			int(hunter_state["attack_request_count"]) == 0
			or bool((hunter_state["last_attack_evidence"] as Dictionary).get(
				"fixed_existing_hull_owner_used",
				false,
			))
		),
		"pirate_hunter_player_hull_floor": (
			damage_state["pirate_hunter_hull_floor"]
		),
		"pirate_hunter_inspected": _inspected_target_ids.has(
			pirate_hunter.target_id
		),
		"pirate_hunter_uses_existing_inspection": (
			hunter_state["uses_existing_inspection_system"]
		),
		"pirate_hunter_uses_existing_broadside": (
			hunter_state["uses_existing_broadside_system"]
		),
		"pirate_hunter_uses_existing_ammunition": (
			hunter_state["uses_existing_ammunition_system"]
		),
		"pirate_hunter_uses_existing_sail_damage_speed": (
			hunter_state["uses_existing_sail_damage_speed"]
		),
		"pirate_hunter_last_player_attack_used_existing_broadside": (
			_last_attacked_target_id != pirate_hunter.target_id
			or bool(_last_broadside_attempt_evidence.get("target_hit", false))
		),
		"pirate_hunter_escape_count": hunter_state["escape_count"],
		"pirate_hunter_defeat_count": hunter_state["defeat_count"],
		"pirate_hunter_player_defeat_resolution_count": (
			hunter_state["player_defeat_resolution_count"]
		),
		"pirate_hunter_attacks_stopped_after_player_defeat": (
			hunter_state["attacks_stopped_after_player_defeat"]
		),
		"pirate_hunter_player_defeat_is_stable": (
			String(hunter_state["outcome"]) != "PLAYER DEFEATED"
			or (
				bool(hunter_state["encounter_resolved"])
				and not bool(hunter_state["encounter_active"])
				and not bool(hunter_state["visual_visible"])
			)
		),
		"pirate_hunter_escape_is_stable": (
			String(hunter_state["outcome"]) != "ESCAPED"
			or (
				bool(hunter_state["encounter_resolved"])
				and not bool(hunter_state["encounter_active"])
				and not bool(hunter_state["visual_visible"])
			)
		),
		"pirate_hunter_escape_reached_clear_distance": (
			String(hunter_state["outcome"]) != "ESCAPED"
			or float((hunter_state["last_resolution_evidence"] as Dictionary).get(
				"distance_to_player",
				-1.0,
			)) >= float(hunter_state["escape_distance"])
		),
		"pirate_hunter_defeat_is_stable": (
			String(hunter_state["outcome"]) != "DEFEATED"
			or (
				bool(hunter_state["encounter_resolved"])
				and not bool(hunter_state["encounter_active"])
				and bool((hunter_state["inspectable_target_state"] as Dictionary)[
					"hull"
				]["disabled"])
			)
		),
		"pirate_hunter_defeated_by_existing_broadside": (
			String(hunter_state["outcome"]) != "DEFEATED"
			or (
				String(_pirate_hunter_defeat_broadside_evidence.get(
					"target_id",
					"",
				)) == pirate_hunter.target_id
				and bool(_pirate_hunter_defeat_broadside_evidence.get(
					"shot_fired",
					false,
				))
				and bool(_pirate_hunter_defeat_broadside_evidence.get(
					"target_hit",
					false,
				))
				and bool(_pirate_hunter_defeat_broadside_evidence.get(
					"target_disabled",
					false,
				))
				and bool(_pirate_hunter_defeat_broadside_evidence.get(
					"ammunition_consumed",
					false,
				))
			)
		),
		"pirate_hunter_defeat_broadside_evidence": (
			_pirate_hunter_defeat_broadside_evidence.duplicate(true)
		),
		"pirate_hunter_heat_unchanged_by_warning_and_spawn": (
			hunter_state["heat_unchanged_by_warning_and_spawn"]
		),
		"pirate_hunter_heat_persists_after_outcome": (
			hunter_state["heat_persisted_through_resolution"]
		),
		"pirate_hunter_no_new_player_combat_actions": (
			int(hunter_state["new_player_combat_action_count"]) == 0
		),
		"pirate_hunter_existing_broadside_input_guard_count": (
			_broadside_held_input_count
		),
		"pirate_hunter_paused_update_count": (
			hunter_state["paused_update_count"]
		),
		"pirate_hunter_modal_paused_update_count": (
			hunter_state["modal_paused_update_count"]
		),
		"pirate_hunter_modal_pause_position_held": (
			hunter_state["modal_pause_position_held"]
		),
		"pirate_hunter_modal_pause_evidence": (
			(hunter_state["modal_pause_evidence"] as Dictionary).duplicate(true)
		),
		"pirate_hunter_modal_input_pauses_encounter": (
			int(hunter_state["modal_paused_update_count"]) > 0
			and bool(hunter_state["modal_pause_position_held"])
		),
		"pirate_hunter_last_attack_conserved_cargo_and_food": (
			(hunter_state["last_attack_evidence"] as Dictionary).is_empty()
			or (
				bool((hunter_state["last_attack_evidence"] as Dictionary).get(
					"cargo_unchanged",
					false,
				))
				and bool((hunter_state["last_attack_evidence"] as Dictionary).get(
					"food_progress_unchanged",
					false,
				))
				and bool((hunter_state["last_attack_evidence"] as Dictionary).get(
					"food_units_unchanged",
					false,
				))
			)
		),
		"pirate_hunter_state": hunter_state.duplicate(true),
		"pirate_hunter_fleet_ship_count": hunter_state["hunter_fleet_ship_count"],
		"pirate_hunter_wanted_level_system_count": (
			hunter_state["wanted_level_system_count"]
		),
		"pirate_hunter_nation_rule_system_count": (
			hunter_state["nation_rule_system_count"]
		),
		"pirate_hunter_faction_rule_system_count": (
			hunter_state["faction_rule_system_count"]
		),
		"pirate_hunter_port_service_refusal_count": (
			hunter_state["port_service_refusal_count"]
		),
		"pirate_hunter_crew_injury_system_count": (
			hunter_state["crew_injury_system_count"]
		),
		"world_heat_port_service_refusal_count": (
			heat_state["port_service_refusal_count"]
		),
		"world_heat_per_nation_meter_count": (
			heat_state["per_nation_heat_meter_count"]
		),
		"world_heat_law_system_count": heat_state["law_system_count"],
		"world_heat_bribe_system_count": heat_state["bribe_system_count"],
		"world_heat_wanted_level_system_count": (
			heat_state["wanted_level_system_count"]
		),
		"world_heat_resident_reaction_count": (
			heat_state["resident_reaction_count"]
		),
		"target_inspection_attack_action_count": broadside_state["system_count"],
		"target_inspection_exact_hidden_cargo_shown": false,
		"target_inspection_hidden_threat_count": 0,
		"target_inspection_faction_record_count": 0,
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
		"storage_starting_slots": storage_state["starting_storage_slots"],
		"storage_starting_lots": storage_state["starting_storage_lots"],
		"storage_starting_used_slots": (
			storage_state["starting_storage_used_slots"]
		),
		"storage_starting_free_slots": (
			storage_state["starting_storage_free_slots"]
		),
		"storage_starting_food_units": (
			storage_state["starting_storage_food_units"]
		),
		"storage_phase_19_real_load_path": (
			storage_state["phase_19_real_load_path"]
		),
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
		"trade_contact_count": (
			get_tree().get_nodes_in_group("port_trader").size()
			+ get_tree().get_nodes_in_group("cove_buyer").size()
		),
		"port_trader_count": get_tree().get_nodes_in_group("port_trader").size(),
		"cove_buyer_count": get_tree().get_nodes_in_group("cove_buyer").size(),
		"port_trader": port_trader_state,
		"cove_buyer": cove_buyer_state,
		"port_trader_interaction_connected": (
			port_trader.body_entered.is_connected(_on_port_trader_body_entered)
			and port_trader.body_exited.is_connected(_on_port_trader_body_exited)
		),
		"cove_buyer_interaction_connected": (
			cove_buyer.body_entered.is_connected(_on_cove_buyer_body_entered)
			and cove_buyer.body_exited.is_connected(_on_cove_buyer_body_exited)
		),
		"player_near_port_trader": _player_near_port_trader,
		"player_near_cove_buyer": _player_near_cove_buyer,
		"completed_voyages": completed_voyages,
		"completed_voyage": completed_voyages,
		"voyage_departure_dock_id": _voyage_departure_dock_id,
		"voyage_departure_count": _voyage_departure_count,
		"same_dock_arrival_count": _same_dock_arrival_count,
		"last_completed_voyage_evidence": (
			_last_completed_voyage_evidence.duplicate(true)
		),
		"journal_object_count": journal_state["owner_count"],
		"journal_screen_count": (
			get_tree().get_nodes_in_group("trade_journal_screen").size()
		),
		"journal_port_entry_count": journal_state["port_entry_count"],
		"journal_known": journal_state["known"],
		"journal_unknown": journal_state["unknown"],
		"journal_status": journal_state["status"],
		"journal_fresh": journal_state["fresh"],
		"journal_old": journal_state["old"],
		"journal_seen_voyage": journal_state["seen_voyage"],
		"journal_current_voyage": journal_state["current_voyage"],
		"journal_age": journal_state["age"],
		"journal_entry_raw_snapshot": journal_state["raw_entry"],
		"journal_recorded_goods": journal_state["goods"],
		"journal_recorded_good_count": journal_state["good_count"],
		"journal_recorded_good_names": journal_good_names,
		"journal_expected_good_names": (
			TradeJournalState.RECORDED_GOOD_NAMES.duplicate()
		),
		"journal_has_exact_four_goods": (
			int(journal_state["good_count"]) == 4
			and journal_good_names
				== TradeJournalState.RECORDED_GOOD_NAMES
		),
		"journal_current_price_states": journal_current_price_states,
		"journal_current_fixed_prices": journal_current_fixed_prices,
		"journal_base_price_states": journal_base_price_states,
		"journal_base_fixed_prices": journal_base_fixed_prices,
		"journal_spice_stock_mark_snapshot": (
			journal_state["spice_stock_mark"]
		),
		"journal_condition_snapshot": journal_state["condition"],
		"journal_record_count": journal_state["record_count"],
		"journal_market_open_record_count": (
			journal_state["market_open_record_count"]
		),
		"journal_successful_purchase_refresh_count": (
			journal_state["purchase_refresh_count"]
		),
		"journal_prize_trade_records_update_count": (
			journal_state["prize_trade_records_update_count"]
		),
		"journal_prize_trade_records_updated_one_port_entry": (
			journal_state["prize_trade_records_updated_one_port_entry"]
		),
		"journal_last_record_source": journal_state["last_record_source"],
		"journal_record_source_counts": journal_state["record_source_counts"],
		"journal_allowed_record_sources": (
			journal_state["allowed_record_sources"]
		),
		"journal_dock_arrival_record_count": 0,
		"journal_voyage_completion_record_count": 0,
		"journal_cove_market_record_count": 0,
		"journal_screen_open_record_count": 0,
		"journal_remote_record_count": 0,
		"journal_remote_raw_snapshot_before_voyage": (
			_journal_remote_raw_snapshot_before_voyage.duplicate(true)
		),
		"journal_remote_raw_snapshot_after_voyage": (
			_journal_remote_raw_snapshot_after_voyage.duplicate(true)
		),
		"journal_remote_raw_snapshot_unchanged": (
			_journal_remote_raw_snapshot_unchanged
		),
		"journal_remote_saved_goods_unchanged": (
			not _journal_remote_raw_snapshot_before_voyage.is_empty()
			and _journal_remote_raw_snapshot_before_voyage.get("goods", [])
				== _journal_remote_raw_snapshot_after_voyage.get("goods", [])
		),
		"journal_remote_saved_spice_mark_unchanged": (
			not _journal_remote_raw_snapshot_before_voyage.is_empty()
			and _journal_remote_raw_snapshot_before_voyage.get(
				"spice_stock_mark",
				{},
			) == _journal_remote_raw_snapshot_after_voyage.get(
				"spice_stock_mark",
				{},
			)
		),
		"journal_remote_saved_condition_unchanged": (
			not _journal_remote_raw_snapshot_before_voyage.is_empty()
			and _journal_remote_raw_snapshot_before_voyage.get("condition", {})
				== _journal_remote_raw_snapshot_after_voyage.get("condition", {})
		),
		"journal_remote_seen_voyage_unchanged": (
			not _journal_remote_raw_snapshot_before_voyage.is_empty()
			and _journal_remote_raw_snapshot_before_voyage.get("seen_voyage", -1)
				== _journal_remote_raw_snapshot_after_voyage.get(
					"seen_voyage",
					-2,
				)
		),
		"journal_remote_live_countdown_did_not_leak": (
			_journal_remote_raw_snapshot_unchanged
			and _journal_remote_last_completed_voyage
				> int(_journal_remote_raw_snapshot_after_voyage.get(
					"seen_voyage",
					-1,
				))
		),
		"journal_remote_unchanged_voyage_count": (
			_journal_remote_unchanged_voyage_count
		),
		"journal_remote_last_completed_voyage": (
			_journal_remote_last_completed_voyage
		),
		"journal_before_return_market_snapshot": (
			_journal_before_return_market_snapshot.duplicate(true)
		),
		"journal_before_return_market_status": (
			_journal_before_return_market_status
		),
		"journal_before_return_market_voyage": (
			_journal_before_return_market_voyage
		),
		"journal_before_return_market_is_old": (
			_journal_before_return_market_status
				== TradeJournalState.OLD_STATUS
		),
		"journal_before_return_market_unchanged": (
			_journal_before_return_market_unchanged
		),
		"journal_return_market_snapshot_before_refresh": (
			_journal_return_market_snapshot_before_refresh.duplicate(true)
		),
		"journal_return_market_snapshot_after_refresh": (
			_journal_return_market_snapshot_after_refresh.duplicate(true)
		),
		"journal_return_market_refresh_count": (
			_journal_return_market_refresh_count
		),
		"journal_return_market_is_fresh": (
			_journal_return_market_refresh_count > 0
			and bool(journal_state["fresh"])
		),
		"journal_return_market_seen_current_voyage": (
			_journal_return_market_refresh_count > 0
			and int(journal_state["seen_voyage"]) == completed_voyages
		),
		"journal_return_market_condition_is_saved_ended_state": (
			_journal_return_market_refresh_count > 0
			and (journal_state["condition"] as Dictionary).get("state", "")
				== "ENDED"
		),
		"journal_return_market_spice_stock_is_saved_restored_state": (
			_journal_return_market_refresh_count > 0
			and int((journal_state["spice_stock_mark"] as Dictionary).get(
				"marks_available",
				-1,
			)) == int((journal_state["spice_stock_mark"] as Dictionary).get(
				"mark_capacity",
				-2,
			))
		),
		"journal_view_open": _journal_view_open,
		"journal_view_visible": journal_view.visible,
		"journal_release_pending": _journal_release_pending,
		"journal_input_blocked": (
			(_journal_view_open or _journal_release_pending)
			and not player_state["movement_enabled"]
		),
		"journal_open_count": _journal_open_count,
		"journal_close_count": _journal_close_count,
		"journal_held_input_count": _journal_held_input_count,
		"journal_blocked_input_count": _journal_blocked_input_count,
		"journal_pressed_key_count": _journal_pressed_keys.size(),
		"journal_last_action": _last_journal_action,
		"journal_can_open_now": _can_open_trade_journal(),
		"journal_open_blocked_by_modes": {
			"chart": waypoint_state["chart_visible"] and not _journal_view_open,
			"chart_release": _chart_release_pending and not _journal_view_open,
			"cargo_choice": _cargo_choice_open and not _journal_view_open,
			"cargo_release": (
				_cargo_choice_release_pending and not _journal_view_open
			),
			"storage": _storage_view_open and not _journal_view_open,
			"storage_release": _storage_release_pending and not _journal_view_open,
			"construction": _construction_view_open and not _journal_view_open,
			"construction_release": (
				_construction_release_pending and not _journal_view_open
			),
			"trade": _trade_view_open and not _journal_view_open,
			"trade_release": _trade_release_pending and not _journal_view_open,
			"dialogue": _dialogue_open and not _journal_view_open,
		},
		"journal_release_guard_keys": (
			"J_X_E_M_1_TO_6_WASD_AND_ARROW_KEYS"
		),
		"journal_view_title": journal_title.text,
		"journal_view_status": journal_status.text,
		"journal_view_details": journal_details.text,
		"journal_view_controls": journal_controls.text,
		"journal_view_text": journal_view_full_text,
		"journal_visible_text_has_port_market": (
			journal_view_full_text.contains("PORT MARKET")
		),
		"journal_visible_text_has_status": (
			journal_view_full_text.contains(String(journal_state["status"]))
		),
		"journal_visible_text_has_exact_saved_goods": (
			journal_view_full_text.contains("TIMBER")
			and journal_view_full_text.contains("FOOD")
			and journal_view_full_text.contains("MEDICINE")
			and journal_view_full_text.contains("SPICE LOT")
		),
		"journal_visible_text_has_saved_spice_marks": (
			not bool(journal_state["known"])
			or journal_view_full_text.contains("SPICE STOCK")
		),
		"journal_visible_text_has_saved_condition": (
			not bool(journal_state["known"])
			or (
				journal_view_full_text.contains("STORM DAMAGE")
				and journal_view_full_text.contains("SAVED REMAINING")
			)
		),
		"journal_visible_text_matches_saved_goods": (
			journal_visible_text_matches_saved_goods
		),
		"journal_visible_text_matches_saved_spice_mark": (
			journal_visible_text_matches_saved_mark
		),
		"journal_visible_text_matches_saved_condition": (
			journal_visible_text_matches_saved_condition
		),
		"journal_modal_blocks": {
			"walking": _journal_view_open and not player_state["movement_enabled"],
			"sailing": (
				_journal_view_open and ship_state["navigation_input_blocked"]
			),
			"chart": _journal_view_open and not waypoint_state["chart_visible"],
			"trade": _journal_view_open and not _trade_view_open,
			"storage": _journal_view_open and not _storage_view_open,
			"construction": (
				_journal_view_open and not _construction_view_open
			),
			"cargo_choice": _journal_view_open and not _cargo_choice_open,
			"salvage": _journal_view_open,
			"docking": _journal_view_open,
			"shore_transitions": _journal_view_open,
			"dialogue": _journal_view_open and not _dialogue_open,
			"slot_keys": _journal_view_open,
			"other_interactions": _journal_view_open,
		},
		"journal_rumor_system_count": 0,
		"journal_upgrade_system_count": 0,
		"journal_advice_system_count": 0,
		"journal_live_market_update_system_count": 0,
		"journal_walking_control_help": WALKING_CONTROLS_TEXT,
		"journal_sailing_control_help": SAILING_CONTROLS_TEXT,
		"journal_docked_control_help": DOCKED_CONTROLS_TEXT,
		"journal_normal_control_help_has_journal": (
			WALKING_CONTROLS_TEXT.contains("J JOURNAL")
			and SAILING_CONTROLS_TEXT.contains("J JOURNAL")
			and DOCKED_CONTROLS_TEXT.contains("J JOURNAL")
		),
		"condition_count": port_condition_state["condition_count"],
		"active_condition_count": (
			port_condition_state["active_condition_count"]
		),
		"condition_name": port_condition_state["name"],
		"condition_active": port_condition_state["active"],
		"condition_ended": port_condition_state["ended"],
		"condition_state": port_condition_state["state"],
		"condition_start_voyage": port_condition_state["start_voyage"],
		"condition_end_voyage": port_condition_state["end_voyage"],
		"condition_current_voyage": port_condition_state["current_voyage"],
		"condition_remaining_voyages": (
			port_condition_state["remaining_voyages"]
		),
		"condition_duration_voyages": port_condition_state["duration_voyages"],
		"condition_duration_is_exactly_two": (
			port_condition_state["duration_is_exactly_two"]
		),
		"condition_affected_good_count": (
			port_condition_state["affected_good_count"]
		),
		"condition_affected_good_count_is_exactly_three": (
			port_condition_state["affected_good_count_is_exactly_three"]
		),
		"condition_affected_goods": port_condition_state["affected_goods"],
		"condition_affected_good_names": (
			port_condition_state["affected_good_names"]
		),
		"condition_affected_cargo_lot_names": (
			port_condition_state["affected_cargo_lot_names"]
		),
		"condition_base_price_states": (
			port_condition_state["base_price_states"]
		),
		"condition_current_price_states": (
			port_condition_state["current_price_states"]
		),
		"condition_base_fixed_prices": (
			port_condition_state["base_fixed_prices"]
		),
		"condition_current_fixed_prices": (
			port_condition_state["current_fixed_prices"]
		),
		"condition_all_affected_goods_currently_valuable": (
			port_condition_state["all_affected_goods_currently_valuable"]
		),
		"condition_all_affected_goods_valuable_while_active": (
			port_condition_state["all_affected_goods_valuable_while_active"]
		),
		"condition_base_states_restored_after_expiry": (
			port_condition_state["base_states_restored_after_expiry"]
		),
		"condition_expiry_count": port_condition_state["expiry_count"],
		"condition_expiry_voyage": port_condition_state["expiry_voyage"],
		"condition_expected_expiry_voyage": (
			port_condition_state["expected_expiry_voyage"]
		),
		"condition_expiry_timing_is_exact": (
			port_condition_state["expiry_timing_is_exact"]
		),
		"one_condition_invariant": (
			int(port_condition_state["condition_count"]) == 1
			and int(port_condition_state["active_condition_count"]) <= 1
		),
		"port_condition": port_condition_state,
		"last_port_condition_update_evidence": (
			_last_port_condition_update_evidence.duplicate(true)
		),
		"port_condition_visible_text": visible_port_condition_text,
		"port_condition_text_visible": not visible_port_condition_text.is_empty(),
		"port_condition_visible_text_has_name": (
			visible_port_condition_text.contains(
				String(port_condition_state["name"])
			)
		),
		"port_condition_visible_text_has_market_effects": (
			visible_port_condition_text.contains("MARKET EFFECTS")
			and visible_port_condition_text.contains("TIMBER")
			and visible_port_condition_text.contains("FOOD")
			and visible_port_condition_text.contains("MEDICINE")
		),
		"port_condition_visible_text_has_exact_end_voyage": (
			visible_port_condition_text.contains("END VOYAGE %d" % (
				port_condition_state["end_voyage"]
			))
		),
		"port_condition_visible_text_has_remaining_voyages": (
			visible_port_condition_text.contains(
				"%d COMPLETED VOYAGES REMAIN" % (
					port_condition_state["remaining_voyages"]
				)
			)
		),
		"cove_condition_count": 0,
		"cove_condition_applies": false,
		"cove_trade_visible_text": visible_cove_trade_text,
		"cove_trade_view_says_no_port_condition": (
			visible_cove_trade_text.contains("NO PORT CONDITION")
			and not visible_cove_trade_text.contains(
				String(port_condition_state["name"])
			)
		),
		"condition_excludes_spice_trade": (
			not condition_cargo_lot_names.has(TradeContact.GOOD_NAME)
		),
		"condition_spice_marks_unchanged_on_last_update": (
			_last_port_condition_update_evidence.is_empty()
			or bool(_last_port_condition_update_evidence.get(
				"port_spice_marks_unchanged",
				false,
			))
		),
		"condition_cove_contact_unchanged_on_last_update": (
			_last_port_condition_update_evidence.is_empty()
			or bool(_last_port_condition_update_evidence.get(
				"cove_contact_unchanged",
				false,
			))
		),
		"mark_return_after_completed_voyages": (
			TradeContact.MARK_RETURN_VOYAGES
		),
		"trade_good_name": TradeContact.GOOD_NAME,
		"trade_fixed_price_map": TradeContact.get_fixed_price_map(),
		"trade_price_state_count": TradeContact.PriceState.size(),
		"trade_shown_good_count_per_contact": 1,
		"trade_each_shown_good_has_exactly_one_state": (
			int(port_trader_state["shown_good_state_count"]) == 1
			and int(cove_buyer_state["shown_good_state_count"]) == 1
		),
		"port_trade_price_state": port_trader_state["price_state"],
		"port_trade_fixed_price": port_trader_state["fixed_price"],
		"cove_trade_price_state": cove_buyer_state["price_state"],
		"cove_trade_fixed_price": cove_buyer_state["fixed_price"],
		"trade_price_states_fixed": (
			port_trader_state["base_price_state"] == "CHEAP"
			and int(port_trader_state["base_fixed_price"]) == 20
			and cove_buyer_state["base_price_state"] == "VALUABLE"
			and int(cove_buyer_state["base_fixed_price"]) == 30
			and fishing_state["fish_price_state"] == "NORMAL"
			and ruin_state["treasure_price_state"] == "NORMAL"
			and TradeContact.NORMAL_PRICE
				== int(TradeContact.get_fixed_price_map()["NORMAL"])
		),
		"trade_base_price_states_fixed": (
			port_trader_state["base_price_state"] == "CHEAP"
			and cove_buyer_state["base_price_state"] == "VALUABLE"
		),
		"trade_current_states_match_marks": (
			port_trader_state["current_price_state"] == "CHEAP"
			and (
				(
					int(cove_buyer_state["marks_available"]) > 0
					and cove_buyer_state["current_price_state"] == "VALUABLE"
				)
				or (
					int(cove_buyer_state["marks_available"]) == 0
					and cove_buyer_state["current_price_state"] == "NORMAL"
				)
			)
		),
		"trade_buy_price": port_trader_state["base_fixed_price"],
		"trade_sell_price": cove_buyer_state["base_fixed_price"],
		"starting_money": STARTING_MONEY,
		"money": money,
		"money_not_negative": money >= 0,
		"expected_money_after_all_transactions": expected_money,
		"money_accounting_holds": money == expected_money,
		"money_view_visible": money_view.visible,
		"money_view_text": money_details.text,
		"fish_normal_sale_price": TradeContact.NORMAL_PRICE,
		"ruin_treasure_normal_sale_price": TradeContact.NORMAL_PRICE,
		"fish_fixed_price_state": {
			"lot_name": FishingAreaState.FISH_LOT_NAME,
			"price_state": fishing_state["fish_price_state"],
			"price_state_index": TradeContact.PriceState.NORMAL,
			"fixed_price": TradeContact.NORMAL_PRICE,
			"canonical_fixed_price_map": TradeContact.get_fixed_price_map(),
			"matches_canonical_normal": (
				fishing_state["fish_price_state"]
					== String(TradeContact.PriceState.keys()[
						TradeContact.PriceState.NORMAL
					])
				and TradeContact.NORMAL_PRICE
					== int(TradeContact.get_fixed_price_map()["NORMAL"])
			),
		},
		"fish_trade_price_state": fishing_state["fish_price_state"],
		"fish_trade_fixed_price": TradeContact.NORMAL_PRICE,
		"fish_trade_uses_canonical_normal_fixed_price": (
			fishing_state["fish_price_state"] == "NORMAL"
			and TradeContact.NORMAL_PRICE
				== int(TradeContact.get_fixed_price_map()["NORMAL"])
		),
		"fish_money_preview": fish_money_preview.duplicate(true),
		"fish_money_earned": _fish_money_earned,
		"fish_sale_attempt_count": _fish_sale_attempt_count,
		"fish_sold_lot_count": _fish_sold_lot_count,
		"fish_sold_unit_count": _fish_sold_unit_count,
		"fish_sale_expected_money_earned": (
			_fish_sold_unit_count * TradeContact.NORMAL_PRICE
		),
		"fish_sale_denied_count": _fish_sale_denied_count,
		"last_fish_sale_evidence": _last_fish_sale_evidence.duplicate(true),
		"successful_fish_sale_evidence": (
			_successful_fish_sale_evidence.duplicate(true)
		),
		"fish_sale_money_accounting_holds": (
			_fish_money_earned
			== _fish_sold_unit_count * TradeContact.NORMAL_PRICE
		),
		"ship_trade_lot_count": (
			ship.get_cargo_lots().count(TradeContact.GOOD_NAME)
		),
		"trade_view_open": _trade_view_open,
		"trade_view_visible": trade_view.visible,
		"trade_view_title": trade_title.text,
		"trade_view_details": trade_details.text,
		"trade_view_result": trade_result.text,
		"trade_view_controls": trade_controls.text,
		"trade_view_text": trade_view_full_text,
		"cove_fish_sale_visible": (
			not (
				_trade_view_open
				and _active_trade_contact == cove_buyer
				and trade_view.visible
			)
			or (
				trade_view_full_text.contains("FISH CATCH SALE")
				and trade_view_full_text.contains(FishingAreaState.FISH_LOT_NAME)
				and trade_view_full_text.contains(
					"NORMAL · %d COINS" % TradeContact.NORMAL_PRICE
				)
				and trade_view_full_text.contains(
					"FISH SELL PREVIEW · %d -> %d (+%d)" % [
						fish_money_preview["money_before"],
						fish_money_preview["money_after"],
						fish_money_preview["money_delta"],
					]
				)
				and trade_view_full_text.contains("[F] SELL ONE FISH LOT")
			)
		),
		"port_ruin_treasure_sale_visible": (
			not (
				_trade_view_open
				and _active_trade_contact == port_trader
				and trade_view.visible
			)
			or (
				trade_view_full_text.contains("RUIN TREASURE SALE")
				and trade_view_full_text.contains(
					RuinExplorationState.TREASURE_LOT_NAME
				)
				and trade_view_full_text.contains(
					"NORMAL · %d COINS" % TradeContact.NORMAL_PRICE
				)
				and trade_view_full_text.contains(
					"TREASURE SELL PREVIEW · %d -> %d (+%d)" % [
						treasure_money_preview["money_before"],
						treasure_money_preview["money_after"],
						treasure_money_preview["money_delta"],
					]
				)
				and trade_view_full_text.contains(
					"[G] SELL ONE RUIN TREASURE LOT"
				)
			)
		),
		"port_ammunition_supply_price_visible": (
			not (
				_trade_view_open
				and _active_trade_contact == port_trader
				and trade_view.visible
			)
			or (
				trade_view_full_text.contains(
					ShipAmmunitionState.SOURCE_CARGO_LOT_NAME
				)
				and trade_view_full_text.contains(
					"FIXED %d COINS" % (
						ShipAmmunitionState.SOURCE_CARGO_FIXED_PRICE
					)
				)
			)
		),
		"port_ammunition_load_action_visible": (
			not (
				_trade_view_open
				and _active_trade_contact == port_trader
				and trade_view.visible
			)
			or trade_view_full_text.contains(
				"[L] LOAD 1 SOURCE LOT · 3 AMMUNITION · SAME SLOT"
			)
		),
		"active_trade_contact": (
			_active_trade_contact.get_display_name()
			if _active_trade_contact != null
			else ""
		),
		"active_trade_price_state": (
			_active_trade_contact.get_price_state_name()
			if _active_trade_contact != null
			else ""
		),
		"active_trade_fixed_price": (
			_active_trade_contact.get_fixed_price()
			if _active_trade_contact != null
			else 0
		),
		"active_trade_money_preview": active_trade_preview.duplicate(true),
		"active_trade_mark_state": (
			_active_trade_contact.get_mark_state(completed_voyages)
			if _active_trade_contact != null
			else {}
		),
		"last_trade_action": _last_trade_action,
		"last_trade_result": _last_trade_result,
		"last_trade_attempt_evidence": _last_trade_attempt_evidence.duplicate(true),
		"successful_purchase_evidence": _successful_purchase_evidence.duplicate(true),
		"successful_sale_evidence": _successful_sale_evidence.duplicate(true),
		"trade_open_count": _trade_open_count,
		"trade_close_count": _trade_close_count,
		"trade_purchase_attempt_count": _trade_purchase_attempt_count,
		"trade_sale_attempt_count": _trade_sale_attempt_count,
		"trade_bought_lot_count": _trade_bought_lot_count,
		"trade_sold_lot_count": _trade_sold_lot_count,
		"trade_denied_purchase_count": _trade_denied_purchase_count,
		"trade_denied_sale_count": _trade_denied_sale_count,
		"trade_held_input_count": _trade_held_input_count,
		"trade_blocked_input_count": _trade_blocked_input_count,
		"trade_release_pending": _trade_release_pending,
		"trade_modal_blocks": {
			"walking": _trade_view_open and not player_state["movement_enabled"],
			"chart": _trade_view_open and not waypoint_state["chart_visible"],
			"ship_return": _trade_view_open,
			"dialogue": _trade_view_open and not _dialogue_open,
			"storage": _trade_view_open and not _storage_view_open,
			"construction": _trade_view_open and not _construction_view_open,
			"salvage": _trade_view_open,
			"fishing": _trade_view_open,
			"docking": _trade_view_open,
			"other_interactions": _trade_view_open,
		},
		"trade_persistence": {
			"purchase_money_snapshot": _trade_purchase_money_snapshot,
			"purchase_cargo_snapshot": _trade_purchase_cargo_snapshot.duplicate(),
			"returned_to_ship_at_port": _trade_returned_to_ship_at_port,
			"sailed_from_port": _trade_sailed_from_port,
			"cove_docked": _trade_cove_docked,
			"cove_ashore": _trade_cove_ashore,
			"money_and_cargo_hold": _trade_persistence_holds,
		},
		"trade_cargo_accounting": {
			"physical_cargo": physical_cargo_total,
			"construction_consumed": construction_state["consumed_lot_count"],
			"food_consumed": food_state["total_units_used"],
			"repair_timber_consumed": repair_state["consumed_timber_count"],
			"ammunition_depleted_lots": ammunition_state["depleted_lot_count"],
			"defeat_lost_cargo_lots": (
				defeat_state["total_cargo_slot_loss_count"]
			),
			"sold_trade_lots": _trade_sold_lot_count,
			"sold_fish_lots": _fish_sold_lot_count,
			"sold_ruin_treasure_lots": _treasure_sold_lot_count,
			"discarded_fish_lots": fishing_state["discarded_catch_count"],
			"fishing_replacement_discarded_cargo_lots": (
				fishing_state["displaced_cargo_discard_count"]
			),
			"ruin_replacement_discarded_cargo_lots": (
				ruin_state["displaced_cargo_discard_count"]
			),
			"pending_fish_lots": fishing_state["pending_catch_count"],
			"ruin_physical_treasure_lots": (
				ruin_state["physical_treasure_lot_count"]
			),
			"initial_physical_cargo": initial_physical_cargo_total,
			"initial_storage_lots": (
				storage_state["starting_storage_used_slots"]
			),
			"bought_trade_lots": _trade_bought_lot_count,
			"bought_ammunition_source_lots": (
				_ammunition_supply_purchased_lot_count
			),
			"caught_fish_lots": fishing_state["successful_catch_count"],
			"ammunition_conversion_cargo_delta": (
				ammunition_conversion_cargo_delta
			),
			"accounted_total": accounted_cargo_total,
			"expected_total": expected_cargo_total,
			"holds": accounted_cargo_total == expected_cargo_total,
			"unaccounted_loss": expected_cargo_total - accounted_cargo_total,
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
			or defeat_state["release_guard_pending"]
			or _chart_release_pending
			or _cargo_choice_release_pending
			or _storage_release_pending
			or _construction_release_pending
			or _trade_release_pending
			or _journal_release_pending
			or ruin_state["transition_release_pending"]
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
		"dialogue_kind": _dialogue_kind,
		"speaker_name": speaker_name.text,
		"dialogue_text": dialogue_text.text,
		"request_state": RequestState.keys()[_request_state],
		"resident_reaction_system_count": resident_state["system_count"],
		"resident_reaction_owner_count": resident_state["owner_count"],
		"resident_reaction_named_resident_count": (
			resident_state["named_resident_count"]
		),
		"resident_reaction_resident_name": resident_state["resident_name"],
		"resident_reaction_important_event_type_count": (
			resident_state["important_event_type_count"]
		),
		"resident_reaction_important_event_id": (
			resident_state["important_event_id"]
		),
		"resident_reaction_important_event_name": (
			resident_state["important_event_name"]
		),
		"resident_reaction_important_event_source": (
			resident_state["important_event_source"]
		),
		"resident_reaction_important_event_record_count": (
			resident_state["important_event_record_count"]
		),
		"resident_reaction_records_exactly_one_event": (
			resident_state["records_exactly_one_important_event"]
		),
		"resident_reaction_records_at_most_one_event": (
			resident_state["records_at_most_one_important_event"]
		),
		"resident_reaction_last_event_evidence": (
			resident_state["last_event_evidence"]
		),
		"resident_reaction_arm_count": resident_state["reaction_arm_count"],
		"resident_reaction_pending": resident_state["reaction_pending"],
		"resident_reaction_show_count": resident_state["reaction_show_count"],
		"resident_reaction_finish_count": (
			resident_state["reaction_finish_count"]
		),
		"resident_reaction_shows_one_time": (
			resident_state["reaction_shows_one_time"]
		),
		"resident_reaction_is_next_talk_after_event": (
			resident_state["reaction_is_next_talk_after_event"]
		),
		"resident_reaction_dialogue": resident_state["reaction_dialogue"],
		"resident_reaction_visible": (
			_dialogue_open
			and _dialogue_kind == CoveResident.REACTION_DIALOGUE_KIND
			and speaker_name.text == resident.display_name
			and dialogue_text.text == CoveResident.REACTION_DIALOGUE_LINE
		),
		"resident_reaction_talk_attempt_count": (
			resident_state["talk_attempt_count"]
		),
		"resident_reaction_held_input_count": (
			resident_state["held_talk_input_count"]
		),
		"resident_reaction_fresh_press_required": (
			resident_state["fresh_press_required"]
		),
		"resident_reaction_last_talk_evidence": (
			resident_state["last_talk_evidence"]
		),
		"resident_reaction_last_talk_finish_evidence": (
			resident_state["last_talk_finish_evidence"]
		),
		"resident_reaction_last_held_input_evidence": (
			resident_state["last_held_talk_evidence"]
		),
		"resident_reaction_normal_talk_count": (
			resident_state["normal_talk_count"]
		),
		"resident_reaction_normal_talk_after_count": (
			resident_state["normal_talk_after_reaction_count"]
		),
		"resident_reaction_normal_dialogue_available": (
			resident_state["normal_dialogue_available_after_reaction"]
		),
		"resident_reaction_normal_request_dialogue_unchanged": (
			resident_state["normal_request_dialogue_unchanged"]
		),
		"resident_reaction_normal_dialogue_visible": (
			_dialogue_open
			and _dialogue_kind == CoveResident.NORMAL_DIALOGUE_KIND
		),
		"resident_reaction_request_state_preserved": (
			resident_state["last_talk_finish_evidence"].is_empty()
			or bool(resident_state["last_talk_finish_evidence"].get(
				"request_state_unchanged_by_reaction",
				false,
			))
		),
		"resident_reaction_monster_return_required": (
			int(resident_state["important_event_record_count"]) == 0
			or (
				monster_state["monster_defeat_count"] == 1
				and monster_state["return_to_cove_count"] == 1
			)
		),
		"resident_reaction_excluded_features": {
			"relationship_values": resident_state["relationship_value_count"],
			"relationship_points": resident_state["relationship_point_count"],
			"relationship_increases": (
				resident_state["relationship_increase_count"]
			),
			"relationship_thresholds": (
				resident_state["relationship_threshold_count"]
			),
			"relationship_scenes": resident_state["relationship_scene_count"],
			"relationship_saves": resident_state["relationship_save_count"],
			"relationship_loads": resident_state["relationship_load_count"],
			"romance": resident_state["romance_system_count"],
			"unnamed_resident_opinions": (
				resident_state["unnamed_resident_opinion_count"]
			),
			"reputation": resident_state["reputation_system_count"],
			"daily_schedules": resident_state["daily_schedule_system_count"],
			"reactions_to_every_action": (
				resident_state["reaction_to_every_action_count"]
			),
		},
		"request_view_visible": request_view.visible,
		"request_title": request_title.text,
		"request_status": request_status.text,
		"request_goal": request_goal.text,
		"relationship_system_count": resident_state["relationship_system_count"],
		"relationship_owner_count": resident_state["relationship_owner_count"],
		"relationship_named_resident_count": (
			resident_state["relationship_named_resident_count"]
		),
		"relationship_resident_id": resident_state["relationship_resident_id"],
		"relationship_resident_name": (
			resident_state["relationship_resident_name"]
		),
		"relationship_value_count": resident_state["relationship_value_count"],
		"relationship_value": resident_state["relationship_value"],
		"relationship_initial_value": resident_state["relationship_initial_value"],
		"relationship_max_value": resident_state["relationship_max_value"],
		"relationship_value_view_count": get_tree().get_nodes_in_group(
			"relationship_value_view"
		).size(),
		"relationship_view_visible": relationship_view.visible,
		"relationship_visible_value_count": int(relationship_view.visible),
		"relationship_view_text": relationship_details.text,
		"relationship_view_text_exact": relationship_details.text == (
			"MARA RELATIONSHIP · %d" % int(resident_state["relationship_value"])
		),
		"relationship_increase_amount": (
			resident_state["relationship_increase_amount"]
		),
		"relationship_increase_count": (
			resident_state["relationship_increase_count"]
		),
		"relationship_exactly_one_fixed_increase": (
			resident_state["relationship_exactly_one_fixed_increase"]
		),
		"relationship_request_title": resident_state["relationship_request_title"],
		"relationship_exact_request_transition": (
			resident_state["relationship_exact_request_transition"]
		),
		"relationship_last_completion_evidence": (
			resident_state["relationship_last_completion_evidence"]
		),
		"relationship_request_result_text": (
			resident_state["relationship_result_text"]
		),
		"relationship_request_result_visible": (
			request_view.visible
			and _request_state == RequestState.COMPLETE
			and request_goal.text.find("MARA RELATIONSHIP 0 -> 1 (+1)") >= 0
		),
		"relationship_threshold_count": (
			resident_state["relationship_threshold_count"]
		),
		"relationship_threshold": resident_state["relationship_threshold"],
		"relationship_threshold_reached": (
			resident_state["relationship_threshold_reached"]
		),
		"relationship_threshold_reach_count": (
			resident_state["relationship_threshold_reach_count"]
		),
		"relationship_scene_count": resident_state["relationship_scene_count"],
		"relationship_scene_dialogue_kind": (
			resident_state["relationship_scene_dialogue_kind"]
		),
		"relationship_scene_dialogue": (
			resident_state["relationship_scene_dialogue"]
		),
		"relationship_scene_pending": (
			resident_state["relationship_scene_pending"]
		),
		"relationship_scene_available": (
			resident_state["relationship_scene_available"]
		),
		"relationship_scene_visible": (
			_dialogue_open
			and _dialogue_kind == CoveResident.RELATIONSHIP_DIALOGUE_KIND
			and speaker_name.text == resident.display_name
		),
		"relationship_scene_show_count": (
			resident_state["relationship_scene_show_count"]
		),
		"relationship_scene_finish_count": (
			resident_state["relationship_scene_finish_count"]
		),
		"relationship_scene_shows_once_per_runtime": (
			resident_state["relationship_scene_shows_once_per_runtime"]
		),
		"relationship_normal_talk_after_pending": (
			resident_state["relationship_normal_talk_after_pending"]
		),
		"relationship_normal_talk_after_count": (
			resident_state["relationship_normal_talk_after_count"]
		),
		"relationship_normal_dialogue_available_after_scene": (
			resident_state["relationship_normal_dialogue_available_after_scene"]
		),
		"relationship_fresh_press_required": resident_state["fresh_press_required"],
		"relationship_last_held_talk_evidence": (
			resident_state["last_held_talk_evidence"]
		),
		"relationship_dialogue_priority": resident_state["dialogue_priority"],
		"relationship_dialogue_priority_conflict_count": (
			resident_state["dialogue_priority_conflict_count"]
		),
		"relationship_dialogue_priority_reaction_win_count": (
			resident_state["dialogue_priority_reaction_win_count"]
		),
		"relationship_phase41_reaction_has_priority": (
			resident_state["phase41_reaction_has_priority"]
		),
		"relationship_phase41_normal_after_reaction_has_priority": (
			resident_state["phase41_normal_talk_keeps_priority_after_reaction"]
		),
		"relationship_save_path": resident_state["relationship_save_path"],
		"relationship_save_section": resident_state["relationship_save_section"],
		"relationship_save_key": resident_state["relationship_save_key"],
		"relationship_save_count": resident_state["relationship_save_count"],
		"relationship_load_count": resident_state["relationship_load_count"],
		"relationship_load_reject_count": (
			resident_state["relationship_load_reject_count"]
		),
		"relationship_startup_load_attempt_count": (
			resident_state["relationship_startup_load_attempt_count"]
		),
		"relationship_cleanup_count": (
			resident_state["relationship_cleanup_count"]
		),
		"relationship_save_file_exists": (
			resident_state["relationship_save_file_exists"]
		),
		"relationship_only_value_persisted": (
			resident_state["relationship_only_value_persisted"]
		),
		"relationship_owner_safe_path": (
			resident_state["relationship_owner_safe_path"]
		),
		"relationship_last_save_evidence": (
			resident_state["relationship_last_save_evidence"]
		),
		"relationship_last_load_evidence": (
			resident_state["relationship_last_load_evidence"]
		),
		"relationship_last_cleanup_evidence": (
			resident_state["relationship_last_cleanup_evidence"]
		),
		"relationship_last_runtime_reset_evidence": (
			resident_state["relationship_last_runtime_reset_evidence"]
		),
		"relationship_excluded_features": {
			"romance": resident_state["romance_system_count"],
			"gifts": resident_state["gift_system_count"],
			"decay": resident_state["relationship_decay_system_count"],
			"multiple_currencies": (
				resident_state["multiple_relationship_currency_count"]
			),
			"daily_schedules": resident_state["daily_schedule_system_count"],
			"passive_stat_bonuses": resident_state["passive_stat_bonus_count"],
			"day_states": resident_state["day_state_count"],
			"night_states": resident_state["night_state_count"],
			"time_advance": resident_state["time_advance_system_count"],
			"night_only_scenes": resident_state["night_only_scene_count"],
		},
		"day_night_system_count": day_night_state["system_count"],
		"day_night_owner_count": day_night_state["owner_count"],
		"day_night_state_count": day_night_state["state_count"],
		"day_night_states": day_night_state["states"],
		"day_night_initial_state": day_night_state["initial_state"],
		"day_night_time_state": day_night_state["time_state"],
		"day_active": day_night_state["day_active"],
		"night_active": day_night_state["night_active"],
		"day_night_arrival_check_count": (
			day_night_state["arrival_check_count"]
		),
		"day_night_eligible_cove_return_count": (
			day_night_state["eligible_cove_return_count"]
		),
		"day_night_advance_count": day_night_state["advance_count"],
		"day_night_advances_at_most_once": (
			day_night_state["advances_at_most_once"]
		),
		"day_night_advance_rule": day_night_state["advance_rule"],
		"day_night_last_arrival_evidence": (
			day_night_state["last_arrival_evidence"]
		),
		"day_night_successful_advance_evidence": (
			day_night_state["successful_advance_evidence"]
		),
		"day_night_uncounted_arrival_count": (
			day_night_state["uncounted_arrival_count"]
		),
		"day_night_same_dock_arrival_count": (
			day_night_state["same_dock_arrival_count"]
		),
		"day_night_non_cove_arrival_count": (
			day_night_state["non_cove_arrival_count"]
		),
		"cove_time_view_count": get_tree().get_nodes_in_group(
			"day_night_view"
		).size(),
		"cove_time_view_visible": cove_time_view.visible,
		"cove_time_view_text": cove_time_view_text,
		"cove_time_view_matches_state": (
			cove_time_title.text
			== "COVE TIME · %s" % String(day_night_state["time_state"])
		),
		"cove_time_status_text": cove_time_status.text,
		"cove_time_day_block_reason_visible": (
			String(day_night_state["time_state"]) != DayNightCycleState.DAY
			or (
				cove_time_view.visible
				and cove_time_status.text.contains("UNAVAILABLE DURING DAY")
				and cove_time_status.text.contains(
					"RETURN FROM A COUNTED VOYAGE TO THE COVE"
				)
			)
		),
		"cove_palette_time_state": cove_state["time_state"],
		"cove_palette_change_count": cove_state["palette_change_count"],
		"cove_active_palette": cove_state["active_palette"],
		"cove_day_palette": cove_state["day_palette"],
		"cove_night_palette": cove_state["night_palette"],
		"cove_sky_changes_between_states": (
			cove_state["sky_changes_between_states"]
		),
		"cove_water_changes_between_states": (
			cove_state["water_changes_between_states"]
		),
		"cove_land_changes_between_states": (
			cove_state["land_changes_between_states"]
		),
		"cove_light_changes_between_states": (
			cove_state["light_changes_between_states"]
		),
		"cove_authored_palette_matches_time_state": (
			cove_state["authored_palette_matches_time_state"]
			and cove_state["time_state"] == day_night_state["time_state"]
		),
		"mara_night_scene_count": resident_state["night_only_scene_count"],
		"mara_night_scene_dialogue_kind": (
			resident_state["night_scene_dialogue_kind"]
		),
		"mara_night_scene_dialogue": resident_state["night_scene_dialogue"],
		"mara_night_scene_arm_count": resident_state["night_scene_arm_count"],
		"mara_night_scene_pending": resident_state["night_scene_pending"],
		"mara_night_scene_available": resident_state["night_scene_available"],
		"mara_night_scene_block_reason": (
			resident_state["night_scene_block_reason"]
		),
		"mara_night_scene_show_count": resident_state["night_scene_show_count"],
		"mara_night_scene_finish_count": (
			resident_state["night_scene_finish_count"]
		),
		"mara_night_scene_shows_one_time": (
			resident_state["night_scene_shows_one_time"]
		),
		"mara_night_scene_visible": (
			_dialogue_open
			and _dialogue_kind == CoveResident.NIGHT_DIALOGUE_KIND
			and speaker_name.text == resident.display_name
		),
		"mara_night_scene_normal_talk_after_pending": (
			resident_state["night_scene_normal_talk_after_pending"]
		),
		"mara_night_scene_normal_talk_after_count": (
			resident_state["night_scene_normal_talk_after_count"]
		),
		"mara_night_scene_normal_dialogue_available_after": (
			resident_state["night_scene_normal_dialogue_available_after"]
		),
		"mara_night_scene_last_state_evidence": (
			resident_state["last_night_state_evidence"]
		),
		"day_night_dialogue_priority": resident_state["dialogue_priority"],
		"day_night_dialogue_priority_holds": (
			resident_state["dialogue_priority"] == PackedStringArray([
				CoveResident.REACTION_DIALOGUE_KIND,
				"NORMAL_AFTER_IMPORTANT_EVENT_REACTION",
				CoveResident.RELATIONSHIP_DIALOGUE_KIND,
				"NORMAL_AFTER_RELATIONSHIP_THRESHOLD_SCENE",
				CoveResident.NIGHT_DIALOGUE_KIND,
				CoveResident.NORMAL_DIALOGUE_KIND,
			])
		),
		"day_night_held_talk_fresh_press_required": (
			resident_state["fresh_press_required"]
		),
		"day_night_last_held_talk_evidence": (
			resident_state["last_held_talk_evidence"]
		),
		"day_night_excluded_features": {
			"calendar": day_night_state["calendar_system_count"],
			"seasons": day_night_state["season_system_count"],
			"resident_schedules": (
				day_night_state["resident_schedule_system_count"]
			),
			"timed_request_failure": (
				day_night_state["timed_request_failure_system_count"]
			),
			"sleep_needs": day_night_state["sleep_need_system_count"],
			"real_time_waiting": (
				day_night_state["real_time_wait_system_count"]
			),
			"phase44_port_unlocks": (
				day_night_state["port_unlock_system_count"]
			),
			"phase44_fast_travel_actions": (
				day_night_state["fast_travel_action_count"]
			),
			"phase44_food_costs": (
				day_night_state["fast_travel_food_cost_count"]
			),
			"phase44_chart_actions": (
				day_night_state["fast_travel_chart_action_count"]
			),
			"phase44_combat_travel_blocks": (
				day_night_state["fast_travel_combat_block_count"]
			),
		},
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
		"weather_system_count": weather_state["system_count"],
		"weather_state_owner_count": weather_state["owner_count"],
		"weather_state_count": weather_state["weather_state_count"],
		"weather_states": weather_state["weather_states"],
		"active_weather_state": weather_state["weather_state"],
		"clear_weather_active": weather_state["clear_active"],
		"storm_weather_active": weather_state["storm_active"],
		"storm_area_count": weather_state["storm_area_count"],
		"storm_area_id": weather_state["storm_area_id"],
		"storm_area_position": weather_state["storm_area_position"],
		"storm_area_radius": weather_state["storm_area_radius"],
		"storm_outside_test_position": (
			weather_state["storm_outside_test_position"]
		),
		"storm_inside_test_position": (
			weather_state["storm_inside_test_position"]
		),
		"storm_exit_test_position": weather_state["storm_exit_test_position"],
		"storm_area_visible": weather_state["storm_area_visible"],
		"storm_area_visual_on_screen": (
			weather_state["storm_visual_on_screen"]
		),
		"storm_area_visual_world_rect": (
			weather_state["storm_visual_world_rect"]
		),
		"storm_area_at_sea": sea_state["bounds"].has_point(
			weather_state["storm_area_position"]
		),
		"storm_area_overlaps_fishing_area": (
			weather_state["storm_area_position"].distance_to(
				fishing_state["area_position"]
			)
			<= float(weather_state["storm_area_radius"])
				+ float(fishing_state["fishing_range"])
		),
		"storm_fishing_center_affected": (
			weather_state["storm_area_position"].distance_to(
				fishing_state["area_position"]
			)
			<= float(weather_state["storm_area_radius"])
		),
		"storm_exit_position_keeps_fishing_available": (
			weather_state["storm_exit_test_position"].distance_to(
				weather_state["storm_area_position"]
			) > float(weather_state["storm_area_radius"])
			and weather_state["storm_exit_test_position"].distance_to(
				fishing_state["area_position"]
			) <= float(fishing_state["fishing_range"])
		),
		"storm_area_seen_from_outside": (
			weather_state["storm_seen_from_outside"]
		),
		"storm_outside_visibility_count": (
			weather_state["outside_visibility_count"]
		),
		"storm_last_outside_visibility_evidence": (
			weather_state["last_outside_visibility_evidence"]
		),
		"ship_distance_to_storm_area": weather_state["ship_distance"],
		"ship_inside_active_storm": (
			weather_state["ship_inside_active_storm"]
		),
		"storm_entry_count": weather_state["storm_entry_count"],
		"storm_exit_count": weather_state["storm_exit_count"],
		"storm_last_entry_evidence": weather_state["last_entry_evidence"],
		"storm_last_exit_evidence": weather_state["last_exit_evidence"],
		"weather_normal_turn_multiplier": (
			weather_state["normal_turn_multiplier"]
		),
		"weather_storm_turn_multiplier": (
			weather_state["storm_turn_multiplier"]
		),
		"weather_current_turn_multiplier": (
			weather_state["current_turn_multiplier"]
		),
		"weather_clear_turn_speed_radians": ship_state["base_turn_speed"],
		"weather_clear_turn_speed_degrees": rad_to_deg(
			ship_state["base_turn_speed"]
		),
		"weather_storm_turn_speed_radians": (
			float(ship_state["base_turn_speed"])
			* float(weather_state["storm_turn_multiplier"])
		),
		"weather_storm_turn_speed_degrees": rad_to_deg(
			float(ship_state["base_turn_speed"])
			* float(weather_state["storm_turn_multiplier"])
		),
		"weather_control_modifier_exact": (
			is_equal_approx(
				float(weather_state["normal_turn_multiplier"]),
				1.0,
			)
			and is_equal_approx(
				float(weather_state["storm_turn_multiplier"]),
				0.5,
			)
			and is_equal_approx(
				float(ship_state["turn_speed"]),
				float(ship_state["base_turn_speed"])
					* float(weather_state["current_turn_multiplier"]),
			)
		),
		"weather_changes_turn_rate_only": (
			ship_state["weather_control_changes_turn_rate_only"]
		),
		"weather_ship_top_speed_unchanged": (
			is_equal_approx(
				float(ship_state["top_speed"]),
				float(crew_state["effective_sailing_top_speed"]),
			)
		),
		"weather_toggle_key": weather_state["toggle_key"],
		"weather_toggle_available": _is_weather_toggle_available(),
		"weather_toggle_held": _weather_toggle_held,
		"weather_toggle_attempt_count": (
			weather_state["toggle_attempt_count"]
		),
		"weather_toggle_success_count": (
			weather_state["toggle_success_count"]
		),
		"weather_toggle_denied_count": (
			weather_state["toggle_denied_count"]
		),
		"weather_held_input_count": weather_state["held_input_count"],
		"weather_fresh_press_required": weather_state["fresh_press_required"],
		"weather_last_toggle_evidence": weather_state["last_toggle_evidence"],
		"weather_last_held_input_evidence": (
			weather_state["last_held_toggle_evidence"]
		),
		"weather_clear_response_evidence": (
			weather_state["clear_response_evidence"]
		),
		"weather_storm_outside_response_evidence": (
			weather_state["storm_outside_response_evidence"]
		),
		"weather_storm_response_evidence": (
			weather_state["storm_response_evidence"]
		),
		"weather_recovery_response_evidence": (
			weather_state["recovery_response_evidence"]
		),
		"weather_clear_turn_input_evidence": (
			weather_state["clear_turn_input_evidence"]
		),
		"weather_storm_turn_input_evidence": (
			weather_state["storm_turn_input_evidence"]
		),
		"weather_recovery_turn_input_evidence": (
			weather_state["recovery_turn_input_evidence"]
		),
		"weather_view_visible": weather_view.visible,
		"weather_view_title": weather_title.text,
		"weather_view_status": weather_status.text,
		"weather_view_text": weather_view_text,
		"weather_view_matches_state": (
			weather_view_text.contains(
				"WEATHER · %s" % weather_state["weather_state"]
			)
			and weather_view_text.contains("TURN RATE")
		),
		"weather_fishing_blocked": weather_state["fishing_blocked"],
		"weather_uses_existing_ship_motion_owner": (
			weather_state["ship_motion_owner_count"] == 1
		),
		"weather_uses_existing_ship_damage_owner": (
			weather_state["uses_existing_ship_damage_owner"]
		),
		"weather_uses_existing_fishing_owner": (
			weather_state["fishing_owner_count"] == 1
		),
		"weather_random_hull_damage_enabled": (
			weather_state["storm_random_hull_damage_enabled"]
		),
		"weather_season_system_count": weather_state["season_system_count"],
		"weather_detailed_forecast_system_count": (
			weather_state["detailed_forecast_system_count"]
		),
		"weather_wind_simulation_enabled": (
			weather_state["wind_simulation_enabled"]
		),
		"weather_random_cargo_loss_enabled": (
			weather_state["random_cargo_loss_enabled"]
		),
		"weather_strange_or_cursed_storm_enabled": (
			weather_state["strange_or_cursed_storm_enabled"]
		),
		"weather_day_night_system_count": (
			weather_state["day_night_system_count"]
		),
		"weather_ruin_system_count": weather_state["ruin_system_count"],
		"weather_tool_gate_system_count": (
			weather_state["tool_gate_system_count"]
		),
		"weather_story_clue_system_count": (
			weather_state["story_clue_system_count"]
		),
		"weather_monster_hunting_system_count": (
			weather_state["monster_hunting_system_count"]
		),
		"weather_excluded_features": {
			"seasons": weather_state["season_system_count"],
			"detailed_forecast": (
				weather_state["detailed_forecast_system_count"]
			),
			"wind_simulation": weather_state["wind_simulation_enabled"],
			"random_cargo_loss": (
				weather_state["random_cargo_loss_enabled"]
			),
			"strange_or_cursed_storms": (
				weather_state["strange_or_cursed_storm_enabled"]
			),
			"day_and_night": weather_state["day_night_system_count"],
			"ruin_exploration": weather_state["ruin_system_count"],
			"tool_gates": weather_state["tool_gate_system_count"],
			"story_clues": weather_state["story_clue_system_count"],
			"monster_hunting": weather_state["monster_hunting_system_count"],
		},
		"ruin_system_count": ruin_state["system_count"],
		"ruin_state_owner_count": ruin_state["owner_count"],
		"ruin_scene_owner_count": get_tree().get_nodes_in_group(
			"ruin_exploration"
		).size(),
		"ruin_id": ruin_state["ruin_id"],
		"ruin_count": ruin_state["ruin_count"],
		"ruin_uses_existing_island_dock": (
			ship_state["dock_ids"].has("island")
			and ship.get_dock_definition("island")["shore_position"]
				== Vector2(1550.0, 1400.0)
		),
		"ruin_entrance_count": ruin_state["entrance_count"],
		"ruin_entrance_position": ruin_state["entrance_position"],
		"ruin_entrance_range": ruin_state["entrance_range"],
		"ruin_entrance_visible": ruin_state["entrance_visible"],
		"ruin_entrance_visual_rect": ruin_state["entrance_visual_rect"],
		"ruin_entrance_visual_on_screen": (
			ruin_state["entrance_visual_on_screen"]
		),
		"ruin_entrance_distance": ruin_state["entrance_distance"],
		"ruin_entrance_in_island_walking_region": (
			ruin_state["entrance_in_island_walking_region"]
		),
		"ruin_inside": ruin_state["inside_ruin"],
		"ruin_area_count": ruin_state["ruin_area_count"],
		"ruin_walking_rect": ruin_state["ruin_walking_rect"],
		"ruin_visual_rect": ruin_state["ruin_visual_rect"],
		"ruin_visual_on_screen": ruin_state["ruin_visual_on_screen"],
		"ruin_entry_position": ruin_state["ruin_entry_position"],
		"ruin_exit_position": ruin_state["ruin_exit_position"],
		"ruin_exit_count": ruin_state["ruin_exit_count"],
		"ruin_exit_visible": ruin_state["ruin_exit_visible"],
		"ruin_exit_range": ruin_state["exit_range"],
		"ruin_exit_distance": ruin_state["exit_distance"],
		"ruin_player_uses_existing_walking_owner": (
			int(ruin_state["movement_owner_count"]) == 1
			and player_state["control_mode"] == "WALKING"
		),
		"ruin_player_movement_enabled": (
			ruin_state["player_movement_enabled"]
		),
		"ruin_player_region_kind": player_state["shore_region_kind"],
		"ruin_player_region_rect": player_state["shore_region_rect"],
		"ruin_walking_distance": ruin_state["walking_distance"],
		"ruin_walking_furthest_progress": (
			ruin_state["walking_furthest_progress"]
		),
		"ruin_walking_path_length": ruin_state["walking_path_length"],
		"ruin_walking_path_progress_ratio": (
			ruin_state["walking_path_progress_ratio"]
		),
		"ruin_walking_path_reached_treasure_end": (
			ruin_state["walking_path_reached_treasure_end"]
		),
		"ruin_interaction_prompt": ruin_state["interaction_prompt"],
		"ruin_prompt_visible": (
			interaction_prompt.visible
			and interaction_prompt.text == ruin_state["interaction_prompt"]
			and not String(ruin_state["interaction_prompt"]).is_empty()
		),
		"ruin_prompt_text": (
			interaction_prompt.text
			if interaction_prompt.visible
			and interaction_prompt.text == ruin_state["interaction_prompt"]
			else ""
		),
		"ruin_entrance_attempt_count": ruin_state["entrance_attempt_count"],
		"ruin_entrance_success_count": ruin_state["entrance_success_count"],
		"ruin_exit_attempt_count": ruin_state["exit_attempt_count"],
		"ruin_exit_success_count": ruin_state["exit_success_count"],
		"ruin_treasure_position": ruin_state["treasure_position"],
		"ruin_treasure_range": ruin_state["treasure_range"],
		"ruin_treasure_distance": ruin_state["treasure_distance"],
		"ruin_treasure_lot_name": ruin_state["treasure_lot_name"],
		"ruin_treasure_type_count": ruin_state["treasure_type_count"],
		"ruin_treasure_price_state": ruin_state["treasure_price_state"],
		"ruin_treasure_available": ruin_state["treasure_available"],
		"ruin_treasure_visible": ruin_state["treasure_visible"],
		"ruin_treasure_collected": ruin_state["treasure_collected"],
		"ruin_treasure_choice_pending": (
			ruin_state["treasure_choice_pending"]
		),
		"ruin_treasure_attempt_count": ruin_state["treasure_attempt_count"],
		"ruin_treasure_collection_count": (
			ruin_state["treasure_collection_count"]
		),
		"ruin_treasure_direct_keep_count": ruin_state["direct_keep_count"],
		"ruin_treasure_choice_required_count": (
			ruin_state["choice_required_count"]
		),
		"ruin_treasure_leave_in_place_count": (
			ruin_state["leave_in_place_count"]
		),
		"ruin_treasure_replacement_keep_count": (
			ruin_state["replacement_keep_count"]
		),
		"ruin_treasure_displaced_cargo_count": (
			ruin_state["displaced_cargo_discard_count"]
		),
		"ruin_treasure_cargo_count": ship.get_cargo_lots().count(
			RuinExplorationState.TREASURE_LOT_NAME
		),
		"ruin_treasure_uses_normal_cargo_slot": (
			int(ruin_state["cargo_owner_count"]) == 1
			and ship_state["each_cargo_lot_uses_one_slot"]
		),
		"ruin_treasure_collects_once": ruin_state["treasure_collects_once"],
		"ruin_treasure_state_consistent": (
			ruin_state["treasure_state_consistent"]
		),
		"ruin_last_transition_evidence": (
			ruin_state["last_transition_evidence"]
		),
		"ruin_last_treasure_evidence": ruin_state["last_treasure_evidence"],
		"ruin_last_choice_evidence": ruin_state["last_choice_evidence"],
		"ruin_last_held_input_evidence": (
			ruin_state["last_held_input_evidence"]
		),
		"ruin_fresh_press_required": ruin_state["fresh_press_required"],
		"ruin_held_input_count": ruin_state["held_input_count"],
		"ruin_transition_release_pending": (
			ruin_state["transition_release_pending"]
		),
		"ruin_transition_release_count": (
			ruin_state["transition_release_count"]
		),
		"ruin_return_to_island_count": ruin_state["return_to_island_count"],
		"ruin_return_to_ship_count": ruin_state["return_to_ship_count"],
		"ruin_exploration_tool_count": ruin_state["exploration_tool_count"],
		"ruin_exploration_tool_owner_count": (
			ruin_state["exploration_tool_owner_count"]
		),
		"ruin_exploration_tool_name": ruin_state["exploration_tool_name"],
		"ruin_exploration_tool_source": ruin_state["exploration_tool_source"],
		"ruin_exploration_tool_owned": ruin_state["exploration_tool_owned"],
		"ruin_exploration_tool_award_count": ruin_state["tool_award_count"],
		"ruin_last_tool_award_evidence": (
			ruin_state["last_tool_award_evidence"]
		),
		"ruin_tool_uses_existing_test_resident_request": (
			ruin_state["exploration_tool_source"]
				== "MARA'S DAMAGED DOCK REQUEST"
		),
		"ruin_tool_request_complete": _request_state == RequestState.COMPLETE,
		"ruin_tool_request_view_text": "%s\n%s\n%s" % [
			request_title.text,
			request_status.text,
			request_goal.text,
		],
		"ruin_tool_gate_system_count": ruin_state["tool_gate_system_count"],
		"ruin_blocked_path_count": ruin_state["blocked_path_count"],
		"ruin_tool_gate_type_count": ruin_state["tool_gate_type_count"],
		"ruin_tool_gate_position": ruin_state["tool_gate_position"],
		"ruin_tool_gate_range": ruin_state["tool_gate_range"],
		"ruin_tool_gate_distance": ruin_state["tool_gate_distance"],
		"ruin_tool_gate_near": ruin_state["tool_gate_near"],
		"ruin_tool_gate_open": ruin_state["tool_gate_open"],
		"ruin_tool_gate_closed": ruin_state["tool_gate_closed"],
		"ruin_tool_gate_collision_enabled": (
			ruin_state["tool_gate_collision_enabled"]
		),
		"ruin_tool_gate_prompt_shows_required_tool": (
			ruin_state["tool_gate_near"]
			and not ruin_state["tool_gate_open"]
			and String(ruin_state["interaction_prompt"]).contains(
				"RUIN PRY BAR"
			)
		),
		"ruin_tool_gate_attempt_count": ruin_state["tool_gate_attempt_count"],
		"ruin_tool_gate_denied_count": ruin_state["tool_gate_denied_count"],
		"ruin_tool_gate_open_count": ruin_state["tool_gate_open_count"],
		"ruin_tool_gate_opens_once": ruin_state["tool_gate_opens_once"],
		"ruin_tool_gate_open_persists": ruin_state["tool_gate_open_persists"],
		"ruin_gate_open_exit_count": ruin_state["gate_open_exit_count"],
		"ruin_gate_open_return_entry_count": (
			ruin_state["gate_open_return_entry_count"]
		),
		"ruin_tool_gate_open_after_return": (
			ruin_state["tool_gate_open_after_return"]
		),
		"ruin_tool_gate_completion_flow_holds": (
			ruin_state["tool_gate_completion_flow_holds"]
		),
		"ruin_last_tool_gate_evidence": (
			ruin_state["last_tool_gate_evidence"]
		),
		"ruin_last_denied_tool_gate_evidence": (
			ruin_state["last_denied_tool_gate_evidence"]
		),
		"ruin_successful_tool_gate_evidence": (
			ruin_state["successful_tool_gate_evidence"]
		),
		"ruin_gated_treasure_position": ruin_state["gated_treasure_position"],
		"ruin_gated_treasure_distance": ruin_state["gated_treasure_distance"],
		"ruin_gated_treasure_available": (
			ruin_state["gated_treasure_available"]
		),
		"ruin_gated_treasure_visible": ruin_state["gated_treasure_visible"],
		"ruin_gated_treasure_collected": ruin_state["gated_treasure_collected"],
		"ruin_gated_treasure_count": ruin_state["gated_treasure_count"],
		"ruin_gated_normal_treasure_count": (
			ruin_state["gated_normal_treasure_count"]
		),
		"ruin_gated_treasure_collection_count": (
			ruin_state["gated_treasure_collection_count"]
		),
		"ruin_gated_treasure_collects_once": (
			ruin_state["gated_treasure_collects_once"]
		),
		"ruin_gated_treasure_state_consistent": (
			ruin_state["gated_treasure_state_consistent"]
		),
		"ruin_gated_treasure_is_normal": (
			ruin_state["treasure_lot_name"]
				== RuinExplorationState.TREASURE_LOT_NAME
			and ruin_state["treasure_price_state"] == "NORMAL"
			and ruin_state["treasure_variant_count"] == 1
		),
		"ruin_gate_stays_open_after_treasure": (
			not ruin_state["gated_treasure_collected"]
			or ruin_state["tool_gate_open"]
		),
		"ruin_tool_gate_uses_existing_interaction": true,
		"ruin_tool_gate_uses_existing_cargo_owner": (
			ruin_state["cargo_owner_count"] == 1
		),
		"ruin_cargo_choice": {
			"open": _cargo_choice_open,
			"open_for_ruin": (
				_cargo_choice_open and _pending_cargo_source == CARGO_SOURCE_RUIN
			),
			"pending_lot": (
				_pending_cargo_lot
				if _pending_cargo_source == CARGO_SOURCE_RUIN
				else ""
			),
			"pending_source": _pending_cargo_source,
			"prompt_visible": (
				cargo_choice_view.visible
				and _pending_cargo_source == CARGO_SOURCE_RUIN
			),
			"prompt_text": (
				"%s\n%s" % [cargo_choice_title.text, cargo_choice_details.text]
				if cargo_choice_view.visible
				and _pending_cargo_source == CARGO_SOURCE_RUIN
				else ""
			),
			"leave_control": "X",
			"replacement_controls": ["1", "2", "3", "4"],
			"last_resolution": ruin_state["last_choice_evidence"],
		},
		"ruin_existing_cargo_choice_sources_supported": (
			[CARGO_SOURCE_WRECK, CARGO_SOURCE_FISHING, CARGO_SOURCE_RUIN]
		),
		"ruin_treasure_money_preview": treasure_money_preview.duplicate(true),
		"ruin_treasure_sale_control": "G",
		"ruin_treasure_sale_attempt_count": _treasure_sale_attempt_count,
		"ruin_treasure_sold_lot_count": _treasure_sold_lot_count,
		"ruin_treasure_sale_denied_count": _treasure_sale_denied_count,
		"ruin_treasure_money_earned": _treasure_money_earned,
		"ruin_last_treasure_sale_evidence": (
			_last_treasure_sale_evidence.duplicate(true)
		),
		"ruin_successful_treasure_sale_evidence": (
			_successful_treasure_sale_evidence.duplicate(true)
		),
		"ruin_last_held_treasure_trade_evidence": (
			_last_held_treasure_trade_evidence.duplicate(true)
		),
		"ruin_treasure_sale_uses_existing_port_trader": true,
		"ruin_treasure_sale_uses_canonical_normal_price": (
			ruin_state["treasure_price_state"] == "NORMAL"
			and TradeContact.NORMAL_PRICE
				== int(TradeContact.get_fixed_price_map()["NORMAL"])
		),
		"ruin_treasure_sale_money_accounting_holds": (
			_treasure_money_earned
			== _treasure_sold_lot_count * TradeContact.NORMAL_PRICE
		),
		"ruin_accounting": {
			"state_holds": ruin_state["cargo_accounting_holds"],
			"world_cargo_accounting_holds": (
				accounted_cargo_total == expected_cargo_total
			),
			"money_accounting_holds": money == expected_money,
			"cargo_limit_never_exceeded": (
				ship_state["cargo_limit_never_exceeded"]
			),
			"physical_treasure": ruin_state["physical_treasure_lot_count"],
			"in_ship": ship.get_cargo_lots().count(
				RuinExplorationState.TREASURE_LOT_NAME
			),
			"sold": _treasure_sold_lot_count,
			"displaced_cargo": ruin_state["displaced_cargo_discard_count"],
		},
		"ruin_excluded_features": {
			"tool_gates": ruin_state["tool_gate_system_count"],
			"blocked_paths": ruin_state["blocked_path_count"],
			"puzzles": ruin_state["puzzle_system_count"],
			"story_clues": ruin_state["story_clue_system_count"],
			"curses": ruin_state["curse_system_count"],
			"combat": ruin_state["ruin_combat_system_count"],
			"procedural_ruins": ruin_state["procedural_ruin_system_count"],
			"treasure_variants": int(ruin_state["treasure_variant_count"]) - 1,
			"new_markets": ruin_state["new_market_system_count"],
		},
		"ruin_tool_gate_excluded_features": {
			"tool_upgrades": ruin_state["tool_upgrade_count"],
			"tool_durability": ruin_state["tool_durability_system_count"],
			"extra_gate_types": int(ruin_state["tool_gate_type_count"]) - 1,
			"many_required_return_visits": maxi(
				int(ruin_state["required_return_visit_count"]) - 1,
				0,
			),
			"skill_tree": ruin_state["skill_tree_system_count"],
			"story_clues": ruin_state["story_clue_system_count"],
			"map_fragments": ruin_state["map_fragment_count"],
			"clue_lists": ruin_state["clue_list_count"],
			"clue_descriptions": ruin_state["clue_description_count"],
			"story_chart_locations": (
				ruin_state["new_story_chart_location_count"]
			),
			"story_clue_persistence": (
				ruin_state["story_clue_persistence_count"]
			),
			"monster_hunting": ruin_state["monster_hunting_system_count"],
			"ship_module_loadout": (
				ruin_state["ship_module_loadout_system_count"]
			),
			"resident_reactions": (
				ruin_state["resident_reaction_system_count"]
			),
			"relationship_progress": (
				ruin_state["relationship_progress_system_count"]
			),
			"day_and_night": ruin_state["day_night_system_count"],
			"fast_travel": ruin_state["fast_travel_system_count"],
		},
		"story_clue_system_count": story_state["system_count"],
		"story_clue_state_owner_count": story_state["owner_count"],
		"story_fragment_id": story_state["fragment_id"],
		"story_fragment_lot_name": story_state["fragment_lot_name"],
		"story_fragment_position": story_state["fragment_position"],
		"story_fragment_range": story_state["fragment_range"],
		"story_fragment_distance": story_state["fragment_distance"],
		"story_fragment_available": story_state["fragment_available"],
		"story_fragment_visible": story_state["fragment_visible"],
		"story_fragment_behind_existing_tool_gate": (
			story_state["fragment_behind_existing_tool_gate"]
			and ruin_state["tool_gate_system_count"] == 1
			and ruin_state["tool_gate_type_count"] == 1
		),
		"story_fragment_requires_open_tool_gate": (
			not story_state["fragment_interaction_available"]
			or ruin_state["tool_gate_open"]
		),
		"story_fragment_interaction_available": (
			story_state["fragment_interaction_available"]
		),
		"story_fragment_prompt_visible": (
			interaction_prompt.visible
			and interaction_prompt.text
				== story_state["interaction_prompt"]
			and not String(story_state["interaction_prompt"]).is_empty()
		),
		"story_fragment_prompt_text": (
			interaction_prompt.text
			if interaction_prompt.visible
			and interaction_prompt.text == story_state["interaction_prompt"]
			else ""
		),
		"story_fragment_acquired": story_state["fragment_acquired"],
		"story_fragment_attempt_count": story_state["fragment_attempt_count"],
		"story_fragment_acquisition_count": (
			story_state["fragment_acquisition_count"]
		),
		"story_fragment_collects_once": story_state["fragment_collects_once"],
		"story_fragment_direct_keep_count": story_state["direct_keep_count"],
		"story_fragment_choice_required_count": (
			story_state["choice_required_count"]
		),
		"story_fragment_leave_in_place_count": (
			story_state["leave_in_place_count"]
		),
		"story_fragment_replacement_keep_count": (
			story_state["replacement_keep_count"]
		),
		"story_fragment_displaced_cargo_count": (
			story_state["displaced_cargo_discard_count"]
		),
		"story_fragment_in_ship_cargo_count": (
			ship.get_cargo_lots().count(StoryClueState.FRAGMENT_LOT_NAME)
		),
		"story_fragment_in_cove_storage_count": (
			cove_storage.count_cargo_lot(
				StoryClueState.FRAGMENT_LOT_NAME
			)
		),
		"story_fragment_in_existing_cargo_owner_count": (
			story_physical_state["cargo_fragment_count"]
		),
		"story_fragment_physical_state": story_physical_state,
		"story_one_physical_fragment_invariant": (
			int(story_physical_state["total_physical_fragment_count"]) == 1
		),
		"story_fragment_uses_existing_cargo_owner": (
			story_state["cargo_owner_count"] == 1
			and ship_state["each_cargo_lot_uses_one_slot"]
		),
		"story_fragment_cargo_limit_never_exceeded": (
			ship_state["cargo_limit_never_exceeded"]
		),
		"story_fragment_choice": {
			"open": _cargo_choice_open,
			"open_for_fragment": (
				_cargo_choice_open
				and _pending_cargo_source == CARGO_SOURCE_STORY_CLUE
			),
			"pending_lot": (
				_pending_cargo_lot
				if _pending_cargo_source == CARGO_SOURCE_STORY_CLUE
				else ""
			),
			"pending_source": _pending_cargo_source,
			"prompt_visible": (
				cargo_choice_view.visible
				and _pending_cargo_source == CARGO_SOURCE_STORY_CLUE
			),
			"prompt_text": (
				"%s\n%s" % [
					cargo_choice_title.text,
					cargo_choice_details.text,
				]
				if cargo_choice_view.visible
				and _pending_cargo_source == CARGO_SOURCE_STORY_CLUE
				else ""
			),
			"leave_control": "X",
			"replacement_controls": ["1", "2", "3", "4"],
			"last_resolution": story_state["last_choice_evidence"],
		},
		"story_fragment_existing_cargo_choice_sources_supported": [
			CARGO_SOURCE_WRECK,
			CARGO_SOURCE_FISHING,
			CARGO_SOURCE_RUIN,
			CARGO_SOURCE_STORY_CLUE,
		],
		"story_fragment_interaction_release_pending": (
			story_state["interaction_release_pending"]
		),
		"story_fragment_release_count": story_state["release_count"],
		"story_fragment_held_input_count": story_state["held_input_count"],
		"story_fragment_fresh_press_required": (
			story_state["fresh_press_required"]
		),
		"story_last_fragment_evidence": (
			story_state["last_fragment_evidence"]
		),
		"story_successful_fragment_evidence": (
			story_state["successful_fragment_evidence"]
		),
		"story_last_held_input_evidence": (
			story_state["last_held_input_evidence"]
		),
		"story_clue_list_count": story_state["clue_list_count"],
		"story_clue_entry_count": story_state["clue_entry_count"],
		"story_clue_entries": story_state["clue_entries"],
		"story_clue_id": story_state["clue_id"],
		"story_clue_title": story_state["clue_title"],
		"story_clue_description": story_state["clue_description"],
		"story_clue_description_count": (
			story_state["clue_description_count"]
		),
		"story_one_clue_entry_only": story_state["one_clue_entry_only"],
		"story_clue_recorded_only_after_fragment": (
			story_state["clue_recorded_only_after_acquisition"]
		),
		"story_clue_identity_exact": story_state["clue_identity_exact"],
		"story_chart_clue_list_entry_count": (
			waypoint_state["story_clue_entry_count"]
		),
		"story_chart_clue_entries": waypoint_state["story_clue_entries"],
		"story_clue_view_matches_owner": (
			waypoint_state["story_clue_entries"]
				== story_state["clue_entries"]
		),
		"story_location_id": story_state["story_location_id"],
		"story_location_name": story_state["story_location_name"],
		"story_location_position": story_state["story_location_position"],
		"story_location_count": story_state["story_location_count"],
		"story_location_unlocked": story_state["story_location_unlocked"],
		"story_location_unlocked_with_clue": (
			story_state["story_location_unlocked_with_clue"]
		),
		"story_location_is_clear_sea_destination": (
			sea_state["bounds"].has_point(
				story_state["story_location_position"]
			)
			and story_state["story_location_position"].distance_to(
				sea_state["island_center"]
			) > float(sea_state["island_radius"])
			and not sea_state["port_land_rect"].has_point(
				story_state["story_location_position"]
			)
		),
		"story_chart_location_marker_count": (
			waypoint_state["story_location_marker_count"]
		),
		"story_chart_location_marker_visible": (
			waypoint_state["story_location_marker_visible"]
		),
		"story_chart_location_selected": (
			waypoint_state["story_location_selected"]
		),
		"story_chart_content_sync_count": (
			waypoint_state["story_content_sync_count"]
		),
		"story_chart_same_location_sync_count": (
			waypoint_state["story_same_location_sync_count"]
		),
		"story_chart_selection_preserved_count": (
			waypoint_state["story_selection_preserved_count"]
		),
		"story_last_chart_content_sync_evidence": (
			waypoint_state["last_story_content_sync_evidence"]
		),
		"story_chart_selection_persists_across_same_sync": (
			bool(
				waypoint_state["last_story_content_sync_evidence"].get(
					"selection_preserved_on_same_location_sync",
					true,
				)
			)
		),
		"story_chart_location_matches_owner": (
			waypoint_state["story_location_id"]
				== (
					story_state["story_location_id"]
					if story_state["story_location_unlocked"]
					else ""
				)
			and waypoint_state["story_location_marker_count"]
				== story_state["story_location_count"]
		),
		"story_chart_select_control": "4",
		"story_return_to_cove_count": story_state["return_to_cove_count"],
		"story_last_return_to_cove_evidence": (
			story_state["last_return_to_cove_evidence"]
		),
		"story_clue_available_after_cove_return": (
			story_state["return_to_cove_count"] == 0
			or (
				story_state["clue_entry_count"] == 1
				and story_state["story_location_unlocked"]
			)
		),
		"story_save_path": story_state["save_path"],
		"story_save_section": story_state["save_section"],
		"story_save_key": story_state["save_key"],
		"story_save_format": story_state["save_format"],
		"story_save_version": story_state["save_version"],
		"story_save_file_exists": story_state["save_file_exists"],
		"story_save_count": story_state["save_count"],
		"story_load_count": story_state["load_count"],
		"story_startup_load_attempt_count": (
			story_state["startup_load_attempt_count"]
		),
		"story_startup_restore_count": (
			story_state["startup_restore_count"]
		),
		"story_persistence_cleanup_count": story_state["cleanup_count"],
		"story_fragment_in_cargo_at_save": (
			story_state["fragment_in_cargo_at_save"]
		),
		"story_fragment_restored_to_cargo_count": (
			story_state["fragment_restored_to_cargo_count"]
		),
		"story_last_save_evidence": story_state["last_save_evidence"],
		"story_last_load_evidence": story_state["last_load_evidence"],
		"story_last_cleanup_evidence": story_state["last_cleanup_evidence"],
		"story_last_load_atomic_evidence": (
			_last_story_load_atomic_evidence.duplicate(true)
		),
		"story_last_cleanup_atomic_evidence": (
			_last_story_cleanup_atomic_evidence.duplicate(true)
		),
		"story_load_atomicity_holds": (
			_last_story_load_atomic_evidence.is_empty()
			or bool(_last_story_load_atomic_evidence.get(
				"atomic_story_and_physical_commit",
				false,
			))
		),
		"story_load_existing_storage_fragment_case_holds": (
			_last_story_load_atomic_evidence.is_empty()
			or not bool(_last_story_load_atomic_evidence.get(
				"storage_fragment_satisfied_load",
				false,
			))
			or (
				bool(_last_story_load_atomic_evidence.get("success", false))
				and not bool(_last_story_load_atomic_evidence.get(
					"restoration_added",
					false,
				))
				and int(story_physical_state["storage_fragment_count"]) == 1
				and int(story_physical_state["total_physical_fragment_count"])
					== 1
			)
		),
		"story_load_no_slot_rejection_holds": (
			_last_story_load_atomic_evidence.is_empty()
			or not bool(_last_story_load_atomic_evidence.get(
				"no_slot_rejection",
				false,
			))
			or (
				not bool(_last_story_load_atomic_evidence.get("success", true))
				and bool(_last_story_load_atomic_evidence.get(
					"atomic_story_and_physical_commit",
					false,
				))
			)
		),
		"story_load_absent_fragment_case_observed": bool(
			_last_story_load_atomic_evidence.get(
				"valid_absent_fragment_load_case_observed",
				false,
			)
		),
		"story_load_absent_fragment_case_holds": (
			_last_story_load_atomic_evidence.is_empty()
			or bool(_last_story_load_atomic_evidence.get(
				"valid_absent_fragment_load_case_holds",
				false,
			))
		),
		"story_cleanup_atomicity_holds": (
			_last_story_cleanup_atomic_evidence.is_empty()
			or (
				bool(_last_story_cleanup_atomic_evidence.get("success", false))
				and bool(_last_story_cleanup_atomic_evidence.get(
					"cargo_accounting_consistent",
					false,
				))
				and bool(_last_story_cleanup_atomic_evidence.get(
					"one_physical_fragment_after_cleanup",
					false,
				))
			)
			or (
				not bool(_last_story_cleanup_atomic_evidence.get(
					"success",
					true,
				))
				and (
					bool(_last_story_cleanup_atomic_evidence.get(
						"state_unchanged",
						false,
					))
					or bool(_last_story_cleanup_atomic_evidence.get(
						"cargo_rollback_holds",
						false,
					))
				)
			)
		),
		"story_cleanup_after_replacement_case_observed": bool(
			_last_story_cleanup_atomic_evidence.get(
				"replacement_then_cleanup_sequence_observed",
				false,
			)
		),
		"story_cleanup_after_replacement_case_holds": (
			_last_story_cleanup_atomic_evidence.is_empty()
			or not bool(_last_story_cleanup_atomic_evidence.get(
				"replacement_then_cleanup_sequence_observed",
				false,
			))
			or bool(_last_story_cleanup_atomic_evidence.get(
				"replacement_then_cleanup_accounting_holds",
				false,
			))
		),
		"story_cleanup_unsupported_fragment_removal_rejection_observed": (
			String(_last_story_cleanup_atomic_evidence.get(
				"reason",
				"",
			)) == "UNSUPPORTED_FRAGMENT_OWNER_OR_REMOVAL"
		),
		"story_cleanup_unsupported_fragment_removal_rejection_holds": (
			String(_last_story_cleanup_atomic_evidence.get(
				"reason",
				"",
			)) != "UNSUPPORTED_FRAGMENT_OWNER_OR_REMOVAL"
			or (
				not bool(_last_story_cleanup_atomic_evidence.get(
					"success",
					true,
				))
				and not bool(_last_story_cleanup_atomic_evidence.get(
					"irreversible_change_started",
					true,
				))
				and bool(_last_story_cleanup_atomic_evidence.get(
					"state_file_cargo_and_chart_unchanged",
					false,
				))
			)
		),
		"story_cleanup_valid_persisted_absent_case_observed": bool(
			_last_story_cleanup_atomic_evidence.get(
				"valid_persisted_absent_cleanup_observed",
				false,
			)
		),
		"story_cleanup_valid_persisted_absent_case_holds": (
			not bool(_last_story_cleanup_atomic_evidence.get(
				"valid_persisted_absent_cleanup_observed",
				false,
			))
			or (
				bool(_last_story_cleanup_atomic_evidence.get("success", false))
				and bool(_last_story_cleanup_atomic_evidence.get(
					"valid_persisted_absent_cleanup_holds",
					false,
				))
			)
		),
		"story_cleanup_never_reports_failure_after_irreversible_commit": (
			_last_story_cleanup_atomic_evidence.is_empty()
			or not bool(_last_story_cleanup_atomic_evidence.get(
				"irreversible_change_committed",
				false,
			))
			or bool(_last_story_cleanup_atomic_evidence.get("success", false))
		),
		"story_clue_and_location_persist_after_load": (
			story_state["load_count"] == 0
			or (
				story_state["clue_entry_count"] == 1
				and story_state["story_location_unlocked"]
				and waypoint_state["story_location_marker_count"] == 1
			)
		),
		"story_cargo_accounting": {
			"world_fragment": story_state["world_fragment_lot_count"],
			"in_ship": ship.get_cargo_lots().count(
				StoryClueState.FRAGMENT_LOT_NAME
			),
			"in_cove_storage": cove_storage.count_cargo_lot(
				StoryClueState.FRAGMENT_LOT_NAME
			),
			"one_physical_fragment": (
				int(story_physical_state["total_physical_fragment_count"])
					== 1
			),
			"displaced_cargo": (
				story_state["displaced_cargo_discard_count"]
			),
			"persisted_fragment_absent": (
				story_state["persisted_fragment_absent_count"]
			),
			"accounted_total": accounted_cargo_total,
			"expected_total": expected_cargo_total,
			"holds": accounted_cargo_total == expected_cargo_total,
			"cargo_limit_never_exceeded": (
				ship_state["cargo_limit_never_exceeded"]
			),
		},
		"story_completion_flow_holds": (
			story_state["fragment_acquisition_count"] == 1
			and story_state["clue_entry_count"] == 1
			and story_state["story_location_unlocked"]
			and waypoint_state["story_location_marker_count"] == 1
		),
		"story_excluded_features": {
			"extra_clue_chains": maxi(
				int(story_state["clue_chain_count"]) - 1,
				0,
			),
			"clue_combination": (
				story_state["clue_combination_system_count"]
			),
			"deduction_screens": story_state["deduction_screen_count"],
			"cursed_objects": story_state["cursed_object_count"],
			"resident_reactions": (
				story_state["resident_reaction_system_count"]
			),
			"relationship_progress": (
				story_state["relationship_progress_system_count"]
			),
			"monsters": story_state["monster_system_count"],
			"harpoon_actions": story_state["harpoon_action_count"],
			"monster_attacks": story_state["monster_attack_count"],
			"monster_part_cargo": story_state["monster_part_cargo_count"],
			"ship_module_loadout": (
				story_state["ship_module_loadout_system_count"]
			),
		},
		"monster_hunt_system_count": monster_state["system_count"],
		"monster_hunt_owner_count": monster_state["owner_count"],
		"monster_count": monster_state["monster_count"],
		"monster_type_count": monster_state["monster_type_count"],
		"monster_id": monster_state["monster_id"],
		"monster_name": monster_state["monster_name"],
		"monster_location_id": monster_state["location_id"],
		"monster_location_position": monster_state["location_position"],
		"monster_location_matches_story_clue_exactly": (
			monster_state["location_matches_story_clue_exactly"]
			and monster_state["location_id"] == story_state["story_location_id"]
			and monster_state["location_position"]
				== story_state["story_location_position"]
		),
		"monster_encounter_range": monster_state["encounter_range"],
		"ship_distance_to_monster": monster_state["ship_distance"],
		"monster_visible": monster_state["visible"],
		"monster_visual_on_screen": monster_state["visual_on_screen"],
		"monster_clue_unlocked": monster_state["clue_unlocked"],
		"monster_encounter_started": monster_state["encounter_started"],
		"monster_encounter_active": monster_state["encounter_active"],
		"monster_encounter_start_count": monster_state["encounter_start_count"],
		"monster_activation_requires_exact_unlocked_clue_location": (
			monster_state[
				"activation_requires_exact_unlocked_clue_location"
			]
		),
		"monster_health": monster_state["health"],
		"monster_health_max": monster_state["health_max"],
		"monster_defeated": monster_state["defeated"],
		"monster_defeat_count": monster_state["monster_defeat_count"],
		"monster_defeat_once_holds": monster_state["defeat_once_holds"],
		"monster_harpoon_action_count": monster_state["harpoon_action_count"],
		"monster_harpoon_key": monster_state["harpoon_key"],
		"monster_harpoon_pressed": _harpoon_pressed,
		"monster_harpoon_damage": monster_state["harpoon_damage"],
		"monster_harpoon_reload_duration": (
			monster_state["harpoon_reload_duration"]
		),
		"monster_harpoon_reload_remaining": (
			monster_state["harpoon_reload_remaining"]
		),
		"monster_harpoon_reload_ready": (
			monster_state["harpoon_reload_ready"]
		),
		"monster_harpoon_attempt_count": (
			monster_state["harpoon_attempt_count"]
		),
		"monster_harpoon_hit_count": monster_state["harpoon_hit_count"],
		"monster_harpoon_held_input_count": (
			monster_state["harpoon_held_input_count"]
		),
		"monster_harpoon_reload_rejected_count": (
			monster_state["harpoon_reload_rejected_count"]
		),
		"monster_harpoon_no_ammunition_rejected_count": (
			monster_state["harpoon_no_ammunition_rejected_count"]
		),
		"monster_harpoon_inactive_rejected_count": (
			monster_state["harpoon_inactive_rejected_count"]
		),
		"monster_harpoon_defeated_rejected_count": (
			monster_state["harpoon_defeated_rejected_count"]
		),
		"monster_last_harpoon_result": monster_state["last_harpoon_result"],
		"monster_last_harpoon_evidence": (
			monster_state["last_harpoon_evidence"]
		),
		"monster_last_held_harpoon_evidence": (
			monster_state["last_held_harpoon_evidence"]
		),
		"monster_last_reload_rejection_evidence": (
			monster_state["last_reload_rejection_evidence"]
		),
		"monster_last_no_ammunition_evidence": (
			monster_state["last_no_ammunition_evidence"]
		),
		"monster_last_inactive_harpoon_evidence": (
			monster_state["last_inactive_evidence"]
		),
		"monster_harpoon_fresh_press_required": (
			monster_state["fresh_press_required"]
		),
		"monster_harpoon_uses_existing_ammunition_owner": (
			monster_state["accepted_harpoon_uses_existing_ammunition"]
		),
		"monster_harpoon_fixed_ammunition_delta": (
			monster_state["accepted_harpoon_ammunition_delta"]
		),
		"monster_attack_action_count": (
			monster_state["monster_attack_action_count"]
		),
		"monster_attack_name": monster_state["monster_attack_name"],
		"monster_attack_request_count": (
			monster_state["monster_attack_request_count"]
		),
		"monster_attack_count": monster_state["monster_attack_count"],
		"monster_attack_completed": (
			monster_state["monster_attack_completed"]
		),
		"monster_one_attack_only": monster_state["one_monster_attack_only"],
		"monster_last_attack_evidence": (
			monster_state["last_attack_evidence"]
		),
		"monster_main_attack_evidence": (
			_last_monster_attack_evidence.duplicate(true)
		),
		"monster_attack_uses_existing_hull_owner": (
			monster_state["uses_existing_ship_damage_owner"]
			and damage_state["owner_count"] == 1
		),
		"monster_attack_uses_existing_crew_owner": (
			monster_state["uses_existing_crew_condition_owner"]
			and crew_state["owner_count"] == 1
		),
		"monster_attack_fixed_hull_damage": (
			damage_state["monster_attack_fixed_damage"]
		),
		"monster_attack_fixed_crew_injury": (
			crew_state["fixed_injury_amount"]
		),
		"monster_weather_effect_count": monster_state["weather_effect_count"],
		"monster_weather_effect_kind": monster_state["weather_effect_kind"],
		"monster_weather_storm_active": monster_state["weather_storm_active"],
		"monster_uses_existing_weather_owner": (
			monster_state["uses_existing_weather_owner"]
			and weather_state["owner_count"] == 1
		),
		"monster_part_lot_name": monster_state["part_lot_name"],
		"monster_part_generation_count": (
			monster_state["part_generation_count"]
		),
		"monster_part_pending_count": monster_state["part_pending_count"],
		"monster_part_in_ship_cargo_count": (
			monster_state["part_in_ship_cargo_count"]
		),
		"monster_part_in_cove_storage_count": (
			monster_state["part_in_cove_storage_count"]
		),
		"monster_part_in_existing_cargo_count": (
			monster_state["part_in_cargo_count"]
		),
		"monster_part_choice_required_count": (
			monster_state["part_choice_required_count"]
		),
		"monster_part_direct_keep_count": (
			monster_state["part_direct_keep_count"]
		),
		"monster_part_leave_available": monster_state["part_leave_available"],
		"monster_part_requires_replacement_when_full": (
			monster_state["part_requires_replacement_when_full"]
		),
		"monster_part_leave_blocked_count": (
			monster_state["part_leave_blocked_count"]
		),
		"monster_last_part_leave_blocked_evidence": (
			monster_state["last_part_leave_blocked_evidence"]
		),
		"monster_part_replacement_keep_count": (
			monster_state["part_replacement_keep_count"]
		),
		"monster_part_displaced_cargo_discard_count": (
			monster_state["part_displaced_cargo_discard_count"]
		),
		"monster_part_accounting_holds": (
			monster_state["part_accounting_holds"]
		),
		"monster_one_part_award_holds": monster_state["one_part_award_holds"],
		"monster_one_part_physical_holds": (
			monster_state["one_part_physical_holds"]
		),
		"monster_part_uses_existing_cargo_owner": (
			monster_state["uses_existing_cargo_owner"]
			and ship_state["each_cargo_lot_uses_one_slot"]
		),
		"monster_part_uses_existing_cargo_choice": (
			monster_state["uses_existing_cargo_choice"]
		),
		"monster_part_cargo_choice": {
			"open": (
				_cargo_choice_open
				and _pending_cargo_source == CARGO_SOURCE_MONSTER_HUNT
			),
			"pending_lot": (
				_pending_cargo_lot
				if _pending_cargo_source == CARGO_SOURCE_MONSTER_HUNT
				else ""
			),
			"prompt_visible": (
				cargo_choice_view.visible
				and _pending_cargo_source == CARGO_SOURCE_MONSTER_HUNT
			),
			"prompt_text": (
				"%s\n%s" % [cargo_choice_title.text, cargo_choice_details.text]
				if cargo_choice_view.visible
				and _pending_cargo_source == CARGO_SOURCE_MONSTER_HUNT
				else ""
			),
			"navigation_blocked": (
				_cargo_choice_open
				and _pending_cargo_source == CARGO_SOURCE_MONSTER_HUNT
				and ship_state["navigation_input_blocked"]
			),
			"leave_control": "UNAVAILABLE",
			"blocked_leave_control": "X",
			"replacement_required": true,
			"replacement_controls": ["1", "2", "3", "4"],
			"last_resolution": monster_state["last_part_choice_evidence"],
		},
		"monster_return_to_cove_count": monster_state["return_to_cove_count"],
		"monster_returned_to_cove_with_part": (
			monster_state["returned_to_cove_with_part"]
		),
		"monster_last_return_evidence": monster_state["last_return_evidence"],
		"monster_completion_flow_holds": (
			monster_state["monster_defeat_count"] == 1
			and monster_state["part_in_cargo_count"] == 1
			and monster_state["returned_to_cove_with_part"]
		),
		"monster_hunt_view_visible": monster_hunt_view.visible,
		"monster_hunt_view_text": monster_hunt_view_text,
		"monster_hunt_state": monster_state.duplicate(true),
		"monster_excluded_features": {
			"extra_monster_types": monster_state["extra_monster_type_count"],
			"ship_module_selection": (
				monster_state["ship_module_selection_count"]
			),
			"ship_module_slots": monster_state["ship_module_slot_count"],
			"harpoon_upgrades": monster_state["harpoon_upgrade_count"],
			"gear_crafting": monster_state["gear_crafting_system_count"],
			"separate_combat_screen": (
				monster_state["separate_combat_screen_count"]
			),
			"repeatable_boss": monster_state["repeatable_boss_system_count"],
			"cargo_racks": monster_state["cargo_rack_module_count"],
			"long_guns": monster_state["long_gun_module_count"],
			"fishing_gear": monster_state["fishing_gear_module_count"],
			"resident_reactions": monster_state["resident_reaction_count"],
			"relationship_progress": (
				monster_state["relationship_progress_count"]
			),
		},
		"fishing_system_count": fishing_state["system_count"],
		"fishing_state_owner_count": fishing_state["owner_count"],
		"fishing_area_count": fishing_state["area_count"],
		"fishing_area_id": fishing_state["area_id"],
		"fishing_area_position": fishing_state["area_position"],
		"fishing_area_at_sea": (
			sea_state["bounds"].has_point(fishing_state["area_position"])
			and fishing_state["area_position"].distance_to(
				sea_state["island_center"]
			) > float(sea_state["island_radius"])
			and not sea_state["port_land_rect"].has_point(
				fishing_state["area_position"]
			)
		),
		"fishing_area_visible": fishing_state["area_visible"],
		"fishing_area_visual_radius": fishing_state["visual_radius"],
		"fishing_area_visual_local_bounds": fishing_state["visual_local_bounds"],
		"fishing_area_visual_world_rect": fishing_state["visual_world_rect"],
		"fishing_area_visual_on_screen": fishing_state["visual_on_screen"],
		"fishing_range": fishing_state["fishing_range"],
		"fishing_max_speed": fishing_state["fishing_max_speed"],
		"ship_distance_to_fishing_area": fishing_state["ship_distance"],
		"fishing_eligibility": fishing_state["eligibility"],
		"fishing_eligible": fishing_state["fishing_eligible"],
		"fishing_requires_captain_aboard": true,
		"fishing_requires_stopped_ship": true,
		"fishing_prompt_visible": (
			interaction_prompt.visible
			and (
				interaction_prompt.text == "[E] CATCH ONE FISH LOT"
				or interaction_prompt.text
					== "[E] FISHING GEAR · CATCH ONE LARGE FISH LOT"
				or interaction_prompt.text == "STOP SHIP TO FISH"
				or interaction_prompt.text == "CAPTAIN MUST BE ABOARD TO FISH"
				or interaction_prompt.text == "STORM · FISHING BLOCKED"
			)
		),
		"fishing_prompt_text": (
			interaction_prompt.text
			if interaction_prompt.visible
			and (
				interaction_prompt.text == "[E] CATCH ONE FISH LOT"
				or interaction_prompt.text
					== "[E] FISHING GEAR · CATCH ONE LARGE FISH LOT"
				or interaction_prompt.text == "STOP SHIP TO FISH"
				or interaction_prompt.text == "CAPTAIN MUST BE ABOARD TO FISH"
				or interaction_prompt.text == "STORM · FISHING BLOCKED"
			)
			else ""
		),
		"fish_lot_name": fishing_state["fish_lot_name"],
		"large_fish_lot_name": fishing_state["large_fish_lot_name"],
		"large_catch_fish_units": fishing_state["large_catch_fish_units"],
		"fish_type_count": fishing_state["fish_type_count"],
		"fishing_catch_size_count": fishing_state["catch_size_count"],
		"fish_price_state": fishing_state["fish_price_state"],
		"fish_cargo_lot_count": (
			ship.get_cargo_lots().count(FishingAreaState.FISH_LOT_NAME)
			+ ship.get_cargo_lots().count(
				FishingAreaState.LARGE_FISH_LOT_NAME
			)
		),
		"large_fish_cargo_lot_count": ship.get_cargo_lots().count(
			FishingAreaState.LARGE_FISH_LOT_NAME
		),
		"fish_uses_normal_cargo_slots": true,
		"fish_each_lot_uses_one_slot": ship_state["each_cargo_lot_uses_one_slot"],
		"fishing_catch_attempt_count": fishing_state["catch_attempt_count"],
		"successful_fishing_catch_count": (
			fishing_state["successful_catch_count"]
		),
		"fishing_direct_keep_count": fishing_state["direct_keep_count"],
		"fishing_choice_required_count": fishing_state["choice_required_count"],
		"fishing_discarded_catch_count": fishing_state["discarded_catch_count"],
		"fishing_replacement_keep_count": fishing_state["replacement_keep_count"],
		"fishing_pending_catch_count": fishing_state["pending_catch_count"],
		"fishing_pending_lot_name": fishing_state["pending_fish_lot_name"],
		"fishing_module_voyage_serial": fishing_state["module_voyage_serial"],
		"fishing_larger_catch_available": (
			fishing_state["larger_catch_available"]
		),
		"fishing_larger_catch_count": fishing_state["larger_catch_count"],
		"fishing_normal_catch_count": fishing_state["normal_catch_count"],
		"fishing_one_larger_catch_per_cove_voyage": (
			fishing_state["one_larger_catch_per_cove_voyage"]
		),
		"fishing_last_module_evidence": fishing_state["last_module_evidence"],
		"fishing_last_catch_result": fishing_state["last_catch_result"],
		"fishing_last_catch_evidence": fishing_state["last_catch_evidence"],
		"fishing_last_choice_evidence": fishing_state["last_choice_evidence"],
		"fishing_last_held_input_evidence": (
			fishing_state["last_held_input_evidence"]
		),
		"fishing_storm_blocked_attempt_count": (
			fishing_state["storm_blocked_attempt_count"]
		),
		"fishing_last_storm_blocked_evidence": (
			fishing_state["last_storm_blocked_evidence"]
		),
		"fishing_weather_recovery_catch_count": (
			fishing_state["weather_recovery_catch_count"]
		),
		"fishing_weather_recovery_pending": (
			fishing_state["weather_recovery_pending"]
		),
		"fishing_last_weather_recovery_evidence": (
			fishing_state["last_weather_recovery_evidence"]
		),
		"weather_fishing_effect_kind": fishing_state["weather_effect_kind"],
		"weather_fishing_block_has_no_state_change": (
			fishing_state["last_storm_blocked_evidence"].is_empty()
			or (
				bool(fishing_state["last_storm_blocked_evidence"].get(
					"cargo_unchanged",
					false,
				))
				and bool(fishing_state["last_storm_blocked_evidence"].get(
					"fish_count_unchanged",
					false,
				))
				and bool(fishing_state["last_storm_blocked_evidence"].get(
					"no_fish_generated",
					false,
				))
			)
		),
		"weather_fishing_accounting_holds": (
			fishing_state["catch_accounting_holds"]
			and accounted_cargo_total == expected_cargo_total
			and money == expected_money
		),
		"fishing_fresh_press_required": fishing_state["fresh_press_required"],
		"fishing_one_lot_per_fresh_press": (
			fishing_state["one_lot_per_fresh_press"]
		),
		"fishing_catch_accounting_holds": (
			fishing_state["catch_accounting_holds"]
		),
		"fishing_uses_existing_cargo_owner": true,
		"fishing_uses_existing_cargo_choice": true,
		"fishing_uses_existing_cove_buyer": true,
		"fishing_cargo_choice": {
			"open_for_fish": (
				_cargo_choice_open
				and _pending_cargo_source == CARGO_SOURCE_FISHING
			),
			"pending_lot": (
				_pending_cargo_lot
				if _pending_cargo_source == CARGO_SOURCE_FISHING
				else ""
			),
			"prompt_visible": (
				cargo_choice_view.visible
				and _pending_cargo_source == CARGO_SOURCE_FISHING
			),
			"prompt_text": (
				"%s\n%s" % [cargo_choice_title.text, cargo_choice_details.text]
				if cargo_choice_view.visible
				and _pending_cargo_source == CARGO_SOURCE_FISHING
				else ""
			),
			"navigation_blocked": (
				_cargo_choice_open
				and _pending_cargo_source == CARGO_SOURCE_FISHING
				and ship_state["navigation_input_blocked"]
			),
			"discard_control": "X",
			"replacement_controls": ["1", "2", "3", "4"],
			"last_resolution": fishing_state["last_choice_evidence"],
		},
		"fishing_sale": {
			"system": "COVE_BUYER",
			"control": "F",
			"lot_name": fishing_state["fish_lot_name"],
			"price_state": fishing_state["fish_price_state"],
			"fixed_price": TradeContact.NORMAL_PRICE,
			"money_preview": fish_money_preview.duplicate(true),
			"large_catch_money_preview": large_fish_money_preview.duplicate(true),
			"uses_canonical_normal_fixed_price": (
				fishing_state["fish_price_state"] == "NORMAL"
				and TradeContact.NORMAL_PRICE
					== int(TradeContact.get_fixed_price_map()["NORMAL"])
			),
			"attempt_count": _fish_sale_attempt_count,
			"sold_lot_count": _fish_sold_lot_count,
			"sold_fish_unit_count": _fish_sold_unit_count,
			"money_earned": _fish_money_earned,
			"expected_money_earned": (
				_fish_sold_unit_count * TradeContact.NORMAL_PRICE
			),
			"exact_money_accounting_holds": (
				_fish_money_earned
				== _fish_sold_unit_count * TradeContact.NORMAL_PRICE
			),
			"last_evidence": _last_fish_sale_evidence.duplicate(true),
			"successful_evidence": (
				_successful_fish_sale_evidence.duplicate(true)
			),
		},
		"fishing_accounting": {
			"catch_accounting_holds": fishing_state["catch_accounting_holds"],
			"world_cargo_accounting_holds": (
				accounted_cargo_total == expected_cargo_total
			),
			"money_accounting_holds": money == expected_money,
			"cargo_limit_never_exceeded": ship_state["cargo_limit_never_exceeded"],
			"caught": fishing_state["successful_catch_count"],
			"in_ship": ship.get_cargo_lots().count(
				FishingAreaState.FISH_LOT_NAME
			) + ship.get_cargo_lots().count(
				FishingAreaState.LARGE_FISH_LOT_NAME
			),
			"pending": fishing_state["pending_catch_count"],
			"discarded_new_fish": fishing_state["discarded_catch_count"],
			"discarded_replaced_cargo": (
				fishing_state["displaced_cargo_discard_count"]
			),
			"sold": _fish_sold_lot_count,
		},
		"fishing_excluded_features": {
			"separate_minigame": fishing_state["separate_minigame_enabled"],
			"rod_net_trap_upgrades": fishing_state["fishing_upgrades_enabled"],
			"rare_fish": fishing_state["rare_fish_enabled"],
			"weather_effects": fishing_state["weather_effects_enabled"],
			"time_effects": fishing_state["time_effects_enabled"],
			"monster_fishing": fishing_state["monster_fishing_enabled"],
		},
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
		"pending_cargo_lot": _pending_cargo_lot,
		"pending_cargo_source": _pending_cargo_source,
		"pending_salvage_lot": (
			_pending_cargo_lot
			if _pending_cargo_source == CARGO_SOURCE_WRECK
			else ""
		),
		"pending_salvage_lot_still_at_wreck": (
			_pending_cargo_source != CARGO_SOURCE_WRECK
			or _pending_cargo_lot.is_empty()
			or wreck_state["next_salvage_lot"] == _pending_cargo_lot
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
			"controls": _get_cargo_choice_controls_text(),
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
