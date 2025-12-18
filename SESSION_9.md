## SESSION 9: UI Foundation & HUD
**Model:** Gemini Flash 3  
**Duration:** 4-6 hours  
**Extended Thinking:** N/A  
**Dependencies:** Sessions 1-8 complete

### Purpose
Create basic UI scenes and HUD (top bar, panels). Focus on boilerplate and layout, not complex logic.

### Tasks

#### P2-001: HUD.tscn Scene Setup
**Goal:** Create top bar UI
- Create `HUD.tscn` (Control, CanvasLayer)
- Add child nodes:
  - Panel (top bar background)
  - HBoxContainer for left side:
	- Label (Money: $XXX)
	- Label (Food: XXX)
	- Label (Season: X)
  - HBoxContainer for right side:
	- Label (Reputation: XXX)
	- Button (Menu)
	- Button (Settings)
- Use theme for consistent styling
- Anchors: top-left, stretch horizontally

**Files:** `scenes/ranch/ui/HUD.tscn`

---

#### P2-002: HUD.gd Controller
**Goal:** Update HUD from RanchState
- Implement `HUD.gd` attached to HUD.tscn
- Connect to RanchState signals:
  - `money_changed` → update money label
  - `food_changed` → update food label
  - `season_changed` → update season label
  - `reputation_increased` → update reputation label
- Implement `_ready()` to initialize labels
- Implement button press handlers (stubs)

**Files:** `scripts/ranch/ui/HUD.gd`

---

#### P2-003: OrdersPanel.tscn Scene Setup
**Goal:** Create orders board panel
- Create `OrdersPanel.tscn` (PanelContainer)
- Add child nodes:
  - VBoxContainer
	- Label (header: "Available Orders")
	- ScrollContainer
	  - VBoxContainer (order list container)
	- Button (Refresh Orders - costs money)
- Style as popup panel (centered, medium size)

**Files:** `scenes/ranch/ui/panels/OrdersPanel.tscn`

---

#### P2-004: OrdersPanel.gd Controller (Basic)
**Goal:** Display order list (no fulfillment yet)
- Implement `OrdersPanel.gd` attached to OrdersPanel.tscn
- Implement `_ready()`:
  - Load initial orders from RanchState
  - Display in list
- Implement `_display_orders(orders: Array[OrderData])`:
  - Clear existing UI
  - For each order, create Label with order details
  - Add button "View Details" (stub)
- Connect to RanchState.orders_generated signal

**Files:** `scripts/ranch/ui/panels/OrdersPanel.gd`

---

#### P2-005: BreedingPanel.tscn Scene Setup
**Goal:** Create breeding panel layout
- Create `BreedingPanel.tscn` (PanelContainer)
- Add child nodes:
  - VBoxContainer
	- Label (header: "Select Breeding Pair")
	- HBoxContainer (parent selection)
	  - Button (Select Parent A)
	  - Label (Parent A genotype)
	  - Button (Select Parent B)
	  - Label (Parent B genotype)
	- Label (Predicted Offspring)
	- VBoxContainer (prediction results)
	- Button (Breed - disabled until both selected)

**Files:** `scenes/ranch/ui/panels/BreedingPanel.tscn`

---

#### P2-006: DragonDetailsPanel.tscn Scene Setup
**Goal:** Create dragon details panel
- Create `DragonDetailsPanel.tscn` (PanelContainer)
- Add child nodes:
  - VBoxContainer
	- Label (dragon name)
	- TextureRect (dragon sprite preview)
	- Label (Genotype: ...)
	- Label (Phenotype: ...)
	- Label (Age: ... seasons)
	- Label (Life Stage: ...)
	- ProgressBar (Health)
	- ProgressBar (Happiness)
	- HBoxContainer (buttons)
	  - Button (Select for Breeding)
	  - Button (Sell)
	  - Button (Close)

**Files:** `scenes/ranch/ui/panels/DragonDetailsPanel.tscn`

---

#### P2-007: BuildPanel.tscn Scene Setup
**Goal:** Create facility build menu
- Create `BuildPanel.tscn` (PanelContainer)
- Add child nodes:
  - VBoxContainer
	- Label (header: "Build Facilities")
	- ScrollContainer
	  - VBoxContainer (facility list container)
- For each facility type, add:
  - HBoxContainer
	- Label (facility name)
	- Label (cost)
	- Label (effect)
	- Button (Build)

**Files:** `scenes/ranch/ui/panels/BuildPanel.tscn`

---

#### P2-008: NotificationsPanel.tscn Scene Setup
**Goal:** Create toast notification system
- Create `NotificationsPanel.tscn` (Control, CanvasLayer)
- Add child nodes:
  - VBoxContainer (top-right corner)
	- (notifications added dynamically)
- Style: semi-transparent background, auto-fade after 3 seconds

**Files:** `scenes/ranch/ui/panels/NotificationsPanel.tscn`

---

#### P2-009: NotificationsPanel.gd Controller
**Goal:** Show notifications
- Implement `NotificationsPanel.gd`
- Implement `show_notification(text: String, type: String)`:
  - Create Label
  - Set text and color based on type (success, error, info)
  - Add to VBoxContainer
  - Create Tween to fade out after 3 seconds
  - Remove label after fade
- Connect to RanchState signals:
  - `order_completed` → "Order completed! +$XXX"
  - `dragon_added` → "Dragon hatched!"
  - `reputation_increased` → "Reputation increased!"

**Files:** `scripts/ranch/ui/panels/NotificationsPanel.gd`

---

**Session 9 Acceptance Criteria:**
- [ ] HUD displays and updates correctly
- [ ] OrdersPanel shows order list
- [ ] BreedingPanel layout complete
- [ ] DragonDetailsPanel layout complete
- [ ] BuildPanel layout complete
- [ ] Notifications appear and fade correctly
