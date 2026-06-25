extends Node
class_name GameplayHandEvaluator


func evaluate(cards: Array) -> Dictionary:
	var selected := _as_cards(cards)
	var rank_groups := _rank_groups(selected)
	var sorted_counts := _sorted_group_counts(rank_groups)
	var flush := _is_flush(selected)
	var straight := _is_straight(selected)
	var hand_type := Config.HAND_SOLO_DROP
	var scoring_cards: Array[TrackCard] = []

	if selected.size() >= 5 and _has_group_count(sorted_counts, 5) and flush:
		hand_type = Config.HAND_DIAMOND_RECORD
		scoring_cards = selected.duplicate()
	elif selected.size() >= 5 and _is_full_house_counts(sorted_counts) and flush:
		hand_type = Config.HAND_PLATINUM_SET
		scoring_cards = selected.duplicate()
	elif selected.size() >= 5 and _has_group_count(sorted_counts, 5):
		hand_type = Config.HAND_ANTHEM
		scoring_cards = _cards_from_largest_groups(rank_groups, [5])
	elif selected.size() >= 5 and straight and flush:
		hand_type = Config.HAND_PERFECT_TRANSITION
		scoring_cards = selected.duplicate()
	elif _has_group_count(sorted_counts, 4):
		hand_type = Config.HAND_WALL_OF_SOUND
		scoring_cards = _cards_from_largest_groups(rank_groups, [4])
	elif selected.size() >= 5 and _is_full_house_counts(sorted_counts):
		hand_type = Config.HAND_HEADLINE_SET
		scoring_cards = _cards_for_full_house(rank_groups)
	elif selected.size() >= 5 and flush:
		hand_type = Config.HAND_COLOR_MIX
		scoring_cards = selected.duplicate()
	elif selected.size() >= 5 and straight:
		hand_type = Config.HAND_CROSSFADE
		scoring_cards = selected.duplicate()
	elif _has_group_count(sorted_counts, 3):
		hand_type = Config.HAND_TRIPLE_THREAT
		scoring_cards = _cards_from_largest_groups(rank_groups, [3])
	elif _pair_count(sorted_counts) >= 2:
		hand_type = Config.HAND_MASHUP
		scoring_cards = _cards_for_two_pair(rank_groups)
	elif _pair_count(sorted_counts) >= 1:
		hand_type = Config.HAND_DOUBLE_BEAT
		scoring_cards = _cards_from_largest_groups(rank_groups, [2])
	else:
		scoring_cards = [_highest_card(selected)] if not selected.is_empty() else []

	return {
		"hand_type": hand_type,
		"display_name": Config.get_hand_display_name(hand_type),
		"scoring_cards": scoring_cards,
		"selected_cards": selected,
		"is_flush": flush,
		"is_straight": straight,
		"rank_counts": _rank_count_dictionary(rank_groups),
	}


func is_ordered_by_rank(cards: Array) -> bool:
	var selected := _as_cards(cards)
	if selected.size() <= 1:
		return true
	var ascending := true
	var descending := true
	for i in range(1, selected.size()):
		if selected[i - 1].rank > selected[i].rank:
			ascending = false
		if selected[i - 1].rank < selected[i].rank:
			descending = false
	return ascending or descending


func uses_only_one_natural_suit(cards: Array) -> bool:
	var selected := _as_cards(cards)
	if selected.is_empty():
		return false
	var suit := selected[0].suit
	for card in selected:
		if card.suit != suit:
			return false
	return true


func run_debug_tests() -> void:
	var tests := {
		"Solo Drop": [_card(2, Config.SUIT_HEARTS)],
		"Double Beat": [_card(7, Config.SUIT_HEARTS), _card(7, Config.SUIT_SPADES)],
		"Mashup": [_card(4, Config.SUIT_HEARTS), _card(4, Config.SUIT_SPADES), _card(9, Config.SUIT_CLUBS), _card(9, Config.SUIT_DIAMONDS)],
		"Triple Threat": [_card(5, Config.SUIT_HEARTS), _card(5, Config.SUIT_SPADES), _card(5, Config.SUIT_CLUBS)],
		"Crossfade": [_card(2, Config.SUIT_HEARTS), _card(3, Config.SUIT_SPADES), _card(4, Config.SUIT_CLUBS), _card(5, Config.SUIT_DIAMONDS), _card(6, Config.SUIT_HEARTS)],
		"Color Mix": [_card(2, Config.SUIT_HEARTS), _card(5, Config.SUIT_HEARTS), _card(8, Config.SUIT_HEARTS), _card(11, Config.SUIT_HEARTS), _card(13, Config.SUIT_HEARTS)],
		"Headline Set": [_card(3, Config.SUIT_HEARTS), _card(3, Config.SUIT_SPADES), _card(3, Config.SUIT_CLUBS), _card(8, Config.SUIT_HEARTS), _card(8, Config.SUIT_DIAMONDS)],
		"Wall of Sound": [_card(10, Config.SUIT_HEARTS), _card(10, Config.SUIT_SPADES), _card(10, Config.SUIT_CLUBS), _card(10, Config.SUIT_DIAMONDS)],
		"Perfect Transition": [_card(4, Config.SUIT_CLUBS), _card(5, Config.SUIT_CLUBS), _card(6, Config.SUIT_CLUBS), _card(7, Config.SUIT_CLUBS), _card(8, Config.SUIT_CLUBS)],
		"Anthem": [_card(12, Config.SUIT_HEARTS), _card(12, Config.SUIT_SPADES), _card(12, Config.SUIT_CLUBS), _card(12, Config.SUIT_DIAMONDS), _card(12, Config.SUIT_HEARTS)],
		"Platinum Set": [_card(6, Config.SUIT_HEARTS), _card(6, Config.SUIT_HEARTS), _card(6, Config.SUIT_HEARTS), _card(9, Config.SUIT_HEARTS), _card(9, Config.SUIT_HEARTS)],
		"Diamond Record": [_card(1, Config.SUIT_SPADES), _card(1, Config.SUIT_SPADES), _card(1, Config.SUIT_SPADES), _card(1, Config.SUIT_SPADES), _card(1, Config.SUIT_SPADES)],
	}
	for label in tests.keys():
		var result := evaluate(tests[label])
		print("%s => %s" % [label, result["display_name"]])


