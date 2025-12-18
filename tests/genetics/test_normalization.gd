# test_normalization.gd
# Unit tests for GeneticsResolvers normalization and validation
# Part of Dragon Ranch - Session 2 Core Genetics Engine
#
# Run these tests with: godot --headless --script tests/genetics/test_normalization.gd

extends SceneTree


func _init() -> void:
	print("\n========================================")
	print("Running Normalization Tests")
	print("========================================\n")

	# Wait for autoloads to initialize
	await get_root().ready

	var passed: int = 0
	var failed: int = 0

	# Run all tests
	if test_allele_sorting():
		passed += 1
	else:
		failed += 1

	if test_validation():
		passed += 1
	else:
		failed += 1

	if test_display_formatting():
		passed += 1
	else:
		failed += 1

	if test_trait_extraction():
		passed += 1
	else:
		failed += 1

	if test_homozygous_heterozygous():
		passed += 1
	else:
		failed += 1

	if test_genotype_equality():
		passed += 1
	else:
		failed += 1

	if test_allele_checking():
		passed += 1
	else:
		failed += 1

	# Print summary
	print("\n========================================")
	print("Test Results: %d passed, %d failed" % [passed, failed])
	print("========================================\n")

	# Exit with appropriate code
	quit(0 if failed == 0 else 1)


## Test allele sorting (alphabetical normalization)
func test_allele_sorting() -> bool:
	print("Test: Allele sorting")

	# Test basic sorting
	var result1: String = GeneticsResolvers.normalize_genotype(["f", "F"])
	if result1 != "Ff":
		print("  FAILED: ['f', 'F'] should normalize to 'Ff', got '%s'\n" % result1)
		return false

	var result2: String = GeneticsResolvers.normalize_genotype(["F", "f"])
	if result2 != "Ff":
		print("  FAILED: ['F', 'f'] should normalize to 'Ff', got '%s'\n" % result2)
		return false

	# Test homozygous
	var result3: String = GeneticsResolvers.normalize_genotype(["F", "F"])
	if result3 != "FF":
		print("  FAILED: ['F', 'F'] should normalize to 'FF', got '%s'\n" % result3)
		return false

	var result4: String = GeneticsResolvers.normalize_genotype(["f", "f"])
	if result4 != "ff":
		print("  FAILED: ['f', 'f'] should normalize to 'ff', got '%s'\n" % result4)
		return false

	# Test with wings (lowercase comes after uppercase in ASCII)
	var result5: String = GeneticsResolvers.normalize_genotype(["W", "w"])
	if result5 != "Ww":
		print("  FAILED: ['W', 'w'] should normalize to 'Ww', got '%s'\n" % result5)
		return false

	var result6: String = GeneticsResolvers.normalize_genotype(["w", "W"])
	if result6 != "Ww":
		print("  FAILED: ['w', 'W'] should normalize to 'Ww', got '%s'\n" % result6)
		return false

	print("  PASSED: Allele sorting works correctly\n")
	return true


## Test genotype validation
func test_validation() -> bool:
	print("Test: Genotype validation")

	# Valid genotype
	var valid_genotype: Dictionary = {
		"fire": ["F", "f"],
		"wings": ["w", "W"],
		"armor": ["A", "a"]
	}

	if not GeneticsResolvers.validate_full_genotype(valid_genotype):
		print("  FAILED: Valid genotype marked as invalid\n")
		return false

	# Test individual trait validation
	if not GeneticsResolvers.validate_genotype(valid_genotype, "fire"):
		print("  FAILED: Valid fire trait marked as invalid\n")
		return false

	# Invalid: wrong number of alleles
	var invalid_count: Dictionary = {"fire": ["F"]}
	if GeneticsResolvers.validate_genotype(invalid_count, "fire"):
		print("  FAILED: Genotype with 1 allele should be invalid\n")
		return false

	# Invalid: unknown allele
	var invalid_allele: Dictionary = {"fire": ["X", "Y"]}
	if GeneticsResolvers.validate_genotype(invalid_allele, "fire"):
		print("  FAILED: Genotype with unknown alleles should be invalid\n")
		return false

	# Invalid: unknown trait
	var invalid_trait: Dictionary = {"unknown": ["A", "B"]}
	if GeneticsResolvers.validate_genotype(invalid_trait, "unknown"):
		print("  FAILED: Unknown trait should be invalid\n")
		return false

	print("  PASSED: Validation works correctly\n")
	return true


## Test display formatting
func test_display_formatting() -> bool:
	print("Test: Display formatting")

	# Single trait
	var genotype_single: Dictionary = {"fire": ["F", "f"]}
	var display_single: String = GeneticsResolvers.format_genotype_display(genotype_single)
	if display_single != "Ff":
		print("  FAILED: Single trait display should be 'Ff', got '%s'\n" % display_single)
		return false

	# Multiple traits (sorted alphabetically by key)
	var genotype_multi: Dictionary = {
		"fire": ["F", "f"],
		"wings": ["w", "W"],
		"armor": ["A", "a"]
	}
	var display_multi: String = GeneticsResolvers.format_genotype_display(genotype_multi)
	# Keys sorted: armor, fire, wings
	if display_multi != "Aa Ff Ww":
		print("  FAILED: Multi-trait display should be 'Aa Ff Ww', got '%s'\n" % display_multi)
		return false

	# Single trait formatting
	var trait_display: String = GeneticsResolvers.format_trait_display(genotype_multi, "fire")
	if trait_display != "Ff":
		print("  FAILED: Trait display should be 'Ff', got '%s'\n" % trait_display)
		return false

	# Missing trait
	var missing_display: String = GeneticsResolvers.format_trait_display(genotype_multi, "missing")
	if missing_display != "??":
		print("  FAILED: Missing trait should display '??', got '%s'\n" % missing_display)
		return false

	print("  PASSED: Display formatting works correctly\n")
	return true


