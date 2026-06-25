extends Node
class_name GameDataLibrary

const EFFECT_FLAT_GROOVE := "flat_groove"
const EFFECT_FLAT_HEAT := "flat_heat"
const EFFECT_PER_RANK_GROOVE := "per_rank_groove"
const EFFECT_HAND_TYPE_HEAT := "hand_type_heat"
const EFFECT_DECAYING_HEAT_BY_LEG := "decaying_heat_by_leg"
const EFFECT_DECK_SIZE_GROOVE := "deck_size_groove"
const EFFECT_EXACT_CARD_COUNT_HEAT := "exact_card_count_heat"
const EFFECT_PER_SUIT_HEAT := "per_suit_heat"
const EFFECT_LAST_DISCARD_HEAT := "last_discard_heat"
const EFFECT_MONEY_ON_DISCARD := "money_on_discard"
const EFFECT_FACE_RANK_HEAT := "face_rank_heat"
const EFFECT_HAND_TYPE_HEAT_MULTIPLIER := "hand_type_heat_multiplier"
const EFFECT_DOUBLE_BEAT_STREAK_HEAT := "double_beat_streak_heat"
const EFFECT_GHOST_PRODUCER := "ghost_producer"
const EFFECT_RETRIGGER_FIRST_CARD := "retrigger_first_card"

const CONSUME_ENHANCE_CARD := "enhance_card"
const CONSUME_DESTROY_SELECTED := "destroy_selected"
const CONSUME_TRANSFORM_TO_TEMPLATE := "transform_to_template"
const CONSUME_DUPLICATE_CARD := "duplicate_card"
const CONSUME_UPGRADE_HANDS := "upgrade_hands"

const BOSS_NO_REPEAT_HAND := "no_repeat_hand_type"
const BOSS_ZERO_DISCARDS := "zero_discards"
const BOSS_HIGHEST_LEVEL_TO_ONE := "highest_level_to_one"
const BOSS_ORDERED_RANKS := "ordered_ranks"
const BOSS_ENCORE := "encore"
const BOSS_DISABLE_ENHANCEMENTS := "disable_enhancements"
const BOSS_FIRST_HAND_ZERO := "first_hand_zero"
const BOSS_ONE_SUIT_PENALTY := "one_suit_penalty"

var _gear_definitions := []
var _consumable_definitions := []
var _boss_definitions := []


func _ready() -> void:
	_build_gear_definitions()
	_build_consumable_definitions()
	_build_boss_definitions()


func get_gear_pool() -> Array[GearData]:
	_ensure_definitions()
	var pool: Array[GearData] = []
	for definition in _gear_definitions:
		pool.append(_create_gear(definition))
	return pool


func get_consumable_pool() -> Array[ConsumableData]:
	_ensure_definitions()
	var pool: Array[ConsumableData] = []
	for definition in _consumable_definitions:
		pool.append(_create_consumable(definition))
	return pool


func get_boss_pool() -> Array[BossData]:
	_ensure_definitions()
	var pool: Array[BossData] = []
	for definition in _boss_definitions:
		pool.append(_create_boss(definition))
	return pool


func get_gear_by_id(id: String) -> GearData:
	_ensure_definitions()
	for definition in _gear_definitions:
		if definition["id"] == id:
			return _create_gear(definition)
	return null


func get_consumable_by_id(id: String) -> ConsumableData:
	_ensure_definitions()
	for definition in _consumable_definitions:
		if definition["id"] == id:
			return _create_consumable(definition)
	return null


func get_boss_by_id(id: String) -> BossData:
	_ensure_definitions()
	for definition in _boss_definitions:
		if definition["id"] == id:
			return _create_boss(definition)
	return null


func get_boss_order_for_run() -> Array[BossData]:
	var bosses := get_boss_pool()
	RngManager.shuffle_array_in_place(bosses)
	var ordered: Array[BossData] = []
	for i in range(mini(Config.TOUR_LEGS, bosses.size())):
		ordered.append(bosses[i])
	return ordered


func get_gear_pool_by_rarity(rarity: String) -> Array[GearData]:
	var matches: Array[GearData] = []
	for gear in get_gear_pool():
		if gear.rarity == rarity:
			matches.append(gear)
	return matches


func get_random_gear() -> GearData:
	return RngManager.choice(get_gear_pool()) as GearData


func get_random_consumable() -> ConsumableData:
	return RngManager.choice(get_consumable_pool()) as ConsumableData


func _create_gear(definition: Dictionary) -> GearData:
	var gear := GearData.new()
	gear.id = definition["id"]
	gear.display_name = definition["display_name"]
	gear.rarity = definition["rarity"]
	gear.price = int(definition["price"])
	gear.description = definition["description"]
	gear.trigger_timing = definition["trigger_timing"]
	gear.effect_type = definition["effect_type"]
	gear.parameters = definition.get("parameters", {}).duplicate(true)
	return gear


