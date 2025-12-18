## SESSION 7: Facility System
**Model:** Claude Sonnet 4.5 (Code)  
**Duration:** 4-6 hours  
**Extended Thinking:** OFF  
**Dependencies:** Sessions 1-6 complete

### Purpose
Implement facility management (capacity, bonuses, building).

### Tasks

#### P3-201: FacilityData Resource Implementation
**Goal:** Implement typed Resource for facilities
- Implement `FacilityData.gd` extends Resource
- Add all @export properties from schema
- Add methods:
  - `get_capacity() -> int`
  - `get_bonuses() -> Dictionary`
  - `get_cost() -> int`

**Files:** `scripts/data/FacilityData.gd`

---

#### P3-202: Facility Definitions
**Goal:** Define facility types in config
- Create `data/config/facility_defs.json`:
  - Stable: +4 capacity, $300
  - Pasture: +4 capacity outdoor, $400
  - Breeding Pen: enables breeding, $500
  - Nursery: +6 hatchling capacity, faster growth, $800
  - Genetics Lab: show genotypes, $5000
  - Luxury Habitat: +2 capacity, +20 happiness, $1500

**Files:** `data/config/facility_defs.json`

---

#### P3-203: Facility Management in RanchState
**Goal:** Add facility CRUD to RanchState
- Implement `build_facility(facility_type: String) -> bool`:
  - Load facility definition
  - Check cost and reputation requirement
  - Spend money
  - Create FacilityData
  - Add to facilities dictionary
  - Emit facility_built signal
  - Return success
- Implement `get_total_capacity() -> int`:
  - Sum capacity from all facilities
  - Base capacity: 6 (from starter ranch)
- Implement `get_facility_bonus(bonus_type: String) -> float`:
  - Sum all bonuses of type (e.g., "happiness", "growth_speed")

**Files:** `scripts/autoloads/RanchState.gd` (add methods)

---

#### P3-204: Capacity Enforcement
**Goal:** Prevent over-capacity
- Implement `can_add_dragon() -> bool`:
  - Check current dragon count vs capacity
- Modify `add_dragon()` to check capacity
- Modify `hatch_egg()` to check capacity:
  - If at capacity, show warning (but don't fail in logic layer)

**Files:** `scripts/autoloads/RanchState.gd` (modify methods)

---

#### P3-205: Facility Bonuses Application
**Goal:** Apply facility bonuses to dragons
- Modify `advance_season()` to apply bonuses:
  - Happiness bonus from Luxury Habitat
  - Growth speed from Nursery (hatchlings age faster)
- Store facility bonuses in FacilityData
- Query bonuses when needed

**Files:** `scripts/autoloads/RanchState.gd` (modify method)

---

**Session 7 Acceptance Criteria:**
- [ ] Can build facilities and spend money
- [ ] Capacity increases with facilities
- [ ] Cannot exceed capacity
- [ ] Facility bonuses apply to dragons
- [ ] Facilities persist through save/load

---
