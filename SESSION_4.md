## SESSION 4: RanchState & Time System
**Model:** Claude Sonnet 4.5 (Code)  
**Duration:** 6-8 hours  
**Extended Thinking:** OFF  
**Dependencies:** Sessions 1-3 complete

### Purpose
Implement the central game state manager with time progression, dragon/egg tracking, and save/load.

### Tasks

#### P1-201: RanchState Skeleton
**Goal:** Create RanchState autoload with signals and properties
- Implement `RanchState.gd` autoload
- Define signals (from P0-001):
  - `season_changed(new_season: int)`
  - `dragon_added(dragon_id: String)`
  - `dragon_removed(dragon_id: String)`
  - `egg_created(egg_id: String)`
  - `egg_hatched(egg_id: String, dragon_id: String)`
  - `order_accepted(order_id: String)`
  - `order_completed(order_id: String, payment: int)`
  - `reputation_increased(new_level: int)`
  - `facility_built(facility_id: String)`
  - `money_changed(new_amount: int)`
  - `food_changed(new_amount: int)`
- Define properties:
  - `current_season: int`
  - `money: int`
  - `reputation: int`
  - `food_supply: int`
  - `dragons: Dictionary` (id → DragonData)
  - `eggs: Dictionary` (id → EggData)
  - `facilities: Dictionary` (id → FacilityData)
  - `active_orders: Array[OrderData]`
- Stub all public methods (implement in next tasks)

**Files:** `scripts/autoloads/RanchState.gd`

---

#### P1-202: Time Progression System
**Goal:** Implement season advancement
- Implement `advance_season() -> void`:
  - Increment current_season
  - Emit season_changed signal
  - Age all dragons by 1 season (call Lifecycle.advance_age)
  - Decrement egg incubation timers
  - Hatch eggs that reach 0
  - Consume food for all dragons
  - Check order deadlines
  - Remove expired orders
- Implement `can_advance_season() -> bool`:
  - Check if any blocking conditions exist (tutorial mode, animation playing, etc.)
- Add time speed controls:
  - `time_speed: float` (1.0, 2.0, 4.0)
  - Affects timer speeds in UI (not core logic)

**Files:** `scripts/autoloads/RanchState.gd`

---

#### P1-203: Dragon Management
**Goal:** Implement dragon CRUD operations
- Implement `add_dragon(data: DragonData) -> String`:
  - Generate ID if not set
  - Add to dragons dictionary
  - Emit dragon_added signal
  - Return ID
- Implement `remove_dragon(dragon_id: String) -> void`:
  - Remove from dictionary
  - Emit dragon_removed signal
  - Remove from facility if assigned
- Implement `get_dragon(dragon_id: String) -> DragonData`
- Implement `get_all_dragons() -> Array[DragonData]`
- Implement `get_adult_dragons() -> Array[DragonData]`:
  - Filter by can_breed()

**Files:** `scripts/autoloads/RanchState.gd`

---

#### P1-204: Egg Management & Hatching
**Goal:** Implement egg lifecycle
- Implement `create_egg(parent_a_id: String, parent_b_id: String) -> String`:
  - Get parent DragonData
  - Call GeneticsEngine.breed_dragons()
  - Create EggData with result
  - Set incubation_seasons_remaining (2-3 seasons)
  - Add to eggs dictionary
  - Emit egg_created signal
  - Return egg ID
- Implement `hatch_egg(egg_id: String) -> String`:
  - Get EggData
  - Create DragonData from egg genotype
  - Generate name
  - Set born_season
  - Add dragon
  - Remove egg
  - Emit egg_hatched signal
  - Return dragon ID
- Implement `_process_egg_incubation()` (called by advance_season):
  - Decrement all egg timers
  - Hatch eggs at 0

**Files:** `scripts/autoloads/RanchState.gd`

---

#### P1-205: Resource Management (Money & Food)
**Goal:** Implement economy tracking
- Implement `add_money(amount: int) -> void`:
  - Update money
  - Emit money_changed
- Implement `spend_money(amount: int) -> bool`:
  - Check if affordable
  - Deduct and emit signal
  - Return success
- Implement `add_food(amount: int) -> void`
- Implement `consume_food(amount: int) -> bool`
- Implement `calculate_food_consumption() -> int`:
  - Base consumption per dragon
  - Modified by size/metabolism traits
- Implement `_process_food_consumption()` (called by advance_season):
  - Calculate total needed
  - Deduct from supply
  - If insufficient, dragons lose health

**Files:** `scripts/autoloads/RanchState.gd`

---

#### P1-206: Game Initialization
**Goal:** Implement new game setup
- Implement `start_new_game() -> void`:
  - Clear all dictionaries
  - Set current_season = 1
  - Set money = 500 (starting cash)
  - Set food_supply = 100
  - Set reputation = 0
  - Create 2 starter dragons:
	- Random genotypes
	- Adult stage
	- Random names
  - Generate first set of orders
  - Emit initialization signals
- Implement `reset_game() -> void` (for testing)

**Files:** `scripts/autoloads/RanchState.gd`

---

#### P1-207: Unit Tests - RanchState
**Goal:** Test core state management
- Create `tests/ranch_state/test_time.gd`:
  - Test season advancement
  - Test dragon aging
  - Test egg hatching
- Create `tests/ranch_state/test_dragons.gd`:
  - Test add/remove dragons
  - Test adult filtering
- Create `tests/ranch_state/test_resources.gd`:
  - Test money transactions
  - Test food consumption

**Files:**
- `tests/ranch_state/test_time.gd`
- `tests/ranch_state/test_dragons.gd`
- `tests/ranch_state/test_resources.gd`

---

**Session 4 Acceptance Criteria:**
- [ ] Season advancement triggers all expected updates
- [ ] Eggs hatch after 2-3 seasons
- [ ] Dragons age correctly through lifecycle stages
- [ ] Money and food track accurately
- [ ] All signals emit at correct times
- [ ] New game initializes with 2 adult dragons

---
