# CraftPilot 0.21.0-alpha

## Neue, aufgeräumte Oberfläche

- **Eine Kopfzeile statt fünf Bänder:** Logo, Berufsauswahl als Menü (eigene Berufe zuerst, mit Skillstand), Skillbalken mit nächstem Ausbildungsrang im Tooltip, Punkt für den AH-Preisstand und ein Zahnrad für die Einstellungen. Die zwölf Berufsbuttons, Untertitel, Statusbox und Designschalter entfallen.
- **Vier Reiter statt sieben:** Jetzt · Plan & Einkauf · Lehrer & Händler · Camping. Etappen sind eine anklickbare Leiste im Plan, Materialien stehen im Rezeptdetail, Clever skillen und die Kostenkalkulation sind aus dem Rezeptdetail erreichbar.
- **Jetzt:** links eine kompakte Rezeptliste (Skillfarbe, fehlende Teile, Chance, Kosten je Punkt; Sortierung per Klick auf die Spaltenköpfe, Filter als Menü), rechts das gewählte Rezept mit Menge, Materialien, „Berufsfenster öffnen“, „Auf Einkaufsliste“ und aufklappbaren Kosten-Details. Kauf- und Lehrerrezepte zeigen Lernkosten, Kostenvergleich und Händler mit Wegpunkt.
- **Plan & Einkauf:** Bereich wählen, Plan erstellen, zwischen Einkaufen, Herstellen und Details wechseln. Selbst hinzugefügte Materialien erscheinen als eigener Abschnitt in derselben Einkaufsliste; Summe, Chat-Ausgabe und Auctionator-Export bleiben unten fest stehen.
- **Lehrer & Händler:** Lehrer mit Empfehlung, Nähe und gelehrtem Rang, darunter lernbare Rezepte mit Wegpunkt. Das vollständige Händlerverzeichnis ist als zweite Seite erreichbar.
- **Einstellungen:** gruppiert in Allgemein, Rezeptwahl und Route, Darstellung; Feineinstellungen unter „Erweitert“.
- **Optik:** flache Flächen mit nur einer Rahmenebene, Gold nur für Auswahl und Hauptaktionen, Skillfarben als Farbsprache.

## Aktuelle Daten

- Rezepte, Händler und Camping aus **Craft Ladder 1.11.0** (Live-Build 1.60.1.70938 statt Beta-Daten vom Oktober): 33 neue Rezepte, geänderte Taschenrezepte, Grober Schleifstein bis Skill 90, 393 geänderte Bezugsquellen, 748 Händlerrezepte.
- **Lehrer für alle zwölf Berufe** aus QuestieDB (Positionen) und CMaNGOS (Ränge): 228 statt 69 Einträge, neu für Kochen, Erste Hilfe, Angeln und Kürschnerei. Sieben Lehrer in Sturmwind stehen jetzt an den richtigen Koordinaten.
- Automatischer Abgleich: Der Workflow `data-sync.yml` schlägt neue Datenstände zweimal pro Woche als Pull Request vor.

## Hinweise

- `/cp etappen` öffnet jetzt Plan & Einkauf, `/cp hilfe` die Einstellungen. Alle übrigen Befehle bleiben gleich.
- Validierung: Syntax und vollständige Tests unter Lua 5.1 und 5.4, Herkunftsprüfung aller Daten, Installationsarchiv aus der Freigabeliste. Die Tests simulieren Spiel-Widgets; Darstellung und Bedienung im laufenden Forever-Client sind noch nicht beobachtet. Rückmeldungen bitte über „Fehler melden“ oder als GitHub-Issue.
