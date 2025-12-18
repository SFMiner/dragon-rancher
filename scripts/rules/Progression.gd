# Progression.gd
# Reputation and progression system
# Part of Dragon Ranch - Session 8 Progression System

class_name Progression

## Reputation level thresholds (lifetime earnings required)
const LEVEL_THRESHOLDS: Dictionary = {
	0: 0,        # Novice
	1: 5000,     # Established
	2: 20000,    # Expert
	3: 50000,    # Master
	4: 100000    # Legendary
}

## Traits unlocked at each level
const UNLOCKED_TRAITS: Dictionary = {
	0: ["fire", "wings", "armor"],
	1: [],  # Color unlocked at level 1 (not implemented yet)
	2: [],  # Size unlocked at level 2 (not implemented yet)
	3: [],  # Metabolism unlocked at level 3 (not implemented yet)
	4: []   # Docility unlocked at level 4 (not implemented yet)
}


## Get reputation level from lifetime earnings
static func get_reputation_level(lifetime_earnings: int) -> int:
	for level in [4, 3, 2, 1, 0]:
		if lifetime_earnings >= LEVEL_THRESHOLDS[level]:
			return level
	return 0


## Get earnings needed for next level
static func get_earnings_for_next_level(current_level: int) -> int:
	if current_level >= 4:
		return 0  # Max level
	return LEVEL_THRESHOLDS[current_level + 1]


## Get traits unlocked at a reputation level
static func get_unlocked_traits(reputation_level: int) -> Array[String]:
	var traits: Array[String] = []
	for level in range(reputation_level + 1):
		if UNLOCKED_TRAITS.has(level):
			traits.append_array(UNLOCKED_TRAITS[level])
	return traits


## Get level name
static func get_level_name(level: int) -> String:
	match level:
		0: return "Novice Breeder"
		1: return "Established Breeder"
		2: return "Expert Breeder"
		3: return "Master Breeder"
		4: return "Legendary Breeder"
		_: return "Unknown"
