# CLAUDE.md

Dragon Ranch: dragon breeding tycoon in Godot 4.5 (Mendelian genetics, orders, facilities, save/load). Signal-based, data-driven (JSON configs), deterministic seedable RNG.

Cold reference (architecture, systems, history): `KNOWLEDGE.md` in this folder.

## Commands

```bash
godot .                       # open project; F5 to run
tests\run_all_tests.bat       # Windows, all tests (set GODOT=..\Godot_v4.5-stable_win64.exe if godot not on PATH)
./tests/run_all_tests.sh      # Unix/Linux/Mac
godot --headless --path . --script tests/genetics/test_breeding.gd   # one suite (exit 0 = pass, 1 = fail)
```
- Suites `extend SceneTree` and, because autoloads are not global identifiers in `--script` mode, declare `var RanchState: Node = null` etc. (shadowing the autoload name) and bind them in `_init()` after `await get_root().ready` with `root.get_node("/root/RanchState")`.
- A one-time `Identifier not found: TraitDB` compile error at startup is expected noise (script loads once before autoloads register, then again successfully); trust the `Test Results` line and exit code.
- Export via Godot Editor (Project > Export); add new export presets to `project.godot`, not custom scripts. Keep `project.godot` autoload paths intact.

## Critical rules

- **Autoload order is LOCKED** (dependencies). Register in the order in `project.godot`; don't reorder (details: `KNOWLEDGE.md` § Autoload singleton order, which is partly out of date).
- **`docs/API_Reference.md` interfaces are LOCKED** (RanchState API included). Changes require architectural review, updates to all dependents, doc updates, and a save migration path if applicable. Check it before modifying autoloads. Changing RanchState also means updating SaveSystem serialization (details: `KNOWLEDGE.md` § Common workflows).
- **Never edit `addons/genome/`.** It is a vendored copy of `../genome-engine`. Change the engine, then run `bash tools/sync_genome.sh ../dragon-rancher` from genome-engine (details: `KNOWLEDGE.md` § Genetics Engine).
- All randomness flows through `RNGService`. No direct file I/O: use `SaveSystem`.
- Never modify state directly; always use RanchState methods, and always emit signals after state changes.
- Connect to RanchState signals in `_ready()`. UI reacts to signals, never polls state.
- All player-facing content in `data/config/`. Data-driven first: extend JSON configs instead of hardcoding, expose through TraitDB/RanchState APIs, keep logic and data separate.
- Pure logic in `scripts/rules/` stays stateless. Data classes in `scripts/data/` extend `Resource` with `to_dict()`, `from_dict()`, `is_valid()`; use `is_valid()` before processing data.
- All getters return `null` for not-found items.
- Errors: `push_warning()` for recoverable, `push_error()` for critical; favor these over bare prints unless in debug mode.
- Testing first: add tests for new features before implementation.
- **ParentSelectPopup:** width clamp includes a +20 padding tweak for long genotype strings; genotype display is a single concatenated allele string with no delimiters.

## Coding conventions

- Typed GDScript always; tabs; LF line endings (`.gitattributes` enforces).
- `snake_case` functions/variables/signals; `PascalCase` classes/resources/scenes; signal names verb-based (`dragon_bred`, `order_fulfilled`, `season_changed`).
- Layout: `scripts/{autoloads,rules,entities,ui,data,util}`, `scenes/{entities,ui}`, `data/config/`, `tests/<domain>/`, `docs/` (details: `KNOWLEDGE.md` § File organization).

## Testing

- Seed RNG via `RNGService.set_seed()` in tests; assert both genotype and phenotype outcomes.
- Keep tests fast: no scene instancing unless required.
- Place suites at `tests/<domain>/test_<feature>.gd` (domains: genetics, lifecycle, ranch_state, progression, save_system), runnable via `godot --headless --script ...`.
- Features touching state need lifecycle/progression coverage.

## Commits and PRs

- Concise, present-tense messages (e.g. `Add music and money_start.ogg`, `Session 15 done`); one feature/fix per commit when possible.
- PRs describe gameplay impact and touched systems; link tracking issue or session doc; include test command and pass result; add notes or screenshots for UI changes.

## Docs

`docs/API_Reference.md` (locked APIs), `docs/Genetics_Normalization_Rules.md`, `docs/Save_Format_v1.md`, `IMPLEMENTATION_STATUS.md`. Session reports `SESSION_*.md` hold implementation-decision history; consult recent ones when working on related systems. Systems reference, workflows, latest changes: `KNOWLEDGE.md`.
