extends Node
class_name GameplayShopGenerator

signal shop_changed()

var offers := []
var reroll_count := 0


func generate_shop() -> Array:
	offers.clear()
	reroll_count = 0
	_roll_offers()
	emit_signal("shop_changed")
	return offers


func reroll_shop() -> Dictionary:
	var cost := Config.REROLL_BASE_COST + (reroll_count * Config.REROLL_INCREMENT)
	if not RunState.spend_money(cost):
		return {"success": false, "message": "Not enough money to reroll."}
	reroll_count += 1
	_roll_offers()
	emit_signal("shop_changed")
	return {"success": true, "message": "Rerolled Backstage for $%d." % cost}


func buy_offer(index: int) -> Dictionary:
	if index < 0 or index >= offers.size():
		return {"success": false, "message": "Invalid shop slot."}
	var offer: Dictionary = offers[index]
	if offer.get("sold", false):
		return {"success": false, "message": "That slot is sold out."}
	var item = offer["item"]
	var price := int(offer["price"])
	if not RunState.spend_money(price):
		return {"success": false, "message": "Not enough money."}

	var added := false
	if offer["type"] == "gear":
		added = RunState.add_gear(item)
	else:
		added = RunState.add_consumable(item)

	if not added:
		RunState.add_money(price)
		return {"success": false, "message": "No room for %s." % offer["type"]}

	offer["sold"] = true
	RunState.last_result_message = "Bought %s for $%d." % [item.display_name, price]
	emit_signal("shop_changed")
	return {"success": true, "message": RunState.last_result_message}


func sell_gear(index: int) -> Dictionary:
	if index < 0 or index >= RunState.gear_inventory.size():
		return {"success": false, "message": "Invalid Gear slot."}
	var gear := RunState.gear_inventory[index]
	var value := gear.get_sell_value()
	RunState.remove_gear(gear)
	RunState.add_money(value)
	RunState.last_result_message = "Sold %s for $%d." % [gear.display_name, value]
	emit_signal("shop_changed")
	return {"success": true, "message": RunState.last_result_message}


func get_reroll_cost() -> int:
	return Config.REROLL_BASE_COST + (reroll_count * Config.REROLL_INCREMENT)


func _roll_offers() -> void:
	offers.clear()
	for i in range(2):
		var gear := _roll_gear()
		offers.append({"type": "gear", "item": gear, "price": gear.price, "sold": false})
	for i in range(2):
		var consumable := GameData.get_random_consumable()
		offers.append({"type": "consumable", "item": consumable, "price": consumable.price, "sold": false})


func _roll_gear() -> GearData:
	var roll := RngManager.rand_float()
	var rarity := "common"
	if roll > 0.92:
		rarity = "rare"
	elif roll > 0.68:
		rarity = "uncommon"
	var pool := GameData.get_gear_pool_by_rarity(rarity)
	if pool.is_empty():
		pool = GameData.get_gear_pool()
	return RngManager.choice(pool) as GearData
