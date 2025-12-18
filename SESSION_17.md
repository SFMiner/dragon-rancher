## SESSION 17: Creative Content Generation
**Model:** ChatGPT 5.2  
**Duration:** 3-4 hours  
**Extended Thinking:** N/A  
**Dependencies:** Sessions 1-16 complete

### Purpose
Generate all player-facing text content: dragon names, order descriptions, tutorial copy, achievements, flavor text.

### Tasks

#### P-CONTENT-001: Dragon Names
**Goal:** Generate 200+ thematic dragon names
- Generate names in categories:
  - Fire-themed: Ember, Blaze, Inferno, etc.
  - Nature-themed: Willow, Moss, Pebble, etc.
  - Mythological: Typhon, Zephyr, Atlas, etc.
  - Whimsical: Noodle, Pickle, Buttons, etc.
- Mix short and long names
- Avoid duplicates
- Export as JSON array

**Deliverable:** `data/config/names_dragons.json`

---

#### P-CONTENT-002: Order Descriptions
**Goal:** Write 50+ order descriptions
- For each order template:
  - Write engaging 1-2 sentence description
  - Explain why customer wants this dragon
  - Match tone (whimsical, not corporate)
- Examples:
  - "Local farmer needs a fire-breather to clear brush. Must be docile!"
  - "Noble family seeks a large, majestic dragon for their estate."
  - "Wizard requires exact genotype FF ww for spell components."
- Use placeholders for traits: `{trait_fire}`, `{trait_color}`

**Deliverable:** Updated `data/config/order_templates.json` with descriptions

---

#### P-CONTENT-003: Tutorial Copy
**Goal:** Write clear, concise tutorial steps
- For each tutorial step:
  - Write title (max 40 chars)
  - Write body (max 140 chars)
  - Use directive voice ("Click the dragon", not "You can click...")
  - One action per step
  - Avoid genetics jargon unless introducing term
- Examples:
  - Step 1: "Welcome! You run a dragon ranch. Let's get started."
  - Step 3: "Click the 🧬 Breeding button to open the breeding panel."
  - Step 5: "Click 'Breed' to create an egg. It will hatch in 2-3 seasons."

**Deliverable:** Updated `data/config/tutorial_steps.json` with copy

---

#### P-CONTENT-004: Achievement Descriptions
**Goal:** Write achievement names and descriptions
- For each achievement:
  - Catchy name
  - 1 sentence description
- Examples:
  - "First Sale": "Fulfill your first customer order."
  - "Genetics Master": "Successfully use the Punnett square 50 times."
  - "Living Legend": "Keep a dragon alive for 20+ seasons."

**Deliverable:** Updated `data/config/achievements.json` with descriptions

---

#### P-CONTENT-005: Notification Messages
**Goal:** Write toast notification messages
- Short messages for events:
  - Order completed: "Order completed! +$XXX"
  - Egg hatched: "{dragon_name} has hatched!"
  - Reputation increased: "Reputation increased to {level}!"
  - Trait unlocked: "New trait unlocked: {trait_name}!"
  - Dragon escaped: "{dragon_name} escaped! (Lost)"
  - Dragon died: "{dragon_name} has died of old age."

**Deliverable:** `data/config/notification_messages.json`

---

#### P-CONTENT-006: Facility Descriptions
**Goal:** Write facility names and descriptions
- For each facility:
  - Short name
  - 1-2 sentence description
  - Explain benefit clearly
- Examples:
  - "Stable": "Basic housing for 4 dragons. Protects from weather."
  - "Genetics Lab": "Advanced facility that reveals hidden genotypes. Unlocks Punnett square tool."

**Deliverable:** Updated `data/config/facility_defs.json` with descriptions

---

**Session 17 Acceptance Criteria:**
- [ ] All dragon names are unique and thematic
- [ ] Order descriptions are engaging and clear
- [ ] Tutorial copy is concise (≤140 chars per step)
- [ ] Achievement descriptions are motivating
- [ ] Notification messages are informative
- [ ] Facility descriptions explain benefits
