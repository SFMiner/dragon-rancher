# trait_def.gd
# Resource class for trait definition data
# Defines how a genetic trait works (alleles, dominance, phenotypes)
# Part of Dragon Ranch - Session 1 Architecture
#
# INTERFACE LOCKED - See docs/API_Reference.md

extends Resource
class_name TraitDef

## Dominance type constants
const DOMINANCE_SIMPLE: String = "simple"           # One allele fully dominant
const DOMINANCE_INCOMPLETE: String = "incomplete"   # Heterozygote is intermediate
const DOMINANCE_HIERARCHY: String = "hierarchy"     # Multiple alleles with ranking

## Canonical trait key (e.g., "fire", "wings", "armor")
## MUST match keys defined in TraitDB
@export var key: String = ""

## Display name for UI (e.g., "Breath Type", "Wing Type")
@export var name: String = ""

## Description for tooltips
@export var description: String = ""

## List of possible alleles (e.g., ["F", "f"] or ["D1", "D2", "D3"])
@export var alleles: Array[String] = []

## Dominance type (see constants above)
@export var dominance_type: String = DOMINANCE_SIMPLE

## Dominance rank: ordered from most dominant to most recessive
## For simple: ["F", "f"] means F is dominant over f
## For hierarchy: ["D2", "D1", "D3"] means D2 > D1 > D3
@export var dominance_rank: Array[String] = []

## Phenotype lookup table
## Key: normalized genotype string (e.g., "Ff", "FF", "ff")
## Value: Dictionary with phenotype data
## {
##   "name": "Fire",
##   "sprite_suffix": "fire",
##   "color": Color,
##   "description": "Breathes fire",
##   ... (trait-specific extras)
## }
@export var phenotypes: Dictionary = {}

## Minimum reputation level to unlock this trait
@export var unlock_level: int = 0

## Whether this is a multi-locus trait (e.g., Size uses size_s and size_g)
@export var is_multi_locus: bool = false

## For multi-locus traits, list of related locus keys
@export var related_loci: Array[String] = []


# === SERIALIZATION ===

func to_dict() -> Dictionary:
	"""Serialize trait definition to JSON-compatible dictionary."""
	# Convert phenotypes Color values to hex strings for JSON
	var phenotypes_json: Dictionary = {}
	for geno_key in phenotypes.keys():
		var pheno_data: Dictionary = phenotypes[geno_key].duplicate(true)
		if pheno_data.has("color") and pheno_data["color"] is Color:
			pheno_data["color"] = pheno_data["color"].to_html()
		phenotypes_json[geno_key] = pheno_data
	
	return {
		"key": key,
		"name": name,
		"description": description,
		"alleles": alleles.duplicate(),
		"dominance_type": dominance_type,
		"dominance_rank": dominance_rank.duplicate(),
		"phenotypes": phenotypes_json,
		"unlock_level": unlock_level,
		"is_multi_locus": is_multi_locus,
		"related_loci": related_loci.duplicate()
	}


func from_dict(data: Dictionary) -> void:
	"""Deserialize trait definition from dictionary."""
	key = data.get("key", "")
	name = data.get("name", "")
	description = data.get("description", "")
	alleles = Array(data.get("alleles", []), TYPE_STRING, "", null)
	dominance_type = data.get("dominance_type", DOMINANCE_SIMPLE)
	dominance_rank = Array(data.get("dominance_rank", []), TYPE_STRING, "", null)
	unlock_level = data.get("unlock_level", 0)
	is_multi_locus = data.get("is_multi_locus", false)
	related_loci = Array(data.get("related_loci", []), TYPE_STRING, "", null)
	
	# Parse phenotypes and convert color strings back to Color
	phenotypes = {}
	var phenotypes_data: Dictionary = data.get("phenotypes", {})
	for geno_key in phenotypes_data.keys():
		var pheno_data: Dictionary = phenotypes_data[geno_key].duplicate(true)
		if pheno_data.has("color") and pheno_data["color"] is String:
			pheno_data["color"] = Color.from_string(pheno_data["color"], Color.WHITE)
		phenotypes[geno_key] = pheno_data


# === VALIDATION ===

func is_valid() -> bool:
	"""Validate that trait definition is complete and correct."""
	if key.is_empty():
		push_warning("TraitDef.is_valid: key is empty")
		return false
	
	if name.is_empty():
		push_warning("TraitDef.is_valid: name is empty")
		return false
	
	if alleles.size() < 2:
		push_warning("TraitDef.is_valid: need at least 2 alleles")
		return false
	
	if dominance_type not in [DOMINANCE_SIMPLE, DOMINANCE_INCOMPLETE, DOMINANCE_HIERARCHY]:
		push_warning("TraitDef.is_valid: invalid dominance_type '%s'" % dominance_type)
		return false
	
	if dominance_rank.size() != alleles.size():
		push_warning("TraitDef.is_valid: dominance_rank size must match alleles size")
		return false
	
	# Verify all alleles are in dominance_rank
	for allele in alleles:
		if allele not in dominance_rank:
			push_warning("TraitDef.is_valid: allele '%s' not in dominance_rank" % allele)
			return false
	
	if phenotypes.is_empty():
		push_warning("TraitDef.is_valid: phenotypes is empty")
		return false
	
	return true


# === HELPER METHODS ===

func get_dominant_allele() -> String:
	"""Get the most dominant allele."""
	if dominance_rank.is_empty():
		return ""
	return dominance_rank[0]


func get_recessive_allele() -> String:
	"""Get the most recessive allele (for simple dominance)."""
	if dominance_rank.is_empty():
		return ""
	return dominance_rank[dominance_rank.size() - 1]


func is_allele_valid(allele: String) -> bool:
	"""Check if an allele is valid for this trait."""
	return allele in alleles


func get_phenotype_data(normalized_genotype: String) -> Dictionary:
	"""Get phenotype data for a normalized genotype string."""
	if phenotypes.has(normalized_genotype):
		return phenotypes[normalized_genotype]
	
	# Try reversed order for heterozygotes
	if normalized_genotype.length() == 2:
		var reversed_geno: String = normalized_genotype[1] + normalized_genotype[0]
		if phenotypes.has(reversed_geno):
			return phenotypes[reversed_geno]
	
	push_warning("TraitDef.get_phenotype_data: unknown genotype '%s' for trait '%s'" % [normalized_genotype, key])
	return {}


func normalize_genotype(allele_a: String, allele_b: String) -> String:
	"""
	Normalize a genotype pair to canonical form for phenotype lookup.
	Uses dominance_rank to determine ordering.
	"""
	var rank_a: int = dominance_rank.find(allele_a)
	var rank_b: int = dominance_rank.find(allele_b)
	
	if rank_a == -1 or rank_b == -1:
		# Unknown allele, use alphabetical
		if allele_a <= allele_b:
			return allele_a + allele_b
		else:
			return allele_b + allele_a
	
	# Put more dominant allele first
	if rank_a <= rank_b:
		return allele_a + allele_b
	else:
		return allele_b + allele_a


func get_all_possible_genotypes() -> Array[String]:
	"""Get all possible genotype combinations for this trait."""
	var genotypes: Array[String] = []
	for i in range(alleles.size()):
		for j in range(i, alleles.size()):
			var geno: String = normalize_genotype(alleles[i], alleles[j])
			if geno not in genotypes:
				genotypes.append(geno)
	return genotypes


func duplicate_data() -> TraitDef:
	"""Create a deep copy of this trait definition."""
	var copy := TraitDef.new()
	copy.from_dict(to_dict())
	return copy
