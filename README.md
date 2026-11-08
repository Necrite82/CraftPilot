# CraftPilot

**Ingame-Berufsplanung für World of Warcraft: Forever.**

CraftPilot zeigt die nächsten sinnvollen Schritte beim Leveln von Berufen direkt im Spiel. Das Addon kombiniert die im Berufsfenster sichtbaren Rezepte und Materialien mit vorhandenen Beständen, geschätzten Skillchancen und den zuletzt gespeicherten Auktionshauspreisen. Bekannte Berufslehrer können ohne manuelle Koordinateneingabe als Wegpunkt gesetzt werden.

**Entwicklungsstand:** 0.6.0-alpha · Forever 1.60.x · Interface 16001 · **Noch nicht im Live-Client getestet**

[English](README.en.md) · [Datenquellen](DATA_SOURCES.md) · [Änderungsverlauf](CHANGELOG.md) · [Mitwirken](CONTRIBUTING.md)

## Unterstützte Berufe

- Ingenieurskunst
- Bergbau
- Schmiedekunst
- Verzauberkunst
- Schneiderei
- Lederverarbeitung
- Kräuterkunde
- Alchemie

Für jeden Beruf ist eine **1–300-Etappenübersicht** hinterlegt. Für die sechs Herstellungsberufe werden **aktuell erlernte, aus dem Spiel auslesbare Rezepte** nach geschätzten zusätzlichen Materialkosten pro Skillpunkt verglichen. Bergbau und Kräuterkunde zeigen geeignete Sammelstufen und Gebiete. Berufs-Skillwerte können auch ohne offenes Rezeptfenster über die Charakter-Berufsübersicht ausgelesen werden.

**Wichtige Abgrenzung:** Die 1–300-Etappen sind eine Orientierung und noch **keine vollständige Offline-Rezeptdatenbank**. Eine durchgehend durchgerechnete, global günstigste Einkaufs- und Herstellungsroute bis 300 sowie sämtliche Lehrerrezepte, Händler- und Beuterezepte sind noch nicht implementiert. Diese Alpha ist zunächst für das Testen von Rezeptauslesung, Kostenvergleich und Navigation gedacht.

## Funktionen

| Funktion | Beschreibung |
| --- | --- |
| Beruf erkennen | Ingenieurskunst, Bergbau, Schmiedekunst, Verzauberkunst, Schneiderei, Lederverarbeitung, Kräuterkunde, Alchemie |
| Rezepte erfassen | Bekannte Rezepte, Reagenzien und aktuelle Schwierigkeitsfarben aus dem geöffneten Berufsfenster übernehmen |
| Kostenvergleich | Aktuell mögliche Rezepte nach geschätzten Kosten pro Skillpunkt sortieren |
| Eigene Materialien | Taschenbestände abziehen; optional Bankbestände, soweit die Spiel-API sie bereitstellt |
| Auktionshauspreise | Letzte gespeicherte Einzelpreise aus Auctionator auswerten |
| Kostenmodus | Zusätzliche Ausgaben minimieren oder den Marktwert eigener Materialien berücksichtigen |
| Skill-Etappen | Kürzere, nach Material- und Ausbildungswechseln strukturierte Abschnitte von 1 bis 300 für alle acht Berufe |
| Wegpunkte | Liste aller hinterlegten Lehrer der eigenen Fraktion; einzeln per Klick auswählbar, mit Rang-Empfehlung und Same-Map-Abstand |
| Einkaufsliste | Fehlende Materialien für **die nächste empfohlene Herstellung** |
| Oberfläche | Verschiebbares Fenster, gespeicherte Position und fünf Registerkarten |
| Themes | Automatischer Stil mit Blizzard-Templates und optional EllesmereUI-Hooks; Dunkel/Klassisch auswählbar |
| Hilfe | Integrierte Befehlsübersicht über `/cp hilfe` |

**Keine Automatisierung:** CraftPilot kauft, verkauft, bewegt den Charakter, lernt und stellt nichts selbstständig her.

## Installation

