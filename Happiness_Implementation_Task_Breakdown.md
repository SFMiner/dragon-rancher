## **Detailed Task Breakdown for Claude Code**

### **Task 1: Add Happiness Constants to RanchState**

**File:** `scripts/autoloads/RanchState.gd`  
**Extended Thinking:** OFF  
**Priority:** P0

**Objective:** Define constants for happiness mechanics

**Implementation:**

gdscript

```gdscript
# Add after existing constants (around line 30)

## Happiness mechanics constants
const BASE_HAPPINESS_DECAY: float = 5.0  # Happiness lost per season without facilities
const OVERCROWDING_PENALTY_PER_DRAGON: float = 3.0  # Additional penalty per dragon over capacity
const MIN_BREEDING_HAPPINESS: float = 40.0  # Minimum happiness to breed
```

**Acceptance Criteria:**

- Constants defined in RanchState
- Values match design intent
- No compilation errors

---

### **Task 2: Implement `_calculate_dragon_capacity()` Helper**

**File:** `scripts/autoloads/RanchState.gd`  
**Extended Thinking:** OFF  
**Priority:** P0

**Objective:** Calculate total dragon capacity from facilities

**Implementation:**

gdscript

```gdscript
# Add after get_facility_bonus() method (around line 280)

## Calculate total dragon housing capacity
## Returns: Total capacity from all facilities
func _calculate_dragon_capacity() -> int:
	var total_capacity: int = 0
	
	for facility_data in facilities.values():
		if facility_data is FacilityData:
			total_capacity += facility_data.capacity
		elif facility_data is Dictionary:
			total_capacity += facility_data.get("capacity", 0)
	
	return total_capacity
```

**Acceptance Criteria:**

- Method correctly sums capacity from all facilities
- Handles both FacilityData and Dictionary formats
- Returns 0 if no facilities

---

### **Task 3: Implement `_calculate_overcrowding_penalty()` Helper**

**File:** `scripts/autoloads/RanchState.gd`  
**Extended Thinking:** OFF  
**Priority:** P0

**Objective:** Calculate happiness penalty from overcrowding

**Implementation:**

gdscript

```gdscript
# Add after _calculate_dragon_capacity() method

## Calculate overcrowding penalty
## Returns: Negative happiness modifier based on dragons over capacity
func _calculate_overcrowding_penalty() -> float:
	var dragon_count: int = dragons.size()
	var total_capacity: int = _calculate_dragon_capacity()
	
	# No penalty if under capacity
	if dragon_count <= total_capacity:
		return 0.0
	
	# Penalty increases per dragon over capacity
	var dragons_over: int = dragon_count - total_capacity
	return dragons_over * OVERCROWDING_PENALTY_PER_DRAGON
```

**Acceptance Criteria:**

- Returns 0.0 when under capacity
- Returns correct penalty when overcrowded
- Penalty scales with number of excess dragons

---

### **Task 4: Implement `_process_happiness()` Core Method**

**File:** `scripts/autoloads/RanchState.gd`  
**Extended Thinking:** ON  
**Priority:** P0

**Objective:** Process happiness changes for all dragons each season

**Implementation:**

gdscript

```gdscript
# Add as a new method after _check_dragon_escapes_optimized()

## Process happiness changes for all dragons
## Called during advance_season()
func _process_happiness(dragon_list: Array) -> void:
	# Calculate facility bonuses and penalties
	var facility_happiness_bonus: float = get_facility_bonus("happiness")
	var overcrowding_penalty: float = _calculate_overcrowding_penalty()
	
	# Net change per season
	var net_change: float = facility_happiness_bonus - BASE_HAPPINESS_DECAY - overcrowding_penalty
	
	# Apply to all dragons
	for dragon_data in dragon_list:
		if dragon_data == null:
			continue
		
		# Apply happiness change
		dragon_data.happiness = clamp(dragon_data.happiness + net_change, 0.0, 100.0)
		
		# Log significant changes (optional, for debugging)
		if net_change < -10.0 and OS.is_debug_build():
			push_warning("[RanchState] %s happiness dropping (now %.1f)" % [dragon_data.name, dragon_data.happiness])
```

**Acceptance Criteria:**

- Applies facility bonuses correctly
- Applies base decay
- Applies overcrowding penalty
- Clamps happiness to 0-100 range
- Processes all dragons in list

---

### **Task 5: Integrate `_process_happiness()` into `advance_season()`**

**File:** `scripts/autoloads/RanchState.gd`  
**Extended Thinking:** OFF  
**Priority:** P0

**Objective:** Call happiness processing during season advancement

**Implementation:**

gdscript

```gdscript
# Modify advance_season() method (around line 560-570)
# Add after dragon aging, before egg incubation

func advance_season() -> void:
	# ... existing code ...
	
	# Age all dragons
	for dragon_data in dragon_list:
		# ... existing aging code ...
	
	# *** ADD THIS LINE ***
	# Process happiness changes
	_process_happiness(dragon_list)
	
	# Process egg incubation
	_process_egg_incubation()
	
	# ... rest of existing code ...
```

