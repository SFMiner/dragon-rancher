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

	# Also include any newly unlocked traits at current reputation level
	# This ensures new traits (like pattern at reputation 2) are added to offspring
	if RanchState:
		var currently_unlocked: Array[String] = TraitDB.get_unlocked_traits(RanchState.reputation)
		for trait_key in currently_unlocked:
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
	if genotype == null or genotype.is_empty():
		push_error("[GeneticsEngine] calculate_phenotype: invalid genotype")
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
		var alleles: Array = _coerce_alleles(genotype[trait_key], trait_key)
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

	# === ADD THIS NEW SECTION ===
	# Calculate combined color phenotype if both loci present
	if genotype.has("color") and genotype.has("hue"):
		var color_pheno: Dictionary = calculate_color_phenotype(genotype)
		# Override the individual color phenotype with combined result
		phenotype["color"] = color_pheno
		# Remove hue from phenotype display since it's now combined into color
		phenotype.erase("hue")
		if debug_mode:
			print("  Combined Color: %s (%s hue, %s base)" % [
				color_pheno.get("name", "Unknown"),
				color_pheno.get("hue", "unknown"),
				color_pheno.get("base_color", "unknown")
			])

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

	var alleles: Array = _coerce_alleles(parent.genotype[trait_key], trait_key)
	if alleles.size() != 2:
		push_warning("[GeneticsEngine] Invalid alleles for parent trait '%s'" % trait_key)
		return ""

	# Randomly select one allele (50% chance for each)
	var index: int = RNGService.randi_range(0, 1)
	return str(alleles[index])


## Create a starter dragon with default genotype
## reputation_level: Current player reputation (determines unlocked traits)
## Returns: DragonData
func create_starter_dragon(reputation_level: int) -> DragonData:
	var dragon: DragonData = DragonData.new()
	dragon.genotype = TraitDB.get_default_genotype(reputation_level)
	dragon.phenotype = calculate_phenotype(dragon.genotype)
	dragon.life_stage = "adult"
	dragon.age = 4  # Young adult
	dragon.health = 100.0
	dragon.happiness = 100.0
	return dragon


## Create a random dragon with random genotype
## reputation_level: Current player reputation (determines unlocked traits)
## Returns: DragonData
func create_random_dragon(reputation_level: int) -> DragonData:
	var dragon: DragonData = DragonData.new()
	dragon.genotype = TraitDB.get_random_genotype(reputation_level)
	dragon.phenotype = calculate_phenotype(dragon.genotype)
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
		if parent_a.life_stage != "adult":
			return {"success": false, "reason": "%s cannot breed (wrong life stage)" % parent_a.name}
		elif parent_a.health < 20.0:
			return {"success": false, "reason": "%s cannot breed (health too low)" % parent_a.name}
		elif parent_a.happiness < 40.0:
			return {"success": false, "reason": "%s cannot breed (happiness too low: %.0f%%)" % [parent_a.name, parent_a.happiness]}
		else:
			return {"success": false, "reason": "%s cannot breed" % parent_a.name}

	if not parent_b.can_breed():
		if parent_b.life_stage != "adult":
			return {"success": false, "reason": "%s cannot breed (wrong life stage)" % parent_b.name}
		elif parent_b.health < 20.0:
			return {"success": false, "reason": "%s cannot breed (health too low)" % parent_b.name}
		elif parent_b.happiness < 40.0:
			return {"success": false, "reason": "%s cannot breed (happiness too low: %.0f%%)" % [parent_b.name, parent_b.happiness]}
		else:
			return {"success": false, "reason": "%s cannot breed" % parent_b.name}

	if parent_a == parent_b or (not parent_a.id.is_empty() and parent_a.id == parent_b.id):
		return {"success": false, "reason": "A dragon cannot breed with itself"}

	if parent_a.breedings_this_season >= 2:
		return {"success": false, "reason": "%s has reached the breeding limit for this season" % parent_a.name}

	if parent_b.breedings_this_season >= 2:
		return {"success": false, "reason": "%s has reached the breeding limit for this season" % parent_b.name}

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
	var s_alleles: Array = _coerce_alleles(genotype.get("size_S", []), "size_S")
	for allele in s_alleles:
		if allele == "S":
			dominant_count += 1

	# Count G alleles
	var g_alleles: Array = _coerce_alleles(genotype.get("size_G", []), "size_G")
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


## Helper to safely read allele arrays, handling legacy dictionary formats
func _coerce_alleles(value, trait_key: String) -> Array:
	if value is Array:
		return value

	if value is Dictionary:
		# Legacy format: {"alleles": ["A","a"]}
		if value.has("alleles") and value["alleles"] is Array:
			return value["alleles"]

		# Fallback: use dictionary values if exactly 2 entries
		var vals: Array = []
		for v in value.values():
			vals.append(v)
		if vals.size() == 2:
			push_warning("[GeneticsEngine] Trait '%s' genotype stored as dict; coerced to array" % trait_key)
			return vals

	push_warning("[GeneticsEngine] Trait '%s' genotype not array/dict, got %s" % [trait_key, type_string(typeof(value))])
	return []


