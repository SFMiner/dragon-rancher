# test_phenotype.gd
# Unit tests for phenotype calculation in GeneticsEngine
# Part of Dragon Ranch - Session 2 Core Genetics Engine
#
# Run these tests with: godot --headless --script tests/genetics/test_phenotype.gd

extends SceneTree


func _init() -> void:
	print("\n========================================")
	print("Running Phenotype Tests")
	print("========================================\n")

	# Wait for autoloads to initialize
	await get_root().ready

	var passed: int = 0
	var failed: int = 0

	# Run all tests
	if test_fire_phenotypes():
		passed += 1
	else:
		failed += 1

	if test_wings_phenotypes():
		passed += 1
	else:
		failed += 1

	if test_armor_phenotypes():
		passed += 1
	else:
		failed += 1

	if test_normalization_equivalence():
		passed += 1
	else:
		failed += 1

	if test_all_mvp_traits():
		passed += 1
	else:
		failed += 1

	if test_invalid_genotype():
		passed += 1
	else:
		failed += 1

	# Print summary
	print("\n========================================")
	print("Test Results: %d passed, %d failed" % [passed, failed])
	print("========================================\n")

	# Exit with appropriate code
	quit(0 if failed == 0 else 1)


## Test fire trait phenotypes (F is dominant)
func test_fire_phenotypes() -> bool:
	print("Test: Fire trait phenotypes")

	# Test FF -> Fire
	var genotype_ff: Dictionary = {"fire": ["F", "F"]}
	var phenotype_ff: Dictionary = GeneticsEngine.calculate_phenotype(genotype_ff)

	if not phenotype_ff.has("fire"):
		print("  FAILED: Missing fire phenotype for FF\n")
		return false

	if phenotype_ff["fire"]["name"] != "Fire":
		print("  FAILED: FF should be Fire, got %s\n" % phenotype_ff["fire"]["name"])
		return false

	# Test Ff -> Fire
	var genotype_Ff: Dictionary = {"fire": ["F", "f"]}
	var phenotype_Ff: Dictionary = GeneticsEngine.calculate_phenotype(genotype_Ff)

	if phenotype_Ff["fire"]["name"] != "Fire":
		print("  FAILED: Ff should be Fire, got %s\n" % phenotype_Ff["fire"]["name"])
		return false

	# Test ff -> Smoke
	var genotype_ff2: Dictionary = {"fire": ["f", "f"]}
	var phenotype_ff2: Dictionary = GeneticsEngine.calculate_phenotype(genotype_ff2)

	if phenotype_ff2["fire"]["name"] != "Smoke":
		print("  FAILED: ff should be Smoke, got %s\n" % phenotype_ff2["fire"]["name"])
		return false

	print("  PASSED: All fire phenotypes correct (FF=Fire, Ff=Fire, ff=Smoke)\n")
	return true


## Test wings trait phenotypes (w is dominant - teaching moment!)
func test_wings_phenotypes() -> bool:
	print("Test: Wings trait phenotypes (vestigial dominant)")

	# Test ww -> Vestigial
	var genotype_ww: Dictionary = {"wings": ["w", "w"]}
	var phenotype_ww: Dictionary = GeneticsEngine.calculate_phenotype(genotype_ww)

	if phenotype_ww["wings"]["name"] != "Vestigial":
		print("  FAILED: ww should be Vestigial, got %s\n" % phenotype_ww["wings"]["name"])
		return false

	# Test wW -> Vestigial (w is dominant!)
	var genotype_wW: Dictionary = {"wings": ["w", "W"]}
	var phenotype_wW: Dictionary = GeneticsEngine.calculate_phenotype(genotype_wW)

	if phenotype_wW["wings"]["name"] != "Vestigial":
		print("  FAILED: wW should be Vestigial, got %s\n" % phenotype_wW["wings"]["name"])
		return false

	# Test WW -> Functional
	var genotype_WW: Dictionary = {"wings": ["W", "W"]}
	var phenotype_WW: Dictionary = GeneticsEngine.calculate_phenotype(genotype_WW)

	if phenotype_WW["wings"]["name"] != "Functional":
		print("  FAILED: WW should be Functional, got %s\n" % phenotype_WW["wings"]["name"])
		return false

	print("  PASSED: Wings phenotypes correct (ww=Vestigial, wW=Vestigial, WW=Functional)\n")
	return true


## Test armor trait phenotypes (A is dominant)
func test_armor_phenotypes() -> bool:
	print("Test: Armor trait phenotypes")

	# Test AA -> Heavy
	var genotype_AA: Dictionary = {"armor": ["A", "A"]}
	var phenotype_AA: Dictionary = GeneticsEngine.calculate_phenotype(genotype_AA)

	if phenotype_AA["armor"]["name"] != "Heavy":
		print("  FAILED: AA should be Heavy, got %s\n" % phenotype_AA["armor"]["name"])
		return false

	# Test Aa -> Heavy
	var genotype_Aa: Dictionary = {"armor": ["A", "a"]}
	var phenotype_Aa: Dictionary = GeneticsEngine.calculate_phenotype(genotype_Aa)

	if phenotype_Aa["armor"]["name"] != "Heavy":
		print("  FAILED: Aa should be Heavy, got %s\n" % phenotype_Aa["armor"]["name"])
		return false

	# Test aa -> Light
	var genotype_aa: Dictionary = {"armor": ["a", "a"]}
	var phenotype_aa: Dictionary = GeneticsEngine.calculate_phenotype(genotype_aa)

	if phenotype_aa["armor"]["name"] != "Light":
		print("  FAILED: aa should be Light, got %s\n" % phenotype_aa["armor"]["name"])
		return false

	print("  PASSED: Armor phenotypes correct (AA=Heavy, Aa=Heavy, aa=Light)\n")
	return true


