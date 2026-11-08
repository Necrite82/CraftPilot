# Datenherkunft / Data sources

**Stand: 2026-11-08 — Forever 1.60.x — Alpha**

## Grundsatz

CraftPilot übernimmt bekannte Rezepte, Reagenzien, aktuelle Schwierigkeitsfarben und Skillstände bevorzugt **direkt aus der WoW-Forever-Addon-API auf dem jeweiligen Client**. Es werden keine vollständigen fremden Guide-Texte, Bilder, Datenbanken oder Addon-Quellcodes in diesem Projekt vervielfältigt.

Die 1–300-Etappen sind eigene, grob zusammengefasste Orientierungen. Sie enthalten **keine** importierte vollständige Rezeptdatenbank und dürfen nicht als garantierter Skill- oder Einkaufsplan verstanden werden.

Die Berufslehrer-Tabelle enthält einzelne sachliche Ortsangaben aus öffentlich zugänglichen Spielerinformationen, die hier eigenständig kuratiert wurden. Diese Fakten sind weder ein vollständiger NPC-Export noch ein Ersatz für die Prüfung im Spiel. Quellenhinweise allein begründen keine Nutzungsrechte an umfangreichen fremden Datenbeständen.

## Eingelesene Daten

- Profession, Skill, Skill-Obergrenze: \`C_TradeSkillUI.GetBaseProfessionInfo\`
- Rezeptliste und aktuelle Schwierigkeit: \`C_TradeSkillUI.GetAllRecipeIDs\`, \`GetRecipeInfo\`
- Reagenzien: \`C_TradeSkillUI.GetRecipeSchematic\`
- Taschenbestand: \`C_Item.GetItemCount\`
- AH-Snapshot: öffentliche Auctionator-API, wenn installiert
- Wegpunkte: TomTom-API oder unterstützte Blizzard-Kartenfunktion

API-Referenz: https://warcraft.wiki.gg/wiki/API:C_TradeSkillUI.GetBaseProfessionInfo

API-Referenz: https://warcraft.wiki.gg/wiki/API_C_TradeSkillUI.GetRecipeSchematic

## Reise- und Ausbildungsinformationen

Orts- und Ranghinweise wurden mit diesen öffentlich verfügbaren Informationen abgeglichen:

- Ingenieurskunst: https://mobalytics.gg/wow-forever/guides/engineering-profession-guide
- Bergbau: https://www.icy-veins.com/wow-forever/mining-leveling-guide
- Schmiedekunst: https://www.method.gg/wow-forever/blacksmithing-in-wow-forever-leveling-guide-and-trainers
- Verzauberkunst: https://www.icy-veins.com/wow-forever/enchanting-leveling-guide
- Schneiderei: https://www.icy-veins.com/wow-forever/tailoring-leveling-guide
- Lederverarbeitung: https://www.icy-veins.com/wow-forever/leatherworking-leveling-guide

Aufgrund von Beta-Änderungen, Kartenvarianten und serverseitigen Änderungen kann eine Position oder ein Trainerangebot abweichen. Insbesondere der Wegpunkt für **Annora** zeigt einen Zugang zu **Uldaman**, nicht den Standort innerhalb der Instanz.

## Rechte und Hinweise

Der eigenständig entwickelte **Programmcode** unterliegt der GPL-3.0-only. Dadurch werden keine Rechte an Spielinhalten, Datenbanken, Marken oder Code Dritter eingeräumt. Vollständige fremde Sammlungen und urheberrechtlich geschützte Guide-Texte dürfen nicht allein aufgrund eines Quellenverweises übernommen werden.

Fehlerhafte Orts- oder Spieldaten bitte als Issue melden; Änderungen sollten anhand aktueller Spieltests überprüft werden.
