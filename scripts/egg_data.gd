# egg_data.gd
# Resource class for egg data storage and serialization
# Part of Dragon Ranch - Session 1 Architecture
#
# INTERFACE LOCKED - See docs/API_Reference.md

extends Resource
class_name EggData

## Unique identifier for this egg
@export var id: String = ""

## Genotype dictionary: trait_key -> [allele1, allele2]
## Determined at breeding time via GeneticsEngine
@export var genotype: Dictionary = {}

## Parent A dragon ID
@export var parent_a_id: String = ""

## Parent B dragon ID
@export var parent_b_id: String = ""

## Seasons remaining until hatching (decrements each season)
@export var incubation_seasons_remaining: int = 2

## ID of facility this egg is in (e.g., Nursery)
@export var facility_id: String = ""

## Season when this egg was created
@export var created_season: int = 0


# === SERIALIZATION ===

func to_dict() -> Dictionary:
	"""Serialize egg data to JSON-compatible dictionary."""
	return {
		"id": id,
		"genotype": genotype.duplicate(true),
		"parent_a_id": parent_a_id,
		"parent_b_id": parent_b_id,
		"incubation_seasons_remaining": incubation_seasons_remaining,
		"facility_id": facility_id,
		"created_season": created_season
	}


func from_dict(data: Dictionary) -> void:
	"""Deserialize egg data from dictionary."""
	id = data.get("id", "")
	genotype = data.get("genotype", {}).duplicate(true)
	parent_a_id = data.get("parent_a_id", "")
	parent_b_id = data.get("parent_b_id", "")
	incubation_seasons_remaining = data.get("incubation_seasons_remaining", 2)
	facility_id = data.get("facility_id", "")
	created_season = data.get("created_season", 0)


# === VALIDATION ===

func is_valid() -> bool:
	"""Validate that all required fields are present and correct."""
	if id.is_empty():
		push_warning("EggData.is_valid: id is empty")
		return false
	
	if genotype.is_empty():
		push_warning("EggData.is_valid: genotype is empty")
		return false
	
	# Validate genotype structure
	for trait_key in genotype.keys():
		var alleles = genotype[trait_key]
		if not alleles is Array or alleles.size() != 2:
			push_warning("EggData.is_valid: invalid genotype for trait '%s'" % trait_key)
			return false
	
	if parent_a_id.is_empty():
		push_warning("EggData.is_valid: parent_a_id is empty")
		return false
	
	if parent_b_id.is_empty():
		push_warning("EggData.is_valid: parent_b_id is empty")
		return false
	
	if incubation_seasons_remaining < 0:
		push_warning("EggData.is_valid: incubation_seasons_remaining is negative")
		return false
	
	return true


# === HELPER METHODS ===

func is_ready_to_hatch() -> bool:
	"""Check if this egg is ready to hatch."""
	return incubation_seasons_remaining <= 0


func decrement_incubation() -> void:
	"""Decrease incubation time by 1 season."""
	incubation_seasons_remaining = max(0, incubation_seasons_remaining - 1)


func get_incubation_progress() -> float:
	"""Get incubation progress as 0.0 to 1.0 (for UI progress bars)."""
	# Assuming standard incubation is 2-3 seasons
	const MAX_INCUBATION: int = 3
	var elapsed: int = MAX_INCUBATION - incubation_seasons_remaining
	return clampf(float(elapsed) / float(MAX_INCUBATION), 0.0, 1.0)


func get_display_genotype(trait_key: String) -> String:
	"""Get displayable genotype string for a trait (e.g., 'Ff')."""
	if not genotype.has(trait_key):
		return "??"
	var alleles: Array = genotype[trait_key]
	if alleles.size() != 2:
		return "??"
	return str(alleles[0]) + str(alleles[1])


func duplicate_data() -> EggData:
	"""Create a deep copy of this egg data."""
	var copy := EggData.new()
	copy.from_dict(to_dict())
	return copy
