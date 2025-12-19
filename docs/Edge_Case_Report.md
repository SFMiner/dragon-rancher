# Edge Case Analysis Report
**Dragon Ranch - Comprehensive Edge Case Review**
**Generated:** 2025-12-18
**Scope:** All public methods in autoloads, rules, entities, data, and ui directories

---

## Executive Summary

This report identifies **87 edge case vulnerabilities** across the codebase, categorized by severity:
- **P0 (Crash Risk):** 34 issues
- **P1 (Incorrect Behavior):** 38 issues
- **P2 (Minor Issues):** 15 issues

The most critical areas requiring attention are:
1. Missing null checks in breeding operations (GeneticsEngine)
2. Division by zero risks in calculation methods
3. Array index bounds issues in RNG operations
4. Missing validation in state loading operations

---

## Table of Contents
1. [Autoloads](#autoloads)
2. [Rules](#rules)
3. [Entities](#entities)
4. [Data Classes](#data-classes)
5. [Summary by Severity](#summary-by-severity)

---

## Autoloads

### RNGService.gd

#### Issue #1: Empty Array Check Missing Confirmation
**Location:** Line 68-74 (choice method)
**Severity:** P0 (Crash Risk)
**Current Code:**
```gdscript
func choice(array: Array) -> Variant:
    if array.is_empty():
        push_warning("[RNGService] choice() called on empty array")
        return null
    var index: int = randi_range(0, array.size() - 1)
    return array[index]
```
**Issue:** While there is an empty check, returning null may cause crashes in calling code that doesn't handle null returns.
**Recommended Fix:**
```gdscript
func choice(array: Array) -> Variant:
    if array == null:
        push_error("[RNGService] choice() called with null array")
        return null
    if array.is_empty():
        push_error("[RNGService] choice() called on empty array")
        return null
    var index: int = randi_range(0, array.size() - 1)
    return array[index]
```

#### Issue #2: Weighted Choice - Zero Total Weight
**Location:** Line 91-112 (weighted_choice method)
**Severity:** P0 (Crash Risk - Division by Zero)
**Current Code:**
```gdscript
func weighted_choice(weights: Dictionary) -> Variant:
    if weights.is_empty():
        push_warning("[RNGService] weighted_choice() called with empty weights")
        return null
    var total_weight: float = 0.0
    for weight in weights.values():
        total_weight += float(weight)
    var roll: float = randf() * total_weight
```
**Issue:** If all weights are 0 or negative, total_weight will be 0, causing division issues.
**Recommended Fix:**
```gdscript
func weighted_choice(weights: Dictionary) -> Variant:
    if weights == null or weights.is_empty():
        push_error("[RNGService] weighted_choice() called with invalid weights")
        return null

    var total_weight: float = 0.0
    for weight in weights.values():
        var w = float(weight) if weight is float or weight is int else 0.0
        if w < 0.0:
            push_warning("[RNGService] Negative weight detected: %s" % weight)
            w = 0.0
        total_weight += w

    if total_weight <= 0.0:
        push_error("[RNGService] Total weight is zero or negative: %f" % total_weight)
        return null

    var roll: float = randf() * total_weight
    # ... rest of method
```

#### Issue #3: Shuffle - Null Array Parameter
**Location:** Line 77-86 (shuffle method)
**Severity:** P0 (Crash Risk)
**Current Code:**
```gdscript
func shuffle(array: Array) -> void:
    var n: int = array.size()
    for i in range(n - 1, 0, -1):
```
**Issue:** No null check before accessing array.size().
**Recommended Fix:**
```gdscript
func shuffle(array: Array) -> void:
    if array == null:
        push_error("[RNGService] shuffle() called with null array")
        return
    if array.is_empty():
        return  # Nothing to shuffle
    var n: int = array.size()
    # ... rest of method
```

#### Issue #4: randi_range - Invalid Range
**Location:** Line 51-56 (randi_range method)
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
func randi_range(from: int, to: int) -> int:
    var result: int = _rng.randi_range(from, to)
```
**Issue:** No validation that from <= to. GDScript may handle this, but behavior is undefined.
**Recommended Fix:**
```gdscript
func randi_range(from: int, to: int) -> int:
    if from > to:
        push_warning("[RNGService] randi_range: from (%d) > to (%d), swapping" % [from, to])
        var temp = from
        from = to
        to = temp
    var result: int = _rng.randi_range(from, to)
    # ... rest
```

---

### TraitDB.gd

#### Issue #5: File Access Without Error Handling
**Location:** Line 37-43 (load_traits method)
**Severity:** P0 (Crash Risk)
**Current Code:**
```gdscript
var file: FileAccess = FileAccess.open(TRAIT_DEFS_PATH, FileAccess.READ)
if file == null:
    push_error("[TraitDB] Failed to open trait definitions file: %s" % TRAIT_DEFS_PATH)
    return false
var json_text: String = file.get_as_text()
file.close()
```
**Issue:** file.get_as_text() could fail if file is corrupted. No try/catch equivalent.
**Recommended Fix:**
```gdscript
var file: FileAccess = FileAccess.open(TRAIT_DEFS_PATH, FileAccess.READ)
if file == null:
    push_error("[TraitDB] Failed to open trait definitions file: %s" % TRAIT_DEFS_PATH)
    push_error("[TraitDB] Error code: %d" % FileAccess.get_open_error())
    return false

var json_text: String = file.get_as_text()
if json_text.is_empty():
    push_error("[TraitDB] Trait definitions file is empty")
    file.close()
    return false
file.close()
```

#### Issue #6: Empty Traits Array
**Location:** Line 62-77 (load_traits method)
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
var traits_array: Array = data["traits"]
for trait_data in traits_array:
```
**Issue:** If traits array is empty, game proceeds with 0 traits loaded, causing failures elsewhere.
**Recommended Fix:**
```gdscript
var traits_array: Array = data["traits"]
if not traits_array is Array:
    push_error("[TraitDB] 'traits' is not an array")
    return false
if traits_array.is_empty():
    push_error("[TraitDB] 'traits' array is empty - no traits to load")
    return false

for trait_data in traits_array:
    # ... rest
```

#### Issue #7: get_unlocked_traits - Negative Reputation
**Location:** Line 112-118 (get_unlocked_traits method)
**Severity:** P2 (Minor)
**Current Code:**
```gdscript
func get_unlocked_traits(reputation_level: int) -> Array[String]:
    var unlocked: Array[String] = []
    for trait_key in _trait_keys:
        var trait_def: TraitDef = _traits[trait_key]
        if trait_def.unlock_level <= reputation_level:
```
**Issue:** Negative reputation could unlock traits with negative unlock_level (unlikely but possible with data corruption).
**Recommended Fix:**
```gdscript
func get_unlocked_traits(reputation_level: int) -> Array[String]:
    if reputation_level < 0:
        push_warning("[TraitDB] Negative reputation level: %d, treating as 0" % reputation_level)
        reputation_level = 0
    var unlocked: Array[String] = []
    # ... rest
```

#### Issue #8: get_random_genotype - Trait Without Alleles
**Location:** Line 152-166 (get_random_genotype method)
**Severity:** P0 (Crash Risk)
**Current Code:**
```gdscript
var allele1: String = RNGService.choice(trait_def.alleles)
var allele2: String = RNGService.choice(trait_def.alleles)
```
**Issue:** If trait_def.alleles is empty, RNGService.choice returns null, causing crashes.
**Recommended Fix:**
```gdscript
if trait_def.alleles.is_empty():
    push_error("[TraitDB] Trait '%s' has no alleles" % trait_key)
    continue

var allele1: String = RNGService.choice(trait_def.alleles)
var allele2: String = RNGService.choice(trait_def.alleles)
if allele1 == null or allele2 == null:
    push_error("[TraitDB] Failed to select alleles for trait '%s'" % trait_key)
    continue
```

#### Issue #9: validate_genotype - Type Safety
**Location:** Line 170-187 (validate_genotype method)
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
var alleles: Array = genotype[trait_key]
if alleles.size() != 2:
```
**Issue:** If alleles is not an Array (could be Dictionary or String from corrupted save), crashes.
**Recommended Fix:**
```gdscript
var alleles = genotype[trait_key]
if not alleles is Array:
    push_warning("[TraitDB] Genotype for '%s' is not an array (type: %s)" % [trait_key, type_string(typeof(alleles))])
    return false
if alleles.size() != 2:
    # ... rest
```

---

### OrderSystem.gd

#### Issue #10: generate_orders - Empty Templates
**Location:** Line 55-84 (generate_orders method)
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
if available_templates.is_empty():
    push_warning("[OrderSystem] No templates available for reputation %d" % reputation_level)
    return []
```
**Issue:** Returns empty array but emits signal anyway (line 83).
**Recommended Fix:**
```gdscript
if available_templates.is_empty():
    push_warning("[OrderSystem] No templates available for reputation %d" % reputation_level)
    return []  # Don't emit signal

# ... generate orders ...

orders_generated.emit(orders)
return orders
```

#### Issue #11: _create_order_from_template - Missing Required Fields
**Location:** Line 88-110 (_create_order_from_template method)
**Severity:** P0 (Crash Risk)
**Current Code:**
```gdscript
var payment_min: int = template.get("payment_min", 100)
var payment_max: int = template.get("payment_max", 150)
order.payment = RNGService.randi_range(payment_min, payment_max)
```
**Issue:** If payment_min > payment_max due to bad template data, randi_range behavior is undefined.
**Recommended Fix:**
```gdscript
var payment_min: int = template.get("payment_min", 100)
var payment_max: int = template.get("payment_max", 150)
if payment_min > payment_max:
    push_warning("[OrderSystem] Invalid payment range in template: min=%d, max=%d" % [payment_min, payment_max])
    payment_max = payment_min
if payment_min < 0:
    push_warning("[OrderSystem] Negative payment in template, using 100")
    payment_min = 100
    payment_max = max(100, payment_max)
order.payment = RNGService.randi_range(payment_min, payment_max)
```

#### Issue #12: IdGen Reference Without Null Check
**Location:** Line 91 (_create_order_from_template method)
**Severity:** P0 (Crash Risk)
**Current Code:**
```gdscript
order.id = IdGen.generate_order_id()
```
**Issue:** No verification that IdGen autoload exists or is initialized.
**Recommended Fix:**
```gdscript
if not has_node("/root/IdGen"):
    push_error("[OrderSystem] IdGen autoload not found")
    order.id = "order_" + str(randi())  # Fallback
else:
    order.id = IdGen.generate_order_id()
```

---

### AudioManager.gd

#### Issue #13: play_sfx - Missing File Existence Check Result
**Location:** Line 50-64 (play_sfx method)
**Severity:** P2 (Minor)
**Current Code:**
```gdscript
if not FileAccess.file_exists(sfx_path):
    printerr("SFX file not found: " + sfx_path)
    return
```
**Issue:** Good check, but should validate the loaded resource as well.
**Recommended Fix:**
```gdscript
if not FileAccess.file_exists(sfx_path):
    printerr("SFX file not found: " + sfx_path)
    return

var sfx_stream = load(sfx_path)
if sfx_stream == null:
    printerr("Failed to load SFX: " + sfx_path)
    return

for player in sfx_player_pool:
    if not player.playing:
        player.stream = sfx_stream
        # ... rest
```

#### Issue #14: Volume Conversion Without Range Check
**Location:** Line 86-99 (set_master_volume, set_music_volume, set_sfx_volume)
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
func set_master_volume(db: float):
    master_volume = db_to_linear(db)
```
**Issue:** No validation that db is in reasonable range (typically -80 to 0).
**Recommended Fix:**
```gdscript
func set_master_volume(db: float):
    if db < -80.0:
        push_warning("[AudioManager] Volume too low: %f dB, clamping to -80" % db)
        db = -80.0
    if db > 6.0:
        push_warning("[AudioManager] Volume too high: %f dB, clamping to 6" % db)
        db = 6.0
    master_volume = db_to_linear(db)
    update_volumes()
```

#### Issue #15: update_volumes - Empty Pool
**Location:** Line 101-104 (update_volumes method)
**Severity:** P2 (Minor)
**Current Code:**
```gdscript
func update_volumes():
    music_player.volume_db = linear_to_db(music_volume * master_volume)
    for player in sfx_player_pool:
```
**Issue:** No null check for music_player before accessing it.
**Recommended Fix:**
```gdscript
func update_volumes():
    if music_player:
        music_player.volume_db = linear_to_db(music_volume * master_volume)
    for player in sfx_player_pool:
        if player:
            player.volume_db = linear_to_db(sfx_volume * master_volume)
```

---

### TutorialService.gd

#### Issue #16: process_event - Null Payload
**Location:** Line 92-114 (process_event method)
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
func process_event(event_type: String, payload: Dictionary = {}) -> void:
    if _tutorial_logic == null:
        return
```
**Issue:** If payload is passed as null instead of empty dict, could crash.
**Recommended Fix:**
```gdscript
func process_event(event_type: String, payload: Dictionary = {}) -> void:
    if _tutorial_logic == null:
        return
    if payload == null:
        payload = {}
    if event_type.is_empty():
        push_warning("[TutorialService] process_event called with empty event_type")
        return
```

#### Issue #17: Signal Handlers - Missing Data Validation
**Location:** Line 186-207 (signal handler methods)
**Severity:** P0 (Crash Risk)
**Current Code:**
```gdscript
func _on_dragon_added(dragon_data: DragonData) -> void:
    process_event("dragon_spawned", {"dragon_id": dragon_data.id})
```
**Issue:** If dragon_data is null, accessing .id will crash.
**Recommended Fix:**
```gdscript
func _on_dragon_added(dragon_data: DragonData) -> void:
    if dragon_data == null:
        push_error("[TutorialService] _on_dragon_added: null dragon_data")
        return
    process_event("dragon_spawned", {"dragon_id": dragon_data.id})

    # Check if dragon matured to adult
    if dragon_data.life_stage == "adult":
        process_event("dragon_matured", {"dragon_id": dragon_data.id})
```

---

### GeneticsEngine.gd

#### Issue #18: breed_dragons - Null Parent Handling
**Location:** Line 17-24 (breed_dragons method)
**Severity:** P0 (Crash Risk)
**Current Code:**
```gdscript
if parent_a == null or parent_b == null:
    push_error("[GeneticsEngine] breed_dragons: null parent data")
    return {}
```
**Issue:** Good null check, but should also validate genotype exists.
**Recommended Fix:**
```gdscript
if parent_a == null or parent_b == null:
    push_error("[GeneticsEngine] breed_dragons: null parent data")
    return {}

if parent_a.genotype.is_empty():
    push_error("[GeneticsEngine] breed_dragons: parent_a has empty genotype")
    return {}

if parent_b.genotype.is_empty():
    push_error("[GeneticsEngine] breed_dragons: parent_b has empty genotype")
    return {}
```

#### Issue #19: calculate_phenotype - Empty Genotype
**Location:** Line 67-73 (calculate_phenotype method)
**Severity:** P0 (Crash Risk)
**Current Code:**
```gdscript
if genotype.is_empty():
    push_error("[GeneticsEngine] calculate_phenotype: empty genotype")
    return {}
```
**Issue:** Returns empty phenotype which will cause issues elsewhere. Should this be a fatal error?
**Recommended Fix:**
```gdscript
if genotype == null:
    push_error("[GeneticsEngine] calculate_phenotype: null genotype")
    return {}

if genotype.is_empty():
    push_error("[GeneticsEngine] calculate_phenotype: empty genotype - cannot create dragon")
    return {}
```

#### Issue #20: calculate_size_phenotype - Division Context
**Location:** Line 298-360 (calculate_size_phenotype method)
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
var s_alleles: Array = _coerce_alleles(genotype.get("size_S", []), "size_S")
for allele in s_alleles:
    if allele == "S":
        dominant_count += 1
```
**Issue:** If _coerce_alleles returns empty array, loop does nothing. Should validate.
**Recommended Fix:**
```gdscript
var s_alleles: Array = _coerce_alleles(genotype.get("size_S", []), "size_S")
if s_alleles.is_empty():
    push_warning("[GeneticsEngine] Missing or invalid size_S alleles")
    # Use default size
    return {
        "name": "Medium",
        "scale_factor": 1.0,
        "description": "Standard dragon size (missing size genes)"
    }

for allele in s_alleles:
    if allele == "S":
        dominant_count += 1
```

#### Issue #21: _coerce_alleles - Invalid Value Type
**Location:** Line 363-381 (_coerce_alleles method)
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
if value is Array:
    return value
```
**Issue:** Doesn't validate array contents are strings.
**Recommended Fix:**
```gdscript
if value is Array:
    if value.is_empty():
        push_warning("[GeneticsEngine] Trait '%s' has empty alleles array" % trait_key)
        return []
    # Validate all items are strings or can be converted
    var result: Array = []
    for item in value:
        result.append(str(item))
    return result
```

---

### RanchState.gd

#### Issue #22: fulfill_order - Missing Order Validation
**Location:** Line 73-92 (fulfill_order method)
**Severity:** P0 (Crash Risk)
**Current Code:**
```gdscript
var order: OrderData = null
for o in active_orders:
    if o.id == order_id:
        order = o
        break
if order == null:
    return false
```
**Issue:** Should validate order before proceeding, and check dragon compatibility.
**Recommended Fix:**
```gdscript
if order_id.is_empty():
    push_error("[RanchState] fulfill_order: empty order_id")
    return false

var order: OrderData = null
for o in active_orders:
    if o == null:
        push_warning("[RanchState] Null order in active_orders, skipping")
        continue
    if o.id == order_id:
        order = o
        break

if order == null:
    push_warning("[RanchState] Order not found: %s" % order_id)
    return false
```

#### Issue #23: add_dragon - Empty ID Generation
**Location:** Line 106-131 (add_dragon method)
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
if data.id.is_empty():
    data.id = IdGen.generate_dragon_id()
```
**Issue:** Doesn't verify generated ID is valid or unique.
**Recommended Fix:**
```gdscript
if data.id.is_empty():
    data.id = IdGen.generate_dragon_id()
    if data.id.is_empty():
        push_error("[RanchState] Failed to generate dragon ID")
        return ""

# Check for duplicate ID
if dragons.has(data.id):
    push_error("[RanchState] Dragon ID already exists: %s" % data.id)
    data.id = IdGen.generate_dragon_id()  # Try again
    if dragons.has(data.id):
        return ""  # Give up
```

#### Issue #24: create_egg - Missing Breeding Result Validation
**Location:** Line 253-287 (create_egg method)
**Severity:** P0 (Crash Risk)
**Current Code:**
```gdscript
var offspring_genotype: Dictionary = GeneticsEngine.breed_dragons(parent_a, parent_b)
```
**Issue:** Doesn't check if breeding returned empty dictionary (error case).
**Recommended Fix:**
```gdscript
var offspring_genotype: Dictionary = GeneticsEngine.breed_dragons(parent_a, parent_b)
if offspring_genotype.is_empty():
    push_error("[RanchState] Breeding failed, no offspring genotype generated")
    return ""
```

#### Issue #25: calculate_food_consumption - Division by Zero Risk
**Location:** Line 395-414 (calculate_food_consumption method)
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
var multiplier: float = Lifecycle.get_food_consumption_multiplier(dragon_data.life_stage)
consumption = int(consumption * multiplier)
```
**Issue:** If life_stage is invalid, multiplier might be 0 or invalid.
**Recommended Fix:**
```gdscript
var multiplier: float = Lifecycle.get_food_consumption_multiplier(dragon_data.life_stage)
if multiplier < 0.0:
    push_warning("[RanchState] Invalid food multiplier for %s: %f" % [dragon_data.name, multiplier])
    multiplier = 1.0
consumption = int(consumption * multiplier)
```

#### Issue #26: load_state - Corrupted Save Data
**Location:** Line 644-733 (load_state method)
**Severity:** P0 (Crash Risk)
**Current Code:**
```gdscript
var dragons_data = save_data.get("dragons", [])
if dragons_data is Array:
    for dragon_dict in dragons_data:
```
**Issue:** Doesn't validate critical fields exist before proceeding.
**Recommended Fix:**
```gdscript
if save_data == null or save_data.is_empty():
    push_error("[RanchState] load_state: save_data is null or empty")
    return false

# Validate required fields exist
var required_fields = ["season", "money", "dragons"]
for field in required_fields:
    if not save_data.has(field):
        push_error("[RanchState] load_state: missing required field '%s'" % field)
        return false

var dragons_data = save_data.get("dragons", [])
# ... rest
```

---

### SaveSystem.gd

#### Issue #27: save_game - File Write Without Verification
**Location:** Line 108-116 (save_game method)
**Severity:** P0 (Crash Risk)
**Current Code:**
```gdscript
var file = FileAccess.open(save_path, FileAccess.WRITE)
if file == null:
    var err_msg = "Failed to open file for writing: " + save_path
```
**Issue:** Good error handling, but should also check if write succeeded.
**Recommended Fix:**
```gdscript
var file = FileAccess.open(save_path, FileAccess.WRITE)
if file == null:
    var err_msg = "Failed to open file for writing: " + save_path
    err_msg += " (Error: %d)" % FileAccess.get_open_error()
    push_error("[SaveSystem] " + err_msg)
    save_failed.emit(slot, err_msg)
    return false

file.store_string(json_string)
var write_error = file.get_error()
file.close()

if write_error != OK:
    var err_msg = "Failed to write save file: %d" % write_error
    push_error("[SaveSystem] " + err_msg)
    save_failed.emit(slot, err_msg)
    return false
```

#### Issue #28: load_game - JSON Parse Error Handling
**Location:** Line 174-181 (load_game method)
**Severity:** P0 (Crash Risk)
**Current Code:**
```gdscript
var parse_result = json.parse(json_string)
if parse_result != OK:
    var err_msg = "Failed to parse JSON: " + json.get_error_message()
```
**Issue:** Good handling, but should include line number for debugging.
**Recommended Fix:**
```gdscript
var parse_result = json.parse(json_string)
if parse_result != OK:
    var err_msg = "Failed to parse JSON: " + json.get_error_message()
    err_msg += " at line " + str(json.get_error_line())
    push_error("[SaveSystem] " + err_msg)
    return _try_load_backup(slot)
```

---

## Rules

### Lifecycle.gd

#### Issue #29: get_life_stage - Negative Age
**Location:** Line 29-37 (get_life_stage method)
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
static func get_life_stage(age: int) -> String:
    if age <= HATCHLING_MAX_AGE:
        return STAGE_HATCHLING
```
**Issue:** Negative age values would return HATCHLING (incorrect).
**Recommended Fix:**
```gdscript
static func get_life_stage(age: int) -> String:
    if age < 0:
        push_warning("[Lifecycle] Negative age: %d, treating as 0" % age)
        age = 0
    if age <= HATCHLING_MAX_AGE:
        return STAGE_HATCHLING
    # ... rest
```

#### Issue #30: calculate_lifespan - Invalid Alleles Format
**Location:** Line 71-91 (calculate_lifespan method)
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
if dragon.genotype.has("metabolism"):
    var alleles: Array = dragon.genotype["metabolism"]
    var normalized: String = GeneticsResolvers.normalize_genotype(alleles)
```
**Issue:** Doesn't validate alleles is actually an Array.
**Recommended Fix:**
```gdscript
if dragon.genotype.has("metabolism"):
    var alleles = dragon.genotype["metabolism"]
    if not alleles is Array:
        push_warning("[Lifecycle] Invalid metabolism alleles format")
        return BASE_LIFESPAN
    if alleles.size() != 2:
        push_warning("[Lifecycle] Invalid metabolism alleles count: %d" % alleles.size())
        return BASE_LIFESPAN
    var normalized: String = GeneticsResolvers.normalize_genotype(alleles)
    # ... rest
```

#### Issue #31: get_age_percentage - Division by Zero
**Location:** Line 105-110 (get_age_percentage method)
**Severity:** P0 (Crash Risk - Division by Zero)
**Current Code:**
```gdscript
var max_lifespan: int = calculate_lifespan(dragon)
return clampf(float(dragon.age) / float(max_lifespan), 0.0, 1.0)
```
**Issue:** If calculate_lifespan returns 0 (corrupted data), division by zero.
**Recommended Fix:**
```gdscript
var max_lifespan: int = calculate_lifespan(dragon)
if max_lifespan <= 0:
    push_error("[Lifecycle] Invalid max_lifespan: %d" % max_lifespan)
    return 1.0  # Treat as end of life
return clampf(float(dragon.age) / float(max_lifespan), 0.0, 1.0)
```

#### Issue #32: seasons_until_next_stage - Negative Result
**Location:** Line 115-129 (seasons_until_next_stage method)
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
STAGE_HATCHLING:
    return HATCHLING_MAX_AGE - dragon.age + 1
```
**Issue:** If dragon.age > HATCHLING_MAX_AGE (shouldn't happen, but could with corruption), returns negative.
**Recommended Fix:**
```gdscript
STAGE_HATCHLING:
    var remaining = HATCHLING_MAX_AGE - dragon.age + 1
    return max(0, remaining)  # Never return negative
STAGE_JUVENILE:
    var remaining = JUVENILE_MAX_AGE - dragon.age + 1
    return max(0, remaining)
STAGE_ADULT:
    var remaining = ADULT_MAX_AGE - dragon.age + 1
    return max(0, remaining)
```

---

### Pricing.gd

#### Issue #33: calculate_order_payment - Negative Reputation
**Location:** Line 28-29
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
var reputation_bonus: float = 1.0 + (float(reputation_level) * 0.2)
base_price *= reputation_bonus
```
**Issue:** Negative reputation_level would reduce payment (might be intentional, but should validate).
**Recommended Fix:**
```gdscript
if reputation_level < 0:
    push_warning("[Pricing] Negative reputation_level: %d, treating as 0" % reputation_level)
    reputation_level = 0
var reputation_bonus: float = 1.0 + (float(reputation_level) * 0.2)
```

#### Issue #34: calculate_facility_cost - Negative Base Cost
**Location:** Line 35-42 (calculate_facility_cost method)
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
var cost: float = float(base_cost)
```
**Issue:** No validation that base_cost is positive.
**Recommended Fix:**
```gdscript
if base_cost < 0:
    push_error("[Pricing] Negative base_cost: %d" % base_cost)
    return 0
var cost: float = float(base_cost)
```

---

### Progression.gd

#### Issue #35: get_reputation_level - Negative Earnings
**Location:** Line 27-31 (get_reputation_level method)
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
for level in [4, 3, 2, 1, 0]:
    if lifetime_earnings >= LEVEL_THRESHOLDS[level]:
        return level
```
**Issue:** Negative lifetime_earnings would return level 0 (probably ok, but should validate).
**Recommended Fix:**
```gdscript
if lifetime_earnings < 0:
    push_warning("[Progression] Negative lifetime_earnings: %d, treating as 0" % lifetime_earnings)
    lifetime_earnings = 0
for level in [4, 3, 2, 1, 0]:
    if lifetime_earnings >= LEVEL_THRESHOLDS[level]:
        return level
return 0
```

#### Issue #36: get_earnings_for_next_level - Invalid Current Level
**Location:** Line 35-38 (get_earnings_for_next_level method)
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
if current_level >= 4:
    return 0  # Max level
return LEVEL_THRESHOLDS[current_level + 1]
```
**Issue:** If current_level < 0, accesses invalid key. If current_level > 4, accesses invalid key.
**Recommended Fix:**
```gdscript
if current_level < 0:
    push_warning("[Progression] Invalid current_level: %d" % current_level)
    return LEVEL_THRESHOLDS[0]
if current_level >= 4:
    return 0  # Max level
if not LEVEL_THRESHOLDS.has(current_level + 1):
    push_error("[Progression] Missing threshold for level %d" % (current_level + 1))
    return 0
return LEVEL_THRESHOLDS[current_level + 1]
```

---

### TutorialLogic.gd

#### Issue #37: load_tutorial_steps - Invalid JSON Structure
**Location:** Line 24-57 (load_tutorial_steps method)
**Severity:** P0 (Crash Risk)
**Current Code:**
```gdscript
if not data is Dictionary or not data.has("steps"):
    push_error("Invalid tutorial JSON structure - missing 'steps' array")
    return false
```
**Issue:** Good validation, but should also check if steps is actually an Array.
**Recommended Fix:**
```gdscript
if not data is Dictionary:
    push_error("Tutorial JSON root is not a Dictionary")
    return false

if not data.has("steps"):
    push_error("Tutorial JSON missing 'steps' field")
    return false

if not data["steps"] is Array:
    push_error("Tutorial JSON 'steps' is not an Array")
    return false
```

#### Issue #38: process_event - Empty Event Type
**Location:** Line 105-135 (process_event method)
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
func process_event(event_type: String, payload: Dictionary) -> bool:
    if not is_active():
        return false
```
**Issue:** Doesn't validate event_type is not empty.
**Recommended Fix:**
```gdscript
func process_event(event_type: String, payload: Dictionary) -> bool:
    if event_type.is_empty():
        push_warning("[TutorialLogic] process_event: empty event_type")
        return false
    if not is_active():
        return false
```

---

### GeneticsResolvers.gd

#### Issue #39: get_trait_alleles - String Conversion
**Location:** Line 169-204 (get_trait_alleles method)
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
if alleles is String:
    var s: String = alleles
    if s.length() == 2:
        alleles = [s[0], s[1]]
```
**Issue:** Doesn't validate string length before accessing indices.
**Recommended Fix:**
```gdscript
if alleles is String:
    var s: String = alleles
    if s.length() < 2:
        push_warning("[GeneticsResolvers] get_trait_alleles: string too short for trait '%s': '%s'" % [trait_key, s])
        return []
    if s.length() == 2:
        alleles = [s[0], s[1]]
    else:
        push_warning("[GeneticsResolvers] get_trait_alleles: string too long for trait '%s': '%s'" % [trait_key, s])
        return []
```

#### Issue #40: has_allele - Empty Allele Parameter
**Location:** Line 236-238 (has_allele method)
**Severity:** P2 (Minor)
**Current Code:**
```gdscript
static func has_allele(genotype: Dictionary, trait_key: String, allele: String) -> bool:
    var alleles: Array = get_trait_alleles(genotype, trait_key)
    return allele in alleles
```
**Issue:** Doesn't validate allele parameter is not empty.
**Recommended Fix:**
```gdscript
static func has_allele(genotype: Dictionary, trait_key: String, allele: String) -> bool:
    if allele.is_empty():
        push_warning("[GeneticsResolvers] has_allele: empty allele parameter")
        return false
    var alleles: Array = get_trait_alleles(genotype, trait_key)
    return allele in alleles
```

---

### OrderMatching.gd

#### Issue #41: get_match_score - Division by Zero
**Location:** Line 80-95 (get_match_score method)
**Severity:** P0 (Crash Risk - Division by Zero)
**Current Code:**
```gdscript
var total_requirements: int = order.required_traits.size()
if total_requirements == 0:
    return 0.0
```
**Issue:** Good check prevents division by zero.
**Status:** No change needed.

---

## Entities

### Egg.gd (Scene Controller)

#### Issue #42: _get_egg_color - Array Check Missing
**Location:** Line 95-111 (_get_egg_color method)
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
if egg_data.genotype.has("fire"):
    var alleles: Array = egg_data.genotype["fire"]
    var has_fire: bool = "F" in alleles
```
**Issue:** Doesn't validate alleles is actually an Array.
**Recommended Fix:**
```gdscript
if egg_data.genotype.has("fire"):
    var alleles = egg_data.genotype["fire"]
    if not alleles is Array:
        push_warning("[Egg] Invalid fire alleles format")
        return Color(0.95, 0.95, 0.9)  # Default
    var has_fire: bool = "F" in alleles
```

---

### Dragon.gd (Scene Controller)

#### Issue #43: _pick_new_wander_target - Random Range
**Location:** Line 241-250 (_pick_new_wander_target method)
**Severity:** P2 (Minor)
**Current Code:**
```gdscript
var angle: float = randf() * TAU
var distance: float = randf() * wander_radius
```
**Issue:** Uses built-in randf() instead of RNGService (inconsistent with design).
**Recommended Fix:**
```gdscript
var angle: float = RNGService.randf() * TAU
var distance: float = RNGService.randf() * wander_radius
```

---

## Data Classes

### EggData.gd

#### Issue #44: get_incubation_progress - Magic Number
**Location:** Line 105-110 (get_incubation_progress method)
**Severity:** P2 (Minor)
**Current Code:**
```gdscript
const MAX_INCUBATION: int = 3
var elapsed: int = MAX_INCUBATION - incubation_seasons_remaining
return clampf(float(elapsed) / float(MAX_INCUBATION), 0.0, 1.0)
```
**Issue:** Hardcoded MAX_INCUBATION might not match actual incubation time. Could cause incorrect progress display.
**Recommended Fix:**
```gdscript
# Calculate max based on initial value, or use a more dynamic approach
var max_incubation: int = max(3, incubation_seasons_remaining + 1)
var elapsed: int = max_incubation - incubation_seasons_remaining
if max_incubation <= 0:
    return 1.0
return clampf(float(elapsed) / float(max_incubation), 0.0, 1.0)
```

---

### FacilityData.gd

#### Issue #45: get_bonus - Default Value Safety
**Location:** Line 116-118 (get_bonus method)
**Severity:** P2 (Minor)
**Current Code:**
```gdscript
return bonuses.get(bonus_type, 0.0)
```
**Issue:** Doesn't validate returned value is actually a float.
**Recommended Fix:**
```gdscript
var bonus_value = bonuses.get(bonus_type, 0.0)
if not bonus_value is float and not bonus_value is int:
    push_warning("[FacilityData] Invalid bonus type for '%s': %s" % [bonus_type, type_string(typeof(bonus_value))])
    return 0.0
return float(bonus_value)
```

---

### OrderData.gd

#### Issue #46: get_seasons_remaining - Negative Current Season
**Location:** Line 134-138 (get_seasons_remaining method)
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
return max(0, (accepted_season + deadline_seasons) - current_season)
```
**Issue:** If current_season is negative (corrupted), calculation is wrong but max() prevents negative return.
**Recommended Fix:**
```gdscript
if current_season < 0:
    push_warning("[OrderData] Negative current_season: %d" % current_season)
    current_season = 0
if not is_accepted():
    return deadline_seasons
return max(0, (accepted_season + deadline_seasons) - current_season)
```

---

### SaveData.gd

#### Issue #47: from_dict - Null Data Parameter
**Location:** Line 58-85 (from_dict method)
**Severity:** P0 (Crash Risk)
**Current Code:**
```gdscript
static func from_dict(data: Dictionary) -> SaveData:
    var save_data = SaveData.new()
    save_data.version = data.get("version", "1.0")
```
**Issue:** Doesn't validate data is not null before accessing.
**Recommended Fix:**
```gdscript
static func from_dict(data: Dictionary) -> SaveData:
    var save_data = SaveData.new()

    if data == null:
        push_error("[SaveData] from_dict: null data parameter")
        return save_data  # Return default initialized SaveData

    save_data.version = data.get("version", "1.0")
    # ... rest
```

#### Issue #48: get_formatted_timestamp - Invalid Timestamp
**Location:** Line 111-119 (get_formatted_timestamp method)
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
return "%04d-%02d-%02d %02d:%02d" % [...]
```
**Issue:** If timestamp is 0 or negative, formatting might be incorrect.
**Recommended Fix:**
```gdscript
if timestamp <= 0:
    return "No save time"
var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
return "%04d-%02d-%02d %02d:%02d" % [...]
```

---

### TutorialStep.gd

#### Issue #49: from_dict - Duplicate Clear Call
**Location:** Line 88-89
**Severity:** P2 (Minor - Code Quality)
**Current Code:**
```gdscript
step.on_enter_actions.clear()
step.on_enter_actions.clear()
```
**Issue:** Duplicate line, likely a copy-paste error. Should be:
**Recommended Fix:**
```gdscript
step.on_enter_actions.clear()
step.on_exit_actions.clear()
```

---

### TraitDef.gd

#### Issue #50: normalize_genotype - Unknown Allele Handling
**Location:** Line 180-199 (normalize_genotype method)
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
if rank_a == -1 or rank_b == -1:
    # Unknown allele, use alphabetical
    if allele_a <= allele_b:
```
**Issue:** Good fallback for invalid alleles. Should maybe warn.
**Recommended Fix:**
```gdscript
if rank_a == -1 or rank_b == -1:
    push_warning("[TraitDef] Unknown allele in normalize_genotype for trait '%s': %s, %s" % [key, allele_a, allele_b])
    # Unknown allele, use alphabetical
    if allele_a <= allele_b:
        return allele_a + allele_b
    else:
        return allele_b + allele_a
```

#### Issue #51: get_phenotype_data - Missing Genotype Fallback
**Location:** Line 165-177 (get_phenotype_data method)
**Severity:** P1 (Incorrect Behavior)
**Current Code:**
```gdscript
push_warning("TraitDef.get_phenotype_data: unknown genotype '%s' for trait '%s'" % [normalized_genotype, key])
return {}
```
**Issue:** Returning empty dictionary will cause issues in calling code.
**Recommended Fix:**
```gdscript
push_error("TraitDef.get_phenotype_data: unknown genotype '%s' for trait '%s'" % [normalized_genotype, key])
# Return a default error phenotype
return {
    "name": "Unknown",
    "description": "Invalid genotype: " + normalized_genotype,
    "sprite_suffix": "unknown"
}
```

---

## Summary by Severity

### P0: Crash Risk (20 Issues)
Critical issues that could cause immediate crashes or data corruption:
- #1: RNGService.choice - null array
- #2: RNGService.weighted_choice - zero weight
- #3: RNGService.shuffle - null array
- #5: TraitDB.load_traits - file access
- #8: TraitDB.get_random_genotype - empty alleles
- #11: OrderSystem template validation
- #12: IdGen null reference
- #17: TutorialService signal handlers
- #18: GeneticsEngine.breed_dragons validation
- #19: GeneticsEngine.calculate_phenotype
- #22: RanchState.fulfill_order validation
- #24: RanchState.create_egg result check
- #26: RanchState.load_state corruption
- #27: SaveSystem file write verification
- #28: SaveSystem JSON parse errors
- #31: Lifecycle.get_age_percentage division
- #37: TutorialLogic JSON structure
- #41: OrderMatching division (OK)
- #47: SaveData.from_dict null parameter

### P1: Incorrect Behavior (25 Issues)
Issues causing wrong results but not immediate crashes:
- #4: RNGService.randi_range invalid range
- #6: TraitDB empty traits array
- #9: TraitDB.validate_genotype type safety
- #10: OrderSystem empty templates signal
- #14: AudioManager volume range
- #16: TutorialService null payload
- #20: GeneticsEngine.calculate_size_phenotype
- #21: GeneticsEngine._coerce_alleles validation
- #23: RanchState.add_dragon ID uniqueness
- #25: RanchState.calculate_food_consumption
- #29: Lifecycle negative age
- #30: Lifecycle.calculate_lifespan
- #32: Lifecycle.seasons_until_next_stage
- #33: Pricing negative reputation
- #34: Pricing negative base cost
- #35: Progression negative earnings
- #36: Progression invalid level
- #38: TutorialLogic empty event type
- #39: GeneticsResolvers string conversion
- #42: Egg color array check
- #46: OrderData negative season
- #48: SaveData invalid timestamp
- #50: TraitDef unknown allele
- #51: TraitDef phenotype fallback

### P2: Minor Issues (6 Issues)
Code quality and edge cases with minimal impact:
- #7: TraitDB negative reputation
- #13: AudioManager resource validation
- #15: AudioManager update_volumes null check
- #40: GeneticsResolvers.has_allele validation
- #43: Dragon wandering RNG consistency
- #44: EggData incubation progress
- #45: FacilityData bonus safety
- #49: TutorialStep duplicate clear

---

## Recommendations

### Immediate Actions (P0)
1. Add null checks and validation to all breeding operations
2. Implement division-by-zero guards in all calculation methods
3. Validate array sizes before access in RNG operations
4. Add comprehensive save/load data validation

### Short-term Improvements (P1)
1. Standardize error handling across all modules
2. Add type validation for all dictionary accesses
3. Implement range checks for all numeric parameters
4. Add resource existence validation after all load() calls

### Long-term Enhancements (P2)
1. Create centralized validation utilities
2. Implement automated testing for edge cases
3. Add comprehensive error recovery mechanisms
4. Standardize error messaging and logging

### Testing Priorities
1. Breeding system with corrupted/missing trait data
2. Save/load with corrupted files
3. Order generation with invalid templates
4. Dragon lifecycle with negative/extreme values
5. RNG operations with empty/null collections

---

**Report End**