## Calculate combined color phenotype from color + hue genes
## Demonstrates epistasis: WW is always white regardless of hue
## genotype: Dictionary with both "color" and "hue" keys
## Returns: Dictionary with combined phenotype data
## Calculate combined color phenotype from color + hue + pattern genes
## Demonstrates epistasis and independent assortment
## genotype: Dictionary with "color", "hue", and optionally "pattern" keys
## Returns: Dictionary with combined phenotype data
func calculate_color_phenotype(genotype: Dictionary) -> Dictionary:
	if not genotype.has("color") or not genotype.has("hue"):
		push_warning("[GeneticsEngine] calculate_color_phenotype: missing color or hue locus")
		return {}

	# Get individual trait definitions
	var color_def: TraitDef = TraitDB.get_trait_def("color")
	var hue_def: TraitDef = TraitDB.get_trait_def("hue")

	if color_def == null or hue_def == null:
		push_error("[GeneticsEngine] calculate_color_phenotype: missing trait definitions")
		return {}

	# Get alleles and normalize
	var color_alleles: Array = _coerce_alleles(genotype["color"], "color")
	var hue_alleles: Array = _coerce_alleles(genotype["hue"], "hue")

	var color_normalized: String = GeneticsResolvers.normalize_genotype_by_dominance(color_alleles, color_def)
	var hue_normalized: String = GeneticsResolvers.normalize_genotype_by_dominance(hue_alleles, hue_def)

	# Get base color phenotype
	var color_pheno: Dictionary = color_def.get_phenotype_data(color_normalized)
	var hue_pheno: Dictionary = hue_def.get_phenotype_data(hue_normalized)

	if color_pheno.is_empty() or hue_pheno.is_empty():
		push_error("[GeneticsEngine] calculate_color_phenotype: missing phenotype data")
		return {}

	# Check for pattern gene (optional)
	var has_stripes: bool = false
	if genotype.has("pattern"):
		var pattern_def: TraitDef = TraitDB.get_trait_def("pattern")
		if pattern_def != null:
			var pattern_alleles: Array = _coerce_alleles(genotype["pattern"], "pattern")
			var pattern_normalized: String = GeneticsResolvers.normalize_genotype_by_dominance(pattern_alleles, pattern_def)
			# pp = striped, PP or Pp = solid
			has_stripes = (pattern_normalized == "pp")

	# EPISTASIS: WW is always white, hue and pattern have no effect
	if color_normalized == "WW":
		return {
			"name": "White",
			"sprite_suffix": "white",
			"color": Color.from_string("#F5F5F5", Color.WHITE),
			"description": "Pure white - no pigment to modify",
			"base_color": "white",
			"hue": "none",
			"pattern": "none"
		}

	# Extract hue name from hue phenotype
	var hue_name: String = hue_pheno.get("hue_name", "red")
	var hue_color: Color = hue_pheno.get("color", Color.WHITE)

	# Determine intensity based on base color (RR = full, RW = pastel)
	var is_full_intensity: bool = (color_normalized == "RR")

	# Color mapping for full intensity (RR)
	var full_colors: Dictionary = {
		"red": {"name": "Red", "color": "#E63946", "desc": "Bright red scales"},
		"gold": {"name": "Gold", "color": "#FFB627", "desc": "Shimmering gold scales"},
		"teal": {"name": "Teal", "color": "#1B9AAA", "desc": "Deep teal scales"},
		"jade": {"name": "Jade", "color": "#06A77D", "desc": "Rich jade green scales"}
	}

	# Color mapping for pastel intensity (RW)
	var pastel_colors: Dictionary = {
		"red": {"name": "Pink", "color": "#F2A2B0", "desc": "Soft pink scales"},
		"gold": {"name": "Peach", "color": "#FFD4A3", "desc": "Delicate peach scales"},
		"teal": {"name": "Sky", "color": "#89CFF0", "desc": "Pale sky blue scales"},
		"jade": {"name": "Mint", "color": "#98D8C8", "desc": "Gentle mint green scales"}
	}

	# Select appropriate color data
	var color_map: Dictionary = full_colors if is_full_intensity else pastel_colors
	var final_data: Dictionary = color_map.get(hue_name, color_map["red"])

	# Modify name and description if striped
	var display_name: String = final_data["name"]
	var description: String = final_data["desc"]
	var sprite_suffix: String = hue_name if is_full_intensity else ("pastel_" + hue_name)

	if has_stripes:
		display_name = "Striped " + display_name
		description = final_data["desc"].replace("scales", "scales with white stripes")
		sprite_suffix += "_striped"

	return {
		"name": display_name,
		"sprite_suffix": sprite_suffix,
		"color": Color.from_string(final_data["color"], Color.WHITE),
		"description": description,
		"base_color": "pigmented" if is_full_intensity else "diluted",
		"hue": hue_name,
		"pattern": "striped" if has_stripes else "solid"
	}
