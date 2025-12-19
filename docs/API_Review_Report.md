# API Review Report

This report details violations of the established API contracts defined in `API_Reference.md`.

## P-REVIEW-001: API Adherence Review

### Violations

### `RNGService` (`scripts/autoloads/RNGService.gd`)

*   **Method Signature Mismatch:**
    *   `shuffle(array: Array) -> Array` is defined in the API, but implemented as `shuffle(array: Array) -> void`. The implementation modifies the array in-place.
*   **Method Name Mismatch:**
    *   The API defines `pick_random(array: Array) -> Variant`, but it is implemented as `choice(array: Array) -> Variant`.
*   **API Drift (New Methods):**
    *   `weighted_choice(weights: Dictionary) -> Variant`: Not defined in API.
    *   `print_seed() -> void`: Not defined in API.
    *   `randomize_seed() -> void`: Not defined in API.
    *   `to_dict() -> Dictionary`: Not defined in API.
    *   `from_dict(data: Dictionary) -> void`: Not defined in API.

### `TraitDB` (`scripts/autoloads/TraitDB.gd`)

*   **Missing Property:**
    *   `unlocked_traits: Array[String] = []` is defined in the API but is missing from the implementation.
*   **Method Name Mismatch:**
    *   `get_all_trait_defs() -> Array[TraitDef]` is defined in the API, but implemented as `get_all_traits() -> Array[TraitDef]`.
*   **Method Signature Mismatch:**
    *   `is_trait_unlocked(trait_key: String) -> bool` is defined in the API, but implemented as `is_trait_unlocked(trait_key: String, reputation_level: int) -> bool`.
*   **Missing Methods:**
    *   `unlock_trait(trait_key: String) -> void` is defined in the API but is missing from the implementation.
    *   `get_trait_keys_for_breeding() -> Array[String]` is defined in the API but is missing from the implementation.
*   **API Drift (New Methods):**
    *   `load_traits() -> bool`
    *   `get_all_trait_keys() -> Array[String]`
    *   `get_default_genotype(reputation_level: int) -> Dictionary`
    *   `get_random_genotype(reputation_level: int) -> Dictionary`
    *   `validate_genotype(genotype: Dictionary) -> bool`
    *   `get_trait_count() -> int`
    *   `is_loaded() -> bool`
    *   `reload() -> bool`

### `GeneticsEngine` (`scripts/autoloads/GeneticsEngine.gd`)

*   **Method Signature Mismatch:**
    *   `generate_punnett_square` returns an `Array` of `Dictionary`, but the API specifies `Array[Array[{genotype: String, phenotype: String, probability: float}]]`. The implemented dictionary has a different structure.
*   **Missing Methods:**
    *   `predict_offspring(parent_a: DragonData, parent_b: DragonData) -> Dictionary` is defined in the API but is missing from the implementation.
    *   `validate_genotype(genotype: Dictionary) -> bool` is defined in the API but is missing. This functionality appears to have been moved to `TraitDB.gd`.
*   **API Drift (New Methods):**
    *   `generate_full_punnett_square(parent_a: DragonData, parent_b: DragonData) -> Dictionary`
    *   `create_starter_dragon(reputation_level: int, sex: String) -> DragonData`
    *   `create_random_dragon(reputation_level: int, sex: String) -> DragonData`
    *   `can_breed(parent_a: DragonData, parent_b: DragonData) -> Dictionary`
    *   `calculate_size_phenotype(genotype: Dictionary) -> Dictionary`

