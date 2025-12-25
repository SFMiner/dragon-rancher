# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Dragon Ranch is a dragon breeding tycoon game built with Godot 4.5. Players breed dragons with Mendelian genetics, fulfill customer orders, and build their ranch empire. The game features a deterministic genetics engine, progression system, save/load functionality, and facility management.

**Key Traits:**
- Signal-based architecture for decoupled systems
- Data-driven design (all content in JSON configs)
- Deterministic gameplay via seedable RNG
- Pure logic modules for testability
- Comprehensive autoload singleton system

## Development Commands

### Running the Game
```bash
# Open project in Godot 4.5+
godot .

# Run the game
# Press F5 in Godot Editor
```

### Running Tests
```bash
# Windows: Run all tests
tests\run_all_tests.bat

# Unix/Linux/Mac: Run all tests
./tests/run_all_tests.sh

# Run individual test suite
godot --headless --script tests/genetics/test_breeding.gd
godot --headless --script tests/lifecycle/test_lifecycle.gd
godot --headless --script tests/ranch_state/test_ranch_state.gd
```

### Exporting Builds
Use Godot Editor: Project > Export
Export presets are configured in `project.godot`

## Critical Architecture

### Autoload Singleton Order (LOCKED)

The autoloads MUST be registered in this exact order due to dependencies. See `docs/API_Reference.md` for full API documentation.

1. **RNGService** - Deterministic randomness (no dependencies)
2. **TraitDB** - Trait definitions database (no dependencies)
3. **GeneticsEngine** - Breeding logic (depends on RNGService, TraitDB)
4. **RanchState** - Central game state (depends on GeneticsEngine)
5. **OrderSystem** - Order generation (depends on TraitDB, GeneticsEngine)
6. **SaveSystem** - Persistence (depends on RanchState)
7. **AudioManager** - Sound management (subscribes to RanchState signals)
8. **TutorialService** - Tutorial system (subscribes to RanchState signals)

### API Stability

The interfaces in `docs/API_Reference.md` are **LOCKED**. Any changes require:
1. Architectural review
2. Updates to all dependent systems
3. Documentation updates
4. Migration path for saves (if applicable)

### Key Design Patterns

**Signal-Based Communication:**
- All state changes emit signals
- UI subscribes to signals for updates
- No direct coupling between systems

**Data-Driven Content:**
- Trait definitions: `data/config/trait_defs.json`
- Dragon names: `data/config/names_dragons.json`
- Order templates: `data/config/order_templates.json`
- Facility definitions: `data/config/facility_defs.json`
- Achievements: `data/config/achievements.json`

**Pure Logic Modules:**
- Located in `scripts/rules/`
- Static classes with no side effects
- Testable independently of game state
- Examples: Lifecycle, GeneticsResolvers, OrderMatching, Pricing, Progression

**Resource-Based Data:**
- All data classes extend `Resource`
- Implement `to_dict()` and `from_dict()` for serialization
- Implement `is_valid()` for validation
- Located in `scripts/data/`

## File Organization

```
dragon-rancher/
├── data/config/          # JSON configuration (traits, orders, facilities, etc.)
├── scripts/
│   ├── autoloads/        # Singleton services (8 autoloads in specific order)
│   ├── rules/            # Pure logic modules (static utility classes)
│   ├── entities/         # Entity controllers (Dragon.gd, Egg.gd)
│   ├── ui/               # UI scripts (HUD, panels)
│   ├── data/             # Resource classes (DragonData, OrderData, etc.)
│   └── util/             # Utilities (IdGen)
├── scenes/
│   ├── entities/         # Entity scenes (dragon/, egg/)
│   └── ui/               # UI scenes (HUD, panels)
├── tests/                # Unit tests grouped by domain
│   ├── genetics/         # 19 genetics tests
│   ├── lifecycle/        # 6 lifecycle tests
│   ├── ranch_state/      # 3 ranch state test suites
│   └── progression/      # 1 progression test suite
├── assets/               # Audio and art assets
└── docs/                 # Technical documentation
```

## Coding Conventions

### GDScript Style
- **Typed GDScript**: Always use type hints
- **Indentation**: Tabs (Godot default)
- **Line endings**: LF (enforced by `.gitattributes`)
- **Naming**:
  - `snake_case`: functions, variables, signals
  - `PascalCase`: classes, resources, scenes
  - Signal names: verb-based (`dragon_bred`, `order_fulfilled`, `season_changed`)

