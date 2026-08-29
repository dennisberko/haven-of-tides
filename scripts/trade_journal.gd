class_name TradeJournalState
extends RefCounted

const PORT_MARKET_NAME := "PORT MARKET"
const UNKNOWN_STATUS := "UNKNOWN"
const FRESH_STATUS := "FRESH"
const OLD_STATUS := "OLD"
const LOCAL_MARKET_OPEN_SOURCE := "LOCAL_PORT_MARKET_OPEN"
const LOCAL_PURCHASE_SOURCE := "LOCAL_PORT_SUCCESSFUL_PURCHASE"
const RECORDED_GOOD_NAMES := [
	"TIMBER",
	"FOOD",
	"MEDICINE",
	"SPICE LOT",
]

var _entry: Dictionary = {}
var _record_count := 0
var _market_open_record_count := 0
var _purchase_refresh_count := 0
var _last_record_source := "NONE"
var _record_source_counts := {
	LOCAL_MARKET_OPEN_SOURCE: 0,
	LOCAL_PURCHASE_SOURCE: 0,
}


func record_local_port_market(
	goods: Array,
	spice_stock_mark: Dictionary,
	condition: Dictionary,
	seen_voyage: int,
	source: String,
) -> bool:
	if not _is_local_record_source(source):
		return false
	if not _has_exact_recorded_goods(goods):
		return false
	if String(spice_stock_mark.get("mark_kind", "")) != "STOCK":
		return false
	if String(condition.get("name", "")) != "STORM DAMAGE":
		return false

	_entry = {
		"port_name": PORT_MARKET_NAME,
		"seen_voyage": seen_voyage,
		"goods": goods.duplicate(true),
		"spice_stock_mark": spice_stock_mark.duplicate(true),
		"condition": condition.duplicate(true),
	}.duplicate(true)
	_record_count += 1
	_last_record_source = source
	_record_source_counts[source] = int(_record_source_counts[source]) + 1
	if source == LOCAL_MARKET_OPEN_SOURCE:
		_market_open_record_count += 1
	else:
		_purchase_refresh_count += 1
	return true


func is_known() -> bool:
	return not _entry.is_empty()


func get_entry_snapshot() -> Dictionary:
	return _entry.duplicate(true)


func get_seen_voyage() -> int:
	return int(_entry.get("seen_voyage", -1))


func get_age(current_voyage: int) -> int:
	if not is_known():
		return 0
	return maxi(0, current_voyage - get_seen_voyage())


func get_status(current_voyage: int) -> String:
	if not is_known():
		return UNKNOWN_STATUS
	return OLD_STATUS if current_voyage > get_seen_voyage() else FRESH_STATUS


func get_playtest_state(current_voyage: int) -> Dictionary:
	var raw_entry := get_entry_snapshot()
	return {
		"owner_count": 1,
		"port_entry_count": 1 if is_known() else 0,
		"known": is_known(),
		"unknown": not is_known(),
		"status": get_status(current_voyage),
		"fresh": get_status(current_voyage) == FRESH_STATUS,
		"old": get_status(current_voyage) == OLD_STATUS,
		"seen_voyage": get_seen_voyage(),
		"current_voyage": current_voyage,
		"age": get_age(current_voyage),
		"raw_entry": raw_entry,
		"goods": raw_entry.get("goods", []).duplicate(true),
		"good_names": RECORDED_GOOD_NAMES.duplicate(),
		"good_count": int(raw_entry.get("goods", []).size()),
		"spice_stock_mark": (
			(raw_entry.get("spice_stock_mark", {}) as Dictionary).duplicate(true)
		),
		"condition": (
			(raw_entry.get("condition", {}) as Dictionary).duplicate(true)
		),
		"record_count": _record_count,
		"market_open_record_count": _market_open_record_count,
		"purchase_refresh_count": _purchase_refresh_count,
		"last_record_source": _last_record_source,
		"record_source_counts": _record_source_counts.duplicate(true),
		"allowed_record_sources": [
			LOCAL_MARKET_OPEN_SOURCE,
			LOCAL_PURCHASE_SOURCE,
		],
	}


func _is_local_record_source(source: String) -> bool:
	return (
		source == LOCAL_MARKET_OPEN_SOURCE
		or source == LOCAL_PURCHASE_SOURCE
	)


func _has_exact_recorded_goods(goods: Array) -> bool:
	if goods.size() != RECORDED_GOOD_NAMES.size():
		return false
	for index in range(RECORDED_GOOD_NAMES.size()):
		var good = goods[index]
		if typeof(good) != TYPE_DICTIONARY:
			return false
		var good_state: Dictionary = good
		if (
			String(good_state.get("good_name", ""))
			!= RECORDED_GOOD_NAMES[index]
		):
			return false
	return true
