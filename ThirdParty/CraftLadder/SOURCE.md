# Bundled profession catalog / Enthaltener Berufskatalog

Source: https://github.com/saintmodx/craft-ladder
Exact upstream revision: `b9c61346ad4cf63245f35cadb1e0a88467fb6e75`
Upstream version: Craft Ladder 1.7.0, source files generated from Forever client builds 1.60.1.70425 / 1.60.1.70450 (October 2026).
Authors: Craft Ladder contributors, including Alex P (see upstream project).
License: GNU GPL-3.0; original file headers preserved for the six manufacturing professions. Derived Mining smelting subset is separately marked.
Additional third-party attributions, including CMaNGOS classic-db, QuestieDB and AllTheThings, are preserved in `CREDITS.txt`. The parent project's `LICENSE` contains the full GPL-3.0 text.

**Important:** The catalog is an upstream snapshot, not a verified current-live Forever 1.60.1.70862 record. It includes historical/unavailable entries, speculative learning requirements and recipes that may not yet be obtainable. CraftPilot must filter source methods, preserve uncertainty and favor newer recipe details read from the player's current game client. No external website guide text, images or raw gathering-node databases have been copied into CraftPilot.

Der Datenstand ist ausdrücklich nicht mit einer überprüften Live-Verfügbarkeit oder einer garantierten günstigsten Route gleichzusetzen. Das Addon berücksichtigt ausschließlich geeignete Herstellungsrezepte und zeigt Annahmen an. Alle Datenquellen können serverseitigen Änderungen unterliegen.

Third-party modules in this directory are redistributed under their original GPL-3.0 terms. They are not independently authored CraftPilot code.

## Camping subset added in 0.11

`Camp.lua` is preserved unchanged from the same pinned revision, generated 2026-10-16 for build 1.60.1.70425. `CampingRecipes.lua` is a marked filtered derivative containing eight matching cooking/first-aid records, with no unrelated recipe tables. Fishing input was inspected and yielded no matching recipes. Input URLs and checksums are in `CAMP_SOURCES.json`; `tools/import_camping.py` reproduces the import. Original contributors, notices and GPL-3.0 terms above apply. See `docs/CAMPING_SOURCES.md` for validation, scope and remaining unknowns.
