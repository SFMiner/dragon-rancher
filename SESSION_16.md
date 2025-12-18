## SESSION 16: Advanced Genetics (Docility)
**Model:** Claude Sonnet 4.5 (Code)  
**Duration:** 4-6 hours  
**Extended Thinking:** OFF  
**Dependencies:** Session 15 complete

### Purpose
Implement Docility trait with multiple alleles and dominance hierarchy.

### Tasks

#### P5-201: Docility Trait Definition
**Goal:** Add Docility trait (3 alleles)
- Extend `trait_defs.json`:
  - Docility trait:
	- Alleles: D1 (Docile), D2 (Normal), D3 (Aggressive)
	- Dominance hierarchy: D2 > D1 > D3
	- Phenotypes:
	  - D1D1 → Very Docile (0% escape, -20 fight)
	  - D1D2 → Docile (5% escape, -10 fight)
	  - D2D2 → Normal (10% escape, 0 fight)
	  - D2D3 → Aggressive (15% escape, +10 fight)
	  - D3D3 → Very Aggressive (25% escape, +20 fight)
	  - D1D3 → Normal (D2 effect masks both)
  - Unlock at reputation level 4

**Files:** `data/config/trait_defs.json` (add trait)

---

#### P5-202: Multi-Allele Breeding
**Goal:** Handle 3-allele inheritance
- Modify `breed_dragons()` in GeneticsEngine:
  - Handle alleles with >2 characters (D1, D2, D3)
  - Select one allele from each parent
- Modify `calculate_phenotype()`:
  - Implement dominance hierarchy lookup
  - D1D3 resolves to Normal (D2 effect)

**Files:** `scripts/autoloads/GeneticsEngine.gd` (modify methods)

---

#### P5-203: Docility Effects Implementation
**Goal:** Apply docility behaviors (optional)
- Add escape chance to dragons:
  - Random event each season
  - Dragons with high aggression may escape if no fencing
- Add fight bonus (for future battle arena feature)
- Display docility in DragonDetailsPanel

**Files:**
- `scripts/autoloads/RanchState.gd` (add escape logic)
- `scripts/data/DragonData.gd` (add properties)

---

#### P5-204: Docility Orders
**Goal:** Generate docility-based orders
- Add docility-specific orders:
  - "Docile dragon for petting zoo"
  - "Aggressive dragon for guard duty"
- Update OrderMatching

**Files:** `data/config/order_templates.json` (add templates)

---

**Session 16 Acceptance Criteria:**
- [ ] D1D2 × D3D3 → 50% D1D3 (Normal), 50% D2D3 (Aggressive)
- [ ] D1D3 correctly displays as Normal phenotype
- [ ] Aggressive dragons have escape chance
- [ ] Orders request docility and match correctly
