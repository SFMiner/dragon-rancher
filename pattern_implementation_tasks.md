Task 1: Test three-gene color system
Extended Thinking: ON (complex gene interaction testing)
Description: Verify the three-gene color system works correctly.
Test Cases:

Epistasis still works: WW + any hue + any pattern → White
Pattern without stripes: RR + HoHo + PP → Solid Gold
Pattern with stripes: RR + HoHo + pp → Striped Gold
Pastel stripes: RW + HgHg + pp → Striped Mint
Independent assortment: Breed two dragons, verify pattern segregates independently

Action:

Start game or load save with reputation ≥ 2
Create/breed dragons with known genotypes
Verify phenotype names include "Striped" when pattern is pp
Check that solid and striped versions differ

Verification:

16 colored phenotypes possible (8 colors × 2 patterns)
White always appears white regardless of genes
Pattern only shows when pigment is present (not WW)
Striped dragons show "Striped [Color]" in name


Task 2: Update Genetics_Normalization_Rules.md
Extended Thinking: OFF
Description: Add documentation for the three-gene color system.
Action:

Open docs/Genetics_Normalization_Rules.md
Add pattern to Section 2.2 (Allele Definitions)
Add new section using content from three_gene_color_documentation.md
Include epistasis examples and phenotype table

Verification:

Documentation includes all 17 phenotypes
Epistasis examples are clear
Independent assortment is explained
Teaching moments highlighted
