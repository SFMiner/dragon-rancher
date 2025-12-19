# GeneticsResolvers.gd
# Static utility functions for genetics normalization and validation
# Part of Dragon Ranch - Session 2 Core Genetics Engine
#
# Not an autoload - use as a static class
# Example: GeneticsResolvers.normalize_genotype(["f", "F"])

class_name GeneticsResolvers


## Normalize a genotype (pair of alleles) to canonical string form
## Sorts alleles alphabetically for consistent phenotype lookups
## Example: ["f", "F"] -> "Ff", ["F", "f"] -> "Ff"
static func normalize_genotype(alleles: Array) -> String:
	if alleles.size() != 2:
		push_warning("[GeneticsResolvers] normalize_genotype: expected 2 alleles, got %d" % alleles.size())
		return ""

	var allele_a: String = str(alleles[0])
	var allele_b: String = str(alleles[1])

	# Sort alphabetically (capital letters come before lowercase in ASCII)
	if allele_a <= allele_b:
		return allele_a + allele_b
	else:
		return allele_b + allele_a


## Normalize using trait definition's dominance rank
## This version uses the trait's dominance hierarchy instead of alphabetical sorting
## Returns the normalized genotype string
static func normalize_genotype_by_dominance(alleles: Array, trait_def: TraitDef) -> String:
	if alleles.size() != 2:
		push_warning("[GeneticsResolvers] normalize_genotype_by_dominance: expected 2 alleles, got %d" % alleles.size())
		return ""

	if trait_def == null:
		push_warning("[GeneticsResolvers] normalize_genotype_by_dominance: trait_def is null")
		return normalize_genotype(alleles)

	return trait_def.normalize_genotype(str(alleles[0]), str(alleles[1]))


## Validate that a genotype dictionary is well-formed
## Checks that each trait has exactly 2 valid alleles
## Returns true if valid, false otherwise
static func validate_genotype(genotype: Dictionary, trait_key: String) -> bool:
	if not genotype.has(trait_key):
		push_warning("[GeneticsResolvers] validate_genotype: missing trait '%s'" % trait_key)
		return false

	var alleles = genotype[trait_key]

	if not alleles is Array:
		push_warning("[GeneticsResolvers] validate_genotype: trait '%s' alleles not an array" % trait_key)
		return false

	if alleles.size() != 2:
		push_warning("[GeneticsResolvers] validate_genotype: trait '%s' has %d alleles (expected 2)" % [trait_key, alleles.size()])
		return false

	# Get trait definition to validate alleles
	var trait_def: TraitDef = TraitDB.get_trait_def(trait_key)
	if trait_def == null:
		push_warning("[GeneticsResolvers] validate_genotype: unknown trait '%s'" % trait_key)
		return false

	# Check each allele is valid for this trait
	for allele in alleles:
		if not trait_def.is_allele_valid(str(allele)):
			push_warning("[GeneticsResolvers] validate_genotype: invalid allele '%s' for trait '%s'" % [allele, trait_key])
			return false

	return true


## Validate an entire genotype dictionary
## Checks all traits in the dictionary
static func validate_full_genotype(genotype: Dictionary) -> bool:
	if genotype.is_empty():
		push_warning("[GeneticsResolvers] validate_full_genotype: genotype is empty")
		return false

	for trait_key in genotype.keys():
		if not validate_genotype(genotype, trait_key):
			return false

	return true


## Format a genotype for display in UI
## Example: {"fire": ["F", "f"], "wings": ["w", "W"]} -> "Ff wW"
static func format_genotype_display(genotype: Dictionary) -> String:
	var parts: Array[String] = []

	# Sort trait keys for consistent display
	var sorted_keys: Array = genotype.keys()
	sorted_keys.sort()

	for trait_key in sorted_keys:
		var alleles = genotype[trait_key]
		if alleles is Array and alleles.size() == 2:
			parts.append(normalize_genotype(alleles))
		else:
			parts.append("??")

	return " ".join(parts)


## Format a single trait's genotype for display
## Example: {"fire": ["F", "f"]} -> "Ff"
static func format_trait_display(genotype: Dictionary, trait_key: String) -> String:
	if not genotype.has(trait_key):
		return "??"

	var alleles = genotype[trait_key]
	if alleles is Array and alleles.size() == 2:
		return normalize_genotype(alleles)
	else:
		return "??"


