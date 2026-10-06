# test_time.gd
# Unit tests for time progression in RanchState
# Part of Dragon Ranch - Session 4 RanchState & Time System

extends SceneTree

# Autoloads are not registered as global identifiers in --script mode, so these
# members shadow them and are bound to the live /root nodes in _init().
var RanchState: Node = null
var RNGService: Node = null

func _init() -> void:
	print("\n========================================")
	print("Running RanchState Time Tests")
	print("========================================\n")

	await get_root().ready
	RanchState = root.get_node("/root/RanchState")
	RNGService = root.get_node("/root/RNGService")

	var passed: int = 0
	var failed: int = 0

	if test_season_advancement():
		passed += 1
	else:
		failed += 1

	if test_dragon_aging():
		passed += 1
	else:
		failed += 1

	if test_egg_hatching():
		passed += 1
	else:
		failed += 1

	print("\n========================================")
	print("Test Results: %d passed, %d failed" % [passed, failed])
	print("========================================\n")

	quit(0 if failed == 0 else 1)


func test_season_advancement() -> bool:
	print("Test: Season advancement")

	RanchState.reset_game()
	var initial_season: int = RanchState.current_season

	RanchState.advance_season()

	if RanchState.current_season != initial_season + 1:
		print("  FAILED: Season should advance by 1\n")
		return false

	print("  PASSED: Season advanced from %d to %d\n" % [initial_season, RanchState.current_season])
	return true


func test_dragon_aging() -> bool:
	print("Test: Dragon aging")

	RanchState.reset_game()

	# Get a dragon
	var dragons: Array[DragonData] = RanchState.get_all_dragons()
	if dragons.is_empty():
		print("  FAILED: No dragons to test\n")
		return false

	var dragon: DragonData = dragons[0]
	var initial_age: int = dragon.age
	var initial_stage: String = dragon.life_stage

	# Advance season
	RanchState.advance_season()

	if dragon.age != initial_age + 1:
		print("  FAILED: Dragon age should increase by 1\n")
		return false

	print("  PASSED: Dragon aged from %d to %d (stage: %s)\n" % [initial_age, dragon.age, dragon.life_stage])
	return true


func test_egg_hatching() -> bool:
	print("Test: Egg hatching")

	# Deterministic RNG (egg count, incubation, escape rolls)
	RNGService.set_seed(12345)
	RanchState.reset_game()

	# Get two adult dragons to breed
	var adults: Array[DragonData] = RanchState.get_adult_dragons()
	if adults.size() < 2:
		print("  FAILED: Need 2 adult dragons\n")
		return false

	# Create eggs
	var egg_ids: Array[String] = RanchState.create_egg(adults[0].id, adults[1].id)
	if egg_ids.is_empty():
		print("  FAILED: Couldn't create eggs\n")
		return false

	# Set incubation to 1 season (will hatch next season)
	for egg_id in egg_ids:
		if RanchState.eggs.has(egg_id):
			RanchState.eggs[egg_id].incubation_seasons_remaining = 1

	var initial_dragon_count: int = RanchState.dragons.size()

	# Track hatches and removals: advance_season() also rolls dragon escapes
	# (docility), which legitimately remove dragons in the same call.
	var hatched: Array[String] = []
	var removed: Array[String] = []
	var on_hatched: Callable = func(egg_id: String, _dragon_id: String) -> void: hatched.append(egg_id)
	var on_removed: Callable = func(dragon_id: String) -> void: removed.append(dragon_id)
	RanchState.egg_hatched.connect(on_hatched)
	RanchState.dragon_removed.connect(on_removed)

	# Advance season (should hatch)
	RanchState.advance_season()

	RanchState.egg_hatched.disconnect(on_hatched)
	RanchState.dragon_removed.disconnect(on_removed)

	# Check eggs hatched
	for egg_id in egg_ids:
		if RanchState.eggs.has(egg_id):
			print("  FAILED: Egg should have hatched\n")
			return false

	if hatched.size() != egg_ids.size():
		print("  FAILED: Expected %d eggs to hatch, got %d\n" % [egg_ids.size(), hatched.size()])
		return false

	# Capacity is soft (add_dragon only warns), so every hatch adds a dragon;
	# escapes during the same season are the only legitimate subtraction.
	var expected_count: int = initial_dragon_count + egg_ids.size() - removed.size()
	if RanchState.dragons.size() != expected_count:
		print("  FAILED: Dragon count should be %d after hatching %d eggs (%d escaped), got %d\n" % [expected_count, egg_ids.size(), removed.size(), RanchState.dragons.size()])
		return false

	print("  PASSED: Egg hatched successfully\n")
	return true
