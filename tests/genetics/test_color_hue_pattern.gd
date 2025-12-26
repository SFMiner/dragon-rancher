# test_color_hue_pattern.gd
# Unit tests for three-gene color system (color + hue + pattern)
# Part of Dragon Ranch - Pattern Implementation
#
# Run these tests with: godot --headless --script tests/genetics/test_color_hue_pattern.gd

extends SceneTree


func _init() -> void:
	print("\n========================================")
	print("Running Three-Gene Color System Tests")
	print("========================================\n")

	# Wait for autoloads to initialize
	await get_root().ready

	var passed: int = 0
	var failed: int = 0

	# Run all tests
	if test_epistasis_white_overrides_pattern():
		passed += 1
	else:
		failed += 1

	if test_solid_color_no_pattern():
		passed += 1
	else:
		failed += 1

	if test_striped_color_with_pattern():
		passed += 1
	else:
		failed += 1

	if test_pastel_with_stripes():
		passed += 1
	else:
		failed += 1

	if test_all_sixteen_color_patterns():
		passed += 1
	else:
		failed += 1

	if test_pattern_independent_assortment():
		passed += 1
	else:
		failed += 1

	if test_striped_marker_in_name():
		passed += 1
	else:
		failed += 1

	# Print summary
	print("\n========================================")
	print("Test Results: %d passed, %d failed" % [passed, failed])
	print("========================================\n")

	# Exit with appropriate code
	quit(0 if failed == 0 else 1)


## Test epistasis: WW + any hue + any pattern → White
func test_epistasis_white_overrides_pattern() -> bool:
	print("Test: Epistasis - White overrides hue and pattern")

	var test_cases: Array = [
		{"hue": ["H", "H"], "pattern": ["P", "P"], "desc": "WW + HH + PP"},
		{"hue": ["Ho", "Ho"], "pattern": ["P", "P"], "desc": "WW + HoHo + PP"},
		{"hue": ["Ho", "Ho"], "pattern": ["p", "p"], "desc": "WW + HoHo + pp"},
		{"hue": ["Hg", "Hg"], "pattern": ["p", "p"], "desc": "WW + HgHg + pp"},
	]

	for test_case in test_cases:
		var genotype: Dictionary = {
			"color": ["W", "W"],
			"hue": test_case["hue"],
			"pattern": test_case["pattern"]
		}
		var phenotype: Dictionary = GeneticsEngine.calculate_phenotype(genotype)

		if not phenotype.has("color"):
			print("  FAILED: Missing color phenotype for %s\n" % test_case["desc"])
			return false

		var color_name: String = phenotype["color"]["name"]
		if color_name != "White":
			print("  FAILED: %s should be White, got %s\n" % [test_case["desc"], color_name])
			return false

		print("  ✓ %s → White" % test_case["desc"])

	print("  PASSED: White epistasis works with pattern gene\n")
	return true


## Test pattern without stripes: RR + HoHo + PP → Solid Gold
func test_solid_color_no_pattern() -> bool:
	print("Test: Solid color without pattern (PP)")

	var genotype: Dictionary = {
		"color": ["R", "R"],
		"hue": ["Ho", "Ho"],
		"pattern": ["P", "P"]
	}
	var phenotype: Dictionary = GeneticsEngine.calculate_phenotype(genotype)

	if not phenotype.has("color"):
		print("  FAILED: Missing color phenotype\n")
		return false

	var color_name: String = phenotype["color"]["name"]
	if color_name != "Gold":
		print("  FAILED: RR + HoHo + PP should be Gold, got %s\n" % color_name)
		return false

	# Verify "Striped" is NOT in the name
	if "Striped" in color_name:
		print("  FAILED: Solid color should not contain 'Striped', got %s\n" % color_name)
		return false

	print("  PASSED: RR + HoHo + PP → Gold (solid)\n")
	return true


## Test striped pattern: RR + HoHo + pp → Striped Gold
func test_striped_color_with_pattern() -> bool:
	print("Test: Striped color with pattern (pp)")

	var genotype: Dictionary = {
		"color": ["R", "R"],
		"hue": ["Ho", "Ho"],
		"pattern": ["p", "p"]
	}
	var phenotype: Dictionary = GeneticsEngine.calculate_phenotype(genotype)

	if not phenotype.has("color"):
		print("  FAILED: Missing color phenotype\n")
		return false

	var color_name: String = phenotype["color"]["name"]
	if color_name != "Striped Gold":
		print("  FAILED: RR + HoHo + pp should be Striped Gold, got %s\n" % color_name)
		return false

	# Verify "Striped" IS in the name
	if "Striped" not in color_name:
		print("  FAILED: Striped color should contain 'Striped', got %s\n" % color_name)
		return false

	print("  PASSED: RR + HoHo + pp → Striped Gold\n")
	return true


