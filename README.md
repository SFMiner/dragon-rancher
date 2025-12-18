# Dragon Ranch

## Project Overview
Dragon Ranch is a dragon breeding tycoon game built with Godot 4.5. Players breed dragons with Mendelian genetics, fulfill customer orders, and build their dragon ranch empire.

## Features

### Core Systems Implemented:
- **Genetics Engine**: Seedable random number generation, trait database, breeding and phenotype calculation, genotype normalization utilities. (3 MVP traits: Fire, Wings, Armor)
- **Dragon Entities & Lifecycle**: Age progression, life stages, unique ID and name generation, visual dragon entities with AI, incubating egg entities with progress bars. (170+ dragon names)
- **RanchState & Time System**: Central game state management, dragon and egg management, resource management (money, food), season advancement, game initialization with starter dragons.
- **Save System**: JSON-based save/load with version management, backup system, configurable autosave, full state serialization.
- **Order System**: Pattern-based requirement matching, dynamic payment calculation, reputation-based order generation, order lifecycle (accept, fulfill, expire).
- **Facility System**: 6 facility types (Stable, Pasture, Nursery, Luxury Habitat, Breeding Pen, Genetics Lab) with capacity expansion, bonuses (happiness, breeding success, growth speed, genotype reveal), and reputation requirements.
- **Progression System**: 5 reputation levels (Novice to Legendary) based on lifetime earnings, 8 achievements with automatic checking, framework for new trait unlocking.
- **UI Foundation**: Basic layouts and scripts for HUD (money, food, season, reputation), Orders Panel, Breeding Panel, Dragon Details Panel, Build Panel, and Notifications Panel. HUD updates in real-time, and notifications provide visual feedback.

## Getting Started

### Installation
1.  Clone the repository: `git clone https://github.com/your-username/dragon-rancher.git` (Replace with actual repo URL)
2.  Open the project in Godot Engine 4.5 or later.

### How to Play
(Detailed instructions on how to start a new game, interact with the UI, breed dragons, fulfill orders, and build facilities will be added here as the UI is completed.)

## Project Structure
The project follows a modular structure, with core logic separated from entities and UI. For a detailed breakdown, refer to `PROJECT_STRUCTURE.md`.

### Key Directories:
- `data/config/`: JSON configuration files for traits, names, orders, facilities, and achievements.
- `scripts/autoloads/`: Global singletons for core game systems (RNG, TraitDB, GeneticsEngine, RanchState, SaveSystem, OrderSystem).
- `scripts/rules/`: Pure logic modules for game mechanics (Lifecycle, GeneticsResolvers, OrderMatching, Pricing, Progression).
- `scripts/entities/`: Scripts for Dragon and Egg entities.
- `scripts/ui/`: Scripts for UI elements (HUD, panels).
- `scenes/entities/`: Godot scenes for Dragon and Egg entities.
- `scenes/ui/`: Godot scenes for UI elements (HUD, panels).
- `tests/`: Unit tests for various game systems.

## Testing Coverage
The project has extensive unit testing for core systems:
- **Genetics**: 19 unit tests
- **Lifecycle**: 6 unit tests
- **RanchState**: 3 comprehensive test suites
- **Progression**: 1 test suite
- Manual testing for Save System, Order System, and Facility System.

## Future Enhancements

### Planned Features:
- Add 5 more traits (color, size, metabolism, docility, temperament).
- Multiple save slots and cloud save support.
- Dragon sprite variations based on phenotype.
- Animations for breeding, hatching, fulfillment.
- Sound effects and background music.
- Tutorial system.
- Achievement notifications and rewards.
- Statistics screen (total earnings, dragons bred, etc.).
- Dragon family tree viewer.

### Current Limitations:
- Placeholder dragon sprites.
- No sound effects or music.
- No animations.
- Some achievements require manual tracking.

## Technical Notes

### Design Principles:
- **Deterministic Gameplay**: Uses seedable RNG for reproducible results, aiding debugging and testing.
- **Data-Driven Design**: All game content defined in JSON files for easy modification and expansion.
- **Signal-Based Architecture**: Decoupled systems communicate via signals for maintainability and flexibility.
- **Pure Logic Modules**: Core logic in static classes, testable independently of game state.

## License
(License information will be added here.)

## Credits
(Credits for assets, contributors, etc., will be added here.)
