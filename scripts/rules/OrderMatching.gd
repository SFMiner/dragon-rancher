# OrderMatching.gd
# Order matching logic for dragon-to-order compatibility
# Part of Dragon Ranch - Session 6 Order System

class_name OrderMatching


## Check if a dragon matches an order's requirements
static func does_dragon_match(dragon: DragonData, order: OrderData) -> bool:
	if dragon == null or order == null:
		return false

	# Check each required trait
	for trait_key in order.required_traits.keys():
		var requirement: String = order.required_traits[trait_key]

		if not _check_trait_requirement(dragon, trait_key, requirement):
			return false

	return true


## Check if dragon meets requirement for a specific trait
static func _check_trait_requirement(dragon: DragonData, trait_key: String, requirement: String) -> bool:
	# Check dragon has this trait
	if not dragon.genotype.has(trait_key):
		return false

	var alleles: Array = GeneticsResolvers.get_trait_alleles(dragon.genotype, trait_key)
	if alleles.size() != 2:
		return false

	# Normalize genotype
	var normalized: String = GeneticsResolvers.normalize_genotype(alleles)

	# Parse requirement pattern
	if requirement.ends_with("_"):
		# Dominant allele present (e.g., "F_" or multi-char like "D1_")
		var required_allele: String = requirement.substr(0, requirement.length() - 1)
		for allele in alleles:
			if str(allele) == required_allele:
				return true
		return false

	elif requirement.length() == 2:
		# Exact genotype match (e.g., "FF", "Ff", "ff")
		var req_normalized: String = GeneticsResolvers.normalize_genotype([requirement[0], requirement[1]])
		return normalized == req_normalized

	else:
		# Phenotype name match, tolerant to dict/string
		if not dragon.phenotype.has(trait_key):
			return false

		var pheno = dragon.phenotype[trait_key]
		var pheno_name: String = ""
		if pheno is Dictionary:
			pheno_name = pheno.get("name", "").to_lower()
		elif pheno is String:
			pheno_name = pheno.to_lower()
		else:
			return false
		return pheno_name == requirement.to_lower()


## Get list of matching dragons for an order
static func get_matching_dragons(dragons: Array[DragonData], order: OrderData) -> Array[DragonData]:
	var matches: Array[DragonData] = []

	for dragon in dragons:
		if does_dragon_match(dragon, order):
			matches.append(dragon)

	return matches


## Get match score (0.0 to 1.0) for partial matches
static func get_match_score(dragon: DragonData, order: OrderData) -> float:
	if dragon == null or order == null:
		return 0.0

	var total_requirements: int = order.required_traits.size()
	if total_requirements == 0:
		return 0.0

	var matches: int = 0

	for trait_key in order.required_traits.keys():
		var requirement: String = order.required_traits[trait_key]
		if _check_trait_requirement(dragon, trait_key, requirement):
			matches += 1

	return float(matches) / float(total_requirements)
