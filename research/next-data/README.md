# Reference data for the next CraftPilot version

Reviewed on 2026-11-08. This directory is a preparation area, excluded from the
addon TOC and the 0.8 installation ZIP. No runtime features or route calculations
consume it. It is not a release and has not been tested in the game client.

## Imported scope

| Source | Included subset | License and limitations |
| --- | --- | --- |
| [Efficient Games / EG Link](https://github.com/JIVESCORP/eg-link-output-wowf/tree/156f29c9af78b1586883e8eb94a13467eb89638c) | 176 services at 6 profession trainers; 174 vendor slots at 30 vendors | CC BY 4.0; original license and attribution retained |
| [pfQuest](https://github.com/shagu/pfQuest/tree/104f35678ca39ab1fb78b655f815cc7016f5e0c8) | 547 NPC records, their available English/German names; vendor relations for 299 relevant items | MIT; Copyright (c) 2017-2021 Eric Mauser (Shagu) |

**Data from [Efficient Games](https://efficient.games), licensed under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).**
Modifications: trainers/services and vendors/entries filtered to CraftPilot's
existing profession/catalog scope; JSON reformatted. All selected entry fields
are preserved, including source counts, costs, stacks, conditions and positions.
See `eg-LICENSE` and the unchanged `eg-README.md` for original terms and notices.
The upstream repository states no separate copyright year; none is invented here.

EG product: **wowf**, client **1.60.1.70862**, observations **2026-11-07 through
2026-11-08 UTC**. Each imported service has **one contributing player file**.
These are observations, not independently corroborated offers. A count of three
in dataset metadata does not mean every service was seen by three people.
Names can reflect the contributing client's language. Coordinates are the player's
position when opening a window, not exact NPC spawn coordinates. Level zero means
no nonzero requirement was observed; it must not become a guaranteed zero-level
requirement. Prices are copper **per stack**, by reaction/standing; retain barter
and non-gold costs. Missing services are not evidence that a trainer lacks them.

pfQuest is a **Classic reference**, with no exact client build asserted by these
source files. Modifications: NPC tables and translations filtered by NPC ID;
only `V` vendor relations extracted from item records. Included NPCs are those
explicitly referenced by CraftPilot's catalog or selected vendor/trainer records.
Included items are recipe-learning items or reagents in that catalog. No unrelated
quest/drop tables or full databases are vendored. pfQuest does not establish current
Forever teaching requirements: the selected tables contain NPC positions/factions
and vendor links, not a profession trainer-offer database. Legacy zone IDs and
0–100 coordinates are retained verbatim, **not converted to UiMapIDs**. Vendor
relation values are preserved without interpreting them as prices or stock.

The three `.lua` files require pfQuest's `pfDB` environment; they are reference
extracts, not executable CraftPilot modules. `pfQuest-LICENSE` preserves the full
original MIT notice. Original project notices remain applicable. MIT and CC BY 4.0
permit the corresponding reuse with notices/attribution and are suitable for this
separate distribution alongside GPL-3.0 CraftPilot. These data retain their own
licenses; they are not simply relabeled GPL. The grants cover the licensors' rights,
not additional Blizzard game-content or trademark rights. No permission from
Endgame Tools is needed to obtain these independently from their original publishers.

## Comparison and validation

`validation.json` records every compared trainer spell's catalog learning skill
and observed skill. Five NPC/spell pairs disagree, representing three distinct spells:

| Spell | Existing catalog learn | Observed requirement | NPCs |
| --- | --- | --- | --- |
| 1229432 | 1 | 20 | 3365, 5811, 11084 |
| 3755 | 1 | 5 | 3523 |
| 1230643 | 1 | 20 | 5695 |

These are differences between the old catalog's `learn` field and observed trainer
`skillRank`, not proof that either value is wrong. No runtime value is overwritten.
Before integration, resolve semantics, profession ranks, trainer availability and
missing/current-build coverage in the actual client. There is no map-coordinate
equivalence claim between pfQuest zones and EG UiMapIDs. Missing pfQuest NPC IDs
are listed explicitly in the report, with no invented fallback positions.

## Deferred sources and license boundaries

- **QuestieDB:** no new dataset imported. At revision
  `f863e106c837f1e30e6dae0e44b166be9bceb5f1`, its original
  [LICENSE.md](https://github.com/Questie/QuestieDB/blob/f863e106c837f1e30e6dae0e44b166be9bceb5f1/LICENSE.md)
  distinguishes file-level licenses, individual GPLv3 consents and historical
  contributions with unresolved rights. See unchanged `questie-LICENSE-review.md`.
  A blanket GPL-3.0 compatibility claim for the whole database is unsupported.
  An import needs a specifically cleared file/subset and traceable provenance.
- **Existing Craft Ladder catalog:** its preserved credits list Questie/QuestieDB
  as upstream sources. That pre-existing dependency deserves a separate provenance
  review before redistributing an updated release. This preparation does not certify
  those historical rights and does not replace its source notices.
- **Endgame Tools:** no database downloaded or imported. Its
  [terms](https://endgametools.com/en/legal) must be considered separately; an export
  and redistribution would need explicit permission covering that data and updates.
- **Everloot, other client-table exports and gathering datasets:** not imported.
  No additional data is necessary for this scoped preparation; separate license,
  provenance, build and relevance checks would be required.
- GTA 6 data, guides, images, proprietary website exports and unrelated game data
  are excluded.

## Reproduce

Python 3.10+; standard library only. Run from the repository root:

```sh
python tools/prepare_sources.py --source-dir ../craftpilot-source-cache --download
python tools/prepare_sources.py --source-dir ../craftpilot-source-cache --check
python -m unittest discover -s tests -p 'test_sources.py' -v
```

The downloader uses only immutable GitHub revision URLs listed in
`sources.lock.json`, with SHA-256 verification before writing or parsing.
Cached original files are outside the repository; only selected extracts, original
license notices, review evidence and manifests are checked in. After downloading,
generation/checking works offline. The manifest records exact source file hashes,
revision/build information and output hashes. Source documentation/index files are
verified as evidence, not shipped as additional game datasets. Updating a revision
requires deliberate lock-file review and rechecking the upstream license.

The CI workflow tests filtering and downloads/rebuilds the locked sources to compare
every generated output byte. Automated tests cover empty Lua records, class/unrelated
profession exclusion, duplicate vendor slots, evidence/price preservation and rejection
of unexpected product/build/license metadata. These checks do not substitute for
current-client verification or resolve rights the publishers themselves do not grant.
