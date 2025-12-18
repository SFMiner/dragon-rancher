# Dragon Ranch — Risk Register

**Document Status:** LOCKED  
**Version:** 1.0  
**Last Updated:** 2025-12-17  

This document identifies risks, assesses their likelihood and impact, and defines mitigation strategies. Risks are categorized into Technical, Design, and Process risks.

---

## Risk Assessment Matrix

| Impact ↓ / Likelihood → | Low (1) | Medium (2) | High (3) |
|-------------------------|---------|------------|----------|
| **Critical (4)** | 4 | 8 | 12 |
| **High (3)** | 3 | 6 | 9 |
| **Medium (2)** | 2 | 4 | 6 |
| **Low (1)** | 1 | 2 | 3 |

**Priority Thresholds:**
- **P0 (Score 8-12):** Must address immediately, blocks progress
- **P1 (Score 5-7):** Address within current phase
- **P2 (Score 3-4):** Address when convenient
- **P3 (Score 1-2):** Monitor, no action required

---

## 1. Technical Risks

### T-001: Genotype Normalization Drift

| Attribute | Value |
|-----------|-------|
| **Description** | Inconsistent genotype key formats (Ff vs fF, string vs array) cause phenotype lookup failures, order matching errors, and save corruption |
| **Likelihood** | High (3) |
| **Impact** | Critical (4) |
| **Risk Score** | 12 (P0) |
| **Trigger Conditions** | Tests fail intermittently; same dragon shows different phenotypes; order matching reports false negatives |

**Mitigation Strategy:**
1. ✅ Create `Genetics_Normalization_Rules.md` with canonical rules (Session 1)
2. Centralize ALL normalization in `GeneticsResolvers.gd` (Session 2)
3. Add comprehensive unit tests covering all allele combinations (Session 2)
4. Validate genotypes on load and before save (Session 5)
5. Never store pre-normalized strings — always normalize at lookup time

**Owner:** Session 2 (GeneticsEngine implementation)

**Verification:**
- [ ] All genetics tests pass with 100% of allele combinations
- [ ] Round-trip test: breed → save → load → breed produces valid offspring
- [ ] Order matching test: all phenotype queries return expected results

---

### T-002: Save/Load Corruption

| Attribute | Value |
|-----------|-------|
| **Description** | Save files become corrupted, unreadable, or lose dragon data due to schema changes, incomplete writes, or migration failures |
| **Likelihood** | High (3) |
| **Impact** | Critical (4) |
| **Risk Score** | 12 (P0) |
| **Trigger Conditions** | Players lose progress; dragons missing after load; crash on load; browser clears IndexedDB |

**Mitigation Strategy:**
1. ✅ Define versioned save format with migration plan (Session 1 - Save_Format_v1.md)
2. Implement backup file system (`.bak` file before overwrite) (Session 5)
3. Validate all data on load, repair with defaults if possible (Session 5)
4. Add `export_save()` / `import_save()` for manual backup (Session 5)
5. Autosave at safe points only (start of season, after order complete)
6. Never autosave during animations or tutorial steps

**Owner:** Session 5 (SaveSystem implementation)

**Verification:**
- [ ] Corrupted JSON falls back to backup file
- [ ] Missing fields get default values without crash
- [ ] Version mismatch triggers migration, not failure
- [ ] Browser refresh preserves save (IndexedDB test)

---

### T-003: HTML5 Performance Degradation

| Attribute | Value |
|-----------|-------|
| **Description** | Game drops below 30 FPS in browser due to excessive per-frame operations, scene tree queries, or memory allocation |
| **Likelihood** | Medium (2) |
| **Impact** | High (3) |
| **Risk Score** | 6 (P1) |
| **Trigger Conditions** | FPS < 30 with 10+ dragons; noticeable lag when opening panels; memory grows over time |

