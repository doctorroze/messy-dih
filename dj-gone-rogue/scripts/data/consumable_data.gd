extends Resource
class_name ConsumableData

@export var id := ""
@export var display_name := ""
@export_enum("studio", "chart") var category := "studio"
@export_range(0, 99, 1) var price := 0
@export_multiline var description := ""
@export var target_rules := {}
@export var effect_type := ""
@export var parameters := {}


func get_sell_value() -> int:
	return int(floor(price / 2.0))


func requires_target() -> bool:
	return not target_rules.is_empty()


func is_chart_card() -> bool:
	return category == "chart"


func is_studio_card() -> bool:
	return category == "studio"


func to_debug_dictionary() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"category": category,
		"price": price,
		"description": description,
		"target_rules": target_rules.duplicate(true),
		"effect_type": effect_type,
		"parameters": parameters.duplicate(true),
	}
