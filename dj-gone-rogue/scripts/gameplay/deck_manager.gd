extends Node
class_name GameplayDeckManager

signal album_deck_loaded(album_deck: AlbumDeckData)
signal deck_built(deck_size: int)
signal card_drawn(card: TrackCard)
signal cards_discarded(cards: Array)
signal draw_pile_shuffled(draw_pile_size: int)

const ALBUM_DECK_PATHS := {
	"basic_mixtape": "res://data/album_decks/basic_mixtape.tres",
}

var current_album_deck: AlbumDeckData


func start_new_run(seed_string: String = "", album_deck_id: String = "") -> bool:
	RunState.reset_run(seed_string, album_deck_id)
	if not build_run_deck(RunState.album_deck_id):
		return false
	shuffle_draw_pile()
	draw_to_hand_size()
	return true


func load_album_deck(album_deck_id: String) -> AlbumDeckData:
	var safe_album_id := album_deck_id.strip_edges()
	if safe_album_id.is_empty():
		safe_album_id = Config.STARTER_ALBUM_DECK_ID

	var path: String = ALBUM_DECK_PATHS.get(safe_album_id, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		push_error("Album deck not found: %s" % safe_album_id)
		return null

	var loaded := ResourceLoader.load(path) as AlbumDeckData
	if loaded == null:
		push_error("Album deck resource could not be loaded: %s" % path)
		return null

	var issues := loaded.validate()
	for issue in issues:
		push_warning("%s: %s" % [loaded.id, issue])

	current_album_deck = loaded
	emit_signal("album_deck_loaded", loaded)
	return loaded


func build_run_deck(album_deck_id: String) -> bool:
	var album_deck := load_album_deck(album_deck_id)
	if album_deck == null:
		return false

	var built_cards := create_album_deck_cards(album_deck)
	RunState.deck.clear()
	RunState.draw_pile.clear()
	RunState.discard_pile.clear()
	RunState.hand.clear()
	RunState.selected_cards.clear()
	RunState.deck.append_array(built_cards)
	RunState.draw_pile.append_array(built_cards)
	RunState.notify_piles_changed()
	emit_signal("deck_built", RunState.deck.size())
	return true


func create_album_deck_cards(album_deck: AlbumDeckData) -> Array[TrackCard]:
	var cards: Array[TrackCard] = []
	var copy_number := 0
	for suit in Config.SUITS:
		for rank in Config.RANKS:
			copy_number += 1
			var card_id := "%s_%s_%02d_%02d" % [album_deck.id, suit, rank, copy_number]
			var card := TrackCard.new().setup(
				card_id,
				rank,
				suit,
				album_deck.id,
				album_deck.get_track_name(rank),
				album_deck.get_suit_subtitle(suit)
			)
			cards.append(card)
	return cards


func shuffle_draw_pile() -> void:
	RngManager.shuffle_array_in_place(RunState.draw_pile)
	RunState.notify_piles_changed()
	emit_signal("draw_pile_shuffled", RunState.draw_pile.size())


func draw_to_hand_size(target_size: int = -1) -> Array[TrackCard]:
	if target_size < 0:
		target_size = Config.HAND_SIZE
	var drawn_cards: Array[TrackCard] = []
	while RunState.hand.size() < target_size:
		var card := draw_card()
		if card == null:
			break
		drawn_cards.append(card)
	return drawn_cards


func draw_card() -> TrackCard:
	if RunState.draw_pile.is_empty():
		recycle_discard_into_draw_pile()
	if RunState.draw_pile.is_empty():
		return null

	var card := RunState.draw_pile.pop_back() as TrackCard
	RunState.hand.append(card)
	RunState.notify_piles_changed()
	emit_signal("card_drawn", card)
	return card


func discard_selected_cards() -> Array[TrackCard]:
	return discard_cards(RunState.selected_cards.duplicate())


func discard_cards(cards: Array) -> Array[TrackCard]:
	var discarded: Array[TrackCard] = []
	for value in cards:
		var card := value as TrackCard
		if card == null:
			continue
		var hand_index := RunState.hand.find(card)
		if hand_index == -1:
			continue
		RunState.hand.remove_at(hand_index)
		RunState.discard_pile.append(card)
		var selected_index := RunState.selected_cards.find(card)
		if selected_index != -1:
			RunState.selected_cards.remove_at(selected_index)
		discarded.append(card)

	if not discarded.is_empty():
		RunState.notify_piles_changed()
		emit_signal("cards_discarded", discarded)
	return discarded


func toggle_card_selection(card: TrackCard, max_selected: int = 5) -> bool:
	if card == null:
		return false
	var index := RunState.selected_cards.find(card)
	if index != -1:
		RunState.selected_cards.remove_at(index)
		RunState.notify_piles_changed()
		return true
	if RunState.selected_cards.size() >= max_selected:
		return false
	RunState.selected_cards.append(card)
	RunState.notify_piles_changed()
	return true


func duplicate_card_to_discard(card: TrackCard) -> TrackCard:
	if card == null:
		return null
	var duplicate_id := "%s_copy_%03d" % [card.unique_id, RunState.get_next_card_number()]
	var copy := card.duplicate_card(duplicate_id)
	RunState.deck.append(copy)
	RunState.discard_pile.append(copy)
	RunState.notify_piles_changed()
	return copy


func remove_card_from_run(card: TrackCard) -> bool:
	if card == null:
		return false
	var removed := false
	for pile in [RunState.deck, RunState.draw_pile, RunState.discard_pile, RunState.hand, RunState.selected_cards]:
		var index := pile.find(card)
		while index != -1:
			pile.remove_at(index)
			removed = true
			index = pile.find(card)
	if removed:
		RunState.notify_piles_changed()
	return removed


func recycle_discard_into_draw_pile() -> void:
	if RunState.discard_pile.is_empty():
		return
	RunState.draw_pile.append_array(RunState.discard_pile)
	RunState.discard_pile.clear()
	shuffle_draw_pile()


func reset_draw_pile_from_deck(shuffle: bool = true) -> void:
	RunState.draw_pile.clear()
	RunState.discard_pile.clear()
	RunState.hand.clear()
	RunState.selected_cards.clear()
	RunState.draw_pile.append_array(RunState.deck)
	if shuffle:
		shuffle_draw_pile()
	else:
		RunState.notify_piles_changed()


func get_pile_snapshot() -> Dictionary:
	return {
		"deck_size": RunState.deck.size(),
		"draw_pile_size": RunState.draw_pile.size(),
		"discard_pile_size": RunState.discard_pile.size(),
		"hand_size": RunState.hand.size(),
		"selected_count": RunState.selected_cards.size(),
		"hand": _cards_to_labels(RunState.hand),
		"draw_top_preview": _cards_to_labels(_get_draw_top_preview(5)),
	}


func get_draw_order_signature(count: int = 10) -> PackedStringArray:
	var labels := PackedStringArray()
	var limit := mini(count, RunState.draw_pile.size())
	for i in range(limit):
		var card := RunState.draw_pile[RunState.draw_pile.size() - 1 - i]
		labels.append(card.get_display_label())
	return labels


func print_pile_snapshot() -> void:
	var snapshot := get_pile_snapshot()
	print("Deck: %d | Draw: %d | Discard: %d | Hand: %d" % [
		snapshot["deck_size"],
		snapshot["draw_pile_size"],
		snapshot["discard_pile_size"],
		snapshot["hand_size"],
	])
	print("Hand: %s" % ", ".join(snapshot["hand"]))
	print("Next draw preview: %s" % ", ".join(snapshot["draw_top_preview"]))


func _get_draw_top_preview(count: int) -> Array[TrackCard]:
	var preview: Array[TrackCard] = []
	var limit := mini(count, RunState.draw_pile.size())
	for i in range(limit):
		preview.append(RunState.draw_pile[RunState.draw_pile.size() - 1 - i])
	return preview


func _cards_to_labels(cards: Array) -> PackedStringArray:
	var labels := PackedStringArray()
	for value in cards:
		var card := value as TrackCard
		if card != null:
			labels.append(card.get_display_label())
	return labels
