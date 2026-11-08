# CraftPilot 0.12.1-alpha

- Recipe rows show current client color and Orange/Yellow/Green ranges plus Gray-from thresholds. Missing, inconsistent and conflicting reference ranges stay explicit.
- Orange/Yellow preference enabled by default for standard recommendations and automatic routes; Green remains selectable and available to God-Mode. Unpriced recipes do not gain priority merely through color.
- Profession review in Settings covers all twelve professions and reports reference coverage and client-color conflicts.
- Adds only 162 cooking/first-aid spell-ID threshold records from existing pinned inputs.
- Current client difficulty and materials take precedence in known automatic-route candidates; conflicting historical colors are not extrapolated to future skills.
- Old automatic proposals are invalidated once; manual plans and explicit recipe selections remain intact.

The available reference data is still from October builds. Review found no changed threshold rows for the seven existing recipe catalogs and 17 inconsistent sequences, now excluded from threshold-based forecasts. Gathering formulas were not treated as live-confirmed crafting thresholds. Open your own profession windows to refresh current recipe colors. No complete current-live verification is claimed.

Automated Lua, threshold-boundary, route-policy, client-precedence, bilingual, import and archive checks pass. In-game rendering remains unverified by simulated tests.
