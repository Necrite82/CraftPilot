# Camping: scope, provenance and validation

## Included reference data

CraftPilot 0.11 adds only the camping subset of the already used Craft Ladder snapshot, revision `b9c61346ad4cf63245f35cadb1e0a88467fb6e75`:

- `ThirdParty/CraftLadder/Camp.lua`: unchanged original file, generated 2026-10-16 from Forever build **1.60.1.70425**. Contains three campfires, profession objects, upgrades, level-based effects, exclusive class buffs and relevant material names. Faction filtering produces **37 objects per faction**, covering all twelve professions.
- `ThirdParty/CraftLadder/CampingRecipes.lua`: eight recipe records selected from Cooking and FirstAid by the maker IDs in Camp.lua. Fishing was checked but yielded no matching recipe records. Other camping recipes use the previously bundled manufacturing catalog; missing gathering-profession recipe metadata remains unknown.
- `CAMP_SOURCES.json`: immutable input URLs, revision, build, generation date and SHA-256 for all four importer inputs. No full cooking, fishing, first-aid or gathering databases are bundled by this import.

Original license: **GNU GPL-3.0**, compatible with CraftPilot's GPL-3.0-only distribution. Copyright/attribution: Craft Ladder contributors, including Alex P; the source does not supply an additional per-file copyright statement for Camp.lua. Its original header is retained. Existing upstream third-party notices remain in [CREDITS.txt](../ThirdParty/CraftLadder/CREDITS.txt); the full license is [LICENSE](../LICENSE). This records the upstream licensing declaration, not an independent reconstruction of the underlying game-data provenance.

## Comparison and limits

[Blizzard's Camping overview](https://news.blizzard.com/en-us/article/24301516/gather-around-the-campfire-in-world-of-warcraft-forever) confirms the profession system, shared cooldown, one-minute participation, fire capacities and examples of effects and exclusions. This article is used as a factual cross-check; its text and assets are not bundled. Most illustrated effects agree with the snapshot. Blizzard's displayed enchanting armor range ends at 260; the snapshot contains a level-60 value of 308. CraftPilot therefore labels every fallback effect as an older reference and gives available client spell descriptions priority. Skill requirements can also differ by learning, crafting and use; the recipe learn field is not presented as a use requirement.

The [WoW-professions Camping guide](https://www.wow-professions.com/forever/camping-guide) additionally names **Trapper's Workbench**, absent from this snapshot. Version 0.11.1 additionally displays its item/recipe IDs, material quantities and use requirement, bringing the view to 38 objects per faction; its reported beta drop remains unconfirmed for live servers. No guide tables, descriptions, images, drop rates or database dumps are copied. No current boss-specific source or chance is inferred from an upstream `npcs = 1` count.

Client-captured recipe names and unambiguous material lists take priority. If a fresh recipe capture cannot resolve materials, an old material list is not silently restored. Native spell descriptions are shown as client text, not proof of a current server-side effect. Missing boss, blueprint, material or learning metadata is explicitly unknown. The view is a browsable reference, not a claim of complete current live coverage. Version 0.12 adds a separate cross-profession camping shopping plan. Objects can be added in quantities of one or five; unknown materials and missing prices remain explicit. The camping plan does not promise skill progression or unlock unlearned recipes.

No Endgame Tools database or proprietary external dump is included. No GTA data is included.

## Reproduce and check

From the repository root:

```sh
python tools/import_camping.py --source-dir work/camping-inputs --download --check
lua tests/test.lua
python tools/build_release.py --check
```

Omit `--check` to regenerate the two camping data files from the exact hash-verified inputs. `--download` requests only the four pinned public source files; it does not search for or follow arbitrary downloads. Neither downloaded input caches nor build tools enter the install ZIP.

Automated tests cover all twelve professions, the faction-filtered object count, all three fire capacities, expandable cards, client-material precedence and clearing, on/off slider callbacks, English/fallback rendering and translation format placeholders. They do not replace an in-game visual test or a current server availability check.