### State Management
- **Never modify state directly** - Always use RanchState methods
- **Always emit signals** after state changes
- **Null checks**: All getters return `null` for not-found items
- **Validation**: Use `is_valid()` before processing data
- **Error handling**: Use `push_warning()` for recoverable issues, `push_error()` for critical failures

### Testing
- **Deterministic RNG**: Always seed RNG via `RNGService.set_seed()` in tests
- **Assert both genotype and phenotype** outcomes
- **Fast tests**: No scene instancing unless required
- **Test location**: Mirror structure in `tests/<domain>/test_<feature>.gd`

### Data-Driven First
- Extend JSON configs instead of hardcoding values
- Expose data through TraitDB/RanchState APIs
- Keep logic and data separate

## Common Workflows

### Adding a New Trait
1. Add trait definition to `data/config/trait_defs.json`
2. Update `TraitDB` constants if needed
3. Add normalization rules to `GeneticsResolvers` if complex
4. Update tests to cover new trait
5. Add to reputation unlock tier in progression system

### Adding a New Order Template
1. Add template to `data/config/order_templates.json`
2. Include requirements (genotype patterns, phenotypes, life stage)
3. Set base payment and reputation level
4. Test matching logic with `OrderMatching.does_dragon_match()`

### Adding a New Facility
1. Add definition to `data/config/facility_defs.json`
2. Include cost, capacity, bonuses, reputation requirement
3. Update UI to display new facility in BuildPanel
4. Add visual representation to Ranch scene

### Modifying RanchState
1. **WARNING**: RanchState API is LOCKED
2. Consult `docs/API_Reference.md` first
3. If changes needed, discuss architectural impact
4. Update SaveSystem serialization
5. Implement save migration if breaking change

## Key Systems Reference

### Genetics Engine
- **Breeding**: `GeneticsEngine.breed_dragons(parent_a, parent_b)`
- **Phenotype**: `GeneticsEngine.calculate_phenotype(genotype)`
- **Predictions**: `GeneticsEngine.predict_offspring(parent_a, parent_b)`
- **Validation**: `GeneticsEngine.validate_genotype(genotype)`

### RanchState (Central Game State)
- **Dragons**: `add_dragon()`, `remove_dragon()`, `get_adult_dragons()`
- **Eggs**: `create_egg()`, `hatch_egg()`, `get_all_eggs()`
- **Resources**: `add_money()`, `spend_money()`, `add_food()`, `consume_food()`
- **Time**: `advance_season()`, `can_advance_season()`
- **Orders**: `accept_order()`, `fulfill_order()`, `remove_order()`
- **Facilities**: `build_facility()`, `get_facility_bonus()`

### Save System
- **Save format**: JSON (version 1, documented in `docs/Save_Format_v1.md`)
- **Location**: `user://savegame_v1.json` (IndexedDB on web)
- **Autosave**: Configurable via `SaveSystem.enable_autosave(interval)`
- **Backup**: Auto-backup created before overwrite
- **Export**: `export_save_string()` for manual backup

### Order System
- **Generation**: `OrderSystem.generate_orders(reputation_level)`
- **Matching**: `OrderMatching.does_dragon_match(dragon, order)`
- **Payment**: `Pricing.calculate_payment(order, dragon)`
- **Patterns**: Genotype patterns like `F_`, `FF`, `Ff` supported

## Documentation Reference

- **`docs/API_Reference.md`**: Complete API documentation (LOCKED interfaces)
- **`docs/Genetics_Normalization_Rules.md`**: Genotype normalization rules
- **`docs/Save_Format_v1.md`**: Save file format specification
- **`PROJECT_STRUCTURE.md`**: Detailed directory structure
- **`IMPLEMENTATION_STATUS.md`**: Current implementation status
- **`AGENTS.md`**: Repository guidelines for AI agents

## Session Reports

Session reports (`SESSION_*.md` and `SESSION_*_COMPLETE.md`) document development history and contain valuable context about implementation decisions. Consult recent session reports when working on related systems.

## Important Notes

- **Deterministic RNG**: All randomness flows through RNGService for reproducibility
- **No direct file I/O**: Use SaveSystem for persistence
- **Signal subscriptions**: Connect to RanchState signals in `_ready()`
- **UI updates**: Always react to signals, never poll state
- **Testing first**: Add tests for new features before implementation
- **JSON configs**: All player-facing content in data/config/
- **Locked APIs**: Check docs/API_Reference.md before modifying autoloads
- **ParentSelectPopup sizing**: Width clamp includes a +20 padding tweak for long genotype strings.
- **ParentSelectPopup genotype display**: Use a single concatenated allele string with no delimiters.
