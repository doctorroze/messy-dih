extends Node
class_name GameConfig

const SUIT_HEARTS := "hearts"
const SUIT_DIAMONDS := "diamonds"
const SUIT_CLUBS := "clubs"
const SUIT_SPADES := "spades"
const SUITS := [SUIT_HEARTS, SUIT_DIAMONDS, SUIT_CLUBS, SUIT_SPADES]

const RANK_MIN := 1
const RANK_MAX := 13
const RANKS := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]

const STOP_ASIA := "asia"
const STOP_NORTH_AMERICA := "north_america"
const STOP_EUROPE := "europe"
const STOP_ORDER := [STOP_ASIA, STOP_NORTH_AMERICA, STOP_EUROPE]
const STOP_DISPLAY_NAMES := {
	STOP_ASIA: "Asia Set",
	STOP_NORTH_AMERICA: "North America Set",
	STOP_EUROPE: "Europe Headliner",
}

const STARTER_ALBUM_DECK_ID := "basic_mixtape"
const DEFAULT_SEED := "opening-night"
const TOUR_LEGS := 6
const HAND_SIZE := 8
const HANDS_PER_STOP := 4
const DISCARDS_PER_STOP := 3
const MAX_GEAR_SLOTS := 5
const MAX_CONSUMABLE_SLOTS := 2

const STARTING_MONEY := 6
const INTEREST_DIVISOR := 5
const INTEREST_CAP := 5
const REROLL_BASE_COST := 4
const REROLL_INCREMENT := 1

const LEG_BASE_TARGETS := {
	1: 300,
	2: 750,
	3: 1800,
	4: 4200,
	5: 10000,
	6: 24000,
}

const STOP_TARGET_MULTIPLIERS := {
	STOP_ASIA: 1.0,
	STOP_NORTH_AMERICA: 1.5,
	STOP_EUROPE: 2.0,
}

const STOP_REWARD_BASES := {
	STOP_ASIA: 3,
	STOP_NORTH_AMERICA: 4,
	STOP_EUROPE: 5,
}

const HAND_SOLO_DROP := "solo_drop"
const HAND_DOUBLE_BEAT := "double_beat"
const HAND_MASHUP := "mashup"
const HAND_TRIPLE_THREAT := "triple_threat"
const HAND_CROSSFADE := "crossfade"
const HAND_COLOR_MIX := "color_mix"
const HAND_HEADLINE_SET := "headline_set"
const HAND_WALL_OF_SOUND := "wall_of_sound"
const HAND_PERFECT_TRANSITION := "perfect_transition"
const HAND_ANTHEM := "anthem"
const HAND_PLATINUM_SET := "platinum_set"
const HAND_DIAMOND_RECORD := "diamond_record"

const HAND_TYPE_ORDER := [
	HAND_SOLO_DROP,
	HAND_DOUBLE_BEAT,
	HAND_MASHUP,
	HAND_TRIPLE_THREAT,
	HAND_CROSSFADE,
	HAND_COLOR_MIX,
	HAND_HEADLINE_SET,
	HAND_WALL_OF_SOUND,
	HAND_PERFECT_TRANSITION,
	HAND_ANTHEM,
	HAND_PLATINUM_SET,
	HAND_DIAMOND_RECORD,
]

const HAND_DISPLAY_NAMES := {
	HAND_SOLO_DROP: "Solo Drop",
	HAND_DOUBLE_BEAT: "Double Beat",
	HAND_MASHUP: "Mashup",
	HAND_TRIPLE_THREAT: "Triple Threat",
	HAND_CROSSFADE: "Crossfade",
	HAND_COLOR_MIX: "Color Mix",
	HAND_HEADLINE_SET: "Headline Set",
	HAND_WALL_OF_SOUND: "Wall of Sound",
	HAND_PERFECT_TRANSITION: "Perfect Transition",
	HAND_ANTHEM: "Anthem",
	HAND_PLATINUM_SET: "Platinum Set",
	HAND_DIAMOND_RECORD: "Diamond Record",
}

