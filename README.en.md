# CraftPilot

**An in-game profession planning addon for World of Warcraft: Forever.**

CraftPilot compares currently learned recipes using materials available to the character, estimated skill-up chances and stored Auctionator prices. It also offers trainer waypoints without manual coordinate entry.

**Status:** 0.5.0-alpha · Forever 1.60.x · Interface 16001 · **Not verified in the live game client**

[Deutsch](README.md) · [Data sources](DATA_SOURCES.md) · [Changelog](CHANGELOG.md) · [Contributing](CONTRIBUTING.md)

## Supported professions

Engineering, Mining, Blacksmithing, Enchanting, Tailoring, Leatherworking, Herbalism and Alchemy.

All eight have a **1–300 milestone overview**. Currently learned crafting recipes can be ranked by estimated material cost per skill point using the current recipe difficulty and stored auction prices. Mining and Herbalism offer gathering progression overviews. Profession levels can also be read from the character profession list.

**Important limitation:** The 1–300 milestones are **not** a complete offline recipe catalog or a globally optimized 1–300 crafting route. This early alpha focuses on verifying recipe capture, cost estimates and trainer navigation in the game.

## Features

- Reads profession level, learned recipes, reagent quantities and current recipe difficulty from the open profession window.
- Compares estimated additional gold cost versus the market value of materials already owned.
- Optionally includes bank materials, depending on game API availability.
- Uses cached Auctionator prices; no real-time auction lookup.
- Provides eight profession milestone guides from skill 1 to 300, subdivided at meaningful material and rank transitions.
- Lists all stored trainers available to the player's faction, with clickable waypoints, recommended next-rank trainers and same-map distance comparisons.
- Shows missing materials for the **next recommended craft**.
- Provides a movable window with per-character saved placement, tab navigation and built-in command help.
- Uses Blizzard templates with optional ElvUI button-skin hooks; Dark and Classic themes are available.
- Does not automate buying, crafting, training or movement.

## Installation

1. Download the **[CraftPilot-0.5.0-alpha installation ZIP](https://raw.githubusercontent.com/Necrite82/CraftPilot/main/dist/CraftPilot-0.5.0-alpha.zip)** (not GitHub's source-code archive).
2. Rename the extracted directory to **CraftPilot** if needed. The \`CraftPilot.toc\` file must be directly inside that directory in the WoW Forever addons folder.
3. Enable CraftPilot, type \`/cp\`, and open the relevant profession window once.
4. Auctionator and TomTom are recommended but optional.

## Commands

| Command | Action |
| --- | --- |
| \`/cp\` / \`/craftpilot\` | Toggle window |
| \`/cp ingi\` | Engineering |
| \`/cp bergbau\` | Mining |
| \`/cp schmied\` | Blacksmithing |
| \`/cp vz\` | Enchanting |
| \`/cp schneider\` | Tailoring |
| \`/cp leder\` | Leatherworking |
| \`/cp kraeuter\` | Herbalism |
| \`/cp alchemie\` | Alchemy |
| `/cp trainer` | Recommended trainer waypoint |
| `/cp lehrer` | Browse all stored trainers and select one |
| `/cp naechster` | Nearest on-map trainer waypoint |
| `/cp etappen` | Open the milestone overview |
| `/cp hilfe` | Open the in-addon help |
| `/cp resetpos` | Reset saved window position |
| `/cp skin auto` / `dark` / `classic` | Change the visual style |
| \`/cp liste\` | Missing materials for one craft |
| \`/cp refresh\` | Refresh the open profession |
| \`/cp mode cash\` / \`/cp mode value\` | Choose cost model |
| \`/cp bank on\` / \`/cp bank off\` | Include or exclude bank materials |

## Limitations

The alpha does not guarantee a cheapest complete 1–300 route. Trainer lists are curated rather than exhaustive. A “nearest” trainer is calculated only within the same map when player coordinates are available; cross-zone travel times are unknown. Automatic UI skinning is not compatible with every third-party UI suite. Recipe difficulties and reagent data must come from the game client. Yellow/green skill-up chances are estimates. Auctionator data is a stored snapshot, not a live offer or guaranteed available quantity. Some enchants require a target item and a runed rod beyond the reagents shown. Some Alchemy recipes have cooldowns or special equipment requirements. Herbalism does not provide fixed plant spawn markers or gathering price optimization. Trainer coordinates are navigation references and must be checked in game; the Annora marker points to the Uldaman entrance.

For bug reports, include the game build, addon version, profession, skill level, reproduction steps and relevant Lua errors. Do not post private information.

## License

CraftPilot's own code is licensed under **GNU GPL-3.0-only**; see [LICENSE](LICENSE). Third-party addons and game assets retain their own rights. Sources and limitations are documented in [DATA_SOURCES.md](DATA_SOURCES.md).

World of Warcraft is a trademark of Blizzard Entertainment. This is an independent community project, not affiliated with Blizzard.
