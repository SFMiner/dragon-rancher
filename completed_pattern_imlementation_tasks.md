Task 1: Add pattern trait definition to trait_defs.json
Extended Thinking: OFF
Description: Add the new pattern trait object to the traits array in data/config/trait_defs.json.
Action:

Open data/config/trait_defs.json
Locate the end of the traits array
Add a comma after the last trait
Insert the complete pattern trait definition from pattern_trait_definition.json

Verification:

JSON remains valid
Pattern trait appears in traits array
unlock_level is 2
is_multi_locus is true
related_loci includes ["color", "hue"]


Task 2: Update color trait related_loci to include pattern
Extended Thinking: OFF
Description: Modify the existing color trait in data/config/trait_defs.json to reference pattern gene.
Changes needed:

Find the trait with "key": "color"
Change "related_loci": ["hue"] to "related_loci": ["hue", "pattern"]

Verification: JSON remains valid, color trait now references both hue and pattern.

Task 3: Update hue trait related_loci to include pattern
Extended Thinking: OFF
Description: Modify the existing hue trait in data/config/trait_defs.json to reference pattern gene.
Changes needed:

Find the trait with "key": "hue"
Change "related_loci": ["color"] to "related_loci": ["color", "pattern"]

Verification: JSON remains valid, hue trait now references both color and pattern.

Task 4: Replace calculate_color_phenotype() in GeneticsEngine.gd
Extended Thinking: ON (complex three-gene interaction logic)
Description: Replace the existing calculate_color_phenotype() function with the updated version that handles pattern.
Action:

Open scripts/autoloads/GeneticsEngine.gd
Find the existing calculate_color_phenotype() function
Replace the entire function with the version from updated_calculate_color_phenotype.gd

Verification:

Function compiles without errors
Uses tabs for indentation
Handles pattern gene when present (optional check)
Falls back gracefully if pattern gene missing
WW still always produces white (epistasis)


Task 5: Add pattern order templates
Extended Thinking: OFF
Description: Add new order templates to data/config/order_templates.json that use the pattern gene.
Action:

Open data/config/order_templates.json
Add the 7 new order templates from pattern_order_templates.json
Ensure each template has unique ID

Verification:

JSON remains valid
All new orders have reputation_required: 2, 3, or 4
Orders showcase striped patterns and independent assortment
