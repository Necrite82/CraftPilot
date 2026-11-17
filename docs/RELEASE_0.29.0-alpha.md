# CraftPilot 0.29.0-alpha

## QuestieDB ist jetzt Voraussetzung

Vorbereitung für CurseForge: CraftPilot liefert keine QuestieDB-Daten mehr mit, sondern liest sie aus dem installierten Addon **QuestieDB** (Forever-Fassung).

- **Feste Abhängigkeit:** In der TOC steht `## Dependencies: QuestieDB`. Die CurseForge-App installiert QuestieDB automatisch mit, sobald es im CurseForge-Projekt als „Required Dependency“ eingetragen ist. Bei Installation von Hand meldet das Spiel ein fehlendes QuestieDB in der Addon-Liste.
- **Lehrer:** Mitgeliefert werden nur NPC-ID, Beruf und höchster Rang (aus CMaNGOS, GPL-3.0). Name, Position, Fraktion und Titel kommen beim Einloggen aus QuestieDB. Ohne QuestieDB bleibt die handgepflegte Lehrerliste.
- **Sammelgebiete:** Mitgeliefert werden nur die IDs der Erze, Steine, Kräuter und ihrer Vorkommen samt Sammel-Skill. Wo die Vorkommen stehen, liest CraftPilot aus QuestieDB.
- **Einstellung „QuestieDB nutzen“ entfällt.** Unter „Erweitert“ zeigt CraftPilot stattdessen, ob QuestieDB gefunden wurde. Fehlt QuestieDB, weist auch die Hilfe darauf hin.
- **Import und automatischer Datenabgleich** erzeugen die schlanken Dateien reproduzierbar weiter.

Validierung: vollständige Tests unter Lua 5.1 und 5.4. Für die Tests ersetzt ein Testgerüst das installierte QuestieDB (`tests/fixtures`, nicht im Zip).
