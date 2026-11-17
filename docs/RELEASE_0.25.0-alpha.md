# CraftPilot 0.25.0-alpha

Fünf Wünsche und neun Vorschläge in einem Paket: schlankere Einstellungen mit frei wählbarem Skillweg, Wege zu Lehrern und Händlern, Lerntour, Rang- und Spezialisierungshinweise, Preisalter, Twinks als Hersteller, Cooldowns, Bank- und Posthilfe, Sammelgebiete, Verkaufserlös, Sitzungsbilanz und Pläne zum Teilen.

## Einstellungen: von 34 auf 9 sichtbare Einträge

- **Skillweg** mit drei Möglichkeiten:
  - *Günstigster Weg*: rein nach AH-Preisen.
  - *Sichere Farben bevorzugen*: Grün nur, wenn es je Punkt über 25 % billiger ist.
  - *Nur Orange und Gelb*.

  Der Skillweg gilt für Empfehlung, Begleitfenster **und „Plan erstellen“**: Der Plan folgt jetzt demselben günstigsten Weg; Zwischenprodukte, Vorräte und Einkaufsliste rechnet weiter der Planer.
- **Vorräte**: nur Taschen, Taschen und Bank oder zusätzlich Twinks.
- **Rezepte zum Lernen einbeziehen**: fasst „Kaufrezepte anzeigen“ und „Auto-Route nur erlernte“ zusammen.
- **Verkaufserlös gegenrechnen** (neu, aus): Was ein hergestellter Gegenstand im AH (abzüglich AH-Abzug) oder beim Händler bringt, senkt die Kosten des Rezepts.
- **Weitere sichtbare Einträge**: Begleitfenster, Berufsfenster beim Wechsel öffnen, Minimap-Button, Design und Zurücksetzen.
- **Unter „Erweitert“**: Punktgrenzen, Vorausschau, AH-Abzug, QuestieDB, Reservierungen, Berufsdaten und Version.
- **Entfallen**:
  - Fenstergröße (Ziehgriff unten rechts), Minimap-Position (Button ziehen) und Rezeptsortierung (Spaltenköpfe)
  - Berufsauswahl, Kostenvergleich, Quelldetails und Sprache
  - reine Knöpfe und die Infokarte

  Bisherige Werte werden übernommen; wer Grün ausgeschaltet hatte, landet bei „Nur Orange und Gelb“.

## Lernen

- **Weg zum Lehrer oder Händler**:
  - Jedes noch nicht erlernte Rezept in der Liste hat ein Kartensymbol, das den Wegpunkt setzt. Der Tooltip nennt Ort, Kosten und Mindest-Skill.
  - In den Details gibt es den Hauptknopf „Weg zum Lehrer“, „Weg zum Händler“ oder „Rezept im AH suchen“.
- **Weltdrop-Rezepte im AH**: Hat Auctionator einen aktuellen Preis für ein Drop-Rezept, zählt es als kaufbares Rezept. Der günstigste Weg nimmt es nur, wenn es sich lohnt („Erst im AH kaufen: …“).
- **Lerntour** (Lehrer & Händler → Lerntour):
  - Alle Rezepte, die der günstigste Weg unterwegs lernt, sind nach Ort zusammengefasst: erst der Lehrer, dann die Händler, zuletzt das AH.
  - „Tour starten“ setzt den Wegpunkt. Nach dem Lernen springt er beim nächsten Einlesen des Berufsfensters zum nächsten Halt.
- **Rang- und Levelsperren**: Ein Plan über die Ausbildungsgrenze hinaus warnt rot, wenn die Charakterstufe für den nächsten Rang fehlt (Geselle 10, Experte 20, Fachmann 35). Kurz vor der Grenze erscheint der Hinweis auch in Empfehlung, Lehreransicht und Begleitfenster.
- **Spezialisierungen** (Lehrer & Händler → Spezialisierung) für Schmiedekunst, Ingenieurskunst und Lederverarbeitung:
  - Für jede Spezialisierung siehst du Voraussetzungen, den aktuellen Schritt und die benötigten Gegenstände.
  - Ein Klick setzt den Wegpunkt zum Questgeber.
  - Die Daten stammen aus Craft Ladder; erledigte Quests erkennt das Spiel.

## Preise

- Die Empfehlungsleiste zeigt „Preise alt“ oder „N ohne Preis“, wenn Materialien des Weges älter als drei Tage sind oder keinen Preis haben. Am Auktionshaus scannt ein Klick per Auctionator genau diese Materialien.
- Unter Plan → Details gibt es dieselbe Prüfung für den Einkauf des Plans.

## Twinks

- **Neuer Reiter „Twinks“**:
  - Cooldowns aller Charaktere
  - Twink-Bestände für deinen Plan (Taschen, Bank, Post)
  - was Twinks günstiger herstellen können
  - alle Charaktere mit Berufen und Stand
- **Twinks als Hersteller**: Kann ein Twink auf demselben Realm und derselben Fraktion ein Material mindestens 5 % billiger herstellen als das AH (z. B. Barren schmelzen), rechnet der günstigste Weg damit und nennt es („Bronzebarren: Gromdal kann es herstellen · spart ca. …“). Erlernte Rezepte merkt sich CraftPilot pro Charakter beim Öffnen des Berufsfensters.
- **Cooldowns**: Mondstoff, Transmutationen und andere Rezepte mit Abklingzeit werden pro Charakter gespeichert. Beim Login nennt CraftPilot, was bereit ist; auch das Begleitfenster zeigt es.
- **Bank**: Beim Öffnen der Bank zeigt ein kleines Fenster, was deine Pläne brauchen und nur in der Bank liegt.
- **Post**:
  - Der Inhalt des Briefkastens zählt als Twink-Bestand.
  - Am Briefkasten zeigt CraftPilot, was ein Twink für seine Pläne noch braucht und du in den Taschen hast.
  - „Brief an … vorbereiten“ trägt Empfänger und Betreff ein. Anhängen und Senden machst du selbst.

## Sonstiges

- **Selbst farmen statt kaufen**: Unter Plan → Einkaufen stehen bei Erzen, Steinen und Kräutern die besten Gebiete für deinen Skill. Dazu siehst du, wer auf dem Account sammeln kann; ein Klick öffnet das Gebiet auf der Weltkarte. Die Daten stammen aus QuestieDB-Knotenpositionen (40 Gegenstände) und werden automatisch mit abgeglichen.
- **Sitzungsbilanz** im Begleitfenster: „+12 Punkte · ausgegeben 3g (Plan: ca. 2g 80s)“. Gezählt werden Ausgaben, während AH, Händler oder Lehrer offen sind.
- **Plan teilen**: Unter Plan → Details wird der Plan als kurzer Text (`CP1;Beruf;von;bis;Rezept=Anzahl,…`) angezeigt. Andere fügen ihn per „Plan importieren“ ein.

Validierung:

- vollständige Tests unter Lua 5.1 und 5.4, darunter ein neuer Test für alle Punkte dieses Pakets
- Prüfung der Datenquellen (Craft Ladder, Lehrer, Sammelgebiete) gegen ihre festgehaltenen Prüfsummen

Im Spielclient nicht getestet; besonders Briefkasten, Bankfenster und Weltkarte bitte rückmelden.
