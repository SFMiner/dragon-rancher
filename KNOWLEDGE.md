---
type: knowledge
domain: coding
status: living
tags: [dragon-rancher, godot]
created: 2026-10-07
updated: 2026-10-07
---
# KNOWLEDGE — Dragon Rancher (cold reference)

Cold reference for Dragon Rancher, moved out of the hot CLAUDE.md on 2026-10-07. Read on demand.

## Project overview

Dragon Ranch is a dragon breeding tycoon game built with Godot 4.5. Players breed dragons with Mendelian genetics, fulfill customer orders, and build their ranch empire. The game features a deterministic genetics engine, progression system, save/load functionality, and facility management.

**Key Traits:**
- Signal-based architecture for decoupled systems
- Data-driven design (all content in JSON configs)
- Deterministic gameplay via seedable RNG
- Pure logic modules for testability
- Comprehensive autoload singleton system

## Autoload singleton order

The autoloads MUST be registered in this exact order due to dependencies. See `docs/API_Reference.md` for full API documentation.

1. **RNGService** - Deterministic randomness (no dependencies)
2. **TraitDB** - Trait definitions database (no dependencies)
3. **GeneticsEngine** - Breeding logic (depends on RNGService, TraitDB)
4. **RanchState** - Central game state (depends on GeneticsEngine)
5. **OrderSystem** - Order generation (depends on TraitDB, GeneticsEngine)
6. **SaveSystem** - Persistence (depends on RanchState)
7. **AudioManager** - Sound management (subscribes to RanchState signals)
8. **TutorialService** - Tutorial system (subscribes to RanchState signals)

Note (checked 2026-10-07 against `project.godot`): the actual registered order is RNGService, TraitDB, GeneticsEngine, IdGen, RanchState, SaveSystem, OrderSystem, AudioManager, TutorialService, SceneManager. So IdGen and SceneManager are also autoloads, and SaveSystem sits before OrderSystem; the list above is out of date.

## Key design patterns

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

## File organization

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

Also (from the old AGENTS.md section): gameplay and UI flows live in `scripts/` under `entities`/`ranch`/`menus`; tests also include a `save_system` domain; docs and design notes are in `docs/` plus session reports and `IMPLEMENTATION_STATUS.md` at repo root. (`PROJECT_STRUCTURE.md` is referenced by the old CLAUDE.md but does not exist on disk as of 2026-10-07.)

## Common workflows

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

## Key systems reference

### Genetics Engine
- **Breeding**: `GeneticsEngine.breed_dragons(parent_a, parent_b)`
- **Phenotype**: `GeneticsEngine.calculate_phenotype(genotype)`
- **Predictions**: `GeneticsEngine.generate_punnett_square(parent_a, parent_b, trait_key)` /
  `generate_full_punnett_square(parent_a, parent_b)`
- **Validation**: `TraitDB.validate_genotype(genotype)`
- **Shared genome addon:** the Mendelian math (meiosis, crosses, single-locus phenotype lookup, Punnett) lives in `addons/genome/` (vendored copy of `../genome-engine`, https://github.com/SFMiner/genome-engine). Rancher-only rules stay in `GeneticsEngine`: which loci breed (reputation unlocks), the size_S/size_G polygenic size, and the color×hue×pattern epistasis.

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

## Documentation and session reports

- `PROJECT_STRUCTURE.md`: detailed directory structure (missing on disk, 2026-10-07)
- `IMPLEMENTATION_STATUS.md`: current implementation status
- Session reports (`SESSION_*.md` and `SESSION_*_COMPLETE.md`) document development history and contain valuable context about implementation decisions. Consult recent session reports when working on related systems.

## Latest changes (as recorded in the old AGENTS.md section)
- Dragons are hermaphrodites (no male/female split).
- Fixed W/wingless allele so functional wings are not treated as dominant.
- Added a theme.
- OrdersPanel randomizes better.
- BreedingPanel allows selecting the dragons to breed.
- Added DragonListPanel to show all owned dragons.
- Hatchlings scale up gradually until they're adults.
- Added a Store button to buy food and other items.
- Dragons breed only twice per season, laying 2-6 eggs at a time.
- ParentSelectPopup width clamp includes a +20 padding tweak for long genotype strings.
- ParentSelectPopup genotype display uses a single concatenated allele string with no delimiters.

## Open Questions
- 2026-10-07: the old CLAUDE.md autoload list (8 entries, OrderSystem before SaveSystem) disagrees with `project.godot` (10 autoloads, SaveSystem before OrderSystem). Which is the intended "locked" order? The hot file now points at `project.godot`.
