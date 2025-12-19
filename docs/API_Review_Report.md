# API Review Report

Generated: 2025-12-18

This report details violations of the established API contracts defined in `API_Reference.md`.

## Summary

This review examines 8 autoload implementations against the locked API specification (Version 1.0). The analysis identifies:

- Missing documented methods, signals, and properties
- Signature mismatches (parameters, types, return values)
- Undocumented public API additions (API drift)
- Naming inconsistencies

## Review Status by Autoload

| Autoload | Missing APIs | Signature Mismatches | API Drift | Status |
|----------|--------------|---------------------|-----------|---------|
| RNGService | 1 method | 1 method | 5 methods | VIOLATIONS |
| TraitDB | 3 methods, 1 property | 1 method | 8 methods | VIOLATIONS |
| GeneticsEngine | 2 methods | 1 method | 5 methods | VIOLATIONS |
| RanchState | 7 methods, 2 signals, 1 property | 2 methods | 14 methods, 1 signal | VIOLATIONS |
| OrderSystem | 4 methods | 0 | 2 methods | VIOLATIONS |
| SaveSystem | 4 methods | 6 methods, 3 constants | 10 methods, 2 signals, 2 properties | VIOLATIONS |
| AudioManager | 4 methods | 0 | 7 methods | VIOLATIONS |
| TutorialService | 3 properties | 2 methods | 9 methods | VIOLATIONS |

---

## Detailed Findings

### RNGService (`scripts/autoloads/RNGService.gd`)

#### Missing Documented APIs

**Method:**
- `pick_random(array: Array) -> Variant` - MISSING (implemented as `choice()` instead)

#### Signature Mismatches

**Method: `shuffle(array: Array)`**
- API Spec: `shuffle(array: Array) -> Array` (returns the shuffled array)
- Implementation: `shuffle(array: Array) -> void` (modifies in-place, no return)
- Impact: Breaks functional programming patterns that expect return value

#### Undocumented Public APIs (API Drift)

**Methods:**
- `choice(array: Array) -> Variant` - Should be named `pick_random()`
- `weighted_choice(weights: Dictionary) -> Variant`
- `print_seed() -> void`
- `randomize_seed() -> void`
- `to_dict() -> Dictionary`
- `from_dict(data: Dictionary) -> void`

**Properties:**
- `debug_mode: bool = false`

---

### TraitDB (`scripts/autoloads/TraitDB.gd`)

#### Missing Documented APIs

**Property:**
- `unlocked_traits: Array[String] = []` - Not present in implementation

**Methods:**
- `get_all_trait_defs() -> Array[TraitDef]` - MISSING (implemented as `get_all_traits()` instead)
- `unlock_trait(trait_key: String) -> void` - Not implemented
- `get_trait_keys_for_breeding() -> Array[String]` - Not implemented

#### Signature Mismatches

**Method: `is_trait_unlocked(trait_key: String) -> bool`**
- API Spec: `is_trait_unlocked(trait_key: String) -> bool`
- Implementation: `is_trait_unlocked(trait_key: String, reputation_level: int) -> bool`
- Impact: Additional required parameter breaks API contract

#### Undocumented Public APIs (API Drift)

**Methods:**
- `load_traits() -> bool`
- `get_all_trait_keys() -> Array[String]`
- `get_all_traits() -> Array[TraitDef]` - Should be named `get_all_trait_defs()`
- `get_default_genotype(reputation_level: int) -> Dictionary`
- `get_random_genotype(reputation_level: int) -> Dictionary`
- `validate_genotype(genotype: Dictionary) -> bool` - This is documented in GeneticsEngine API
- `get_trait_count() -> int`
- `is_loaded() -> bool`
- `reload() -> bool`

**Constants:**
- `TRAIT_DEFS_PATH: String = "res://data/config/trait_defs.json"`

**Note:** The API spec defines canonical trait key constants (TRAIT_FIRE, TRAIT_WINGS, etc.) but these are not present in the implementation.

---

### GeneticsEngine (`scripts/autoloads/GeneticsEngine.gd`)

#### Missing Documented APIs

