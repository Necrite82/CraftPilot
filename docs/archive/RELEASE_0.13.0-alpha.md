# CraftPilot 0.13.0-alpha

- Purchase recipes in Skill now, with a one-click purchase-only filter. Clicking an offer shows vendor rows directly below it; clicking a known location sets a TomTom or map waypoint.
- Learned recipe clicks open the matching profession recipe through the client API, outside combat and directly from the click path. No automatic crafting. Older clients without recipe selection retain general profession opening.
- Focused 71-record cooking/first-aid vendor subset, using existing hash-pinned inputs and original notices.
- Optional read-only QuestieDB integration for vendor names/locations and item-vendor additions with known faction eligibility. Checks public API contract and active Forever flavor; malformed/unmapped/phase-specific coordinates are rejected, with existing-data fallback. QuestieDB itself is not bundled or required.
- Learned purchase recipes move back to normal selection after client capture. Unknown recipes are not silently treated as learned plan steps.

Vendor inventory, prices and server availability remain unverified reference information. QuestieDB integration is covered with API fixtures, not an installed Forever-client acceptance test. Automated Lua, route, faction, waypoint, protected-call, optional-provider, import and archive checks pass.