func _as_cards(values: Array) -> Array[TrackCard]:
	var cards: Array[TrackCard] = []
	for value in values:
		var card := value as TrackCard
		if card != null:
			cards.append(card)
	return cards


func _rank_groups(cards: Array[TrackCard]) -> Dictionary:
	var groups := {}
	for card in cards:
		if not groups.has(card.rank):
			groups[card.rank] = []
		groups[card.rank].append(card)
	return groups


func _rank_count_dictionary(groups: Dictionary) -> Dictionary:
	var counts := {}
	for rank in groups.keys():
		counts[rank] = groups[rank].size()
	return counts


func _sorted_group_counts(groups: Dictionary) -> Array[int]:
	var counts: Array[int] = []
	for rank in groups.keys():
		counts.append(groups[rank].size())
	counts.sort()
	counts.reverse()
	return counts


func _has_group_count(counts: Array[int], size: int) -> bool:
	for count in counts:
		if count >= size:
			return true
	return false


func _pair_count(counts: Array[int]) -> int:
	var pairs := 0
	for count in counts:
		if count >= 2:
			pairs += 1
	return pairs


func _is_full_house_counts(counts: Array[int]) -> bool:
	var has_three := false
	var has_pair := false
	for count in counts:
		if count >= 3 and not has_three:
			has_three = true
		elif count >= 2:
			has_pair = true
	return has_three and has_pair


func _is_flush(cards: Array[TrackCard]) -> bool:
	if cards.size() < 5:
		return false
	var natural_suits := []
	for card in cards:
		if card.has_enhancement("autotune"):
			continue
		if not natural_suits.has(card.suit):
			natural_suits.append(card.suit)
	return natural_suits.size() <= 1


func _is_straight(cards: Array[TrackCard]) -> bool:
	if cards.size() < 5:
		return false
	var values := []
	for card in cards:
		var high_value := _rank_high_value(card.rank)
		if not values.has(high_value):
			values.append(high_value)
		if card.rank == 1 and not values.has(1):
			values.append(1)
	values.sort()
	if values.size() < 5:
		return false
	for start in range(0, values.size() - 4):
		var ok := true
		for offset in range(1, 5):
			if values[start + offset] != values[start] + offset:
				ok = false
				break
		if ok:
			return true
	return false


func _cards_from_largest_groups(groups: Dictionary, desired_counts: Array[int]) -> Array[TrackCard]:
	var result: Array[TrackCard] = []
	var ranks := groups.keys()
	ranks.sort_custom(func(a, b): return _rank_high_value(a) > _rank_high_value(b))
	for desired_count in desired_counts:
		for rank in ranks:
			var group: Array = groups[rank]
			if group.size() >= desired_count:
				for value in group:
					var card := value as TrackCard
					if card != null and not result.has(card):
						result.append(card)
				break
	return result


func _cards_for_two_pair(groups: Dictionary) -> Array[TrackCard]:
	var result: Array[TrackCard] = []
	var ranks := groups.keys()
	ranks.sort_custom(func(a, b): return _rank_high_value(a) > _rank_high_value(b))
	var found := 0
	for rank in ranks:
		var group: Array = groups[rank]
		if group.size() >= 2:
			var first := group[0] as TrackCard
			var second := group[1] as TrackCard
			if first != null:
				result.append(first)
			if second != null:
				result.append(second)
			found += 1
			if found == 2:
				break
	return result


func _cards_for_full_house(groups: Dictionary) -> Array[TrackCard]:
	var result: Array[TrackCard] = []
	var ranks := groups.keys()
	ranks.sort_custom(func(a, b): return _rank_high_value(a) > _rank_high_value(b))
	var trip_rank = null
	for rank in ranks:
		if groups[rank].size() >= 3:
			trip_rank = rank
			for value in groups[rank]:
				var card := value as TrackCard
				if card != null:
					result.append(card)
			break
	for rank in ranks:
		if rank == trip_rank:
			continue
		if groups[rank].size() >= 2:
			var first := groups[rank][0] as TrackCard
			var second := groups[rank][1] as TrackCard
			if first != null:
				result.append(first)
			if second != null:
				result.append(second)
			break
	return result


func _highest_card(cards: Array[TrackCard]) -> TrackCard:
	var best: TrackCard = null
	for card in cards:
		if best == null or _rank_high_value(card.rank) > _rank_high_value(best.rank):
			best = card
	return best


func _rank_high_value(rank: int) -> int:
	return 14 if rank == 1 else rank


func _card(rank: int, suit: String) -> TrackCard:
	return TrackCard.new().setup("test_%s_%d" % [suit, rank], rank, suit, "test_album", "Test %d" % rank)
