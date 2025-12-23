# Dragon Ranch — Genetics Normalization Rules

**Document Status:** LOCKED  
**Version:** 1.0  
**Last Updated:** 2025-12-17  

This document defines the canonical rules for genotype storage, normalization, and phenotype resolution. All genetics code MUST follow these rules exactly.

---

## 1. Canonical Trait Keys

All trait references use these **exact string keys** (lowercase, underscore-separated):

| Trait Key | MVP | Unlock Level | Description |
|-----------|-----|--------------|-------------|
| `fire` | ✓ | 0 | Fire/Smoke breath |
| `wings` | ✓ | 0 | Vestigial/Functional wings |
| `armor` | ✓ | 0 | Heavy/Light armor scales |
| `color` | | 1 | Red/White with incomplete dominance |
| `size_s` | | 2 | Size gene 1 (Large/small) |
| `size_g` | | 2 | Size gene 2 (Tall/short) |
| `metabolism` | | 3 | Normal/Hyper with trade-offs |
| `docility` | | 4 | Docile/Normal/Aggressive (3 alleles) |

### Rules

1. **NEVER** use enum IDs as dictionary keys in saved data
2. **ALWAYS** use these exact string keys when referencing traits
3. Trait keys are **case-sensitive** — always lowercase
4. Multi-locus traits (Size) use separate keys: `size_s`, `size_g`

---

## 2. Allele Representation

### 2.1 Storage Format

Alleles are stored as **uppercase single characters** (or two-character codes for multi-allele traits):

```gdscript
# Correct - Array of string alleles
genotype["fire"] = ["F", "f"]
genotype["wings"] = ["w", "W"]
genotype["docility"] = ["D1", "D3"]

# WRONG - String concatenation
genotype["fire"] = "Ff"  # NO!

# WRONG - Lowercase storage
genotype["fire"] = ["f", "f"]  # Use uppercase: ["F", "F"] or normalized
```

### 2.2 Allele Definitions by Trait

| Trait | Alleles | Notes |
|-------|---------|-------|
| `fire` | `F`, `f` | F = Fire (dominant), f = Smoke (recessive) |
| `wings` | `w`, `W` | W = Vestigial (DOMINANT), w = Functional (recessive) — **Teaching moment!** |
| `armor` | `A`, `a` | A = Heavy (dominant), a = Light (recessive) |
| `color` | `R`, `W` | Incomplete dominance: RR=Red, RW=Pink, WW=White |
| `size_s` | `S`, `s` | S = Large (dominant), s = small (recessive) |
| `size_g` | `G`, `g` | G = Tall (dominant), g = short (recessive) |
| `metabolism` | `M`, `m` | Incomplete dominance: MM=Normal, Mm=Intermediate, mm=Hyper |
| `docility` | `D1`, `D2`, `D3` | Dominance hierarchy: D2 > D1 > D3 |

### 2.3 Uppercase Convention

All alleles are stored in their canonical uppercase form:
- Dominant alleles: `F`, `A`, `S`, `G`, `M`
- Recessive alleles: `f`, `a`, `s`, `g`, `m` (stored as lowercase)
- Multi-allele: `D1`, `D2`, `D3` (number suffix)
- Wings exception: `W` (dominant), `w` (recessive) — reversed!

---

## 3. Genotype Normalization

### 3.1 Purpose

Normalization ensures consistent phenotype lookups regardless of allele order during breeding.

### 3.2 Normalization Algorithm

```gdscript
## Normalize a genotype array for phenotype lookup
## Returns a consistent string key like "Ff" or "D1D3"
static func normalize_genotype(alleles: Array) -> String:
    if alleles.size() != 2:
        push_error("Invalid genotype: must have exactly 2 alleles")
        return ""
    
    var a1: String = str(alleles[0])
    var a2: String = str(alleles[1])
    
    # Sort alphabetically for consistent ordering
    # This ensures ["f", "F"] and ["F", "f"] both become "Ff"
    var sorted_alleles: Array = [a1, a2]
    sorted_alleles.sort()
    
    return sorted_alleles[0] + sorted_alleles[1]
```

### 3.3 Normalization Examples

| Input Array | Normalized String | Notes |
|-------------|-------------------|-------|
| `["F", "f"]` | `"Ff"` | Standard heterozygous |
| `["f", "F"]` | `"Ff"` | Same result regardless of order |
| `["F", "F"]` | `"FF"` | Homozygous dominant |
| `["f", "f"]` | `"ff"` | Homozygous recessive |
| `["w", "W"]` | `"Ww"` | Wings — W sorts before w |
| `["D1", "D3"]` | `"D1D3"` | Multi-allele (numeric sort) |
| `["D3", "D1"]` | `"D1D3"` | Same result |
| `["R", "W"]` | `"RW"` | Color incomplete dominance |

