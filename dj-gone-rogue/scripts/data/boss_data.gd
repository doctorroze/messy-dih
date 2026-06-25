extends Resource
class_name BossData

@export var id := ""
@export var country := ""
@export var venue_name := ""
@export var display_name := ""
@export_enum("medium", "hard") var difficulty := "medium"
@export_multiline var rule_text := ""
@export var effect_type := ""
@export var parameters := {}


func get_full_display_name() -> String:
	if country.is_empty() and venue_name.is_empty():
		return display_name
	if display_name.is_empty():
		return "%s / %s" % [country, venue_name]
	return "%s - %s / %s" % [display_name, country, venue_name]


func to_debug_dictionary() -> Dictionary:
	return {
		"id": id,
		"country": country,
		"venue_name": venue_name,
		"display_name": display_name,
		"difficulty": difficulty,
		"rule_text": rule_text,
		"effect_type": effect_type,
		"parameters": parameters.duplicate(true),
	}
