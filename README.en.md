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

**Status:** 1.3.0 · WoW Forever 1.60.x (Interface 16001) · English and German

> **Questions, ideas and bugs:** in-game via "Report bug", on [Discord](https://discord.gg/DpsBkHtQS) or as a [GitHub issue](https://github.com/Necrite82/CraftPilot/issues).

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
- **Budget** right on "Now": how far your gold gets you, with a warning when a step exceeds it
- **Two professions together**: make intermediates with your second profession (e.g. smelt bars) – saving and skill points there
- **Confirmed skill ranges**: CraftPilot notes at which skill points came; shared data makes the colour ranges more accurate for everyone

**Shopping**
- Shopping plan for any skill range, price limit per material ("worth it up to 12s")
- **Shopping round at the auction house** with Auctionator: item by item, purchases are counted
- **Vendor helper** buys exactly the missing amount; bank helper shows what to take along
- Gathering zones for ores, stones and herbs, sale value
- **Cheap now**: materials of your path that are clearly below their usual price today, with the saving
- **Farm or buy** by your own gathering pace
- Prices from **Auctionator, TradeSkillMaster or Auctioneer**

**Learning**
- One click to every trainer and vendor, a learning tour along the cheapest path
- Specializations (blacksmith, engineer, leatherworker) with steps and quest givers

**Endgame**
- Profit per craft for your learned recipes: with bought and with own materials (own and farmed materials count at their sale value)
- Recipes for **Merchant's Favor** with profit per craft; optionally CraftPilot converts Favor into gold and includes Favor recipes in the cheapest path
- **Recipe wishlist** with sources (trainer, vendor, Favor, quest, bosses from QuestieDB); bosses show your wished recipe in their tooltip
- **Raid stock**: potions, flasks and food with a target amount, crafting versus buying, reservation and an Auctionator shopping list
- **AH alarm** after a scan: wished recipes on the AH and cheap raid stock

**Items**
- Every item with all recipes it goes into and who makes it – recipe chain, price, stock, drops; missing recipes of your profession with a waypoint
- **Craftable now** from bags, bank, mail and alts, **watchlist** with AH alarm, **keep or sell** in the tooltip

**Alts**
- Stock in bags, bank and mail of every character, cooldowns, alts as cheaper crafters
- **Mail packer**: at the mailbox CraftPilot packs the mail to your alt with exactly the missing amounts – you only click "Send"

**Safety**
- Marks on reserved items in any bag view (default bags, EllesmereUI, Baganator, Bagnon, AdiBags …)
- Warning and "Buy back" when you sell something reserved anyway; warnings at the auction house, when destroying, disenchanting and when mailing to someone else's character
- Hints in item tooltips

## Installation

**CurseForge app (recommended):** search for CraftPilot and install it. **QuestieDB** is installed automatically.

**Manually:**
1. Download [CraftPilot-1.3.0.zip](https://github.com/Necrite82/CraftPilot/raw/main/dist/CraftPilot-1.3.0.zip) (not the GitHub source archive).
2. Extract it to `World of Warcraft\_forever_\Interface\AddOns`; `CraftPilotPro\CraftPilotPro.toc` must sit directly in the `CraftPilotPro` folder.
3. Also install **QuestieDB** (Forever version).

| Addon | |
| --- | --- |
| QuestieDB | **required**: trainers, vendor locations, gathering zones |
| Auctionator | recommended: AH prices, shopping round |
| TradeSkillMaster / Auctioneer | optional: further price sources |
| TomTom | optional: waypoints with arrow |
| EllesmereUI | optional: matching look |

## First steps

1. `/cpp` opens CraftPilot. On first start, the help explains the basics.
2. **Open the profession window once** so CraftPilot reads your recipes and skill colors.
3. Scan once at the auction house with Auctionator.
4. Follow the recommendation at the top of "Now".

Open the in-game help any time with "Help" at the bottom of the sidebar or `/cpp help`.

## Commands

| Command | |
| --- | --- |
| `/cpp` | open or close the window |
| `/cpp help` | help |
| `/cpp <profession>` | choose a profession, e.g. `/cpp blacksmithing`, `/cpp engineering` |
| `/cpp plan` · `/cpp lehrer` | Plan & shopping · Trainers & vendors |
| `/cpp trainer` · `/cpp naechster` | waypoint to the recommended or nearest trainer |
| `/cpp refresh` | read the profession window again |
| `/cpp resetpos` | reset the window position |
| `/cpp skin auto\|dark\|classic` | look |

## Good to know

- Prices are stored scans, not live offers. Missing or old prices are named, not guessed.
- Skill chances are typical values; single results vary.
- Trainer and vendor locations are travel aids; their stock is not checked live.

## Contributing

Bugs and ideas are welcome on [Discord](https://discord.gg/DpsBkHtQS) (no GitHub account needed) or as [issues](https://github.com/Necrite82/CraftPilot/issues). In-game, "Report bug" builds a ready-made report with version and Lua errors. Developer notes are in [CONTRIBUTING.md](CONTRIBUTING.md); automated tests run under Lua 5.1 and 5.4.

## License and data

CraftPilot is licensed under the **GNU GPL-3.0-only**, see [LICENSE](LICENSE).

- Recipe data: built by CraftPilot itself from the Forever client's tables (via wago.tools), [QuestieDB](https://github.com/Questie/QuestieDB), [CMaNGOS classic-db](https://github.com/cmangos/classic-db) and [AllTheThings](https://github.com/ATTWoWAddon/AllTheThings) (MIT)
- Trainer ranks: [CMaNGOS classic-db](https://github.com/cmangos/classic-db) (GPL-3.0)
- Trainer and gathering node locations: read at runtime from the [QuestieDB](https://github.com/Questie/QuestieDB) addon

Details in [DATA_SOURCES.md](DATA_SOURCES.md). World of Warcraft is a trademark of Blizzard Entertainment; CraftPilot is an independent community project.
