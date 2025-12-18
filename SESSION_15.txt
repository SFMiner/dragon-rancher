## SESSION 15: Advanced Genetics (Size & Metabolism)
**Model:** Claude Sonnet 4.5 (Code)  
**Duration:** 6-8 hours  
**Extended Thinking:** OFF  
**Dependencies:** Session 14 complete

### Purpose
Implement Size (multi-gene) and Metabolism (trade-offs) traits.

### Tasks

#### P5-101: Size Trait Definition
**Goal:** Add Size trait (multi-gene)
- Extend `trait_defs.json`:
  - Size trait (stored as two loci):
	- `size_S`: S (Large) / s (small)
	- `size_G`: G (Tall) / g (short)
  - Dominance: S > s, G > g
  - Phenotypes (additive):
	- SSGG → Extra Large (2.0x scale)
	- SSGg, SsGG → Large (1.5x scale)
	- SsGg, Ssgg, ssGG → Medium (1.0x scale)
	- ssGg, ssgg → Small (0.75x scale)
  - Unlock at reputation level 2

**Files:** `data/config/trait_defs.json` (add trait)

---

#### P5-102: Multi-Gene Breeding
**Goal:** Handle multiple loci for Size
- Modify `breed_dragons()` in GeneticsEngine:
  - Treat `size_S` and `size_G` as separate traits
  - Each segregates independently
- Modify `calculate_phenotype()`:
  - Count dominant alleles (S and G)
  - Map to size category
  - Return scale factor

**Files:** `scripts/autoloads/GeneticsEngine.gd` (modify methods)

---

#### P5-103: Size Rendering
**Goal:** Scale dragon sprites by size
- Modify `Dragon.gd` `update_visuals()`:
  - Get size phenotype (scale factor)
  - Apply to sprite scale
- Ensure size persists through lifecycle stages

**Files:** `scripts/entities/Dragon.gd` (modify method)

---

#### P5-104: Metabolism Trait Definition
**Goal:** Add Metabolism trait (trade-offs)
- Extend `trait_defs.json`:
  - Metabolism trait:
	- Alleles: M (Normal) / m (Hyper)
	- Dominance: incomplete (MM/Mm/mm)
	- Phenotypes:
	  - MM → Normal (1.0x speed, 1.0x food, 1.0x lifespan)
	  - Mm → Intermediate (1.25x speed, 1.5x food, 0.85x lifespan)
	  - mm → Hyper (1.5x speed, 2.0x food, 0.7x lifespan)
  - Unlock at reputation level 3

**Files:** `data/config/trait_defs.json` (add trait)

---

#### P5-105: Metabolism Effects Implementation
**Goal:** Apply metabolism modifiers
- Modify `advance_season()` in RanchState:
  - Apply food consumption multiplier based on metabolism
- Modify `calculate_lifespan()` in Lifecycle:
  - Apply lifespan multiplier
- Optionally modify dragon movement speed (cosmetic)

**Files:**
- `scripts/autoloads/RanchState.gd` (modify method)
- `scripts/rules/Lifecycle.gd` (modify method)

---

#### P5-106: Trade-off Orders
**Goal:** Generate orders requesting specific metabolism
- Add metabolism-specific orders:
  - "Hyper dragon (for racing)" → higher pay
  - "Normal metabolism dragon (reliable)" → standard pay
- Update OrderMatching to handle metabolism

**Files:** `data/config/order_templates.json` (add templates)

---

**Session 15 Acceptance Criteria:**
- [ ] SSGG × ssgg → all SsGg (Medium size)
- [ ] SsGg × SsGg → size distribution correct (9:3:3:1 ratio)
- [ ] Dragon sprites scale correctly by size
- [ ] MM × mm → all Mm (Intermediate metabolism)
- [ ] Hyper dragons consume 2x food
- [ ] Hyper dragons have shorter lifespan
- [ ] Orders request size and metabolism correctly

---
