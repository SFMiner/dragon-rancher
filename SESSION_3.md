## SESSION 3: Dragon Entities & Lifecycle
**Model:** Claude Sonnet 4.5 (Code)  
**Duration:** 6-8 hours  
**Extended Thinking:** OFF  
**Dependencies:** Session 2 complete

### Purpose
Implement dragon and egg entities with aging, lifecycle stages, and visual representation.

### Tasks

#### P1-101: DragonData Resource Implementation
**Goal:** Implement typed Resource for dragon data
- Implement `DragonData.gd` extends Resource
- Add all @export properties from schema (P0-002)
- Implement `to_dict() -> Dictionary` for serialization
- Implement `from_dict(data: Dictionary) -> void` for loading
- Add validation methods:
  - `is_valid() -> bool`
  - `can_breed() -> bool` (adult stage, not elder)
  - `get_age_category() -> String` (egg, hatchling, juvenile, adult, elder)

**Files:** `scripts/data/DragonData.gd`

---

#### P1-102: EggData Resource Implementation
**Goal:** Implement typed Resource for egg data
- Implement `EggData.gd` extends Resource
- Add all @export properties from schema
- Implement serialization methods
- Add `is_ready_to_hatch() -> bool`

**Files:** `scripts/data/EggData.gd`

---

#### P1-103: Dragon.tscn Scene Setup
**Goal:** Create dragon scene with animations
- Create `Dragon.tscn` (CharacterBody2D or Node2D)
- Add child nodes:
  - Sprite2D (for visual)
  - AnimationPlayer (for idle/walk)
  - Label (for debug name display)
  - Area2D with CollisionShape2D (for click detection)
- Create placeholder sprite texture (colored square)
- Create idle animation (bob up/down)

**Files:** `scenes/entities/dragon/Dragon.tscn`

---

#### P1-104: Dragon.gd Controller
**Goal:** Implement dragon behavior and rendering
- Implement `Dragon.gd` attached to Dragon.tscn
- Properties:
  - `dragon_data: DragonData`
  - `target_position: Vector2` (for wandering)
  - `wander_speed: float`
- Methods:
  - `setup(data: DragonData)` - initialize from data
  - `update_visuals()` - set sprite based on phenotype
  - `_process(delta)` - simple wander behavior
- Visual rendering:
  - Use phenotype sprite_suffix to load sprite (e.g., "dragon_fire_vestigial_heavy.png")
  - Fallback to colored square if sprite missing
  - Scale sprite based on life_stage (hatchling small, adult full size)
- Click detection:
  - Emit `dragon_clicked` signal when clicked

**Files:** `scripts/entities/Dragon.gd`

---

#### P1-105: Egg.tscn Scene Setup
**Goal:** Create egg scene
- Create `Egg.tscn` (Node2D)
- Add Sprite2D (egg visual)
- Add ProgressBar (incubation timer)
- Add AnimationPlayer (crack animation for hatching)

**Files:** `scenes/entities/egg/Egg.tscn`

---

#### P1-106: Egg.gd Controller
**Goal:** Implement egg behavior
- Implement `Egg.gd` attached to Egg.tscn
- Properties:
  - `egg_data: EggData`
- Methods:
  - `setup(data: EggData)`
  - `update_timer_display()`
  - `play_hatch_animation()`
- Connect to RanchState.season_changed to decrement timer

**Files:** `scripts/entities/Egg.gd`

---

#### P1-107: Lifecycle.gd Rules Module
**Goal:** Implement aging and stage transitions
- Implement `Lifecycle.gd` module (pure logic, no scene refs)
- Define stage thresholds:
  - Hatchling: 0-1 seasons
  - Juvenile: 2-3 seasons
  - Adult: 4-18 seasons
  - Elder: 19+ seasons
- Implement `get_life_stage(age: int) -> String`
- Implement `can_breed(dragon: DragonData) -> bool` (adult stage only)
- Implement `advance_age(dragon: DragonData) -> void` (mutates age)
- Implement `calculate_lifespan(dragon: DragonData) -> int`:
  - Base: 23 seasons
  - Modified by metabolism trait (if present)

**Files:** `scripts/rules/Lifecycle.gd`

---

#### P1-108: Dragon Name Generator Integration
**Goal:** Generate and assign dragon names
- Create `data/config/names_dragons.json` with 100+ names
- Implement `IdGen.gd` utility:
  - `generate_dragon_id() -> String` (unique ID)
  - `generate_random_name() -> String` (from name list)
- Load names at startup

**Files:**
- `data/config/names_dragons.json` (defer content to ChatGPT session)
- `scripts/util/IdGen.gd`

---

**Session 3 Acceptance Criteria:**
- [ ] DragonData serialization round-trips correctly
- [ ] Dragon.tscn displays in editor with placeholder sprite
- [ ] Dragons wander around screen in test scene
- [ ] Egg countdown decrements each season
- [ ] Lifecycle stages calculate correctly
- [ ] Names are unique and random

---
