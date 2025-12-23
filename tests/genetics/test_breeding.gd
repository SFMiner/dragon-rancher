# test_breeding.gd
# Unit tests for breeding logic in GeneticsEngine
# Part of Dragon Ranch - Session 2 Core Genetics Engine
#
# Run these tests with: godot --headless --script tests/genetics/test_breeding.gd

extends SceneTree


func _init() -> void:
	print("\n========================================")
	print("Running Breeding Tests")
	print("========================================\n")

	# Wait for autoloads to initialize
	await get_root().ready

	var passed: int = 0
	var failed: int = 0

	# Run all tests
	if test_homozygous_cross():
		passed += 1
	else:
		failed += 1

	if test_heterozygous_cross():
		passed += 1
	else:
		failed += 1

	if test_wings_trait():
		passed += 1
	else:
		failed += 1

	if test_armor_trait():
		passed += 1
	else:
		failed += 1

	if test_statistical_distribution():
		passed += 1
	else:
		failed += 1

	if test_multiple_traits():
		passed += 1
	else:
		failed += 1

	# Print summary
	print("\n========================================")
	print("Test Results: %d passed, %d failed" % [passed, failed])
	print("========================================\n")

	# Exit with appropriate code
	quit(0 if failed == 0 else 1)


## Test FF × ff → all Ff
func test_homozygous_cross() -> bool:
	print("Test: Homozygous cross (FF × ff)")

	# Set fixed seed for deterministic results
	RNGService.set_seed(12345)

	# Create parent dragons
	var parent_a: DragonData = DragonData.new()
	parent_a.id = "test_a"
	parent_a.name = "Fire Dragon"
	parent_a.genotype = {
		"fire": ["F", "F"],
		"wings": ["w", "w"],
		"armor": ["A", "A"]
	}
	parent_a.life_stage = "adult"
	parent_a.health = 100.0

	var parent_b: DragonData = DragonData.new()
	parent_b.id = "test_b"
	parent_b.name = "Smoke Dragon"
	parent_b.genotype = {
		"fire": ["f", "f"],
		"wings": ["W", "W"],
		"armor": ["a", "a"]
	}
	parent_b.life_stage = "adult"
	parent_b.health = 100.0

	# Breed multiple times to check consistency
	for i in range(10):
		var offspring_genotype: Dictionary = GeneticsEngine.breed_dragons(parent_a, parent_b)

		# Check fire trait: should always be Ff
		var fire_alleles: Array = offspring_genotype["fire"]
		var fire_normalized: String = GeneticsResolvers.normalize_genotype(fire_alleles)

		if fire_normalized != "Ff":
			print("  FAILED: Expected Ff, got %s" % fire_normalized)
			return false

	print("  PASSED: All offspring are Ff\n")
	return true


## Test Ff × Ff → 25% FF, 50% Ff, 25% ff (statistical)
func test_heterozygous_cross() -> bool:
	print("Test: Heterozygous cross (Ff × Ff)")

	# Set fixed seed
	RNGService.set_seed(54321)

	# Create parent dragons (both heterozygous)
	var parent_a: DragonData = DragonData.new()
	parent_a.id = "test_a"
	parent_a.name = "Hybrid A"
	parent_a.genotype = {"fire": ["F", "f"]}
	parent_a.life_stage = "adult"
	parent_a.health = 100.0

	var parent_b: DragonData = DragonData.new()
	parent_b.id = "test_b"
	parent_b.name = "Hybrid B"
	parent_b.genotype = {"fire": ["F", "f"]}
	parent_b.life_stage = "adult"
	parent_b.health = 100.0

	# Breed many times and count outcomes
	var counts: Dictionary = {"FF": 0, "Ff": 0, "ff": 0}
	var trials: int = 100

	for i in range(trials):
		var offspring_genotype: Dictionary = GeneticsEngine.breed_dragons(parent_a, parent_b)
		var fire_normalized: String = GeneticsResolvers.normalize_genotype(offspring_genotype["fire"])
		counts[fire_normalized] += 1

	# Check if distribution is approximately correct (with some tolerance)
	var ff_percent: float = (counts["FF"] / float(trials)) * 100.0
	var ff_percent_expected: float = 25.0
	var ff_diff: float = abs(ff_percent - ff_percent_expected)

	var Ff_percent: float = (counts["Ff"] / float(trials)) * 100.0
	var Ff_percent_expected: float = 50.0
	var Ff_diff: float = abs(Ff_percent - Ff_percent_expected)

	var ff2_percent: float = (counts["ff"] / float(trials)) * 100.0
	var ff2_percent_expected: float = 25.0
	var ff2_diff: float = abs(ff2_percent - ff2_percent_expected)

	print("  Distribution over %d trials:" % trials)
	print("    FF: %d (%.1f%%, expected 25%%)" % [counts["FF"], ff_percent])
	print("    Ff: %d (%.1f%%, expected 50%%)" % [counts["Ff"], Ff_percent])
	print("    ff: %d (%.1f%%, expected 25%%)" % [counts["ff"], ff2_percent])

	# Allow 15% tolerance for statistical variation
	var tolerance: float = 15.0

	if ff_diff > tolerance or Ff_diff > tolerance or ff2_diff > tolerance:
		print("  FAILED: Distribution outside tolerance (15%%)\n")
		return false

	print("  PASSED: Distribution within tolerance\n")
	return true


