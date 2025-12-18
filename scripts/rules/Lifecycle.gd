# Lifecycle.gd
# Dragon lifecycle rules and aging system
# Part of Dragon Ranch - Session 3 Dragon Entities & Lifecycle
#
# Pure logic module - no scene references
# Handles age progression, life stage transitions, and lifespan calculations

class_name Lifecycle

## Life stage thresholds (in seasons)
const HATCHLING_MAX_AGE: int = 1
const JUVENILE_MAX_AGE: int = 3
const ADULT_MAX_AGE: int = 18
const ELDER_MIN_AGE: int = 19

## Base lifespan for dragons (in seasons)
const BASE_LIFESPAN: int = 23

## Life stage names
const STAGE_EGG: String = "egg"
const STAGE_HATCHLING: String = "hatchling"
const STAGE_JUVENILE: String = "juvenile"
const STAGE_ADULT: String = "adult"
const STAGE_ELDER: String = "elder"


## Get the life stage for a given age
## Returns: "hatchling", "juvenile", "adult", or "elder"
static func get_life_stage(age: int) -> String:
	if age <= HATCHLING_MAX_AGE:
		return STAGE_HATCHLING
	elif age <= JUVENILE_MAX_AGE:
		return STAGE_JUVENILE
	elif age <= ADULT_MAX_AGE:
		return STAGE_ADULT
	else:
		return STAGE_ELDER


## Check if a dragon can breed based on life stage
## Only adult dragons can breed (not hatchlings, juveniles, or elders)
static func can_breed(dragon: DragonData) -> bool:
	if dragon == null:
		return false

	# Must be adult stage
	if dragon.life_stage != STAGE_ADULT:
		return false

	# Must have sufficient health
	if dragon.health < 20.0:
		return false

	return true


## Advance a dragon's age by one season
## Mutates the dragon's age and updates life_stage
static func advance_age(dragon: DragonData) -> void:
	if dragon == null:
		push_error("[Lifecycle] advance_age: null dragon")
		return

	dragon.age += 1
	dragon.life_stage = get_life_stage(dragon.age)


## Calculate expected lifespan for a dragon
## Base: 23 seasons
## Modified by metabolism trait (if present)
static func calculate_lifespan(dragon: DragonData) -> int:
	if dragon == null:
		return BASE_LIFESPAN

	var lifespan: int = BASE_LIFESPAN

	# Check if dragon has metabolism trait
	if dragon.genotype.has("metabolism"):
		var alleles: Array = dragon.genotype["metabolism"]
		var normalized: String = GeneticsResolvers.normalize_genotype(alleles)

		# Apply metabolism modifiers
		match normalized:
			"MM":  # Normal metabolism
				pass  # No change
			"Mm":  # Heterozygous - intermediate effect
				lifespan = int(lifespan * 0.85)  # -15% lifespan
			"mm":  # Hyper metabolism
				lifespan = int(lifespan * 0.70)  # -30% lifespan

	return lifespan


## Check if a dragon has reached end of life
static func is_end_of_life(dragon: DragonData) -> bool:
	if dragon == null:
		return true

	var max_lifespan: int = calculate_lifespan(dragon)
	return dragon.age >= max_lifespan


## Get age as a percentage of total lifespan (0.0 to 1.0)
## Useful for UI health bars or aging visual effects
static func get_age_percentage(dragon: DragonData) -> float:
	if dragon == null:
		return 1.0

	var max_lifespan: int = calculate_lifespan(dragon)
	return clampf(float(dragon.age) / float(max_lifespan), 0.0, 1.0)


## Get remaining seasons until next life stage
## Returns -1 if in final stage (elder)
static func seasons_until_next_stage(dragon: DragonData) -> int:
	if dragon == null:
		return -1

	match dragon.life_stage:
		STAGE_HATCHLING:
			return HATCHLING_MAX_AGE - dragon.age + 1
		STAGE_JUVENILE:
			return JUVENILE_MAX_AGE - dragon.age + 1
		STAGE_ADULT:
			return ADULT_MAX_AGE - dragon.age + 1
		STAGE_ELDER:
			return -1  # No next stage
		_:
			return -1


