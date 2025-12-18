## SESSION 6: Order System & Matching
**Model:** Claude Sonnet 4.5 (Code)  
**Duration:** 6-8 hours  
**Extended Thinking:** OFF  
**Dependencies:** Sessions 1-5 complete

### Purpose
Implement order generation, requirement matching, and fulfillment logic.

### Tasks

#### P3-101: OrderData Resource Implementation
**Goal:** Implement typed Resource for orders
- Implement `OrderData.gd` extends Resource
- Add all @export properties from schema (P0-002)
- Implement serialization methods
- Add `is_expired(current_season: int) -> bool`
- Add `get_display_text() -> String` (for UI)

**Files:** `scripts/data/OrderData.gd`

---

#### P3-102: Order Templates
**Goal:** Define order templates (defer descriptions to ChatGPT)
- Create `data/config/order_templates.json` structure:
  - Template ID
  - Type (simple, complex, exact_genotype, rental, breeding)
  - Required traits (as patterns: "F_", "FF", etc.)
  - Payment range
  - Deadline range
  - Reputation requirement
  - Description template (with placeholders)
- Define 10 placeholder templates (descriptions to be filled by ChatGPT)

**Files:** `data/config/order_templates.json`

---

#### P3-103: OrderSystem Skeleton
**Goal:** Create OrderSystem autoload
- Implement `OrderSystem.gd` autoload
- Load order templates from JSON
- Define signals:
  - `orders_generated(orders: Array[OrderData])`
- Stub methods

**Files:** `scripts/autoloads/OrderSystem.gd`

---

#### P3-104: Order Generation
**Goal:** Generate orders based on reputation
- Implement `generate_orders(reputation_level: int) -> Array[OrderData]`:
  - Select 3-5 templates appropriate for reputation
  - Instantiate OrderData from templates
  - Randomize payment within range
  - Set deadline (2-5 seasons based on complexity)
  - Generate unique order ID
  - Fill description template
  - Return array
- Ensure at least 1 order is fulfillable with starter dragons
- Balance order types: 60% simple, 30% complex, 10% special

**Files:** `scripts/autoloads/OrderSystem.gd`

---

#### P3-105: Order Matching Logic
**Goal:** Implement dragon-to-order matching
- Implement `OrderMatching.gd` module (pure logic)
- Implement `does_dragon_match(dragon: DragonData, order: OrderData) -> bool`:
  - For each required trait in order:
	- Parse requirement pattern (e.g., "F_" means at least one F)
	- Get dragon's genotype for that trait
    - Check if matches:
      - Exact: "FF" must be ["F", "F"]
      - Dominant: "F_" must have at least one "F"
      - Phenotype: "fire" must have fire phenotype
  - All traits must match
  - Return true if match
- Handle edge cases:
  - Dragon missing trait (false)
  - Unknown requirement pattern (error)
  - Null/invalid data (false)

**Files:** `scripts/rules/OrderMatching.gd`

---

#### P3-106: Pricing Logic
**Goal:** Calculate order payments
- Implement `Pricing.gd` module (pure logic)
- Implement `calculate_order_payment(order: OrderData, dragon: DragonData) -> int`:
  - Base price from template
  - Multipliers:
    - Exact genotype requested: ×2
    - Pure bloodline (known parents): ×1.5
    - Perfect health: ×1.2
  - Reputation bonus: 1.0 + (reputation_level × 0.2)
  - Return final payment
- Implement `calculate_facility_cost(facility_type: String, reputation_level: int) -> int`:
  - Base costs from config
  - Early game discount (reputation < 2)

**Files:** `scripts/rules/Pricing.gd`

---

#### P3-107: Order Integration with RanchState
**Goal:** Add order management to RanchState
- Implement `accept_order(order: OrderData) -> void` in RanchState:
  - Add to active_orders
  - Emit order_accepted signal
- Implement `fulfill_order(order_id: String, dragon_id: String) -> bool`:
  - Verify dragon matches order (call OrderMatching)
  - Calculate payment (call Pricing)
  - Add money
  - Remove dragon
  - Remove order from active_orders
  - Emit order_completed signal
  - Return success
- Implement `_check_order_deadlines()` (called by advance_season):
  - Remove expired orders
  - Optionally penalize reputation

**Files:** `scripts/autoloads/RanchState.gd` (add methods)

---

#### P3-108: Order System Tests
**Goal:** Test order matching logic
- Create `tests/orders/test_matching.gd`:
  - Test FF matches "FF" requirement
  - Test Ff matches "F_" requirement
  - Test ff does NOT match "F_" requirement
  - Test phenotype matching
  - Test multi-trait orders
  - Test vestigial wings edge case
- Create `tests/orders/test_generation.gd`:
  - Test reputation-appropriate orders
  - Test at least 1 fulfillable order
- Create `tests/orders/test_pricing.gd`:
  - Test base pricing
  - Test multipliers

**Files:**
- `tests/orders/test_matching.gd`
- `tests/orders/test_generation.gd`
- `tests/orders/test_pricing.gd`

---

**Session 6 Acceptance Criteria:**
- [ ] Orders generate with correct difficulty for reputation
- [ ] Dragon matching is accurate (100% correct in tests)
- [ ] Vestigial wings (ww) correctly match orders requiring "w_"
- [ ] Payment calculations are consistent
- [ ] Order deadlines expire correctly
- [ ] Can fulfill order and receive payment

---
