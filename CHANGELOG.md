# Changelog

## 1.5.0

- „Jetzt skillen“ stellt den nächsten Klick und die benötigte Herstellungsmenge über die Rezeptliste. Die Liste zeigt Rezept-Icons und Skillchancen. Im gewählten Rezept stehen geschätzter Zukauf, genutzter Vorrat und Fehlmenge zusammen.
- „Plan & Einkauf“ zeigt den Skillbereich und den Arbeitsablauf. Die Materialtabelle trennt den Bedarf nach Tasche, Bank, Twink und Zukauf. Gespeicherte Bestände und unvollständige Preise bleiben erkennbar.
- Navigation und Farben entsprechen dem neuen CraftPilot-Entwurf. Die WoW-Tooltips sind an der Rezeptzeile und am Detail-Icon verfügbar.

## 1.4.5

- „Jetzt skillen“ hebt die passende nächste Aktion hervor. Im Plan stehen Zielbereich und Reihenfolge der Schritte über Einkauf und Herstellung.
- „Jetzt skillen“ zeigt den nächsten Schritt am Rezept und hält beim Aktualisieren die Position. Der Vergleich der Skillwege nutzt den gewählten Bereich und zeigt die Abweichung zum aktiven Weg.
- Der Plan-Einkauf trennt die benötigten Mengen nach Tasche, Bank, Twink und Zukauf und kennzeichnet gespeicherte Bestände.
- Projekt-Einkaufslisten werden mit den korrekten Gegenstands-IDs und Fehlmengen an Auctionator übergeben; der Lua-Fehler beim Export entfällt.
- Projekte berücksichtigen die vom Spielclient erfasste Ausbeute einer Herstellung, etwa fünf Silberkontakte aus einem Silberbarren. Ohne Mengenangabe des Clients gilt die Katalogausbeute.
- Mehrere Schritte und Projekte teilen sich einen Vorrat. Fehlende Zwischenprodukte werden aus den verbleibenden Rohstoffen geplant; dieselben Bestände schließen nicht mehrere Projekte zugleich ab.
- Vorräte für höher priorisierte Berufs-, Camping- und Raid-Pläne bleiben auch beim Projekt-Einkauf reserviert.

## 1.4.4

- **Speicher, zweiter Schritt**: Die Suche nach Taschen-Knöpfen (für die Markierungen reservierter Gegenstände) legte für jedes Fenster der Spieloberfläche neue Hilfsfunktionen an – mehrere MB Datenmüll pro Durchlauf. Jetzt entsteht dabei praktisch keiner mehr, und sie läuft alle 30 statt 15 Sekunden
- Preisangaben, Bestände und die Behalten-Liste werden zwischengespeichert, statt bei jeder Wegberechnung tausendfach neu erstellt zu werden
- Ein geschlossenes CraftPilot-Fenster wird nicht mehr bei jeder Zauber- oder Fertigkeitsänderung neu gezeichnet, sondern erst beim Öffnen
- **/cpp speicher**: misst 60 Sekunden lang, welche Teile von CraftPilot wie viel Speicher anlegen – hilft bei Fehlermeldungen

## 1.4.3

- **Weniger Speicher**: CraftPilot erzeugt deutlich weniger Datenmüll (im Test rund 60 % weniger pro Spielminute), die Speicheranzeige im Spiel bleibt dadurch niedriger
  - Tooltips merken sich ihre Zeilen, bis sich Taschen, Preise oder Pläne ändern – nicht nur 3 Sekunden
  - Die Markierungen in den Taschen berechnen die reservierten Gegenstände nur noch nach Änderungen, nicht alle 2 Sekunden
  - Bei offenem Fenster prüft CraftPilot Pläne und Vorrat nach Taschen-, Bank-, Post-, AH- und Berufs-Ereignissen statt blind alle 5 Sekunden
- **Händlerrezepte**: Ein Klick auf eine Rezeptkarte öffnet die Karte mit allen Händlern, die das Rezept verkaufen, samt Preis – bisher passierte bei „Klick: alle Angebote“ nichts
- **TomTom-Pfeil**: Der Pfeil zeigt jetzt auf den neu gesetzten Wegpunkt, auch wenn noch andere Wegpunkte (z. B. von anderen Addons) gesetzt sind. Ohne TomTom weist CraftPilot einmal darauf hin, dass WoW Forever nur eine Kartenmarkierung zeigt

## 1.4.2

- **Kochen und Erste Hilfe planen**: „Plan erstellen“ funktioniert jetzt auch für diese beiden Berufe, z. B. von 1 bis 300 in einem Rutsch – mit Einkauf, Lehrern und Rezepthändlern. Bisher fehlte ihnen der vollständige Rezeptkatalog für die Planung
- **Händlerrezepte im Plan**: Der Plan nutzt jetzt auch Rezepte vom Händler (z. B. die Verbands-Handbücher für Erste Hilfe 180–240), wie es die Empfehlung schon tat
- **Start-Rezepte beim Kochen** (Charred Wolf Meat, Roasted Boar Meat, Herb Baked Egg) galten fälschlich als nicht erhältlich
- Rezepte der Winterhauch-Händler werden weiter angezeigt, aber nicht mehr eingeplant – die Händler gibt es nur während des Fests

## 1.4.1

- **Karte**: Schließen (x), Weltkarte, Ganze Karte / Nur erkundet und Zoom (+/−) reagieren wieder auf Klicks – die Ziehleiste oben im Fenster lag über diesen Knöpfen
- **Rezeptkatalog** aktualisiert: 37 Rezepte, die es bisher in WoW Forever nicht gab, sind jetzt erhältlich und werden mit Quelle geplant – u. a. Holzschlundfeste, Argentumdämmerung, Dunkeleisen und Geschmolzener Kern (z. B. Teufelsstoffbeutel, Lavagürtel, Flammenkernrobe)

