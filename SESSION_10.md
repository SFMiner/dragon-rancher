## SESSION 10: UI Logic & Interactivity
**Model:** Claude Sonnet 4.5 (Code)  
**Duration:** 6-8 hours  
**Extended Thinking:** OFF  
**Dependencies:** Session 9 complete

### Purpose
Implement UI controllers and connect panels to game logic.

### Tasks

#### P2-101: BreedingPanel.gd Controller
**Goal:** Implement breeding workflow
- Implement `BreedingPanel.gd` attached to BreedingPanel.tscn
- Properties:
  - `selected_parent_a: DragonData`
  - `selected_parent_b: DragonData`
- Implement `_on_select_parent_a_pressed()`:
  - Show dragon selection dialog (filter adult dragons)
  - On selection, update selected_parent_a
  - Display genotype
  - Update predictions
- Implement `_on_select_parent_b_pressed()` (same)
- Implement `_update_predictions()`:
  - If both parents selected:
	- Call GeneticsEngine to predict offspring
	- Display prediction text (e.g., "50% Fire, 50% Smoke")
	- Enable Breed button
- Implement `_on_breed_pressed()`:
  - Check if Breeding Pen facility exists (required)
  - If not, show error notification
  - Call RanchState.create_egg()
  - Show success notification
  - Close panel

**Files:** `scripts/ranch/ui/panels/BreedingPanel.gd`

---

#### P2-102: DragonDetailsPanel.gd Controller
**Goal:** Show dragon details
- Implement `DragonDetailsPanel.gd` attached to DragonDetailsPanel.tscn
- Implement `show_dragon(dragon: DragonData)`:
  - Update all labels
  - Load sprite preview
  - Update progress bars
  - Enable/disable buttons based on dragon state
- Implement `_on_select_for_breeding_pressed()`:
  - Open BreedingPanel with this dragon pre-selected
- Implement `_on_sell_pressed()`:
  - Show confirmation dialog
  - If confirmed, open OrdersPanel in "fulfill" mode with this dragon

**Files:** `scripts/ranch/ui/panels/DragonDetailsPanel.gd`

---

#### P2-103: OrdersPanel.gd Controller (Full)
**Goal:** Implement order fulfillment
- Implement `_on_view_details_pressed(order: OrderData)`:
  - Show detailed order requirements
  - Show dragons that match
  - Show payment amount
- Implement `_on_fulfill_pressed(order: OrderData, dragon: DragonData)`:
  - Call RanchState.fulfill_order()
  - Show success notification with payment
  - Close panel
- Implement `_on_refresh_pressed()`:
  - Cost: $50
  - Generate new orders
  - Update display

**Files:** `scripts/ranch/ui/panels/OrdersPanel.gd` (expand)

---

#### P2-104: BuildPanel.gd Controller
**Goal:** Implement facility building
- Implement `BuildPanel.gd` attached to BuildPanel.tscn
- Implement `_ready()`:
  - Load facility definitions
  - Display facilities with costs
  - Disable buttons if unaffordable or reputation too low
- Implement `_on_build_pressed(facility_type: String)`:
  - Call RanchState.build_facility()
  - Show success notification
  - Update UI (disable button if can't afford multiple)

**Files:** `scripts/ranch/ui/panels/BuildPanel.gd`

---

#### P2-105: Dragon Selection Dialog
**Goal:** Create reusable dragon picker
- Create `DragonSelectionDialog.tscn` (AcceptDialog or custom)
- Display grid or list of dragons
- Allow filtering (adults only, by trait, etc.)
- Emit signal when dragon selected
- Reuse in BreedingPanel, OrdersPanel, etc.

**Files:**
- `scenes/ranch/ui/widgets/DragonSelectionDialog.tscn`
- `scripts/ranch/ui/widgets/DragonSelectionDialog.gd`

---

#### P2-106: Punnett Square Widget (Optional Helper)
**Goal:** Create Punnett square visualization
- Create `PunnettSquareWidget.tscn` (GridContainer)
- Implement `PunnettSquareWidget.gd`:
  - `display_square(parent_a: DragonData, parent_b: DragonData, trait_key: String)`
  - Query GeneticsEngine.generate_punnett_square()
  - Render 2x2 or 4x4 grid
  - Show genotypes and probabilities
- Add toggle in BreedingPanel to show/hide

**Files:**
- `scenes/ranch/ui/widgets/PunnettSquareWidget.tscn`
- `scripts/ranch/ui/widgets/PunnettSquareWidget.gd`

---

**Session 10 Acceptance Criteria:**
- [ ] Can select two dragons and breed them
- [ ] Egg appears after breeding
- [ ] Can view dragon details by clicking
- [ ] Can fulfill orders by selecting matching dragon
- [ ] Can build facilities from menu
- [ ] Punnett square (if implemented) shows correct predictions
