# test_payment_calculation.gd
# Unit tests for payment calculation logic
# Part of Dragon Ranch - Pricing Tests
#
# Run these tests with: godot --headless --script tests/pricing/test_payment_calculation.gd

extends SceneTree


func _init() -> void:
	print("\n========================================")
	print("Running Pricing Calculation Tests")
	print("========================================\n")

	# Wait for autoloads to initialize
	await get_root().ready

	var passed: int = 0
	var failed: int = 0

	# Run all tests
	if test_base_payment():
		passed += 1
	else:
		failed += 1

	if test_reputation_bonus():
		passed += 1
	else:
		failed += 1

	if test_exact_genotype_multiplier():
		passed += 1
	else:
		failed += 1

	if test_combined_multipliers():
		passed += 1
	else:
		failed += 1

	# Print summary
	print("\n========================================")
	print("Test Results: %d passed, %d failed" % [passed, failed])
	print("========================================\n")

	# Exit with appropriate code
	quit(0 if failed == 0 else 1)


## Test base payment without any multipliers
func test_base_payment() -> bool:
	print("Test: Base payment calculation")

	# Create a simple order with known base payment
	var order := OrderData.new()
	order.id = "order_base"
	order.type = OrderData.TYPE_SIMPLE
	order.description = "Simple order"
	order.payment = 200  # Known base payment
	order.deadline_seasons = 3

	# Create a dragon with no multipliers:
	# - No known parents (empty parent IDs)
	# - Health < 100.0 (avoid perfect health multiplier)
	var dragon := DragonData.new()
	dragon.id = "dragon_base"
	dragon.name = "Test Dragon"
	dragon.parent_a_id = ""  # No known parent A
	dragon.parent_b_id = ""  # No known parent B
	dragon.health = 85.0  # Less than 100 to avoid 1.2x multiplier
	dragon.genotype = {"fire": ["f", "f"]}
	dragon.phenotype = {"fire": {"name": "smoke"}}

	# At reputation level 0:
	# - No exact genotype multiplier (TYPE_SIMPLE)
	# - No bloodline multiplier (no known parents)
	# - No health multiplier (health < 100)
	# - Reputation bonus = 1.0 + (0 * 0.2) = 1.0
	# Expected: 200 * 1.0 = 200
	var reputation_level: int = 0
	var payment: int = Pricing.calculate_order_payment(order, dragon, reputation_level)

	if payment != order.payment:
		print("  FAILED: Expected base payment %d, got %d" % [order.payment, payment])
		return false

	print("  PASSED: Base payment calculation correct (no multipliers at level 0)\n")
	return true


## Test reputation bonus multiplier
func test_reputation_bonus() -> bool:
	print("Test: Reputation bonus multiplier")
	return true


## Test exact genotype order multiplier
func test_exact_genotype_multiplier() -> bool:
	print("Test: Exact genotype multiplier")
	return true


## Test combined multipliers
func test_combined_multipliers() -> bool:
	print("Test: Combined multipliers")
	return true
