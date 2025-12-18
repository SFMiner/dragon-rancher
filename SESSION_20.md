## SESSION 20: Final Polish & Playtesting
**Model:** Claude Opus 4.5  
**Duration:** 4-6 hours  
**Extended Thinking:** ON  
**Priority:** Final pass before release

### Purpose
Final balance pass, playtesting, bug fixes, and release preparation.

### Tasks

#### P-FINAL-001: Balance Review
**Goal:** Review and adjust all game balance
- Playtest full game (tutorial → 30 minutes)
- Review:
  - Starting money (too easy/hard?)
  - Order payments (fair?)
  - Facility costs (balanced progression?)
  - Food consumption (too punishing?)
  - Reputation thresholds (too fast/slow?)
  - Trait unlock pacing
- Adjust constants
- Document rationale

**Deliverable:** `docs/Balance_Notes.md` + updated constants

---

#### P-FINAL-002: Tutorial Iteration
**Goal:** Improve tutorial based on playtest
- Playtest tutorial with fresh tester
- Note confusion points
- Revise copy if needed
- Adjust step order if needed
- Verify all advance conditions work

**Deliverable:** Updated tutorial

---

#### P-FINAL-003: HTML5 Export Testing
**Goal:** Test browser build thoroughly
- Export to HTML5
- Test in:
  - Chrome
  - Firefox
  - Safari (if possible)
- Test:
  - Save/load (IndexedDB)
  - Performance (30+ FPS)
  - Audio
  - Touch controls (if implemented)
- Fix browser-specific issues

**Deliverable:** Working HTML5 build

---

#### P-FINAL-004: Bug Bash
**Goal:** Final bug fixing pass
- Run through entire game
- Fix any remaining bugs
- Prioritize:
  - Crashes
  - Incorrect genetics
  - Broken UI
  - Save corruption
- Test edge cases

**Deliverable:** Stable build

---

#### P-FINAL-005: README & Documentation
**Goal:** Write player-facing documentation
- Write README.md:
  - How to play
  - Genetics basics
  - Controls
  - Tips
- Write CREDITS.md
- Write CHANGELOG.md

**Deliverable:** Documentation files

---

**Session 20 Acceptance Criteria:**
- [ ] Game is balanced and fun
- [ ] Tutorial is clear and effective
- [ ] HTML5 build works in all browsers
- [ ] No critical bugs remain
- [ ] Documentation is complete
- [ ] Ready for release
