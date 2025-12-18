# Dragon Ranch - Save Format Specification v1

**Document Version:** 1.0  
**Save Version:** 1  
**Status:** LOCKED - Changes require migration plan

---

## Overview

Dragon Ranch uses JSON-based saves stored via Godot's `FileAccess` to `user://`. On HTML5 exports, this maps to IndexedDB. The format prioritizes human readability, safe defaults, and forward compatibility.

---

## File Locations

| File | Purpose | Platform |
|------|---------|----------|
| `user://savegame_v1.json` | Primary save file | All |
| `user://savegame_v1.bak.json` | Backup (pre-overwrite copy) | All |
| `user://settings.json` | Player settings (separate from game state) | All |

---

## Save File Schema

```json
{
  "save_version": 1,
  "save_timestamp": "2024-01-15T14:30:00Z",
  "playtime_seconds": 3600,
  
  "ranch_state": {
    "current_season": 15,
    "money": 5420,
    "lifetime_earnings": 12500,
    "reputation_level": 2,
    "food_supply": 230,
    "next_dragon_id": 45,
    "next_egg_id": 12,
    "next_facility_id": 8,
    "next_order_id": 30
  },
  
  "dragons": [
    {
      "id": "dragon_001",
      "name": "Ember",
      "sex": "female",
      "genotype": {
        "fire": ["F", "f"],
        "wings": ["w", "W"],
        "armor": ["A", "a"]
      },
      "phenotype": {
        "fire": {"name": "Fire", "sprite_suffix": "fire"},
        "wings": {"name": "Vestigial", "sprite_suffix": "vestigial"},
        "armor": {"name": "Heavy", "sprite_suffix": "heavy"}
      },
      "age": 8,
      "life_stage": "adult",
      "health": 85.0,
      "happiness": 70.0,
      "training": 0.0,
      "parent_a_id": "dragon_002",
      "parent_b_id": "dragon_003",
      "children_ids": ["dragon_010", "dragon_015"],
      "born_season": 7,
      "facility_id": "facility_001"
    }
  ],
  
  "eggs": [
    {
      "id": "egg_001",
      "genotype": {
        "fire": ["F", "f"],
        "wings": ["w", "w"],
        "armor": ["a", "a"]
      },
      "parent_a_id": "dragon_001",
      "parent_b_id": "dragon_004",
      "incubation_seasons_remaining": 2,
      "facility_id": "facility_002",
      "created_season": 14
    }
  ],
  
  "facilities": [
    {
      "id": "facility_001",
      "type": "stable",
      "name": "Main Stable",
      "capacity": 4,
      "bonuses": {},
      "cost": 300,
      "reputation_required": 0,
      "grid_position": {"x": 2, "y": 1}
    }
  ],
  
  "active_orders": [
    {
      "id": "order_015",
      "type": "simple",
      "description": "Local farmer needs a fire-breathing dragon.",
      "required_traits": {"fire": "F_"},
      "payment": 150,
      "deadline_seasons": 3,
      "reputation_required": 0,
      "accepted_season": 14,
      "created_season": 13,
      "is_urgent": false,
      "customer_name": "Farmer Giles"
    }
  ],
  
  "completed_order_ids": ["order_001", "order_002", "order_005"],
  
  "unlocked_traits": ["fire", "wings", "armor", "color"],
  
  "achievements": {
    "first_sale": true,
    "full_house": true,
    "perfect_match": false,
    "rare_breed": false
  },
  
  "statistics": {
    "total_dragons_bred": 42,
    "total_orders_completed": 25,
    "total_eggs_hatched": 38,
    "dragons_sold": 20,
    "dragons_died_naturally": 5,
    "punnett_squares_used": 15
  },
  
  "tutorial_state": {
    "tutorial_enabled": false,
    "current_step_id": "",
    "completed_steps": {
      "tut_01_welcome": true,
      "tut_02_view_dragons": true,
      "tut_03_open_breeding": true
    }
  },
  
  "rng_seed": 12345678
}
```

---

## Field Specifications

### Root Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `save_version` | int | Yes | 1 | Schema version for migrations |
| `save_timestamp` | String | Yes | "" | ISO 8601 timestamp of save |
| `playtime_seconds` | int | No | 0 | Total playtime in seconds |

