# CraftPilot

**Ingame-Berufsplanung für World of Warcraft: Forever.**

CraftPilot zeigt die nächsten sinnvollen Schritte beim Leveln von Berufen direkt im Spiel. Das Addon kombiniert die im Berufsfenster sichtbaren Rezepte und Materialien mit vorhandenen Beständen, geschätzten Skillchancen und den zuletzt gespeicherten Auktionshauspreisen. Bekannte Berufslehrer können ohne manuelle Koordinateneingabe als Wegpunkt gesetzt werden.

**Entwicklungsstand:** 0.10.0-alpha · Forever 1.60.x · Interface 16001 · **Noch nicht im Live-Client getestet**

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
- Kürschnerei
- Kochen
- Erste Hilfe
- Angeln

Für die bisherigen acht Berufe ist eine **1–300-Etappenübersicht** hinterlegt. Für die sechs Herstellungsberufe werden **aktuell erlernte, aus dem Spiel auslesbare Rezepte** nach geschätzten zusätzlichen Materialkosten pro Skillpunkt verglichen. Bergbau und Kräuterkunde zeigen geeignete Sammelstufen und Gebiete. Berufs-Skillwerte können auch ohne offenes Rezeptfenster über die Charakter-Berufsübersicht ausgelesen werden.

**Wichtige Abgrenzung:** Ein umfangreicher GPL-3.0-Rezeptkatalog für die sechs Herstellungsberufe ist jetzt integriert. Er stammt aus einer **älteren Forever-Clientversion** (Oktober 2026, 1.60.1.70425–70450); nicht jede Rezeptquelle oder Trainerstufe ist im aktuellen Live-Spiel bestätigt. Automatische Routen sind **Schätzungen** und ausdrücklich nicht nachweislich global kostenoptimal. Bergbau behält eine Sammlungsübersicht, ergänzt um Schmelzrezepte für Herstellungsketten; Kräuterkunde ist eine Sammelroute.

## Funktionen

| Funktion | Beschreibung |
| --- | --- |
| Beruf erkennen | Ingenieurskunst, Bergbau, Schmiedekunst, Verzauberkunst, Schneiderei, Lederverarbeitung, Kräuterkunde, Alchemie |
| Rezepte erfassen | Bekannte Rezepte, Reagenzien und aktuelle Schwierigkeitsfarben aus dem geöffneten Berufsfenster übernehmen |
| Kostenvergleich | Aktuell mögliche Rezepte nach geschätzten Kosten pro Skillpunkt sortieren |
| Eigene Materialien | Taschenbestände abziehen; optional Bankbestände, soweit die Spiel-API sie bereitstellt |
| Auktionshauspreise | Letzte gespeicherte Einzelpreise aus Auctionator auswerten |
| Kostenmodus | Zusätzliche Ausgaben minimieren oder den Marktwert eigener Materialien berücksichtigen |
| Skill-Etappen | Kürzere, nach Material- und Ausbildungswechseln strukturierte Abschnitte von 1 bis 300 für die bisherigen acht Berufe |
| Wegpunkte | Liste aller hinterlegten Lehrer der eigenen Fraktion; einzeln per Klick auswählbar, mit Rang-Empfehlung und Same-Map-Abstand |
| Einkaufsliste | Fehlende Materialien für **die nächste empfohlene Herstellung** |
| Oberfläche | Verschiebbares Fenster, gespeicherte Position und fünf Registerkarten |
| Themes | Automatischer Stil mit Blizzard-Templates und optional EllesmereUI-Hooks; Dunkel/Klassisch auswählbar |
| Hilfe | Integrierte Befehlsübersicht über `/cp hilfe` |

**Keine Automatisierung:** CraftPilot kauft, verkauft, bewegt den Charakter, lernt und stellt nichts selbstständig her.

## Installation