**Acceptance Criteria:**

- `_process_happiness()` called after aging
- Uses same cached dragon_list for efficiency
- Season advancement completes without errors

---

### **Task 6: Update `DragonData.can_breed()` to Check Happiness**

**File:** `scripts/dragon_data.gd`  
**Extended Thinking:** OFF  
**Priority:** P1

**Objective:** Add happiness requirement to breeding eligibility

**Implementation:**

gdscript

```gdscript
# Modify can_breed() method (around line 156)

func can_breed() -> bool:
	"""Check if this dragon can breed (adult stage, healthy enough, happy enough)."""
	if life_stage != "adult":
		return false
	
	if health < 20.0:
		return false
	
	# *** ADD THIS CHECK ***
	# Minimum happiness threshold for breeding
	if happiness < 40.0:  # RanchState.MIN_BREEDING_HAPPINESS
		return false
	
	return true
```

**Acceptance Criteria:**

- Returns false if happiness < 40.0
- Does not break existing breeding checks
- All existing tests still pass

---

### **Task 7: Update `GeneticsEngine.can_breed()` with Happiness Reason**

**File:** `scripts/autoloads/GeneticsEngine.gd`  
**Extended Thinking:** OFF  
**Priority:** P1

**Objective:** Provide user-friendly error message for happiness failure

**Implementation:**

gdscript

```gdscript
# Modify can_breed() method (around line 138)

func can_breed(parent_a: DragonData, parent_b: DragonData) -> Dictionary:
	if parent_a == null or parent_b == null:
		return {"success": false, "reason": "Missing parent data"}

	if not parent_a.can_breed():
		# *** ENHANCE THIS CHECK ***
		if parent_a.life_stage != "adult":
			return {"success": false, "reason": "%s cannot breed (wrong life stage)" % parent_a.name}
		elif parent_a.health < 20.0:
			return {"success": false, "reason": "%s cannot breed (health too low)" % parent_a.name}
		elif parent_a.happiness < 40.0:
			return {"success": false, "reason": "%s cannot breed (happiness too low: %.0f%%)" % [parent_a.name, parent_a.happiness]}
		else:
			return {"success": false, "reason": "%s cannot breed" % parent_a.name}

	if not parent_b.can_breed():
		# *** ENHANCE THIS CHECK ***
		if parent_b.life_stage != "adult":
			return {"success": false, "reason": "%s cannot breed (wrong life stage)" % parent_b.name}
		elif parent_b.health < 20.0:
			return {"success": false, "reason": "%s cannot breed (health too low)" % parent_b.name}
		elif parent_b.happiness < 40.0:
			return {"success": false, "reason": "%s cannot breed (happiness too low: %.0f%%)" % [parent_b.name, parent_b.happiness]}
		else:
			return {"success": false, "reason": "%s cannot breed" % parent_b.name}
	
	# ... rest of existing checks ...
```

**Acceptance Criteria:**

- Provides specific error message for low happiness
- Shows current happiness percentage
- Does not change behavior for other failures

---

### **Task 8: Add Happiness Status to DragonDetailsPanel**

**File:** `scripts/ranch/ui/panels/DragonDetailsPanel.gd`  
**Extended Thinking:** OFF  
**Priority:** P2

**Objective:** Show happiness impact on breeding in UI

**Implementation:**

gdscript

```gdscript
# Modify _update_info() method (around line 120-150)

func _update_info() -> void:
	# ... existing code to update dragon info ...
	
	# Update progress bars
	health_bar.value = current_dragon.health
	happiness_bar.value = current_dragon.happiness
	
	# *** ADD THIS SECTION ***
	# Add breeding eligibility note based on happiness
	var breeding_note: String = ""
	if current_dragon.life_stage == "adult":
		if current_dragon.health < 20.0:
			breeding_note = "\n[Health too low to breed]"
		elif current_dragon.happiness < 40.0:
			breeding_note = "\n[Happiness too low to breed - needs %.0f%%]" % (40.0 - current_dragon.happiness)
		else:
			breeding_note = "\n[Ready to breed ✓]"
	
	# Append to appropriate label (adjust based on your UI structure)
	if breeding_note:
		age_label.text += breeding_note
	
	# ... rest of existing code ...
```

**Acceptance Criteria:**

- Shows clear breeding status
- Updates when dragon info updates
- Doesn't break existing UI layout

---

### **Task 9: Create Happiness Mechanics Unit Test**

**File:** `scenes/tests/test_happiness.gd` (new file)  
**Extended Thinking:** ON  
**Priority:** P1

**Objective:** Test happiness calculation and effects

**Implementation:**

gdscript

