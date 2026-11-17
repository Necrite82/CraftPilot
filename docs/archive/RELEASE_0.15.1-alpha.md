# CraftPilot 0.15.1-alpha

- Fix optional QuestieDB detection for packaged Baked-mode addons. Upstream’s status indicator obtains its expansion from the Source backend and can return no expansion for a valid Baked package. CraftPilot now reads the loaded package’s X-Flavor metadata in that specific case. Explicit wrong-flavor and incompatible providers remain rejected; no database is bundled or modified.
- Replace the generic unavailable message with separate API incompatibility, wrong-flavor and missing-package-marker states.
- Fix own-profession recognition when a learned profession is absent from legacy return slots. Read every legacy return slot and fall back to the current GetProfessionInfoBySkillLineID API. Current positive skill, cap and matching skill-line ID are required. First Aid is included regardless of low rank; reference snapshots and linked/guild/NPC views do not establish ownership.
- Refresh on skill-line/spell changes so newly learned professions can receive their owned marker immediately.

Validation: the maintainer’s live First Aid response identifies profession 129 at 35/75; regression cases cover that response and 25/75, empty legacy slots, zero-skill references, unlearning and linked views. QuestieDB regressions cover the actual missing-expansion Baked status shape, modern/legacy metadata APIs, other flavors, missing markers, source mode and incompatible contracts. Existing Lua tests and the reproducible install-archive check pass. No new datasets or third-party code were imported.
