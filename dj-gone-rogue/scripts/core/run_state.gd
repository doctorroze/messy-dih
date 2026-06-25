extends Node
class_name RunStateManager

signal run_started(seed_string: String, album_deck_id: String)
signal stop_started(stop_snapshot: Dictionary)
signal money_changed(money: int)
signal inventories_changed()
signal piles_changed()
signal scoring_breakdown_changed(breakdown: Dictionary)
signal run_won()
signal run_lost(reason: String)

var current_leg := 1
var current_stop_index := 0
var current_stop_type := ""
var money := 0

var deck: Array[TrackCard] = []
var draw_pile: Array[TrackCard] = []
var discard_pile: Array[TrackCard] = []
var hand: Array[TrackCard] = []
var selected_cards: Array[TrackCard] = []

var gear_inventory: Array[GearData] = []
var consumables: Array[ConsumableData] = []
var hand_levels := {}
var current_boss: BossData

var hands_remaining := 0
var discards_remaining := 0
var target_hype := 0
var current_hype := 0
var previous_hand_types_this_stop: Array[String] = []
var last_scoring_breakdown := {}
var last_result_message := ""
var discards_used_this_stop := 0

var rng_seed_string := ""
var album_deck_id := ""
var run_flags := {}


func reset_run(seed_value: String = "", starter_album_deck_id: String = "") -> void:
	rng_seed_string = seed_value.strip_edges()
	if rng_seed_string.is_empty():
		rng_seed_string = Config.DEFAULT_SEED

	album_deck_id = starter_album_deck_id.strip_edges()
	if album_deck_id.is_empty():
		album_deck_id = Config.STARTER_ALBUM_DECK_ID

	current_leg = 1
	current_stop_index = 0
	current_stop_type = Config.STOP_ORDER[current_stop_index]
	money = Config.STARTING_MONEY
	deck.clear()
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	selected_cards.clear()
	gear_inventory.clear()
	consumables.clear()
	hand_levels = Config.get_starting_hand_levels()
	current_boss = null
	hands_remaining = Config.HANDS_PER_STOP
	discards_remaining = Config.DISCARDS_PER_STOP
	target_hype = Config.get_target_hype(current_leg, current_stop_type)
	current_hype = 0
	previous_hand_types_this_stop.clear()
	last_scoring_breakdown.clear()
	last_result_message = ""
	discards_used_this_stop = 0
	run_flags.clear()
	run_flags["next_card_number"] = 53

	RngManager.set_seed_from_string(rng_seed_string)
	run_started.emit(rng_seed_string, album_deck_id)
	money_changed.emit(money)
	inventories_changed.emit()
	piles_changed.emit()


func begin_stop(stop_type: String, boss_data: BossData = null) -> void:
	current_stop_type = stop_type
	current_boss = boss_data
	hands_remaining = Config.HANDS_PER_STOP
	discards_remaining = Config.DISCARDS_PER_STOP
	target_hype = Config.get_target_hype(current_leg, current_stop_type)
	current_hype = 0
	previous_hand_types_this_stop.clear()
	last_scoring_breakdown.clear()
	last_result_message = ""
	discards_used_this_stop = 0
	stop_started.emit(get_stop_snapshot())


func advance_stop_pointer() -> bool:
	current_stop_index += 1
	if current_stop_index >= Config.STOP_ORDER.size():
		current_stop_index = 0
		current_leg += 1
	return current_leg <= Config.TOUR_LEGS


func get_next_stop_type() -> String:
	if current_leg > Config.TOUR_LEGS:
		return ""
	return Config.STOP_ORDER[current_stop_index]


func add_money(amount: int) -> void:
	money = maxi(0, money + amount)
	money_changed.emit(money)


func spend_money(amount: int) -> bool:
	if amount < 0:
		return false
	if money < amount:
		return false
	money -= amount
	money_changed.emit(money)
	return true


func earn_stop_reward() -> int:
	var reward := Config.get_reward_base(current_stop_type) + hands_remaining
	var interest := mini(Config.INTEREST_CAP, int(floor(float(money) / Config.INTEREST_DIVISOR)))
	add_money(reward + interest)
	return reward + interest


func can_add_gear() -> bool:
	return gear_inventory.size() < Config.MAX_GEAR_SLOTS


func can_add_consumable() -> bool:
	return consumables.size() < Config.MAX_CONSUMABLE_SLOTS


func add_gear(gear_data: GearData) -> bool:
	if gear_data == null or not can_add_gear():
		return false
	gear_inventory.append(gear_data)
	inventories_changed.emit()
	return true


func remove_gear(gear_data: GearData) -> bool:
	var index := gear_inventory.find(gear_data)
	if index == -1:
		return false
	gear_inventory.remove_at(index)
	inventories_changed.emit()
	return true


func add_consumable(consumable_data: ConsumableData) -> bool:
	if consumable_data == null or not can_add_consumable():
		return false
	consumables.append(consumable_data)
	inventories_changed.emit()
	return true


func remove_consumable(consumable_data: ConsumableData) -> bool:
	var index := consumables.find(consumable_data)
	if index == -1:
		return false
	consumables.remove_at(index)
	inventories_changed.emit()
	return true


func clear_selected_cards() -> void:
	selected_cards.clear()
	piles_changed.emit()


func notify_piles_changed() -> void:
	piles_changed.emit()


func set_last_scoring_breakdown(breakdown: Dictionary) -> void:
	last_scoring_breakdown = breakdown.duplicate(true)
	scoring_breakdown_changed.emit(last_scoring_breakdown)


func mark_run_won() -> void:
	run_won.emit()


func mark_run_lost(reason: String) -> void:
	run_lost.emit(reason)


func get_next_card_number() -> int:
	var next_number := int(run_flags.get("next_card_number", 53))
	run_flags["next_card_number"] = next_number + 1
	return next_number


func get_stop_snapshot() -> Dictionary:
	return {
		"current_leg": current_leg,
		"current_stop_index": current_stop_index,
		"current_stop_type": current_stop_type,
		"stop_display_name": Config.get_stop_display_name(current_stop_type),
		"money": money,
		"hands_remaining": hands_remaining,
		"discards_remaining": discards_remaining,
		"target_hype": target_hype,
		"current_hype": current_hype,
		"last_result_message": last_result_message,
		"boss_id": current_boss.id if current_boss != null else "",
		"rng_seed_string": rng_seed_string,
	}


func get_run_snapshot() -> Dictionary:
	return {
		"current_leg": current_leg,
		"current_stop_index": current_stop_index,
		"current_stop_type": current_stop_type,
		"money": money,
		"deck_size": deck.size(),
		"draw_pile_size": draw_pile.size(),
		"discard_pile_size": discard_pile.size(),
		"hand_size": hand.size(),
		"selected_count": selected_cards.size(),
		"gear_count": gear_inventory.size(),
		"consumable_count": consumables.size(),
		"hand_levels": hand_levels.duplicate(true),
		"current_boss": current_boss.id if current_boss != null else "",
		"hands_remaining": hands_remaining,
		"discards_remaining": discards_remaining,
		"target_hype": target_hype,
		"current_hype": current_hype,
		"last_result_message": last_result_message,
		"discards_used_this_stop": discards_used_this_stop,
		"previous_hand_types_this_stop": previous_hand_types_this_stop.duplicate(),
		"last_scoring_breakdown": last_scoring_breakdown.duplicate(true),
		"rng_seed_string": rng_seed_string,
		"album_deck_id": album_deck_id,
		"run_flags": run_flags.duplicate(true),
	}
