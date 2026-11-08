# CraftPilot

**Ein Ingame-Berufsplaner für World of Warcraft: Forever.**

CraftPilot hilft dabei, Berufe möglichst material- und kosteneffizient zu leveln. Statt einer festen Rezeptliste berücksichtigt das Addon bekannte Rezepte, vorhandene Materialien und – sofern verfügbar – die zuletzt erfassten Auktionshauspreise. Die nächsten Schritte, fehlenden Materialien und passende Lehrer lassen sich direkt im Spiel anzeigen.

**Projektstatus:** `0.2.0-alpha` · WoW Forever 1.60.x (Interface 16001) · **Noch nicht im Live-Client verifiziert**

[English documentation](README.en.md) · [Änderungsverlauf](CHANGELOG.md) · [Mitwirken](CONTRIBUTING.md)

## Aktueller Funktionsumfang

Die erste Ausbaustufe konzentriert sich auf **Ingenieurskunst und Bergbau (Skill 1–300)**.

| Bereich | Funktionen |
| --- | --- |
| Ingenieurskunst | Hinterlegte 1–300-Referenzroute mit ausgewählten Rezepten, Zwischenprodukten und Materialbedarf |
| Bergbau | Erz- und Skillbereiche bis 300 mit Gebiets- und Lehrerhinweisen |
| Individuelle Planung | Abgleich mit bekannten Rezepten und aktuell erfassten Materialien |
| Kosten | Vergleich von Zukaufkosten und Materialwert anhand gespeicherter Auctionator-Preise |
| Schmelzen | Bekannte Schmelzrezepte können als Alternative zum Kauf von Barren berücksichtigt werden |
| Navigation | Hinterlegte Lehrer- und ausgewählte Rezeptverkäufer-Positionen; Wegpunkte mit TomTom oder unterstützter Spielkartenfunktion |
| Oberfläche | Kompakte Routenübersicht, nächste Schritte, Alternativen und Einkaufsliste |

### Zwei Kostenmodelle

- **Zukauf minimieren:** Bereits vorhandene Materialien werden bevorzugt eingesetzt. Relevant ist vor allem, was zusätzlich gekauft werden müsste.
- **Materialwert berücksichtigen:** Eigene Materialien werden mit ihrem bekannten Marktwert bewertet, damit ihre Verwendung nicht automatisch als kostenlos gilt.

Eine Empfehlung hängt von den verfügbaren Daten ab. Fehlen Preise, Rezeptinformationen oder Bestände, wird die Berechnung entsprechend eingeschränkt.

## Installation

Das Projekt befindet sich noch in der Alpha-Phase. **Der GitHub-Quellcode bzw. ein Release-Paket muss zunächst veröffentlicht sein**, bevor eine Installation über dieses Repository möglich ist.

Sobald ein Paket verfügbar ist:

1. Die zu WoW Forever passende CraftPilot-Version beziehen.
2. Den Addon-Ordner `CraftPilot` im `AddOns`-Verzeichnis der WoW-Forever-Installation ablegen. Die Datei `CraftPilot.toc` muss direkt in diesem Ordner liegen.
3. Das Spiel starten und CraftPilot in der Addonliste aktivieren.
4. Das Fenster mit `/cp` öffnen und die Berufsfenster für Ingenieurskunst und Bergbau einmal aufrufen, damit bekannte Rezepte eingelesen werden.

**Optionale Erweiterungen:** Auctionator für gespeicherte Auktionshauspreise und TomTom für Navigationspfeile. Ohne Auctionator sind Preisberechnungen nur eingeschränkt möglich; ohne TomTom wird, soweit vom Client unterstützt, ein Karten-Wegpunkt versucht.

## Befehle

| Befehl | Funktion |
| --- | --- |
| `/cp` oder `/craftpilot` | Fenster öffnen oder schließen |
| `/cp ingi` | Ingenieurskunst-Plan anzeigen |
| `/cp bergbau` | Bergbau-Plan anzeigen |
| `/cp refresh` | Eingelesene Daten aktualisieren |
| `/cp trainer` | Wegpunkt zum passenden Berufslehrer |
| `/cp rezept` | Wegpunkt zu einer hinterlegten Rezeptquelle |
| `/cp liste` | Einkaufsliste im Chat ausgeben |
| `/cp mode cash` | Zusätzliche Ausgaben minimieren |
| `/cp mode value` | Marktwert vorhandener Materialien berücksichtigen |
| `/cp bank on` / `/cp bank off` | Bankbestände ein- oder ausschließen, soweit auslesbar |

## Grenzen der Alpha-Version

CraftPilot ist **noch kein vollständiger, global kostenoptimaler 1–300-Rechner**. Die aktuelle Planung verwendet eine ausgewählte Referenzroute und vergleicht zusätzliche bekannte Rezepte. Entscheidungen erfolgen schrittweise; wechselnde Skillchancen können den tatsächlichen Materialverbrauch verändern.

- Nicht jedes Forever-Rezept und jede Rezeptquelle ist bereits enthalten.
- Auctionator liefert einen **gespeicherten Preisstand**, keine garantierten Live-Preise oder verfügbaren Auktionsmengen.
- Einige Händler-, Lehrer- und Rezeptdaten müssen noch im tatsächlichen Forever-Client geprüft werden.
- Wegpunkte führen zu festen Anlaufstellen, nicht zu zufällig erscheinenden Erzvorkommen.
- Das Addon führt keine Käufe, Herstellungsaktionen, Trainerinteraktionen oder Bewegungen automatisch aus.

## Geplante Entwicklung

- Erweiterung und Prüfung der Forever-Rezept- und Lehrerdatenbank
- Bessere Planung über mehrere Skillstufen statt ausschließlich lokaler Entscheidungen
- Mehr Herstellungsberufe und alternative Skillrouten
- Präzisere Berücksichtigung von Zwischenprodukten, Rezeptquellen und verfügbaren Beständen
- Verbessertes Feedback bei fehlenden oder veralteten Preisdaten

## Fehler melden und mitwirken

Fehlerberichte, Hinweise zu falschen NPC-Positionen und Verbesserungsvorschläge sind willkommen. Besonders hilfreich sind die Spielversion, der Beruf und Skillstand, eine kurze Beschreibung der Schritte sowie gegebenenfalls Lua-Fehlertexte. Bitte keine Zugangsdaten, Charakter- oder anderen privaten Informationen veröffentlichen.

Hinweise zur Mitarbeit stehen in [CONTRIBUTING.md](CONTRIBUTING.md).

## Hinweis

CraftPilot ist ein unabhängiges Community-Projekt und steht in keiner Verbindung zu Blizzard Entertainment. World of Warcraft und zugehörige Bezeichnungen sind Marken ihrer jeweiligen Rechteinhaber.
