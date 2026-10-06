# test_reputation.gd
# Unit tests for reputation and progression system
# Part of Dragon Ranch - Session 8 Progression System

extends SceneTree

# Plain-script port of the former GutTest suite (GUT addon is not installed).
# Run with: godot --headless --path . --script tests/progression/test_reputation.gd
# Autoloads are not registered as global identifiers in --script mode, so this
# member shadows it and is bound to the live /root node in _init().
var RanchState: Node = null

var _checks_failed: int = 0
var _checks_total: int = 0
var _signal_counts: Dictionary = {}
var _connections: Array[Dictionary] = []


func _init() -> void:
	print("
========================================")
	print("Running Reputation & Progression Tests")
	print("========================================
")

	await get_root().ready
	RanchState = root.get_node("/root/RanchState")

	var passed: int = 0
	var failed: int = 0

	for test_name: String in ["test_reputation_levels", "test_level_names", "test_earnings_for_next_level", "test_trait_unlocking", "test_ranchstate_reputation", "test_achievements", "test_full_house_achievement", "test_expansion_achievement"]:
		var before: int = _checks_failed
		print("Test: %s" % test_name)
		call(test_name)
		if _checks_failed == before:
			print("  PASSED
")
			passed += 1
		else:
			print("  FAILED
")
			failed += 1

	print("
========================================")
	print("Test Results: %d passed, %d failed (%d assertions)" % [passed, failed, _checks_total])
	print("========================================
")

	quit(0 if failed == 0 else 1)


# === ASSERT HELPERS (replace GUT) ===

func assert_eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	_checks_total += 1
	if actual != expected:
		_checks_failed += 1
		print("  ASSERT FAILED: expected %s, got %s %s" % [str(expected), str(actual), msg])


func assert_true(value: bool, msg: String = "") -> void:
	_checks_total += 1
	if not value:
		_checks_failed += 1
		print("  ASSERT FAILED: expected true %s" % msg)


func assert_false(value: bool, msg: String = "") -> void:
	_checks_total += 1
	if value:
		_checks_failed += 1
		print("  ASSERT FAILED: expected false %s" % msg)


## Start counting emissions of every signal declared on the node's script.
## Disconnects handlers from any previous watch first.
func _watch(node: Node) -> void:
	for conn: Dictionary in _connections:
		if is_instance_valid(conn["node"]) and conn["node"].is_connected(conn["signal"], conn["callable"]):
			conn["node"].disconnect(conn["signal"], conn["callable"])
	_connections.clear()
	_signal_counts.clear()
	for sig: Dictionary in node.get_script().get_script_signal_list():
		var sig_name: String = sig["name"]
		var arg_count: int = (sig["args"] as Array).size()
		var handler: Callable = _on_signal.bind(sig_name).unbind(arg_count)
		_signal_counts[sig_name] = 0
		node.connect(sig_name, handler)
		_connections.append({"node": node, "signal": sig_name, "callable": handler})


func _on_signal(sig_name: String) -> void:
	_signal_counts[sig_name] = int(_signal_counts.get(sig_name, 0)) + 1


func assert_signal_emitted(sig_name: String) -> void:
	_checks_total += 1
	if int(_signal_counts.get(sig_name, 0)) == 0:
		_checks_failed += 1
		print("  ASSERT FAILED: signal %s not emitted" % sig_name)


func assert_signal_not_emitted(sig_name: String) -> void:
	_checks_total += 1
	if int(_signal_counts.get(sig_name, 0)) != 0:
		_checks_failed += 1
		print("  ASSERT FAILED: signal %s was emitted" % sig_name)


func assert_signal_emit_count(sig_name: String, expected: int) -> void:
	_checks_total += 1
	var actual: int = int(_signal_counts.get(sig_name, 0))
	if actual != expected:
		_checks_failed += 1
		print("  ASSERT FAILED: signal %s emitted %d times, expected %d" % [sig_name, actual, expected])


# === TESTS ===

# Test reputation level calculation
func test_reputation_levels() -> void:
	assert_eq(Progression.get_reputation_level(0), 0, "Level 0: Novice at $0")
	assert_eq(Progression.get_reputation_level(4999), 0, "Level 0: Just below threshold")
	assert_eq(Progression.get_reputation_level(5000), 1, "Level 1: Established at $5000")
	assert_eq(Progression.get_reputation_level(19999), 1, "Level 1: Just below next")
	assert_eq(Progression.get_reputation_level(20000), 2, "Level 2: Expert at $20000")
	assert_eq(Progression.get_reputation_level(50000), 3, "Level 3: Master at $50000")
	assert_eq(Progression.get_reputation_level(100000), 4, "Level 4: Legendary at $100000")
	assert_eq(Progression.get_reputation_level(999999), 4, "Level 4: Cap at legendary")


# Test level names
func test_level_names() -> void:
	assert_eq(Progression.get_level_name(0), "Novice Breeder")
	assert_eq(Progression.get_level_name(1), "Established Breeder")
	assert_eq(Progression.get_level_name(2), "Expert Breeder")
	assert_eq(Progression.get_level_name(3), "Master Breeder")
	assert_eq(Progression.get_level_name(4), "Legendary Breeder")


# Test earnings for next level
func test_earnings_for_next_level() -> void:
	assert_eq(Progression.get_earnings_for_next_level(0), 5000, "Level 0 -> 1: $5000")
	assert_eq(Progression.get_earnings_for_next_level(1), 20000, "Level 1 -> 2: $20000")
	assert_eq(Progression.get_earnings_for_next_level(2), 50000, "Level 2 -> 3: $50000")
	assert_eq(Progression.get_earnings_for_next_level(3), 100000, "Level 3 -> 4: $100000")
	assert_eq(Progression.get_earnings_for_next_level(4), 0, "Level 4 is max")


# Test trait unlocking
func test_trait_unlocking() -> void:
	var traits_0: Array[String] = Progression.get_unlocked_traits(0)
	assert_eq(traits_0.size(), 3, "Level 0 has 3 traits")
	assert_true(traits_0.has("fire"), "Fire unlocked at 0")
	assert_true(traits_0.has("wings"), "Wings unlocked at 0")
	assert_true(traits_0.has("armor"), "Armor unlocked at 0")

	# Higher levels include all lower level traits
	var traits_4: Array[String] = Progression.get_unlocked_traits(4)
	assert_true(traits_4.has("fire"), "Fire still unlocked at 4")
	assert_true(traits_4.has("wings"), "Wings still unlocked at 4")
	assert_true(traits_4.has("armor"), "Armor still unlocked at 4")


# Test reputation increases in RanchState
func test_ranchstate_reputation() -> void:
	RanchState.start_new_game()

	assert_eq(RanchState.reputation, 0, "Start at level 0")
	assert_eq(RanchState.lifetime_earnings, 0, "Start at $0 earnings")

	# Earn some money
	_watch(RanchState)
	RanchState.add_money(3000)
	assert_eq(RanchState.lifetime_earnings, 3000, "Lifetime earnings tracked")
	assert_eq(RanchState.reputation, 0, "Still level 0")
	assert_signal_not_emitted("reputation_increased")

	# Cross threshold to level 1
	RanchState.add_money(2500)  # Total: 5500
	assert_eq(RanchState.lifetime_earnings, 5500, "Earnings at 5500")
	assert_eq(RanchState.reputation, 1, "Promoted to level 1")
	assert_signal_emitted("reputation_increased")
	assert_signal_emit_count("reputation_increased", 1)

	# Add more within same level
	RanchState.add_money(5000)  # Total: 10500
	assert_eq(RanchState.reputation, 1, "Still level 1")


# Test achievements unlocking
func test_achievements() -> void:
	RanchState.start_new_game()

	# First sale achievement
	assert_false(RanchState.achievements.has("first_sale"), "No first sale yet")
	_watch(RanchState)
	RanchState.add_money(100)
	RanchState._check_achievements()
	assert_true(RanchState.achievements.has("first_sale"), "First sale unlocked")
	assert_signal_emitted("achievement_unlocked")

	# Wealthy achievement
	assert_false(RanchState.achievements.has("wealthy"), "Not wealthy yet")
	RanchState.add_money(10000)  # Total: 10100
	RanchState._check_achievements()
	assert_true(RanchState.achievements.has("wealthy"), "Wealthy unlocked")

	# Check achievement season tracking
	assert_eq(RanchState.achievements["first_sale"], 1, "First sale on season 1")


# Test full house achievement
func test_full_house_achievement() -> void:
	RanchState.start_new_game()

	# Start with 2 dragons
	assert_eq(RanchState.dragons.size(), 2, "Start with 2 dragons")
	assert_false(RanchState.achievements.has("full_house"), "No full house yet")

	# Add dragons to reach 6
	for i in range(4):
		var dragon := DragonData.new()
		dragon.name = "Test %d" % i
		dragon.genotype = {"fire": ["F", "f"]}
		dragon.phenotype = {"fire": "fire"}
		dragon.age = 1
		dragon.life_stage = "hatchling"
		RanchState.add_dragon(dragon)

	assert_eq(RanchState.dragons.size(), 6, "Have 6 dragons")
	assert_true(RanchState.achievements.has("full_house"), "Full house unlocked")


# Test expansion achievement
func test_expansion_achievement() -> void:
	RanchState.start_new_game()
	RanchState.money = 5000  # Give money for facilities

	assert_false(RanchState.achievements.has("expansion"), "No expansion yet")

	# Build 3 facilities
	RanchState.build_facility("stable")
	assert_false(RanchState.achievements.has("expansion"), "1 facility not enough")

	RanchState.build_facility("pasture")
	assert_false(RanchState.achievements.has("expansion"), "2 facilities not enough")

	RanchState.build_facility("nursery")
	assert_true(RanchState.achievements.has("expansion"), "Expansion unlocked")
