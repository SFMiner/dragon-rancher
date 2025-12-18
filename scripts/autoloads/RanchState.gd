# RanchState.gd
# Central game state manager
# Part of Dragon Ranch - Session 4 RanchState & Time System
#
# Manages all game state including dragons, eggs, resources, and time progression

extends Node

## Signals for game events
signal season_changed(new_season: int)
signal dragon_added(dragon_id: String)
signal dragon_removed(dragon_id: String)
signal egg_created(egg_id: String)
signal egg_hatched(egg_id: String, dragon_id: String)
signal order_accepted(order_id: String)
signal order_completed(order_id: String, payment: int)
signal reputation_increased(new_level: int)
signal facility_built(facility_id: String)
signal money_changed(new_amount: int)
signal food_changed(new_amount: int)
signal achievement_unlocked(achievement_id: String)

## Current season number (increments over time)
var current_season: int = 1

## Player's money
var money: int = 500

## Player's reputation level (0-4)
var reputation: int = 0

## Player's lifetime earnings (for reputation calculation)
var lifetime_earnings: int = 0

## Unlocked achievements: achievement_id -> unlock_season
var achievements: Dictionary = {}

## Food supply
var food_supply: int = 100

## All dragons: dragon_id -> DragonData
var dragons: Dictionary = {}

## All eggs: egg_id -> EggData
var eggs: Dictionary = {}

## All facilities: facility_id -> FacilityData
var facilities: Dictionary = {}

## Active orders
var active_orders: Array = []

## Time speed multiplier (for UI feedback only, not core logic)
var time_speed: float = 1.0

## Base dragon capacity (from starter ranch)
const BASE_CAPACITY: int = 6

## Food consumption per dragon per season
const FOOD_PER_DRAGON: int = 5


# === ORDER MANAGEMENT ===

func accept_order(order: OrderData) -> void:
	if order == null:
		return
	order.accepted_season = current_season
	active_orders.append(order)
	order_accepted.emit(order.id)
	print("[RanchState] Accepted order: %s" % order.description)

func fulfill_order(order_id: String, dragon_id: String) -> bool:
	var order: OrderData = null
	for o in active_orders:
		if o.id == order_id:
			order = o
			break
	if order == null:
		return false
	var dragon: DragonData = get_dragon(dragon_id)
	if dragon == null:
		return false
	if not OrderMatching.does_dragon_match(dragon, order):
		return false
	var payment: int = Pricing.calculate_order_payment(order, dragon, reputation)
	add_money(payment)
	remove_dragon(dragon_id)
	active_orders.erase(order)
	order_completed.emit(order_id, payment)
	print("[RanchState] Fulfilled order for $%d" % payment)
	return true

func _check_order_deadlines() -> void:
	var expired_orders: Array = []
	for order in active_orders:
		if order.is_expired(current_season):
			expired_orders.append(order)
	for order in expired_orders:
		active_orders.erase(order)


# === DRAGON MANAGEMENT ===

## Add a dragon to the ranch
func add_dragon(data: DragonData) -> String:
	if data == null:
		push_error("[RanchState] add_dragon: null data")
		return ""

	# Generate ID if not set
	if data.id.is_empty():
		data.id = IdGen.generate_dragon_id()

	# Check capacity
	if not can_add_dragon():
		push_warning("[RanchState] At capacity, cannot add dragon")
		# Still add for now, let UI handle the warning

	# Add to dictionary
	dragons[data.id] = data

	# Emit signal
	dragon_added.emit(data.id)

	# Check achievements (full_house)
	_check_achievements()

	print("[RanchState] Added dragon: %s (%s)" % [data.name, data.id])

	return data.id


## Remove a dragon from the ranch
func remove_dragon(dragon_id: String) -> void:
	if not dragons.has(dragon_id):
		push_warning("[RanchState] Dragon not found: %s" % dragon_id)
		return

	# Remove from dictionary
	dragons.erase(dragon_id)

	# Emit signal
	dragon_removed.emit(dragon_id)

	print("[RanchState] Removed dragon: %s" % dragon_id)


## Get a dragon by ID
func get_dragon(dragon_id: String) -> DragonData:
	if dragons.has(dragon_id):
		return dragons[dragon_id]
	return null