1. Das **[CraftPilot-0.10.0-alpha Installations-ZIP](https://github.com/Necrite82/CraftPilot/releases/download/v0.10.0-alpha/CraftPilot-0.10.0-alpha.zip)** herunterladen (nicht das GitHub-Quellcode-Archiv).
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

## Neu in 0.8: Rezeptkatalog, Produktionsketten und Preisaktualität

### Rezeptdatenbank und Quellen

Für **Ingenieurskunst, Schmiedekunst, Schneiderei, Lederverarbeitung, Verzauberkunst und Alchemie** sind jetzt die vollständigen Rezeptlisten des eingebundenen **Craft-Ladder-Snapshots** mit Reagenzien, Output, Skillfarben und verfügbaren Lernquellen enthalten. Zusätzlich sind Schmelzrezepte aus Bergbau enthalten. Damit kann CraftPilot auch zukünftige Etappen prüfen, ohne dass jedes Rezept bereits im aktuellen Berufsfenster sichtbar sein muss.

Die Daten sind unter **GNU GPL-3.0** mit den ursprünglichen Quellenhinweisen eingebunden. Details: [ThirdParty/CraftLadder/SOURCE.md](ThirdParty/CraftLadder/SOURCE.md), [CREDITS.txt](ThirdParty/CraftLadder/CREDITS.txt) und [DATA_SOURCES.md](DATA_SOURCES.md). Es wurden keine externen Website-Guides als Texte kopiert.

**Achtung:** Der mitgelieferte Datensatz wurde für frühere Forever-Builds erstellt. Neue Rezepte, Server-Hotfixes, Trainerangebote, Spezialisierungen und Verkaufsquellen können abweichen. Der Planer kennzeichnet nicht live bestätigte Trainingsschritte.

### Automatischer Vorschlag im Einkaufsplan

1. Beruf auswählen und im Tab **Einkaufsplan** Start- und Zielskill einstellen, etwa **30–100**.
2. Auf **Auto-Route** klicken oder `/cp autoplan` verwenden.
3. CraftPilot erstellt einen **voraussichtlich preisgünstigen** Herstellungsweg anhand der bekannten Skillfarben und gespeicherten Preise. Das Verfahren trifft **schrittweise Kostenentscheidungen** und ist keine mathematisch garantierte Gesamtoptimierung.
4. Die Liste berücksichtigt den einmalig erfassten Taschen- und Bankbestand. Bei Zwischenprodukten vergleicht sie, soweit eigene Berufe und Rezepte dafür bekannt sind, **Kauf gegen Selbstherstellung** – etwa Erz → Barren → Bauteil. Verbleibende benötigte Rohmaterialien erscheinen als Einkaufsliste.
5. Geplante Schritte, Annahmen, unbekannte Preise und alternative Herstellungsaktionen werden angezeigt. `/cp einkauf` gibt die Einkaufsliste aus.

Der bisherige **manuelle Plan** mit selbst gewählten Rezepten und Mengen bleibt erhalten. Eine unbekannte Rezeptquelle, Materialpreis oder benötigte Spezialisierung kann dazu führen, dass der automatische Vorschlag unvollständig ist.

### Preisalter statt nur Preis

CraftPilot liest über die **offizielle Auctionator-API** nicht nur den gespeicherten Stückpreis, sondern – soweit verfügbar – auch das **Alter in Tagen** aus. Bis **3 Tage** gilt ein Preis als frisch, nach **mehr als 3 Tagen** erscheint ein Hinweis und nach **mehr als 7 Tagen** die Kennzeichnung *veraltet*. Ohne verfügbares Alter heißt es ausdrücklich *Alter unbekannt*. Wenn ein dokumentierter unbegrenzt verfügbarer Händlerpreis günstiger ist, kann dieser verwendet werden.

Ein angezeigter Preis ist **kein Live-Angebot** und garantiert weder Lagerbestand noch den tatsächlichen Kaufpreis. Ein neuer Scan vor größeren Einkäufen bleibt empfehlenswert.

## Neu in 0.7: einheitliche Karten, Berufe öffnen und Einkaufsplan

Die Bereiche **Materialien**, **Etappen 1–300**, **Hilfe** und **Sammelberufe** verwenden jetzt Karten mit Statusfarben, Symbolen aus dem WoW-Client und kurzen Hinweisen. Materialkarten zeigen benötigte Mengen, Taschen- und zuletzt erfasste Bankbestände, Fehlmengen und gespeicherte AH-Preise. Eine Etappenkarte kann den Abschnitt direkt in den Planer übernehmen.

**Berufsfenster bei Auswahl öffnen:** Ein Klick auf einen gelernten Beruf in CraftPilot versucht, das native Berufsfenster über `C_TradeSkillUI.OpenTradeSkill` zu öffnen. Dies erfordert eine echte Benutzeraktion und kann vom Client oder im Kampf verweigert werden. Für Sammelberufe gibt es nicht in jedem Fall ein Herstellungsfenster. Das Verhalten lässt sich mit `/cp autoopen on` beziehungsweise `/cp autoopen off` deaktivieren. Nicht erlernte Berufe werden nicht automatisch geöffnet.

### Einkaufsplan: frei wählbarer Skillbereich

1. Im neuen Tab **Einkaufsplan** Start und Ziel festlegen, beispielsweise **30 bis 100**.
2. Ein gelerntes Rezept im Tab **Jetzt skillen** auswählen.
3. Im Einkaufsplan eine geplante **Stückzahl** eingeben und auf **Rezept +** klicken. Weitere Rezepte können genauso hinzugefügt werden.
4. CraftPilot fasst alle Zutaten für diese geplanten Herstellungen zusammen. Taschenbestände, der markierte Bank-Snapshot und gespeicherte Auctionator-Preise fließen in die Zukaufübersicht ein.
5. **Liste im Chat** oder `/cp einkauf` gibt die fehlenden Materialien aus. Einzelne geplante Rezeptschritte lassen sich anklicken und entfernen.

**Schnellschritt +10** ergänzt einen vorläufigen Plan für maximal die nächsten zehn Skillpunkte, basierend auf dem aktuell besten Rezept und der zuletzt eingelesenen Skillchance. Der Vorschlag endet spätestens an der Ausbildungsgrenze.

**Wichtige Grenze:** Der frei wählbare Bereich bezeichnet das **Ziel**, nicht eine garantierte Skillroute. Die Materialmengen stimmen für die **ausgewählten Rezepte und Stückzahlen**, aber die erforderlichen Skillpunkte hängen von der sich ändernden Rezeptfarbe ab. Noch unbekannte oder nicht erlernte spätere Rezepte kann diese Version nicht selbstständig hinzufügen. Ein Plan für 30–100 wird erst dann vollständig, wenn die benötigten Herstellungsschritte feststehen. Zwischenprodukte werden derzeit als Bruttomaterialbedarf gezählt und nicht doppelt durch eine vollständige Produktionskette optimiert.

Neue Befehle: `/cp plan`, `/cp einkauf`, `/cp autoopen on`, `/cp autoopen off`.

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

## Entwicklung: alle zwölf Berufe

Eigene Berufe stehen zuerst; über „Alle Berufe anzeigen“ werden weitere eingeblendet. Auch Kochen, Erste Hilfe und Angeln werden aus den Nebenberufs-Slots erkannt. Neue Berufsfenster liefern ihre erlernten Rezepte, Materialien und Skillfarben direkt aus dem Client. Für die vier ergänzten Berufe sind noch keine vollständigen Etappen, Lehrerstandorte oder Fremdkataloge hinterlegt. Ausbildungsanforderungen werden nicht aus den Hauptberufen übernommen. Juwelenschleifen und Inschriftenkunde gehören nicht zu den zwölf bestätigten Forever-Berufen.

Quelle: [Blizzards Berufsübersicht vom 21. Oktober 2026](https://worldofwarcraft.blizzard.com/en-us/news/24301516/gather-around-the-campfire-in-world-of-warcraft-forever).

Das neue Installationspaket ist `dist/CraftPilot-0.10.0-alpha.zip`. Die älteren Archive bleiben unverändert. Es wurden keine neuen Fremddatensätze importiert. Minimap-Button und Einstellungen sind in dieser Version enthalten.

## Bedienung und Darstellung in 0.10

- Minimap-Logo: Linksklick öffnet/schließt CraftPilot, Rechtsklick öffnet Einstellungen. Zum Verschieben ziehen; Position bleibt gespeichert.
- Einstellungen sind auch über die Schaltfläche im Fenster erreichbar, wenn der Minimap-Button ausgeblendet ist.
- Bankbestände, Preisbewertung, Sortierung, Design, Berufsauswahl, automatisches Berufsfenster, Quelldetails und Routenwahl sind ohne Befehle bedienbar.
- Auto-Route kann auf erlernte Rezepte beschränkt werden. Sie bleibt eine Schätzung aus einem früheren Katalogstand; künftige Skillfarben werden nicht als live geprüft ausgegeben.
- Material- und Rezeptbilder kommen aus dem Client; Geldbeträge verwenden Gold-, Silber- und Kupfersymbole. Das neue eigene Logo ist im Paket enthalten.
- Relevante Einstellungswechsel verwerfen alte Auto-Vorschläge. Fenster-/Minimap-Reset und das Leeren des gesamten Plans erfordern eine zweite Bestätigung.
- Aktualisieren behält die Scrollposition im gleichen Bereich bei. Slash-Befehle bleiben optionale Abkürzungen.

Automatisierte Lua-Tests decken die Steuerung ab; die tatsächliche Darstellung auf einer WoW-Minimap und bei angepasster UI-Skalierung benötigt noch einen Test im Spielclient.
