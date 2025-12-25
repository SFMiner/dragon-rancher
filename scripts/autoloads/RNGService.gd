# RNGService.gd
# Centralized RNG service with seedable random number generation
# Part of Dragon Ranch - Session 2 Core Genetics Engine
#
# All randomness in the game should go through this service to ensure
# deterministic behavior for testing and save/load reproducibility.

extends Node

## Current RNG seed (stored for save/load)
var current_seed: int = 0

## Internal RNG instance
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

## Whether debug mode is enabled (logs seed operations)
var debug_mode: bool = false


func _ready() -> void:
	# Initialize with a random seed based on system time
	randomize()
	set_seed(randi())
	if debug_mode:
		print("[RNGService] Initialized with seed: %d" % current_seed)


## Set the RNG seed for deterministic random generation
## This should be called when loading a save or starting a new game
func set_seed(new_seed: int) -> void:
	current_seed = new_seed
	_rng.seed = new_seed
	if debug_mode:
		print("[RNGService] Seed set to: %d" % new_seed)


## Get the current seed (for save system)
func get_seed() -> int:
	return current_seed


## Generate a random float in range [0.0, 1.0)
func randf() -> float:
	var result: float = _rng.randf()
	if debug_mode:
		print("[RNGService] randf() -> %f" % result)
	return result


## Generate a random integer in range [from, to] (inclusive)
func randi_range(from: int, to: int) -> int:
	var result: int = _rng.randi_range(from, to)
	if debug_mode:
		print("[RNGService] randi_range(%d, %d) -> %d" % [from, to, result])
	return result


## Generate a random float in range [from, to]
func randf_range(from: float, to: float) -> float:
	var result: float = _rng.randf_range(from, to)
	if debug_mode:
		print("[RNGService] randf_range(%f, %f) -> %f" % [from, to, result])
	return result


## Randomly choose one element from an array
## Returns null if array is empty
func choice(array: Array) -> Variant:
	if array == null or array.is_empty():
		push_error("[RNGService] choice: null or empty array")
		return null
	var index: int = randi_range(0, array.size() - 1)
	return array[index]


## Shuffle an array in-place using Fisher-Yates algorithm
func shuffle(array: Array) -> void:
	if array == null or array.is_empty():
		push_warning("[RNGService] shuffle: null or empty array")
		return
	var n: int = array.size()
	for i in range(n - 1, 0, -1):
		var j: int = randi_range(0, i)
		var temp = array[i]
		array[i] = array[j]
		array[j] = temp
	if debug_mode:
		print("[RNGService] Shuffled array of size %d" % n)


## Roll a weighted random choice
## weights: Dictionary mapping values to weights (higher = more likely)
## Example: {"common": 70, "rare": 25, "legendary": 5}
func weighted_choice(weights: Dictionary) -> Variant:
	if weights == null or weights.is_empty():
		push_error("[RNGService] weighted_choice: null or empty weights")
		return null

	var total_weight: float = 0.0
	for weight in weights.values():
		total_weight += float(weight)

	# P0 FIX: Division by zero protection - handle zero/negative total weight
	if total_weight <= 0.0:
		push_error("[RNGService] weighted_choice() total weight is zero or negative: %f" % total_weight)
		# Return first key as fallback
		var keys = weights.keys()
		return keys[0] if keys.size() > 0 else null

	var roll: float = randf() * total_weight
	var cumulative: float = 0.0

	for key in weights.keys():
		cumulative += float(weights[key])
		if roll < cumulative:
			if debug_mode:
				print("[RNGService] weighted_choice() -> %s (roll: %f/%f)" % [key, roll, total_weight])
			return key

	# Fallback (should never happen due to floating point precision)
	return weights.keys()[0]


## Print current seed for debugging
func print_seed() -> void:
	print("[RNGService] Current seed: %d" % current_seed)


## Generate a new random seed and set it
func randomize_seed() -> void:
	randomize()
	set_seed(randi())


## Serialization for save system
func to_dict() -> Dictionary:
	return {
		"current_seed": current_seed,
		"debug_mode": debug_mode
	}


## Deserialization for load system
func from_dict(data: Dictionary) -> void:
	debug_mode = data.get("debug_mode", false)
	set_seed(data.get("current_seed", 0))
