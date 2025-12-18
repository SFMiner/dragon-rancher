# GeneticsEngine.gd
# Core genetics engine - handles breeding and phenotype calculation
# Part of Dragon Ranch - Session 2 Core Genetics Engine
#
# This is the mathematical heart of the game and must be deterministic

extends Node

## Debug mode - logs all breeding operations
var debug_mode: bool = false


## Breed two dragons and return offspring genotype
## parent_a: DragonData for first parent
## parent_b: DragonData for second parent
## Returns: Dictionary with offspring genotype (trait_key -> [allele1, allele2])
func breed_dragons(parent_a: DragonData, parent_b: DragonData) -> Dictionary:
	if parent_a == null or parent_b == null:
		push_error("[GeneticsEngine] breed_dragons: null parent data")
		return {}

	if not parent_a.is_valid() or not parent_b.is_valid():
		push_error("[GeneticsEngine] breed_dragons: invalid parent data")
		return {}

	if debug_mode:
		print("[GeneticsEngine] Breeding:")
		print("  Parent A: %s (ID: %s)" % [parent_a.name, parent_a.id])
		print("  Parent B: %s (ID: %s)" % [parent_b.name, parent_b.id])
		print("  Seed: %d" % RNGService.get_seed())

	var offspring_genotype: Dictionary = {}

	# Get all trait keys from both parents (in case they have different traits)
	var all_trait_keys: Dictionary = {}
	for trait_key in parent_a.genotype.keys():
		all_trait_keys[trait_key] = true
	for trait_key in parent_b.genotype.keys():
		all_trait_keys[trait_key] = true

	# For each trait, randomly select one allele from each parent
	for trait_key in all_trait_keys.keys():
		var allele_from_a: String = _get_random_allele_from_parent(parent_a, trait_key)
		var allele_from_b: String = _get_random_allele_from_parent(parent_b, trait_key)

		if allele_from_a.is_empty() or allele_from_b.is_empty():
			push_warning("[GeneticsEngine] Missing allele for trait '%s', using defaults" % trait_key)
			continue

		offspring_genotype[trait_key] = [allele_from_a, allele_from_b]

		if debug_mode:
			print("  Trait '%s': %s + %s -> [%s, %s]" % [
				trait_key,
				GeneticsResolvers.format_trait_display(parent_a.genotype, trait_key),
				GeneticsResolvers.format_trait_display(parent_b.genotype, trait_key),
				allele_from_a,
				allele_from_b
			])

	return offspring_genotype


## Calculate phenotype from genotype
## genotype: Dictionary (trait_key -> [allele1, allele2])
## Returns: Dictionary (trait_key -> phenotype_data)
func calculate_phenotype(genotype: Dictionary) -> Dictionary:
	if genotype.is_empty():
		push_error("[GeneticsEngine] calculate_phenotype: empty genotype")
		return {}

	if debug_mode:
		print("[GeneticsEngine] Calculating phenotype for genotype: %s" % GeneticsResolvers.format_genotype_display(genotype))

	var phenotype: Dictionary = {}

	for trait_key in genotype.keys():
		# Get trait definition
		var trait_def: TraitDef = TraitDB.get_trait_def(trait_key)
		if trait_def == null:
			push_warning("[GeneticsEngine] Unknown trait '%s' in genotype" % trait_key)
			continue

		# Get alleles for this trait
		var alleles: Array = genotype[trait_key]
		if alleles.size() != 2:
			push_warning("[GeneticsEngine] Invalid alleles for trait '%s'" % trait_key)
			continue

		# Normalize genotype for lookup
		var normalized: String = GeneticsResolvers.normalize_genotype_by_dominance(alleles, trait_def)

		# Look up phenotype data
		var pheno_data: Dictionary = trait_def.get_phenotype_data(normalized)
		if pheno_data.is_empty():
			push_error("[GeneticsEngine] No phenotype data for genotype '%s' of trait '%s'" % [normalized, trait_key])
			continue

		phenotype[trait_key] = pheno_data.duplicate()

		if debug_mode:
			print("  Trait '%s': %s -> %s" % [trait_key, normalized, pheno_data.get("name", "Unknown")])

	# Calculate combined size phenotype if both loci present
	if genotype.has("size_S") and genotype.has("size_G"):
		var size_pheno: Dictionary = calculate_size_phenotype(genotype)
		phenotype["size"] = size_pheno
		if debug_mode:
			print("  Combined Size: %s (scale: %.1fx)" % [size_pheno.get("name", "Unknown"), size_pheno.get("scale_factor", 1.0)])

	return phenotype


