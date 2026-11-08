# Datenherkunft / Data sources

**Stand:** 2026-11-08 · WoW Forever · CraftPilot 0.8.0-alpha

## Lizenzierter Herstellungs-Rezeptkatalog

CraftPilot integriert einen Schnappschuss aus dem **GPL-3.0-Projekt [Craft Ladder](https://github.com/saintmodx/craft-ladder)**: vollständige `Data/*.lua`-Dateien für Alchemy, Blacksmithing, Enchanting, Engineering, Leatherworking und Tailoring sowie einen ausdrücklich gekennzeichneten Schmelzrezept-Auszug aus Mining.

Verwendete Quellrevision: `b9c61346ad4cf63245f35cadb1e0a88467fb6e75`.

- Originaldateien und deren Kopfkommentare: [ThirdParty/CraftLadder](ThirdParty/CraftLadder)
- Originale mehrstufige Urheber- und Lizenzhinweise: [CREDITS.txt](ThirdParty/CraftLadder/CREDITS.txt)
- Quellrevision, Data-Builds und Adaptionsgrenzen: [SOURCE.md](ThirdParty/CraftLadder/SOURCE.md)
- Gesamtlizenz: GNU GPL-3.0 (siehe [LICENSE](LICENSE))

Craft Ladder führt insbesondere die **Blizzard-Clienttabellen über wago.tools, CMaNGOS classic-db, QuestieDB und AllTheThings** als Datenursprünge auf. Die ursprüngliche MIT-Notiz für AllTheThings ist vollständig in `CREDITS.txt` enthalten. Es werden weder fremde Guide-Texte noch Grafiken aus Websites übernommen. Fremde Daten, Spieldateien, Namen und Marken behalten ihre jeweiligen Rechte; die GPL allein erteilt keine Rechte an Blizzard-Marken oder beliebigen fremden Datenbanken.

**Zeitliche Grenze:** Die eingebundenen Herstellungsdaten stammen aus **1.60.1.70425 und 1.60.1.70450** vom Oktober 2026. Diese Versionen sind älter als neuere Forever-Builds. Der Datenkatalog enthält Einträge, deren Trainerangebot, Beuterezept, Lernstufe oder tatsächliche Serverfreigabe noch nicht bestätigt ist. Er ist für die Planung ein Referenzdatensatz, **kein garantierter, aktueller Live-Rezeptbestand**.

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
