<p align="center"><img src="Media/CraftPilot.png" width="128" alt="CraftPilot"></p>

<h1 align="center">CraftPilot</h1>

<p align="center"><b>Der günstigste Weg zum Skillen deiner Berufe in WoW Forever</b><br>
nach deinen eigenen Auktionshauspreisen, mit Einkauf, Lehrern, Twinks und Herstellen an einem Ort.</p>

<p align="center">
<a href="https://www.curseforge.com/wow/addons/craftpilot">CurseForge</a> ·
<a href="README.en.md">English</a> ·
<a href="CHANGELOG.md">Änderungen</a> ·
<a href="DATA_SOURCES.md">Datenquellen</a> ·
<a href="https://github.com/Necrite82/CraftPilot/issues">Fehler melden</a>
</p>

---

**Stand:** 0.2.3-beta · WoW Forever 1.60.x (Interface 16001) · Deutsch und Englisch

> **Beta:** CraftPilot ist neu. Fehler bitte im Spiel über „Fehler melden“ oder als [GitHub-Issue](https://github.com/Necrite82/CraftPilot/issues) melden.

## Was CraftPilot macht

CraftPilot rechnet für deinen Beruf Skillpunkt für Skillpunkt aus, welcher Weg bis zur Ausbildungsgrenze am wenigsten kostet. Grundlage sind deine Auktionator-Preise und die Chance jeder Skillfarbe (Orange immer, Gelb meist, Grün selten). Rezepte, die du erst lernen musst, kommen nur in den Weg, wenn sie sich trotz Lernkosten lohnen.

Daraus entsteht eine klare Empfehlung: **was du jetzt herstellen, kaufen oder lernen solltest**, direkt im Addon und neben dem Berufsfenster.

**CraftPilot kauft, lernt und stellt nur her, wenn du klickst.**

## Funktionen

**Skillen**
- Günstigster Weg nach AH-Preisen, wählbar: *günstigster Weg*, *sichere Farben bevorzugen*, *nur Orange und Gelb* oder *schnellster Weg*
- Begleitfenster am Berufsfenster: Empfehlung, „noch N× bis zur nächsten Farbe“, **Herstellen-Knopf**, Sitzungsbilanz
- Klare Hinweise, was du für spätere Schritte **aufheben** musst, und „schon vorhanden“ statt doppelt herstellen
- Vorschau auf den nächsten Lernschritt, Warnungen bei Rang- und Levelsperren

**Einkaufen**
- Einkaufsplan für jeden Skillbereich, Preisgrenze je Material („lohnt sich bis 12s“)
- **Einkaufsrunde am Auktionshaus** mit Auctionator: Posten für Posten, Gekauftes wird abgezählt
- **Händler-Helfer** kauft genau die fehlende Menge, Bank-Helfer zeigt, was du mitnehmen musst
- Sammelgebiete für Erze, Steine und Kräuter, Verkaufserlös, Budget-Modus

**Lernen**
- Weg zu jedem Lehrer und Händler mit einem Klick, Lerntour entlang des günstigsten Weges
- Spezialisierungen (Schmied, Ingenieur, Lederer) mit Schritten und Questgeber

**Endgame**
- Gewinn je Herstellung für deine erlernten Rezepte: mit gekauften und mit eigenen Materialien (eigene und gefarmte Materialien zählen mit ihrem Verkaufswert)
- Rezepte für **Merchant's Favor** mit Gewinn je Herstellung; auf Wunsch rechnet CraftPilot Favor in Gold um und bezieht Favor-Rezepte in den günstigsten Weg ein
- **Rezept-Wunschliste** mit Quellen (Lehrer, Händler, Favor, Quest, Bosse aus QuestieDB); Bosse zeigen dein Wunschrezept im Tooltip
- **Raid-Vorrat**: Tränke, Fläschchen und Essen mit Zielmenge, Herstellen oder AH-Kauf im Vergleich, Reservierung und Einkaufsliste für Auctionator
- **AH-Alarm** nach dem Scan: Wunschrezepte im AH und günstiger Raid-Vorrat

**Twinks**
- Bestände in Taschen, Bank und Post aller Charaktere, Cooldowns, Twinks als günstigere Hersteller
- Am Briefkasten: was deine Twinks brauchen, mit vorbereitetem Brief

**Sicherheit**
- Markierung reservierter Gegenstände in jeder Taschenansicht (Standardtaschen, EllesmereUI, Baganator, Bagnon, AdiBags …)
- Warnung und „Zurückkaufen“, wenn du doch etwas Reserviertes verkaufst; Warnung am Auktionshaus, beim Zerstören, Entzaubern und beim Verschicken an fremde Charaktere
- Hinweise in Gegenstands-Tooltips

## Installation

**Über die CurseForge-App (empfohlen):** CraftPilot suchen und installieren. **QuestieDB** wird automatisch mitinstalliert.

**Von Hand:**
1. [CraftPilot-0.2.3-beta.zip](https://github.com/Necrite82/CraftPilot/raw/main/dist/CraftPilot-0.2.3-beta.zip) herunterladen (nicht das GitHub-Quellcode-Archiv).
2. Nach `World of Warcraft\_forever_\Interface\AddOns` entpacken. `CraftPilot\CraftPilot.toc` muss direkt im Ordner `CraftPilot` liegen.
3. **QuestieDB** (Forever-Fassung) zusätzlich installieren.

| Addon | |
| --- | --- |
| QuestieDB | **erforderlich**: Lehrer, Händlerstandorte, Sammelgebiete |
| Auctionator | empfohlen: AH-Preise, Einkaufsrunde |
| TomTom | optional: Wegpunkte mit Pfeil |
| EllesmereUI | optional: passendes Design |

## Erste Schritte

1. `/cp` öffnet CraftPilot. Beim ersten Start erklärt die Hilfe die Bedienung.
2. **Berufsfenster einmal öffnen**, damit CraftPilot deine Rezepte und Skillfarben einliest.
3. Am Auktionshaus einmal mit Auctionator scannen.
4. Der Empfehlung oben in „Jetzt“ folgen.

Die Hilfe im Spiel öffnest du jederzeit über „Hilfe“ unten in der Seitenleiste oder `/cp hilfe`.

## Befehle

| Befehl | |
| --- | --- |
| `/cp` | Fenster öffnen oder schließen |
| `/cp hilfe` | Hilfe |
| `/cp <Beruf>` | Beruf wählen, z. B. `/cp schmied`, `/cp ingi`, `/cp leder` |
| `/cp plan` · `/cp lehrer` | Plan & Einkauf · Lehrer & Händler |
| `/cp trainer` · `/cp naechster` | Wegpunkt zum empfohlenen bzw. nächsten Lehrer |
| `/cp refresh` | Berufsfenster neu einlesen |
| `/cp resetpos` | Fensterposition zurücksetzen |
| `/cp skin auto\|dark\|classic` | Darstellung |

## Gut zu wissen

- Preise sind gespeicherte Scans, keine Live-Angebote. Fehlende oder alte Preise nennt CraftPilot, statt sie zu raten.
- Skillchancen sind Erfahrungswerte; einzelne Ergebnisse weichen ab.
- Lehrer- und Händlerstandorte sind Reisehilfen, das Angebot wird nicht live geprüft.

## Mitmachen

Fehler und Ideen gern als [Issue](https://github.com/Necrite82/CraftPilot/issues). Im Spiel erstellt „Fehler melden“ einen fertigen Bericht mit Version und Lua-Fehlern. Hinweise für Entwickler stehen in [CONTRIBUTING.md](CONTRIBUTING.md); die automatisierten Tests laufen unter Lua 5.1 und 5.4.

## Lizenz und Daten

CraftPilot steht unter der **GNU GPL-3.0-only**, siehe [LICENSE](LICENSE).

- Rezeptdaten: [Craft Ladder](https://github.com/saintmodx/craft-ladder) (GPL-3.0)
- Lehrer-Ränge: [CMaNGOS classic-db](https://github.com/cmangos/classic-db) (GPL-3.0)
- Standorte von Lehrern und Sammelvorkommen: zur Laufzeit aus dem Addon [QuestieDB](https://github.com/Questie/QuestieDB)

Einzelheiten in [DATA_SOURCES.md](DATA_SOURCES.md). World of Warcraft ist eine Marke von Blizzard Entertainment; CraftPilot ist ein unabhängiges Community-Projekt.