func _ensure_definitions() -> void:
	if _gear_definitions.is_empty():
		_build_gear_definitions()
	if _consumable_definitions.is_empty():
		_build_consumable_definitions()
	if _boss_definitions.is_empty():
		_build_boss_definitions()


func _create_consumable(definition: Dictionary) -> ConsumableData:
	var consumable := ConsumableData.new()
	consumable.id = definition["id"]
	consumable.display_name = definition["display_name"]
	consumable.category = definition["category"]
	consumable.price = int(definition["price"])
	consumable.description = definition["description"]
	consumable.target_rules = definition.get("target_rules", {}).duplicate(true)
	consumable.effect_type = definition["effect_type"]
	consumable.parameters = definition.get("parameters", {}).duplicate(true)
	return consumable


func _create_boss(definition: Dictionary) -> BossData:
	var boss := BossData.new()
	boss.id = definition["id"]
	boss.country = definition["country"]
	boss.venue_name = definition["venue_name"]
	boss.display_name = definition["display_name"]
	boss.difficulty = definition["difficulty"]
	boss.rule_text = definition["rule_text"]
	boss.effect_type = definition["effect_type"]
	boss.parameters = definition.get("parameters", {}).duplicate(true)
	return boss


func _build_gear_definitions() -> void:
	_gear_definitions = [
		{"id": "subwoofer", "display_name": "Subwoofer", "rarity": "common", "price": 5, "description": "+40 Groove.", "trigger_timing": "score", "effect_type": EFFECT_FLAT_GROOVE, "parameters": {"groove": 40}},
		{"id": "hype_man", "display_name": "Hype Man", "rarity": "common", "price": 5, "description": "+4 Heat.", "trigger_timing": "score", "effect_type": EFFECT_FLAT_HEAT, "parameters": {"heat": 4}},
		{"id": "drum_machine", "display_name": "Drum Machine", "rarity": "common", "price": 4, "description": "+15 Groove for every scored Track 4.", "trigger_timing": "score", "effect_type": EFFECT_PER_RANK_GROOVE, "parameters": {"rank": 4, "groove": 15}},
		{"id": "crossfader", "display_name": "Crossfader", "rarity": "common", "price": 5, "description": "+10 Heat if the hand is Crossfade.", "trigger_timing": "score", "effect_type": EFFECT_HAND_TYPE_HEAT, "parameters": {"hand_type": Config.HAND_CROSSFADE, "heat": 10}},
		{"id": "cheap_headphones", "display_name": "Cheap Headphones", "rarity": "common", "price": 4, "description": "+8 Heat, loses 2 Heat per Tour Leg.", "trigger_timing": "score", "effect_type": EFFECT_DECAYING_HEAT_BY_LEG, "parameters": {"base_heat": 8, "loss_per_leg": 2}},
		{"id": "vinyl_crate", "display_name": "Vinyl Crate", "rarity": "common", "price": 6, "description": "+2 Groove per card in deck.", "trigger_timing": "score", "effect_type": EFFECT_DECK_SIZE_GROOVE, "parameters": {"groove_per_card": 2}},
		{"id": "smoke_machine", "display_name": "Smoke Machine", "rarity": "common", "price": 5, "description": "+12 Heat if exactly 3 Tracks are played.", "trigger_timing": "score", "effect_type": EFFECT_EXACT_CARD_COUNT_HEAT, "parameters": {"card_count": 3, "heat": 12}},
		{"id": "laser_rig", "display_name": "Laser Rig", "rarity": "common", "price": 5, "description": "+5 Heat for every Club scored.", "trigger_timing": "score", "effect_type": EFFECT_PER_SUIT_HEAT, "parameters": {"suit": Config.SUIT_CLUBS, "heat": 5}},
		{"id": "neon_sign", "display_name": "Neon Sign", "rarity": "common", "price": 5, "description": "+5 Heat for every Heart scored.", "trigger_timing": "score", "effect_type": EFFECT_PER_SUIT_HEAT, "parameters": {"suit": Config.SUIT_HEARTS, "heat": 5}},
		{"id": "strobe_light", "display_name": "Strobe Light", "rarity": "common", "price": 5, "description": "+5 Heat for every Diamond scored.", "trigger_timing": "score", "effect_type": EFFECT_PER_SUIT_HEAT, "parameters": {"suit": Config.SUIT_DIAMONDS, "heat": 5}},
		{"id": "spare_cables", "display_name": "Spare Cables", "rarity": "uncommon", "price": 7, "description": "+5 Heat for every Spade scored.", "trigger_timing": "score", "effect_type": EFFECT_PER_SUIT_HEAT, "parameters": {"suit": Config.SUIT_SPADES, "heat": 5}},
		{"id": "sound_engineer", "display_name": "Sound Engineer", "rarity": "uncommon", "price": 8, "description": "+15 Heat if played with 0 discards remaining.", "trigger_timing": "score", "effect_type": EFFECT_LAST_DISCARD_HEAT, "parameters": {"heat": 15}},
		{"id": "vip_list", "display_name": "VIP List", "rarity": "uncommon", "price": 8, "description": "Earn $2 whenever you use a discard.", "trigger_timing": "discard", "effect_type": EFFECT_MONEY_ON_DISCARD, "parameters": {"money": 2}},
		{"id": "golden_mic", "display_name": "Golden Mic", "rarity": "uncommon", "price": 8, "description": "Tracks 11, 12, and 13 give +4 Heat when scored.", "trigger_timing": "score", "effect_type": EFFECT_FACE_RANK_HEAT, "parameters": {"ranks": [11, 12, 13], "heat": 4}},
		{"id": "synthesizer", "display_name": "Synthesizer", "rarity": "uncommon", "price": 9, "description": "x2 Heat if the hand is Mashup.", "trigger_timing": "score", "effect_type": EFFECT_HAND_TYPE_HEAT_MULTIPLIER, "parameters": {"hand_type": Config.HAND_MASHUP, "heat_multiplier": 2.0}},
		{"id": "metronome", "display_name": "Metronome", "rarity": "uncommon", "price": 9, "description": "+2 Heat for each current Double Beat streak. Resets on other hands.", "trigger_timing": "score", "effect_type": EFFECT_DOUBLE_BEAT_STREAK_HEAT, "parameters": {"heat_per_streak": 2}},
		{"id": "ghost_producer", "display_name": "Ghost Producer", "rarity": "rare", "price": 13, "description": "x3 Heat, but disables flat +Groove Gear.", "trigger_timing": "score", "effect_type": EFFECT_GHOST_PRODUCER, "parameters": {"heat_multiplier": 3.0}},
		{"id": "the_sampler", "display_name": "The Sampler", "rarity": "rare", "price": 12, "description": "Retrigger the first scoring Track 3 times.", "trigger_timing": "score", "effect_type": EFFECT_RETRIGGER_FIRST_CARD, "parameters": {"times": 3}},
	]


