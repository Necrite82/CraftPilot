# Changelog

## 1.2.1

- **Seitenleiste deckend** – auch mit EllesmereUI (dort bekam sie bisher den halbdurchsichtigen Stil für innere Felder)
- **Empfehlung**: Die zweite Zeile zeigt nur so viele Hinweise, wie hineinpassen; der Rest steht im Tooltip
- **Budget-Fenster** im CraftPilot-Stil und direkt unter der Budget-Zeile
- **Gegenstände**: Symbole der hergestellten Gegenstände statt einer Schriftrolle; Reiter auf dem dunklen Balken wie auf den anderen Seiten (auch Endgame)
- **Begleitfenster** kürzer: die zwei wichtigsten Hinweise und höchstens drei Zusatzzeilen
- **Lerntour**: „Auktionshaus“ nicht mehr doppelt
- **Preisfelder** zeigen „—“ statt „0“, wenn es keinen Preis gibt (z. B. Händler bei Camping)
- **Plan & Einkauf**: keine doppelt wirkenden Trennlinien mehr

## 1.2.0

- **Neue Seite „Gegenstände“**: jeden Gegenstand suchen (oder Alt-Klick in der Tasche, `/cpp item <Name>`) und sehen, in welchen Rezepten aller Berufe er Zutat ist und wodurch er hergestellt wird – mit Farbbereich, Menge, Preis, Vorrat und Drops
- **Fehlende Rezepte deines Berufs** stehen dort mit Lernquelle; ein Klick setzt den Wegpunkt zum Lehrer oder Händler
- **Rezeptkette** vom Rohstoff bis zum Endprodukt (z. B. Mithrilerz > Mithrilbarren > Mithrilrohr > …)
- **Jetzt herstellbar**: alle erlernten Rezepte, die du mit Taschen, Bank, Post und Twinks sofort herstellen kannst – Skillpunkte zuerst, dann nach Gewinn
- **Behalten oder verkaufen** im Tooltip: Zutat für deinen Weg, deine Berufe, deine Twinks – oder nur für andere Berufe mit AH-Preis bzw. Händlerpreis (abschaltbar)
- **Merkliste**: Gegenstände merken; der AH-Alarm meldet sie nach dem Scan, Gegner, die sie droppen, zeigen es im Tooltip
- **Direkt planen**: aus „Hergestellt durch“ einen Vorrat anlegen (Endgame › Raid-Vorrat) – mit Herstellen-oder-kaufen, Reservierung und Einkaufsliste
- - **Fehler im Kampf behoben**: „CraftPilotPro hat versucht die geschützte Funktion SetFrameStrata aufzurufen“ (ADDON_ACTION_BLOCKED). Die Knöpfe des Berufswechslers hingen nach dem Schließen noch am Fenster und machten es im Kampf zu einem geschützten Fenster; sie werden jetzt gelöst, und die Ebene des Fensters wird im Kampf nicht mehr gesetzt

## 1.1.0

- **Budget sichtbar**: Auf „Jetzt“ steht direkt unter der Empfehlung, wie weit dein Budget reicht (oder was der ganze Weg kostet); Klick öffnet eine Eingabe mit Plus/Minus. Kostet der nächste Schritt mehr als dein Budget, steht es dabei. Auch im Begleitfenster
- **Post-Packer**: Am Briefkasten packt „Brief an … packen“ den Brief an deinen Twink mit genau den fehlenden Mengen (ganze Stapel, der letzte geteilt) – du prüfst und klickst „Senden“. Was die Empfehlung von Twinks braucht, zählt jetzt mit
- **Jetzt günstig**: CraftPilot merkt sich die AH-Preise der Materialien deines Weges einmal am Tag. Liegt eines heute mindestens 20 % unter seinem üblichen Preis, nennen Empfehlung und „Plan & Einkauf“ es mit der Ersparnis
- **Weitere Preisquellen**: TradeSkillMaster und Auctioneer neben Auctionator; Einstellungen › Preisquelle (Automatisch nimmt die erste mit Preis)
- **Skilldaten**: Bei jedem Herstellen notiert CraftPilot Skill und ob ein Punkt kam (abschaltbar). In den Rezeptdetails stehen deine eigenen Werte; unter Hilfe › Skilldaten teilen gibt es einen Code für den Discord. Geteilte Daten fließen als „Grenzen bestätigt“ in den Katalog zurück
- **Farmen oder kaufen**: CraftPilot misst beim Sammeln dein eigenes Tempo je Gebiet und nennt bei „Selbst farmen statt kaufen“, wie lange es dauert und was Farmen pro Stunde spart
- **Zwei Berufe zusammen**: Zwischenprodukte, die du mit einem zweiten Beruf selbst herstellen kannst (z. B. Barren mit Bergbau), mit Ersparnis und den Skillpunkten, die es dort bringt

## 1.0.0

CraftPilot ist fertig für alle: kein Beta-Status mehr. Ab jetzt heißen Fehlerbehebungen und kleine Änderungen 1.0.1, 1.0.2 …, neue Funktionen 1.1.0, 1.2.0 ….

- **Selbst herstellen**: Fehlt ein Material, dessen Vorstufe du hast (Erz für Barren, Stoff für Ballen …), nennen Empfehlung und Rezeptdetails sie, z. B. „bis 21 Mithrilbarren aus 21 Mithrilerz (Bergbau)“. Gezählt werden Tasche, Bank, Briefkasten und Twinks; kann ein Twink es statt dir herstellen, steht sein Name dabei
- **Empfehlung ohne abgeschnittenen Text**: Was fehlt, steht in der ersten Zeile; Twinks, Spartipp und Kosten des ganzen Wegs in einer zweiten
- **Schärfere Schrift** auf den goldenen Knöpfen (z. B. „Im AH suchen“, „Weg zum Lehrer“)
- **Seitenleiste deckend**: Andere Fenster scheinen nicht mehr durch

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
