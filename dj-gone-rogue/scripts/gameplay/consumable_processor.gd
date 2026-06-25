extends Node
class_name GameplayConsumableProcessor


func use_consumable(consumable: ConsumableData, targets: Array) -> Dictionary:
	if consumable == null:
		return _result(false, "No consumable selected.")
	var cards := _as_cards(targets)
	if not _targets_valid(consumable, cards):
		return _result(false, _target_message(consumable))

	match consumable.effect_type:
		GameData.CONSUME_ENHANCE_CARD:
			cards[0].add_enhancement(str(consumable.parameters.get("enhancement", "")))
		GameData.CONSUME_DESTROY_SELECTED:
			var max_count := int(consumable.parameters.get("max", 2))
			for i in range(mini(max_count, cards.size())):
				DeckManager.remove_card_from_run(cards[i])
		GameData.CONSUME_TRANSFORM_TO_TEMPLATE:
			var template := cards[0]
			for i in range(1, cards.size()):
				cards[i].set_identity_from(template)
		GameData.CONSUME_DUPLICATE_CARD:
			DeckManager.duplicate_card_to_discard(cards[0])
		GameData.CONSUME_UPGRADE_HANDS:
			for hand_type in consumable.parameters.get("hand_types", []):
				RunState.hand_levels[hand_type] = int(RunState.hand_levels.get(hand_type, 1)) + 1
		_:
			return _result(false, "Unsupported consumable effect: %s" % consumable.effect_type)

	RunState.remove_consumable(consumable)
	RunState.clear_selected_cards()
	RunState.last_result_message = "Used %s." % consumable.display_name
	return _result(true, RunState.last_result_message)


func _targets_valid(consumable: ConsumableData, cards: Array[TrackCard]) -> bool:
	if consumable.target_rules.is_empty():
		return true
	var min_targets := int(consumable.target_rules.get("min", 0))
	var max_targets := int(consumable.target_rules.get("max", 99))
	return cards.size() >= min_targets and cards.size() <= max_targets


func _target_message(consumable: ConsumableData) -> String:
	var min_targets := int(consumable.target_rules.get("min", 0))
	var max_targets := int(consumable.target_rules.get("max", 99))
	if min_targets == max_targets:
		return "%s needs exactly %d selected Track(s)." % [consumable.display_name, min_targets]
	return "%s needs %d-%d selected Track(s)." % [consumable.display_name, min_targets, max_targets]


func _as_cards(values: Array) -> Array[TrackCard]:
	var cards: Array[TrackCard] = []
	for value in values:
		var card := value as TrackCard
		if card != null:
			cards.append(card)
	return cards


func _result(success: bool, message: String) -> Dictionary:
	return {"success": success, "message": message}
