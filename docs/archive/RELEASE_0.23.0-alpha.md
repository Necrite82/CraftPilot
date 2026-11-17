# CraftPilot 0.23.0-alpha

## Begleitfenster am Berufsfenster

Öffnest du einen Herstellungsberuf, erscheint rechts neben dem Berufsfenster ein kleines CraftPilot-Feld:

- die aktuelle Empfehlung mit Menge, fehlenden Materialien und Kosten
- „Noch ca. 3× bis Gelb (Skill 200)“, nach jeder Herstellung aktualisiert
- **Rezept wählen** springt im Berufsfenster zum empfohlenen Rezept, **Im AH suchen** wie in „Jetzt“
- **Hinweise**, wenn das empfohlene Rezept die Farbe wechselt („… ist jetzt Gelb“) oder die Ausbildungsgrenze erreicht ist; dann mit „Lehrer markieren“. Die Hinweise erscheinen zusätzlich kurz in der Bildschirmmitte.

Abschaltbar unter Einstellungen → Allgemein → „Begleitfenster am Berufsfenster“.

## Twinks: Taschen und Bank aller Charaktere

- CraftPilot merkt sich accountweit, was jeder deiner Charaktere in Taschen (beim Login, bei Änderungen, beim Ausloggen) und auf der Bank (beim Bankbesuch) hat.
- **Bestände von Twinks auf demselben Realm und derselben Fraktion zählen beim Planen mit**, weil du sie per Post schicken kannst: Fehlmengen, Einkaufsliste, Empfehlung und Auctionator-Export werden entsprechend kleiner.
- Im Rezeptdetail und in der Empfehlung steht, was von wem zu holen ist („Von Twinks holen: 3 Jade (Name)“). Die Vorrat-Spalte enthält diese Mengen.
- Abschaltbar unter Einstellungen → Allgemein → „Twinks einplanen“. Dort steht auch, wie viele Twinks erfasst sind.
- Jeder Twink muss **einmal mit 0.23 eingeloggt** werden, für die Bank einmal die Bank öffnen. Die gemeinsame Kriegsmeute-Bank wird weiterhin nicht erfasst.

## Technik

- Neue accountweite Ablage `CraftPilotAccountDB` (nur Mengen je Gegenstand, Realm, Fraktion, Stufe und Berufsstand je Charakter).
- Neue Module `Alts.lua` und `Companion.lua`; die Twink-Summen sind indiziert, die Routenberechnung bleibt so schnell wie vorher.

Validierung: vollständige Tests unter Lua 5.1 und 5.4, darunter neue Tests für Twink-Bestände (Post-erreichbar oder nur Info, Schalter, Taschen- und Bankscan) und das Begleitfenster (Anzeige, Farbwechsel, Ausbildungsgrenze, Ein/Aus). Im Spielclient nicht getestet; der Name des Berufsfensters (TradeSkillFrame bzw. ProfessionsFrame) wird zur Laufzeit erkannt.
