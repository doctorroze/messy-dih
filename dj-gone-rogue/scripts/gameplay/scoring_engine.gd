extends Node
class_name GameplayScoringEngine


func score_cards(cards: Array) -> Dictionary:
	var evaluation := HandEvaluator.evaluate(cards)
	var hand_type: String = evaluation["hand_type"]
	var scoring_cards: Array = evaluation["scoring_cards"]
	var selected_cards: Array = evaluation["selected_cards"]
	var level := _get_effective_hand_level(hand_type)
	var base_values := Config.get_hand_level_values(hand_type, level)
	var groove := float(base_values["groove"])
	var heat := float(base_values["heat"])
	var heat_multiplier := 1.0
	var final_multiplier := 1.0
	var lines := []
	var gear_lines := []
	var boss_lines := []
	var card_lines := []
	var ghost_active := _has_gear_effect(GameData.EFFECT_GHOST_PRODUCER)
	var enhancements_enabled := not _boss_effect_is(GameData.BOSS_DISABLE_ENHANCEMENTS)

	lines.append("%s level %d: +%d Groove, +%d Heat" % [evaluation["display_name"], level, base_values["groove"], base_values["heat"]])

	for card in scoring_cards:
		var contribution := _score_card_groove(card, enhancements_enabled)
		groove += contribution["groove"]
		heat *= contribution["heat_multiplier"]
		card_lines.append_array(contribution["lines"])

	for gear in RunState.gear_inventory:
		var effect := _apply_gear(gear, hand_type, scoring_cards, selected_cards, ghost_active)
		groove += effect["groove"]
		heat += effect["heat"]
		heat_multiplier *= effect["heat_multiplier"]
		if effect["line"] != "":
			gear_lines.append(effect["line"])

	heat *= heat_multiplier

	var boss_effect := _apply_boss_effects(hand_type, selected_cards, final_multiplier)
	final_multiplier = boss_effect["final_multiplier"]
	boss_lines.append_array(boss_effect["lines"])

	var final_hype := int(round(groove * heat * final_multiplier))
	final_hype = maxi(0, final_hype)

	var breakdown := {
		"hand_type": hand_type,
		"hand_display_name": evaluation["display_name"],
		"hand_level": level,
		"base_groove": base_values["groove"],
		"base_heat": base_values["heat"],
		"groove": groove,
		"heat": heat,
		"heat_multiplier": heat_multiplier,
		"final_multiplier": final_multiplier,
		"final_hype": final_hype,
		"scoring_cards": _card_labels(scoring_cards),
		"selected_cards": _card_labels(selected_cards),
		"lines": lines,
		"card_lines": card_lines,
		"gear_lines": gear_lines,
		"boss_lines": boss_lines,
	}
	RunState.set_last_scoring_breakdown(breakdown)
	_print_breakdown(breakdown)
	return breakdown


func after_hand_scored(hand_type: String) -> void:
	if hand_type == Config.HAND_DOUBLE_BEAT:
		RunState.run_flags["double_beat_streak"] = int(RunState.run_flags.get("double_beat_streak", 0)) + 1
	else:
		RunState.run_flags["double_beat_streak"] = 0


func _score_card_groove(card: TrackCard, enhancements_enabled: bool, retrigger_label: String = "") -> Dictionary:
	var groove := float(card.get_rank_groove_value())
	var heat_multiplier := 1.0
	var lines: Array[String] = []
	var prefix := retrigger_label
	if prefix != "":
		prefix += " "
	lines.append("%s%s: +%d Groove" % [prefix, card.display_track_name, card.get_rank_groove_value()])

	if enhancements_enabled:
		if card.has_enhancement("bass_boost"):
			groove += 30
			lines.append("%sBass Boost: +30 Groove" % prefix)
		if card.has_enhancement("remaster"):
			heat_multiplier *= 1.5
			lines.append("%sRemaster: x1.5 Heat" % prefix)
		if card.has_enhancement("reverb") and retrigger_label == "":
			var retrigger := _score_card_groove(card, false, "Reverb")
			groove += retrigger["groove"]
			lines.append_array(retrigger["lines"])

	return {
		"groove": groove,
		"heat_multiplier": heat_multiplier,
		"lines": lines,
	}


