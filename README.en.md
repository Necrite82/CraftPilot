# CraftPilot

**An in-game profession planning addon for World of Warcraft: Forever.**

CraftPilot is designed to help players level professions with fewer unnecessary purchases. It combines a curated profession route with known recipes, available materials and, when possible, recently recorded auction prices.

**Status:** `0.2.0-alpha` · WoW Forever 1.60.x (Interface 16001) · **Not yet verified in the live game client**

[Deutsche Dokumentation](README.md) · [Changelog](CHANGELOG.md) · [Contributing](CONTRIBUTING.md)

## Current scope

The initial version covers **Engineering and Mining (skill 1–300)**.

| Area | Features |
| --- | --- |
| Engineering | Curated 1–300 reference route, selected recipes, intermediate components and estimated materials |
| Mining | Ore skill ranges, recommended zones and trainer guidance up to 300 |
| Personal planning | Takes learned recipes and recorded materials into account |
| Prices | Compares additional purchase cost and the market value of owned materials using stored Auctionator prices |
| Smelting | Can consider known smelting recipes as an alternative to buying bars |
| Navigation | Built-in locations for profession trainers and selected recipe vendors; TomTom or supported map waypoints |
| Interface | Current step, alternative recipes, route overview and shopping list |

### Cost modes

- **Cash (`/cp mode cash`):** Focus on the additional gold required, using owned materials first.
- **Value (`/cp mode value`):** Include the known market value of materials already in inventory.

Recommendations depend on the available recipe, inventory and price data. Missing data may limit the calculation.

## Installation

This project is in alpha. **Source files or a release package still need to be published in this repository** before it can be installed from GitHub.

Once a compatible package is available:

1. Obtain the CraftPilot package for WoW Forever.
2. Place the `CraftPilot` folder in the game's `AddOns` directory, with `CraftPilot.toc` directly inside that folder.
3. Enable the addon in the game.
4. Use `/cp` to open the panel. Open the Engineering and Mining profession windows once so available recipes can be recorded.

**Optional addons:** Auctionator provides stored auction prices; TomTom provides navigation arrows. Without Auctionator, cost estimates are limited. Without TomTom, CraftPilot attempts an available built-in map waypoint.

## Commands

| Command | Action |
| --- | --- |
| `/cp` or `/craftpilot` | Toggle the addon window |
| `/cp ingi` | Engineering |
| `/cp bergbau` | Mining |
| `/cp refresh` | Refresh recorded data |
| `/cp trainer` | Profession trainer waypoint |
| `/cp rezept` | Waypoint for a recorded recipe source |
| `/cp liste` | Print the shopping list |
| `/cp mode cash` | Minimize additional purchases |
| `/cp mode value` | Include the market value of owned materials |
| `/cp bank on` / `/cp bank off` | Include or exclude bank inventory when available |

## Alpha limitations

The current version **does not guarantee the mathematically cheapest route from 1 to 300**. It uses a curated reference route and compares currently known alternatives, making local planning decisions. Skill-up probabilities may change the number of crafts required.

- The recipe and vendor databases are not exhaustive.
- Auctionator prices are snapshots, not guaranteed live prices or available quantities.
- Some trainer, vendor and recipe details still require in-game verification.
- Mining routes refer to zones, not individual randomized ore spawn points.
- The addon does not automate purchases, crafting, NPC interactions or movement.

## Roadmap

- Expand and validate Forever recipe and trainer data
- Improve multi-step route optimization
- Support additional crafting professions
- Improve intermediate-material and recipe-source planning
- Better handling of missing or outdated market prices

## Feedback and contributions

Bug reports, incorrect trainer locations and feature requests are welcome. Useful reports include the game version, profession and skill level, reproduction steps, and Lua errors where relevant. Do not post account details or other private information.

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## Disclaimer

CraftPilot is an independent community project and is not affiliated with Blizzard Entertainment. World of Warcraft and related names are trademarks of their respective owners.