## Test ww × WW → all wW (vestigial phenotype)
func test_wings_trait() -> bool:
	print("Test: Wings trait (ww × WW)")

	RNGService.set_seed(99999)

	var parent_a: DragonData = DragonData.new()
	parent_a.id = "test_a"
	parent_a.name = "Vestigial Wings"
	parent_a.genotype = {"wings": ["w", "w"]}
	parent_a.life_stage = "adult"
	parent_a.health = 100.0

	var parent_b: DragonData = DragonData.new()
	parent_b.id = "test_b"
	parent_b.name = "Functional Wings"
	parent_b.genotype = {"wings": ["W", "W"]}
	parent_b.life_stage = "adult"
	parent_b.health = 100.0

	# Breed and check
	var offspring_genotype: Dictionary = GeneticsEngine.breed_dragons(parent_a, parent_b)
	var wings_normalized: String = GeneticsResolvers.normalize_genotype(offspring_genotype["wings"])

	# Calculate phenotype
	var phenotype: Dictionary = GeneticsEngine.calculate_phenotype(offspring_genotype)
	var wings_phenotype: String = phenotype["wings"]["name"]

	if wings_normalized != "wW":
		print("  FAILED: Expected wW, got %s" % wings_normalized)
		return false

	if wings_phenotype != "Vestigial":
		print("  FAILED: Expected Vestigial phenotype, got %s" % wings_phenotype)
		return false

	print("  PASSED: Genotype wW with Vestigial phenotype (w is dominant)\n")
	return true


## Test Aa × aa → 50% Aa, 50% aa
func test_armor_trait() -> bool:
	print("Test: Armor trait (Aa × aa)")

	RNGService.set_seed(11111)

	var parent_a: DragonData = DragonData.new()
	parent_a.id = "test_a"
	parent_a.name = "Heavy Armor Hybrid"
	parent_a.genotype = {"armor": ["A", "a"]}
	parent_a.life_stage = "adult"
	parent_a.health = 100.0

	var parent_b: DragonData = DragonData.new()
	parent_b.id = "test_b"
	parent_b.name = "Light Armor"
	parent_b.genotype = {"armor": ["a", "a"]}
	parent_b.life_stage = "adult"
	parent_b.health = 100.0

	# Breed many times
	var counts: Dictionary = {"Aa": 0, "aa": 0}
	var trials: int = 100

	for i in range(trials):
		var offspring_genotype: Dictionary = GeneticsEngine.breed_dragons(parent_a, parent_b)
		var armor_normalized: String = GeneticsResolvers.normalize_genotype(offspring_genotype["armor"])
		counts[armor_normalized] += 1

	var Aa_percent: float = (counts["Aa"] / float(trials)) * 100.0
	var aa_percent: float = (counts["aa"] / float(trials)) * 100.0

	print("  Distribution over %d trials:" % trials)
	print("    Aa: %d (%.1f%%, expected 50%%)" % [counts["Aa"], Aa_percent])
	print("    aa: %d (%.1f%%, expected 50%%)" % [counts["aa"], aa_percent])

	# Check within tolerance
	var tolerance: float = 15.0
	if abs(Aa_percent - 50.0) > tolerance or abs(aa_percent - 50.0) > tolerance:
		print("  FAILED: Distribution outside tolerance\n")
		return false

	print("  PASSED: Distribution within tolerance\n")
	return true