func _apply_gear(gear: GearData, hand_type: String, scoring_cards: Array, selected_cards: Array, ghost_active: bool) -> Dictionary:
	var groove := 0.0
	var heat := 0.0
	var heat_multiplier := 1.0
	var line := ""

	match gear.effect_type:
		GameData.EFFECT_FLAT_GROOVE:
			if not ghost_active:
				groove += float(gear.parameters.get("groove", 0))
				line = "%s: +%d Groove" % [gear.display_name, gear.parameters.get("groove", 0)]
		GameData.EFFECT_FLAT_HEAT:
			heat += float(gear.parameters.get("heat", 0))
			line = "%s: +%d Heat" % [gear.display_name, gear.parameters.get("heat", 0)]
		GameData.EFFECT_PER_RANK_GROOVE:
			var count := _count_scoring_rank(scoring_cards, int(gear.parameters.get("rank", 0)))
			if count > 0:
				groove += float(count * int(gear.parameters.get("groove", 0)))
				line = "%s: +%d Groove" % [gear.display_name, int(groove)]
		GameData.EFFECT_HAND_TYPE_HEAT:
			if hand_type == gear.parameters.get("hand_type", ""):
				heat += float(gear.parameters.get("heat", 0))
				line = "%s: +%d Heat" % [gear.display_name, gear.parameters.get("heat", 0)]
		GameData.EFFECT_DECAYING_HEAT_BY_LEG:
			var value := maxi(0, int(gear.parameters.get("base_heat", 0)) - ((RunState.current_leg - 1) * int(gear.parameters.get("loss_per_leg", 0))))
			if value > 0:
				heat += value
				line = "%s: +%d Heat" % [gear.display_name, value]
		GameData.EFFECT_DECK_SIZE_GROOVE:
			var value := RunState.deck.size() * int(gear.parameters.get("groove_per_card", 0))
			groove += value
			line = "%s: +%d Groove" % [gear.display_name, value]
		GameData.EFFECT_EXACT_CARD_COUNT_HEAT:
			if selected_cards.size() == int(gear.parameters.get("card_count", 0)):
				heat += float(gear.parameters.get("heat", 0))
				line = "%s: +%d Heat" % [gear.display_name, gear.parameters.get("heat", 0)]
		GameData.EFFECT_PER_SUIT_HEAT:
			var count := _count_scoring_suit(scoring_cards, str(gear.parameters.get("suit", "")))
			if count > 0:
				heat += float(count * int(gear.parameters.get("heat", 0)))
				line = "%s: +%d Heat" % [gear.display_name, int(heat)]
		GameData.EFFECT_LAST_DISCARD_HEAT:
			if RunState.discards_remaining == 0:
				heat += float(gear.parameters.get("heat", 0))
				line = "%s: +%d Heat" % [gear.display_name, gear.parameters.get("heat", 0)]
		GameData.EFFECT_FACE_RANK_HEAT:
			var ranks: Array = gear.parameters.get("ranks", [])
			var count := 0
			for card in scoring_cards:
				if ranks.has(card.rank):
					count += 1
			if count > 0:
				heat += count * int(gear.parameters.get("heat", 0))
				line = "%s: +%d Heat" % [gear.display_name, int(heat)]
		GameData.EFFECT_HAND_TYPE_HEAT_MULTIPLIER:
			if hand_type == gear.parameters.get("hand_type", ""):
				heat_multiplier *= float(gear.parameters.get("heat_multiplier", 1.0))
				line = "%s: x%s Heat" % [gear.display_name, str(gear.parameters.get("heat_multiplier", 1.0))]
		GameData.EFFECT_DOUBLE_BEAT_STREAK_HEAT:
			var streak := int(RunState.run_flags.get("double_beat_streak", 0))
			if streak > 0:
				var value := streak * int(gear.parameters.get("heat_per_streak", 0))
				heat += value
				line = "%s: +%d Heat" % [gear.display_name, value]
		GameData.EFFECT_GHOST_PRODUCER:
			heat_multiplier *= float(gear.parameters.get("heat_multiplier", 1.0))
			line = "%s: x%s Heat, flat +Groove Gear disabled" % [gear.display_name, str(gear.parameters.get("heat_multiplier", 1.0))]
		GameData.EFFECT_RETRIGGER_FIRST_CARD:
			if not scoring_cards.is_empty():
				var times := mini(int(gear.parameters.get("times", 0)), Config.MAX_RETRIGGER_LOOPS)
				for i in range(times):
					var retrigger := _score_card_groove(scoring_cards[0], not _boss_effect_is(GameData.BOSS_DISABLE_ENHANCEMENTS), "%s %d" % [gear.display_name, i + 1])
					groove += retrigger["groove"]
				line = "%s: retriggered %s %d times" % [gear.display_name, scoring_cards[0].display_track_name, times]

	return {
		"groove": groove,
		"heat": heat,
		"heat_multiplier": heat_multiplier,
		"line": line,
	}


