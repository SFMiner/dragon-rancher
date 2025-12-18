# Pricing.gd
# Pricing calculations for orders and facilities
# Part of Dragon Ranch - Session 6 Order System

class_name Pricing


## Calculate final payment for fulfilling an order
static func calculate_order_payment(order: OrderData, dragon: DragonData, reputation_level: int) -> int:
	if order == null or dragon == null:
		return 0

	var base_price: float = float(order.payment)

	# Multiplier for exact genotype orders
	if order.type == OrderData.TYPE_EXACT:
		base_price *= 2.0

	# Multiplier for pure bloodline (known parents)
	if dragon.has_known_parents():
		base_price *= 1.5

	# Multiplier for perfect health
	if dragon.health >= 100.0:
		base_price *= 1.2

	# Reputation bonus
	var reputation_bonus: float = 1.0 + (float(reputation_level) * 0.2)
	base_price *= reputation_bonus

	return int(base_price)


## Calculate cost of a facility
static func calculate_facility_cost(base_cost: int, reputation_level: int) -> int:
	var cost: float = float(base_cost)

	# Early game discount
	if reputation_level < 2:
		cost *= 0.8

	return int(cost)