## Test pastel with stripes: RW + HgHg + pp → Striped Mint
func test_pastel_with_stripes() -> bool:
	print("Test: Pastel striped color (RW + HgHg + pp)")

	var genotype: Dictionary = {
		"color": ["R", "W"],
		"hue": ["Hg", "Hg"],
		"pattern": ["p", "p"]
	}
	var phenotype: Dictionary = GeneticsEngine.calculate_phenotype(genotype)

	if not phenotype.has("color"):
		print("  FAILED: Missing color phenotype\n")
		return false

	var color_name: String = phenotype["color"]["name"]
	if color_name != "Striped Mint":
		print("  FAILED: RW + HgHg + pp should be Striped Mint, got %s\n" % color_name)
		return false

	print("  PASSED: RW + HgHg + pp → Striped Mint\n")
	return true


## Test all 16 color + pattern combinations
func test_all_sixteen_color_patterns() -> bool:
	print("Test: All 16 color + pattern combinations")

	# 8 colors × 2 patterns (solid PP, striped pp) = 16 combinations
	var test_cases: Array = [
		# RR colors (full intensity)
		{"color": ["R", "R"], "hue": ["H", "H"], "pattern": ["P", "P"], "expected": "Red"},
		{"color": ["R", "R"], "hue": ["H", "H"], "pattern": ["p", "p"], "expected": "Striped Red"},
		{"color": ["R", "R"], "hue": ["Ho", "Ho"], "pattern": ["P", "P"], "expected": "Gold"},
		{"color": ["R", "R"], "hue": ["Ho", "Ho"], "pattern": ["p", "p"], "expected": "Striped Gold"},
		{"color": ["R", "R"], "hue": ["Hb", "Hb"], "pattern": ["P", "P"], "expected": "Teal"},
		{"color": ["R", "R"], "hue": ["Hb", "Hb"], "pattern": ["p", "p"], "expected": "Striped Teal"},
		{"color": ["R", "R"], "hue": ["Hg", "Hg"], "pattern": ["P", "P"], "expected": "Jade"},
		{"color": ["R", "R"], "hue": ["Hg", "Hg"], "pattern": ["p", "p"], "expected": "Striped Jade"},
		# RW colors (pastel/diluted)
		{"color": ["R", "W"], "hue": ["H", "H"], "pattern": ["P", "P"], "expected": "Pink"},
		{"color": ["R", "W"], "hue": ["H", "H"], "pattern": ["p", "p"], "expected": "Striped Pink"},
		{"color": ["R", "W"], "hue": ["Ho", "Ho"], "pattern": ["P", "P"], "expected": "Peach"},
		{"color": ["R", "W"], "hue": ["Ho", "Ho"], "pattern": ["p", "p"], "expected": "Striped Peach"},
		{"color": ["R", "W"], "hue": ["Hb", "Hb"], "pattern": ["P", "P"], "expected": "Sky"},
		{"color": ["R", "W"], "hue": ["Hb", "Hb"], "pattern": ["p", "p"], "expected": "Striped Sky"},
		{"color": ["R", "W"], "hue": ["Hg", "Hg"], "pattern": ["P", "P"], "expected": "Mint"},
		{"color": ["R", "W"], "hue": ["Hg", "Hg"], "pattern": ["p", "p"], "expected": "Striped Mint"},
	]

	var success_count: int = 0

	for test_case in test_cases:
		var genotype: Dictionary = {
			"color": test_case["color"],
			"hue": test_case["hue"],
			"pattern": test_case["pattern"]
		}
		var phenotype: Dictionary = GeneticsEngine.calculate_phenotype(genotype)

		if not phenotype.has("color"):
			print("  FAILED: Missing color phenotype for %s\n" % test_case["expected"])
			return false

		var color_name: String = phenotype["color"]["name"]
		if color_name != test_case["expected"]:
			print("  FAILED: Expected %s, got %s\n" % [test_case["expected"], color_name])
			return false

		success_count += 1

	print("  ✓ All %d color + pattern combinations correct" % success_count)
	print("  PASSED: All 16 phenotypes correct\n")
	return true


