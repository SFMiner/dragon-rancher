## SESSION 5: Save System
**Model:** Claude Sonnet 4.5 (Code)  
**Duration:** 4-6 hours  
**Extended Thinking:** OFF  
**Dependencies:** Session 4 complete

### Purpose
Implement robust save/load with versioning and validation for browser (IndexedDB via FileAccess) and desktop.

### Tasks

#### P3-001: SaveSystem Skeleton
**Goal:** Create SaveSystem autoload
- Implement `SaveSystem.gd` autoload
- Define constants:
  - `SAVE_VERSION: int = 1`
  - `SAVE_PATH: String = "user://savegame_v1.json"`
  - `BACKUP_PATH: String = "user://savegame_v1.bak.json"`
- Define signals:
  - `save_complete(success: bool)`
  - `load_complete(success: bool)`
- Stub methods

**Files:** `scripts/autoloads/SaveSystem.gd`

---

#### P3-002: Serialization - Dragons & Eggs
**Goal:** Serialize dragon and egg data
- Implement `_serialize_dragon(dragon: DragonData) -> Dictionary`:
  - Convert all properties to JSON-compatible types
  - Genotype arrays → nested arrays
  - Validate before returning
- Implement `_deserialize_dragon(data: Dictionary) -> DragonData`:
  - Create DragonData
  - Call from_dict()
  - Validate
- Implement `_serialize_egg(egg: EggData) -> Dictionary`
- Implement `_deserialize_egg(data: Dictionary) -> EggData`

**Files:** `scripts/autoloads/SaveSystem.gd`

---

#### P3-003: Save Game Implementation
**Goal:** Implement save to disk
- Implement `save_game() -> bool`:
  - Gather all state from RanchState:
	- save_version
	- current_season, money, reputation, food_supply
	- dragons (serialized)
	- eggs (serialized)
	- facilities (serialized)
	- active_orders (serialized)
	- tutorial_state (if exists)
	- settings (volume, speed)
  - Convert to JSON string
  - If SAVE_PATH exists, copy to BACKUP_PATH
  - Write to SAVE_PATH using FileAccess
  - Verify write succeeded
  - Emit save_complete
  - Return success
- Handle errors:
  - Disk full
  - Permission denied
  - Corrupted data

**Files:** `scripts/autoloads/SaveSystem.gd`

---

#### P3-004: Load Game Implementation
**Goal:** Implement load from disk
- Implement `load_game() -> bool`:
  - Check if SAVE_PATH exists
  - Read JSON string using FileAccess
  - Parse JSON
  - Validate save_version
  - If version mismatch, attempt migration (see P3-005)
  - Deserialize all data
  - Call RanchState loading methods (see P3-006)
  - Emit load_complete
  - Return success
- Handle errors:
  - Missing file (return false, don't error)
  - Corrupted JSON (try backup)
  - Invalid data (try backup)
  - Migration failure (try backup)

**Files:** `scripts/autoloads/SaveSystem.gd`

---

#### P3-005: Save Migration System
**Goal:** Handle save version updates
- Implement `_migrate_save(data: Dictionary, from_version: int, to_version: int) -> Dictionary`:
  - For now, just validate basic structure
  - Plan for future: add migration paths
  - Log migration attempts
- Define validation rules:
  - Required keys present
  - Data types correct
  - No null dragons/eggs
  - Genotypes valid

**Files:** `scripts/autoloads/SaveSystem.gd`

---

#### P3-006: RanchState Loading Integration
**Goal:** Add load methods to RanchState
- Implement `load_state(save_data: Dictionary) -> void` in RanchState:
  - Clear existing state
  - Load current_season, money, etc.
  - Recreate dragons from serialized data
  - Recreate eggs
  - Recreate facilities
  - Recreate orders
  - Emit relevant signals (without triggering side effects)
- Implement quiet mode for loading (don't play sounds, etc.)

**Files:** `scripts/autoloads/RanchState.gd` (add method)

---

#### P3-007: Autosave System
**Goal:** Implement periodic autosave
- Implement `enable_autosave(interval_seconds: float = 300.0)`:
  - Create Timer node
  - Connect to save_game()
- Implement `disable_autosave()`
- Trigger autosave:
  - At start of each new season
  - On facility purchase
  - On order completion
- Never autosave during animations or tutorial steps

**Files:** `scripts/autoloads/SaveSystem.gd`

---

#### P3-008: Save System Tests
**Goal:** Test serialization and migration
- Create `tests/save/test_serialization.gd`:
  - Test dragon round-trip
  - Test egg round-trip
  - Test full save round-trip
- Create `tests/save/test_migration.gd`:
  - Test version detection
  - Test validation
- Create `tests/save/test_backup.gd`:
  - Test backup creation
  - Test backup restoration

**Files:**
- `tests/save/test_serialization.gd`
- `tests/save/test_migration.gd`
- `tests/save/test_backup.gd`

---

**Session 5 Acceptance Criteria:**
- [ ] Can save game and reload with identical state
- [ ] Backup created before overwriting save
- [ ] Corrupted save falls back to backup
- [ ] Autosave doesn't interrupt gameplay
- [ ] Save works in browser (IndexedDB) and desktop
- [ ] Save file is human-readable JSON
