extends Resource
class_name TourStopData

@export_enum("asia", "north_america", "europe") var stop_type := "asia"
@export_range(0, 999999, 1) var target_hype := 0
@export_range(0, 99, 1) var reward_base := 0
@export var boss_id := ""
@export var modifier_id := ""
@export var parameters := {}


func setup(
	new_stop_type: String,
	new_target_hype: int,
	new_reward_base: int,
	new_boss_id: String = "",
	new_modifier_id: String = "",
	new_parameters: Dictionary = {}
) -> TourStopData:
	stop_type = new_stop_type
	target_hype = new_target_hype
	reward_base = new_reward_base
	boss_id = new_boss_id
	modifier_id = new_modifier_id
	parameters = new_parameters.duplicate(true)
	return self


func get_display_name() -> String:
	return Config.get_stop_display_name(stop_type)


func has_boss() -> bool:
	return not boss_id.strip_edges().is_empty()


func to_debug_dictionary() -> Dictionary:
	return {
		"stop_type": stop_type,
		"target_hype": target_hype,
		"reward_base": reward_base,
		"boss_id": boss_id,
		"modifier_id": modifier_id,
		"parameters": parameters.duplicate(true),
	}