### ranch_state Object

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `current_season` | int | Yes | 1 | Current game season |
| `money` | int | Yes | 500 | Current money balance |
| `lifetime_earnings` | int | Yes | 0 | Total money ever earned |
| `reputation_level` | int | Yes | 0 | Current reputation (0-4) |
| `food_supply` | int | Yes | 100 | Current food reserves |
| `next_dragon_id` | int | Yes | 1 | Counter for dragon ID generation |
| `next_egg_id` | int | Yes | 1 | Counter for egg ID generation |
| `next_facility_id` | int | Yes | 1 | Counter for facility ID generation |
| `next_order_id` | int | Yes | 1 | Counter for order ID generation |

### dragons Array (DragonData)

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `id` | String | Yes | "" | Unique dragon identifier |
| `name` | String | Yes | "" | Dragon's display name |
| `sex` | String | Yes | "male" | "male" or "female" |
| `genotype` | Dictionary | Yes | {} | trait_key → [allele1, allele2] |
| `phenotype` | Dictionary | Yes | {} | trait_key → phenotype data |
| `age` | int | Yes | 0 | Age in seasons |
| `life_stage` | String | Yes | "hatchling" | Current life stage |
| `health` | float | Yes | 100.0 | Health percentage (0-100) |
| `happiness` | float | Yes | 100.0 | Happiness percentage (0-100) |
| `training` | float | No | 0.0 | Training level (0-100) |
| `parent_a_id` | String | No | "" | First parent's ID |
| `parent_b_id` | String | No | "" | Second parent's ID |
| `children_ids` | Array | No | [] | IDs of offspring |
| `born_season` | int | Yes | 0 | Season when hatched |
| `facility_id` | String | No | "" | Current facility location |

### eggs Array (EggData)

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `id` | String | Yes | "" | Unique egg identifier |
| `genotype` | Dictionary | Yes | {} | Inherited genotype |
| `parent_a_id` | String | Yes | "" | First parent's ID |
| `parent_b_id` | String | Yes | "" | Second parent's ID |
| `incubation_seasons_remaining` | int | Yes | 3 | Seasons until hatching |
| `facility_id` | String | No | "" | Incubation facility |
| `created_season` | int | Yes | 0 | Season when bred |

### facilities Array (FacilityData)

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `id` | String | Yes | "" | Unique facility identifier |
| `type` | String | Yes | "" | Facility type key |
| `name` | String | No | "" | Custom display name |
| `capacity` | int | Yes | 0 | Dragon capacity |
| `bonuses` | Dictionary | No | {} | Bonus type → value |
| `cost` | int | Yes | 0 | Build cost |
| `reputation_required` | int | No | 0 | Unlock requirement |
| `grid_position` | Dictionary | No | {} | {x, y} grid location |

### active_orders Array (OrderData)

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `id` | String | Yes | "" | Unique order identifier |
| `type` | String | Yes | "simple" | Order type |
| `description` | String | Yes | "" | Display text |
| `required_traits` | Dictionary | Yes | {} | trait_key → requirement |
| `payment` | int | Yes | 100 | Base payment amount |
| `deadline_seasons` | int | Yes | 3 | Seasons to complete |
| `reputation_required` | int | No | 0 | Minimum reputation |
| `accepted_season` | int | No | 0 | When accepted (0=pending) |
| `created_season` | int | No | 0 | When generated |
| `is_urgent` | bool | No | false | Urgent flag |
| `customer_name` | String | No | "" | Flavor name |

### tutorial_state Object

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `tutorial_enabled` | bool | Yes | true | Whether tutorial is active |
| `current_step_id` | String | Yes | "" | Current tutorial step |
| `completed_steps` | Dictionary | Yes | {} | step_id → completed bool |

---

## Validation Rules

### On Load

1. **Version Check**: If `save_version` > current supported version, abort with error
2. **Required Fields**: All "Required: Yes" fields must exist
3. **Type Validation**: All fields must match expected types
4. **Reference Validation**: All ID references (parent_a_id, facility_id, etc.) must point to existing entities OR be empty
5. **Range Validation**:
   - `health`, `happiness`, `training`: 0.0 to 100.0
   - `reputation_level`: 0 to 4
   - `money`, `food_supply`: ≥ 0
   - `current_season`, `age`: ≥ 1

### Fallback Behavior

If a non-required field is missing or invalid:
- Use the default value from this specification
- Log a warning (not error)
- Continue loading

If a required field is missing:
- Attempt to load from backup file
- If backup also fails, prompt user to start new game
- Log error with details

---

## Migration System

### Version Detection

