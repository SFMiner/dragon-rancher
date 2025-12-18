# Dragon Ranch - API Reference
## Version 1.0 - LOCKED INTERFACES

> **CRITICAL:** These interfaces are LOCKED. Any changes require architectural review and updates to all dependent systems.

---

## Table of Contents

1. [Autoload Singletons](#autoload-singletons)
2. [RanchState](#ranchstate)
3. [GeneticsEngine](#geneticsengine)
4. [TraitDB](#traitdb)
5. [OrderSystem](#ordersystem)
6. [SaveSystem](#savesystem)
7. [RNGService](#rngservice)
8. [AudioManager](#audiomanager)
9. [TutorialService](#tutorialservice)
10. [Cross-Autoload Dependencies](#cross-autoload-dependencies)

---

## Autoload Singletons

Register these in `Project > Project Settings > Autoload` in this order:

| Name | Path | Description |
|------|------|-------------|
| RNGService | `res://scripts/autoloads/rng_service.gd` | Deterministic randomness |
| TraitDB | `res://scripts/autoloads/trait_db.gd` | Trait definitions |
| GeneticsEngine | `res://scripts/autoloads/genetics_engine.gd` | Breeding logic |
| RanchState | `res://scripts/autoloads/ranch_state.gd` | Central game state |
| OrderSystem | `res://scripts/autoloads/order_system.gd` | Order generation |
| SaveSystem | `res://scripts/autoloads/save_system.gd` | Persistence |
| AudioManager | `res://scripts/autoloads/audio_manager.gd` | Sound management |
| TutorialService | `res://scripts/autoloads/tutorial_service.gd` | Onboarding |

---

## RanchState

**Purpose:** Central authoritative game state manager. All game state flows through this singleton.

### Signals

```gdscript
signal season_changed(new_season: int)
signal dragon_added(dragon_id: String)
signal dragon_removed(dragon_id: String)
signal egg_created(egg_id: String)
signal egg_hatched(egg_id: String, dragon_id: String)
signal order_accepted(order_id: String)
signal order_completed(order_id: String, payment: int)
signal order_expired(order_id: String)
signal reputation_increased(new_level: int)
signal facility_built(facility_id: String)
signal money_changed(new_amount: int)
signal food_changed(new_amount: int)
signal game_initialized()
```

### Properties (Read-Only from External Code)

```gdscript
var current_season: int = 1
var money: int = 500
var reputation_level: int = 0
var lifetime_earnings: int = 0
var food_supply: int = 100
var dragons: Dictionary = {}       # String -> DragonData
var eggs: Dictionary = {}          # String -> EggData
var facilities: Dictionary = {}    # String -> FacilityData
var active_orders: Array[OrderData] = []
var game_active: bool = false
```

### Public Methods

#### Game Flow

```gdscript
func start_new_game() -> void
	## Initialize fresh game state with starter dragons.
	## Emits: game_initialized, dragon_added (x2)

func advance_season() -> void
	## Progress to next season. Ages dragons, hatches eggs, consumes food.
	## Emits: season_changed, egg_hatched (if any), dragon_removed (if deaths)

func can_advance_season() -> bool
	## Returns true if no blocking conditions (tutorial, animations, etc.)
```

#### Dragon Management

```gdscript
func add_dragon(data: DragonData) -> String
	## Add dragon to ecosystem. Generates ID if not set.
	## Returns: dragon_id
	## Emits: dragon_added

func remove_dragon(dragon_id: String) -> void
	## Remove dragon from ecosystem.
	## Emits: dragon_removed

func get_dragon(dragon_id: String) -> DragonData
	## Get dragon by ID. Returns null if not found.

func get_all_dragons() -> Array[DragonData]
	## Get all dragons in ecosystem.

func get_adult_dragons() -> Array[DragonData]
	## Get dragons that can breed (adult life stage).
```

#### Egg Management

```gdscript
func create_egg(parent_a_id: String, parent_b_id: String) -> String
	## Breed two dragons to create an egg.
	## Returns: egg_id
	## Emits: egg_created

func hatch_egg(egg_id: String) -> String
	## Hatch an egg into a dragon.
	## Returns: dragon_id
	## Emits: egg_hatched, dragon_added

func get_egg(egg_id: String) -> EggData
	## Get egg by ID. Returns null if not found.

func get_all_eggs() -> Array[EggData]
	## Get all eggs in ecosystem.
```

#### Resources

```gdscript
func add_money(amount: int) -> void
	## Add money. Updates lifetime_earnings and checks reputation.
	## Emits: money_changed, reputation_increased (if threshold crossed)

func spend_money(amount: int) -> bool
	## Attempt to spend money. Returns false if insufficient funds.
	## Emits: money_changed (if successful)

func add_food(amount: int) -> void
	## Add food to supply.
	## Emits: food_changed

func consume_food(amount: int) -> bool
	## Consume food. Returns false if insufficient.
	## Emits: food_changed
```

#### Orders

```gdscript
func accept_order(order: OrderData) -> void
	## Add order to active orders.
	## Emits: order_accepted

func fulfill_order(order_id: String, dragon_id: String) -> bool
	## Attempt to fulfill order with dragon. Returns false if mismatch.
	## Emits: order_completed, dragon_removed, money_changed

func get_active_orders() -> Array[OrderData]
	## Get all active orders.

func remove_order(order_id: String) -> void
	## Remove order (expired or fulfilled).
```

#### Facilities

```gdscript
func build_facility(facility_type: String) -> bool
	## Build a facility. Returns false if can't afford or reputation too low.
	## Emits: facility_built, money_changed

func get_facility(facility_id: String) -> FacilityData
	## Get facility by ID.

func get_all_facilities() -> Array[FacilityData]
	## Get all built facilities.

func get_total_capacity() -> int
	## Get total dragon capacity from all facilities.

func get_facility_bonus(bonus_type: String) -> float
	## Get sum of bonuses of a type (e.g., "happiness", "growth_speed").
```

#### State Loading (Used by SaveSystem)

```gdscript
func load_state(save_data: Dictionary) -> void
	## Load complete game state from save data.
	## Does NOT emit signals during load (prevents side effects).

func get_save_data() -> Dictionary
	## Export current state for saving.
```

---

## GeneticsEngine

**Purpose:** Pure genetics logic. Deterministic breeding and phenotype calculation.

### Public Methods

```gdscript
func breed_dragons(parent_a: DragonData, parent_b: DragonData) -> Dictionary
	## Breed two dragons and return offspring genotype.
	## Returns: Dictionary[trait_key: String, Array[allele1, allele2]]
	## Uses RNGService for allele selection.

func calculate_phenotype(genotype: Dictionary) -> Dictionary
	## Convert genotype to phenotype.
	## Returns: Dictionary[trait_key: String, phenotype_data: Dictionary]
	## phenotype_data contains: name, sprite_suffix, color, etc.

func generate_punnett_square(parent_a: DragonData, parent_b: DragonData, trait_key: String) -> Array
	## Generate 2D Punnett square for a single trait.
	## Returns: Array[Array[{genotype: String, phenotype: String, probability: float}]]

func predict_offspring(parent_a: DragonData, parent_b: DragonData) -> Dictionary
	## Predict offspring trait distributions.
	## Returns: Dictionary[trait_key: String, Array[{phenotype: String, probability: float}]]

func validate_genotype(genotype: Dictionary) -> bool
	## Check if genotype is valid (all traits present, valid alleles).
```

---

## TraitDB

**Purpose:** Trait definitions database. Loads from config, tracks unlocks.

### Properties

```gdscript
var unlocked_traits: Array[String] = []
```

### Public Methods

```gdscript
func get_trait_def(trait_key: String) -> TraitDef
	## Get trait definition by key. Returns null if not found.

func get_all_trait_defs() -> Array[TraitDef]
	## Get all trait definitions.

func get_unlocked_traits(reputation_level: int) -> Array[String]
	## Get trait keys unlocked at or below reputation level.

func unlock_trait(trait_key: String) -> void
	## Unlock a trait (for progression).

func is_trait_unlocked(trait_key: String) -> bool
	## Check if trait is unlocked.

func get_trait_keys_for_breeding() -> Array[String]
	## Get currently unlocked trait keys for breeding.
```

### Canonical Trait Keys

```gdscript
# MVP Traits (Reputation 0)
const TRAIT_FIRE: String = "fire"
const TRAIT_WINGS: String = "wings"
const TRAIT_ARMOR: String = "armor"

# Progression Traits
const TRAIT_COLOR: String = "color"           # Reputation 1
const TRAIT_SIZE_S: String = "size_s"         # Reputation 2 (locus 1)
const TRAIT_SIZE_G: String = "size_g"         # Reputation 2 (locus 2)
const TRAIT_METABOLISM: String = "metabolism" # Reputation 3
const TRAIT_DOCILITY: String = "docility"     # Reputation 4
```

---

## OrderSystem

**Purpose:** Order generation and requirement matching.

### Signals

```gdscript
signal orders_generated(orders: Array[OrderData])
```

### Public Methods

```gdscript
func generate_orders(reputation_level: int) -> Array[OrderData]
	## Generate 3-5 orders appropriate for reputation level.
	## Emits: orders_generated

func does_dragon_match(dragon: DragonData, order: OrderData) -> bool
	## Check if dragon fulfills order requirements.

func get_matching_dragons(order: OrderData, dragons: Array[DragonData]) -> Array[DragonData]
	## Get all dragons that match an order.

func calculate_payment(order: OrderData, dragon: DragonData) -> int
	## Calculate final payment with multipliers.

func refresh_orders(reputation_level: int) -> Array[OrderData]
	## Generate new orders (costs money).
	## Emits: orders_generated
```

---

## SaveSystem

**Purpose:** Persistence to user:// (IndexedDB on web).

### Signals

```gdscript
signal save_complete(success: bool)
signal load_complete(success: bool)
```

### Constants

```gdscript
const SAVE_VERSION: int = 1
const SAVE_PATH: String = "user://savegame_v1.json"
const BACKUP_PATH: String = "user://savegame_v1.bak.json"
```

### Public Methods

```gdscript
func save_game() -> bool
	## Save current game state. Creates backup first.
	## Emits: save_complete

func load_game() -> bool
	## Load saved game state into RanchState.
	## Emits: load_complete

func has_save() -> bool
	## Check if save file exists.

func delete_save() -> void
	## Delete save file and backup.

func get_save_info() -> Dictionary
	## Get save metadata without loading full state.
	## Returns: {season: int, money: int, dragons: int, timestamp: int}

func enable_autosave(interval_seconds: float = 300.0) -> void
	## Enable periodic autosave.

func disable_autosave() -> void
	## Disable periodic autosave.

func export_save_string() -> String
	## Export save as base64 string (for manual backup).

func import_save_string(save_string: String) -> bool
	## Import save from base64 string.
```

---

## RNGService

**Purpose:** Centralized deterministic randomness for testability.

### Public Methods

```gdscript
func set_seed(seed: int) -> void
	## Set RNG seed. Use for deterministic testing.

func get_seed() -> int
	## Get current seed.

func randf() -> float
	## Random float 0.0 to 1.0.

func randi_range(from: int, to: int) -> int
	## Random integer in range [from, to] inclusive.

func randf_range(from: float, to: float) -> float
	## Random float in range [from, to].

func shuffle(array: Array) -> Array
	## Shuffle array in place and return it.

func pick_random(array: Array) -> Variant
	## Pick random element from array. Returns null if empty.
```

---

## AudioManager

**Purpose:** Centralized audio playback.

### Public Methods

```gdscript
func play_sfx(sfx_name: String) -> void
	## Play sound effect from assets/audio/sfx/{sfx_name}.ogg

func play_music(track_name: String, loop: bool = true) -> void
	## Play music track from assets/audio/music/{track_name}.ogg

func stop_music(fade_out: float = 0.5) -> void
	## Stop current music with fade out.

func set_master_volume(db: float) -> void
	## Set master volume in decibels.

func set_music_volume(db: float) -> void
	## Set music volume in decibels.

func set_sfx_volume(db: float) -> void
	## Set SFX volume in decibels.

func get_master_volume() -> float
func get_music_volume() -> float
func get_sfx_volume() -> float
```

---

## TutorialService

**Purpose:** Tutorial state machine and UI coordination.

### Signals

```gdscript
signal step_changed(step: TutorialStep)
signal tutorial_completed()
signal tutorial_skipped()
```

### Properties

```gdscript
var tutorial_enabled: bool = false
var current_step_id: String = ""
var completed_steps: Dictionary = {}  # String -> bool
```

### Public Methods

```gdscript
func start_tutorial() -> void
	## Begin tutorial from first step.
	## Emits: step_changed

func process_event(event_type: String, payload: Dictionary = {}) -> bool
	## Process game event for tutorial advancement.
	## Returns: true if step advanced
	## Emits: step_changed (if advanced)

func skip_tutorial() -> void
	## Skip remaining tutorial.
	## Emits: tutorial_skipped

func get_current_step() -> TutorialStep
	## Get current tutorial step data.

func is_step_complete(step_id: String) -> bool
	## Check if specific step has been completed.

func reset_tutorial() -> void
	## Reset tutorial to beginning (for testing).

func get_save_data() -> Dictionary
	## Get tutorial state for saving.

func load_state(data: Dictionary) -> void
	## Load tutorial state from save.
```

---

## Cross-Autoload Dependencies

```
RNGService          <- (no dependencies)
     ^
     |
TraitDB             <- (no dependencies, loads from config)
     ^
     |
GeneticsEngine      <- RNGService, TraitDB
     ^
     |
RanchState          <- GeneticsEngine, TraitDB
     ^
     |
OrderSystem         <- TraitDB, GeneticsEngine (for matching)
     ^
     |
SaveSystem          <- RanchState (reads/writes state)
     |
AudioManager        <- RanchState (subscribes to signals)
     |
TutorialService     <- RanchState (subscribes to signals)
```

### Initialization Order

1. RNGService - No dependencies
2. TraitDB - Loads config files
3. GeneticsEngine - Needs TraitDB
4. RanchState - Needs GeneticsEngine
5. OrderSystem - Needs TraitDB
6. SaveSystem - Needs RanchState
7. AudioManager - Subscribes to RanchState signals
8. TutorialService - Subscribes to RanchState signals

---

## Data Resources

All data resources extend `Resource` and provide:

```gdscript
func to_dict() -> Dictionary
	## Serialize to JSON-compatible dictionary.

func from_dict(data: Dictionary) -> void
	## Deserialize from dictionary.

func is_valid() -> bool
	## Validate all required fields are present and correct.
```

See `scripts/data/` for implementations:
- `DragonData.gd`
- `EggData.gd`
- `OrderData.gd`
- `FacilityData.gd`
- `TraitDef.gd`
- `TutorialStep.gd`

---

## Error Handling Policy

1. **Null Checks:** All getters return `null` for not-found items
2. **Validation:** Use `is_valid()` before processing data
3. **Signals:** Always emit signals after state changes
4. **Logging:** Use `push_warning()` for recoverable issues, `push_error()` for critical failures
5. **Fail Safe:** Methods return `false` or `null` rather than crashing

---

*Document Version: 1.0*
*Status: LOCKED*
*Last Updated: Session 1*