**Mitigation Strategy:**
1. Use signal-driven UI updates, not per-frame polling (All sessions)
2. Implement timer-based dragon wandering (every 0.5s, not _process) (Session 3)
3. Cache trait lookups — don't query TraitDB every frame (Session 2)
4. Limit visible dragons (hide off-screen, use LOD) (Session 11)
5. Profile before each phase milestone
6. Set hard limit: max 30 dragons on screen

**Owner:** Session 11 (Ranch Scene) + Session 18 (Review)

**Verification:**
- [ ] Maintain 30+ FPS with 20 dragons in Chrome
- [ ] Memory stays under 200MB after 30 minutes
- [ ] No GC stutters visible during normal play

---

### T-004: Audio Overlap and Clipping

| Attribute | Value |
|-----------|-------|
| **Description** | Multiple sound effects play simultaneously causing distortion; long sounds cut off; volume spikes |
| **Likelihood** | Low (1) |
| **Impact** | Medium (2) |
| **Risk Score** | 2 (P3) |
| **Trigger Conditions** | Rapid events (multiple eggs hatching); sounds play on top of each other; player complains about audio |

**Mitigation Strategy:**
1. Use SFX player pool (4 AudioStreamPlayers) (Session 12)
2. Implement per-sound cooldown (don't replay same sound within 100ms)
3. Limit simultaneous sounds (max 4 SFX at once)
4. Use short SFX files (< 2 seconds)
5. Lower priority sounds get skipped when pool exhausted

**Owner:** Session 12 (Audio implementation)

**Verification:**
- [ ] Rapid egg hatches don't cause audio distortion
- [ ] Volume stays consistent
- [ ] No audio cuts off prematurely

---

### T-005: Multi-Allele Breeding Errors

| Attribute | Value |
|-----------|-------|
| **Description** | Docility trait (3 alleles) produces invalid genotypes or incorrect phenotypes due to non-standard allele handling |
| **Likelihood** | Medium (2) |
| **Impact** | High (3) |
| **Risk Score** | 6 (P1) |
| **Trigger Conditions** | D1D3 doesn't resolve to "Normal" phenotype; breeding D1D2 × D3D3 produces invalid offspring |

**Mitigation Strategy:**
1. ✅ Document multi-allele rules in Genetics_Normalization_Rules.md (Session 1)
2. Implement allele selection to handle any length allele string (Session 2)
3. Unit test all 6 docility genotype combinations (Session 16)
4. Test dominance hierarchy resolution explicitly
5. Add validation that offspring alleles exist in trait definition

**Owner:** Session 16 (Docility implementation)

**Verification:**
- [ ] All 6 genotype combinations produce correct phenotypes
- [ ] D1D3 specifically shows "Normal" (D1 masks D3)
- [ ] Breeding produces only valid allele combinations

---

## 2. Design Risks

### D-001: Players Don't Understand Genetics

| Attribute | Value |
|-----------|-------|
| **Description** | Players confused by inheritance rules, can't predict breeding outcomes, frustrated by "random" results |
| **Likelihood** | Medium (2) |
| **Impact** | High (3) |
| **Risk Score** | 6 (P1) |
| **Trigger Conditions** | Tutorial completion < 80%; players ask "why did I get this dragon?"; Punnett square never used |

**Mitigation Strategy:**
1. Start with simple Mendelian (3 traits) before complex (Session 2)
2. Show predicted offspring percentages before breeding (Session 10)
3. Provide optional Punnett square tool (Session 10)
4. Wings trait "surprise" becomes teaching moment (Session 2)
5. Add micro-tutorials when new traits unlock (Session 14-16)
6. Tooltips explain each trait's inheritance pattern

**Owner:** Session 13 (Tutorial) + Session 17 (Content)

**Verification:**
- [ ] Fresh tester completes tutorial without getting stuck
- [ ] Players can predict FF × Ff outcome after 15 minutes
- [ ] "Why?" questions decrease after tutorial

---

### D-002: Core Loop Feels Grindy

| Attribute | Value |
|-----------|-------|
| **Description** | Players feel there's "nothing to do" between seasons; waiting is boring; progression too slow |
| **Likelihood** | Medium (2) |
| **Impact** | High (3) |
| **Risk Score** | 6 (P1) |
| **Trigger Conditions** | Session length < 10 minutes; players spam "advance season"; "boring" feedback |

**Mitigation Strategy:**
1. Keep season duration short (2-3 minutes real time) (Session 4)
2. Provide time skip controls (1x, 2x, 4x speed) (Session 4)
3. Ensure always 3-5 actionable orders available (Session 6)
4. Early orders achievable with starter dragons (Session 6)
5. Visual activity: dragons wander, eggs wobble, weather changes (Session 11)
6. Multiple progression paths: orders, facilities, achievements (Session 8)

**Owner:** Session 20 (Balance pass)

**Verification:**
- [ ] Players play 20+ minutes without boredom
- [ ] Average session length > 15 minutes
- [ ] Multiple goals available at any time

---

### D-003: Economy Unbalanced

| Attribute | Value |
|-----------|-------|
| **Description** | Game too easy (infinite money) or too hard (can't afford anything); food costs punishing; facility costs arbitrary |
| **Likelihood** | High (3) |
| **Impact** | Medium (2) |
| **Risk Score** | 6 (P1) |
| **Trigger Conditions** | Money > $50,000 by season 10; can't afford second facility by season 5; dragons starve constantly |

**Mitigation Strategy:**
1. ✅ Document initial balance constants (GDD has values)
2. Centralize ALL pricing in `Pricing.gd` for easy tuning (Session 6)
3. Playtest balance at end of each phase (All sessions)
4. Ensure first order fulfillable with starter dragons (Session 6)
5. Food consumption scales with dragon count, not linearly (Session 4)
6. Final balance pass with extended playtest (Session 20)

**Owner:** Session 20 (Balance pass)

**Verification:**
- [ ] Can afford first facility by season 3
- [ ] Money grows but not exponentially
- [ ] Dragons rarely starve with reasonable play

---

### D-004: Order Requirements Unfulfillable

| Attribute | Value |
|-----------|-------|
| **Description** | Generated orders require traits player can't breed; no valid orders available; orders feel arbitrary |
| **Likelihood** | Medium (2) |
| **Impact** | Medium (2) |
| **Risk Score** | 4 (P2) |
| **Trigger Conditions** | Player can't fulfill any order for 3+ seasons; orders require unlocked traits; "impossible order" complaints |

**Mitigation Strategy:**
1. Order generator only uses unlocked traits (Session 6)
2. Guarantee at least 1 order fulfillable with current dragons (Session 6)
3. Order complexity scales with reputation (Session 6)
4. Allow order refresh (costs money) (Session 10)
5. Some orders have flexible requirements ("any fire breather")

**Owner:** Session 6 (OrderSystem)

**Verification:**
- [ ] New game: at least 1 order fulfillable immediately
- [ ] Orders never require locked traits
- [ ] 50%+ of orders achievable within 2 breeding cycles

---

### D-005: Trait Unlock Pacing Wrong

| Attribute | Value |
|-----------|-------|
| **Description** | New traits unlock too fast (overwhelming) or too slow (boring); unlocks don't feel rewarding |
| **Likelihood** | Medium (2) |
| **Impact** | Medium (2) |
| **Risk Score** | 4 (P2) |
| **Trigger Conditions** | All traits unlocked by season 20; players never reach color trait; "what's next?" complaints |

**Mitigation Strategy:**
1. ✅ Document unlock thresholds in GDD ($5K, $20K, $50K, $100K)
2. Provide micro-tutorial for each new trait (Session 14-16)
3. New trait = new order types immediately (Session 14-16)
4. Visual celebration on unlock (Session 8)
5. Balance pass adjusts thresholds if needed (Session 20)

**Owner:** Session 8 (Progression) + Session 20 (Balance)

**Verification:**
- [ ] First unlock (Color) within 15-20 minutes
- [ ] Each unlock accompanied by new orders
- [ ] Players express excitement at unlocks

---

## 3. Process Risks

### P-001: AI Models Introduce Inconsistent APIs

| Attribute | Value |
|-----------|-------|
| **Description** | Different AI assistants generate conflicting method signatures, duplicate logic, or break established interfaces |
| **Likelihood** | High (3) |
| **Impact** | High (3) |
| **Risk Score** | 9 (P0) |
| **Trigger Conditions** | Merge conflicts; "method not found" errors; same function implemented twice differently |

**Mitigation Strategy:**
1. ✅ Lock interfaces in API_Reference.md BEFORE implementation (Session 1)
2. ✅ Provide task packets with exact method signatures (This document)
3. Forbid API changes without explicit "API change" in task title
4. Use Gemini Pro for review pass between phases (Session 18)
5. Every task specifies "Files to edit" — no others allowed
6. Escalate to Opus if API needs modification

**Owner:** All sessions (process control)

**Verification:**
- [ ] No method signature drift across sessions
- [ ] Review pass finds < 5 API inconsistencies
- [ ] All callers match documented interfaces

---

### P-002: Rework Due to Vague Acceptance Criteria

| Attribute | Value |
|-----------|-------|
| **Description** | Implemented features don't match intent; "works on my machine" but fails in context; misunderstood requirements |
| **Likelihood** | Medium (2) |
| **Impact** | High (3) |
| **Risk Score** | 6 (P1) |
| **Trigger Conditions** | Features rejected in review; > 30% rework rate; "that's not what I meant" feedback |

**Mitigation Strategy:**
1. ✅ Every task has explicit acceptance criteria (Task Distribution)
2. ✅ Every task has "Deliverables" list with file paths
3. Include manual test plan in task ("How to verify")
4. Add unit test requirement for logic-heavy tasks
5. Review deliverables against acceptance criteria before marking complete

**Owner:** All sessions (process control)

**Verification:**
- [ ] < 10% rework rate
- [ ] All acceptance criteria checkable (yes/no, not subjective)
- [ ] Each deliverable maps to criteria

---

### P-003: Scope Creep into Multiplayer

| Attribute | Value |
|-----------|-------|
| **Description** | "Cool idea" additions delay core game; multiplayer complexity overwhelms MVP; features added without planning |
| **Likelihood** | Medium (2) |
| **Impact** | High (3) |
| **Risk Score** | 6 (P1) |
| **Trigger Conditions** | Phase duration exceeds estimate by > 50%; "while we're here, let's add..." comments; WebRTC code appears before Phase 6 |

**Mitigation Strategy:**
1. ✅ Strict phase boundaries with defined deliverables (Task Distribution)
2. NO multiplayer before Phase 6 (explicit in plan)
3. Trade packets (copy-paste) as MVP multiplayer (defer WebRTC)
4. "Future Ideas" captured but not implemented
5. Opus review if task exceeds estimated hours significantly

**Owner:** Session planning (process control)

**Verification:**
- [ ] No multiplayer code until Phase 6
- [ ] Phase durations within 20% of estimates
- [ ] Deferred features documented, not abandoned

---

### P-004: Content Generation Breaks Tone/Clarity

| Attribute | Value |
|-----------|-------|
| **Description** | AI-generated text is too wordy, inconsistent tone, uses jargon, or confuses players |
| **Likelihood** | Low (1) |
| **Impact** | Medium (2) |
| **Risk Score** | 2 (P3) |
| **Trigger Conditions** | Tutorial text > 140 chars; players confused by order descriptions; tone shifts between whimsical and technical |

**Mitigation Strategy:**
1. ✅ Define content constraints (140 char limit, one action per step)
2. Use GPT-5.2 exclusively for content generation (Session 17)
3. Provide tone rubric: "whimsical, not corporate"
4. Review all content in playtest (Session 20)
5. Keep genetics jargon to introduced terms only

**Owner:** Session 17 (Content) + Session 20 (Polish)

**Verification:**
- [ ] All tutorial steps ≤ 140 characters
- [ ] Tone consistent across all player-facing text
- [ ] No unexplained jargon

---

### P-005: Test Coverage Gaps

| Attribute | Value |
|-----------|-------|
| **Description** | Critical systems lack tests; bugs discovered late; genetics edge cases missed |
| **Likelihood** | Medium (2) |
| **Impact** | Medium (2) |
| **Risk Score** | 4 (P2) |
| **Trigger Conditions** | Bugs in genetics found in playtest; order matching fails silently; save corruption not caught |

**Mitigation Strategy:**
1. Session 2 creates genetics unit tests (mandatory)
2. Session 6 creates order matching tests (mandatory)
3. Session 5 creates save/load round-trip tests (mandatory)
4. Session 18 (Gemini Pro) reviews test coverage
5. Minimum 80% coverage for genetics and order matching

**Owner:** Sessions 2, 5, 6 (test creation) + Session 18 (review)

**Verification:**
- [ ] All genotype combinations tested
- [ ] Order matching has positive and negative tests
- [ ] Save/load round-trip passes with all data types

---

## 4. Risk Monitoring Schedule

| Phase End | Review Focus | Escalation Trigger |
|-----------|--------------|-------------------|
| Session 1 | Architecture risks, interface completeness | Any P0 risk unmitigated |
| Session 4 | Genetics correctness, RanchState stability | Breeding tests fail |
| Session 8 | Core loop complete, economy balance | Loop not fun |
| Session 13 | Tutorial effectiveness, UX quality | > 20% tutorial abandonment |
| Session 18 | Code quality, test coverage | Coverage < 70% |
| Session 20 | Overall balance, polish | P0 or P1 risks remain |

---

## 5. Escalation Policy

### When to Escalate to Claude Opus

1. **API changes needed:** Any modification to locked interfaces
2. **Architecture questions:** Unclear responsibility boundaries
3. **Stuck > 30 minutes:** Bug that smaller models can't resolve
4. **Design pivots:** GDD doesn't cover the situation
5. **Risk materialized:** P0 risk trigger condition met

### Escalation Template

```
## Escalation Request

**Risk ID:** T-001 / D-002 / P-003
**Trigger Condition Met:** [describe what happened]
**Current State:** [what's broken/unclear]
**Attempted Solutions:** [what was tried]
**Decision Needed:** [specific question]
```

---

## 6. Risk Status Tracking

| Risk ID | Status | Mitigations Complete | Next Action |
|---------|--------|---------------------|-------------|
| T-001 | 🟡 In Progress | 1 of 5 | Session 2: centralize normalization |
| T-002 | 🟡 In Progress | 1 of 6 | Session 5: implement backup system |
| T-003 | ⚪ Not Started | 0 of 6 | Session 11: implement dragon rendering |
| T-004 | ⚪ Not Started | 0 of 5 | Session 12: implement audio pool |
| T-005 | 🟡 In Progress | 1 of 5 | Session 16: implement docility |
| D-001 | ⚪ Not Started | 0 of 6 | Session 13: implement tutorial |
| D-002 | ⚪ Not Started | 0 of 6 | Session 4: implement time controls |
| D-003 | 🟡 In Progress | 1 of 6 | Session 6: centralize pricing |
| D-004 | ⚪ Not Started | 0 of 5 | Session 6: order generator |
| D-005 | 🟡 In Progress | 1 of 5 | Session 8: implement progression |
| P-001 | ✅ Complete | 3 of 6 | Session 18: review pass |
| P-002 | ✅ Complete | 4 of 5 | Ongoing: verify acceptance criteria |
| P-003 | ✅ Complete | 4 of 5 | Ongoing: enforce phase boundaries |
| P-004 | ⚪ Not Started | 0 of 5 | Session 17: content generation |
| P-005 | ⚪ Not Started | 0 of 5 | Session 2: begin test creation |

**Legend:**
- ✅ Complete: All mitigations in place
- 🟡 In Progress: Some mitigations complete
- ⚪ Not Started: Mitigations pending
- 🔴 At Risk: Trigger conditions observed

---

*Document End — Update risk status after each session completion.*
