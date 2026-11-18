# Datenherkunft / Data sources

**Stand:** 2026-11-18 · WoW Forever Client-Build 1.60.1.70959 · eigener Katalog seit CraftPilot 0.2.3-beta

## Eigener Rezeptkatalog

Seit 0.2.3-beta baut CraftPilot seinen Rezeptkatalog (`Data/Catalog`) selbst. Werkzeuge und Ablauf: [tools/catalog](tools/catalog/README.md). Quellen, Lizenzhinweise und Prüfsummen: [Data/Catalog/SOURCE.md](Data/Catalog/SOURCE.md) und `Data/Catalog/SOURCES.json`.

| Quelle | Was CraftPilot daraus liest |
|---|---|
| Tabellen des WoW-Forever-Clients (über [wago.tools](https://wago.tools)) | welche Zauber Rezepte sind, Skillfarben, Materialien, Ergebnis und Menge, Werkzeuge, Abklingzeiten, Rezeptgegenstände samt geforderter Stufe, Ruf und Spezialisierung, Händlerpreise, Camp-Objekte und ihre Boni |
| [CMaNGOS classic-db](https://github.com/cmangos/classic-db) (GPL-3.0) | Lehrerkosten und Lernstufe, wo Forever ein Classic-Rezept beim Lehrer lässt; Quests, die ein Rezept oder eine Spezialisierung verleihen |
| [QuestieDB](https://github.com/Questie/QuestieDB) (GPL-3.0, Forever-Releasepaket) | Händler, Drops und Questbelohnungen von Rezeptgegenständen, NPC-Namen und -Orte, Quest-Voraussetzungen |
| [AllTheThings](https://github.com/ATTWoWAddon/AllTheThings) (MIT) | welche Rezepte Forevers Lehrer lehren, was noch nicht veröffentlicht ist, Merchant's-Favor-Preise und Rufstufen, Lernstufen neuer Forever-Rezepte |

Übernommen werden nur Fakten (IDs, Zahlen, Namen), keine Dateien. Rezepte, die nur noch im Client stehen (z. B. aus Season of Discovery) oder laut AllTheThings noch nicht veröffentlicht sind, bleiben als `unavailable` im Katalog und werden nicht geplant. Lehrerkosten neuer Forever-Rezepte kennt keine Quelle; sie werden aus Rezepten ähnlicher Stufe geschätzt und als Schätzung gekennzeichnet.

Frühere Versionen (auf CurseForge bis 0.1.0-beta) enthielten einen Schnappschuss des GPL-3.0-Projekts [Craft Ladder](https://github.com/saintmodx/craft-ladder). Der Abschlussvergleich vor der Umstellung steht in [docs/CATALOG_COMPARE.md](docs/CATALOG_COMPARE.md): keine Abweichung bei Materialien, Ergebnis, Menge, Rezeptgegenstand und Skillfarben.

## Automatische Aktualisierung

- [catalog-inputs.yml](.github/workflows/catalog-inputs.yml) holt täglich die Client-Tabellen, das QuestieDB-Releasepaket und die AllTheThings-Daten in den Zweig `catalog-inputs` (nur wenn sich etwas geändert hat).
- [catalog-build.yml](.github/workflows/catalog-build.yml) baut daraus den Katalog neu, prüft Syntax und Tests und schlägt Änderungen als ein einziger Pull Request `data/catalog` nach `dev` vor.
- [data-sync.yml](.github/workflows/data-sync.yml) hält Lehrerliste und Sammelgebiete aktuell (`tools/sync_data.py`).

Übernommen wird nichts automatisch.

## QuestieDB als Voraussetzung

Seit 0.29 ist das Addon **QuestieDB** (Forever-Fassung) eine feste Voraussetzung (`## Dependencies: QuestieDB`); die CurseForge-App installiert es automatisch mit. Namen, Positionen, Fraktionen und Titel der Lehrer sowie die Standorte der Sammelvorkommen liest CraftPilot zur Laufzeit aus QuestieDB. CraftPilot selbst liefert davon nur IDs, Ränge und Sammel-Skills mit, keine QuestieDB-Daten.

## Lehrer

Seit 0.21 stammt die Lehrerliste aus [ThirdParty/Trainers](ThirdParty/Trainers/SOURCE.md): die gelehrten Ränge aus **CMaNGOS classic-db**; Positionen, Fraktion und Titel seit 0.29 zur Laufzeit aus dem **QuestieDB**-Addon. Beide sind in `SOURCES.json` mit Commit und SHA-256 festgehalten; `tools/import_trainers.py` erzeugt die Datei reproduzierbar. Das deckt alle zwölf Berufe ab (228 Einträge statt bisher 69 für acht Berufe). Handgepflegte Einträge in `Core/Data.lua` ergänzen nur, was dort fehlt. Der Abgleich-Workflow prüft auch diese Quellen und schlägt Änderungen nur vor, wenn sich die Lehrerliste tatsächlich ändert. Lizenzhinweise siehe SOURCE.md.

## Sammelgebiete

Seit 0.25 zeigt CraftPilot für Erze, Steine und Kräuter die Gebiete mit den meisten Vorkommen ([ThirdParty/Gathering](ThirdParty/Gathering/SOURCE.md)). Seit 0.29 kommen die Standorte zur Laufzeit aus dem QuestieDB-Addon; mitgeliefert werden nur die IDs der Vorkommen und ihr Sammel-Skill. `tools/import_gathering.py` erzeugt die Datei reproduzierbar; der Abgleich-Workflow aktualisiert sie mit.

## Spezialisierungen

Die Schritte zu Waffen-/Rüstungsschmied (samt Meister-Spezialisierungen), Gnomen-/Goblin-Ingenieur und Drachen-/Elementar-/Stammeslederer leitet `tools/catalog/spec_guides.py` ab: die verleihende Quest aus CMaNGOS, die Vorquests aus QuestieDB, die verlangten Gegenstände aus CMaNGOS.

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

## Camping

Lagerfeuer, Camp-Objekte, ihre Boni je Charakterstufe, Ausbauten und Herstellrezepte baut `tools/catalog/build_camp.py` aus den Zauberbeschreibungen und Rezepttabellen des Clients (`Data/Catalog/Camp.lua`). Aktuelle Tooltips im Spiel haben Vorrang.

