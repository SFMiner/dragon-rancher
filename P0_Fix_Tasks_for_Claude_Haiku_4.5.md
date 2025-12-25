## P0 Fix Tasks for Claude Haiku 4.5

### Task Group A: Null/Empty Safety Checks in RNGService

---

**Task A1: Add null/empty guard to RNGService.choice()**

📁 File: `scripts/autoloads/RNGService.gd` 🧠 Extended Thinking: **OFF** (simple guard addition)

**Instructions:** Find the `choice()` function. Add a null and empty array check at the start that:

1. Returns `null` if the array parameter is null
2. Returns `null` if the array is empty
3. Calls `push_error()` with message `"[RNGService] choice: null or empty array"`

**Expected pattern:**

gdscript

```gdscript
func choice(array: Array) -> Variant:
    if array == null or array.is_empty():
        push_error("[RNGService] choice: null or empty array")
        return null
    # ... existing code
```

---

**Task A2: Add null/empty guard to RNGService.shuffle()**

📁 File: `scripts/autoloads/RNGService.gd` 🧠 Extended Thinking: **OFF** (simple guard addition)

**Instructions:** Find the `shuffle()` function. Add a null and empty array check at the start that:

1. Returns early (do nothing) if the array is null or empty
2. Calls `push_warning()` with message `"[RNGService] shuffle: null or empty array"`

---

**Task A3: Add zero-weight guard to RNGService.weighted_choice()**

📁 File: `scripts/autoloads/RNGService.gd` 🧠 Extended Thinking: **OFF** (simple guard addition)

**Instructions:** Find the `weighted_choice()` function. Add validation that:

1. Returns `null` if the weights Dictionary is null or empty
2. Returns `null` if the sum of all weight values equals zero
3. Calls `push_error()` with appropriate message for each case

---

### Task Group B: Populate Progression Unlock Arrays

---

**Task B1: Fix UNLOCKED_TRAITS constant in Progression.gd**

📁 File: `scripts/rules/Progression.gd` 🧠 Extended Thinking: **OFF** (direct value replacement)

**Instructions:** Find the `UNLOCKED_TRAITS` constant Dictionary. Replace the empty arrays with the correct trait keys based on the comments:

gdscript

```gdscript
const UNLOCKED_TRAITS: Dictionary = {
    0: ["fire", "wings", "armor"],
    1: ["color"],
    2: ["size_S", "size_G"],
    3: ["metabolism"],
    4: ["docility"]
}
```

Remove the "not implemented yet" comments since they will now be implemented.

---

### Task Group C: GeneticsEngine Validation

---

**Task C1: Add parent validation to GeneticsEngine.breed_dragons()**

📁 File: `scripts/autoloads/GeneticsEngine.gd` 🧠 Extended Thinking: **OFF** (guard already partially exists, verify completeness)

**Instructions:** Review the `breed_dragons()` function. Verify it has null checks for both parents at the start. The function should already have this—confirm it exists and returns an empty Dictionary `{}` on failure. If missing, add:

gdscript

```gdscript
if parent_a == null or parent_b == null:
    push_error("[GeneticsEngine] breed_dragons: null parent data")
    return {}
```

---

**Task C2: Add genotype validation to GeneticsEngine.calculate_phenotype()**

📁 File: `scripts/autoloads/GeneticsEngine.gd` 🧠 Extended Thinking: **ON** (must trace through function logic to find all entry points that need guards)

**Instructions:** Find the `calculate_phenotype()` function. Add validation at the start:

1. Return empty Dictionary if genotype parameter is null or empty
2. Log error with `push_error("[GeneticsEngine] calculate_phenotype: invalid genotype")`

Also check if individual trait entries are validated (each should be an Array of 2 strings). Add a guard inside the trait loop if missing.

---

### Task Group D: RanchState Edge Cases

---

**Task D1: Add breeding result validation in RanchState.create_egg()**

📁 File: `scripts/autoloads/RanchState.gd` 🧠 Extended Thinking: **ON** (must understand the breeding flow and what create_egg expects)

**Instructions:** Find where `create_egg()` is called or implemented. Ensure the offspring genotype from `GeneticsEngine.breed_dragons()` is validated before creating the egg:

1. Check if the returned genotype Dictionary is empty
2. If empty, do NOT create the egg—return early
3. Log warning: `push_warning("[RanchState] create_egg: breeding failed, no offspring genotype")`

---

**Task D2: Add duplicate ID check to RanchState.add_dragon()**

📁 File: `scripts/autoloads/RanchState.gd` 🧠 Extended Thinking: **OFF** (simple dictionary key check)

**Instructions:** Find the `add_dragon()` function. After ID generation (if ID was empty), add a check:

1. If `dragons.has(data.id)` is true, log `push_warning("[RanchState] add_dragon: duplicate ID, regenerating")` and generate a new ID
2. Use a while loop to ensure uniqueness (max 10 attempts, then error)

---

### Task Group E: TraitDB Safety

---

**Task E1: Add empty traits guard to TraitDB.get_random_genotype()**

📁 File: `scripts/autoloads/TraitDB.gd` 🧠 Extended Thinking: **ON** (must understand how traits are loaded and accessed)

**Instructions:** Find `get_random_genotype()`. Add validation:

