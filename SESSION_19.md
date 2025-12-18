## SESSION 19: Main Menu & Game Flow
**Model:** Gemini Flash 3  
**Duration:** 3-4 hours  
**Extended Thinking:** N/A  
**Dependencies:** Sessions 1-18 complete

### Purpose
Create main menu, settings, scene transitions, and game flow.

### Tasks

#### P-MENU-001: MainMenu.tscn Scene Setup
**Goal:** Create main menu scene
- Create `MainMenu.tscn` (Control)
- Add child nodes:
  - Background (simple or animated)
  - VBoxContainer (centered)
	- Label (title: "Dragon Ranch")
	- Button (New Game)
	- Button (Continue - disabled if no save)
	- Button (Settings)
	- Button (Credits)
	- Button (Quit - desktop only)

**Files:** `scenes/main_menu/MainMenu.tscn`

---

#### P-MENU-002: MainMenu.gd Controller
**Goal:** Handle menu navigation
- Implement `MainMenu.gd` attached to MainMenu.tscn
- Implement `_ready()`:
  - Check if save exists
  - Enable/disable Continue button
- Implement `_on_new_game_pressed()`:
  - Confirm if save exists ("This will overwrite your save!")
  - Call RanchState.start_new_game()
  - Change scene to Ranch.tscn
- Implement `_on_continue_pressed()`:
  - Call SaveSystem.load_game()
  - Change scene to Ranch.tscn
- Implement `_on_settings_pressed()`:
  - Open SettingsPanel
- Implement `_on_quit_pressed()`:
  - Quit game

**Files:** `scripts/main_menu/MainMenu.gd`

---

#### P-MENU-003: Scene Transitions
**Goal:** Add smooth scene transitions
- Create `SceneTransition.tscn` (CanvasLayer with ColorRect)
- Implement fade in/out
- Use AnimationPlayer or Tween
- Add to autoload or use scene manager

**Files:**
- `scenes/ui/SceneTransition.tscn`
- `scripts/util/SceneManager.gd` (autoload)

---

#### P-MENU-004: Pause Menu
**Goal:** Add pause menu to Ranch scene
- Add pause panel to Ranch.tscn:
  - Resume
  - Settings
  - Save and Quit
- Implement pause functionality (tree.paused = true)
- Connect to Menu button in HUD

**Files:** (modify Ranch.tscn and Ranch.gd)

---

**Session 19 Acceptance Criteria:**
- [ ] Main menu displays and buttons work
- [ ] New Game starts tutorial
- [ ] Continue loads save and resumes
- [ ] Scene transitions are smooth
- [ ] Pause menu works without breaking game state
