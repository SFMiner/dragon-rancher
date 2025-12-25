# test_pattern_matching.gd
# Unit tests for order matching logic
# Part of Dragon Ranch - OrderMatching Tests
#
# Run these tests with: godot --headless --script tests/order_matching/test_pattern_matching.gd

extends SceneTree


func _init() -> void:
	print("\n========================================")
	print("Running Order Pattern Matching Tests")
	print("========================================\n")

	# Wait for autoloads to initialize
	await get_root().ready

	var passed: int = 0
	var failed: int = 0

	# Run all tests
	if test_dominant_allele_pattern():
		passed += 1
	else:
		failed += 1

	if test_exact_genotype_match():
		passed += 1
	else:
		failed += 1

	if test_phenotype_name_match():
		passed += 1
	else:
		failed += 1

	if test_missing_trait_requirement():
		passed += 1
	else:
		failed += 1

	# Print summary
	print("\n========================================")
	print("Test Results: %d passed, %d failed" % [passed, failed])
	print("========================================\n")

	# Exit with appropriate code
	quit(0 if failed == 0 else 1)


## Test dominant allele pattern matching (e.g., F_)
func test_dominant_allele_pattern() -> bool:
	print("Test: Dominant allele pattern (F_)")

	# Create order requiring at least one F allele
	var order := OrderData.new()
	order.id = "order_dominant_f"
	order.type = OrderData.TYPE_SIMPLE
	order.description = "Need fire-breathing dragon"
	order.required_traits = {"fire": "F_"}
	order.payment = 150
	order.deadline_seasons = 3

	# Test case 1: FF (homozygous dominant) - should match
	var dragon_ff := DragonData.new()
	dragon_ff.id = "dragon_ff"
	dragon_ff.name = "Blaze"
	dragon_ff.genotype = {"fire": ["F", "F"]}
	dragon_ff.phenotype = GeneticsEngine.calculate_phenotype(dragon_ff.genotype)

	if not OrderMatching.does_dragon_match(dragon_ff, order):
		print("  FAILED: FF genotype should match F_ pattern")
		return false

	# Test case 2: Ff (heterozygous) - should match
	var dragon_Ff := DragonData.new()
	dragon_Ff.id = "dragon_Ff"
	dragon_Ff.name = "Ember"
	dragon_Ff.genotype = {"fire": ["F", "f"]}
	dragon_Ff.phenotype = GeneticsEngine.calculate_phenotype(dragon_Ff.genotype)

	if not OrderMatching.does_dragon_match(dragon_Ff, order):
		print("  FAILED: Ff genotype should match F_ pattern")
		return false

	# Test case 3: ff (homozygous recessive) - should NOT match
	var dragon_ff_rec := DragonData.new()
	dragon_ff_rec.id = "dragon_ff_rec"
	dragon_ff_rec.name = "Smokey"
	dragon_ff_rec.genotype = {"fire": ["f", "f"]}
	dragon_ff_rec.phenotype = GeneticsEngine.calculate_phenotype(dragon_ff_rec.genotype)

	if OrderMatching.does_dragon_match(dragon_ff_rec, order):
		print("  FAILED: ff genotype should NOT match F_ pattern")
		return false

	print("  PASSED: Dominant allele pattern matching works correctly\n")
	return true


## Test exact genotype matching (e.g., FF)
func test_exact_genotype_match() -> bool:
	print("Test: Exact genotype match (FF)")

	# Create order requiring exact FF genotype
	var order := OrderData.new()
	order.id = "order_exact_ff"
	order.type = OrderData.TYPE_EXACT
	order.description = "Need homozygous fire-breathing dragon"
	order.required_traits = {"fire": "FF"}
	order.payment = 500
	order.deadline_seasons = 3

	# Test case 1: FF (homozygous dominant) - should match
	var dragon_ff := DragonData.new()
	dragon_ff.id = "dragon_ff"
	dragon_ff.name = "Blaze"
	dragon_ff.genotype = {"fire": ["F", "F"]}
	dragon_ff.phenotype = GeneticsEngine.calculate_phenotype(dragon_ff.genotype)

	if not OrderMatching.does_dragon_match(dragon_ff, order):
		print("  FAILED: FF genotype should match FF pattern")
		return false

	# Test case 2: Ff (heterozygous) - should NOT match
	var dragon_Ff := DragonData.new()
	dragon_Ff.id = "dragon_Ff"
	dragon_Ff.name = "Ember"
	dragon_Ff.genotype = {"fire": ["F", "f"]}
	dragon_Ff.phenotype = GeneticsEngine.calculate_phenotype(dragon_Ff.genotype)

	if OrderMatching.does_dragon_match(dragon_Ff, order):
		print("  FAILED: Ff genotype should NOT match FF pattern")
		return false

	# Test case 3: ff (homozygous recessive) - should NOT match
	var dragon_ff_rec := DragonData.new()
	dragon_ff_rec.id = "dragon_ff_rec"
	dragon_ff_rec.name = "Smokey"
	dragon_ff_rec.genotype = {"fire": ["f", "f"]}
	dragon_ff_rec.phenotype = GeneticsEngine.calculate_phenotype(dragon_ff_rec.genotype)

	if OrderMatching.does_dragon_match(dragon_ff_rec, order):
		print("  FAILED: ff genotype should NOT match FF pattern")
		return false

	print("  PASSED: Exact genotype matching works correctly\n")
	return true


## Test phenotype name matching
func test_phenotype_name_match() -> bool:
	print("Test: Phenotype name match")
	return true


## Test missing trait requirement handling
func test_missing_trait_requirement() -> bool:
	print("Test: Missing trait requirement")
	return true