## Get sprite scale multiplier based on life stage
## Used for visual representation
static func get_stage_scale(life_stage: String) -> float:
	match life_stage:
		STAGE_HATCHLING:
			return 0.5  # 50% size
		STAGE_JUVENILE:
			return 0.75  # 75% size
		STAGE_ADULT:
			return 1.0  # 100% size
		STAGE_ELDER:
			return 1.0  # Same as adult
		_:
			return 1.0


## Get movement speed multiplier based on life stage
## Hatchlings are slower, adults are fastest
static func get_stage_speed_multiplier(life_stage: String) -> float:
	match life_stage:
		STAGE_HATCHLING:
			return 0.6  # 60% speed
		STAGE_JUVENILE:
			return 0.85  # 85% speed
		STAGE_ADULT:
			return 1.0  # 100% speed
		STAGE_ELDER:
			return 0.7  # 70% speed (slower in old age)
		_:
			return 1.0


## Get display name for life stage
static func get_stage_display_name(life_stage: String) -> String:
	match life_stage:
		STAGE_EGG:
			return "Egg"
		STAGE_HATCHLING:
			return "Hatchling"
		STAGE_JUVENILE:
			return "Juvenile"
		STAGE_ADULT:
			return "Adult"
		STAGE_ELDER:
			return "Elder"
		_:
			return "Unknown"


## Validate that a life stage string is valid
static func is_valid_stage(stage: String) -> bool:
	return stage in [STAGE_EGG, STAGE_HATCHLING, STAGE_JUVENILE, STAGE_ADULT, STAGE_ELDER]


## Get breeding age range (min and max age for breeding)
static func get_breeding_age_range() -> Dictionary:
	return {
		"min": JUVENILE_MAX_AGE + 1,  # First season of adulthood
		"max": ADULT_MAX_AGE  # Last season of adulthood
	}


## Check if dragon is in prime breeding age (mid-adulthood)
static func is_prime_breeding_age(dragon: DragonData) -> bool:
	if not can_breed(dragon):
		return false

	# Prime breeding age is middle third of adult stage
	var adult_range: int = ADULT_MAX_AGE - JUVENILE_MAX_AGE
	var prime_start: int = JUVENILE_MAX_AGE + (adult_range / 3)
	var prime_end: int = ADULT_MAX_AGE - (adult_range / 3)

	return dragon.age >= prime_start and dragon.age <= prime_end


## Get stage-specific food consumption multiplier
## Larger/more active dragons eat more
static func get_food_consumption_multiplier(life_stage: String) -> float:
	match life_stage:
		STAGE_HATCHLING:
			return 0.5  # Eat less
		STAGE_JUVENILE:
			return 0.75  # Growing, need more food
		STAGE_ADULT:
			return 1.0  # Standard consumption
		STAGE_ELDER:
			return 0.6  # Reduced appetite
		_:
			return 1.0


## Get detailed lifecycle info for a dragon (useful for UI)
static func get_lifecycle_info(dragon: DragonData) -> Dictionary:
	if dragon == null:
		return {}

	return {
		"age": dragon.age,
		"life_stage": dragon.life_stage,
		"stage_display_name": get_stage_display_name(dragon.life_stage),
		"max_lifespan": calculate_lifespan(dragon),
		"age_percentage": get_age_percentage(dragon),
		"seasons_until_next_stage": seasons_until_next_stage(dragon),
		"can_breed": can_breed(dragon),
		"is_prime_breeding_age": is_prime_breeding_age(dragon),
		"is_end_of_life": is_end_of_life(dragon),
		"scale_multiplier": get_stage_scale(dragon.life_stage),
		"speed_multiplier": get_stage_speed_multiplier(dragon.life_stage),
		"food_multiplier": get_food_consumption_multiplier(dragon.life_stage)
	}