## Get a displayable summary of genotype and phenotype for a dragon
## Returns a formatted string with both genotype and phenotype info
static func format_dragon_genetics(dragon: DragonData) -> String:
	if dragon == null:
		return "No dragon data"

	var lines: Array[String] = []
	lines.append("Genotype:")

	# Sort trait keys for consistent display
	var sorted_keys: Array = dragon.genotype.keys()
	sorted_keys.sort()

	for trait_key in sorted_keys:
		var geno_str: String = format_trait_display(dragon.genotype, trait_key)
		var pheno_str: String = dragon.get_phenotype_name(trait_key)

		# Get trait display name
		var trait_def: TraitDef = TraitDB.get_trait_def(trait_key)
		var trait_name: String = trait_def.name if trait_def else trait_key

		lines.append("  %s: %s (%s)" % [trait_name, geno_str, pheno_str])

	return "\n".join(lines)


## Check if two genotypes are identical (same alleles for all traits)
static func genotypes_equal(genotype_a: Dictionary, genotype_b: Dictionary) -> bool:
	if genotype_a.size() != genotype_b.size():
		return false

	for trait_key in genotype_a.keys():
		if not genotype_b.has(trait_key):
			return false

		var alleles_a: String = normalize_genotype(genotype_a[trait_key])
		var alleles_b: String = normalize_genotype(genotype_b[trait_key])

		if alleles_a != alleles_b:
			return false

	return true


## Extract a single trait's alleles from a genotype
## Returns a 2-element array of allele strings
static func get_trait_alleles(genotype: Dictionary, trait_key: String) -> Array:
	if not genotype.has(trait_key):
		push_warning("[GeneticsResolvers] get_trait_alleles: trait '%s' not found" % trait_key)
		return []

	var alleles = genotype[trait_key]

	# Coerce legacy dictionary format (e.g., {"alleles": [...]})
	if alleles is Dictionary:
		if alleles.has("alleles") and alleles["alleles"] is Array:
			alleles = alleles["alleles"]
		else:
			# Fallback: use values if exactly 2
			var vals: Array = []
			for v in alleles.values():
				vals.append(v)
			if vals.size() == 2:
				alleles = vals
			else:
				push_warning("[GeneticsResolvers] get_trait_alleles: invalid dict format for trait '%s'" % trait_key)
				return []

	# Coerce string formats like "Ff"
	if alleles is String:
		var s: String = alleles
		if s.length() == 2:
			alleles = [s[0], s[1]]
		else:
			push_warning("[GeneticsResolvers] get_trait_alleles: invalid string format for trait '%s': %s" % [trait_key, s])
			return []

	if not alleles is Array or alleles.size() != 2:
		push_warning("[GeneticsResolvers] get_trait_alleles: invalid alleles for trait '%s' (type: %s)" % [trait_key, type_string(typeof(alleles))])
		return []

	return [str(alleles[0]), str(alleles[1])]


## Check if a genotype is homozygous for a specific trait
## Returns true if both alleles are the same
static func is_homozygous(genotype: Dictionary, trait_key: String) -> bool:
	var alleles: Array = get_trait_alleles(genotype, trait_key)
	if alleles.size() != 2:
		return false
	return alleles[0] == alleles[1]


## Check if a genotype is heterozygous for a specific trait
## Returns true if alleles are different
static func is_heterozygous(genotype: Dictionary, trait_key: String) -> bool:
	var alleles: Array = get_trait_alleles(genotype, trait_key)
	if alleles.size() != 2:
		return false
	return alleles[0] != alleles[1]


## Count how many traits are homozygous in a genotype
static func count_homozygous_traits(genotype: Dictionary) -> int:
	var count: int = 0
	for trait_key in genotype.keys():
		if is_homozygous(genotype, trait_key):
			count += 1
	return count


## Check if a genotype has a specific allele for a trait
## Example: has_allele({"fire": ["F", "f"]}, "fire", "F") -> true
static func has_allele(genotype: Dictionary, trait_key: String, allele: String) -> bool:
	var alleles: Array = get_trait_alleles(genotype, trait_key)
	return allele in alleles