const HAND_SCORING_RULES := {
	HAND_SOLO_DROP: {
		"base_groove": 5,
		"base_heat": 1,
		"level_groove": 10,
		"level_heat": 1,
	},
	HAND_DOUBLE_BEAT: {
		"base_groove": 10,
		"base_heat": 2,
		"level_groove": 15,
		"level_heat": 1,
	},
	HAND_MASHUP: {
		"base_groove": 20,
		"base_heat": 2,
		"level_groove": 20,
		"level_heat": 1,
	},
	HAND_TRIPLE_THREAT: {
		"base_groove": 30,
		"base_heat": 3,
		"level_groove": 20,
		"level_heat": 2,
	},
	HAND_CROSSFADE: {
		"base_groove": 30,
		"base_heat": 4,
		"level_groove": 30,
		"level_heat": 2,
	},
	HAND_COLOR_MIX: {
		"base_groove": 35,
		"base_heat": 4,
		"level_groove": 15,
		"level_heat": 2,
	},
	HAND_HEADLINE_SET: {
		"base_groove": 40,
		"base_heat": 4,
		"level_groove": 25,
		"level_heat": 2,
	},
	HAND_WALL_OF_SOUND: {
		"base_groove": 60,
		"base_heat": 7,
		"level_groove": 30,
		"level_heat": 3,
	},
	HAND_PERFECT_TRANSITION: {
		"base_groove": 100,
		"base_heat": 8,
		"level_groove": 40,
		"level_heat": 3,
	},
	HAND_ANTHEM: {
		"base_groove": 120,
		"base_heat": 12,
		"level_groove": 35,
		"level_heat": 3,
	},
	HAND_PLATINUM_SET: {
		"base_groove": 140,
		"base_heat": 14,
		"level_groove": 40,
		"level_heat": 4,
	},
	HAND_DIAMOND_RECORD: {
		"base_groove": 160,
		"base_heat": 16,
		"level_groove": 50,
		"level_heat": 3,
	},
}

const MAX_RETRIGGER_LOOPS := 32


func get_stop_display_name(stop_type: String) -> String:
	return STOP_DISPLAY_NAMES.get(stop_type, stop_type.capitalize())


func get_target_hype(leg: int, stop_type: String) -> int:
	var clamped_leg := clampi(leg, 1, TOUR_LEGS)
	var base_target: int = LEG_BASE_TARGETS.get(clamped_leg, LEG_BASE_TARGETS[TOUR_LEGS])
	var multiplier: float = STOP_TARGET_MULTIPLIERS.get(stop_type, 1.0)
	return int(round(base_target * multiplier))


func get_reward_base(stop_type: String) -> int:
	return STOP_REWARD_BASES.get(stop_type, STOP_REWARD_BASES[STOP_ASIA])


func get_hand_display_name(hand_type: String) -> String:
	return HAND_DISPLAY_NAMES.get(hand_type, hand_type.capitalize())


func get_starting_hand_levels() -> Dictionary:
	var levels := {}
	for hand_type in HAND_TYPE_ORDER:
		levels[hand_type] = 1
	return levels


func get_hand_level_values(hand_type: String, level: int) -> Dictionary:
	var rule: Dictionary = HAND_SCORING_RULES.get(hand_type, HAND_SCORING_RULES[HAND_SOLO_DROP])
	var safe_level := maxi(level, 1)
	var level_offset := safe_level - 1
	return {
		"groove": rule["base_groove"] + (rule["level_groove"] * level_offset),
		"heat": rule["base_heat"] + (rule["level_heat"] * level_offset),
	}


func get_rank_groove_value(rank: int) -> int:
	if rank == 1:
		return 11
	if rank >= 11:
		return 10
	return clampi(rank, 2, 10)
