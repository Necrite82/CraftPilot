# CraftPilot 0.14.0-alpha

- New flat Cost breakdown window, accessible from the header and emphasized plan totals. Supports the selected recipe/purchase recipe, Clever skillen comparison, profession plan and shared camping plan.
- Separates additional cash needed (materials + one-time recipe acquisition), net AH value of consumed owned stock, and economic cost. Potential proceeds from freed stock and a conditional balance are shown separately and never reduce upfront purchasing funds.
- Existing recipe books and learned recipes avoid repeat acquisition charges. Missing prices and recipe/material information remain explicit unknown portions.
- Recalculate refreshes the displayed calculation. Saved automatic-route quantities remain a snapshot; old routes lacking owned-material accounting are invalidated once, preserving manual plans.
- Automatic routes now track original owned materials separately from produced intermediates, avoiding a second stock deduction in the breakdown.

This release does not reserve stock across independent plans or reoptimize the route from the cost dialog. Output sales, travel and failed-auction deposits are excluded. Vendor costs and AH proceeds remain estimates; sales based on unreliable comparisons are not credited.

Validation: automated cash/economic separation, one-time fees, owned books, missing-price, shared-material, sale/liquidity, route ownership and popup refresh regressions, bilingual rendering, syntax and archive equality pass. Live game rendering remains unverified by simulated tests.
