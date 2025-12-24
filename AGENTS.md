# Repository Guidelines

## Project Structure & Module Organization
- Core logic lives in `scripts/` (`autoloads` singletons for RNG/TraitDB/GeneticsEngine/State, `rules` for pure utilities, `entities`/`ranch`/`menus` for gameplay and UI flows).
- Scenes are under `scenes/` (`entities` for dragons/eggs, `ui` for HUD and panels); data files are in `data/config/` (traits, names, orders, facilities, achievements JSON).
- Tests reside in `tests/` grouped by domain (`genetics`, `lifecycle`, `ranch_state`, `progression`, `save_system`); runners in `tests/run_all_tests.*`.
- Assets (audio, art) live in `assets/`; docs and design notes are in `docs/` plus session reports and `PROJECT_STRUCTURE.md`/`IMPLEMENTATION_STATUS.md` at repo root.

## Build, Test, and Development Commands
- Open and run in Godot 4.5+: `godot .` then F5 to play; keep `project.godot` autoload paths intact.
- Run all scripted tests (Windows): `tests\run_all_tests.bat`; individual suites: `godot --headless --script tests/genetics/test_breeding.gd` (replace path per suite).
- Export builds via Godot Editor’s Project > Export; add new export presets to `project.godot` rather than custom scripts.

## Coding Style & Naming Conventions
- Use typed GDScript; match existing indentation (tabs, Godot default) and LF line endings (`.gitattributes` enforces).
- Snake_case for functions/variables, PascalCase for classes/resources/scenes; keep signal names verb-based (`dragon_bred`, `order_fulfilled`).
- Keep pure logic stateless inside `scripts/rules`; use autoloads for shared state/services; favor `push_error/push_warning` over bare prints unless in debug mode.
- Data-driven first: extend JSON in `data/config/` and expose keys via TraitDB/RanchState instead of hardcoding.

## Testing Guidelines
- Mirror current pattern: place new suites as `tests/<domain>/test_<feature>.gd` and make them runnable via `godot --headless --script ...`.
- Seed RNG deterministically through `RNGService` in tests; assert both genotype and phenotype outcomes to avoid regressions.
- When adding features that touch state, include lifecycle/progression coverage and keep tests fast (no scene instancing unless required).

## Commit & Pull Request Guidelines
- Follow existing concise, present-tense messages (e.g., `Add music and money_start.ogg`, `Session 15 done`). One feature/fix per commit when possible.
- PRs should describe gameplay impact and touched systems (autoloader, data config, UI); link any tracking issue or session doc.
- Include test evidence: command used and pass result. Add short notes or screenshots if UI changes affect HUD/panels.

## Latest Changes
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
