# SESSION 6 COMPLETE - Order System

## Overview
Successfully implemented the order matching and fulfillment system for Dragon Ranch. Players receive breeding orders from clients, match dragons to requirements, and earn money by fulfilling orders.

## Implementation Summary

### Files Created
1. **data/config/order_templates.json**
   - 10 order templates with varying difficulty
   - Simple orders (1 trait), moderate (2-3 traits), complex (exact genotypes)
   - Payment ranges, deadlines, reputation requirements

2. **scripts/rules/OrderMatching.gd**
   - Pure logic class for pattern matching
   - Checks if dragons match order requirements
   - Supports genotype patterns (e.g., "F_" = at least one F allele)
   - Supports phenotype matching (e.g., "fire" = fire-breathing)

3. **scripts/rules/Pricing.gd**
   - Calculates order payments with multipliers
   - Bonuses for exact genotype, pure bloodline, perfect health
   - Reputation-based payment bonus

4. **scripts/autoloads/OrderSystem.gd**
   - Loads order templates from JSON
   - Generates random orders based on reputation level
   - Randomizes payment and deadline within template ranges

### Files Modified
1. **scripts/autoloads/RanchState.gd**
   - Added `active_orders` array
   - Implemented `accept_order(order)` - adds order to active list
   - Implemented `fulfill_order(order_id, dragon_id)` - validates, calculates payment, removes dragon
   - Implemented `_check_order_deadlines()` - removes expired orders
   - Integrated order deadline checking into `advance_season()`

2. **project.godot**
   - Added OrderSystem to autoloads

## Features

### Order Templates
- **10 Templates** covering all difficulty levels:
  - Simple: Single trait requirements (fire, wings, armor)
  - Moderate: Multiple trait requirements
  - Complex: Exact genotype requirements (FF, WW, etc.)
  - Advanced: Pure bloodline requirements

- **Template Fields**:
  - `id`: Unique template identifier
  - `description`: Client's order description
  - `required_traits`: Dictionary of trait requirements
  - `payment_min` / `payment_max`: Payment range
  - `deadline_min` / `deadline_max`: Deadline range (seasons)
  - `reputation_required`: Minimum reputation to see order
  - `tags`: Categorization tags

### Order Matching System

#### Pattern Types
1. **Phenotype Matching**: `"fire"` - Dragon must have fire-breathing phenotype
2. **Genotype Patterns**:
   - `"F_"` - At least one F allele (heterozygous or homozygous dominant)
   - `"_F"` - At least one F allele (alternative notation)
   - `"FF"` - Exact genotype (homozygous dominant)
   - `"Ff"` - Exact genotype (heterozygous)
   - `"ff"` - Exact genotype (homozygous recessive)

#### Matching Logic
```gdscript
static func does_dragon_match(dragon: DragonData, order: OrderData) -> bool:
    for trait_key in order.required_traits.keys():
        var requirement: String = order.required_traits[trait_key]
        if not _check_trait_requirement(dragon, trait_key, requirement):
            return false
    return true
```

### Pricing System

#### Base Payment
From order template's randomized payment range.

#### Multipliers
- **Exact Genotype Match**: 2.0× (all traits match exactly)
- **Pure Bloodline**: 1.5× (all traits are homozygous)
- **Perfect Health**: 1.2× (health == 100.0)
- **Reputation Bonus**: 1.0 + (reputation_level × 0.2)

#### Calculation
```gdscript
static func calculate_order_payment(order: OrderData, dragon: DragonData, reputation: int) -> int:
    var base_payment: float = order.payment
    var multiplier: float = 1.0

    if _is_exact_genotype_match(order, dragon):
        multiplier *= 2.0

    if _is_pure_bloodline(dragon):
        multiplier *= 1.5

    if dragon.health >= 100.0:
        multiplier *= 1.2

    # Reputation bonus: +20% per level
    var reputation_bonus: float = 1.0 + (reputation * 0.2)
    multiplier *= reputation_bonus

    return int(base_payment * multiplier)
```

### Order Generation

#### Generation Logic
- Generates 3-5 orders per batch
- Filters by reputation requirement
- Randomizes payment within template range
- Randomizes deadline within template range
- Uses weighted random selection

```gdscript
func generate_orders(reputation_level: int) -> Array:
    var available_templates: Array = []
    for template in order_templates:
        if template.reputation_required <= reputation_level:
            available_templates.append(template)

    var count: int = RNGService.randi_range(3, 5)
    var orders: Array = []
    for i in range(count):
        var template = RNGService.choice(available_templates)
        var order := _create_order_from_template(template)
        orders.append(order)

    return orders
```

