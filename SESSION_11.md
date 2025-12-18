## SESSION 11: Ranch World Scene
**Model:** Claude Sonnet 4.5 (Code)  
**Duration:** 4-6 hours  
**Extended Thinking:** OFF  
**Dependencies:** Sessions 1-10 complete

### Purpose
Create the main ranch scene with camera, background, dragon spawning, and visual layout.

### Tasks

#### P1-301: Ranch.tscn Scene Setup
**Goal:** Create main ranch scene
- Create `Ranch.tscn` (Node2D)
- Add child nodes:
  - Background (ParallaxBackground or Sprite2D)
  - DragonsLayer (Node2D - for spawning dragons)
  - EggsLayer (Node2D - for spawning eggs)
  - FacilitiesLayer (Node2D - for spawning facilities)
  - Camera2D (for scrolling)
  - UILayer (CanvasLayer - add HUD, panels)

**Files:** `scenes/ranch/Ranch.tscn`

---

#### P1-302: Ranch.gd Controller
**Goal:** Manage ranch world state
- Implement `Ranch.gd` attached to Ranch.tscn
- Implement `_ready()`:
  - Connect to RanchState signals
  - Spawn existing dragons/eggs/facilities
- Implement `_on_dragon_added(dragon_id: String)`:
  - Instantiate Dragon.tscn
  - Call dragon.setup(dragon_data)
  - Add to DragonsLayer at random position
- Implement `_on_dragon_removed(dragon_id: String)`:
  - Find dragon node
  - Play exit animation
  - Remove from scene
- Implement `_on_egg_created(egg_id: String)`:
  - Instantiate Egg.tscn
  - Add to EggsLayer
- Implement `_on_egg_hatched(egg_id, dragon_id)`:
  - Remove egg node
  - Trigger dragon spawn

**Files:** `scripts/ranch/Ranch.gd`

---

#### P1-303: RanchCamera.gd
**Goal:** Implement camera controls
- Implement `RanchCamera.gd` attached to Camera2D
- Add drag-to-pan:
  - Detect mouse drag
  - Move camera position
- Add zoom controls:
  - Mouse wheel or pinch gesture
  - Limit zoom levels (0.5x - 2.0x)
- Add bounds:
  - Keep camera within ranch area

**Files:** `scripts/ranch/RanchCamera.gd`

---

#### P1-304: Dragon Spawning & Positioning
**Goal:** Spawn dragons at valid positions
- Implement `get_spawn_position() -> Vector2` in Ranch.gd:
  - Check facility positions
  - Prefer spawning near Stables/Pastures
  - Avoid overlapping dragons
  - Fallback to random position within bounds
- Implement dragon wandering (if not done in Dragon.gd):
  - Simple random walk
  - Stay within bounds

**Files:** `scripts/ranch/Ranch.gd` (add method)

---

#### P1-305: Facility Visual Placement
**Goal:** Show facilities in world
- Implement `_on_facility_built(facility_id: String)`:
  - Load facility scene (e.g., Stable.tscn)
  - Place at predetermined grid position
  - Add to FacilitiesLayer
- Create placeholder facility scenes:
  - Stable.tscn (simple sprite)
  - Pasture.tscn (fenced area)
  - BreedingPen.tscn (barn sprite)

**Files:**
- `scripts/ranch/Ranch.gd` (add handler)
- `scenes/facilities/*.tscn` (create placeholders)

---

**Session 11 Acceptance Criteria:**
- [ ] Ranch scene loads and displays
- [ ] Dragons spawn and wander
- [ ] Eggs appear when created
- [ ] Camera can pan and zoom
- [ ] Facilities appear when built
- [ ] Clicking dragon opens details panel