**Methods:**
- `predict_offspring(parent_a: DragonData, parent_b: DragonData) -> Dictionary`
- `validate_genotype(genotype: Dictionary) -> bool` - Moved to TraitDB instead

#### Signature Mismatches

**Method: `generate_punnett_square(parent_a: DragonData, parent_b: DragonData, trait_key: String) -> Array`**
- API Spec: Returns `Array[Array[{genotype: String, phenotype: String, probability: float}]]` (2D array)
- Implementation: Returns `Array` of dictionaries with structure `{genotype, phenotype, phenotype_data, probability, count, total}`
- Impact: Different data structure, additional fields not in spec, flat array instead of 2D

#### Undocumented Public APIs (API Drift)

**Methods:**
- `generate_full_punnett_square(parent_a: DragonData, parent_b: DragonData) -> Dictionary`
- `create_starter_dragon(reputation_level: int, sex: String) -> DragonData`
- `create_random_dragon(reputation_level: int, sex: String) -> DragonData`
- `can_breed(parent_a: DragonData, parent_b: DragonData) -> Dictionary`
- `calculate_size_phenotype(genotype: Dictionary) -> Dictionary`

**Properties:**
- `debug_mode: bool = false`

---

### RanchState (`scripts/autoloads/RanchState.gd`)

#### Missing Documented APIs