1. Das **[CraftPilot-0.6.0-alpha Installations-ZIP](https://raw.githubusercontent.com/Necrite82/CraftPilot/main/dist/CraftPilot-0.6.0-alpha.zip)** herunterladen (nicht das GitHub-Quellcode-Archiv).
2. Den entpackten Ordner gegebenenfalls in **CraftPilot** umbenennen. Im WoW-Forever-Addonverzeichnis muss die Datei \`CraftPilot/CraftPilot.toc\` unmittelbar im Addon-Ordner liegen.
3. WoW Forever starten und das Addon aktivieren.
4. Im Chat \`/cp\` eingeben und den gewünschten Beruf auswählen.
5. **Das Berufsfenster im Spiel einmal öffnen**, damit CraftPilot die gelernten Rezepte und die aktuelle Skillfarbe übernimmt.

**Empfohlen:** eine Forever-kompatible Version von [Auctionator](https://www.curseforge.com/wow/addons/auctionator) und [TomTom](https://www.curseforge.com/wow/addons/tomtom). Die Addons sind optional, verbessern aber Kostenabschätzungen und Navigation.

Die Skillfarben sind nur am aktuell eingelesenen Skillstand zuverlässig. Für Kräuterkunde reicht zur Anzeige des Skillstands die erlernte Profession; eine Rezeptliste ist dafür nicht erforderlich. Bei einem Skillaufstieg das Berufsfenster erneut öffnen beziehungsweise aktualisieren.

## Befehle

| Befehl | Funktion |
| --- | --- |
| \`/cp\` oder \`/craftpilot\` | Fenster öffnen / schließen |
| \`/cp ingi\` | Ingenieurskunst |
| \`/cp bergbau\` | Bergbau |
| \`/cp schmied\` | Schmiedekunst |
| \`/cp vz\` | Verzauberkunst |
| \`/cp schneider\` | Schneiderei |
| \`/cp leder\` | Lederverarbeitung |
| \`/cp kraeuter\` | Kräuterkunde |
| \`/cp alchemie\` | Alchemie |
| `/cp trainer` | Empfohlenen Lehrer markieren |
| `/cp lehrer` | Liste hinterlegter Lehrer und direkte Auswahl öffnen |
| `/cp naechster` | Nächsten Lehrer auf derselben Karte markieren |
| `/cp etappen` | Skill-Etappen öffnen |
| `/cp hilfe` | Ingame-Hilfe öffnen |
| `/cp resetpos` | Fensterposition zurücksetzen |
| `/cp skin auto` / `dark` / `classic` | Darstellungsmodus ändern |
| \`/cp liste\` | Fehlende Materialien für die nächste Herstellung ausgeben |
| \`/cp refresh\` | Geöffnetes Berufsfenster erneut einlesen |
| \`/cp mode cash\` | Zusätzliche Ausgaben minimieren |
| \`/cp mode value\` | Eigene Materialien zum Marktwert berücksichtigen |
| \`/cp bank on\` / \`/cp bank off\` | Bankbestände nach API-Verfügbarkeit ein-/ausschalten |

## Neu in 0.6: Bank, Ellesmere UI und Rezeptkarten

CraftPilot verwendet die offizielle **EllesmereUI-Skinning-API** für eigene Fenster, Buttons, Registerkarten und Scrollleisten, wenn EllesmereUI vorhanden und die Skin-Integration dort freigegeben ist. Andernfalls stehen Standard-, Dunkel- und Klassisch-Darstellung zur Verfügung.

Das Fenster kann an der Kopfzeile bewegt und **unten rechts am Ziehgriff vergrößert oder verkleinert** werden. Größe und Position werden pro Charakter gespeichert.

Im Tab **Jetzt skillen** erscheinen auswählbare Rezeptkarten mit Symbol aus dem WoW-Client, Name, geschätzter Skillchance, geschätzten Kosten pro Skillpunkt und fehlenden Materialien. Über die oberen Schaltflächen wird nach **Preis, Skillchance, Zukaufmenge oder Name** sortiert. Das angeklickte Rezept steuert die Materialliste.

**Bank:** Die Bankberücksichtigung ist für neue Einstellungen standardmäßig an. Beim Öffnen der Bank wird der Bestand der bisher bekannten Rezeptmaterialien erfasst. Nach dem Schließen wird ein ausdrücklich als **letzter Stand** markierter Snapshot verwendet. Er kann veralten. Noch nicht erfasste Bankmaterialien werden nicht als bestätigt vorhanden gewertet. Die Erfassung umfasst nicht die gemeinsame Account-/Warband-Bank. Im Material-Tab kann die Bank ein- oder ausgeschaltet werden.

Weitere Befehle: `/cp sort cost`, `/cp sort chance`, `/cp sort missing`, `/cp sort name`. Alle Befehle sind über `/cp hilfe` ingame abrufbar.

## Alpha-Hinweise

- Kein Anspruch auf die mathematisch günstigste gesamte Skillroute 1–300.
- Aufgeführte Etappen sind **keine** Mengen- oder Preisgarantie. Kräuterkunde bietet keine Erntekostenoptimierung oder festen Pflanzen-Spawnpunkte.
- Auctionator-Preise sind **gespeicherte Scans**, keine Echtzeitpreise, Lagerbestände oder garantierten Kaufmöglichkeiten.
- Rezepte mit nicht eindeutig auslesbaren Reagenzien werden nicht preislich bewertet. Bei Alchemie können bestimmte Rezepte zusätzliche Geräte, Voraussetzungen oder Abklingzeiten haben.
- Enchants können ein geeignetes Zielitem und eine passende Runenrute erfordern; solche Voraussetzungen fließen nicht immer in die Materialrechnung ein.
- Die geschätzten Skillchancen für gelbe/grüne Rezepte sind Näherungen. Die tatsächlichen Erfolge schwanken.
- Die Lehrerliste enthält **alle hinterlegten, fraktionskompatiblen** Trainer. Die gespeicherte NPC-Datenbank ist nicht vollständig.
- „Empfohlen“ bedeutet: Der Trainer kann den nächsten benötigten Berufs-Rang lehren. Ein geeigneter Trainer auf der aktuellen Karte wird bevorzugt.
- „Nächster“ ist ausschließlich ein Vergleich der Kartenkoordinaten **auf derselben Karte**, keine Entfernung in Metern und keine Schätzung der Reisezeit über Zonengrenzen.
- Auto-Skinning kann die von Blizzard bereitgestellten UI-Templates und ggf. vorhandene EllesmereUI-Skin-Funktionen nutzen. Für andere UI-Komplettpakete gibt es keine garantierte automatische Übernahme.
- Trainerkoordinaten sind Reisehilfen, keine Live-Prüfung der Trainerangebote. Der Uldaman-Wegpunkt markiert den Zugang, nicht Annoras Standort im Inneren.
- Noch keine automatisierte Verarbeitung gekaufter oder selbst hergestellter Zwischenprodukte für eine vollständige Zukunftsroute.

## Mithelfen und testen

Zur Fehlerdiagnose im Spiel zunächst \`/console scriptErrors 1\` setzen. Bei einem Issue bitte Clientversion, CraftPilot-Version, Beruf, Skillstand, Vorgehensweise und gegebenenfalls Lua-Fehler angeben. Keine persönlichen Daten oder Zugangsdaten hochladen.

Die Lua-Syntax und Grundfunktionen werden automatisiert mit [Lua-Smoketests](tests/test.lua) geprüft. Diese Tests ersetzen **keinen** Test im echten Forever-Client.

## Lizenz und Daten

CraftPilot-Quellcode ist unter **GNU GPL-3.0-only** lizenziert, siehe [LICENSE](LICENSE). Fremde Addons und Spieldaten unterliegen weiterhin den Rechten ihrer jeweiligen Inhaber. Die Datenherkunft und Grenzen sind in [DATA_SOURCES.md](DATA_SOURCES.md) erläutert.

World of Warcraft ist eine Marke von Blizzard Entertainment. CraftPilot ist ein unabhängiges Community-Projekt und nicht mit Blizzard verbunden.
