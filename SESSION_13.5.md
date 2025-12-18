## SESSION 14: Save/Load System
**Model:** Claude Sonnet 4.5 (Code)
**Duration:** 4-6 hours
**Extended Thinking:** OFF
**Dependencies:** Sessions 1-13 complete

### Purpose
Implement complete save/load system with localStorage persistence, save file management, and tutorial state preservation.

### Tasks

#### P4-401: SaveData.gd Resource
**Goal:** Define save data structure
- Implement `SaveData.gd` extends Resource
- Properties:
  - `version: String` (save format version)
  - `timestamp: int` (Unix timestamp)
  - `season: int`
  - `money: int`
  - `food: int`
  - `reputation: int`
  - `dragons: Array[Dictionary]` (serialized DragonData)
  - `eggs: Array[Dictionary]` (serialized EggData)
  - `facilities: Array[Dictionary]` (serialized FacilityData)
  - `active_orders: Array[Dictionary]` (serialized OrderData)
  - `completed_orders: Array[Dictionary]`
  - `tutorial_state: Dictionary` (from TutorialService)
  - `rng_state: int` (from RNGService)
  - `unlocked_traits: Array[String]`
- Implement `to_dict()` and `from_dict()` methods

**Files:** `scripts/data/SaveData.gd`

---

#### P4-402: SaveSystem.gd Autoload
**Goal:** Implement save/load manager
- Implement `SaveSystem.gd` autoload
- Methods:
  - `save_game(slot: int = 0) -> bool`
  - `load_game(slot: int = 0) -> bool`
  - `delete_save(slot: int) -> bool`
  - `get_save_info(slot: int) -> Dictionary`
  - `has_save(slot: int) -> bool`
  - `list_saves() -> Array[Dictionary]`
- Use `FileAccess` for save file I/O
- Save to `user://saves/save_<slot>.json`
- Handle errors gracefully (corrupted files, missing files, etc.)
- Emit signals:
  - `save_completed(slot: int)`
  - `load_completed(slot: int)`
  - `save_failed(slot: int, error: String)`

**Files:** `scripts/autoloads/SaveSystem.gd`

---

#### P4-403: RanchState Save/Load Integration
**Goal:** Add save/load methods to RanchState
- Implement `RanchState.save_state() -> Dictionary`
  - Serialize all dragons
  - Serialize all eggs
  - Serialize all facilities
  - Serialize active orders
  - Include season, money, food, reputation
- Implement `RanchState.load_state(data: Dictionary) -> void`
  - Clear existing state
  - Restore all data from dictionary
  - Emit appropriate signals for UI updates
- Implement `RanchState.is_new_game() -> bool`
  - Returns true if no dragons/eggs and season == 1
- Add `RanchState.start_new_game()`
  - Initialize with 2 starter dragons
  - Set starting money/food
  - Generate initial orders
  - Start at season 1

**Files:** `scripts/autoloads/RanchState.gd` (modify existing)

---

#### P4-404: Auto-Save System
**Goal:** Implement automatic saving
- Auto-save triggers:
  - Every 5 seasons
  - After important events (order completed, dragon born, etc.)
  - When closing game (if browser supports)
- Add setting to enable/disable auto-save
- Show "Saving..." notification briefly
- Use dedicated auto-save slot (slot -1)
- Don't block gameplay during save

**Files:** `scripts/autoloads/SaveSystem.gd` (extend)

---

#### P4-405: Load Game Menu
**Goal:** Create load game UI
- Create `LoadGameMenu.tscn` scene
- Show list of save slots with:
  - Save slot number
  - Timestamp (formatted)
  - Season number
  - Money amount
  - Dragon count
  - Preview image (optional - can be added later)
- Buttons:
  - Load - loads selected save
  - Delete - deletes save (with confirmation)
  - Back - returns to main menu
- Show "Empty Slot" for unused slots
- Sort by most recent first

**Files:**
- `scenes/menus/LoadGameMenu.tscn`
- `scripts/menus/LoadGameMenu.gd`

---

#### P4-406: Main Menu Integration
**Goal:** Add main menu with New Game / Load Game
- Create `MainMenu.tscn` scene
- Buttons:
  - New Game - starts new game (warns if auto-save exists)
  - Load Game - opens LoadGameMenu
  - Settings - opens settings panel
  - Quit - closes game (HTML5: returns to title)
- Set as main scene in project settings
- Handle auto-load detection (offer to continue from auto-save)

**Files:**
- `scenes/menus/MainMenu.tscn`
- `scripts/menus/MainMenu.gd`

---

#### P4-407: Save File Migration System
**Goal:** Handle save format version changes
- Add version checking in `SaveSystem.load_game()`
- Implement migration functions:
  - `_migrate_v1_0_to_v1_1(data: Dictionary) -> Dictionary`
  - Add more as needed
- Current version: "1.0"
- If version mismatch, attempt migration
- If migration fails, show error message
- Keep backup of old save before migration

**Files:** `scripts/autoloads/SaveSystem.gd` (extend)

---

#### P4-408: Save/Load Error Handling
**Goal:** Robust error handling
- Handle corrupted JSON gracefully
- Handle missing keys (use defaults)
- Handle invalid data types
- Show user-friendly error messages
- Create error log file: `user://saves/error_log.txt`
- Offer to create backup before overwriting
- Test with:
  - Empty file
  - Invalid JSON
  - Missing fields
  - Wrong data types

**Files:** `scripts/autoloads/SaveSystem.gd` (extend)

---

#### P4-409: Tutorial State Persistence
**Goal:** Save/load tutorial progress
- Add `TutorialService.save_state()` to SaveData
- Add `TutorialService.load_state()` on game load
- Tutorial should resume from last step
- If tutorial completed, don't show again
- Add "Reset Tutorial" option in settings

**Files:**
- `scripts/autoloads/TutorialService.gd` (already has methods, integrate with SaveSystem)
- `scripts/autoloads/SaveSystem.gd`

---

#### P4-410: Testing & Validation
**Goal:** Comprehensive save/load testing
- Test scenarios:
  - Save game with 10 dragons, load successfully
  - Save game with eggs, verify incubation resumes
  - Save mid-tutorial, resume at correct step
  - Auto-save works every 5 seasons
  - Delete save works correctly
  - Load non-existent save shows error
  - Corrupted save doesn't crash game
- Write unit tests for:
  - SaveData serialization
  - RanchState.save_state() / load_state()
  - Migration system

**Files:** `tests/save_system/test_save_load.gd`

---

**Session 14 Acceptance Criteria:**
- [ ] Can save game to file
- [ ] Can load game from file
- [ ] Save includes all dragons, eggs, facilities, orders
- [ ] Tutorial state persists correctly
- [ ] RNG state persists (reproducible outcomes)
- [ ] Auto-save works every 5 seasons
- [ ] Main menu allows New Game / Load Game
- [ ] Load game menu shows save slots with info
- [ ] Corrupted saves don't crash game
- [ ] Version migration system works
- [ ] is_new_game() correctly detects new games
- [ ] Tutorial starts only for new games

---

**Implementation Notes:**
- Use `user://` path for cross-platform compatibility
- JSON format for human-readable saves
- Consider compression for large save files (future)
- Keep auto-save separate from manual saves
- Implement save file backup before overwrite
