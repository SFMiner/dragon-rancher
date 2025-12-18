## SESSION 14: Advanced Genetics (Color Trait)
**Model:** Claude Sonnet 4.5 (Code)  
**Duration:** 4-6 hours  
**Extended Thinking:** OFF  
**Dependencies:** Sessions 1-13 complete

### Purpose
Implement Color trait with incomplete dominance and integrate into game systems.

### Tasks

#### P4-101: Color Trait Definition
**Goal:** Add Color to TraitDB
- Extend `trait_defs.json`:
  - Color trait:
	- Alleles: R (Red), W (White)
	- Dominance: incomplete
	- Phenotypes:
	  - RR → Red (bright red color)
	  - RW → Pink (blend)
	  - WR → Pink (same as RW)
	  - WW → White (pure white color)
  - Unlock at reputation level 1
- Update TraitDB to load Color trait

**Files:** `data/config/trait_defs.json` (add trait)

---

#### P4-102: Incomplete Dominance in GeneticsEngine
**Goal:** Handle incomplete dominance phenotypes
- Modify `calculate_phenotype()` in GeneticsEngine:
  - Check trait's dominance type
  - If "incomplete":
    - Normalize genotype (alphabetical)
    - Lookup phenotype (RW and WR both map to Pink)
  - Ensure correct color values returned

**Files:** `scripts/autoloads/GeneticsEngine.gd` (modify method)

---

#### P4-103: Color Rendering in Dragon Sprites
**Goal:** Display dragon color
- Modify `Dragon.gd` `update_visuals()`:
  - Get color phenotype from dragon_data
  - Apply color modulation to sprite:
    - Red: `Color(0.9, 0.2, 0.2)`
    - Pink: `Color(0.95, 0.6, 0.6)`
    - White: `Color(0.95, 0.95, 0.95)`
  - Combine with existing suffix (fire/smoke, wings, armor)

**Files:** `scripts/entities/Dragon.gd` (modify method)

---

#### P4-104: Color Orders
**Goal:** Generate color-based orders
- Add color requirements to order templates:
  - "Red dragon with fire breath"
  - "Pink dragon (any other traits)"
  - "White dragon with vestigial wings"
- Update OrderGenerator to include color in requirements when unlocked

**Files:** `data/config/order_templates.json` (add templates)

---

#### P4-105: Tutorial Step for Color Unlock
**Goal:** Add micro-tutorial for incomplete dominance
- Add 2-3 tutorial steps triggered on color unlock:
  - Explain incomplete dominance (RR=Red, RW=Pink, WW=White)
  - Show breeding panel with color predictions
  - Prompt to breed a Pink dragon
- Wire into TutorialService

**Files:** `data/config/tutorial_steps.json` (add steps)

---

**Session 14 Acceptance Criteria:**
- [ ] Color trait unlocks at reputation level 1
- [ ] RR × WW → all RW (Pink)
- [ ] RW × RW → 25% RR (Red), 50% RW (Pink), 25% WW (White)
- [ ] Dragon sprites display correct color
- [ ] Orders request color and match correctly
- [ ] Tutorial explains incomplete dominance
