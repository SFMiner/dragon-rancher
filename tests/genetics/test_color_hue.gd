# test_color_hue.gd
# Unit tests for color + hue genetics interaction
# Part of Dragon Ranch - Hue Modifier Implementation
#
# Run these tests with: godot --headless --script tests/genetics/test_color_hue.gd

extends SceneTree


func _init() -> void:
	print("\n========================================")
	print("Running Color + Hue Genetics Tests")
	print("========================================\n")

	# Wait for autoloads to initialize
	await get_root().ready

	var passed: int = 0
	var failed: int = 0

	# Run all tests
	if test_epistasis_white_overrides_hue():
		passed += 1
	else:
		failed += 1

	if test_full_intensity_rr_homozygous():
		passed += 1
	else:
		failed += 1

	if test_pastel_intensity_rw_heterozygous():
		passed += 1
	else:
		failed += 1

	if test_hue_dominance_hierarchy():
		passed += 1
	else:
		failed += 1

	if test_all_eight_combined_colors():
		passed += 1
	else:
		failed += 1

	if test_hue_no_effect_on_white():
		passed += 1
	else:
		failed += 1

	# Print summary
	print("\n========================================")
	print("Test Results: %d passed, %d failed" % [passed, failed])
	print("========================================\n")

	# Exit with appropriate code
	quit(0 if failed == 0 else 1)


## Test epistasis: WW + HoHo → White (hue has no effect)
func test_epistasis_white_overrides_hue() -> bool:
	print("Test: Epistasis - White overrides hue")

	# White homozygous + any hue
	var genotype: Dictionary = {
		"color": ["W", "W"],
		"hue": ["Ho", "Ho"]
	}
	var phenotype: Dictionary = GeneticsEngine.calculate_phenotype(genotype)

	if not phenotype.has("color"):
		print("  FAILED: Missing color phenotype\n")
		return false

	var color_name: String = phenotype["color"]["name"]
	if color_name != "White":
		print("  FAILED: WW should be White regardless of hue, got %s\n" % color_name)
		return false

	print("  PASSED: White (WW) overrides hue modifier (Ho/Ho)\n")
	return true


## Test full intensity: RR + HoHo → Gold
func test_full_intensity_rr_homozygous() -> bool:
	print("Test: Full intensity - RR + HoHo → Gold")

	var genotype: Dictionary = {
		"color": ["R", "R"],
		"hue": ["Ho", "Ho"]
	}
	var phenotype: Dictionary = GeneticsEngine.calculate_phenotype(genotype)

	if not phenotype.has("color"):
		print("  FAILED: Missing color phenotype\n")
		return false

	var color_name: String = phenotype["color"]["name"]
	if color_name != "Gold":
		print("  FAILED: RR + HoHo should be Gold, got %s\n" % color_name)
		return false

	print("  PASSED: Full red (RR) with Gold modifier (HoHo) → Gold\n")
	return true


## Test pastel intensity: RW + HgHg → Mint
func test_pastel_intensity_rw_heterozygous() -> bool:
	print("Test: Pastel intensity - RW + HgHg → Mint")

	var genotype: Dictionary = {
		"color": ["R", "W"],
		"hue": ["Hg", "Hg"]
	}
	var phenotype: Dictionary = GeneticsEngine.calculate_phenotype(genotype)

	if not phenotype.has("color"):
		print("  FAILED: Missing color phenotype\n")
		return false

	var color_name: String = phenotype["color"]["name"]
	if color_name != "Mint":
		print("  FAILED: RW + HgHg should be Mint, got %s\n" % color_name)
		return false

	print("  PASSED: Pastel red (RW) with Mint modifier (HgHg) → Mint\n")
	return true