## Test with large number of trials for accurate statistics
func test_statistical_distribution() -> bool:
	print("Test: Statistical distribution (Ff × Ff, 1000 trials)")

	RNGService.set_seed(777777)

	var parent_a: DragonData = DragonData.new()
	parent_a.id = "test_a"
	parent_a.name = "Hybrid A"
	parent_a.genotype = {"fire": ["F", "f"]}
	parent_a.life_stage = "adult"
	parent_a.health = 100.0

	var parent_b: DragonData = DragonData.new()
	parent_b.id = "test_b"
	parent_b.name = "Hybrid B"
	parent_b.genotype = {"fire": ["F", "f"]}
	parent_b.life_stage = "adult"
	parent_b.health = 100.0

	var counts: Dictionary = {"FF": 0, "Ff": 0, "ff": 0}
	var trials: int = 1000

	for i in range(trials):
		var offspring_genotype: Dictionary = GeneticsEngine.breed_dragons(parent_a, parent_b)
		var fire_normalized: String = GeneticsResolvers.normalize_genotype(offspring_genotype["fire"])
		counts[fire_normalized] += 1

	var ff_percent: float = (counts["FF"] / float(trials)) * 100.0
	var Ff_percent: float = (counts["Ff"] / float(trials)) * 100.0
	var ff2_percent: float = (counts["ff"] / float(trials)) * 100.0

	print("  Distribution over %d trials:" % trials)
	print("    FF: %d (%.1f%%, expected 25%%)" % [counts["FF"], ff_percent])
	print("    Ff: %d (%.1f%%, expected 50%%)" % [counts["Ff"], Ff_percent])
	print("    ff: %d (%.1f%%, expected 25%%)" % [counts["ff"], ff2_percent])

	# With 1000 trials, tolerance can be tighter
	var tolerance: float = 10.0
	if abs(ff_percent - 25.0) > tolerance or abs(Ff_percent - 50.0) > tolerance or abs(ff2_percent - 25.0) > tolerance:
		print("  FAILED: Distribution outside tolerance (10%%)\n")
		return false

	print("  PASSED: Distribution within tolerance\n")
	return true


## Test breeding with multiple traits at once
func test_multiple_traits() -> bool:
	print("Test: Multiple traits (Ff wW Aa × ff WW aa)")

	RNGService.set_seed(42424)

	var parent_a: DragonData = DragonData.new()
	parent_a.id = "test_a"
	parent_a.name = "Mixed A"
	parent_a.genotype = {
		"fire": ["F", "f"],
		"wings": ["w", "W"],
		"armor": ["A", "a"]
	}
	parent_a.life_stage = "adult"
	parent_a.health = 100.0

	var parent_b: DragonData = DragonData.new()
	parent_b.id = "test_b"
	parent_b.name = "Mixed B"
	parent_b.genotype = {
		"fire": ["f", "f"],
		"wings": ["W", "W"],
		"armor": ["a", "a"]
	}
	parent_b.life_stage = "adult"
	parent_b.health = 100.0

	var offspring_genotype: Dictionary = GeneticsEngine.breed_dragons(parent_a, parent_b)

	# Check all traits are present
	if not offspring_genotype.has("fire") or not offspring_genotype.has("wings") or not offspring_genotype.has("armor"):
		print("  FAILED: Missing traits in offspring\n")
		return false

	# Validate each trait has 2 alleles
	for trait_key in ["fire", "wings", "armor"]:
		if offspring_genotype[trait_key].size() != 2:
			print("  FAILED: Trait '%s' doesn't have 2 alleles\n" % trait_key)
			return false

	print("  Offspring genotype: %s" % GeneticsResolvers.format_genotype_display(offspring_genotype))
	print("  PASSED: All traits inherited correctly\n")
	return true