## Get all dragons as array
func get_all_dragons() -> Array[DragonData]:
	var result: Array[DragonData] = []
	for dragon_data in dragons.values():
		result.append(dragon_data)
	return result


## Get adult dragons (can breed)
func get_adult_dragons() -> Array[DragonData]:
	var result: Array[DragonData] = []
	for dragon_data in dragons.values():
		if Lifecycle.can_breed(dragon_data):
			result.append(dragon_data)
	return result


## Check if can add more dragons
func can_add_dragon() -> bool:
	return dragons.size() < get_total_capacity()


## Get total dragon capacity
func get_total_capacity() -> int:
	var total: int = BASE_CAPACITY
	for facility_data in facilities.values():
		if facility_data.has("capacity"):
			total += facility_data["capacity"]
	return total


# === FACILITY MANAGEMENT ===

func build_facility(facility_type: String) -> bool:
	# TODO: Load from facility_defs.json
	var cost: int = _get_facility_cost(facility_type)
	if not spend_money(cost):
		return false
	var facility := FacilityData.new()
	facility.id = IdGen.generate_facility_id()
	facility.type = facility_type
	facility.name = facility_type.capitalize()
	facility.capacity = _get_facility_capacity(facility_type)
	facility.cost = cost
	facility.built_season = current_season
	facilities[facility.id] = facility
	facility_built.emit(facility.id)

	# Check achievements (expansion)
	_check_achievements()

	print("[RanchState] Built %s" % facility_type)
	return true

func _get_facility_cost(facility_type: String) -> int:
	match facility_type:
		"stable": return 300
		"pasture": return 400
		"nursery": return 800
		"luxury_habitat": return 1500
		_: return 500

func _get_facility_capacity(facility_type: String) -> int:
	match facility_type:
		"stable", "pasture": return 4
		"nursery": return 6
		"luxury_habitat": return 2
		_: return 0

func get_facility_bonus(bonus_type: String) -> float:
	var total: float = 0.0
	for facility_data in facilities.values():
		if facility_data.has("bonuses") and facility_data["bonuses"].has(bonus_type):
			total += facility_data["bonuses"][bonus_type]
	return total


# === EGG MANAGEMENT ===

## Create an egg from breeding two dragons
func create_egg(parent_a_id: String, parent_b_id: String) -> String:
	var parent_a: DragonData = get_dragon(parent_a_id)
	var parent_b: DragonData = get_dragon(parent_b_id)

	if parent_a == null or parent_b == null:
		push_error("[RanchState] create_egg: parent not found")
		return ""

	# Check breeding eligibility
	var can_breed_check: Dictionary = GeneticsEngine.can_breed(parent_a, parent_b)
	if not can_breed_check["success"]:
		push_warning("[RanchState] Cannot breed: %s" % can_breed_check["reason"])
		return ""

	# Breed dragons to get offspring genotype
	var offspring_genotype: Dictionary = GeneticsEngine.breed_dragons(parent_a, parent_b)

	# Create egg data
	var egg := EggData.new()
	egg.id = IdGen.generate_egg_id()
	egg.genotype = offspring_genotype
	egg.parent_a_id = parent_a_id
	egg.parent_b_id = parent_b_id
	egg.incubation_seasons_remaining = RNGService.randi_range(2, 3)
	egg.created_season = current_season

	# Add to eggs dictionary
	eggs[egg.id] = egg

	# Emit signal
	egg_created.emit(egg.id)

	print("[RanchState] Created egg: %s (parents: %s + %s)" % [egg.id, parent_a.name, parent_b.name])

	return egg.id


