extends RefCounted

const TradeContact := preload("res://scripts/trade_contact.gd")

const CONDITION_NAME := "STORM DAMAGE"
const START_VOYAGE := 0
const END_VOYAGE := 2
const DURATION_VOYAGES := END_VOYAGE - START_VOYAGE
const CONDITION_GOODS := [
	{
		"good_name": "TIMBER",
		"cargo_lot_name": "TIMBER LOT",
		"base_price_state": TradeContact.PriceState.NORMAL,
	},
	{
		"good_name": "FOOD",
		"cargo_lot_name": "VOYAGE FOOD LOT",
		"base_price_state": TradeContact.PriceState.CHEAP,
	},
	{
		"good_name": "MEDICINE",
		"cargo_lot_name": "COVE MEDICINE LOT",
		"base_price_state": TradeContact.PriceState.NORMAL,
	},
]

var _active := true
var _last_current_voyage := START_VOYAGE
var _update_count := 0
var _expiry_count := 0
var _expiry_voyage := -1
var _last_update_evidence: Dictionary = {}


func update_completed_voyage(completed_voyage: int) -> Dictionary:
	var active_before := _active
	_last_current_voyage = completed_voyage
	var expired_this_update := false
	if _active and completed_voyage >= END_VOYAGE:
		_active = false
		_expiry_count += 1
		_expiry_voyage = completed_voyage
		expired_this_update = true
	_update_count += 1
	_last_update_evidence = {
		"completed_voyage": completed_voyage,
		"active_before": active_before,
		"active_after": _active,
		"expired_this_update": expired_this_update,
		"expiry_count": _expiry_count,
		"expiry_voyage": _expiry_voyage,
		"expected_expiry_voyage": END_VOYAGE,
		"expired_at_expected_voyage": (
			not expired_this_update or completed_voyage == END_VOYAGE
		),
	}
	return _last_update_evidence.duplicate(true)


func get_market_goods() -> Array[Dictionary]:
	var goods: Array[Dictionary] = []
	for authored_good in CONDITION_GOODS:
		var base_state: int = int(authored_good["base_price_state"])
		var current_state: int = (
			TradeContact.PriceState.VALUABLE if _active else base_state
		)
		goods.append({
			"good_name": authored_good["good_name"],
			"cargo_lot_name": authored_good["cargo_lot_name"],
			"base_price_state": _get_price_state_name(base_state),
			"base_price_state_index": base_state,
			"base_fixed_price": int(TradeContact.FIXED_PRICES[base_state]),
			"current_price_state": _get_price_state_name(current_state),
			"current_price_state_index": current_state,
			"current_fixed_price": int(TradeContact.FIXED_PRICES[current_state]),
			"affected_while_active": true,
			"base_state_restored": current_state == base_state,
		})
	return goods


func get_playtest_state(current_voyage: int = START_VOYAGE) -> Dictionary:
	var goods := get_market_goods()
	var base_state_map := {}
	var current_state_map := {}
	var base_fixed_price_map := {}
	var current_fixed_price_map := {}
	var cargo_identity_map := {}
	var all_current_valuable := true
	var all_base_states_restored := true
	for good_state in goods:
		var good_name: String = good_state["good_name"]
		base_state_map[good_name] = good_state["base_price_state"]
		current_state_map[good_name] = good_state["current_price_state"]
		base_fixed_price_map[good_name] = good_state["base_fixed_price"]
		current_fixed_price_map[good_name] = good_state["current_fixed_price"]
		cargo_identity_map[good_name] = good_state["cargo_lot_name"]
		all_current_valuable = (
			all_current_valuable
			and good_state["current_price_state"] == "VALUABLE"
			and int(good_state["current_fixed_price"])
				== TradeContact.VALUABLE_PRICE
		)
		all_base_states_restored = (
			all_base_states_restored and bool(good_state["base_state_restored"])
		)
	var remaining_voyages := (
		maxi(0, END_VOYAGE - current_voyage) if _active else 0
	)
	return {
		"condition_count": 1,
		"active_condition_count": 1 if _active else 0,
		"name": CONDITION_NAME,
		"condition_name": CONDITION_NAME,
		"active": _active,
		"ended": not _active,
		"state": "ACTIVE" if _active else "ENDED",
		"start_voyage": START_VOYAGE,
		"end_voyage": END_VOYAGE,
		"current_voyage": current_voyage,
		"last_updated_voyage": _last_current_voyage,
		"remaining_voyages": remaining_voyages,
		"duration_voyages": DURATION_VOYAGES,
		"duration_is_exactly_two": DURATION_VOYAGES == 2,
		"affected_good_count": goods.size(),
		"affected_good_count_is_exactly_three": goods.size() == 3,
		"affected_goods": goods,
		"affected_good_names": ["TIMBER", "FOOD", "MEDICINE"],
		"affected_cargo_lot_names": [
			"TIMBER LOT",
			"VOYAGE FOOD LOT",
			"COVE MEDICINE LOT",
		],
		"cargo_identity_map": cargo_identity_map,
		"base_price_states": base_state_map,
		"current_price_states": current_state_map,
		"base_fixed_prices": base_fixed_price_map,
		"current_fixed_prices": current_fixed_price_map,
		"all_affected_goods_currently_valuable": all_current_valuable,
		"all_affected_goods_valuable_while_active": (
			not _active or all_current_valuable
		),
		"all_base_states_currently_restored": all_base_states_restored,
		"base_states_restored_after_expiry": (
			not _active and all_base_states_restored
		),
		"expiry_count": _expiry_count,
		"expiry_voyage": _expiry_voyage,
		"expected_expiry_voyage": END_VOYAGE,
		"expiry_timing_is_exact": (
			_expiry_count == 0 or _expiry_voyage == END_VOYAGE
		),
		"update_count": _update_count,
		"last_update_evidence": _last_update_evidence.duplicate(true),
	}


func _get_price_state_name(price_state: int) -> String:
	return String(TradeContact.PriceState.keys()[price_state])
