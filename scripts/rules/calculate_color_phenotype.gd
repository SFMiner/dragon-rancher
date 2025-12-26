## Calculate combined color phenotype from color + hue genes
## Demonstrates epistasis: WW is always white regardless of hue
## genotype: Dictionary with both "color" and "hue" keys
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

	# EPISTASIS: WW is always white, hue has no effect
	if color_normalized == "WW":
		return {
			"name": "White",
			"sprite_suffix": "white",
			"color": Color.from_string("#F5F5F5", Color.WHITE),
			"description": "Pure white - no pigment to modify",
			"base_color": "white",
			"hue": "none"
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

	return {
		"name": final_data["name"],
		"sprite_suffix": hue_name if is_full_intensity else ("pastel_" + hue_name),
		"color": Color.from_string(final_data["color"], Color.WHITE),
		"description": final_data["desc"],
		"base_color": "pigmented" if is_full_intensity else "diluted",
		"hue": hue_name
	}