## Hatch an egg into a dragon
func hatch_egg(egg_id: String) -> String:
	if not eggs.has(egg_id):
		push_warning("[RanchState] Egg not found: %s" % egg_id)
		return ""

	var egg: EggData = eggs[egg_id]

	# Create dragon from egg
	var dragon := DragonData.new()
	dragon.id = IdGen.generate_dragon_id()
	dragon.name = IdGen.generate_random_name()
	dragon.sex = "male" if RNGService.randf() > 0.5 else "female"
	dragon.genotype = egg.genotype.duplicate(true)
	dragon.phenotype = GeneticsEngine.calculate_phenotype(dragon.genotype)
	dragon.age = 0
	dragon.life_stage = "hatchling"
	dragon.health = 100.0
	dragon.happiness = 100.0
	dragon.training = 0.0
	dragon.parent_a_id = egg.parent_a_id
	dragon.parent_b_id = egg.parent_b_id
	dragon.born_season = current_season

	# Update parents' children lists
	var parent_a: DragonData = get_dragon(egg.parent_a_id)
	var parent_b: DragonData = get_dragon(egg.parent_b_id)
	if parent_a:
		parent_a.add_child(dragon.id)
	if parent_b:
		parent_b.add_child(dragon.id)

	# Add dragon
	var dragon_id: String = add_dragon(dragon)

	# Remove egg
	eggs.erase(egg_id)

	# Emit signal
	egg_hatched.emit(egg_id, dragon_id)

	print("[RanchState] Hatched egg %s -> dragon %s (%s)" % [egg_id, dragon_id, dragon.name])

	return dragon_id


## Process egg incubation (called by advance_season)
func _process_egg_incubation() -> void:
	var eggs_to_hatch: Array[String] = []

	# Decrement all egg timers
	for egg_id in eggs.keys():
		var egg: EggData = eggs[egg_id]
		egg.decrement_incubation()

		if egg.is_ready_to_hatch():
			eggs_to_hatch.append(egg_id)

	# Hatch ready eggs
	for egg_id in eggs_to_hatch:
		hatch_egg(egg_id)


# === RESOURCE MANAGEMENT ===

## Add money
func add_money(amount: int) -> void:
	money += amount
	lifetime_earnings += amount
	money_changed.emit(money)
	_update_reputation()
	print("[RanchState] Money: %d (+%d)" % [money, amount])


## Spend money (returns false if can't afford)
func spend_money(amount: int) -> bool:
	if money < amount:
		push_warning("[RanchState] Cannot afford: need %d, have %d" % [amount, money])
		return false

	money -= amount
	money_changed.emit(money)
	print("[RanchState] Money: %d (-%d)" % [money, amount])
	return true


## Add food
func add_food(amount: int) -> void:
	food_supply += amount
	food_changed.emit(food_supply)
	print("[RanchState] Food: %d (+%d)" % [food_supply, amount])


## Consume food (returns false if insufficient)
func consume_food(amount: int) -> bool:
	if food_supply < amount:
		push_warning("[RanchState] Insufficient food: need %d, have %d" % [amount, food_supply])
		return false

	food_supply -= amount
	food_changed.emit(food_supply)
	return true


## Calculate total food consumption for all dragons
func calculate_food_consumption() -> int:
	var total: int = 0

	for dragon_data in dragons.values():
		# Base consumption
		var consumption: int = FOOD_PER_DRAGON

		# Modified by life stage
		var multiplier: float = Lifecycle.get_food_consumption_multiplier(dragon_data.life_stage)
		consumption = int(consumption * multiplier)

		# TODO: Add metabolism trait modifier in future

		total += consumption

	return total


## Process food consumption (called by advance_season)
func _process_food_consumption() -> void:
	var needed: int = calculate_food_consumption()

	if not consume_food(needed):
		# Insufficient food - dragons lose health
		var health_loss: float = 10.0
		print("[RanchState] WARNING: Insufficient food! Dragons losing %d health" % health_loss)

		for dragon_data in dragons.values():
			dragon_data.health = max(0.0, dragon_data.health - health_loss)


# === PROGRESSION SYSTEM ===

## Update reputation level based on lifetime earnings
func _update_reputation() -> void:
	var new_level: int = Progression.get_reputation_level(lifetime_earnings)
	if new_level > reputation:
		reputation = new_level
		reputation_increased.emit(new_level)
		print("[RanchState] Reputation increased to level %d: %s" % [new_level, Progression.get_level_name(new_level)])


