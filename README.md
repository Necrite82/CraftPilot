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

**Stand:** 1.2.1 · WoW Forever 1.60.x (Interface 16001) · Deutsch und Englisch

> **Fragen, Ideen und Fehler:** im Spiel über „Fehler melden“, im [Discord](https://discord.gg/DpsBkHtQS) oder als [GitHub-Issue](https://github.com/Necrite82/CraftPilot/issues).

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
- **Budget** direkt auf „Jetzt“: wie weit dein Gold reicht, Warnung, wenn ein Schritt dein Budget sprengt
- **Zwei Berufe zusammen**: Zwischenprodukte mit deinem zweiten Beruf selbst herstellen (z. B. Barren verhütten) – Ersparnis und Skillpunkte dort
- **Bestätigte Skillgrenzen**: CraftPilot schreibt mit, bei welchem Skill es Punkte gab; geteilte Daten machen die Farbgrenzen für alle genauer

**Einkaufen**
- Einkaufsplan für jeden Skillbereich, Preisgrenze je Material („lohnt sich bis 12s“)
- **Einkaufsrunde am Auktionshaus** mit Auctionator: Posten für Posten, Gekauftes wird abgezählt
- **Händler-Helfer** kauft genau die fehlende Menge, Bank-Helfer zeigt, was du mitnehmen musst
- Sammelgebiete für Erze, Steine und Kräuter, Verkaufserlös
- **Jetzt günstig**: Materialien deines Weges, die heute deutlich unter ihrem üblichen Preis liegen, mit Ersparnis
- **Farmen oder kaufen** nach deinem eigenen Sammeltempo
- Preise aus **Auctionator, TradeSkillMaster oder Auctioneer**

**Lernen**
- Weg zu jedem Lehrer und Händler mit einem Klick, Lerntour entlang des günstigsten Weges
- Spezialisierungen (Schmied, Ingenieur, Lederer) mit Schritten und Questgeber

**Endgame**
- Gewinn je Herstellung für deine erlernten Rezepte: mit gekauften und mit eigenen Materialien (eigene und gefarmte Materialien zählen mit ihrem Verkaufswert)
- Rezepte für **Merchant's Favor** mit Gewinn je Herstellung; auf Wunsch rechnet CraftPilot Favor in Gold um und bezieht Favor-Rezepte in den günstigsten Weg ein
- **Rezept-Wunschliste** mit Quellen (Lehrer, Händler, Favor, Quest, Bosse aus QuestieDB); Bosse zeigen dein Wunschrezept im Tooltip
- **Raid-Vorrat**: Tränke, Fläschchen und Essen mit Zielmenge, Herstellen oder AH-Kauf im Vergleich, Reservierung und Einkaufsliste für Auctionator
- **AH-Alarm** nach dem Scan: Wunschrezepte im AH und günstiger Raid-Vorrat

**Gegenstände**
- Jeder Gegenstand mit allen Rezepten, in denen er Zutat ist, und wer ihn herstellt – Rezeptkette, Preis, Vorrat, Drops; fehlende Rezepte deines Berufs mit Wegpunkt
- **Jetzt herstellbar** aus Taschen, Bank, Post und Twinks, **Merkliste** mit AH-Alarm, **Behalten oder verkaufen** im Tooltip

**Twinks**
- Bestände in Taschen, Bank und Post aller Charaktere, Cooldowns, Twinks als günstigere Hersteller
- **Post-Packer**: Am Briefkasten packt CraftPilot den Brief an deinen Twink mit genau den fehlenden Mengen – du klickst nur noch „Senden“

**Sicherheit**
- Markierung reservierter Gegenstände in jeder Taschenansicht (Standardtaschen, EllesmereUI, Baganator, Bagnon, AdiBags …)
- Warnung und „Zurückkaufen“, wenn du doch etwas Reserviertes verkaufst; Warnung am Auktionshaus, beim Zerstören, Entzaubern und beim Verschicken an fremde Charaktere
- Hinweise in Gegenstands-Tooltips

## Installation

**Über die CurseForge-App (empfohlen):** CraftPilot suchen und installieren. **QuestieDB** wird automatisch mitinstalliert.

**Von Hand:**
1. [CraftPilot-1.2.1.zip](https://github.com/Necrite82/CraftPilot/raw/main/dist/CraftPilot-1.2.1.zip) herunterladen (nicht das GitHub-Quellcode-Archiv).
2. Nach `World of Warcraft\_forever_\Interface\AddOns` entpacken. `CraftPilotPro\CraftPilotPro.toc` muss direkt im Ordner `CraftPilotPro` liegen.
3. **QuestieDB** (Forever-Fassung) zusätzlich installieren.

| Addon | |
| --- | --- |
| QuestieDB | **erforderlich**: Lehrer, Händlerstandorte, Sammelgebiete |
| Auctionator | empfohlen: AH-Preise, Einkaufsrunde |
| TradeSkillMaster / Auctioneer | optional: weitere Preisquellen |
| TomTom | optional: Wegpunkte mit Pfeil |
| EllesmereUI | optional: passendes Design |

## Erste Schritte

1. `/cpp` öffnet CraftPilot. Beim ersten Start erklärt die Hilfe die Bedienung.
2. **Berufsfenster einmal öffnen**, damit CraftPilot deine Rezepte und Skillfarben einliest.
3. Am Auktionshaus einmal mit Auctionator scannen.
4. Der Empfehlung oben in „Jetzt“ folgen.

Die Hilfe im Spiel öffnest du jederzeit über „Hilfe“ unten in der Seitenleiste oder `/cpp hilfe`.

## Befehle

| Befehl | |
| --- | --- |
| `/cpp` | Fenster öffnen oder schließen |
| `/cpp hilfe` | Hilfe |
| `/cpp <Beruf>` | Beruf wählen, z. B. `/cpp schmied`, `/cpp ingi`, `/cpp leder` |
| `/cpp plan` · `/cpp lehrer` | Plan & Einkauf · Lehrer & Händler |
| `/cpp trainer` · `/cpp naechster` | Wegpunkt zum empfohlenen bzw. nächsten Lehrer |
| `/cpp refresh` | Berufsfenster neu einlesen |
| `/cpp resetpos` | Fensterposition zurücksetzen |
| `/cpp skin auto\|dark\|classic` | Darstellung |

## Gut zu wissen

- Preise sind gespeicherte Scans, keine Live-Angebote. Fehlende oder alte Preise nennt CraftPilot, statt sie zu raten.
- Skillchancen sind Erfahrungswerte; einzelne Ergebnisse weichen ab.
- Lehrer- und Händlerstandorte sind Reisehilfen, das Angebot wird nicht live geprüft.

## Mitmachen

Fehler und Ideen gern im [Discord](https://discord.gg/DpsBkHtQS) (auch ohne GitHub-Konto) oder als [Issue](https://github.com/Necrite82/CraftPilot/issues). Im Spiel erstellt „Fehler melden“ einen fertigen Bericht mit Version und Lua-Fehlern. Hinweise für Entwickler stehen in [CONTRIBUTING.md](CONTRIBUTING.md); die automatisierten Tests laufen unter Lua 5.1 und 5.4.

## Lizenz und Daten

CraftPilot steht unter der **GNU GPL-3.0-only**, siehe [LICENSE](LICENSE).

- Rezeptdaten: von CraftPilot selbst gebaut aus den Tabellen des Forever-Clients (über wago.tools), [QuestieDB](https://github.com/Questie/QuestieDB), [CMaNGOS classic-db](https://github.com/cmangos/classic-db) und [AllTheThings](https://github.com/ATTWoWAddon/AllTheThings) (MIT)
- Lehrer-Ränge: [CMaNGOS classic-db](https://github.com/cmangos/classic-db) (GPL-3.0)
- Standorte von Lehrern und Sammelvorkommen: zur Laufzeit aus dem Addon [QuestieDB](https://github.com/Questie/QuestieDB)

Einzelheiten in [DATA_SOURCES.md](DATA_SOURCES.md). World of Warcraft ist eine Marke von Blizzard Entertainment; CraftPilot ist ein unabhängiges Community-Projekt.
