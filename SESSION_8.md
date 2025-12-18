## SESSION 8: Progression System
**Model:** Claude Sonnet 4.5 (Code)  
**Duration:** 4-6 hours  
**Extended Thinking:** OFF  
**Dependencies:** Sessions 1-7 complete

### Purpose
Implement reputation system, trait unlocks, and achievement tracking.

### Tasks

#### P4-001: Reputation Levels Definition
**Goal:** Define progression thresholds
- Create `Progression.gd` module (pure logic)
- Define reputation levels:
  - Level 0 (Novice): $0 earned
  - Level 1 (Established): $5,000 earned
  - Level 2 (Expert): $20,000 earned
  - Level 3 (Master): $50,000 earned
  - Level 4 (Legendary): $100,000 earned
- Define unlocks per level:
  - Level 0: Fire, Wings, Armor
  - Level 1: Color (incomplete dominance)
  - Level 2: Size (multi-gene)
  - Level 3: Metabolism (trade-offs)
  - Level 4: Docility (multi-allele)

**Files:** `scripts/rules/Progression.gd`

---

#### P4-002: Reputation Tracking in RanchState
**Goal:** Track lifetime earnings and reputation
- Add to RanchState:
  - `lifetime_earnings: int`
  - `reputation_level: int`
- Implement `_update_reputation()` (called when earning money):
  - Check if lifetime_earnings crosses threshold
  - If so, increase reputation_level
  - Emit reputation_increased signal
  - Unlock new traits (see P4-003)
- Modify `add_money()` to update lifetime_earnings

**Files:** `scripts/autoloads/RanchState.gd` (add tracking)

---

#### P4-003: Trait Unlock System
**Goal:** Gate traits by reputation
- Modify `TraitDB.gd` to track unlocked traits:
  - `unlocked_traits: Array[String]`
  - `unlock_trait(trait_key: String)`
- Modify `get_unlocked_traits(reputation_level: int) -> Array[String]`:
  - Return traits for reputation level and below
- Integrate with RanchState:
  - When reputation increases, unlock new traits
  - Orders only use unlocked traits

**Files:** `scripts/autoloads/TraitDB.gd` (modify)

---

#### P4-004: Achievement System Skeleton
**Goal:** Define achievement tracking
- Create `data/config/achievements.json` (defer descriptions to ChatGPT):
  - "first_sale": Fulfill first order
  - "full_house": Own 6 dragons
  - "perfect_match": Breed exact phenotype requested
  - "rare_breed": Create dragon with 3+ rare traits
  - "wealthy": Earn $10,000 total
  - "genetics_master": Use Punnett square 50 times
- Add to RanchState:
  - `achievements: Dictionary` (id → unlocked: bool)
  - `check_achievement(achievement_id: String) -> bool`
  - `unlock_achievement(achievement_id: String)`
- Emit `achievement_unlocked` signal

**Files:**
- `data/config/achievements.json`
- `scripts/autoloads/RanchState.gd` (add tracking)

---

**Session 8 Acceptance Criteria:**
- [ ] Reputation increases at correct thresholds
- [ ] Traits unlock at correct reputation levels
- [ ] Orders only use unlocked traits
- [ ] Achievements track and unlock
- [ ] Reputation persists through save/load

---