1. If no traits are loaded (empty trait list), return empty Dictionary
2. Log error: `push_error("[TraitDB] get_random_genotype: no traits loaded")`
3. For each trait, verify alleles array is not empty before selecting random allele

---

**Task E2: Add file existence check to TraitDB.load_traits()**

📁 File: `scripts/autoloads/TraitDB.gd` 🧠 Extended Thinking: **OFF** (standard file access pattern)

**Instructions:** Find `load_traits()`. Verify it has proper file access guards:

1. Check `FileAccess.file_exists()` before opening
2. Check `FileAccess.open()` result is not null
3. Return `false` on failure with appropriate `push_error()` messages

---

### Task Group F: OrderMatching Test Suite (Skeleton)

---

**Task F1: Create test file structure for OrderMatching**

📁 File: `tests/order_matching/test_pattern_matching.gd` (NEW FILE) 🧠 Extended Thinking: **OFF** (following existing test patterns)

**Instructions:** Create a new test file following the existing test pattern in the project. Include:

1. `extends SceneTree` (or match existing test base)
2. `func _init():` that runs all tests
3. Empty test function stubs:
    - `func test_dominant_allele_pattern() -> bool`
    - `func test_exact_genotype_match() -> bool`
    - `func test_phenotype_name_match() -> bool`
    - `func test_missing_trait_requirement() -> bool`
4. Each stub should `print()` the test name and `return true`

---

**Task F2: Implement test_dominant_allele_pattern()**

📁 File: `tests/order_matching/test_pattern_matching.gd` 🧠 Extended Thinking: **ON** (must understand OrderMatching.does_dragon_match() behavior and OrderData structure)

**Instructions:** Implement the `test_dominant_allele_pattern()` function:

1. Create an OrderData with `required_traits = {"fire": "F_"}`
2. Create DragonData with genotype `{"fire": ["F", "F"]}` - should match
3. Create DragonData with genotype `{"fire": ["F", "f"]}` - should match
4. Create DragonData with genotype `{"fire": ["f", "f"]}` - should NOT match
5. Call `GeneticsEngine.calculate_phenotype()` on each dragon's genotype
6. Use `OrderMatching.does_dragon_match()` to verify behavior
7. Return `false` if any assertion fails, `true` if all pass

---

**Task F3: Implement test_exact_genotype_match()**

📁 File: `tests/order_matching/test_pattern_matching.gd` 🧠 Extended Thinking: **OFF** (follows same pattern as F2)

**Instructions:** Implement `test_exact_genotype_match()`:

1. Create OrderData with `required_traits = {"fire": "FF"}`
2. Dragon with `["F", "F"]` should match
3. Dragon with `["F", "f"]` should NOT match
4. Dragon with `["f", "f"]` should NOT match

---

### Task Group G: Pricing Test Suite (Skeleton)

---

**Task G1: Create test file for Pricing**

📁 File: `tests/pricing/test_payment_calculation.gd` (NEW FILE) 🧠 Extended Thinking: **OFF** (following existing test patterns)

**Instructions:** Create test file with stubs:

1. `func test_base_payment() -> bool`
2. `func test_reputation_bonus() -> bool`
3. `func test_exact_genotype_multiplier() -> bool`
4. `func test_combined_multipliers() -> bool`

---

**Task G2: Implement test_base_payment()**

📁 File: `tests/pricing/test_payment_calculation.gd` 🧠 Extended Thinking: **ON** (must understand Pricing.calculate_order_payment() signature and behavior)

**Instructions:** Implement `test_base_payment()`:

1. Create a minimal OrderData with known `base_payment` value
2. Create a minimal DragonData that matches the order
3. Call `Pricing.calculate_order_payment()` with reputation level 0
4. Verify returned payment equals base_payment (no bonuses at level 0)

---

## Summary Checklist

|Task|File|Extended Thinking|Complexity|
|---|---|---|---|
|A1|RNGService.gd|OFF|Simple|
|A2|RNGService.gd|OFF|Simple|
|A3|RNGService.gd|OFF|Simple|
|B1|Progression.gd|OFF|Trivial|
|C1|GeneticsEngine.gd|OFF|Simple|
|C2|GeneticsEngine.gd|**ON**|Medium|
|D1|RanchState.gd|**ON**|Medium|
|D2|RanchState.gd|OFF|Simple|
|E1|TraitDB.gd|**ON**|Medium|
|E2|TraitDB.gd|OFF|Simple|
|F1|test_pattern_matching.gd|OFF|Simple|
|F2|test_pattern_matching.gd|**ON**|Medium|
|F3|test_pattern_matching.gd|OFF|Simple|
|G1|test_payment_calculation.gd|OFF|Simple|
|G2|test_payment_calculation.gd|**ON**|Medium|

**Estimated total time:** 2-3 hours for all tasks

[Claude is AI and can make mistakes.  
Please double-check responses.](https://support.anthropic.com/en/articles/8525154-claude-is-providing-incorrect-or-misleading-responses-what-s-going-on)

  

Opus 4.5

[Claude is AI and can make mistakes. Please double-check responses.](https://support.anthropic.com/en/articles/8525154-claude-is-providing-incorrect-or-misleading-responses-what-s-going-on)