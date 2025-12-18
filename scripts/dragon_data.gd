# dragon_data.gd
# Resource class for dragon data storage and serialization
# Part of Dragon Ranch - Session 1 Architecture
#
# INTERFACE LOCKED - See docs/API_Reference.md

extends Resource
class_name DragonData

## Unique identifier for this dragon
@export var id: String = ""

## Display name for the dragon
@export var name: String = ""

## Biological sex: "male" or "female"
@export var sex: String = ""

## Genotype dictionary: trait_key -> [allele1, allele2]
## Example: {"fire": ["F", "f"], "wings": ["w", "W"]}
@export var genotype: Dictionary = {}

## Phenotype dictionary: trait_key -> phenotype_data
## phenotype_data contains: {name, sprite_suffix, color, etc.}
## Calculated from genotype via GeneticsEngine.calculate_phenotype()
@export var phenotype: Dictionary = {}

## Age in seasons (increments each season)
@export var age: int = 0

## Current life stage: "egg", "hatchling", "juvenile", "adult", "elder"
@export var life_stage: String = "hatchling"

## Health value 0.0 - 100.0
@export var health: float = 100.0

## Happiness value 0.0 - 100.0
@export var happiness: float = 100.0

## Training level 0.0 - 100.0 (for contests/battles)
@export var training: float = 0.0

## Parent A dragon ID (empty string if unknown/starter)
@export var parent_a_id: String = ""

## Parent B dragon ID (empty string if unknown/starter)
@export var parent_b_id: String = ""

## Array of child dragon IDs
@export var children_ids: Array[String] = []

## ID of facility this dragon is assigned to (empty if none)
@export var facility_id: String = ""

## Season when this dragon was born/hatched
@export var born_season: int = 0


# === SERIALIZATION ===

func to_dict() -> Dictionary:
	"""Serialize dragon data to JSON-compatible dictionary."""
	return {
		"id": id,
		"name": name,
		"sex": sex,
		"genotype": genotype.duplicate(true),
		"phenotype": phenotype.duplicate(true),
		"age": age,
		"life_stage": life_stage,
		"health": health,
		"happiness": happiness,
		"training": training,
		"parent_a_id": parent_a_id,
		"parent_b_id": parent_b_id,
		"children_ids": children_ids.duplicate(),
		"facility_id": facility_id,
		"born_season": born_season
	}


func from_dict(data: Dictionary) -> void:
	"""Deserialize dragon data from dictionary."""
	id = data.get("id", "")
	name = data.get("name", "")
	sex = data.get("sex", "")
	genotype = data.get("genotype", {}).duplicate(true)
	phenotype = data.get("phenotype", {}).duplicate(true)
	age = data.get("age", 0)
	life_stage = data.get("life_stage", "hatchling")
	health = data.get("health", 100.0)
	happiness = data.get("happiness", 100.0)
	training = data.get("training", 0.0)
	parent_a_id = data.get("parent_a_id", "")
	parent_b_id = data.get("parent_b_id", "")
	children_ids = Array(data.get("children_ids", []), TYPE_STRING, "", null)
	facility_id = data.get("facility_id", "")
	born_season = data.get("born_season", 0)


# === VALIDATION ===

func is_valid() -> bool:
	"""Validate that all required fields are present and correct."""
	if id.is_empty():
		push_warning("DragonData.is_valid: id is empty")
		return false
	
	if name.is_empty():
		push_warning("DragonData.is_valid: name is empty")
		return false
	
	if sex not in ["male", "female"]:
		push_warning("DragonData.is_valid: invalid sex '%s'" % sex)
		return false
	
	if genotype.is_empty():
		push_warning("DragonData.is_valid: genotype is empty")
		return false
	
	# Validate genotype structure
	for trait_key in genotype.keys():
		var alleles = genotype[trait_key]
		if not alleles is Array or alleles.size() != 2:
			push_warning("DragonData.is_valid: invalid genotype for trait '%s'" % trait_key)
			return false
	
	if life_stage not in ["egg", "hatchling", "juvenile", "adult", "elder"]:
		push_warning("DragonData.is_valid: invalid life_stage '%s'" % life_stage)
		return false
	
	if health < 0.0 or health > 100.0:
		push_warning("DragonData.is_valid: health out of range: %f" % health)
		return false
	
	if happiness < 0.0 or happiness > 100.0:
		push_warning("DragonData.is_valid: happiness out of range: %f" % happiness)
		return false
	
	return true


# === HELPER METHODS ===

func can_breed() -> bool:
	"""Check if this dragon can breed (adult stage, healthy enough)."""
	return life_stage == "adult" and health >= 20.0


func get_display_genotype(trait_key: String) -> String:
	"""Get displayable genotype string for a trait (e.g., 'Ff')."""
	if not genotype.has(trait_key):
		return "??"
	var alleles: Array = genotype[trait_key]
	if alleles.size() != 2:
		return "??"
	return str(alleles[0]) + str(alleles[1])


func get_phenotype_name(trait_key: String) -> String:
	"""Get display name for a trait's phenotype."""
	if not phenotype.has(trait_key):
		return "Unknown"
	var pheno_data: Dictionary = phenotype[trait_key]
	return pheno_data.get("name", "Unknown")


func has_known_parents() -> bool:
	"""Check if this dragon has known parentage."""
	return not parent_a_id.is_empty() and not parent_b_id.is_empty()


func add_child(child_id: String) -> void:
	"""Add a child to this dragon's children list."""
	if not child_id in children_ids:
		children_ids.append(child_id)


func duplicate_data() -> DragonData:
	"""Create a deep copy of this dragon data."""
	var copy := DragonData.new()
	copy.from_dict(to_dict())
	return copy
