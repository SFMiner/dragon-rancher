## SESSION 13: Tutorial System
**Model:** Claude Sonnet 4.5 (Code)  
**Duration:** 6-8 hours  
**Extended Thinking:** OFF  
**Dependencies:** Sessions 1-12 complete

### Purpose
Implement tutorial system with step tracking, UI overlay, and event-driven progression.

### Tasks

#### P3-301: TutorialStep.gd Resource
**Goal:** Define tutorial step data structure
- Implement `TutorialStep.gd` extends Resource
- Properties:
  - `id: String`
  - `title: String`
  - `body: String`
  - `anchor: String` (UI element id to highlight)
  - `highlight_mode: String` ("anchor", "screen_center", "none")
  - `advance_condition: Dictionary` (event type and payload)
  - `on_enter_actions: Array[Dictionary]` (optional)
  - `on_exit_actions: Array[Dictionary]` (optional)

**Files:** `scripts/data/TutorialStep.gd`

---

#### P3-302: Tutorial Steps Definition
**Goal:** Define 10-12 tutorial steps (defer copy to ChatGPT)
- Create `data/config/tutorial_steps.json` structure
- Define step IDs:
  - `tut_01_welcome`
  - `tut_02_view_dragons`
  - `tut_03_open_breeding`
  - `tut_04_select_parents`
  - `tut_05_breed`
  - `tut_06_advance_season`
  - `tut_07_egg_hatches`
  - `tut_08_view_orders`
  - `tut_09_fulfill_order`
  - `tut_10_build_facility`
  - `tut_11_complete`
- Define advance conditions for each
- Placeholder body text (to be filled by ChatGPT)

**Files:** `data/config/tutorial_steps.json`

---

#### P3-303: TutorialLogic.gd Module
**Goal:** Implement tutorial state machine
- Implement `TutorialLogic.gd` module (not autoload)
- Load tutorial steps from JSON
- Properties:
  - `tutorial_enabled: bool`
  - `current_step_id: String`
  - `completed_steps: Dictionary[String, bool]`
- Implement `process_event(event_type: String, payload: Dictionary) -> bool`:
  - Check if current step's advance_condition matches event
  - If yes, advance to next step
  - Return true if advanced
- Implement `get_current_step() -> TutorialStep`
- Implement `skip_tutorial()`
- Implement serialization for save/load

**Files:** `scripts/rules/TutorialLogic.gd`

---

#### P3-304: TutorialService.gd Autoload
**Goal:** Integrate tutorial with game state
- Implement `TutorialService.gd` autoload
- Uses TutorialLogic internally
- Emit signals:
  - `step_changed(step: TutorialStep)`
  - `tutorial_completed()`
- Implement `start_tutorial()`
- Implement `process_event(event_type: String, payload: Dictionary)`:
  - Forward to TutorialLogic
  - Emit step_changed if advanced
- Connect to RanchState signals to detect events:
  - `dragon_added` → event "dragon_spawned"
  - `egg_created` → event "egg_created"
  - `order_completed` → event "order_completed"
  - etc.
- Save/load tutorial state through SaveSystem

**Files:** `scripts/autoloads/TutorialService.gd`

---

#### P3-305: TutorialOverlay.tscn Scene
**Goal:** Create tutorial UI overlay
- Create `TutorialOverlay.tscn` (CanvasLayer, top layer)
- Add child nodes:
  - ColorRect (semi-transparent black backdrop)
  - PanelContainer (tutorial step card)
    - VBoxContainer
      - Label (step title)
      - Label (step body)
      - Button (Next - enabled when advance condition met)
      - Button (Skip Tutorial)
  - Control (highlight overlay - draws rect around anchored element)

**Files:** `scenes/ranch/ui/TutorialOverlay.tscn`

---

#### P3-306: TutorialOverlay.gd Controller
**Goal:** Display tutorial steps and highlight UI
- Implement `TutorialOverlay.gd` attached to TutorialOverlay.tscn
- Connect to TutorialService.step_changed signal
- Implement `_on_step_changed(step: TutorialStep)`:
  - Update title and body labels
  - Position card based on anchor
  - Highlight anchored UI element (if any)
  - Enable/disable Next button based on advance condition
- Implement `_highlight_element(anchor_id: String)`:
  - Find UI node by anchor_id (using registry or NodePath)
  - Draw highlight rect around it
  - Optionally dim rest of screen
- Implement `_on_next_pressed()`:
  - Emit event to TutorialService (user clicked Next)
- Implement `_on_skip_pressed()`:
  - Call TutorialService.skip_tutorial()
  - Hide overlay

**Files:** `scripts/ranch/ui/TutorialOverlay.gd`

---

#### P3-307: UI Anchor Registration
**Goal:** Allow UI elements to be highlighted
- Add anchor IDs to key UI elements:
  - OrdersPanel button: `"orders_button"`
  - BreedingPanel button: `"breeding_button"`
  - BuildPanel button: `"build_button"`
  - DragonDetailsPanel: `"dragon_details"`
- Create registry in TutorialOverlay or use NodePath
- Enable TutorialOverlay to query anchor positions

**Files:** (modify existing UI scripts)

---

#### P3-308: Tutorial Event Emission
**Goal:** Emit tutorial events from UI interactions
- Modify UI controllers to emit events:
  - DragonDetailsPanel opened → `TutorialService.process_event("panel_opened", {"panel": "dragon_details"})`
  - BreedingPanel opened → `TutorialService.process_event("panel_opened", {"panel": "breeding"})`
  - Dragon selected for breeding → `TutorialService.process_event("dragon_selected", {})`
  - Egg created → already handled by RanchState signal
  - Order completed → already handled by RanchState signal

**Files:** (modify existing UI scripts)

---

#### P3-309: Tutorial Guardrails (Optional)
**Goal:** Prevent off-script actions during tutorial
- Disable irrelevant buttons while tutorial active:
  - Settings, Menu, etc.
- Show "Complete tutorial first" message if clicked
- Keep minimal to avoid frustration

**Files:** (modify Ranch.gd or HUD.gd)

---

**Session 13 Acceptance Criteria:**
- [ ] Tutorial starts on new game
- [ ] Steps advance based on player actions
- [ ] UI elements highlight correctly
- [ ] "Next" button enabled only when condition met
- [ ] Tutorial can be skipped
- [ ] Tutorial state persists through save/load
- [ ] Tutorial doesn't break normal gameplay if disabled

---
