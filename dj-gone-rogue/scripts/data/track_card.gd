extends Resource
class_name TrackCard

@export var unique_id := ""
@export_range(1, 13, 1) var rank := 1
@export_enum("hearts", "diamonds", "clubs", "spades") var suit := "hearts"
@export var album_deck_id := ""
@export var display_track_name := ""
@export var display_suit_subtitle := ""
@export var enhancements: Array[String] = []
@export var temporary_modifiers: Array[String] = []
@export var edition_flags := {}


func setup(
	card_id: String,
	card_rank: int,
	card_suit: String,
	card_album_deck_id: String,
	card_display_track_name: String,
	card_display_suit_subtitle: String = ""
) -> TrackCard:
	unique_id = card_id
	rank = clampi(card_rank, Config.RANK_MIN, Config.RANK_MAX)
	suit = card_suit
	album_deck_id = card_album_deck_id
	display_track_name = card_display_track_name
	display_suit_subtitle = card_display_suit_subtitle
	return self


func duplicate_card(new_unique_id: String = "") -> TrackCard:
	var copy := duplicate(true) as TrackCard
	if not new_unique_id.is_empty():
		copy.unique_id = new_unique_id
	return copy


func get_mechanical_label() -> String:
	return "%s %d" % [suit.capitalize(), rank]


func get_display_label() -> String:
	if display_track_name.is_empty():
		return get_mechanical_label()
	return "%s (%s)" % [display_track_name, get_mechanical_label()]


func get_rank_groove_value() -> int:
	return Config.get_rank_groove_value(rank)


func has_enhancement(enhancement_id: String) -> bool:
	return enhancements.has(enhancement_id)


func has_temporary_modifier(modifier_id: String) -> bool:
	return temporary_modifiers.has(modifier_id)


func add_enhancement(enhancement_id: String) -> void:
	if enhancement_id.strip_edges().is_empty():
		return
	if not enhancements.has(enhancement_id):
		enhancements.append(enhancement_id)


func set_identity_from(other: TrackCard) -> void:
	if other == null:
		return
	rank = other.rank
	suit = other.suit
	album_deck_id = other.album_deck_id
	display_track_name = other.display_track_name
	display_suit_subtitle = other.display_suit_subtitle


func to_debug_dictionary() -> Dictionary:
	return {
		"unique_id": unique_id,
		"rank": rank,
		"suit": suit,
		"album_deck_id": album_deck_id,
		"display_track_name": display_track_name,
		"display_suit_subtitle": display_suit_subtitle,
		"enhancements": enhancements.duplicate(),
		"temporary_modifiers": temporary_modifiers.duplicate(),
		"edition_flags": edition_flags.duplicate(true),
	}