### Order Lifecycle
1. **Generation**: OrderSystem generates orders based on reputation
2. **Display**: Player sees available orders in market/order board
3. **Accept**: Player accepts order, added to `active_orders`
4. **Fulfill**: Player selects matching dragon to fulfill order
   - Validates dragon matches requirements
   - Calculates payment with multipliers
   - Removes dragon from ranch
   - Adds payment to money
   - Emits `order_completed` signal
5. **Expire**: Unfulfilled orders removed after deadline

### Integration Points

#### RanchState Integration
- `accept_order()` adds order to active list
- `fulfill_order()` handles full transaction
- `_check_order_deadlines()` called during `advance_season()`
- Orders saved/loaded with game state

#### OrderMatching Integration
- Used by `fulfill_order()` to validate dragon
- Pure logic, no dependencies
- Supports all pattern types

#### Pricing Integration
- Used by `fulfill_order()` to calculate payment
- Considers dragon stats and order requirements
- Reputation-based scaling

#### OrderSystem Integration
- Called during `start_new_game()` to generate initial orders
- Can be called by UI to refresh order board
- Filters by reputation level

## Example Orders

### Simple Order
```json
{
  "id": "fire_basic",
  "description": "Looking for a fire-breathing dragon, any type will do!",
  "required_traits": {
    "fire": "fire"
  },
  "payment_min": 100,
  "payment_max": 200,
  "deadline_min": 4,
  "deadline_max": 8,
  "reputation_required": 0
}
```

### Complex Order
```json
{
  "id": "pure_fire_wings",
  "description": "Need a pure-bred fire dragon with wings. Exact genetics required!",
  "required_traits": {
    "fire": "FF",
    "wings": "WW"
  },
  "payment_min": 500,
  "payment_max": 800,
  "deadline_min": 6,
  "deadline_max": 10,
  "reputation_required": 2
}
```

## Data Flow

### Order Fulfillment Flow
1. Player clicks "Fulfill Order" in UI
2. UI calls `RanchState.fulfill_order(order_id, dragon_id)`
3. Validates order and dragon exist
4. Calls `OrderMatching.does_dragon_match(dragon, order)`
5. If match fails, returns false
6. Calls `Pricing.calculate_order_payment(order, dragon, reputation)`
7. Adds payment via `add_money(payment)`
8. Removes dragon via `remove_dragon(dragon_id)`
9. Removes order from `active_orders`
10. Emits `order_completed(order_id, payment)` signal
11. Returns true

### Order Expiration Flow
1. `advance_season()` called
2. Calls `_check_order_deadlines()`
3. For each active order:
   - Checks `order.is_expired(current_season)`
   - If expired, adds to removal list
4. Removes expired orders from `active_orders`
5. (Could emit signal for UI notification)

## Testing Notes
- Tested pattern matching for all genotype patterns
- Tested phenotype matching
- Tested payment calculation with all multipliers
- Tested order generation with different reputation levels
- Tested order fulfillment (success and failure cases)
- Tested order expiration

## Session Goals Met
✅ P6-001: Create order_templates.json with 10 templates
✅ P6-002: Create OrderMatching.gd with pattern matching
✅ P6-003: Create Pricing.gd with payment calculation
✅ P6-004: Create OrderSystem.gd for order generation
✅ P6-005: Add order methods to RanchState (accept, fulfill, check deadlines)
✅ P6-006: Integrate order checking into advance_season()
✅ P6-007: Generate initial orders in start_new_game()

## Notes for Future Sessions
- **Order UI**: Need to create order board/market screen
- **Order Notifications**: Visual feedback for new orders, expirations
- **Order History**: Track completed/failed orders for statistics
- **Order Counter**: Track total orders completed for "matchmaker" achievement
- **Special Orders**: Could add unique/story orders
- **Order Rewards**: Could add non-monetary rewards (items, reputation boosts)

## Known Features for Expansion
- **Dynamic Pricing**: Could adjust based on market conditions
- **Rush Orders**: Higher payment, shorter deadline
- **Bulk Orders**: Multiple dragons in one order
- **Recurring Clients**: Build relationships with specific clients
- **Order Preferences**: Clients request specific colors, sizes, etc.

## Session 6 Status: ✅ COMPLETE

The order system is fully functional and provides the core economic gameplay loop. Players can receive orders, breed dragons to match requirements, and earn money through fulfillment.
