extends Resource
class_name GearData

@export var id := ""
@export var display_name := ""
@export_enum("common", "uncommon", "rare") var rarity := "common"
@export_range(0, 99, 1) var price := 0
@export_multiline var description := ""
@export var trigger_timing := ""
@export var effect_type := ""
@export var parameters := {}


func get_sell_value() -> int:
	return int(floor(price / 2.0))


func can_afford(current_money: int) -> bool:
	return current_money >= price


func to_debug_dictionary() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"rarity": rarity,
		"price": price,
		"description": description,
		"trigger_timing": trigger_timing,
		"effect_type": effect_type,
		"parameters": parameters.duplicate(true),
	}