## Check if an achievement condition is met
func check_achievement(achievement_id: String) -> bool:
	# Already unlocked
	if achievements.has(achievement_id):
		return false

	# Check specific achievement conditions
	match achievement_id:
		"first_sale":
			return lifetime_earnings > 0

		"full_house":
			return dragons.size() >= 6

		"perfect_match":
			# Checked externally when fulfilling orders
			return false

		"rare_breed":
			# Check if any dragon has 3+ rare traits (special phenotype values)
			for dragon in dragons.values():
				var rare_count: int = 0
				# This is a placeholder - trait rarity not yet implemented
				# TODO: Implement trait rarity system
				if rare_count >= 3:
					return true
			return false

		"wealthy":
			return lifetime_earnings >= 10000

		"genetics_master":
			# Tracked externally - would need prediction tracking
			return false

		"expansion":
			return facilities.size() >= 3

		"matchmaker":
			# Would need order completion counter
			return false

	return false


## Unlock an achievement
func unlock_achievement(achievement_id: String) -> bool:
	if achievements.has(achievement_id):
		return false  # Already unlocked

	achievements[achievement_id] = current_season
	achievement_unlocked.emit(achievement_id)
	print("[RanchState] Achievement unlocked: %s" % achievement_id)
	return true


## Check and unlock achievements (called during key events)
func _check_achievements() -> void:
	# Check simple condition-based achievements
	var achievement_ids: Array[String] = [
		"first_sale",
		"full_house",
		"rare_breed",
		"wealthy",
		"expansion"
	]

	for achievement_id in achievement_ids:
		if check_achievement(achievement_id):
			unlock_achievement(achievement_id)


# === TIME PROGRESSION ===

## Check if can advance season
func can_advance_season() -> bool:
	# For now, always allowed
	# TODO: Add blocking conditions (tutorial, animations, etc.)
	return true


## Advance to next season
func advance_season() -> void:
	if not can_advance_season():
		return

	# Increment season
	current_season += 1

	print("\n[RanchState] ===== SEASON %d =====" % current_season)

	# Age all dragons
	for dragon_data in dragons.values():
		var old_stage: String = dragon_data.life_stage
		Lifecycle.advance_age(dragon_data)

		if old_stage != dragon_data.life_stage:
			print("[RanchState] %s aged to %s (age %d)" % [dragon_data.name, dragon_data.life_stage, dragon_data.age])

	# Process egg incubation
	_process_egg_incubation()

	# Process food consumption
	_process_food_consumption()

	# Check order deadlines
	_check_order_deadlines()

	# Check for achievement unlocks
	_check_achievements()

	# Emit signal
	season_changed.emit(current_season)

	print("[RanchState] Season %d complete\n" % current_season)


# === GAME INITIALIZATION ===

## Start a new game
func start_new_game() -> void:
	print("\n[RanchState] Starting new game...")

	# Clear all data
	dragons.clear()
	eggs.clear()
	facilities.clear()
	active_orders.clear()

	# Reset values
	current_season = 1
	money = 500
	food_supply = 100
	reputation = 0
	lifetime_earnings = 0
	achievements.clear()
	time_speed = 1.0

	# Create 2 starter dragons
	for i in range(2):
		var dragon := DragonData.new()
		dragon.id = IdGen.generate_dragon_id()
		dragon.name = IdGen.generate_random_name()
		dragon.sex = "male" if i == 0 else "female"
		dragon.genotype = TraitDB.get_random_genotype(reputation)
		dragon.phenotype = GeneticsEngine.calculate_phenotype(dragon.genotype)
		dragon.age = 4  # Young adult
		dragon.life_stage = "adult"
		dragon.health = 100.0
		dragon.happiness = 80.0
		dragon.training = 0.0
		dragon.born_season = 0  # Pre-game

		add_dragon(dragon)

	# Generate initial orders
	var initial_orders: Array = OrderSystem.generate_orders(reputation)
	for order in initial_orders:
		active_orders.append(order)

	# Emit initialization signals
	money_changed.emit(money)
	food_changed.emit(food_supply)

	print("[RanchState] New game started with %d dragons" % dragons.size())
	print("[RanchState] Starting money: $%d, Food: %d\n" % [money, food_supply])


## Reset game (for testing)
func reset_game() -> void:
	start_new_game()


# === SERIALIZATION ===

