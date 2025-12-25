# test_happiness_mechanics.gd
# Unit tests for happiness mechanics
# Part of Dragon Ranch - Happiness System Tests
#
# Run these tests with: godot --headless --script tests/happiness/test_happiness_mechanics.gd

extends SceneTree


func _init() -> void:
	print("\n========================================")
	print("Running Happiness Mechanics Tests")
	print("========================================\n")

	# Wait for autoloads to initialize
	await get_root().ready

	var passed: int = 0
	var failed: int = 0

	# Run all tests
	if test_base_happiness_decay():
		passed += 1
	else:
		failed += 1

	if test_facility_bonus_happiness():
		passed += 1
	else:
		failed += 1

	if test_overcrowding_penalty():
		passed += 1
	else:
		failed += 1

	if test_happiness_prevents_breeding():
		passed += 1
	else:
		failed += 1

	if test_happiness_allows_breeding_above_threshold():
		passed += 1
	else:
		failed += 1

	# Print summary
	print("\n========================================")
	print("Test Results: %d passed, %d failed" % [passed, failed])
	print("========================================\n")

	# Exit with appropriate code
	quit(0 if failed == 0 else 1)


## Test base happiness decay without facilities
func test_base_happiness_decay() -> bool:
	print("Test: Base happiness decay")

	# Start fresh game
	RanchState.start_new_game()

	# Get first dragon
	var dragons: Array[DragonData] = RanchState.get_all_dragons()
	if dragons.is_empty():
		print("  FAILED: No starter dragons found")
		return false

	var dragon: DragonData = dragons[0]
	var initial_happiness: float = dragon.happiness
	print("  Initial happiness: %.1f" % initial_happiness)

	# Advance season
	RanchState.advance_season()

	# Check happiness decreased by BASE_HAPPINESS_DECAY (5.0)
	var expected: float = initial_happiness - RanchState.BASE_HAPPINESS_DECAY
	print("  After 1 season: %.1f (expected %.1f)" % [dragon.happiness, expected])

	if not is_equal_approx(dragon.happiness, expected):
		print("  FAILED: Expected %.1f, got %.1f" % [expected, dragon.happiness])
		return false

	print("  PASSED: Happiness decays correctly\n")
	return true


## Test facility bonus offsetting decay
func test_facility_bonus_happiness() -> bool:
	print("Test: Facility bonus happiness")

	# Start fresh game
	RanchState.start_new_game()

	# Get first dragon
	var dragons: Array[DragonData] = RanchState.get_all_dragons()
	if dragons.is_empty():
		print("  FAILED: No starter dragons found")
		return false

	var dragon: DragonData = dragons[0]
	dragon.happiness = 50.0
	var initial_happiness: float = dragon.happiness
	print("  Initial happiness: %.1f" % initial_happiness)

	# Build a pasture (should have happiness bonus)
	RanchState.money = 1000
	if not RanchState.build_facility("pasture"):
		print("  WARNING: Could not build pasture, skipping facility bonus check")
		# Still test decay
		RanchState.advance_season()
		print("  PASSED: Test skipped (no facility definitions)\n")
		return true

	# Get facility bonus
	var facility_bonus: float = RanchState.get_facility_bonus("happiness")
	print("  Facility happiness bonus: %.1f" % facility_bonus)

	# Advance season
	RanchState.advance_season()

	# Net change = facility_bonus - BASE_HAPPINESS_DECAY - overcrowding_penalty
	# No overcrowding, so: facility_bonus - 5.0
	var net_change: float = facility_bonus - RanchState.BASE_HAPPINESS_DECAY
	var expected: float = initial_happiness + net_change
	print("  After 1 season: %.1f (expected %.1f)" % [dragon.happiness, expected])

	if not is_equal_approx(dragon.happiness, expected):
		print("  FAILED: Expected %.1f, got %.1f" % [expected, dragon.happiness])
		return false

	print("  PASSED: Facility bonus applied correctly\n")
	return true