## Test trait allele extraction
func test_trait_extraction() -> bool:
	print("Test: Trait allele extraction")

	var genotype: Dictionary = {
		"fire": ["F", "f"],
		"wings": ["w", "W"]
	}

	# Extract fire alleles
	var fire_alleles: Array = GeneticsResolvers.get_trait_alleles(genotype, "fire")
	if fire_alleles.size() != 2:
		print("  FAILED: Should get 2 alleles for fire\n")
		return false

	if "F" not in fire_alleles or "f" not in fire_alleles:
		print("  FAILED: Fire alleles should contain F and f\n")
		return false

	# Extract wings alleles
	var wings_alleles: Array = GeneticsResolvers.get_trait_alleles(genotype, "wings")
	if wings_alleles.size() != 2:
		print("  FAILED: Should get 2 alleles for wings\n")
		return false

	# Extract missing trait
	var missing_alleles: Array = GeneticsResolvers.get_trait_alleles(genotype, "missing")
	if not missing_alleles.is_empty():
		print("  FAILED: Missing trait should return empty array\n")
		return false

	print("  PASSED: Trait extraction works correctly\n")
	return true


## Test homozygous/heterozygous detection
func test_homozygous_heterozygous() -> bool:
	print("Test: Homozygous/heterozygous detection")

	var genotype: Dictionary = {
		"fire": ["F", "F"],  # Homozygous
		"wings": ["w", "W"],  # Heterozygous
		"armor": ["a", "a"]   # Homozygous
	}

	# Test homozygous
	if not GeneticsResolvers.is_homozygous(genotype, "fire"):
		print("  FAILED: FF should be homozygous\n")
		return false

	if GeneticsResolvers.is_homozygous(genotype, "wings"):
		print("  FAILED: wW should not be homozygous\n")
		return false

	# Test heterozygous
	if GeneticsResolvers.is_heterozygous(genotype, "fire"):
		print("  FAILED: FF should not be heterozygous\n")
		return false

	if not GeneticsResolvers.is_heterozygous(genotype, "wings"):
		print("  FAILED: wW should be heterozygous\n")
		return false

	# Count homozygous traits
	var homo_count: int = GeneticsResolvers.count_homozygous_traits(genotype)
	if homo_count != 2:
		print("  FAILED: Should have 2 homozygous traits, got %d\n" % homo_count)
		return false

	print("  PASSED: Homozygous/heterozygous detection works correctly\n")
	return true


## Test genotype equality comparison
func test_genotype_equality() -> bool:
	print("Test: Genotype equality")

	var genotype_a: Dictionary = {
		"fire": ["F", "f"],
		"wings": ["w", "W"]
	}

	var genotype_b: Dictionary = {
		"fire": ["f", "F"],  # Different order but same alleles
		"wings": ["W", "w"]
	}

	# Should be equal (normalization handles order)
	if not GeneticsResolvers.genotypes_equal(genotype_a, genotype_b):
		print("  FAILED: Genotypes with same alleles (different order) should be equal\n")
		return false

	var genotype_c: Dictionary = {
		"fire": ["F", "F"],  # Different alleles
		"wings": ["w", "W"]
	}

	# Should not be equal
	if GeneticsResolvers.genotypes_equal(genotype_a, genotype_c):
		print("  FAILED: Genotypes with different alleles should not be equal\n")
		return false

	var genotype_d: Dictionary = {
		"fire": ["F", "f"]  # Missing wings trait
	}

	# Should not be equal (different number of traits)
	if GeneticsResolvers.genotypes_equal(genotype_a, genotype_d):
		print("  FAILED: Genotypes with different traits should not be equal\n")
		return false

	print("  PASSED: Genotype equality works correctly\n")
	return true


## Test allele presence checking
func test_allele_checking() -> bool:
	print("Test: Allele presence checking")

	var genotype: Dictionary = {
		"fire": ["F", "f"],
		"wings": ["W", "W"]
	}

	# Test has_allele
	if not GeneticsResolvers.has_allele(genotype, "fire", "F"):
		print("  FAILED: Should have F allele for fire\n")
		return false

	if not GeneticsResolvers.has_allele(genotype, "fire", "f"):
		print("  FAILED: Should have f allele for fire\n")
		return false

	if GeneticsResolvers.has_allele(genotype, "fire", "X"):
		print("  FAILED: Should not have X allele for fire\n")
		return false

	if not GeneticsResolvers.has_allele(genotype, "wings", "W"):
		print("  FAILED: Should have W allele for wings\n")
		return false

	if GeneticsResolvers.has_allele(genotype, "wings", "w"):
		print("  FAILED: Should not have w allele for wings (it's WW)\n")
		return false

	print("  PASSED: Allele checking works correctly\n")
	return true
