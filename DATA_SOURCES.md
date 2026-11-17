# Datenherkunft / Data sources

**Stand:** 2026-11-17 · WoW Forever Live-Build 1.60.1.70938 · Craft Ladder 1.11.0

## Lizenzierter Herstellungs-Rezeptkatalog

CraftPilot integriert einen Schnappschuss aus dem **GPL-3.0-Projekt [Craft Ladder](https://github.com/saintmodx/craft-ladder)**: vollständige `Data/*.lua`-Dateien für Alchemy, Blacksmithing, Enchanting, Engineering, Leatherworking und Tailoring sowie einen ausdrücklich gekennzeichneten Schmelzrezept-Auszug aus Mining.

Verwendete Quellrevision: `fd801d7af49465bbe8d24d0cba558f77f4f6a595` (Craft Ladder `v1.11.0`). Alle Eingaben samt SHA-256 stehen in [UPSTREAM.json](ThirdParty/CraftLadder/UPSTREAM.json).

- Originaldateien und deren Kopfkommentare: [ThirdParty/CraftLadder](ThirdParty/CraftLadder)
- Originale mehrstufige Urheber- und Lizenzhinweise: [CREDITS.txt](ThirdParty/CraftLadder/CREDITS.txt)
- Quellrevision, Data-Builds und Adaptionsgrenzen: [SOURCE.md](ThirdParty/CraftLadder/SOURCE.md)
- Gesamtlizenz: GNU GPL-3.0 (siehe [LICENSE](LICENSE))

Craft Ladder führt insbesondere die **Blizzard-Clienttabellen über wago.tools, CMaNGOS classic-db, QuestieDB und AllTheThings** als Datenursprünge auf. Die ursprüngliche MIT-Notiz für AllTheThings ist vollständig in `CREDITS.txt` enthalten. Es werden weder fremde Guide-Texte noch Grafiken aus Websites übernommen. Fremde Daten, Spieldateien, Namen und Marken behalten ihre jeweiligen Rechte; die GPL allein erteilt keine Rechte an Blizzard-Marken oder beliebigen fremden Datenbanken.

**Zeitliche Grenze:** Die eingebundenen Herstellungsdaten stammen aus dem **Live-Client-Build 1.60.1.70938** (erzeugt 13.–15. November 2026). Bezugsquellen von Rezepten wurden upstream aus AllTheThings und QuestieDB 1.1.1 neu aufgebaut. Serverseitige Hotfixes nach diesem Build können fehlen; bis CraftPilot 0.20.1 stammten die Daten aus den Beta-Builds 1.60.1.70425/70450 vom Oktober. Der Datenkatalog enthält Einträge, deren Trainerangebot, Beuterezept, Lernstufe oder tatsächliche Serverfreigabe noch nicht bestätigt ist. Er ist für die Planung ein Referenzdatensatz, **kein garantierter, aktueller Live-Rezeptbestand**.

## Automatischer Abgleich

`tools/sync_craft_ladder.py` übernimmt einen Craft-Ladder-Release vollständig und reproduzierbar: die sechs Herstellungskataloge, `Camp.lua` und `CREDITS.txt` unverändert, den Schmelz-Auszug aus `Mining.lua` sowie die Teilmengen für Camping, Kochen und Erste Hilfe über die bestehenden Importer. Jede Eingabe wird mit Commit und SHA-256 in `UPSTREAM.json` festgehalten; `--check` prüft in der CI, dass die gebündelten Dateien exakt daraus entstehen.

Der Workflow [data-sync.yml](.github/workflows/data-sync.yml) sucht montags und donnerstags nach einem neuen Craft-Ladder-Release. Gibt es einen, führt er Syntaxprüfung, Tests und ZIP-Bau aus und öffnet einen Pull Request mit einer Änderungsübersicht je Beruf. Übernommen wird nichts automatisch. Craft Ladder bündelt bereits Blizzard-Clienttabellen (wago.tools), QuestieDB, AllTheThings und CMaNGOS; deshalb folgt CraftPilot diesen Quellen über Craft Ladder statt sie einzeln zu importieren.

## QuestieDB als Voraussetzung

Seit 0.29 ist das Addon **QuestieDB** (Forever-Fassung) eine feste Voraussetzung (`## Dependencies: QuestieDB`); die CurseForge-App installiert es automatisch mit. Namen, Positionen, Fraktionen und Titel der Lehrer sowie die Standorte der Sammelvorkommen liest CraftPilot zur Laufzeit aus QuestieDB. CraftPilot selbst liefert davon nur IDs, Ränge und Sammel-Skills mit, keine QuestieDB-Daten.

## Lehrer

Seit 0.21 stammt die Lehrerliste aus [ThirdParty/Trainers](ThirdParty/Trainers/SOURCE.md): die gelehrten Ränge aus **CMaNGOS classic-db**; Positionen, Fraktion und Titel seit 0.29 zur Laufzeit aus dem **QuestieDB**-Addon. Beide sind in `SOURCES.json` mit Commit und SHA-256 festgehalten; `tools/import_trainers.py` erzeugt die Datei reproduzierbar. Das deckt alle zwölf Berufe ab (228 Einträge statt bisher 69 für acht Berufe). Handgepflegte Einträge in `Core/Data.lua` ergänzen nur, was dort fehlt. Der Abgleich-Workflow prüft auch diese Quellen und schlägt Änderungen nur vor, wenn sich die Lehrerliste tatsächlich ändert. Lizenzhinweise siehe SOURCE.md.

## Sammelgebiete

Seit 0.25 zeigt CraftPilot für Erze, Steine und Kräuter die Gebiete mit den meisten Vorkommen ([ThirdParty/Gathering](ThirdParty/Gathering/SOURCE.md)). Seit 0.29 kommen die Standorte zur Laufzeit aus dem QuestieDB-Addon; mitgeliefert werden nur die IDs der Vorkommen und ihr Sammel-Skill. `tools/import_gathering.py` erzeugt die Datei reproduzierbar; der Abgleich-Workflow aktualisiert sie mit.

## Spezialisierungen

Die Schritte zu Waffen-/Rüstungsschmied, Gnomen-/Goblin-Ingenieur und Drachen-/Elementar-/Stammeslederer stammen aus den mitgelieferten Craft-Ladder-Dateien (`specGuides`, Quests und Questgeber).

## Daten aus dem Spiel

CraftPilot liest den aktuellen Skill, erlernte Rezepte, Reagenzien und Skillfarbe vorrangig aus den vom Forever-Client angebotenen APIs aus:

- `C_TradeSkillUI.GetBaseProfessionInfo`, `GetRecipeInfo`, `GetRecipeSchematic`, `GetAllRecipeIDs`
- `GetProfessions`, `GetProfessionInfo`
- `C_Item.GetItemCount` für Taschen-/Bankmengen
- TomTom oder Blizzard-Kartenwegpunkte

Wenn die Schnittstelle keine vollständigen aktuellen Daten liefert, kennzeichnet CraftPilot Annahmen statt unverifizierte Tatsachen zu behaupten. Trainerstandorte sind Reisehilfen; ihr Angebot wird nicht live überprüft.

## Preise

Auctionator wird ausschließlich über seine dokumentierte **externe API v1** angesprochen:

- `GetAuctionPriceByItemID("CraftPilot", itemID)`: letzter gespeicherter Stückpreis
- `GetAuctionAgeByItemID("CraftPilot", itemID)`: Alter in Tagen, sofern diese API verfügbar ist

Preise werden nicht als Echtzeitangebote ausgegeben. Ein fehlendes Preisdatum wird als unbekannt gekennzeichnet. Sofern ein dokumentierter Händlerpreis vorliegt, wird er als separater Preisursprung markiert.

## Weiterentwicklung und Aktualisierung

Quellenänderungen für den Rezeptkatalog sollten aus einem rechtlich kompatiblen, nachweisbaren Herkunftsstand übernommen und mit Commit-ID, Client-Build, Erstellerhinweisen und Tests dokumentiert werden. Neue Fremddaten dürfen nicht ohne Prüfung der Lizenz- und Datenbankrechte übernommen werden.

## Camping reference subset (0.11)

The separate Camping view uses the pinned Craft Ladder camp file and eight matching recipe records. Original notices and GPL terms remain intact. Exact inputs, SHA-256 hashes, scope, factual cross-checks and known differences are documented in [Camping sources](docs/CAMPING_SOURCES.md) and [CAMP_SOURCES.json](ThirdParty/CraftLadder/CAMP_SOURCES.json). Client-captured recipe information takes priority over this older reference snapshot. No current boss/drop completeness is claimed.
