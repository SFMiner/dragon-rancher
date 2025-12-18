# test_reputation.gd
# Unit tests for reputation and progression system
# Part of Dragon Ranch - Session 8 Progression System

extends GutTest

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
	watch_signals(RanchState)
	RanchState.add_money(3000)
	assert_eq(RanchState.lifetime_earnings, 3000, "Lifetime earnings tracked")
	assert_eq(RanchState.reputation, 0, "Still level 0")
	assert_signal_not_emitted(RanchState, "reputation_increased")

	# Cross threshold to level 1
	RanchState.add_money(2500)  # Total: 5500
	assert_eq(RanchState.lifetime_earnings, 5500, "Earnings at 5500")
	assert_eq(RanchState.reputation, 1, "Promoted to level 1")
	assert_signal_emitted(RanchState, "reputation_increased")
	assert_signal_emit_count(RanchState, "reputation_increased", 1)

	# Add more within same level
	RanchState.add_money(5000)  # Total: 10500
	assert_eq(RanchState.reputation, 1, "Still level 1")


# Test achievements unlocking
func test_achievements() -> void:
	RanchState.start_new_game()

	# First sale achievement
	assert_false(RanchState.achievements.has("first_sale"), "No first sale yet")
	watch_signals(RanchState)
	RanchState.add_money(100)
	RanchState._check_achievements()
	assert_true(RanchState.achievements.has("first_sale"), "First sale unlocked")
	assert_signal_emitted(RanchState, "achievement_unlocked")

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
