# CraftPilot 0.12.0-alpha

- New God-Mode tab compares learned, current-skill recipes using purchase costs and potential net sale value of consumed owned materials. Shows alternative recipes, material purchases and stock preserved versus the cash-cheapest option.
- Configurable AH deduction: 5% by default, slider range 0–30%. Missing or noncurrent relevant prices prevent a reliable advantage claim. Sales and purchases stay manual.
- A selected option can replace the shopping plan; the previous plan can be restored once from God-Mode.
- Camping shopping plan combines objects across professions, supports +1/+5 and reduces quantities on click. Shared materials and owned stock are counted once.
- Professions without authored stage guides display their current learned skill-up recipes where available.
- Version notices without CurseForge: group/raid/guild version exchange, one-time local chat notification, status in Settings and a copyable fixed release link. Both clients need 0.12 or newer; no direct GitHub lookup or automatic installation.
- German/English UI extended for the new views.

God-Mode compares the next skill step and direct ingredients, not a complete route to 300 or recursive make-or-buy alternatives. Existing plans do not reserve stock in this comparison. Integer craft batches can yield different expected skill points; economic costs are compared per expected point. Output sales and unsuccessful auction deposits are excluded. Market prices do not guarantee a sale or purchase. Unverified future skill paths and additional trainer locations remain outstanding.

Automated Lua, economic regression, camping aggregation, language and archive checks pass. Live game layout and market execution are not verified by those checks.