```gdscript
extends GutTest

## Test happiness mechanics

func before_each():
	RanchState.start_new_game()

func test_base_happiness_decay():
	# Setup: Dragon with no facilities
	var dragon: DragonData = RanchState.dragons.values()[0]
	dragon.happiness = 100.0
	
	# Execute: Advance season
	RanchState.advance_season()
	
	# Verify: Happiness decreased by BASE_HAPPINESS_DECAY
	assert_eq(dragon.happiness, 95.0, "Happiness should decay by 5.0 per season")

func test_facility_bonus_happiness():
	# Setup: Build pasture (+5 happiness)
	RanchState.money = 1000
	RanchState.build_facility("pasture")
	
	var dragon: DragonData = RanchState.dragons.values()[0]
	dragon.happiness = 50.0
	
	# Execute: Advance season
	RanchState.advance_season()
	
	# Verify: Net change = +5 (facility) - 5 (decay) = 0
	assert_eq(dragon.happiness, 50.0, "Pasture bonus should offset decay")

func test_overcrowding_penalty():
	# Setup: 8 dragons with only 4 capacity
	RanchState.build_facility("stable")  # capacity 4
	
	for i in range(6):
		var dragon := DragonData.new()
		dragon.id = "test_dragon_%d" % i
		dragon.name = "Test %d" % i
		dragon.genotype = TraitDB.get_default_genotype(0)
		dragon.phenotype = GeneticsEngine.calculate_phenotype(dragon.genotype)
		dragon.happiness = 100.0
		RanchState.add_dragon(dragon)
	
	# Execute: Advance season
	RanchState.advance_season()
	
	# Verify: 4 dragons over capacity = 4 * 3.0 = 12.0 penalty
	# Net = 0 - 5 (decay) - 12 (overcrowding) = -17
	var dragon: DragonData = RanchState.dragons.values()[0]
	assert_lt(dragon.happiness, 85.0, "Overcrowding should cause happiness loss")

func test_happiness_prevents_breeding():
	# Setup: Adult dragon with low happiness
	var dragon: DragonData = RanchState.dragons.values()[0]
	dragon.life_stage = "adult"
	dragon.age = 8
	dragon.health = 100.0
	dragon.happiness = 30.0  # Below threshold
	
	# Execute & Verify
	assert_false(dragon.can_breed(), "Low happiness should prevent breeding")

func test_happiness_allows_breeding_above_threshold():
	# Setup: Adult dragon with adequate happiness
	var dragon: DragonData = RanchState.dragons.values()[0]
	dragon.life_stage = "adult"
	dragon.age = 8
	dragon.health = 100.0
	dragon.happiness = 50.0  # Above 40.0 threshold
	
	# Execute & Verify
	assert_true(dragon.can_breed(), "Adequate happiness should allow breeding")
```

**Acceptance Criteria:**

- All tests pass
- Tests cover base decay, facility bonuses, overcrowding, breeding effects
- Tests are repeatable and isolated

---

### **Task 10: Balance Testing & Constant Tuning**

**File:** `scripts/autoloads/RanchState.gd`  
**Extended Thinking:** ON  
**Priority:** P2

**Objective:** Playtest and tune happiness constants for good gameplay

**Activities:**

1. Play through 20 seasons
2. Monitor happiness values with different facility configurations
3. Test breeding scenarios
4. Adjust constants if needed:
    - `BASE_HAPPINESS_DECAY`: Currently 5.0
    - `OVERCROWDING_PENALTY_PER_DRAGON`: Currently 3.0
    - `MIN_BREEDING_HAPPINESS`: Currently 40.0

**Tuning Guidelines:**

- Happiness should stabilize around 50-70 with basic facilities
- Overcrowding should feel meaningful but not punishing
- Players should need luxury habitat for optimal happiness
- Breeding threshold should encourage facility investment

**Acceptance Criteria:**

- Gameplay feels balanced
- Players have reason to build happiness-boosting facilities
- Happiness doesn't feel like a frustrating mechanic
- Documentation updated with final values

---

## **Summary**

### **Task Sequence for Claude Haiku 4.5:**

1. **Task 1** (OFF): Add happiness constants
2. **Task 2** (OFF): Implement capacity calculation helper
3. **Task 3** (OFF): Implement overcrowding penalty helper
4. **Task 4** (ON): Implement core `_process_happiness()` method
5. **Task 5** (OFF): Integrate into `advance_season()`
6. **Task 6** (OFF): Update `DragonData.can_breed()`
7. **Task 7** (OFF): Update `GeneticsEngine.can_breed()` error messages
8. **Task 8** (OFF): Enhance DragonDetailsPanel UI
9. **Task 9** (ON): Create comprehensive unit tests
10. **Task 10** (ON): Balance testing and tuning

### **Extended Thinking Recommendations:**

- **OFF** for simple, mechanical tasks (constants, simple helpers, integrations)
- **ON** for complex logic (`_process_happiness()`, unit tests, balance analysis)

### **Files Modified:**

- `scripts/autoloads/RanchState.gd` (Tasks 1-5)
- `scripts/dragon_data.gd` (Task 6)
- `scripts/autoloads/GeneticsEngine.gd` (Task 7)
- `scripts/ranch/ui/panels/DragonDetailsPanel.gd` (Task 8)
- `scenes/tests/test_happiness.gd` (Task 9, new file)