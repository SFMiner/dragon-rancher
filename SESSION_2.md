## SESSION 2: Core Genetics Engine
**Model:** Claude Sonnet 4.5 (Code)  
**Duration:** 6-8 hours  
**Extended Thinking:** OFF (well-defined problem space)  
**Dependencies:** Session 1 complete

### Purpose
Implement pure genetics logic with full test coverage. This is the mathematical heart of the game and must be deterministic and correct.

### Tasks

#### P1-001: RNGService Implementation
**Goal:** Centralize all randomness with seedable RNG
- Implement `RNGService.gd` autoload
- Provide `set_seed(seed: int)`
- Provide `randf() -> float`, `randi_range(from: int, to: int) -> int`
- Store current seed for save/load
- Add debug method to print seed

**Files:** `scripts/autoloads/RNGService.gd`

---

#### P1-002: TraitDB Implementation (MVP Traits)
**Goal:** Implement trait database with 3 MVP traits
- Implement `TraitDB.gd` autoload
- Load trait definitions from `data/config/trait_defs.json` (or hardcode initially)
- Implement MVP traits:
  - Fire: F (dominant) / f (recessive) → fire / smoke
  - Wings: w (dominant - teaching moment!) / W (recessive) → vestigial / functional
  - Armor: A (dominant) / a (recessive) → heavy / light
- Implement `get_trait_def(trait_key: String) -> TraitDef`
- Implement `get_unlocked_traits(reputation_level: int) -> Array[String]`
- All traits unlocked at reputation 0 for MVP

**Files:** 
- `scripts/autoloads/TraitDB.gd`
- `data/config/trait_defs.json` (create)

---

#### P1-003: GeneticsEngine Core - Breeding
**Goal:** Implement deterministic breeding logic
- Implement `GeneticsEngine.gd` autoload
- Implement `breed_dragons(parent_a: DragonData, parent_b: DragonData) -> Dictionary`:
  - For each trait in TraitDB, randomly select one allele from each parent using RNGService
  - Return offspring genotype as `Dictionary[trait_key, Array[allele1, allele2]]`
  - Log seed and inputs for debugging
- Handle edge cases:
  - Null/missing parent data
  - Parent missing trait (use defaults)
  - Invalid alleles

**Files:** `scripts/autoloads/GeneticsEngine.gd`

---

#### P1-004: GeneticsEngine Core - Phenotype Calculation
**Goal:** Convert genotypes to visible traits
- Implement `calculate_phenotype(genotype: Dictionary) -> Dictionary`:
  - For each trait_key in genotype:
	- Get TraitDef from TraitDB
	- Normalize allele order (alphabetical)
	- Lookup in phenotype table
	- Return phenotype data (name, sprite_suffix, color, etc.)
  - Handle incomplete dominance (not needed for MVP but structure for it)
- Handle edge cases:
  - Unknown trait keys
  - Malformed genotypes
  - Missing phenotype entries

**Files:** `scripts/autoloads/GeneticsEngine.gd`

---

#### P1-005: GeneticsResolvers - Normalization Utilities
**Goal:** Implement genotype normalization utilities
- Implement `GeneticsResolvers.gd` module (not autoload)
- Implement `normalize_genotype(alleles: Array) -> String`:
  - Sort alphabetically: ["f", "F"] → "Ff"
  - Used for phenotype lookups
- Implement `validate_genotype(genotype: Dictionary, trait_key: String) -> bool`:
  - Check alleles are valid for trait
- Implement `format_genotype_display(genotype: Dictionary) -> String`:
  - For UI: `{"fire": ["F", "f"]}` → "Ff"

**Files:** `scripts/rules/GeneticsResolvers.gd`

---

#### P1-006: Unit Tests - Genetics Core
**Goal:** Comprehensive test coverage for genetics
- Create `tests/genetics/test_breeding.gd`:
  - Test FF × ff → all Ff
  - Test Ff × Ff → 25% FF, 50% Ff, 25% ff (with fixed seed)
  - Test ww × WW → all wW (vestigial phenotype)
  - Test Aa × aa → 50% Aa, 50% aa
- Create `tests/genetics/test_phenotype.gd`:
  - Test all phenotype lookups for MVP traits
  - Test normalization (Ff == fF)
  - Test invalid genotypes throw errors
- Create `tests/genetics/test_normalization.gd`:
  - Test allele sorting
  - Test validation
  - Test display formatting

**Files:**
- `tests/genetics/test_breeding.gd`
- `tests/genetics/test_phenotype.gd`
- `tests/genetics/test_normalization.gd`

---

#### P1-007: Punnett Square Generator
**Goal:** Implement optional helper tool
- Implement `generate_punnett_square(parent_a: DragonData, parent_b: DragonData, trait_key: String) -> Array`:
  - Return 2D array of outcomes with probabilities
  - Each cell: `{"genotype": "Ff", "phenotype": "Fire", "probability": 0.25}`
- Handle edge cases:
  - Invalid trait keys
  - Missing genotypes
- This is for UI display only, not core logic

**Files:** `scripts/autoloads/GeneticsEngine.gd` (add method)

---

**Session 2 Acceptance Criteria:**
- [ ] All genetics tests pass with fixed seed
- [ ] Breeding produces correct offspring ratios (verified statistically over 1000 runs)
- [ ] Phenotype calculation handles all MVP traits
- [ ] Vestigial wings (ww) correctly display as dominant
- [ ] Normalization handles all edge cases
- [ ] Punnett square matches actual breeding outcomes

---