## Generate a Punnett square for a specific trait
## parent_a: DragonData for first parent
## parent_b: DragonData for second parent
## trait_key: Which trait to analyze
## Returns: Array of outcome dictionaries with genotype, phenotype, and probability
func generate_punnett_square(parent_a: DragonData, parent_b: DragonData, trait_key: String) -> Array:
	if parent_a == null or parent_b == null:
		push_error("[GeneticsEngine] generate_punnett_square: null parent data")
		return []

	if trait_key.is_empty():
		push_error("[GeneticsEngine] generate_punnett_square: empty trait_key")
		return []

	# Get trait definition
	var trait_def: TraitDef = TraitDB.get_trait_def(trait_key)
	if trait_def == null:
		push_error("[GeneticsEngine] generate_punnett_square: unknown trait '%s'" % trait_key)
		return []

	# Get alleles from both parents
	var parent_a_alleles: Array = GeneticsResolvers.get_trait_alleles(parent_a.genotype, trait_key)
	var parent_b_alleles: Array = GeneticsResolvers.get_trait_alleles(parent_b.genotype, trait_key)

	if parent_a_alleles.is_empty() or parent_b_alleles.is_empty():
		push_error("[GeneticsEngine] generate_punnett_square: missing alleles for trait '%s'" % trait_key)
		return []

	# Generate all possible combinations (2x2 = 4 outcomes)
	var outcomes: Array = []
	for allele_a in parent_a_alleles:
		for allele_b in parent_b_alleles:
			var offspring_alleles: Array = [allele_a, allele_b]
			var normalized: String = GeneticsResolvers.normalize_genotype_by_dominance(offspring_alleles, trait_def)
			var pheno_data: Dictionary = trait_def.get_phenotype_data(normalized)

			outcomes.append({
				"genotype": normalized,
				"phenotype": pheno_data.get("name", "Unknown"),
				"phenotype_data": pheno_data,
				"alleles": offspring_alleles
			})

	# Calculate probabilities
	var outcome_counts: Dictionary = {}
	for outcome in outcomes:
		var key: String = outcome["genotype"]
		if not outcome_counts.has(key):
			outcome_counts[key] = 0
		outcome_counts[key] += 1

	# Create final results with probabilities
	var results: Array = []
	var processed: Dictionary = {}

	for outcome in outcomes:
		var key: String = outcome["genotype"]
		if processed.has(key):
			continue

		var count: int = outcome_counts[key]
		var probability: float = count / 4.0

		results.append({
			"genotype": outcome["genotype"],
			"phenotype": outcome["phenotype"],
			"phenotype_data": outcome["phenotype_data"],
			"probability": probability,
			"count": count,
			"total": 4
		})

		processed[key] = true

	if debug_mode:
		print("[GeneticsEngine] Punnett square for trait '%s':" % trait_key)
		for result in results:
			print("  %s (%s): %.1f%% (%d/4)" % [
				result["genotype"],
				result["phenotype"],
				result["probability"] * 100.0,
				result["count"]
			])

	return results


## Generate Punnett squares for all traits
## Returns: Dictionary (trait_key -> Array of outcomes)
func generate_full_punnett_square(parent_a: DragonData, parent_b: DragonData) -> Dictionary:
	if parent_a == null or parent_b == null:
		push_error("[GeneticsEngine] generate_full_punnett_square: null parent data")
		return {}

	var result: Dictionary = {}

	# Get all trait keys from both parents
	var all_trait_keys: Dictionary = {}
	for trait_key in parent_a.genotype.keys():
		all_trait_keys[trait_key] = true
	for trait_key in parent_b.genotype.keys():
		all_trait_keys[trait_key] = true

	# Generate Punnett square for each trait
	for trait_key in all_trait_keys.keys():
		result[trait_key] = generate_punnett_square(parent_a, parent_b, trait_key)

	return result