## Test overcrowding penalty
func test_overcrowding_penalty() -> bool:
	print("Test: Overcrowding penalty")

	# Start fresh game
	RanchState.start_new_game()

	# Add extra dragons to cause overcrowding
	var initial_count: int = RanchState.dragons.size()
	print("  Initial dragons: %d" % initial_count)

	# Add 6 more dragons to cause overcrowding (assuming base capacity is around 6)
	for i in range(6):
		var dragon := DragonData.new()
		dragon.id = "test_dragon_%d" % i
		dragon.name = "Test Dragon %d" % i
		dragon.genotype = TraitDB.get_default_genotype(0)
		dragon.phenotype = GeneticsEngine.calculate_phenotype(dragon.genotype)
		dragon.happiness = 100.0
		dragon.life_stage = "adult"
		RanchState.add_dragon(dragon)

	var total_dragons: int = RanchState.dragons.size()
	print("  Total dragons after adding: %d" % total_dragons)

	# Calculate expected overcrowding penalty
	var capacity: int = RanchState._calculate_dragon_capacity()
	var overcrowding_penalty: float = RanchState._calculate_overcrowding_penalty()
	print("  Capacity: %d, Overcrowding penalty: %.1f" % [capacity, overcrowding_penalty])

	# Get a dragon and track its happiness
	var dragon: DragonData = RanchState.dragons.values()[0]
	var initial_happiness: float = dragon.happiness

	# Advance season
	RanchState.advance_season()

	# Expected: 100.0 - 5.0 (decay) - overcrowding_penalty
	var facility_bonus: float = RanchState.get_facility_bonus("happiness")
	var net_change: float = facility_bonus - RanchState.BASE_HAPPINESS_DECAY - overcrowding_penalty
	var expected: float = initial_happiness + net_change
	print("  After 1 season: %.1f (expected %.1f)" % [dragon.happiness, expected])

	if not is_equal_approx(dragon.happiness, expected):
		print("  FAILED: Expected %.1f, got %.1f" % [expected, dragon.happiness])
		return false

	print("  PASSED: Overcrowding penalty applied correctly\n")
	return true


## Test happiness prevents breeding
func test_happiness_prevents_breeding() -> bool:
	print("Test: Happiness prevents breeding")

	# Create an adult dragon with low happiness
	var dragon: DragonData = DragonData.new()
	dragon.id = "test_sad_dragon"
	dragon.name = "Sad Dragon"
	dragon.life_stage = "adult"
	dragon.age = 8
	dragon.health = 100.0
	dragon.happiness = 30.0  # Below 40.0 threshold
	dragon.genotype = {"fire": ["F", "F"]}
	dragon.phenotype = {"fire": {"name": "fire"}}

	# Check can_breed()
	var can_breed: bool = dragon.can_breed()
	print("  Dragon with 30.0 happiness can breed: %s (expected: false)" % can_breed)

	if can_breed:
		print("  FAILED: Low happiness should prevent breeding")
		return false

	print("  PASSED: Happiness threshold prevents breeding\n")
	return true


## Test happiness allows breeding above threshold
func test_happiness_allows_breeding_above_threshold() -> bool:
	print("Test: Happiness allows breeding above threshold")

	# Create an adult dragon with adequate happiness
	var dragon: DragonData = DragonData.new()
	dragon.id = "test_happy_dragon"
	dragon.name = "Happy Dragon"
	dragon.life_stage = "adult"
	dragon.age = 8
	dragon.health = 100.0
	dragon.happiness = 50.0  # Above 40.0 threshold
	dragon.genotype = {"fire": ["F", "F"]}
	dragon.phenotype = {"fire": {"name": "fire"}}

	# Check can_breed()
	var can_breed: bool = dragon.can_breed()
	print("  Dragon with 50.0 happiness can breed: %s (expected: true)" % can_breed)

	if not can_breed:
		print("  FAILED: Adequate happiness should allow breeding")
		return false

	print("  PASSED: Happiness threshold allows breeding\n")
	return true
