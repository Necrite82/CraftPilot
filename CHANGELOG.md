# Changelog

## 0.2.4-beta

- Neuer interner Name **CraftPilotPro**: Addon-Ordner `CraftPilotPro`, gespeicherte Daten `CraftPilotProDB` / `CraftPilotProAccountDB`, Befehl **`/cpp`** (oder `/craftpilotpro`). Grund: Ein anderes Addon heißt ebenfalls „CraftPilot“ und belegt denselben Ordner, dieselben Daten und `/cp`. Im Spiel heißt CraftPilot weiter CraftPilot.
- Fehlerberichte erfassen nur noch Fehler aus CraftPilotPro, nicht aus dem gleichnamigen Addon
- Nach dem Update Einstellungen einmal setzen und jeden Beruf einmal öffnen

## 0.2.3-beta

- **Discord-Community** direkt im Addon: Link in der Seitenleiste, in der Hilfe, im Fenster „Fehler melden“ und mit `/cp discord`, zum Kopieren bereit
- **Empfehlung ehrlicher**: Der Skillweg rechnet nur noch mit dem, was ein Händler sicher zahlt („Händlererlös gegenrechnen“); mögliche AH-Verkäufe werden angezeigt, aber nie eingerechnet. „Zukauf“ und „Ganzer Weg“ sind klar getrennt, dazu ein **Spartipp**, wenn ein anderes Rezept je Punkt deutlich billiger ist
- Kosten-Details zeigen für die ganze Menge, was ein Händler sicher zahlt und was im AH vielleicht möglich wäre
- **Hinweis an Bank und Briefkasten**: verschiebbar (Position wird gemerkt), Schließen blendet ihn aus, bis sich die Liste ändert, und in den Einstellungen abschaltbar
- **Vorratsreservierung** zeigt jeden reservierten Gegenstand je Plan; Klick öffnet den Plan, „Nach vorn“ ändert die Reihenfolge
- AH-Status nach einem Scan: Materialien ohne Angebot zählen als „derzeit nicht im AH“ statt als fehlend; das Fenster aktualisiert sich nach dem Scan
- **Eigener Rezeptkatalog**: CraftPilot baut seine Rezept-, Händler-, Camping- und Spezialisierungsdaten jetzt selbst aus den Tabellen des Forever-Clients (Build 1.60.1.70959), QuestieDB, CMaNGOS und AllTheThings und aktualisiert sie täglich; keine Craft-Ladder-Daten mehr
- Merchant's-Favor-Rezepte nennen die nötige Rufstufe (z. B. „ab Ruf Freundlich“); Favor-Preise gelten für die Händler beider Fraktionen
- Drop-Rezepte nennen die Zahl der Gegner auch im Camping-Bereich; Rezepte, die es in Forever noch nicht gibt, werden nicht mehr eingeplant
- Neue Oberfläche: Navigation in einer **Seitenleiste** links statt Reitern oben, mit Logo, Berufswahl und Skillbalken oben sowie Einstellungen und Hilfe unten
- **Abgerundete Ecken** für Fenster, Seitenleiste, Karten, Felder und Knöpfe
- Kopf mit Seitentitel, kurzer Erklärung und Statusfeldern „AH aktuell“ und „N Gegenstände reserviert“ (Klick öffnet die Reservierung)
- Gewinn-Karten nebeneinander im Raster mit **Wertebalken** (Mitte = 0) und dezent eingefärbtem Hintergrund
- **Endgame** in vier Unterseiten: Gewinn, Raid-Vorrat, Wunschliste, Merchant's Favor
- Raid-Vorrat mit **Plus/Minus** und Fortschrittsbalken statt Regler
- Wunschliste, Vorschläge und Favor-Rezepte mit sichtbaren Knöpfen **Wegpunkt** und **Auf/Von der Wunschliste**; Favor-Karten nennen den Händler
- Neue Seite **Endgame**: Gewinn je Herstellung für erlernte Rezepte, mit gekauften und mit eigenen Materialien; eigene und gefarmte Materialien zählen mit ihrem Verkaufswert
- **Rezept-Wunschliste** mit Quellen (Lehrer, Händler, Favor, Quest, Bosse aus QuestieDB), Hinweis im Tooltip des Rezepts und der Bosse, die es droppen; Klick setzt einen Wegpunkt zum Händler oder Boss, Rechtsklick nimmt es auf die Wunschliste oder herunter
- **Raid-Vorrat**: Verbrauchsgüter mit Zielmenge, Herstellen (auch Twinks) oder AH-Kauf im Vergleich, gemeinsame Reservierung, Einkaufsliste für Auctionator
- **AH-Alarm** nach einem Auctionator-Scan: Wunschrezepte im AH und Raid-Vorrat, der im AH deutlich günstiger ist (abschaltbar)
- **Merchant's Favor**: Favor-Rezepte des Berufs mit Gewinn je Herstellung; optional Umrechnung „Silber je Favor“ (Einstellungen > Erweitert), dann zählen Favor-Rezepte im günstigsten Weg mit
- Skillweg **Schnellster Weg**: so wenige Herstellungen wie möglich
- Mehr Schutz für reservierte Gegenstände: Warnung beim Zerstören, Entzaubern und beim Verschicken an Charaktere, die nicht deine sind
- Lehrerorte zeigen den Kartennamen aus dem Spielclient
- Englische Befehle `/cp stages` und `/cp shop`
- Intern: Ordnerstruktur `Core/`, `Planning/`, `Features/`, `UI/`

## 0.1.0-beta

Erste Beta auf CurseForge. Die Versionsnummern beginnen hier neu.

- Günstigster Skillweg nach deinen AH-Preisen, wählbar zwischen günstig, sicheren Farben und nur Orange/Gelb
- Begleitfenster am Berufsfenster mit Empfehlung und Herstellen-Knopf
- Einkaufsplan mit Preisgrenzen, Einkaufsrunde am Auktionshaus, Händler- und Bank-Helfer
- Wege zu Lehrern und Händlern, Lerntour, Spezialisierungen, Rang- und Levelsperren
- Twinks: Bestände, Cooldowns, Twinks als Hersteller, Briefkasten-Hilfe
- Reservierte Gegenstände in jeder Taschenansicht markiert, Rückkauf und AH-Warnung
- Hinweise in Tooltips, Sammelgebiete, Sitzungsbilanz, Budget-Modus, Plan teilen
- Hilfe im Spiel und Willkommen beim ersten Start
- QuestieDB ist Voraussetzung und wird über CurseForge automatisch mitinstalliert