### 3.4 Special Cases

#### Wings Trait Sorting
The wings trait has reversed dominance (W dominant, w recessive). After alphabetical sort:
- `["w", "W"]` → `"Ww"` (capital W sorts first)
- Phenotype table must use `"Ww"` as the key for heterozygous

#### Multi-Allele Traits (Docility)
Three-allele traits sort by string comparison:
- `["D1", "D2"]` → `"D1D2"`
- `["D2", "D3"]` → `"D2D3"`
- `["D1", "D3"]` → `"D1D3"`

---

## 4. Phenotype Lookup Tables

### 4.1 Structure

Each trait defines a phenotype table mapping normalized genotype strings to phenotype data:

```gdscript
var phenotypes: Dictionary = {
    "FF": {
        "name": "Fire",
        "sprite_suffix": "fire",
        "color": Color(1.0, 0.4, 0.1),
        "description": "Breathes fire"
    },
    "Ff": {
        "name": "Fire", 
        "sprite_suffix": "fire",
        "color": Color(1.0, 0.4, 0.1),
        "description": "Breathes fire"
    },
    "ff": {
        "name": "Smoke",
        "sprite_suffix": "smoke", 
        "color": Color(0.5, 0.5, 0.5),
        "description": "Puffs smoke"
    }
}
```

### 4.2 MVP Trait Phenotype Tables

#### Fire (`fire`)
| Genotype | Phenotype | Sprite Suffix |
|----------|-----------|---------------|
| `FF` | Fire | `fire` |
| `Ff` | Fire | `fire` |
| `ff` | Smoke | `smoke` |

#### Wings (`wings`) — **Reversed Dominance**
| Genotype | Phenotype | Sprite Suffix |
|----------|-----------|---------------|
| `WW` | Vestigial | `vestigial` |
| `Ww` | Vestigial | `vestigial` |
| `ww` | Functional | `functional` |

**Note:** `W` (vestigial) is DOMINANT. This is a teaching moment about dominant ≠ "better."

#### Armor (`armor`)
| Genotype | Phenotype | Sprite Suffix |
|----------|-----------|---------------|
| `AA` | Heavy | `heavy` |
| `Aa` | Heavy | `heavy` |
| `aa` | Light | `light` |

### 4.3 Extended Trait Phenotype Tables

#### Color (`color`) — Incomplete Dominance
| Genotype | Phenotype | Color Value |
|----------|-----------|-------------|
| `RR` | Red | `Color(0.9, 0.2, 0.2)` |
| `RW` | Pink | `Color(0.95, 0.6, 0.6)` |
| `WW` | White | `Color(0.95, 0.95, 0.95)` |

#### Size — Multi-Gene Additive
Size phenotype is calculated from TWO loci: `size_s` and `size_g`

| Dominant Count | Phenotype | Scale |
|----------------|-----------|-------|
| 4 (SSGG) | Extra Large | 2.0x |
| 3 (SSGg, SsGG) | Large | 1.5x |
| 2 (SsGg, SSgg, ssGG) | Medium | 1.0x |
| 1 (Ssgg, ssGg) | Small | 0.75x |
| 0 (ssgg) | Tiny | 0.5x |

```gdscript
func calculate_size_phenotype(genotype: Dictionary) -> Dictionary:
    var dominant_count: int = 0
    
    # Count S alleles
    for allele in genotype.get("size_s", ["s", "s"]):
        if allele == "S":
            dominant_count += 1
    
    # Count G alleles
    for allele in genotype.get("size_g", ["g", "g"]):
        if allele == "G":
            dominant_count += 1
    
    match dominant_count:
        4: return {"name": "Extra Large", "scale": 2.0}
        3: return {"name": "Large", "scale": 1.5}
        2: return {"name": "Medium", "scale": 1.0}
        1: return {"name": "Small", "scale": 0.75}
        0: return {"name": "Tiny", "scale": 0.5}
    
    return {"name": "Medium", "scale": 1.0}
```

#### Metabolism (`metabolism`) — Incomplete Dominance with Trade-offs
| Genotype | Phenotype | Speed | Food | Lifespan |
|----------|-----------|-------|------|----------|
| `MM` | Normal | 1.0x | 1.0x | 1.0x |
| `Mm` | Intermediate | 1.25x | 1.5x | 0.85x |
| `mm` | Hyper | 1.5x | 2.0x | 0.7x |