## Load game state from dictionary (used by SaveSystem)
func load_state(save_data: Dictionary) -> bool:
	print("[RanchState] Loading game state...")

	# Clear existing state
	dragons.clear()
	eggs.clear()
	facilities.clear()
	active_orders.clear()

	# Load basic values
	current_season = save_data.get("current_season", 1)
	money = save_data.get("money", 500)
	reputation = save_data.get("reputation", 0)
	lifetime_earnings = save_data.get("lifetime_earnings", 0)
	food_supply = save_data.get("food_supply", 100)

	# Load achievements
	achievements = save_data.get("achievements", {}).duplicate(true)

	# Load dragons
	var dragons_data: Dictionary = save_data.get("dragons", {})
	for dragon_id in dragons_data.keys():
		var dragon := DragonData.new()
		dragon.from_dict(dragons_data[dragon_id])
		if dragon.is_valid():
			dragons[dragon_id] = dragon
		else:
			push_warning("[RanchState] Skipped invalid dragon: %s" % dragon_id)

	# Load eggs
	var eggs_data: Dictionary = save_data.get("eggs", {})
	for egg_id in eggs_data.keys():
		var egg := EggData.new()
		egg.from_dict(eggs_data[egg_id])
		if egg.is_valid():
			eggs[egg_id] = egg
		else:
			push_warning("[RanchState] Skipped invalid egg: %s" % egg_id)

	# Load facilities
	facilities = save_data.get("facilities", {}).duplicate(true)

	# Load active orders
	active_orders = save_data.get("active_orders", []).duplicate(true)

	# Restore RNG seed
	if save_data.has("rng_seed"):
		RNGService.set_seed(save_data["rng_seed"])

	# Emit signals (quietly, without sound effects)
	money_changed.emit(money)
	food_changed.emit(food_supply)

	print("[RanchState] Loaded: Season %d, %d dragons, %d eggs, $%d" % [current_season, dragons.size(), eggs.size(), money])

	return true


## Serialize game state to dictionary
func to_dict() -> Dictionary:
	# Serialize dragons
	var dragons_dict: Dictionary = {}
	for dragon_id in dragons.keys():
		dragons_dict[dragon_id] = dragons[dragon_id].to_dict()

	# Serialize eggs
	var eggs_dict: Dictionary = {}
	for egg_id in eggs.keys():
		eggs_dict[egg_id] = eggs[egg_id].to_dict()

	return {
		"current_season": current_season,
		"money": money,
		"reputation": reputation,
		"lifetime_earnings": lifetime_earnings,
		"achievements": achievements.duplicate(true),
		"food_supply": food_supply,
		"dragons": dragons_dict,
		"eggs": eggs_dict,
		"facilities": facilities.duplicate(true),
		"active_orders": active_orders.duplicate(true),
		"rng_seed": RNGService.get_seed()
	}


## Deserialize game state from dictionary
func from_dict(data: Dictionary) -> void:
	# Load basic values
	current_season = data.get("current_season", 1)
	money = data.get("money", 500)
	reputation = data.get("reputation", 0)
	lifetime_earnings = data.get("lifetime_earnings", 0)
	food_supply = data.get("food_supply", 100)

	# Load achievements
	achievements = data.get("achievements", {}).duplicate(true)

	# Load dragons
	dragons.clear()
	var dragons_data: Dictionary = data.get("dragons", {})
	for dragon_id in dragons_data.keys():
		var dragon := DragonData.new()
		dragon.from_dict(dragons_data[dragon_id])
		dragons[dragon_id] = dragon

	# Load eggs
	eggs.clear()
	var eggs_data: Dictionary = data.get("eggs", {})
	for egg_id in eggs_data.keys():
		var egg := EggData.new()
		egg.from_dict(eggs_data[egg_id])
		eggs[egg_id] = egg

	# Load facilities
	facilities = data.get("facilities", {}).duplicate(true)

	# Load active orders
	active_orders = data.get("active_orders", []).duplicate(true)

	# Restore RNG seed
	if data.has("rng_seed"):
		RNGService.set_seed(data["rng_seed"])

	# Emit signals
	money_changed.emit(money)
	food_changed.emit(food_supply)

	print("[RanchState] Game loaded: Season %d, %d dragons, %d eggs" % [current_season, dragons.size(), eggs.size()])
