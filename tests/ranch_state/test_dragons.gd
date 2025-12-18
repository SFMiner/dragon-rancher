# test_dragons.gd
# Unit tests for dragon management in RanchState

extends SceneTree

func _init() -> void:
	print("\n========================================")
	print("Running RanchState Dragon Tests")
	print("========================================\n")

	await get_root().ready

	var passed: int = 0
	var failed: int = 0

	if test_add_remove_dragons():
		passed += 1
	else:
		failed += 1

	if test_adult_filtering():
		passed += 1
	else:
		failed += 1

	if test_dragon_retrieval():
		passed += 1
	else:
		failed += 1

	print("\n========================================")
	print("Test Results: %d passed, %d failed" % [passed, failed])
	print("========================================\n")

	quit(0 if failed == 0 else 1)


func test_add_remove_dragons() -> bool:
	print("Test: Add/remove dragons")

	RanchState.reset_game()
	var initial_count: int = RanchState.dragons.size()

	# Create a test dragon
	var dragon := DragonData.new()
	dragon.name = "Test Dragon"
	dragon.sex = "male"
	dragon.genotype = {"fire": ["F", "f"]}
	dragon.phenotype = GeneticsEngine.calculate_phenotype(dragon.genotype)
	dragon.life_stage = "adult"
	dragon.age = 5

	var dragon_id: String = RanchState.add_dragon(dragon)

	if dragon_id.is_empty():
		print("  FAILED: add_dragon returned empty ID\n")
		return false

	if RanchState.dragons.size() != initial_count + 1:
		print("  FAILED: Dragon count should increase\n")
		return false

	# Remove dragon
	RanchState.remove_dragon(dragon_id)

	if RanchState.dragons.size() != initial_count:
		print("  FAILED: Dragon count should decrease\n")
		return false

	print("  PASSED: Dragons added and removed correctly\n")
	return true


func test_adult_filtering() -> bool:
	print("Test: Adult dragon filtering")

	RanchState.reset_game()

	# Add a hatchling
	var hatchling := DragonData.new()
	hatchling.name = "Baby"
	hatchling.sex = "female"
	hatchling.genotype = {"fire": ["f", "f"]}
	hatchling.phenotype = GeneticsEngine.calculate_phenotype(hatchling.genotype)
	hatchling.life_stage = "hatchling"
	hatchling.age = 0
	hatchling.health = 100.0

	RanchState.add_dragon(hatchling)

	var adults: Array[DragonData] = RanchState.get_adult_dragons()
	var all_dragons: Array[DragonData] = RanchState.get_all_dragons()

	# Adults should be less than or equal to all dragons
	if adults.size() > all_dragons.size():
		print("  FAILED: Adult count can't exceed total count\n")
		return false

	# Check that all returned dragons can breed
	for dragon in adults:
		if not Lifecycle.can_breed(dragon):
			print("  FAILED: get_adult_dragons returned non-breeding dragon\n")
			return false

	print("  PASSED: Adult filtering works (found %d adults out of %d dragons)\n" % [adults.size(), all_dragons.size()])
	return true


func test_dragon_retrieval() -> bool:
	print("Test: Dragon retrieval")

	RanchState.reset_game()

	var dragons: Array[DragonData] = RanchState.get_all_dragons()
	if dragons.is_empty():
		print("  FAILED: No dragons to test\n")
		return false

	var dragon: DragonData = dragons[0]
	var retrieved: DragonData = RanchState.get_dragon(dragon.id)

	if retrieved == null:
		print("  FAILED: Couldn't retrieve dragon by ID\n")
		return false

	if retrieved.id != dragon.id:
		print("  FAILED: Retrieved wrong dragon\n")
		return false

	# Test non-existent dragon
	var missing: DragonData = RanchState.get_dragon("nonexistent_id")
	if missing != null:
		print("  FAILED: Should return null for missing dragon\n")
		return false

	print("  PASSED: Dragon retrieval works correctly\n")
	return true