func _build_consumable_definitions() -> void:
	_consumable_definitions = [
		{"id": "bass_boost", "display_name": "Bass Boost", "category": "studio", "price": 4, "description": "Enhance 1 Track. When scored: +30 Groove.", "target_rules": {"min": 1, "max": 1}, "effect_type": CONSUME_ENHANCE_CARD, "parameters": {"enhancement": "bass_boost"}},
		{"id": "reverb", "display_name": "Reverb", "category": "studio", "price": 5, "description": "Enhance 1 Track. It retriggers once.", "target_rules": {"min": 1, "max": 1}, "effect_type": CONSUME_ENHANCE_CARD, "parameters": {"enhancement": "reverb"}},
		{"id": "autotune", "display_name": "Autotune", "category": "studio", "price": 5, "description": "Enhance 1 Track. It can count as any suit for flush checks.", "target_rules": {"min": 1, "max": 1}, "effect_type": CONSUME_ENHANCE_CARD, "parameters": {"enhancement": "autotune"}},
		{"id": "remaster", "display_name": "Remaster", "category": "studio", "price": 6, "description": "Enhance 1 Track. When scored: x1.5 Heat.", "target_rules": {"min": 1, "max": 1}, "effect_type": CONSUME_ENHANCE_CARD, "parameters": {"enhancement": "remaster"}},
		{"id": "fade_out", "display_name": "Fade Out", "category": "studio", "price": 5, "description": "Destroy up to 2 selected Tracks.", "target_rules": {"min": 1, "max": 2}, "effect_type": CONSUME_DESTROY_SELECTED, "parameters": {"max": 2}},
		{"id": "white_label", "display_name": "White Label", "category": "studio", "price": 6, "description": "Transform selected Tracks into copies of the first selected Track identity.", "target_rules": {"min": 2, "max": 2}, "effect_type": CONSUME_TRANSFORM_TO_TEMPLATE, "parameters": {"max": 2}},
		{"id": "loop_pedal", "display_name": "Loop Pedal", "category": "studio", "price": 6, "description": "Duplicate 1 selected Track into the deck.", "target_rules": {"min": 1, "max": 1}, "effect_type": CONSUME_DUPLICATE_CARD, "parameters": {}},
		{"id": "gold_plating", "display_name": "Gold Plating", "category": "studio", "price": 5, "description": "Enhance 1 Track. Gives $3 when held at end of stop.", "target_rules": {"min": 1, "max": 1}, "effect_type": CONSUME_ENHANCE_CARD, "parameters": {"enhancement": "gold_plating"}},
		{"id": "billboard_top_100", "display_name": "Billboard Top 100", "category": "chart", "price": 5, "description": "Upgrade Solo Drop and Double Beat.", "target_rules": {}, "effect_type": CONSUME_UPGRADE_HANDS, "parameters": {"hand_types": [Config.HAND_SOLO_DROP, Config.HAND_DOUBLE_BEAT]}},
		{"id": "club_anthem", "display_name": "Club Anthem", "category": "chart", "price": 5, "description": "Upgrade Mashup and Triple Threat.", "target_rules": {}, "effect_type": CONSUME_UPGRADE_HANDS, "parameters": {"hand_types": [Config.HAND_MASHUP, Config.HAND_TRIPLE_THREAT]}},
		{"id": "radio_edit", "display_name": "Radio Edit", "category": "chart", "price": 4, "description": "Upgrade Crossfade.", "target_rules": {}, "effect_type": CONSUME_UPGRADE_HANDS, "parameters": {"hand_types": [Config.HAND_CROSSFADE]}},
		{"id": "underground_hit", "display_name": "Underground Hit", "category": "chart", "price": 4, "description": "Upgrade Color Mix.", "target_rules": {}, "effect_type": CONSUME_UPGRADE_HANDS, "parameters": {"hand_types": [Config.HAND_COLOR_MIX]}},
		{"id": "main_stage_banger", "display_name": "Main Stage Banger", "category": "chart", "price": 5, "description": "Upgrade Headline Set.", "target_rules": {}, "effect_type": CONSUME_UPGRADE_HANDS, "parameters": {"hand_types": [Config.HAND_HEADLINE_SET]}},
		{"id": "festival_closer", "display_name": "Festival Closer", "category": "chart", "price": 6, "description": "Upgrade Wall of Sound and Perfect Transition.", "target_rules": {}, "effect_type": CONSUME_UPGRADE_HANDS, "parameters": {"hand_types": [Config.HAND_WALL_OF_SOUND, Config.HAND_PERFECT_TRANSITION]}},
	]