```gdscript
func _detect_version(data: Dictionary) -> int:
    return data.get("save_version", 0)
```

### Migration Chain

Migrations are applied sequentially:
- v0 → v1: Add missing fields with defaults
- v1 → v2: (future) Convert format changes

### Migration Functions

```gdscript
# Example migration from v0 (no version) to v1
func _migrate_v0_to_v1(data: Dictionary) -> Dictionary:
    # Add save_version
    data["save_version"] = 1
    
    # Add missing ranch_state fields
    if not data.has("ranch_state"):
        data["ranch_state"] = {}
    var rs: Dictionary = data["ranch_state"]
    rs["lifetime_earnings"] = rs.get("lifetime_earnings", rs.get("money", 0))
    rs["next_dragon_id"] = rs.get("next_dragon_id", 1)
    rs["next_egg_id"] = rs.get("next_egg_id", 1)
    rs["next_facility_id"] = rs.get("next_facility_id", 1)
    rs["next_order_id"] = rs.get("next_order_id", 1)
    
    # Add statistics if missing
    if not data.has("statistics"):
        data["statistics"] = {
            "total_dragons_bred": 0,
            "total_orders_completed": 0,
            "total_eggs_hatched": 0,
            "dragons_sold": 0,
            "dragons_died_naturally": 0,
            "punnett_squares_used": 0
        }
    
    # Add tutorial_state if missing
    if not data.has("tutorial_state"):
        data["tutorial_state"] = {
            "tutorial_enabled": false,  # Assume existing save = tutorial done
            "current_step_id": "",
            "completed_steps": {}
        }
    
    return data
```

### Migration Policy

1. **Never delete data**: Unknown keys are preserved for forward compatibility
2. **Always add defaults**: Missing fields get safe defaults
3. **Log all changes**: Migration actions are logged for debugging
4. **Test both directions**: Verify old saves load and new saves are valid

---

## Backup Strategy

### Automatic Backup

1. Before overwriting `savegame_v1.json`:
   - Copy existing file to `savegame_v1.bak.json`
   - Verify copy succeeded
   - Then write new save

2. On load failure:
   - Try primary file first
   - If corrupt/invalid, try backup file
   - If backup works, copy it to primary
   - Log recovery action

### Manual Export (Future)

For browser players worried about data loss:
- Implement "Export Save" button
- Outputs base64-encoded JSON string
- User can copy/paste to external storage
- "Import Save" reverses the process

---

## Settings File (Separate)

`user://settings.json` stores player preferences independently from game state:

```json
{
  "settings_version": 1,
  "audio": {
    "master_volume": 1.0,
    "music_volume": 0.8,
    "sfx_volume": 1.0
  },
  "gameplay": {
    "auto_feed": true,
    "show_genotypes": false,
    "animation_speed": 1.0,
    "confirm_sales": true
  },
  "accessibility": {
    "high_contrast": false,
    "large_text": false,
    "reduce_motion": false
  }
}
```

Settings are loaded on game start and saved on change. They persist even if game save is deleted.

---

## Implementation Notes

### SaveSystem.gd Responsibilities

1. **save_game() → bool**
   - Gather all state from RanchState
   - Serialize each component
   - Create backup of existing save
   - Write JSON to `user://savegame_v1.json`
   - Return success/failure

2. **load_game() → bool**
   - Check if save exists
   - Read JSON file
   - Detect version and migrate if needed
   - Validate all fields
   - Populate RanchState
   - Return success/failure

3. **has_save() → bool**
   - Check if valid save file exists

4. **delete_save() → void**
   - Remove save and backup files

5. **get_save_info() → Dictionary**
   - Quick read of save metadata without full load
   - Returns: season, money, dragon_count, timestamp

### Thread Safety

- All save/load operations are synchronous (no threading)
- UI should show loading indicator during operations
- Never save during animation or game logic execution

### Error Handling

```gdscript
enum SaveError {
    NONE = 0,
    FILE_NOT_FOUND,
    PARSE_ERROR,
    VALIDATION_ERROR,
    VERSION_TOO_NEW,
    WRITE_FAILED,
    BACKUP_FAILED
}
```

---

## Changelog

### v1 (Initial Release)
- Complete save format specification
- Support for dragons, eggs, facilities, orders
- Tutorial state persistence
- Statistics tracking
- Backup system

### Future Versions (Planned)
- v2: Add multiplayer trade history
- v3: Add advanced genetics (linked traits, sex-linked)
