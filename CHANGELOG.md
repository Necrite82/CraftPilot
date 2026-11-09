# Changelog

## 0.17.0-alpha

Nicht erlernte Lehrerrezepte inklusive einmaliger Lernkosten und Materialkosten vergleichen; passende Lehrer direkt als Wegpunkt. Umschaltbare Ansichten sinnvoll/nicht gelernt/alle, mit ausgegrauten zukünftigen Katalogrezepten. [Details](docs/RELEASE_0.17.0-alpha.md).

## 0.16.0-alpha

Gemeinsamer Release mit QuestieDB-/Erste-Hilfe-Korrekturen, AH-/Netto-/Händler-Stückpreisen, Behalten-/Verkaufshinweisen, Taschen-/Bankangaben direkt am Rezept und Auctionator-Einkaufslisten für manuelle Pläne sowie Skillbereich-Auto-Routen. Geplante Zwischenprodukte werden verrechnet. [Details](docs/RELEASE_0.16.0-alpha.md).

## 0.15.1-alpha

Korrektur der Erkennung gepackter QuestieDB-Forever-Versionen und eigene Berufserkennung über die aktuelle Berufs-API, insbesondere Erste Hilfe. Getrennte Statusmeldungen für fehlende API, falschen Datenstand und fehlende Paketkennung. [Details](docs/RELEASE_0.15.1-alpha.md).

## 0.15.0-alpha

Gemeinsame Vorratsreservierungen für Berufs- und Campingpläne, Prioritäten, Neubewertung bei Änderungen und erfasster Herstellungsfortschritt. Kaufrezepte vergleichen Rezept- und Materialkosten mit erlernten Alternativen. Lokale Fehlerberichte mit Vorschau und vorbereitetem GitHub-Issue-Link. [Details](docs/RELEASE_0.15.0-alpha.md).

## 0.8.0-alpha — 2026-11-08

- GPL-3.0-Rezeptkatalog für sechs Herstellungsberufe aus dem Craft-Ladder-Datenstand 1.60.1.70425–70450 integriert; Bergbau-Schmelzrezepte für Herstellungswege ergänzt.
- Ursprungsautoren, Quellrevision und fremde Lizenzen klar nachgewiesen und erhalten.
- Automatischer, heuristischer Skillweg-Vorschlag im Einkaufsplan samt Trainerannahmen und detaillierter Zukaufliste.
- Rekursive make-or-buy-Materialrechnung mit Zwischenprodukten und vorhandenen Taschen-/Bankbeständen (beispielsweise Erz zu Barren zu Bauteil).
- Auctionator-Preisalter über öffentliche API eingelesen und als frisch, älter, veraltet oder unbekannt angezeigt.
- Lua- und Datenbanktests erweitert und Installation-ZIP aktualisiert.

**Grenzen:** Datenstand aus älterem Forever-Build; spätere Trainerangebote, Lernvoraussetzungen und Rezeptänderungen erfordern Ingame-Prüfung. Die schrittweise Heuristik garantiert weder einen vollständigen noch den weltweit günstigsten Weg zum Zielskill.


## 0.7.0-alpha — 2026-11-08

- Materialien, Skilletappen, Hilfe und Sammelberuf-Übersichten auf einheitliche Karten mit dezenten visuellen Markierungen umgestellt.
- Etappenkarten übernehmen den gewählten Skillbereich direkt in den Einkaufsplan.
- Gelernte Herstellungsberufe können durch einen direkten Benutzerklick ihr natives Berufsfenster öffnen (clientabhängige sichere API).
- Frei einstellbarer Skillbereich mit mehreren ausgewählten Rezepten und Stückzahlen; aggregierte Material- und Einkaufsliste mit Taschen, Bank-Snapshot und gespeicherten AH-Preisen.
- Vorsichtiger Schnellvorschlag für bis zu zehn aktuelle Skillpunkte; keine vorgetäuschte 1–300-Komplettplanung.
- Zusätzliche Tests für sichere Berufsöffnung, Planbereich, Material-Aggregation und UI-Karten.

**Grenzen:** Ohne vollständige Forever-Rezeptdatenbank und zuverlässige zukünftige Skillfarben kann CraftPilot keine garantierte kostenoptimale Route von z. B. Skill 30 auf 100 berechnen. Die Einkaufsliste bezieht sich auf ausdrücklich gewählte Herstellungsmengen; Zwischenprodukte werden nicht aufgelöst.


## 0.6.0-alpha — 2026-11-08

