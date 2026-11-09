# CraftPilot 0.12.2-alpha

The economic recipe comparison is now called **Clever skillen** in German and **Smart Skilling** in English. Its implementation is renamed to `Economy.lua`; runtime methods and settings use economy names.

Saved AH deductions, selected recipe/view and the previous shopping plan used by Undo are migrated without changing the calculations. Existing new-format values take precedence, and migration is idempotent. Historical release archives remain unchanged. This release contains no visual redesign.

Validation: Lua smoke tests, migration/undo regressions, bilingual rendering and archive/source equality pass. Live game rendering is not verified by simulated tests.
