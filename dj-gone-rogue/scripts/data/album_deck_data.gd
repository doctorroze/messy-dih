extends Resource
class_name AlbumDeckData

@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var deck_effect_id := ""
@export var track_names := {}
@export var suit_subtitles := {}


func get_track_name(rank: int) -> String:
	if track_names.has(rank):
		return str(track_names[rank])
	var rank_key := str(rank)
	if track_names.has(rank_key):
		return str(track_names[rank_key])
	return "Track %d" % rank


func get_suit_subtitle(suit: String) -> String:
	return str(suit_subtitles.get(suit, suit.capitalize()))


func has_deck_effect() -> bool:
	return not deck_effect_id.strip_edges().is_empty()


func validate() -> PackedStringArray:
	var issues := PackedStringArray()
	if id.strip_edges().is_empty():
		issues.append("Album deck id is required.")
	if display_name.strip_edges().is_empty():
		issues.append("Album deck display name is required.")
	for rank in Config.RANKS:
		if get_track_name(rank).strip_edges().is_empty():
			issues.append("Missing track name for rank %d." % rank)
	return issues
