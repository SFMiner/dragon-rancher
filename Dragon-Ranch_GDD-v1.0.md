# Dragon Ranch - Game Design Document

## Version 1.0

**Platform:** HTML5 (Web Browser)  
**Engine:** Godot 4.5  
**Target Audience:** Middle school and up, casual sim players  
**Genre:** Dragon Breeding Tycoon / Genetics Sandbox  
**Art Style:** Whimsical pixel art or hand-drawn sprites  
**Scope:** Expandable sandbox with progressive unlock system

---

## Table of Contents

1. [Core Concept & Vision](#core-concept--vision)
2. [Core Gameplay Loop](#core-gameplay-loop)
3. [Genetics System](#genetics-system)
4. [Dragon Lifecycle](#dragon-lifecycle)
5. [Customer Orders & Economy](#customer-orders--economy)
6. [Facility Management](#facility-management)
7. [Progression & Unlocks](#progression--unlocks)
8. [Multiplayer Trading](#multiplayer-trading)
9. [Controls & Interface](#controls--interface)
10. [Technical Architecture](#technical-architecture)
11. [Development Plan](#development-plan)

---

## Core Concept & Vision

### Executive Summary

**Dragon Ranch** is a whimsical dragon breeding simulation where players run a ranch, breeding dragons to fulfill customer orders. Success requires understanding Mendelian genetics to predict offspring traits. Players expand their facilities, unlock rare traits, and build valuable bloodlines.

### Core Experience

**"I run a dragon ranch. I breed dragons with specific traits to fulfill orders. The better I understand genetics, the more successful I become."**

### Design Pillars

1. **Genetics Rewards Understanding** - Punnett squares are optional tools, but players who understand inheritance patterns succeed faster
2. **Meaningful Choices** - Which breeding pair? Which facility to buy? Which order to accept?
3. **Satisfying Progression** - Start small, unlock rare traits, build empire
4. **Low Pressure** - No fail states, but opportunity costs (time/money)
5. **Charming & Whimsical** - Dragons are cute/quirky, not scary

---

## Core Gameplay Loop

```
START OF SEASON
↓
REVIEW AVAILABLE ORDERS
(customers want dragons with specific traits)
↓
SELECT BREEDING PAIRS
(from your current dragons)
↓
BREED & INCUBATE EGGS
(2-3 days per egg)
↓
HATCH & RAISE HATCHLINGS
(grow from hatchling → juvenile → adult)
↓
FULFILL ORDERS
(sell/rent dragons that match requirements)
↓
EARN MONEY & REPUTATION
↓
BUY FACILITIES / NEW BREEDING STOCK
(unlock new traits, expand capacity)
↓
NEXT SEASON
```

### Time Progression

**Seasons:** Game progresses in seasons (Spring, Summer, Fall, Winter)

- Each season = ~10-15 real-time minutes of gameplay
- Can speed up time when waiting for eggs/growth
- Dragons age by seasons (not individual days)

**Dragon Lifespans:**

- Hatchling: 1 season
- Juvenile: 2 seasons
- Adult: 10-15 seasons (breeding age)
- Elder: 3-5 seasons (can't breed, but can be companions/mentors)
- Total lifespan: ~16-23 seasons (2.5-6 hours of gameplay)

---

## Genetics System

### Core Traits (Version 1)

|Trait|Dominant|Recessive|Phenotype|
|---|---|---|---|
|**Breath**|F (Fire)|f (Smoke)|Fire breathing vs smoke puffs|
|**Wings**|w (Vestigial)|W (Functional)|Tiny stubs vs full wings|
|**Armor**|A (Heavy)|a (Light)|Thick dark scales vs smooth light scales|

**NOTE:** Vestigial wings are dominant (counter-intuitive teaching moment)

### Extended Traits (Unlocked Progressively)

#### Color (Incomplete Dominance)

- **Red (R) × White (W) → Pink (RW)** - blending
- **Red (RR)** - bright red
- **White (WW)** - pure white
- **Pink (RW)** - salmon/pink

Later unlock:

- **Blue (B)** - adds third color to mix
- **RB = Purple, WB = Light blue, RWB = Lavender**

#### Size (Multiple Genes)

- **Gene 1: S (Large) / s (small)**
- **Gene 2: G (Tall) / g (short)**
- **Phenotype:**
    - SSGG = Extra Large (2x size)
    - SSgg or ssGG = Large (1.5x size)
    - Ssgg or ssGg = Medium (1x size)
    - ssgg = Small (0.75x size)

#### Metabolism (Single Gene with Trade-offs)

- **M (Normal)** - standard speed, standard food needs, normal lifespan
- **m (Hyper)** - +50% speed, +100% food needs, -30% lifespan

**Heterozygous Mm** = intermediate (+25% speed, +50% food, -15% lifespan)

#### Docility (Multiple Alleles)

- **D¹ (Docile)** - never escapes, easy handling, poor fighter
- **D² (Normal)** - baseline behavior
- **D³ (Aggressive)** - escape attempts, dangerous, excellent fighter

**Dominance:** D² > D¹ > D³

- D¹D¹ = Very docile
- D¹D² = Docile-leaning
- D²D² = Normal
- D²D³ = Aggressive-leaning
- D³D³ = Very aggressive
- D¹D³ = Normal (D² effect)

### Advanced Genetics (Later Unlocks)

#### Linked Traits (Same Chromosome)

Example: Wings and Metabolism linked

- Usually inherited together
- Rare crossover events (~10% chance) can separate them

#### Sex-Linked Traits

Example: Iridescence only on Z chromosome

- Males (ZZ) can be homozygous or heterozygous
- Females (ZW) always express single Z allele

#### Codominance

Example: Scale patterns

- **S^S (Spotted)** - spots visible
- **S^T (Striped)** - stripes visible
- **S^S S^T** - BOTH spots AND stripes visible

---

## Dragon Lifecycle

### Growth Stages

#### 1. Egg (2-3 seasons)

- Needs incubation chamber
- Shows color hints through shell
- Can peek genotype early with "Genetics Lab" facility

#### 2. Hatchling (1 season)

- Size: Very small (~32x32 pixels)
- Needs: Basic food, water
- Behavior: Playful, wobbly
- Can start seeing phenotype traits

#### 3. Juvenile (2 seasons)

- Size: Medium (~64x64 pixels)
- Needs: More food, training
- Behavior: Energetic, curious
- All traits fully visible

#### 4. Adult (10-15 seasons)

- Size: Full (~96x96 pixels)
- **Breeding Age** - can reproduce
- Needs: Regular food, maintenance
- Behavior: Stable, personality emerges
- Prime for fulfilling orders

#### 5. Elder (3-5 seasons)

- Can't breed anymore
- Reduced food needs
- Can mentor younger dragons (+bonuses)
- Still valuable as companions/displays

### Dragon Stats

**Health:** 0-100

- Decreases if not fed
- Affected by overcrowding
- Recovers with proper care

**Happiness:** 0-100

- Affected by facility quality
- Social dragons need companions
- Affects breeding willingness

**Training:** 0-100 (for fighters/performers)

- Increases with time in training facility
- Determines success in contests

**Pedigree Value:** Calculated

- Based on parents' traits
- Rare combinations worth more
- "Champion bloodline" bonus

---

## Customer Orders & Economy

### Order Types

#### 1. Basic Orders (Always Available)

```
"Need a dragon with Fire Breath"
Pays: $100
Accepts: Any dragon with F_ genotype
```

#### 2. Specific Orders (More Money)

```
"Need a dragon with Fire Breath AND Functional Wings"
Pays: $300
Accepts: F_ WW or F_ Ww
```

#### 3. Exact Genotype Orders (High Pay)

```
"Need a homozygous fire-breather with vestigial wings"
Pays: $500
Accepts: Only FF ww
```

#### 4. Rental Contracts (Recurring Income)

```
"Rent a Large dragon for farm work"
Pays: $50/season for 4 seasons
Returns dragon after contract
```

#### 5. Breeding Contracts

```
"Breed with my dragon, I keep one offspring"
Pays: $200 + you keep other offspring
Uses customer's dragon as one parent
```

### Pricing Factors

**Base Price by Traits:**

- Common trait (F, f, W, w): +$50 each
- Rare trait (specific colors): +$100 each
- Very rare (linked combos): +$300 each

**Multipliers:**

- Exact genotype requested: 2x
- Pure bloodline (known pedigree): 1.5x
- Champion lineage: 2x
- Perfect condition: 1.2x

**Reputation Bonuses:**

- Novice: 1x prices
- Established: 1.2x prices
- Expert: 1.5x prices
- Master: 2x prices

---

## Facility Management

### Starting Facilities (Tutorial Gives You)

#### Ranch House

- Free
- Provides 2 dragon slots
- Basic incubator (1 egg)

#### Pasture

- Free
- Outdoor space for 4 dragons
- Reduces unhappiness from crowding

### Purchasable Facilities

#### Breeding Facilities

**Basic Breeding Pen** - $500

- Holds 1 breeding pair
- Produces 1-2 eggs per breeding

**Advanced Breeding Den** - $2000

- Holds 2 breeding pairs
- +10% chance for rare traits
- Can see egg genotypes before hatching

**Genetics Lab** - $5000

- Unlock Punnett square tool (auto-fill)
- Can test dragon genotypes (instead of guessing)
- Unlock advanced trait breeding

#### Housing Facilities

**Dragon Stable** - $300

- +4 dragon slots
- Basic shelter
- Stackable (buy multiple)

**Luxury Habitat** - $1500

- +2 dragon slots
- +20 happiness for dragons inside
- Required for picky customers

**Nursery** - $800

- +6 hatchling slots (small dragons only)
- Faster growth rate
- Reduces food costs for young dragons

#### Training Facilities

**Training Grounds** - $1200

- Train dragons for contests
- Increases "performance" stat
- Required for some orders

**Battle Arena** - $2000

- Train aggressive dragons
- Unlocks tournament participation
- Teaches battle moves

#### Special Facilities

**Food Silo** - $600

- Stores bulk food (cheaper)
- Auto-feeds dragons
- Reduces daily management

**Medical Bay** - $1000

- Heals sick dragons faster
- Prevents disease spread
- Required for elder care

**Display Gallery** - $800

- Showcase rare dragons (not for sale)
- Generates passive reputation
- Attracts better customers

**Fountain of Youth** - $10,000 (Late game)

- Extends dragon lifespan by 5 seasons
- Can only be used once per dragon
- Expensive but preserves champion bloodlines

---

## Progression & Unlocks

### Reputation Levels

**Level 1: Novice Breeder** (Start)

- Unlocks: Basic traits (Fire, Wings, Armor)
- Orders: Simple single-trait requests
- Max 6 dragons

**Level 2: Established Breeder** ($5,000 earned)

- Unlocks: Color gene (incomplete dominance)
- Orders: Two-trait combinations
- Max 12 dragons
- Can buy Advanced Breeding Den

**Level 3: Expert Breeder** ($20,000 earned)

- Unlocks: Size genes (multiple genes)
- Orders: Exact genotype requests
- Max 20 dragons
- Can buy Genetics Lab

**Level 4: Master Breeder** ($50,000 earned)

- Unlocks: Metabolism gene
- Orders: Complex multi-trait + rare combos
- Max 30 dragons
- Can buy Battle Arena

**Level 5: Legendary Breeder** ($100,000 earned)

- Unlocks: Docility alleles
- Orders: Bloodline + exact genotype
- Unlimited dragons (if you have space)
- Can buy Fountain of Youth

### Trait Unlock Progression

**Phase 1: Simple Mendelian** (Tutorial)

- Fire/Smoke (F/f)
- Wings (w/W - teaching dominance surprise)
- Armor (A/a)

**Phase 2: Incomplete Dominance** (Reputation 2)

- Color (Red/White blending)

**Phase 3: Multiple Genes** (Reputation 3)

- Size (S/s + G/g = 4 phenotypes)

**Phase 4: Trade-offs** (Reputation 4)

- Metabolism (M/m with pros/cons)

**Phase 5: Multiple Alleles** (Reputation 5)

- Docility (D¹/D²/D³)

**Phase 6: Advanced** (Special Achievements)

- Linked traits (complete 50 breedings)
- Sex-linked traits (breed 10 champion females)
- Codominance (own all basic traits)

### Achievement System

**Early Achievements:**

- "First Sale" - Fulfill first order
- "Full House" - Own 6 dragons
- "Perfect Match" - Breed exact phenotype requested
- "Genetics Novice" - Use Punnett square correctly 5 times

**Mid Achievements:**

- "Rare Breed" - Create dragon with 3+ rare traits
- "Expansion" - Own 3+ facilities
- "Wealthy" - Earn $10,000 total
- "Matchmaker" - Complete 20 orders

**Late Achievements:**

- "Perfect Pedigree" - Breed 5-generation champion line
- "Living Legend" - Keep dragon alive 20+ seasons
- "Genetics Master" - Correctly predict 50 offspring genotypes
- "Tycoon" - Earn $100,000 total

---

## Multiplayer Trading

### Connection System

**Ranch Code:** Each player gets a unique 6-icon code

- Example: 🌸🔥🏔️🌊⭐🐉
- Easy to share via text/email
- Players enter code to connect ranches

### Trading Features

#### 1. Dragon Trading

- Offer dragon for sale
- Set price or "make offer"
- Other player can accept/counter
- Dragon transfers between ranches

#### 2. Egg Sales

- Sell unhatched eggs
- Buyer sees parent genotypes
- Cheaper than adult dragons
- Good for bloodline trading

#### 3. Breeding Arrangements

- "Stud Service" - use another player's dragon for breeding
- Fee negotiated
- Each player keeps 1 offspring
- Expands genetic diversity

#### 4. Gift Dragons

- Send dragon as gift (no payment)
- Good for helping new players
- Builds community

### Trading Hub (Optional)

**Global Market** (If we implement)

- Post dragons for sale publicly
- Browse other ranches' offerings
- Filter by traits/price
- Reputation affects trustworthiness

**Private Trades Only** (Simpler MVP)

- Only trade with friends via ranch code
- No public marketplace
- Reduces moderation needs

---

## Controls & Interface

### Main Ranch View

```
+--------------------------------------------------+
| [$5,420]  [⭐ Rep: Expert]  [🍖 Food: 230]       |
+--------------------------------------------------+
|                                                   |
|         [RANCH VIEW - Scrollable]                |
|    Dragons wandering, facilities visible        |
|    Click dragon → Details panel                  |
|    Click facility → Manage panel                 |
|                                                   |
+--------------------------------------------------+
| [📋 Orders] [🧬 Breed] [🏗️ Build] [⏩ Speed Up]  |
+--------------------------------------------------+
```

### Dragon Details Panel

```
+----------------------------+
| Ember [♀ Adult, Age 8]    |
| [Animated Dragon Sprite]   |
|                            |
| Genotype:                  |
| Fire: Ff (Fire)            |
| Wings: ww (Vestigial)      |
| Armor: Aa (Heavy)          |
|                            |
| Health: ████████░░ 80%     |
| Happy:  ██████░░░░ 60%     |
|                            |
| Parents: Blaze × Smokey    |
| Children: 3 (view tree)    |
|                            |
| [Breed] [Sell] [Train]     |
+----------------------------+
```

### Breeding Interface

```
+----------------------------------------+
| SELECT BREEDING PAIR                   |
+----------------------------------------+
| Parent A:  [Ember ♀]  [Change]        |
|   Ff ww Aa                             |
|                                        |
| Parent B:  [Ash ♂]    [Change]        |
|   ff WW aa                             |
+----------------------------------------+
| [🧬 Show Punnett Square]              |
|                                        |
| Predicted Offspring:                   |
| - 50% Fire, 50% Smoke                 |
| - 100% Vestigial wings                |
| - 100% Intermediate armor             |
|                                        |
| Expected eggs: 1-2                     |
| Incubation time: 2 seasons            |
|                                        |
| [Breed Now] ($50 fee)                 |
+----------------------------------------+
```

### Punnett Square Tool (Optional Helper)

```
+-------------------------+
| Fire Trait (F/f)        |
+-------------------------+
|        F      f         |
|    +------+------+      |
|  f | Ff   | ff   |      |
|    | 50%  | 50%  |      |
|    +------+------+      |
|                         |
| Show: [Fire] [Wings]    |
|       [Armor] [All]     |
+-------------------------+
```

### Orders Board

```
+-----------------------------------+
| AVAILABLE ORDERS                  |
+-----------------------------------+
| [URGENT] Fire-breathing dragon    |
| Pays: $150  Due: 2 seasons       |
| Required: F_                      |
| [Accept] [Details]                |
+-----------------------------------+
| Large dragon with functional wings|
| Pays: $400  Due: 5 seasons       |
| Required: (SS__ or S_G_) and WW  |
| [Accept] [Details]                |
+-----------------------------------+
| [BREEDING] Use my dragon          |
| Pays: $250 + 1 offspring         |
| Brings: ff WW aa male            |
| [Accept] [Details]                |
+-----------------------------------+
| [Refresh Orders] (1/season)       |
+-----------------------------------+
```

---

## Technical Architecture

### Scene Structure (StoryRoom Pattern)

```
DragonRanch (Node2D) - Main scene
├── Environment (Node2D)
│   ├── Background (Parallax layers)
│   ├── Ground (TileMap or sprite)
│   └── Decorations (trees, rocks, etc)
├── Facilities (Node2D)
│   └── (instances of various facility scenes)
├── Dragons (Node2D)
│   └── (instances of Dragon.tscn)
├── Camera2D (for scrolling)
└── CanvasLayer (UI)
	├── TopBar (money, reputation, food)
	├── OrdersPanel
	├── BreedingPanel
	├── DragonDetailsPanel
	└── BuildMenu
```

### AutoLoad Singletons

**RanchState.gd** (Like EcosystemState)

gdscript

```gdscript
extends Node

signal dragon_born(dragon_id: int)
signal dragon_died(dragon_id: int)
signal order_completed(order_id: int, payment: int)
signal season_changed(season: int)
signal reputation_increased(new_level: int)

var current_season: int = 1
var money: int = 500  # Starting cash
var reputation: int = 0
var food_supply: int = 100

var dragons: Dictionary = {}  # dragon_id -> dragon data
var facilities: Dictionary = {}  # facility_id -> facility data
var active_orders: Array = []
var completed_orders: Array = []

func start_new_game() -> void
func save_game() -> Dictionary
func load_game(data: Dictionary) -> void
func advance_season() -> void
```

**GeneticsEngine.gd** (Replaces GeneticsState)

gdscript

```gdscript
extends Node

func breed_dragons(parent_a: Dictionary, parent_b: Dictionary) -> Dictionary:
	# Returns offspring genotype
	var offspring = {}
	
	# For each trait, randomly select one allele from each parent
	for trait in TRAITS:
		var from_a = parent_a[trait][randi() % 2]
		var from_b = parent_b[trait][randi() % 2]
		offspring[trait] = [from_a, from_b]
	
	return offspring

func calculate_phenotype(genotype: Dictionary) -> Dictionary:
	# Convert genotype to visible traits
	pass

func generate_punnett_square(parent_a: Dictionary, parent_b: Dictionary, trait: String) -> Array:
	# Returns 2x2 or 4x4 grid for visualization
	pass
```

**TraitConstants.gd** (Like EcosystemConstants)

gdscript

```gdscript
extends Node

const TRAITS = {
	"fire": {
		"alleles": ["F", "f"],
		"dominance": "F",  # F is dominant
		"phenotypes": {
			"FF": "fire",
			"Ff": "fire",
			"ff": "smoke"
		},
		"unlock_reputation": 0  # Available from start
	},
	"wings": {
		"alleles": ["w", "W"],
		"dominance": "w",  # Vestigial dominant (teaching moment)
		"phenotypes": {
			"ww": "vestigial",
			"wW": "vestigial",
			"WW": "functional"
		},
		"unlock_reputation": 0
	},
	# ... more traits
}
```

**OrderGenerator.gd**

gdscript

```gdscript
extends Node

func generate_orders(reputation_level: int) -> Array:
	# Create 3-5 orders appropriate for player level
	var orders = []
	
	# Simple orders
	if reputation_level >= 0:
		orders.append(_create_simple_order())
	
	# Complex orders unlock at higher levels
	if reputation_level >= 2:
		orders.append(_create_complex_order())
	
	return orders

func _create_simple_order() -> Dictionary:
	return {
		"id": _next_order_id(),
		"type": "simple",
		"required_traits": {"fire": "F_"},
		"payment": 150,
		"deadline": 3,  # seasons
		"description": "Need a fire-breathing dragon"
	}
```

### Dragon Data Structure

gdscript

```gdscript
{
	"id": 0,
	"name": "Ember",
	"sex": "female",  # for sex-linked traits later
	"genotype": {
		"fire": ["F", "f"],
		"wings": ["w", "W"],
		"armor": ["A", "a"]
		# More traits added as unlocked
	},
	"phenotype": {
		"fire": "fire",
		"wings": "vestigial",
		"armor": "heavy"
	},
	"age": 8,  # in seasons
	"life_stage": "adult",  # egg, hatchling, juvenile, adult, elder
	"health": 85,
	"happiness": 70,
	"training": 0,
	"parent_a_id": 1,
	"parent_b_id": 2,
	"children_ids": [5, 7, 12],
	"born_season": 3,
	"facility_id": 4  # which facility they're in
}
```

### Save System (localStorage for web)

gdscript

```gdscript
# save_data.json structure
{
	"version": "1.0",
	"current_season": 15,
	"money": 5420,
	"reputation": 2,
	"food": 230,
	"dragons": [...],
	"facilities": [...],
	"active_orders": [...],
	"unlocked_traits": ["fire", "wings", "armor", "color"],
	"achievements": [...],
	"settings": {
		"auto_feed": true,
		"animation_speed": 1.0
	}
}
```

---

## Development Plan

### Phase 1: Core MVP (4-6 weeks)

**Week 1-2: Foundation**

- [ ]  RanchState singleton
- [ ]  GeneticsEngine with basic traits (Fire, Wings, Armor)
- [ ]  Dragon.tscn with animations
- [ ]  Basic ranch view (scrollable area)
- [ ]  Dragon lifecycle (egg → adult)

**Week 3-4: Breeding**

- [ ]  Breeding interface
- [ ]  Egg incubation system
- [ ]  Genotype → Phenotype rendering
- [ ]  Basic Punnett square tool
- [ ]  Time progression (seasons)

**Week 5-6: Economy**

- [ ]  Order system (simple orders only)
- [ ]  Order board UI
- [ ]  Fulfill order mechanic
- [ ]  Money & food management
- [ ]  2-3 basic facilities

**MVP Deliverable:** Can breed dragons, fulfill simple orders, buy basic facilities

---

### Phase 2: Content & Polish (3-4 weeks)

**Week 7-8: Progression**

- [ ]  Reputation system
- [ ]  Unlock new traits (Color with incomplete dominance)
- [ ]  More facility types
- [ ]  Dragon aging & lifespan
- [ ]  Elder mechanics

**Week 9-10: UI/UX**

- [ ]  Improved dragon details panel
- [ ]  Pedigree viewer (family tree)
- [ ]  Achievement system
- [ ]  Tutorial/onboarding
- [ ]  Sound effects & music

**Deliverable:** Full progression system, polished UI, playable for 2-3 hours

---

### Phase 3: Advanced Genetics (2-3 weeks)

**Week 11-12: Complex Traits**

- [ ]  Size (multiple genes)
- [ ]  Metabolism (trade-offs)
- [ ]  Docility (multiple alleles)
- [ ]  More complex orders

**Week 13 (Optional): Very Advanced**

- [ ]  Linked traits
- [ ]  Sex-linked traits
- [ ]  Codominance patterns

**Deliverable:** Deep genetics for engaged players

---

### Phase 4: Multiplayer (2-3 weeks)

**Week 14-15: Trading**

- [ ]  Ranch code system
- [ ]  Connect to friend's ranch
- [ ]  Trade dragons
- [ ]  Breeding arrangements

**Week 16 (Optional): Tournaments**

- [ ]  Battle arena mechanics
- [ ]  Asynchronous tournaments
- [ ]  Leaderboards

**Deliverable:** Social features, extended gameplay

---

## Success Criteria

### Technical

- [ ]  Runs smoothly in browser (30+ FPS)
- [ ]  Save/load works reliably
- [ ]  Genetics calculations are accurate
- [ ]  No major bugs

### Gameplay

- [ ]  Players understand basic genetics after 30 minutes
- [ ]  Breeding → order → profit loop is satisfying
- [ ]  Progression feels meaningful
- [ ]  Can play for 5+ hours without running out of goals

### Educational

- [ ]  Players can predict offspring without Punnett square (after practice)
- [ ]  Understanding genetics = tangible advantage (earn more, faster)
- [ ]  Advanced concepts (codominance, etc) feel like natural progressions

---

## Future Expansion Ideas

**Post-Launch Content:**

- Seasonal events (holiday-themed dragons)
- Contest system (beauty contests, races, battles)
- Biome expansion (different ranch environments)
- Dragon equipment (saddles, armor that affect stats)
- Mutation system (rare random alleles)
- Cross-breeding with wild dragons
- Retirement home (for beloved elder dragons)
