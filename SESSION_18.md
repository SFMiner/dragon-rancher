## SESSION 18: Code Review & Bug Fixing
**Model:** Gemini Pro 3  
**Duration:** 4-6 hours  
**Extended Thinking:** N/A  
**Dependencies:** Sessions 1-17 complete

### Purpose
Comprehensive code review, static analysis, edge case verification, and bug fixing.

### Tasks

#### P-REVIEW-001: API Adherence Review
**Goal:** Verify all code follows locked APIs
- Review all autoload implementations against API_Reference.md
- Check method signatures match
- Check signal payloads match
- Identify API drift or inconsistencies
- Generate list of violations

**Deliverable:** `docs/API_Review_Report.md`

---

#### P-REVIEW-002: Edge Case Analysis
**Goal:** Identify missing null/edge case handling
- Review all public methods for:
  - Null checks
  - Empty array/dictionary checks
  - Division by zero
  - Index out of bounds
  - Invalid enum values
- Generate list of missing checks

**Deliverable:** `docs/Edge_Case_Report.md`

---

#### P-REVIEW-003: Performance Analysis
**Goal:** Identify performance bottlenecks for HTML5
- Review code for:
  - Per-frame operations (should be minimal)
  - Unnecessary scene tree queries
  - Large allocations
  - Expensive string operations
  - Missing caching
- Suggest optimizations

**Deliverable:** `docs/Performance_Report.md`

---

#### P-REVIEW-004: Test Coverage Analysis
**Goal:** Identify missing unit tests
- Review test files
- List untested methods (especially genetics and order matching)
- Suggest additional test cases
- Check for statistical testing of random outcomes

**Deliverable:** `docs/Test_Coverage_Report.md`

---

#### P-REVIEW-005: Save Format Validation
**Goal:** Verify save/load is robust
- Test serialization edge cases:
  - Empty save
  - Partial save (missing keys)
  - Corrupted JSON
  - Version mismatch
  - Large save files
- Verify migration system
- Verify backup restoration

**Deliverable:** `docs/Save_System_Report.md`

---

#### P-REVIEW-006: Cross-File Consistency Check
**Goal:** Ensure consistency across codebase
- Check trait keys are consistent (fire, wings, armor, etc.)
- Check signal names match between emitter and receiver
- Check naming conventions (snake_case, PascalCase)
- Check indentation (tabs, not spaces)

**Deliverable:** `docs/Consistency_Report.md`

---

#### P-REVIEW-007: Bug Fix Session
**Goal:** Fix all critical issues from reports
- Prioritize fixes:
  - P0: Crashes, data loss, incorrect genetics
  - P1: Major bugs, poor UX
  - P2: Minor bugs, polish
- Implement fixes
- Verify with tests

**Deliverable:** Fixed code + updated test coverage

---

**Session 18 Acceptance Criteria:**
- [ ] All P0 bugs fixed
- [ ] API drift corrected
- [ ] Edge cases handled
- [ ] Performance bottlenecks addressed
- [ ] Test coverage >80% for genetics and order matching
- [ ] Save/load is robust

---
