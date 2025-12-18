# Dragon Ranch - Project Structure

## Directory Layout

```
dragon-rancher/
├── data/
│   └── config/
│       └── trait_defs.json          # Trait definitions (Fire, Wings, Armor)
│
├── scripts/
│   ├── autoloads/                   # Singleton services
│   │   ├── RNGService.gd            # Seedable random number generator
│   │   ├── TraitDB.gd               # Trait database manager
│   │   └── GeneticsEngine.gd        # Core genetics & breeding logic
│   │
│   ├── rules/                       # Static utility classes
│   │   └── GeneticsResolvers.gd     # Genetics normalization & validation
│   │
│   ├── dragon_data.gd               # DragonData resource class
│   ├── egg_data.gd                  # EggData resource class
│   ├── facility_data.gd             # FacilityData resource class
│   ├── order_data.gd                # OrderData resource class
│   ├── trait_def.gd                 # TraitDef resource class
│   └── tutorial_step.gd             # TutorialStep resource class
│
├── tests/
│   ├── genetics/
│   │   ├── test_breeding.gd         # Breeding logic tests (6 tests)
│   │   ├── test_phenotype.gd        # Phenotype calculation tests (6 tests)
│   │   └── test_normalization.gd    # Normalization utility tests (7 tests)
│   │
│   ├── run_all_tests.sh             # Unix test runner
│   └── run_all_tests.bat            # Windows test runner
│
├── SESSION_2.md                     # Session 2 plan (genetics engine)
├── SESSION_2_COMPLETE.md            # Session 2 completion report
├── Dragon-Ranch_GDD-v1.0.md         # Game design document
├── project.godot                    # Godot project configuration
└── icon.svg                         # Project icon
```

## Session Completion Status

### ✅ Session 1: Architecture & Data Structures
- DragonData resource class
- TraitDef resource class
- EggData, FacilityData, OrderData resource classes
- TutorialStep resource class

### ✅ Session 2: Core Genetics Engine
- RNGService autoload
- TraitDB autoload
- GeneticsEngine autoload
- GeneticsResolvers utility class
- Trait definitions JSON
- Comprehensive unit tests (19 tests total)

### ✅ Session 3: Dragon Entities & Lifecycle
- Lifecycle rules module
- IdGen utility (ID and name generation)
- Dragon entity scene and controller
- Egg entity scene and controller
- Interactive test scene
- Lifecycle unit tests (6 tests)
- 170+ dragon names database

### 🔲 Session 4: Ranch State & UI (Planned)
- RanchState management
- Season progression
- UI framework
- Basic economy

### 🔲 Session 5: Advanced Features (Planned)
- Order system
- Facility management
- Save/load system

## Autoload Configuration

Registered in `project.godot`:

1. **RNGService** - `scripts/autoloads/RNGService.gd`
2. **TraitDB** - `scripts/autoloads/TraitDB.gd`
3. **GeneticsEngine** - `scripts/autoloads/GeneticsEngine.gd`
4. **IdGen** - `scripts/util/IdGen.gd`

## Testing

Run all tests:
```bash
# Unix/Linux/Mac
./tests/run_all_tests.sh

# Windows
tests\run_all_tests.bat
```

Run individual test suites:
```bash
godot --headless --script tests/genetics/test_breeding.gd
godot --headless --script tests/genetics/test_phenotype.gd
godot --headless --script tests/genetics/test_normalization.gd
```

## Key Files by Purpose

### Genetics System
- `scripts/autoloads/GeneticsEngine.gd` - Breeding & phenotype calculation
- `scripts/autoloads/TraitDB.gd` - Trait management
- `scripts/rules/GeneticsResolvers.gd` - Utilities
- `data/config/trait_defs.json` - Trait definitions

### Data Models
- `scripts/dragon_data.gd` - Dragon storage & serialization
- `scripts/trait_def.gd` - Trait definition storage

### Randomness
- `scripts/autoloads/RNGService.gd` - Deterministic RNG

### Testing
- `tests/genetics/` - Unit tests for genetics system
- `tests/run_all_tests.*` - Test runners

## Current Capabilities

The game can currently:

**Genetics System (Session 2)**
- ✅ Load trait definitions from JSON
- ✅ Generate random dragon genotypes
- ✅ Breed two dragons with Mendelian inheritance
- ✅ Calculate phenotypes from genotypes
- ✅ Generate Punnett squares for breeding predictions
- ✅ Validate genotypes
- ✅ Format genetics data for display
- ✅ Save/load RNG state for reproducibility

**Lifecycle System (Session 3)**
- ✅ Age dragons through life stages (hatchling → juvenile → adult → elder)
- ✅ Calculate breeding eligibility based on life stage
- ✅ Determine lifespan (base + trait modifiers)
- ✅ Stage-specific visual scaling and behavior modifiers
- ✅ Track age progression with automatic stage transitions

**Entity System (Session 3)**
- ✅ Spawn dragons with visual representation
- ✅ Simple wandering AI behavior
- ✅ Click detection and interaction
- ✅ Spawn eggs with incubation timers
- ✅ Hatch eggs into dragons
- ✅ Generate unique IDs and random names
- ✅ Placeholder sprite generation based on phenotype

**Testing**
- ✅ 19 genetics unit tests (breeding, phenotype, normalization)
- ✅ 6 lifecycle unit tests (stages, aging, breeding, lifespan)
- ✅ Interactive test scene for visual testing

## Next Session Focus

**Session 4** should implement:
1. RanchState autoload for global game state
2. Season progression system (automatic time advancement)
3. Dragon and egg collection management
4. Basic UI framework (HUD, panels, buttons)
5. Ranch view with camera controls
6. Simple economy (money, food tracking)

This will transform the test scene into an actual playable game.