## Test independent assortment: pattern segregates independently from color/hue
func test_pattern_independent_assortment() -> bool:
	print("Test: Pattern independent assortment")

	# Set seed for deterministic breeding
	RNGService.set_seed(42)

	# Create two dragons with known genotypes
	var dragon_a = DragonData.new()
	dragon_a.id = "test_dragon_a"
	dragon_a.name = "Dragon A"
	dragon_a.genotype = {
		"fire": ["F", "f"],
		"wings": ["w", "w"],
		"armor": ["A", "a"],
		"color": ["R", "R"],
		"hue": ["Ho", "Ho"],
		"pattern": ["P", "p"]  # Heterozygous - can pass P or p
	}
	dragon_a.phenotype = GeneticsEngine.calculate_phenotype(dragon_a.genotype)
	dragon_a.life_stage = "adult"

	var dragon_b = DragonData.new()
	dragon_b.id = "test_dragon_b"
	dragon_b.name = "Dragon B"
	dragon_b.genotype = {
		"fire": ["F", "f"],
		"wings": ["w", "w"],
		"armor": ["A", "a"],
		"color": ["R", "R"],
		"hue": ["Ho", "Ho"],
		"pattern": ["p", "p"]  # Homozygous recessive - only passes p
	}
	dragon_b.phenotype = GeneticsEngine.calculate_phenotype(dragon_b.genotype)
	dragon_b.life_stage = "adult"

	# Breed them multiple times to see pattern segregation
	var pattern_counts: Dictionary = {
		"PP": 0,
		"Pp": 0,
		"pp": 0
	}

	for i in range(20):
		var offspring_genotype: Dictionary = GeneticsEngine.breed_dragons(dragon_a, dragon_b)

		# Track pattern genotype
		if offspring_genotype.has("pattern"):
			var pattern_alleles: Array = offspring_genotype["pattern"]
			var pattern_normalized: String = GeneticsResolvers.normalize_genotype(pattern_alleles)
			if pattern_normalized in pattern_counts:
				pattern_counts[pattern_normalized] += 1

	# With these parents, we expect roughly 50% Pp and 50% pp
	# (assuming P comes from Dragon A ~50% of the time)
	var pp_count: int = pattern_counts["pp"]
	var pp_percentage: float = float(pp_count) / 20.0 * 100.0

	print("  Pattern segregation over 20 offspring:")
	print("    PP: %d (%.1f%%)" % [pattern_counts["PP"], float(pattern_counts["PP"]) / 20.0 * 100.0])
	print("    Pp: %d (%.1f%%)" % [pattern_counts["Pp"], float(pattern_counts["Pp"]) / 20.0 * 100.0])
	print("    pp: %d (%.1f%%)" % [pattern_counts["pp"], pp_percentage])

	# Verify we got both solid (P_) and striped (pp) offspring
	if pattern_counts["pp"] == 0 or (pattern_counts["PP"] + pattern_counts["Pp"]) == 0:
		print("  FAILED: Expected both solid and striped offspring\n")
		return false

	print("  PASSED: Pattern segregates independently\n")
	return true


## Test striped marker appears in phenotype name
func test_striped_marker_in_name() -> bool:
	print("Test: Striped marker in phenotype name")

	# Test that all striped phenotypes have "Striped" prefix
	var striped_cases: Array = [
		{"color": ["R", "R"], "hue": ["H", "H"], "pattern": ["p", "p"]},
		{"color": ["R", "W"], "hue": ["Ho", "Ho"], "pattern": ["p", "p"]},
		{"color": ["R", "R"], "hue": ["Hb", "Hb"], "pattern": ["p", "p"]},
	]

	for test_case in striped_cases:
		var genotype: Dictionary = {
			"color": test_case["color"],
			"hue": test_case["hue"],
			"pattern": test_case["pattern"]
		}
		var phenotype: Dictionary = GeneticsEngine.calculate_phenotype(genotype)

		if not phenotype.has("color"):
			print("  FAILED: Missing color phenotype\n")
			return false

		var color_name: String = phenotype["color"]["name"]
		if "Striped" not in color_name:
			print("  FAILED: Striped phenotype missing 'Striped' prefix: %s\n" % color_name)
			return false

		print("  ✓ %s has Striped prefix" % color_name)

	# Test that solid phenotypes do NOT have "Striped"
	var solid_cases: Array = [
		{"color": ["R", "R"], "hue": ["H", "H"], "pattern": ["P", "P"]},
		{"color": ["R", "W"], "hue": ["Ho", "Ho"], "pattern": ["P", "P"]},
	]

	for test_case in solid_cases:
		var genotype: Dictionary = {
			"color": test_case["color"],
			"hue": test_case["hue"],
			"pattern": test_case["pattern"]
		}
		var phenotype: Dictionary = GeneticsEngine.calculate_phenotype(genotype)

		var color_name: String = phenotype["color"]["name"]
		if "Striped" in color_name:
			print("  FAILED: Solid phenotype should not have 'Striped': %s\n" % color_name)
			return false

		print("  ✓ %s has no Striped prefix" % color_name)

	print("  PASSED: Striped marker correct in all phenotypes\n")
	return true