- Offizielle EllesmereUI-Skinning-API für eigenes Fenster und Bedienelemente integriert.
- Fenstergröße per Griff unten rechts verstellbar und pro Charakter gespeichert.
- Auswählbare Rezeptkarten mit Ingame-Symbolen, Kosten, Skillchance und Materialbedarf; nach vier Kriterien sortierbar.
- Materialanzeige mit getrennten Taschen- und Bankbeständen, gespeicherten letzten Bankständen sowie einem direkten Ein/Aus-Schalter.
- Automatisierte Tests für Bank-Snapshots, Skin-API, Rezeptwahl und Fenstergröße erweitert.

**Weiterhin Alpha:** kein bestätigter Live-Client-Test; gespeicherte Bankdaten können veralten.


## 0.5.0-alpha — 2026-11-08

- Überarbeitetes Ingame-Fenster mit klarer Titelzeile, kompakteren Bedienelementen und fünf Registerkarten.
- Verschieben über die Kopfzeile; Fensterposition wird pro Charakter gespeichert, mit Rücksetzfunktion.
- Darstellungsmodi Automatisch, Dunkel und Klassisch; optionale ElvUI-Button-Skin-Unterstützung.
- Für acht Berufe feinere 1–300-Etappen an Material- und Ausbildungswechseln.
- Liste aller hinterlegten Lehrer der eigenen Fraktion, einzeln anklickbar.
- Lehrerempfehlung passend zum nächsten Ausbildungsrang; Same-Map-Kartenabstand nur bei verfügbaren Positionsdaten.
- Vollständige Slash-Befehlshilfe im Addon sowie neue Befehle für Etappen, Lehrerliste, Fensterposition und Darstellung.
- Ergänzende Offline-Tests für Lehrerauswahl, Fensterposition und Darstellungs-Fallbacks.

**Hinweis:** Die Trainerdatenbank ist noch nicht vollständig; es werden keine kartenübergreifenden Reisezeiten berechnet. Ein Live-Test in WoW Forever steht noch aus.

## 0.4.0-alpha — 2026-11-08

- Kräuterkunde und Alchemie als siebten und achten Beruf ergänzt.
- Eigene 1–300-Etappenübersichten für beide Berufe und passende Trainerziele für Horde und Allianz.
- Berufs-Skillstände zusätzlich über `GetProfessions` und `GetProfessionInfo` eingelesen, insbesondere für Sammelberufe ohne offenes Rezeptfenster.
- Oberfläche auf acht Berufsschaltflächen erweitert; Lua-Smoketests angepasst.
- Unterschiedliche Charakterstufen-Anforderungen für Kräuterkunde berücksichtigt.

**Bekannte Einschränkungen:** Kein vollständiger Offline-Rezeptkatalog, keine globale 1–300-Kostenoptimierung und noch kein Live-Client-Test.

## 0.3.0-alpha — 2026-11-08

- Unterstützung für Schmiedekunst, Verzauberkunst, Schneiderei und Lederverarbeitung ergänzt.
- Sechs Berufsübersichten mit 1–300-Skilletappen und fraktionsabhängigen Lehrerzielen.
- Einheitliche Rezeptauslesung und Kostenbewertung anhand aktueller Clientdaten.
- Vergleich zwischen zusätzlichen Ausgaben und dem Marktwert vorhandener Materialien.
- Neuer Lua-Smoke-Test und GitHub-Actions-Syntaxprüfung.
- Dokumentation und Datenquellenhinweise für das öffentliche Repository ergänzt.
- Eigenen Quellcode unter GNU GPL-3.0-only lizenziert.

**Bekannte Einschränkung:** Keine vollständige Offline-Rezeptdatenbank und noch keine komplette, global optimierte Route bis 300. Ein Live-Client-Test steht aus.

## 0.2.0-alpha — 2026-11-08

- Lokaler Prototyp für Ingenieurskunst und Bergbau: Etappenplanung, ausgewählte Rezepte, Materialien und Trainerstandorte.
- Erste Berücksichtigung von Auctionator-Preisen und TomTom-Wegpunkten.

**Hinweis:** Die frühere 0.2-Planungslogik mit projektierten Ingenieursrezepten wurde in 0.3 zunächst durch die gemeinsame, auf aktuellen Spielrezepten basierende Bewertung ersetzt. Die vollständige Zukunftsplanung ist noch in Arbeit.

## 0.1.0-alpha — 2026-11-08

- Erster lokaler Prototyp zur Berufs- und Materialplanung.
