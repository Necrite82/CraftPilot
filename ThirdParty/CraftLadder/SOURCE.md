# Bundled profession catalog / Enthaltener Berufskatalog

Source: https://github.com/saintmodx/craft-ladder
Exact upstream revision: `fd801d7af49465bbe8d24d0cba558f77f4f6a595` (tag `v1.11.0`)
Upstream version: Craft Ladder 1.11.0, data generated 2026-11-13 to 2026-11-15 from the live Forever client build 1.60.1.70938, with sources rebuilt from AllTheThings `95bb427` and QuestieDB 1.1.1.
Pinned inputs and SHA-256 hashes: `UPSTREAM.json`. Reproduce or verify with `python3 tools/sync_craft_ladder.py --check`.
Previous revision until CraftPilot 0.20.1: `b9c61346ad4cf63245f35cadb1e0a88467fb6e75` (Craft Ladder 1.7.0, beta builds 1.60.1.70425 / 70450).
Authors: Craft Ladder contributors, including Alex P (see upstream project).
License: GNU GPL-3.0; original file headers preserved for the six manufacturing professions. Derived Mining smelting subset is separately marked.
Additional third-party attributions, including CMaNGOS classic-db, QuestieDB and AllTheThings, are preserved in `CREDITS.txt`. The parent project's `LICENSE` contains the full GPL-3.0 text.

**Important:** The catalog is an upstream snapshot, not a verified record of every server-side hotfix on top of client build 1.60.1.70938. It includes historical/unavailable entries, speculative learning requirements and recipes that may not yet be obtainable. CraftPilot must filter source methods, preserve uncertainty and favor newer recipe details read from the player's current game client. No external website guide text, images or raw gathering-node databases have been copied into CraftPilot.

Der Datenstand ist ausdrücklich nicht mit einer überprüften Live-Verfügbarkeit oder einer garantierten günstigsten Route gleichzusetzen. Das Addon berücksichtigt ausschließlich geeignete Herstellungsrezepte und zeigt Annahmen an. Alle Datenquellen können serverseitigen Änderungen unterliegen.

Third-party modules in this directory are redistributed under their original GPL-3.0 terms. They are not independently authored CraftPilot code.

## Camping subset added in 0.11

`Camp.lua` is preserved unchanged from the same pinned revision (since the 1.11.0 sync: generated 2026-11-13 for build 1.60.1.70938). `CampingRecipes.lua` is a marked filtered derivative containing eight matching cooking/first-aid records, with no unrelated recipe tables. Fishing input was inspected and yielded no matching recipes. Input URLs and checksums are in `CAMP_SOURCES.json`; `tools/import_camping.py` reproduces the import. Original contributors, notices and GPL-3.0 terms above apply. See `docs/CAMPING_SOURCES.md` for validation, scope and remaining unknowns.

## Secondary skill-range subset in 0.12.1

`SecondarySkillRanges.lua` is a marked GPL-3.0 derivative containing only 162 cooking/first-aid recipe spell IDs and their four color thresholds. Its two input files are already pinned and hashed in `CAMP_SOURCES.json`. Original notices above remain applicable. No material lists, vendor tables, names or gathering datasets are included in this subset. Reproduce with `tools/import_skill_ranges.py`.

## Vendor subset in 0.13

`VendorRecipes.lua` is a marked GPL-3.0 derivative limited to 71 cooking/first-aid crafting recipes with vendor sources and their referenced NPC rows. Inputs are the existing Cooking/FirstAid entries in `CAMP_SOURCES.json`; no new full recipe or gathering databases are bundled. Original notices above remain applicable. `tools/import_vendor_recipes.py` verifies pinned hashes and reproduces the output.
