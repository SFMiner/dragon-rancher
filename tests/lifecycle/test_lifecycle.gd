# test_lifecycle.gd
# Unit tests for Lifecycle rules module
# Part of Dragon Ranch - Session 3 Dragon Entities & Lifecycle
#
# Run with: godot --headless --script tests/lifecycle/test_lifecycle.gd

extends SceneTree


func _init() -> void:
	print("\n========================================")
	print("Running Lifecycle Tests")
	print("========================================\n")

	# Wait for autoloads to initialize
	await get_root().ready

	var passed: int = 0
	var failed: int = 0

	# Run all tests
	if test_life_stage_transitions():
		passed += 1
	else:
		failed += 1

	if test_breeding_eligibility():
		passed += 1
	else:
		failed += 1

	if test_age_advancement():
		passed += 1
	else:
		failed += 1

	if test_lifespan_calculation():
		passed += 1
	else:
		failed += 1

	if test_stage_multipliers():
		passed += 1
	else:
		failed += 1

	if test_lifecycle_info():
		passed += 1
	else:
		failed += 1

	# Print summary
	print("\n========================================")
	print("Test Results: %d passed, %d failed" % [passed, failed])
	print("========================================\n")

	# Exit with appropriate code
	quit(0 if failed == 0 else 1)


## Test life stage transitions based on age
func test_life_stage_transitions() -> bool:
	print("Test: Life stage transitions")

	# Test hatchling (0-1 seasons)
	if Lifecycle.get_life_stage(0) != "hatchling":
		print("  FAILED: Age 0 should be hatchling\n")
		return false

	if Lifecycle.get_life_stage(1) != "hatchling":
		print("  FAILED: Age 1 should be hatchling\n")
		return false

	# Test juvenile (2-3 seasons)
	if Lifecycle.get_life_stage(2) != "juvenile":
		print("  FAILED: Age 2 should be juvenile\n")
		return false

	if Lifecycle.get_life_stage(3) != "juvenile":
		print("  FAILED: Age 3 should be juvenile\n")
		return false

	# Test adult (4-18 seasons)
	if Lifecycle.get_life_stage(4) != "adult":
		print("  FAILED: Age 4 should be adult\n")
		return false

	if Lifecycle.get_life_stage(10) != "adult":
		print("  FAILED: Age 10 should be adult\n")
		return false

	if Lifecycle.get_life_stage(18) != "adult":
		print("  FAILED: Age 18 should be adult\n")
		return false

	# Test elder (19+ seasons)
	if Lifecycle.get_life_stage(19) != "elder":
		print("  FAILED: Age 19 should be elder\n")
		return false

	if Lifecycle.get_life_stage(25) != "elder":
		print("  FAILED: Age 25 should be elder\n")
		return false

	print("  PASSED: All life stage transitions correct\n")
	return true


## Test breeding eligibility
func test_breeding_eligibility() -> bool:
	print("Test: Breeding eligibility")

	# Create test dragons at different stages
	var hatchling := DragonData.new()
	hatchling.life_stage = "hatchling"
	hatchling.age = 0
	hatchling.health = 100.0

	var juvenile := DragonData.new()
	juvenile.life_stage = "juvenile"
	juvenile.age = 2
	juvenile.health = 100.0

	var adult := DragonData.new()
	adult.life_stage = "adult"
	adult.age = 8
	adult.health = 100.0

	var elder := DragonData.new()
	elder.life_stage = "elder"
	elder.age = 20
	elder.health = 100.0

	# Test breeding eligibility
	if Lifecycle.can_breed(hatchling):
		print("  FAILED: Hatchling should not be able to breed\n")
		return false

	if Lifecycle.can_breed(juvenile):
		print("  FAILED: Juvenile should not be able to breed\n")
		return false

	if not Lifecycle.can_breed(adult):
		print("  FAILED: Adult should be able to breed\n")
		return false

	if Lifecycle.can_breed(elder):
		print("  FAILED: Elder should not be able to breed\n")
		return false

	# Test health requirement
	var sick_adult := DragonData.new()
	sick_adult.life_stage = "adult"
	sick_adult.age = 8
	sick_adult.health = 10.0  # Too low

	if Lifecycle.can_breed(sick_adult):
		print("  FAILED: Sick adult should not be able to breed\n")
		return false

	print("  PASSED: Breeding eligibility checks work correctly\n")
	return true


## Test age advancement
func test_age_advancement() -> bool:
	print("Test: Age advancement")

	var dragon := DragonData.new()
	dragon.id = "test"
	dragon.name = "Test"
	dragon.sex = "male"
	dragon.genotype = {}
	dragon.life_stage = "hatchling"
	dragon.age = 0

	# Age through stages
	Lifecycle.advance_age(dragon)
	if dragon.age != 1 or dragon.life_stage != "hatchling":
		print("  FAILED: Age 0->1 transition failed\n")
		return false

	Lifecycle.advance_age(dragon)
	if dragon.age != 2 or dragon.life_stage != "juvenile":
		print("  FAILED: Age 1->2 transition to juvenile failed\n")
		return false

	# Age to adult
	dragon.age = 3
	Lifecycle.advance_age(dragon)
	if dragon.age != 4 or dragon.life_stage != "adult":
		print("  FAILED: Age 3->4 transition to adult failed\n")
		return false

	# Age to elder
	dragon.age = 18
	Lifecycle.advance_age(dragon)
	if dragon.age != 19 or dragon.life_stage != "elder":
		print("  FAILED: Age 18->19 transition to elder failed\n")
		return false

	print("  PASSED: Age advancement works correctly\n")
	return true