## Test hue dominance hierarchy: H > Ho > Hb > Hg
func test_hue_dominance_hierarchy() -> bool:
	print("Test: Hue dominance hierarchy")

	# Test H dominant over Ho
	var genotype_h_ho: Dictionary = {
		"color": ["R", "R"],
		"hue": ["H", "Ho"]
	}
	var phenotype_h_ho: Dictionary = GeneticsEngine.calculate_phenotype(genotype_h_ho)

	var color_name_h_ho: String = phenotype_h_ho["color"]["name"]
	if color_name_h_ho != "Red":
		print("  FAILED: RR + HHo should be Red (H dominant), got %s\n" % color_name_h_ho)
		return false

	# Test Ho dominant over Hb
	var genotype_ho_hb: Dictionary = {
		"color": ["R", "R"],
		"hue": ["Ho", "Hb"]
	}
	var phenotype_ho_hb: Dictionary = GeneticsEngine.calculate_phenotype(genotype_ho_hb)

	var color_name_ho_hb: String = phenotype_ho_hb["color"]["name"]
	if color_name_ho_hb != "Gold":
		print("  FAILED: RR + HoHb should be Gold (Ho dominant), got %s\n" % color_name_ho_hb)
		return false

	# Test Hb dominant over Hg
	var genotype_hb_hg: Dictionary = {
		"color": ["R", "R"],
		"hue": ["Hb", "Hg"]
	}
	var phenotype_hb_hg: Dictionary = GeneticsEngine.calculate_phenotype(genotype_hb_hg)

	var color_name_hb_hg: String = phenotype_hb_hg["color"]["name"]
	if color_name_hb_hg != "Teal":
		print("  FAILED: RR + HbHg should be Teal (Hb dominant), got %s\n" % color_name_hb_hg)
		return false

	print("  PASSED: Hue hierarchy correct (H > Ho > Hb > Hg)\n")
	return true


## Test all eight combined colors
func test_all_eight_combined_colors() -> bool:
	print("Test: All eight combined colors")

	var expected_colors: Array[String] = [
		"Red",      # RR + HH
		"Gold",     # RR + HoHo
		"Teal",     # RR + HbHb
		"Jade",     # RR + HgHg
		"Pink",     # RW + HH
		"Peach",    # RW + HoHo
		"Sky",      # RW + HbHb
		"Mint"      # RW + HgHg
	]

	var test_cases: Array = [
		{"color": ["R", "R"], "hue": ["H", "H"], "expected": "Red"},
		{"color": ["R", "R"], "hue": ["Ho", "Ho"], "expected": "Gold"},
		{"color": ["R", "R"], "hue": ["Hb", "Hb"], "expected": "Teal"},
		{"color": ["R", "R"], "hue": ["Hg", "Hg"], "expected": "Jade"},
		{"color": ["R", "W"], "hue": ["H", "H"], "expected": "Pink"},
		{"color": ["R", "W"], "hue": ["Ho", "Ho"], "expected": "Peach"},
		{"color": ["R", "W"], "hue": ["Hb", "Hb"], "expected": "Sky"},
		{"color": ["R", "W"], "hue": ["Hg", "Hg"], "expected": "Mint"},
	]

	for test_case in test_cases:
		var genotype: Dictionary = {
			"color": test_case["color"],
			"hue": test_case["hue"]
		}
		var phenotype: Dictionary = GeneticsEngine.calculate_phenotype(genotype)

		if not phenotype.has("color"):
			print("  FAILED: Missing color phenotype for %s\n" % test_case["expected"])
			return false

		var color_name: String = phenotype["color"]["name"]
		if color_name != test_case["expected"]:
			print("  FAILED: Expected %s, got %s (genotype: color=%s, hue=%s)\n" % [
				test_case["expected"],
				color_name,
				str(test_case["color"]),
				str(test_case["hue"])
			])
			return false

		print("  ✓ %s + %s → %s" % [
			str(test_case["color"]),
			str(test_case["hue"]),
			color_name
		])

	print("  PASSED: All eight colors correct\n")
	return true


## Test that hue has no effect on white dragons
func test_hue_no_effect_on_white() -> bool:
	print("Test: Hue has no effect on white dragons")

	var white_test_cases: Array = [
		["H", "H"],
		["Ho", "Ho"],
		["Hb", "Hb"],
		["Hg", "Hg"],
		["H", "Ho"],
		["Hb", "Hg"]
	]

	for hue_pair in white_test_cases:
		var genotype: Dictionary = {
			"color": ["W", "W"],
			"hue": hue_pair
		}
		var phenotype: Dictionary = GeneticsEngine.calculate_phenotype(genotype)

		if not phenotype.has("color"):
			print("  FAILED: Missing color phenotype for WW + %s\n" % str(hue_pair))
			return false

		var color_name: String = phenotype["color"]["name"]
		if color_name != "White":
			print("  FAILED: WW + %s should be White, got %s\n" % [str(hue_pair), color_name])
			return false

		print("  ✓ WW + %s → White" % str(hue_pair))

	print("  PASSED: White dragons unaffected by hue (epistasis works)\n")
	return true