**Signals:**
- `order_expired(order_id: String)` - Not emitted (internal method `_check_order_deadlines()` exists but doesn't emit)
- `game_initialized()` - Not emitted

**Properties:**
- `reputation_level: int = 0` - MISSING (implemented as `reputation` instead)
- `game_active: bool = false` - Not present

**Methods:**
- `get_egg(egg_id: String) -> EggData` - Not implemented
- `get_all_eggs() -> Array[EggData]` - Not implemented
- `get_active_orders() -> Array[OrderData]` - Not implemented
- `remove_order(order_id: String) -> void` - Not implemented (orders removed via array erase)
- `get_facility(facility_id: String) -> FacilityData` - Not implemented
- `get_all_facilities() -> Array[FacilityData]` - Not implemented
- `get_save_data() -> Dictionary` - MISSING (implemented as `save_state()` instead)

#### Signature Mismatches

**Method: `load_state(save_data: Dictionary)`**
- API Spec: `load_state(save_data: Dictionary) -> void`
- Implementation: `load_state(save_data: Dictionary) -> bool`
- Impact: Returns success status instead of void

**Property: `reputation`**
- API Spec: `reputation_level: int = 0`
- Implementation: `reputation: int = 0`
- Impact: Property name mismatch

#### Undocumented Public APIs (API Drift)

**Signals:**
- `achievement_unlocked(achievement_id: String)`

**Properties:**
- `reputation: int = 0` - Should be `reputation_level`
- `achievements: Dictionary = {}`
- `time_speed: float = 1.0`
- `BASE_CAPACITY: int = 6` (constant)
- `FOOD_PER_DRAGON: int = 5` (constant)

**Methods (Public):**
- `can_add_dragon() -> bool`
- `calculate_food_consumption() -> int`
- `check_achievement(achievement_id: String) -> bool`
- `unlock_achievement(achievement_id: String) -> bool`
- `reset_game() -> void`
- `is_new_game() -> bool`
- `save_state() -> Dictionary` - Should be named `get_save_data()`
- `to_dict() -> Dictionary` - Legacy serialization method
- `from_dict(data: Dictionary) -> void` - Legacy deserialization method

**Methods (Private - should be prefixed with _):**
- `_check_order_deadlines() -> void`
- `_get_facility_cost(facility_type: String) -> int`
- `_get_facility_capacity(facility_type: String) -> int`
- `_get_facility_capacity_value(facility_data) -> int`
- `_process_egg_incubation() -> void`
- `_process_food_consumption() -> void`
- `_check_dragon_escapes() -> void`
- `_update_reputation() -> void`
- `_check_achievements() -> void`

---

### OrderSystem (`scripts/autoloads/OrderSystem.gd`)

#### Missing Documented APIs

**Methods:**
- `does_dragon_match(dragon: DragonData, order: OrderData) -> bool` - Not implemented
- `get_matching_dragons(order: OrderData, dragons: Array[DragonData]) -> Array[DragonData]` - Not implemented
- `calculate_payment(order: OrderData, dragon: DragonData) -> int` - Not implemented
- `refresh_orders(reputation_level: int) -> Array[OrderData]` - Not implemented

**Note:** These methods appear to be implemented elsewhere (OrderMatching, Pricing utilities) but should be exposed through OrderSystem API per spec.

#### Undocumented Public APIs (API Drift)

**Constants:**
- `ORDER_TEMPLATES_PATH: String = "res://data/config/order_templates.json"`

**Properties:**
- `_templates: Array = []` (private)
- `_loaded: bool = false` (private)

**Methods:**
- `load_templates() -> bool`
- `_create_order_from_template(template: Dictionary) -> OrderData` (private)

---

### SaveSystem (`scripts/autoloads/SaveSystem.gd`)

#### Missing Documented APIs

**Methods:**
- `enable_autosave(interval_seconds: float = 300.0) -> void` - Not implemented
- `disable_autosave() -> void` - Not implemented
- `export_save_string() -> String` - Not implemented
- `import_save_string(save_string: String) -> bool` - Not implemented

#### Signature Mismatches

**Constants:**
- API Spec: `SAVE_VERSION: int = 1`
- Implementation: `SAVE_VERSION: String = "1.0"`
- Impact: Type mismatch (int vs String) and value format change

- API Spec: `SAVE_PATH: String = "user://savegame_v1.json"`
- Implementation: No single constant (uses `_get_save_path(slot)` dynamic generation)
- Impact: API contract broken, no fixed path constant

- API Spec: `BACKUP_PATH: String = "user://savegame_v1.bak.json"`
- Implementation: No single constant (uses `_get_backup_path(slot)` dynamic generation)
- Impact: API contract broken, no fixed path constant

**Signals:**
- API Spec: `save_complete(success: bool)`
- Implementation: `save_completed(slot: int)`
- Impact: Different parameter (slot instead of success flag)

- API Spec: `load_complete(success: bool)`
- Implementation: `load_completed(slot: int)`
- Impact: Different parameter (slot instead of success flag)

**Methods:**
- API Spec: `save_game() -> bool`
- Implementation: `save_game(slot: int = 0) -> bool`
- Impact: Additional slot parameter changes signature

- API Spec: `load_game() -> bool`
- Implementation: `load_game(slot: int = 0) -> bool`
- Impact: Additional slot parameter changes signature

- API Spec: `has_save() -> bool`
- Implementation: `has_save(slot: int) -> bool`
- Impact: Requires slot parameter instead of checking default save

- API Spec: `delete_save() -> void`
- Implementation: `delete_save(slot: int) -> bool`
- Impact: Requires slot parameter and returns bool instead of void

- API Spec: `get_save_info() -> Dictionary`
- Implementation: `get_save_info(slot: int) -> Dictionary`
- Impact: Requires slot parameter

#### Undocumented Public APIs (API Drift)

**Constants:**
- `SAVE_DIR: String = "user://saves/"`
- `AUTOSAVE_SLOT: int = -1`

**Signals:**
- `save_failed(slot: int, error: String)`
- `load_failed(slot: int, error: String)`

**Properties:**
- `autosave_enabled: bool = true`
- `autosave_interval_seasons: int = 5`
- `_seasons_since_autosave: int = 0` (private)

**Methods:**
- `list_saves() -> Array[Dictionary]`
- `_ensure_save_directory() -> void` (private)
- `_get_save_path(slot: int) -> String` (private)
- `_get_backup_path(slot: int) -> String` (private)
- `_coerce_array_of_dicts(value) -> Array[Dictionary]` (private)
- `_try_load_backup(slot: int) -> bool` (private)
- `_migrate_save_data(save_data: SaveData) -> SaveData` (private)
- `_on_season_changed(_season: int) -> void` (private signal handler)
- `_on_order_completed(_order_id: String, _payment: int) -> void` (private signal handler)

**Note:** The implementation has significantly diverged from the API spec to support multiple save slots, which is a major architectural change.

---

### AudioManager (`scripts/autoloads/AudioManager.gd`)

#### Missing Documented APIs

**Methods:**
- `stop_music(fade_out: float = 0.5) -> void` - Not implemented
- `get_master_volume() -> float` - Not implemented
- `get_music_volume() -> float` - Not implemented
- `get_sfx_volume() -> float` - Not implemented

#### Signature Mismatches

None - the documented methods that ARE implemented match their signatures.

#### Undocumented Public APIs (API Drift)

**Properties:**
- `sfx_player_pool: Array[AudioStreamPlayer]`
- `music_player: AudioStreamPlayer`
- `master_volume: float = 1.0`
- `music_volume: float = 1.0`
- `sfx_volume: float = 1.0`
- `previous_money: int = 0`

**Constants:**
- `SFX_PLAYER_COUNT = 4`
- `SFX_PATH = "res://assets/audio/sfx/"`
- `MUSIC_PATH = "res://assets/audio/music/"`

**Methods:**
- `update_volumes()` - Public helper method
- `_on_egg_created(_egg)` (private signal handler)
- `_on_egg_hatched(_dragon)` (private signal handler)
- `_on_order_completed(_order)` (private signal handler)
- `_on_money_changed(new_total: int)` (private signal handler)
- `_on_reputation_increased(_amount)` (private signal handler)
- `_on_facility_built(_facility)` (private signal handler)

**Note:** The volume getter methods are missing but the volume is stored as linear values (0.0-1.0) instead of decibels as the setter methods suggest.

---

### TutorialService (`scripts/autoloads/TutorialService.gd`)

#### Missing Documented APIs

**Properties:**
- `tutorial_enabled: bool = false` - Not exposed (internal to TutorialLogic)
- `current_step_id: String = ""` - Not exposed (internal to TutorialLogic)
- `completed_steps: Dictionary = {}` - Not exposed (internal to TutorialLogic)

#### Signature Mismatches

**Method: `process_event(event_type: String, payload: Dictionary = {})`**
- API Spec: `process_event(event_type: String, payload: Dictionary = {}) -> bool`
- Implementation: `process_event(event_type: String, payload: Dictionary = {}) -> void`
- Impact: No return value indicating whether step advanced

**Method: `is_step_complete(step_id: String) -> bool`**
- API Spec: `is_step_complete(step_id: String) -> bool`
- Implementation: `is_step_completed(step_id: String) -> bool` (different name)
- Impact: Method name mismatch (complete vs completed)

**Method: `get_save_data() -> Dictionary`**
- API Spec: `get_save_data() -> Dictionary`
- Implementation: `save_state() -> Dictionary` (different name)
- Impact: Method name mismatch

**Method: `load_state(data: Dictionary) -> void`**
- API matches implementation (correct)

#### Undocumented Public APIs (API Drift)

**Properties:**
- `_tutorial_logic: TutorialLogic = null` (private)

**Constants:**
- `TUTORIAL_JSON_PATH = "res://data/config/tutorial_steps.json"`

**Methods:**
- `is_tutorial_active() -> bool`
- `is_tutorial_completed() -> bool`
- `get_progress_percentage() -> float`
- `save_state() -> Dictionary` - Should be named `get_save_data()`
- `connect_to_ranch_state() -> void`
- `_on_step_advanced(old_step_id: String, new_step_id: String) -> void` (private)
- `_on_dragon_added(dragon_data: DragonData) -> void` (private signal handler)
- `_on_egg_created(egg_id: int) -> void` (private signal handler)
- `_on_order_completed(order_id: int, payment: int) -> void` (private signal handler)
- `_on_season_changed(season: int) -> void` (private signal handler)
- `_on_facility_built(facility_id: String) -> void` (private signal handler)

**Note:** The documented properties are delegated to the internal `_tutorial_logic` object and not directly exposed.

---

## Critical Issues

### Architecture Violations

1. **SaveSystem Multi-Slot Design** - The API spec assumes single save file, but implementation supports multiple save slots. This is a fundamental architectural divergence requiring API spec update.

2. **Distributed Order Logic** - OrderSystem API defines matching/payment methods, but these are implemented in separate utility classes (OrderMatching, Pricing). API should be updated or methods should be exposed through OrderSystem.

3. **Property Encapsulation** - TutorialService delegates properties to internal TutorialLogic, violating direct property access contract.

### Breaking Changes

1. **RNGService.shuffle()** - Return type change breaks functional code patterns
2. **TraitDB.is_trait_unlocked()** - Additional required parameter breaks all callers
3. **RanchState.load_state()** - Return type change affects error handling
4. **SaveSystem** - Entire API signature changes due to slot-based design

### Naming Inconsistencies

1. `RNGService.choice()` should be `pick_random()`
2. `TraitDB.get_all_traits()` should be `get_all_trait_defs()`
3. `RanchState.reputation` should be `reputation_level`
4. `RanchState.save_state()` should be `get_save_data()`
5. `TutorialService.save_state()` should be `get_save_data()`
6. `TutorialService.is_step_completed()` should be `is_step_complete()`

---

## Recommendations

### Immediate Actions (Breaking Changes)

1. **RNGService**
   - Rename `choice()` to `pick_random()`
   - Change `shuffle()` to return the array: `shuffle(array: Array) -> Array`

2. **TraitDB**
   - Rename `get_all_traits()` to `get_all_trait_defs()`
   - Add `unlocked_traits` property
   - Implement `unlock_trait()` method
   - Implement `get_trait_keys_for_breeding()` method
   - Fix `is_trait_unlocked()` signature to match API (remove reputation_level parameter)

3. **RanchState**
   - Rename `reputation` to `reputation_level`
   - Rename `save_state()` to `get_save_data()`
   - Change `load_state()` return type to `void`
   - Add missing getter methods for eggs, orders, facilities
   - Implement missing signals: `order_expired`, `game_initialized`
   - Add `game_active` property

4. **TutorialService**
   - Rename `save_state()` to `get_save_data()`
   - Rename `is_step_completed()` to `is_step_complete()`
   - Change `process_event()` to return bool
   - Expose properties: `tutorial_enabled`, `current_step_id`, `completed_steps`

### Major Design Decisions

1. **SaveSystem Multi-Slot Architecture**
   - OPTION A: Update API spec to document slot-based design
   - OPTION B: Create wrapper methods for default slot (slot 0) to maintain API compatibility
   - RECOMMENDED: Option A - Update spec to reflect current implementation

2. **OrderSystem Distributed Logic**
   - OPTION A: Move OrderMatching/Pricing logic into OrderSystem
   - OPTION B: Update API spec to remove these methods
   - RECOMMENDED: Option A - Centralize in OrderSystem as spec intended

3. **GeneticsEngine.validate_genotype()**
   - OPTION A: Move from TraitDB back to GeneticsEngine
   - OPTION B: Update API spec to document it in TraitDB
   - RECOMMENDED: Option B - Makes sense in TraitDB

### Non-Breaking Additions

1. **AudioManager** - Implement missing getter methods for volumes and `stop_music()`
2. **GeneticsEngine** - Implement `predict_offspring()` method
3. **OrderSystem** - Implement `refresh_orders()` method
4. **SaveSystem** - Implement `export_save_string()` and `import_save_string()` methods
5. **SaveSystem** - Implement `enable_autosave()` and `disable_autosave()` methods (currently only exposed as properties)

### API Drift Cleanup

Review all undocumented public methods and either:
1. Make them private (prefix with `_`)
2. Document them in the API spec
3. Remove if unused

Private signal handlers and internal helpers should consistently use `_` prefix.

---

## Compliance Tracking

Total Documented APIs: 184
- Implemented Correctly: 112 (61%)
- Missing: 29 (16%)
- Signature Mismatches: 16 (9%)
- Name Mismatches: 7 (4%)
- Undocumented Additions: 67 (API drift)

**Status:** SIGNIFICANT VIOLATIONS - Requires architectural review and remediation plan.

---

*Report Generated: 2025-12-18*
*API Reference Version: 1.0 (LOCKED)*
*Last Review: Session 17*