## Test lifespan calculation with metabolism trait
func test_lifespan_calculation() -> bool:
	print("Test: Lifespan calculation")

	# Test base lifespan (no metabolism trait)
	var normal_dragon := DragonData.new()
	normal_dragon.genotype = {"fire": ["F", "f"]}

	var base_lifespan: int = Lifecycle.calculate_lifespan(normal_dragon)
	if base_lifespan != 23:
		print("  FAILED: Base lifespan should be 23, got %d\n" % base_lifespan)
		return false

	# Test with normal metabolism (MM)
	var normal_meta := DragonData.new()
	normal_meta.genotype = {"metabolism": ["M", "M"]}

	var normal_lifespan: int = Lifecycle.calculate_lifespan(normal_meta)
	if normal_lifespan != 23:
		print("  FAILED: Normal metabolism lifespan should be 23, got %d\n" % normal_lifespan)
		return false

	# Test with heterozygous metabolism (Mm) - 15% reduction
	var hetero_meta := DragonData.new()
	hetero_meta.genotype = {"metabolism": ["M", "m"]}

	var hetero_lifespan: int = Lifecycle.calculate_lifespan(hetero_meta)
	var expected_hetero: int = int(23 * 0.85)  # 19
	if hetero_lifespan != expected_hetero:
		print("  FAILED: Heterozygous metabolism lifespan should be %d, got %d\n" % [expected_hetero, hetero_lifespan])
		return false

	# Test with hyper metabolism (mm) - 30% reduction
	var hyper_meta := DragonData.new()
	hyper_meta.genotype = {"metabolism": ["m", "m"]}

	var hyper_lifespan: int = Lifecycle.calculate_lifespan(hyper_meta)
	var expected_hyper: int = int(23 * 0.70)  # 16
	if hyper_lifespan != expected_hyper:
		print("  FAILED: Hyper metabolism lifespan should be %d, got %d\n" % [expected_hyper, hyper_lifespan])
		return false

	print("  PASSED: Lifespan calculations correct (base=23, Mm=%d, mm=%d)\n" % [hetero_lifespan, hyper_lifespan])
	return true


## Test stage multipliers
func test_stage_multipliers() -> bool:
	print("Test: Stage multipliers")

	# Test scale multipliers
	if Lifecycle.get_stage_scale("hatchling") != 0.5:
		print("  FAILED: Hatchling scale should be 0.5\n")
		return false

	if Lifecycle.get_stage_scale("juvenile") != 0.75:
		print("  FAILED: Juvenile scale should be 0.75\n")
		return false

	if Lifecycle.get_stage_scale("adult") != 1.0:
		print("  FAILED: Adult scale should be 1.0\n")
		return false

	# Test speed multipliers
	if Lifecycle.get_stage_speed_multiplier("hatchling") != 0.6:
		print("  FAILED: Hatchling speed should be 0.6\n")
		return false

	if Lifecycle.get_stage_speed_multiplier("adult") != 1.0:
		print("  FAILED: Adult speed should be 1.0\n")
		return false

	# Test food consumption multipliers
	if Lifecycle.get_food_consumption_multiplier("hatchling") != 0.5:
		print("  FAILED: Hatchling food consumption should be 0.5\n")
		return false

	if Lifecycle.get_food_consumption_multiplier("adult") != 1.0:
		print("  FAILED: Adult food consumption should be 1.0\n")
		return false

	print("  PASSED: All stage multipliers correct\n")
	return true


## Test lifecycle info dictionary
func test_lifecycle_info() -> bool:
	print("Test: Lifecycle info dictionary")

	var dragon := DragonData.new()
	dragon.id = "test"
	dragon.name = "Test"
	dragon.sex = "male"
	dragon.genotype = {}
	dragon.life_stage = "adult"
	dragon.age = 8
	dragon.health = 100.0

	var info: Dictionary = Lifecycle.get_lifecycle_info(dragon)

	# Check all expected keys
	var required_keys: Array[String] = [
		"age", "life_stage", "stage_display_name", "max_lifespan",
		"age_percentage", "seasons_until_next_stage", "can_breed",
		"is_prime_breeding_age", "is_end_of_life", "scale_multiplier",
		"speed_multiplier", "food_multiplier"
	]

	for key in required_keys:
		if not info.has(key):
			print("  FAILED: Missing key '%s' in lifecycle info\n" % key)
			return false

	# Check some values
	if info["age"] != 8:
		print("  FAILED: Age should be 8\n")
		return false

	if info["life_stage"] != "adult":
		print("  FAILED: Life stage should be adult\n")
		return false

	if not info["can_breed"]:
		print("  FAILED: Adult should be able to breed\n")
		return false

	if info["scale_multiplier"] != 1.0:
		print("  FAILED: Adult scale multiplier should be 1.0\n")
		return false

	print("  PASSED: Lifecycle info dictionary contains all expected data\n")
	return true