## Test that normalization gives same phenotype (Ff == fF)
func test_normalization_equivalence() -> bool:
	print("Test: Normalization equivalence (Ff == fF)")

	# Test Ff
	var genotype_Ff: Dictionary = {"fire": ["F", "f"]}
	var phenotype_Ff: Dictionary = GeneticsEngine.calculate_phenotype(genotype_Ff)

	# Test fF (reversed order)
	var genotype_fF: Dictionary = {"fire": ["f", "F"]}
	var phenotype_fF: Dictionary = GeneticsEngine.calculate_phenotype(genotype_fF)

	if phenotype_Ff["fire"]["name"] != phenotype_fF["fire"]["name"]:
		print("  FAILED: Ff and fF should have same phenotype\n")
		print("    Ff: %s" % phenotype_Ff["fire"]["name"])
		print("    fF: %s" % phenotype_fF["fire"]["name"])
		return false

	# Test with wings trait too
	var genotype_wW: Dictionary = {"wings": ["w", "W"]}
	var phenotype_wW: Dictionary = GeneticsEngine.calculate_phenotype(genotype_wW)

	var genotype_Ww: Dictionary = {"wings": ["W", "w"]}
	var phenotype_Ww: Dictionary = GeneticsEngine.calculate_phenotype(genotype_Ww)

	if phenotype_wW["wings"]["name"] != phenotype_Ww["wings"]["name"]:
		print("  FAILED: wW and Ww should have same phenotype\n")
		return false

	print("  PASSED: Allele order doesn't affect phenotype\n")
	return true


## Test all MVP traits together
func test_all_mvp_traits() -> bool:
	print("Test: All MVP traits together")

	var genotype: Dictionary = {
		"fire": ["F", "f"],
		"wings": ["w", "W"],
		"armor": ["A", "a"]
	}

	var phenotype: Dictionary = GeneticsEngine.calculate_phenotype(genotype)

	# Check all traits are present
	if not phenotype.has("fire") or not phenotype.has("wings") or not phenotype.has("armor"):
		print("  FAILED: Missing traits in phenotype\n")
		return false

	# Check each phenotype
	if phenotype["fire"]["name"] != "Fire":
		print("  FAILED: Expected Fire, got %s\n" % phenotype["fire"]["name"])
		return false

	if phenotype["wings"]["name"] != "Vestigial":
		print("  FAILED: Expected Vestigial, got %s\n" % phenotype["wings"]["name"])
		return false

	if phenotype["armor"]["name"] != "Heavy":
		print("  FAILED: Expected Heavy, got %s\n" % phenotype["armor"]["name"])
		return false

	# Check that phenotype data includes expected fields
	for trait_key in ["fire", "wings", "armor"]:
		var pheno_data: Dictionary = phenotype[trait_key]

		if not pheno_data.has("name"):
			print("  FAILED: Phenotype missing 'name' field for %s\n" % trait_key)
			return false

		if not pheno_data.has("sprite_suffix"):
			print("  FAILED: Phenotype missing 'sprite_suffix' field for %s\n" % trait_key)
			return false

		if not pheno_data.has("color"):
			print("  FAILED: Phenotype missing 'color' field for %s\n" % trait_key)
			return false

	print("  Phenotype result:")
	print("    Fire: Ff -> %s" % phenotype["fire"]["name"])
	print("    Wings: wW -> %s" % phenotype["wings"]["name"])
	print("    Armor: Aa -> %s" % phenotype["armor"]["name"])
	print("  PASSED: All traits calculated correctly\n")
	return true


## Test that invalid genotypes are handled gracefully
func test_invalid_genotype() -> bool:
	print("Test: Invalid genotype handling")

	# Test with unknown trait
	var genotype_unknown: Dictionary = {"unknown_trait": ["X", "Y"]}
	var phenotype_unknown: Dictionary = GeneticsEngine.calculate_phenotype(genotype_unknown)

	# Should return empty or handle gracefully
	if not phenotype_unknown.is_empty():
		print("  WARNING: Unknown trait returned non-empty phenotype\n")

	# Test with invalid alleles (should fail validation)
	var genotype_invalid: Dictionary = {"fire": ["X", "Y"]}
	var phenotype_invalid: Dictionary = GeneticsEngine.calculate_phenotype(genotype_invalid)

	# Test with wrong number of alleles
	var genotype_wrong_count: Dictionary = {"fire": ["F"]}
	var phenotype_wrong_count: Dictionary = GeneticsEngine.calculate_phenotype(genotype_wrong_count)

	# These should all handle errors gracefully without crashing
	print("  PASSED: Invalid genotypes handled without crashing\n")
	return true