#### Docility (`docility`) — Multiple Alleles with Hierarchy
Dominance: D2 > D1 > D3

| Genotype | Phenotype | Escape Chance | Fight Bonus |
|----------|-----------|---------------|-------------|
| `D1D1` | Very Docile | 0% | -20 |
| `D1D2` | Docile | 5% | -10 |
| `D2D2` | Normal | 10% | 0 |
| `D2D3` | Aggressive | 15% | +10 |
| `D3D3` | Very Aggressive | 25% | +20 |
| `D1D3` | Normal | 10% | 0 |

**Note:** D1D3 expresses as Normal because D1 masks D3 (D1 > D3), and the combined effect mimics D2.

---

## 5. Breeding Mechanics

### 5.1 Allele Selection

Each parent contributes ONE randomly selected allele per trait:

```gdscript
func breed_dragons(parent_a: DragonData, parent_b: DragonData) -> Dictionary:
    var offspring_genotype: Dictionary = {}
    
    for trait_key in TraitDB.get_unlocked_traits():
        var alleles_a: Array = parent_a.genotype.get(trait_key, _get_default_alleles(trait_key))
        var alleles_b: Array = parent_b.genotype.get(trait_key, _get_default_alleles(trait_key))
        
        # Randomly select one allele from each parent
        var from_a: String = alleles_a[RNGService.randi_range(0, 1)]
        var from_b: String = alleles_b[RNGService.randi_range(0, 1)]
        
        offspring_genotype[trait_key] = [from_a, from_b]
    
    return offspring_genotype
```

### 5.2 Default Alleles

When a dragon is missing a trait (e.g., older dragon from before trait was unlocked), use defaults:

| Trait | Default Genotype |
|-------|------------------|
| `fire` | `["F", "f"]` |
| `wings` | `["w", "W"]` |
| `armor` | `["A", "a"]` |
| `color` | `["R", "W"]` |
| `size_s` | `["S", "s"]` |
| `size_g` | `["G", "g"]` |
| `metabolism` | `["M", "m"]` |
| `docility` | `["D2", "D2"]` |

### 5.3 Punnett Square Generation

```gdscript
func generate_punnett_square(parent_a: DragonData, parent_b: DragonData, trait_key: String) -> Array:
    var alleles_a: Array = parent_a.genotype.get(trait_key, _get_default_alleles(trait_key))
    var alleles_b: Array = parent_b.genotype.get(trait_key, _get_default_alleles(trait_key))
    
    var square: Array = []
    
    for a in alleles_a:
        var row: Array = []
        for b in alleles_b:
            var normalized: String = normalize_genotype([a, b])
            var phenotype: Dictionary = TraitDB.get_phenotype_data(trait_key, normalized)
            row.append({
                "genotype": normalized,
                "alleles": [a, b],
                "phenotype": phenotype.get("name", "Unknown"),
                "probability": 0.25
            })
        square.append(row)
    
    return square
```

---

## 6. Validation Rules

### 6.1 Genotype Validation

```gdscript
func validate_genotype(genotype: Dictionary, trait_key: String) -> bool:
    if not genotype.has(trait_key):
        return false
    
    var alleles: Array = genotype[trait_key]
    
    if alleles.size() != 2:
        return false
    
    var valid_alleles: Array = TraitDB.get_trait_def(trait_key).alleles
    
    for allele in alleles:
        if allele not in valid_alleles:
            return false
    
    return true
```

### 6.2 Complete Genotype Validation

```gdscript
func validate_full_genotype(genotype: Dictionary) -> Dictionary:
    var result: Dictionary = {
        "valid": true,
        "errors": [],
        "warnings": []
    }
    
    # Check required MVP traits
    for trait_key in ["fire", "wings", "armor"]:
        if not genotype.has(trait_key):
            result.errors.append("Missing required trait: %s" % trait_key)
            result.valid = false
        elif not validate_genotype(genotype, trait_key):
            result.errors.append("Invalid alleles for trait: %s" % trait_key)
            result.valid = false
    
    # Check optional traits (warn if present but invalid)
    for trait_key in genotype.keys():
        if trait_key not in ["fire", "wings", "armor"]:
            if not validate_genotype(genotype, trait_key):
                result.warnings.append("Invalid alleles for optional trait: %s" % trait_key)
    
    return result
```

---

## 7. Display Formatting

### 7.1 Genotype Display String

For UI display, format genotypes consistently:

```gdscript
func format_genotype_display(genotype: Dictionary) -> String:
    var parts: Array = []
    
    # Display in canonical order
    var display_order: Array = ["fire", "wings", "armor", "color", "size_s", "size_g", "metabolism", "docility"]
    
    for trait_key in display_order:
        if genotype.has(trait_key):
            var alleles: Array = genotype[trait_key]
            var normalized: String = normalize_genotype(alleles)
            parts.append("%s: %s" % [trait_key.capitalize(), normalized])
    
    return ", ".join(parts)
```

**Example Output:** `"Fire: Ff, Wings: Ww, Armor: AA"`

### 7.2 Phenotype Display String

```gdscript
func format_phenotype_display(phenotype: Dictionary) -> String:
    var parts: Array = []
    
    var display_order: Array = ["fire", "wings", "armor", "color", "size", "metabolism", "docility"]
    
    for trait_key in display_order:
        if phenotype.has(trait_key):
            var trait_data: Dictionary = phenotype[trait_key]
            parts.append(trait_data.get("name", "Unknown"))
    
    return ", ".join(parts)
```

**Example Output:** `"Fire, Vestigial, Heavy"`

---

## 8. Edge Cases and Error Handling

### 8.1 Missing Traits

When a dragon is missing a trait key:
1. **During breeding:** Use default alleles (see Section 5.2)
2. **During phenotype lookup:** Return null/empty, UI handles gracefully
3. **During validation:** Flag as warning for optional traits, error for MVP traits

### 8.2 Invalid Alleles

When encountering invalid alleles:
1. Log error with dragon ID and trait key
2. Attempt to repair with default alleles
3. Flag dragon for review (set `needs_repair` flag)

### 8.3 Null/Empty Genotype

```gdscript
func safe_get_genotype(dragon: DragonData, trait_key: String) -> Array:
    if dragon == null or dragon.genotype == null:
        return _get_default_alleles(trait_key)
    
    if not dragon.genotype.has(trait_key):
        return _get_default_alleles(trait_key)
    
    var alleles: Array = dragon.genotype[trait_key]
    
    if alleles.size() != 2:
        return _get_default_alleles(trait_key)
    
    return alleles
```

### 8.4 Phenotype Lookup Failure

If phenotype table doesn't have the normalized genotype:
1. Log error
2. Return sensible default (first entry in phenotype table)
3. Never crash or return null without warning

---

## 9. Testing Requirements

### 9.1 Normalization Tests

Every normalization function MUST pass these tests:

```gdscript
func test_normalization():
    # Basic cases
    assert(normalize_genotype(["F", "f"]) == "Ff")
    assert(normalize_genotype(["f", "F"]) == "Ff")
    assert(normalize_genotype(["F", "F"]) == "FF")
    assert(normalize_genotype(["f", "f"]) == "ff")
    
    # Wings (reversed dominance)
    assert(normalize_genotype(["w", "W"]) == "Ww")
    assert(normalize_genotype(["W", "w"]) == "Ww")
    
    # Multi-allele
    assert(normalize_genotype(["D1", "D3"]) == "D1D3")
    assert(normalize_genotype(["D3", "D1"]) == "D1D3")
    assert(normalize_genotype(["D2", "D3"]) == "D2D3")
```

### 9.2 Breeding Outcome Tests

With fixed RNG seed, verify:
- FF × ff → 100% Ff
- Ff × Ff → 25% FF, 50% Ff, 25% ff (over 1000 runs)
- ww × WW → 100% Ww (vestigial phenotype)

### 9.3 Phenotype Lookup Tests

```gdscript
func test_phenotype_lookup():
    # Fire trait
    assert(get_phenotype("fire", "FF").name == "Fire")
    assert(get_phenotype("fire", "Ff").name == "Fire")
    assert(get_phenotype("fire", "ff").name == "Smoke")
    
    # Wings trait (reversed!)
    assert(get_phenotype("wings", "ww").name == "Functional")
    assert(get_phenotype("wings", "Ww").name == "Vestigial")
    assert(get_phenotype("wings", "WW").name == "Vestigial")
```

---

## 10. Summary: Critical Rules

1. **Trait keys are lowercase strings:** `"fire"`, `"wings"`, `"armor"`
2. **Alleles are arrays of strings:** `["F", "f"]`, never `"Ff"`
3. **Normalization uses alphabetical sort** for consistent lookups
4. **Wings has REVERSED dominance:** `W` (vestigial) is dominant
5. **Multi-locus traits use separate keys:** `size_s`, `size_g`
6. **Always validate before breeding or saving**
7. **Use defaults for missing traits, never crash**
8. **All genetics use RNGService for deterministic testing**

---

*Document End — This specification is LOCKED and must not change without architectural review.*