## 1.4.0

- **Karte**: Lehrer & Händler, Händlerrezepte, Lerntour und Rezept-Sammlung haben eine Karte im CraftPilot-Stil – zoombar, verschiebbar, ganze Karte oder nur Erkundetes, Filter Lehrer/Händler, Gebiet für Gebiet. Klick auf einen Punkt setzt den Wegpunkt (TomTom oder die Spielmarkierung)
- **Kochen, Erste Hilfe, Angeln über 150**: Experte gibt es nicht beim Lehrer, sondern als Buch beim Händler (Kochbuch: Shandrina/Wulan, Erste Hilfe: Deneb Walker/Balai Lok'Wein, Angeln: Old Man Heming). Fachmann bei Dirge Quikcleave (Kochen) bzw. über die Quests „Triage“ (Erste Hilfe) und „Nat Pagle, Angler Extreme“ (Angeln). CraftPilot zeigt diese Orte jetzt wie Lehrer, mit Wegpunkt und auf der Karte; Fachmann braucht Skill 225
- **Lehrer für Kochen, Erste Hilfe und Angeln auch ohne QuestieDB**

## 1.3.0

**Verlässlichere Rechnung**
- **Post-Packer sicher**: Jeder Taschenplatz wird direkt vor dem Anhängen neu gesucht (Taschen-Addons dürfen dazwischen sortieren), jeder Anhang wird geprüft; bei Unerwartetem bricht er ab. Die Meldung kommt erst, wenn wirklich alles angehängt ist
- **Mengen richtig**: Händler-Helfer, Einkaufsrunde, Bankhinweis und Twink-Übersicht zogen den Vorrat bei der Empfehlung doppelt ab (10 nötig, 3 da → nur 4 statt 7)
- **Herstellungspreise unabhängig von der Rechenreihenfolge**: ein unvollständig berechneter Preis wird nicht mehr als fertiger Preis wiederverwendet
- **Twink-Rezepte nur bestätigt**: Ohne eingelesene Rezeptliste rechnet CraftPilot einen Twink nicht mehr als Hersteller ein (nur noch als Hinweis)
- **Dein Plan zuerst**: Deckt ein gespeicherter Plan deinen Skill ab, empfiehlt CraftPilot dessen Schritt; ein günstigerer Weg steht daneben. Mit „Günstigsten nehmen“ / „Meinen Plan nehmen“ wechselst du jederzeit
- **Skilldaten strenger**: „Bestätigt“ erst ab 20 Herstellungen ohne Punkt an der Graugrenze, getrennt nach Client-Build; der Skill wird beim Start des Herstellens gemerkt
- **Behalten oder verkaufen** nur noch bei Handwerkswaren, nicht bei Ausrüstung

**Neu**
- **Warum dieses Rezept?** im Tooltip der Empfehlung: Kosten je Punkt, Chance, Lerngebühr und späterer Bedarf – neben den zwei besten Alternativen
- **Budget mit Puffer**: Bei gelben und grünen Rezepten schwankt der Bedarf; CraftPilot nennt den Weg mit Puffer für Pech
- **Alter der Twink-Bestände** an der Empfehlung („Stand vor 5 Tagen“); Einstellung, ab welchem Alter Bestände nicht mehr fest eingeplant werden
- **Nach dem Scan**: Ändert ein AH-Scan den günstigsten Weg, sagt CraftPilot, was sich ändert – Ersparnis, neue oder entfallene Rezepte, zusätzliche Lehrer-/Händlerbesuche
- **Händlerrezepte mit Besuchsstatus**: Beim Öffnen eines Händlers merkt sich CraftPilot (accountweit), welche Rezepte im Angebot, ausverkauft oder nicht da waren. Lernziel und Lerntour bevorzugen Händler, die nicht ausverkauft gesehen wurden, und zeigen den Stand
- **Wege vergleichen** (Plan & Einkauf): wenig Gold, wenig Herstellungen oder wenig Wege nebeneinander – Einkauf, Lernkosten, Herstellungen und Lernwege; ein Klick nimmt den Weg
- **Rezept-Sammlung** (Endgame › Sammlung): alle Rezepte deines Berufs mit Fortschritt, fehlende mit Quelle, Filter nach Quelle und Gebiet, Sammeltour im aktuellen Gebiet
- **Preisquelle automatisch erkannt**: CraftPilot merkt, ob TradeSkillMaster oder Auctioneer neue Preise haben, schätzt deren Alter und fragt bei „Automatisch“ das Addon mit dem neuesten Scan zuerst. Damit funktionieren AH-Alarm, Merkliste und „Nach dem Scan“ auch ohne Auctionator
- **QuestieDB optional**: nur noch empfohlen. Ohne QuestieDB nutzt CraftPilot seine eigene Lehrerliste; Sammelgebiete und Bosse als Rezeptquelle fehlen dann
- **Produktionsprojekte** (Plan & Einkauf › Projekte): Skillziele und Gegenstände zu einem Ablauf verbinden, z. B. „Ingenieur auf 225, dann 20 Bomben“. Zwischenprodukte, die du selbst herstellen kannst, werden mitgeplant (Erz statt Barren); Material wird mit den anderen Plänen gemeinsam reserviert, der nächste Schritt steht auf „Jetzt“. Gegenstände kommen über Gegenstände › Hergestellt durch („Zum Projekt“) dazu. Bestehende Pläne bleiben unverändert

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