func _build_boss_definitions() -> void:
	_boss_definitions = [
		{"id": "germany_industrial_warehouse", "country": "Germany", "venue_name": "Industrial Warehouse", "display_name": "Industrial Warehouse", "difficulty": "medium", "rule_text": "Cannot play the same Hand Type twice during this stop.", "effect_type": BOSS_NO_REPEAT_HAND, "parameters": {}},
		{"id": "uk_open_air_mudfest", "country": "UK", "venue_name": "Open Air Mudfest", "display_name": "Open Air Mudfest", "difficulty": "medium", "rule_text": "Start this stop with 0 discards.", "effect_type": BOSS_ZERO_DISCARDS, "parameters": {}},
		{"id": "france_critic_balcony", "country": "France", "venue_name": "Critic Balcony", "display_name": "Critic Balcony", "difficulty": "hard", "rule_text": "Highest leveled Hand Type is treated as level 1.", "effect_type": BOSS_HIGHEST_LEVEL_TO_ONE, "parameters": {}},
		{"id": "netherlands_laser_grid", "country": "Netherlands", "venue_name": "Laser Grid", "display_name": "Laser Grid", "difficulty": "medium", "rule_text": "Selected Tracks must be in ascending or descending rank order or score -50%.", "effect_type": BOSS_ORDERED_RANKS, "parameters": {"multiplier": 0.5}},
		{"id": "italy_encore_demand", "country": "Italy", "venue_name": "Encore Demand", "display_name": "Encore Demand", "difficulty": "hard", "rule_text": "After reaching the target, play one more Encore worth at least 10% of target.", "effect_type": BOSS_ENCORE, "parameters": {"required_ratio": 0.1}},
		{"id": "sweden_clean_room", "country": "Sweden", "venue_name": "Clean Room", "display_name": "Clean Room", "difficulty": "hard", "rule_text": "Enhanced Tracks do not trigger enhancement effects.", "effect_type": BOSS_DISABLE_ENHANCEMENTS, "parameters": {}},
		{"id": "iceland_ice_cave", "country": "Iceland", "venue_name": "Ice Cave", "display_name": "Ice Cave", "difficulty": "hard", "rule_text": "The first hand played this stop scores 0 Crowd Hype.", "effect_type": BOSS_FIRST_HAND_ZERO, "parameters": {}},
		{"id": "spain_sunset_festival", "country": "Spain", "venue_name": "Sunset Festival", "display_name": "Sunset Festival", "difficulty": "medium", "rule_text": "Hands using only one suit score -40% Crowd Hype.", "effect_type": BOSS_ONE_SUIT_PENALTY, "parameters": {"multiplier": 0.6}},
	]
