# test_resources.gd
# Unit tests for resource management in RanchState

extends SceneTree

func _init() -> void:
	print("\n========================================")
	print("Running RanchState Resource Tests")
	print("========================================\n")

	await get_root().ready

	var passed: int = 0
	var failed: int = 0

	if test_money_transactions():
		passed += 1
	else:
		failed += 1

	if test_food_consumption():
		passed += 1
	else:
		failed += 1

	if test_insufficient_resources():
		passed += 1
	else:
		failed += 1

	print("\n========================================")
	print("Test Results: %d passed, %d failed" % [passed, failed])
	print("========================================\n")

	quit(0 if failed == 0 else 1)


func test_money_transactions() -> bool:
	print("Test: Money transactions")

	RanchState.reset_game()
	var initial_money: int = RanchState.money

	# Add money
	RanchState.add_money(100)
	if RanchState.money != initial_money + 100:
		print("  FAILED: add_money didn't update money\n")
		return false

	# Spend money (affordable)
	var success: bool = RanchState.spend_money(50)
	if not success:
		print("  FAILED: spend_money failed when affordable\n")
		return false

	if RanchState.money != initial_money + 50:
		print("  FAILED: spend_money didn't deduct correctly\n")
		return false

	# Try to spend too much
	success = RanchState.spend_money(RanchState.money + 100)
	if success:
		print("  FAILED: spend_money should fail when can't afford\n")
		return false

	print("  PASSED: Money transactions work correctly\n")
	return true


func test_food_consumption() -> bool:
	print("Test: Food consumption")

	RanchState.reset_game()

	# Calculate expected consumption
	var expected: int = RanchState.calculate_food_consumption()

	if expected <= 0:
		print("  FAILED: Food consumption should be positive with dragons\n")
		return false

	# Check it's reasonable (5 food per dragon, modified by stage)
	var dragon_count: int = RanchState.dragons.size()
	if expected > dragon_count * 10:
		print("  FAILED: Food consumption seems too high\n")
		return false

	print("  PASSED: Food consumption calculated (%d for %d dragons)\n" % [expected, dragon_count])
	return true


func test_insufficient_resources() -> bool:
	print("Test: Insufficient resources")

	RanchState.reset_game()

	# Set food to very low
	RanchState.food_supply = 5

	# Get initial dragon health
	var dragons: Array[DragonData] = RanchState.get_all_dragons()
	if dragons.is_empty():
		print("  FAILED: No dragons to test\n")
		return false

	var initial_health: float = dragons[0].health

	# Advance season (should fail to feed dragons)
	RanchState.advance_season()

	# Dragons should lose health
	if dragons[0].health >= initial_health:
		print("  FAILED: Dragons should lose health when underfed\n")
		return false

	print("  PASSED: Dragons lose health when food insufficient\n")
	return true