func _apply_boss_effects(hand_type: String, selected_cards: Array, start_multiplier: float) -> Dictionary:
	var final_multiplier := start_multiplier
	var lines: Array[String] = []
	var boss := RunState.current_boss
	if boss == null:
		return {"final_multiplier": final_multiplier, "lines": lines}

	match boss.effect_type:
		GameData.BOSS_NO_REPEAT_HAND:
			if RunState.previous_hand_types_this_stop.has(hand_type):
				final_multiplier = 0.0
				lines.append("%s: repeated hand type scores 0" % boss.display_name)
		GameData.BOSS_ORDERED_RANKS:
			if not HandEvaluator.is_ordered_by_rank(selected_cards):
				final_multiplier *= float(boss.parameters.get("multiplier", 0.5))
				lines.append("%s: rank order broken, -50%% Crowd Hype" % boss.display_name)
		GameData.BOSS_FIRST_HAND_ZERO:
			if RunState.previous_hand_types_this_stop.is_empty():
				final_multiplier = 0.0
				lines.append("%s: first hand scores 0" % boss.display_name)
		GameData.BOSS_ONE_SUIT_PENALTY:
			if HandEvaluator.uses_only_one_natural_suit(selected_cards):
				final_multiplier *= float(boss.parameters.get("multiplier", 0.6))
				lines.append("%s: one-suit hand, -40%% Crowd Hype" % boss.display_name)

	return {"final_multiplier": final_multiplier, "lines": lines}


func _get_effective_hand_level(hand_type: String) -> int:
	var level := int(RunState.hand_levels.get(hand_type, 1))
	if _boss_effect_is(GameData.BOSS_HIGHEST_LEVEL_TO_ONE):
		var highest := 1
		for value in RunState.hand_levels.values():
			highest = maxi(highest, int(value))
		if level == highest and highest > 1:
			return 1
	return level


func _boss_effect_is(effect_type: String) -> bool:
	return RunState.current_boss != null and RunState.current_boss.effect_type == effect_type


func _has_gear_effect(effect_type: String) -> bool:
	for gear in RunState.gear_inventory:
		if gear.effect_type == effect_type:
			return true
	return false


func _count_scoring_rank(cards: Array, rank: int) -> int:
	var count := 0
	for card in cards:
		if card.rank == rank:
			count += 1
	return count


func _count_scoring_suit(cards: Array, suit: String) -> int:
	var count := 0
	for card in cards:
		if card.suit == suit:
			count += 1
	return count


func _card_labels(cards: Array) -> PackedStringArray:
	var labels := PackedStringArray()
	for value in cards:
		var card := value as TrackCard
		if card != null:
			labels.append(card.get_display_label())
	return labels


func _print_breakdown(breakdown: Dictionary) -> void:
	print("%s => Groove %.1f x Heat %.1f x Final %.2f = %d Crowd Hype" % [
		breakdown["hand_display_name"],
		breakdown["groove"],
		breakdown["heat"],
		breakdown["final_multiplier"],
		breakdown["final_hype"],
	])