## Helper: Get a random allele from a parent for a specific trait
## Returns empty string if trait not found or invalid
func _get_random_allele_from_parent(parent: DragonData, trait_key: String) -> String:
	if not parent.genotype.has(trait_key):
		# Parent doesn't have this trait, try to use default
		var trait_def: TraitDef = TraitDB.get_trait_def(trait_key)
		if trait_def == null:
			return ""
		# Return recessive allele as default
		return trait_def.get_recessive_allele()

	var alleles: Array = parent.genotype[trait_key]
	if alleles.size() != 2:
		push_warning("[GeneticsEngine] Invalid alleles for parent trait '%s'" % trait_key)
		return ""

	# Randomly select one allele (50% chance for each)
	var index: int = RNGService.randi_range(0, 1)
	return str(alleles[index])


## Create a starter dragon with default genotype
## reputation_level: Current player reputation (determines unlocked traits)
## sex: "male" or "female"
## Returns: DragonData
func create_starter_dragon(reputation_level: int, sex: String) -> DragonData:
	var dragon: DragonData = DragonData.new()
	dragon.genotype = TraitDB.get_default_genotype(reputation_level)
	dragon.phenotype = calculate_phenotype(dragon.genotype)
	dragon.sex = sex
	dragon.life_stage = "adult"
	dragon.age = 4  # Young adult
	dragon.health = 100.0
	dragon.happiness = 100.0
	return dragon


## Create a random dragon with random genotype
## reputation_level: Current player reputation (determines unlocked traits)
## sex: "male" or "female"
## Returns: DragonData
func create_random_dragon(reputation_level: int, sex: String) -> DragonData:
	var dragon: DragonData = DragonData.new()
	dragon.genotype = TraitDB.get_random_genotype(reputation_level)
	dragon.phenotype = calculate_phenotype(dragon.genotype)
	dragon.sex = sex
	dragon.life_stage = "adult"
	dragon.age = 4  # Young adult
	dragon.health = 100.0
	dragon.happiness = 100.0
	return dragon


## Validate that breeding is possible between two dragons
## Returns: Dictionary with {success: bool, reason: String}
func can_breed(parent_a: DragonData, parent_b: DragonData) -> Dictionary:
	if parent_a == null or parent_b == null:
		return {"success": false, "reason": "Missing parent data"}

	if not parent_a.can_breed():
		return {"success": false, "reason": "%s cannot breed (wrong stage or health)" % parent_a.name}

	if not parent_b.can_breed():
		return {"success": false, "reason": "%s cannot breed (wrong stage or health)" % parent_b.name}

	if parent_a.sex == parent_b.sex:
		return {"success": false, "reason": "Both parents are the same sex"}

	return {"success": true, "reason": "Breeding is possible"}


## Calculate combined size from multi-locus size genes
## genotype: Dictionary with genotype data
## Returns: Dictionary with size category and scale factor
func calculate_size_phenotype(genotype: Dictionary) -> Dictionary:
	if not genotype.has("size_S") or not genotype.has("size_G"):
		# No size genes, return default medium size
		return {
			"name": "Medium",
			"scale_factor": 1.0,
			"description": "Standard dragon size"
		}

	# Count dominant alleles
	var dominant_count: int = 0

	# Count S alleles
	var s_alleles: Array = genotype.get("size_S", [])
	for allele in s_alleles:
		if allele == "S":
			dominant_count += 1

	# Count G alleles
	var g_alleles: Array = genotype.get("size_G", [])
	for allele in g_alleles:
		if allele == "G":
			dominant_count += 1

	# Map dominant count to size category
	match dominant_count:
		4:  # SSGG
			return {
				"name": "Extra Large",
				"scale_factor": 2.0,
				"description": "Massive dragon (SSGG)"
			}
		3:  # SSGg or SsGG
			return {
				"name": "Large",
				"scale_factor": 1.5,
				"description": "Large dragon (3 dominant alleles)"
			}
		2:  # SsGg, SSgg, or ssGG
			return {
				"name": "Medium",
				"scale_factor": 1.0,
				"description": "Standard dragon size (2 dominant alleles)"
			}
		1:  # Ssgg or ssGg
			return {
				"name": "Small",
				"scale_factor": 0.75,
				"description": "Small dragon (1 dominant allele)"
			}
		0:  # ssgg
			return {
				"name": "Tiny",
				"scale_factor": 0.5,
				"description": "Tiny dragon (ssgg)"
			}
		_:
			return {
				"name": "Medium",
				"scale_factor": 1.0,
				"description": "Standard dragon size"
			}
