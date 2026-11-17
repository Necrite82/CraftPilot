<p align="center"><img src="Media/CraftPilot.png" width="128" alt="CraftPilot"></p>

<h1 align="center">CraftPilot</h1>

<p align="center"><b>The cheapest way to level your professions in WoW Forever</b><br>
by your own auction house prices, with shopping, trainers, alts and crafting in one place.</p>

<p align="center">
<a href="https://www.curseforge.com/wow/addons/craftpilot">CurseForge</a> ·
<a href="README.md">Deutsch</a> ·
<a href="CHANGELOG.md">Changelog (German)</a> ·
<a href="DATA_SOURCES.md">Data sources</a> ·
<a href="https://github.com/Necrite82/CraftPilot/issues">Report a bug</a>
</p>

---

**Status:** 0.2.0-beta · WoW Forever 1.60.x (Interface 16001) · English and German

> **Beta:** CraftPilot is new. Please report bugs in-game via "Report bug" or as a [GitHub issue](https://github.com/Necrite82/CraftPilot/issues).

## What CraftPilot does

CraftPilot works out, skill point by skill point, which way to the training cap costs the least. It uses your Auctionator prices and the chance of each skill color (orange always, yellow mostly, green rarely). Recipes you still have to learn only join the path when they pay for their fee.

The result is a clear recommendation of **what to craft, buy or learn next**, inside the addon and next to the profession window.

**CraftPilot buys, learns and crafts only when you click.**

## Features

**Leveling**
- Cheapest path by AH prices, selectable: *cheapest*, *prefer reliable colors*, *orange and yellow only* or *fastest*
- Companion panel at the profession window: recommendation, "N× more to the next color", **craft button**, session balance
- Clear hints on what to **keep** for later steps, and "already there" instead of crafting twice
- Preview of the next recipe to learn, warnings for rank and level requirements

**Shopping**
- Shopping plan for any skill range, price limit per material ("worth it up to 12s")
- **Shopping round at the auction house** with Auctionator: item by item, purchases are counted
- **Vendor helper** buys exactly the missing amount; bank helper shows what to take along
- Gathering zones for ores, stones and herbs, sale value, budget mode

**Learning**
- One click to every trainer and vendor, a learning tour along the cheapest path
- Specializations (blacksmith, engineer, leatherworker) with steps and quest givers

**After 300**
- Profit per craft for your learned recipes: with bought and with own materials (own and farmed materials count at their sale value)
- Recipes for **Merchant's Favor** with profit per craft; optionally CraftPilot converts Favor into gold and includes Favor recipes in the cheapest path

**Alts**
- Stock in bags, bank and mail of every character, cooldowns, alts as cheaper crafters
- At the mailbox: what your alts need, with a prepared mail

**Safety**
- Marks on reserved items in any bag view (default bags, EllesmereUI, Baganator, Bagnon, AdiBags …)
- Warning and "Buy back" when you sell something reserved anyway; warnings at the auction house, when destroying, disenchanting and when mailing to someone else's character
- Hints in item tooltips

## Installation

**CurseForge app (recommended):** search for CraftPilot and install it. **QuestieDB** is installed automatically.

**Manually:**
1. Download [CraftPilot-0.2.0-beta.zip](https://github.com/Necrite82/CraftPilot/raw/main/dist/CraftPilot-0.2.0-beta.zip) (not the GitHub source archive).
2. Extract it to `World of Warcraft\_forever_\Interface\AddOns`; `CraftPilot\CraftPilot.toc` must sit directly in the `CraftPilot` folder.
3. Also install **QuestieDB** (Forever version).

| Addon | |
| --- | --- |
| QuestieDB | **required**: trainers, vendor locations, gathering zones |
| Auctionator | recommended: AH prices, shopping round |
| TomTom | optional: waypoints with arrow |
| EllesmereUI | optional: matching look |

## First steps

1. `/cp` opens CraftPilot. On first start, the help explains the basics.
2. **Open the profession window once** so CraftPilot reads your recipes and skill colors.
3. Scan once at the auction house with Auctionator.
4. Follow the recommendation at the top of "Now".

Open the in-game help any time with "?" at the top right or `/cp help`.

## Commands

| Command | |
| --- | --- |
| `/cp` | open or close the window |
| `/cp help` | help |
| `/cp <profession>` | choose a profession, e.g. `/cp blacksmithing`, `/cp engineering` |
| `/cp plan` · `/cp lehrer` | Plan & shopping · Trainers & vendors |
| `/cp trainer` · `/cp naechster` | waypoint to the recommended or nearest trainer |
| `/cp refresh` | read the profession window again |
| `/cp resetpos` | reset the window position |
| `/cp skin auto\|dark\|classic` | look |

## Good to know

- Prices are stored scans, not live offers. Missing or old prices are named, not guessed.
- Skill chances are typical values; single results vary.
- Trainer and vendor locations are travel aids; their stock is not checked live.

## Contributing

Bugs and ideas are welcome as [issues](https://github.com/Necrite82/CraftPilot/issues). In-game, "Report bug" builds a ready-made report with version and Lua errors. Developer notes are in [CONTRIBUTING.md](CONTRIBUTING.md); automated tests run under Lua 5.1 and 5.4.

## License and data

CraftPilot is licensed under the **GNU GPL-3.0-only**, see [LICENSE](LICENSE).

- Recipe data: [Craft Ladder](https://github.com/saintmodx/craft-ladder) (GPL-3.0)
- Trainer ranks: [CMaNGOS classic-db](https://github.com/cmangos/classic-db) (GPL-3.0)
- Trainer and gathering node locations: read at runtime from the [QuestieDB](https://github.com/Questie/QuestieDB) addon

Details in [DATA_SOURCES.md](DATA_SOURCES.md). World of Warcraft is a trademark of Blizzard Entertainment; CraftPilot is an independent community project.
