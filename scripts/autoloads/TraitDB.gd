# TraitDB.gd
# Trait database autoload - manages all trait definitions
# Part of Dragon Ranch - Session 2 Core Genetics Engine
#
# Loads trait definitions from JSON and provides access to trait data
# Handles trait unlocking based on reputation level

extends Node

## Path to trait definitions JSON file
const TRAIT_DEFS_PATH: String = "res://data/config/trait_defs.json"

## Dictionary of all trait definitions: trait_key -> TraitDef
var _traits: Dictionary = {}

## Cached list of trait keys for quick access
var _trait_keys: Array[String] = []

## Whether the database has been loaded successfully
var _loaded: bool = false


func _ready() -> void:
	load_traits()


## Load trait definitions from JSON file
func load_traits() -> bool:
	if _loaded:
		push_warning("[TraitDB] Traits already loaded, skipping")
		return true

	if not FileAccess.file_exists(TRAIT_DEFS_PATH):
		push_error("[TraitDB] Trait definitions file not found: %s" % TRAIT_DEFS_PATH)
		return false

	var file: FileAccess = FileAccess.open(TRAIT_DEFS_PATH, FileAccess.READ)
	if file == null:
		push_error("[TraitDB] Failed to open trait definitions file: %s" % TRAIT_DEFS_PATH)
		return false

	var json_text: String = file.get_as_text()
	file.close()

	# P0 FIX: Handle empty file
	if json_text.is_empty():
		push_error("[TraitDB] Trait definitions file is empty: %s" % TRAIT_DEFS_PATH)
		return false

	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_text)

	if parse_result != OK:
		push_error("[TraitDB] Failed to parse JSON: %s" % json.get_error_message())
		return false

	var data: Dictionary = json.data
	if not data.has("traits"):
		push_error("[TraitDB] JSON missing 'traits' array")
		return false

	# Clear existing traits
	_traits.clear()
	_trait_keys.clear()

	# Load each trait definition
	var traits_array: Array = data["traits"]
	for trait_data in traits_array:
		if not trait_data is Dictionary:
			push_warning("[TraitDB] Skipping invalid trait data (not a dictionary)")
			continue

		var trait_def: TraitDef = TraitDef.new()
		trait_def.from_dict(trait_data)

		if not trait_def.is_valid():
			push_error("[TraitDB] Invalid trait definition for key: %s" % trait_data.get("key", "unknown"))
			continue

		_traits[trait_def.key] = trait_def
		_trait_keys.append(trait_def.key)

	_loaded = true
	print("[TraitDB] Loaded %d trait definitions" % _traits.size())
	return true


## Get a trait definition by key
## Returns null if trait not found
func get_trait_def(trait_key: String) -> TraitDef:
	if not _loaded:
		push_error("[TraitDB] Database not loaded yet")
		return null

	if not _traits.has(trait_key):
		push_warning("[TraitDB] Trait not found: %s" % trait_key)
		return null

	return _traits[trait_key]


## Get all trait keys
func get_all_trait_keys() -> Array[String]:
	return _trait_keys.duplicate()


## Get all trait definitions
func get_all_traits() -> Array[TraitDef]:
	var result: Array[TraitDef] = []
	for trait_def in _traits.values():
		result.append(trait_def)
	return result


## Get unlocked trait keys for a given reputation level
## Returns array of trait keys that should be available
func get_unlocked_traits(reputation_level: int) -> Array[String]:
	var unlocked: Array[String] = []
	for trait_key in _trait_keys:
		var trait_def: TraitDef = _traits[trait_key]
		if trait_def.unlock_level <= reputation_level:
			unlocked.append(trait_key)
	return unlocked


## Check if a trait is unlocked at a given reputation level
func is_trait_unlocked(trait_key: String, reputation_level: int) -> bool:
	var trait_def: TraitDef = get_trait_def(trait_key)
	if trait_def == null:
		return false
	return trait_def.unlock_level <= reputation_level


## Get default genotype for all unlocked traits
## Useful for creating starter dragons
## Returns Dictionary: trait_key -> [allele, allele]
func get_default_genotype(reputation_level: int) -> Dictionary:
	var genotype: Dictionary = {}
	var unlocked: Array[String] = get_unlocked_traits(reputation_level)

	for trait_key in unlocked:
		var trait_def: TraitDef = get_trait_def(trait_key)
		if trait_def == null:
			continue

		# Default to heterozygous (one dominant, one recessive)
		var dominant: String = trait_def.get_dominant_allele()
		var recessive: String = trait_def.get_recessive_allele()
		genotype[trait_key] = [dominant, recessive]

	return genotype


## Get a random valid genotype for all unlocked traits
## Uses RNGService for randomization
## Returns Dictionary: trait_key -> [allele, allele]
func get_random_genotype(reputation_level: int) -> Dictionary:
	var genotype: Dictionary = {}
	var unlocked: Array[String] = get_unlocked_traits(reputation_level)

	# P0 FIX: Check if no traits are available
	if unlocked.is_empty():
		push_error("[TraitDB] get_random_genotype: no traits loaded")
		return {}

	for trait_key in unlocked:
		var trait_def: TraitDef = get_trait_def(trait_key)
		if trait_def == null:
			continue

		# P0 FIX: Verify alleles array is not empty
		if trait_def.alleles.is_empty():
			push_warning("[TraitDB] get_random_genotype: trait '%s' has no alleles" % trait_key)
			continue

		# Randomly select two alleles (may be the same)
		var allele1: String = RNGService.choice(trait_def.alleles)
		var allele2: String = RNGService.choice(trait_def.alleles)
		genotype[trait_key] = [allele1, allele2]

	return genotype


## Check if a genotype is valid (all traits have valid alleles)
func validate_genotype(genotype: Dictionary) -> bool:
	for trait_key in genotype.keys():
		var trait_def: TraitDef = get_trait_def(trait_key)
		if trait_def == null:
			push_warning("[TraitDB] Unknown trait in genotype: %s" % trait_key)
			return false

		var alleles: Array = genotype[trait_key]
		if alleles.size() != 2:
			push_warning("[TraitDB] Genotype for %s must have exactly 2 alleles" % trait_key)
			return false

		for allele in alleles:
			if not trait_def.is_allele_valid(allele):
				push_warning("[TraitDB] Invalid allele '%s' for trait %s" % [allele, trait_key])
				return false

	return true


## Get the number of loaded traits
func get_trait_count() -> int:
	return _traits.size()


## Check if database is loaded
func is_loaded() -> bool:
	return _loaded


## Reload trait definitions from file (useful for development)
func reload() -> bool:
	_loaded = false
	return load_traits()
