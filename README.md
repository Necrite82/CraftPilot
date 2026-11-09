# CraftPilot

**Ingame-Berufsplanung für World of Warcraft: Forever.**

CraftPilot zeigt die nächsten sinnvollen Schritte beim Leveln von Berufen direkt im Spiel. Das Addon kombiniert die im Berufsfenster sichtbaren Rezepte und Materialien mit vorhandenen Beständen, geschätzten Skillchancen und den zuletzt gespeicherten Auktionshauspreisen. Bekannte Berufslehrer können ohne manuelle Koordinateneingabe als Wegpunkt gesetzt werden.

**Entwicklungsstand:** 0.17.0-alpha · Forever 1.60.x · Interface 16001 · **Alpha-Freigabe: bisherige Kernabläufe als bestätigt angenommen**

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

1. Das **[CraftPilot-0.17.0-alpha Installations-ZIP](https://github.com/Necrite82/CraftPilot/releases/download/v0.17.0-alpha/CraftPilot-0.17.0-alpha.zip)** herunterladen (nicht das GitHub-Quellcode-Archiv).
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

Das aktuelle Installationspaket ist `dist/CraftPilot-0.17.0-alpha.zip`. Die älteren Archive bleiben unverändert. Camping ergänzt den gezielt gefilterten Referenzbestand; siehe [Camping-Daten und Abgleich](docs/CAMPING_SOURCES.md).

## Bedienung und Darstellung in 0.10

- Minimap-Logo: Linksklick öffnet/schließt CraftPilot, Rechtsklick öffnet Einstellungen. Zum Verschieben ziehen; Position bleibt gespeichert.
- Einstellungen sind auch über die Schaltfläche im Fenster erreichbar, wenn der Minimap-Button ausgeblendet ist.
- Bankbestände, Preisbewertung, Sortierung, Design, Berufsauswahl, automatisches Berufsfenster, Quelldetails und Routenwahl sind ohne Befehle bedienbar.
- Auto-Route kann auf erlernte Rezepte beschränkt werden. Sie bleibt eine Schätzung aus einem früheren Katalogstand; künftige Skillfarben werden nicht als live geprüft ausgegeben.
- Material- und Rezeptbilder kommen aus dem Client; Geldbeträge verwenden Gold-, Silber- und Kupfersymbole. Das neue eigene Logo ist im Paket enthalten.
- Relevante Einstellungswechsel verwerfen alte Auto-Vorschläge. Fenster-/Minimap-Reset und das Leeren des gesamten Plans erfordern eine zweite Bestätigung.
- Aktualisieren behält die Scrollposition im gleichen Bereich bei. Slash-Befehle bleiben optionale Abkürzungen.

Automatisierte Lua-Tests decken die Steuerung ab; die tatsächliche Darstellung auf einer WoW-Minimap und bei angepasster UI-Skalierung benötigt noch einen Test im Spielclient.

## Korrekturen in 0.10.2

Berufsfenster werden direkt aus dem Klickpfad vor der UI-Aktualisierung geöffnet, ohne `pcall` um die eingeschränkte API. Goldene Auswahlmarkierungen und grüne Erlernt-Häkchen sind Grafiken statt fontabhängiger Sonderzeichen. Das Logo liegt auf einem eigenen Rahmen und wird durch EllesmereUIs Panel-Skin nicht mit ausgeblendet. In den Einstellungen gibt es Schieberegler für Fensterbreite, Fensterhöhe und Minimap-Winkel. Die bisherigen Kernabläufe werden für die aktuelle Alpha-Freigabe als bestätigt angenommen.

## Neu in 0.11: Camping und Sprache

Der eigene Reiter **Camping** enthält die Unterbereiche **Campfires**, **Buffs** und **Objekte & Ausbauten**. Standardmäßig erscheinen alle zwölf Berufe; auf Wunsch nur der oben gewählte Beruf. Ein Objekt anklicken zeigt Lernskill, bekannte Rezept-/Blueprint-Quelle, Materialien für eine Herstellung und Fehlmengen. Buffs anklicken klappt die im Referenzstand hinterlegten Charakterstufen aus. Die drei Feuer bieten 3, 5 und 10 Plätze. 37 Objekte je Fraktion stammen aus dem eingebundenen Snapshot; Trapper's Workbench ergänzt die Ansicht auf 38 Einträge je Fraktion; sie zeigt Materialien und Benutzungsanforderung. Unbestätigte Dropmeldungen bleiben gekennzeichnet.

Die Oberfläche folgt automatisch der Clientsprache: Deutsch für `deDE`, Englisch für englische und andere Clients. Rezept-/Gegenstandsnamen und verfügbare Zaubertexte werden bevorzugt aus dem Client gelesen; nicht auflösbare Referenznamen können Englisch bleiben. Gespeicherte Namen werden beim nächsten Einlesen des Berufsfensters aktualisiert.

Einstellungen enthalten sichtbar gezeichnete Regler für Breite, Höhe und Minimap-Position sowie An/Aus-Schieber für die booleschen Optionen. Auswahloptionen wie Design und Sortierung bleiben anklickbar. Automatisiert geprüft, noch nicht im Forever-Spielclient visuell getestet.

## Korrekturen in 0.11.1

Ein einziger Reiter Einstellungen ersetzt die doppelte Navigation. Bankstand und AH-Preisstatus stehen getrennt nebeneinander. Der AH-Status bewertet die eindeutigen Materialien der erfassten Rezepte des gewählten Berufs: aktuell bis drei Tage, älter, ohne Datum oder fehlend. Ohne erfasste Materialien wird keine Aktualität behauptet. Die Fußzeile zeigt den gewählten Kostenmodus statt einer dauerhaften Preisalterwarnung.

Vier Camping-Dropzuordnungen und die Trapper-Werkbank sind ergänzt. Konkrete Live-Verfügbarkeit und verlässliche Dropchancen sind damit nicht bestätigt. Automatisierte Prüfungen ersetzen weiterhin keinen Test im Spiel.

## Neu in 0.12: Clever skillen und Camping-Einkauf

**Clever skillen** vergleicht den nächsten Skillschritt anhand erlernter Rezepte mit aktueller Skillfarbe. Neben nötigen Zukäufen zählt auch der mögliche Nettoverkaufswert verbrauchter eigener Materialien. So kann ein gekauftes Ersatzmaterial wirtschaftlicher sein als der Verbrauch wertvoller Vorräte. Eine Alternative anklicken zeigt Herstellungen, geschätzte Skillchance, Zukäufe und gegenüber der cash-günstigsten Variante freigewordene Verkaufsmengen.

Der AH-Abzug beträgt standardmäßig 5 % und lässt sich in Einstellungen von 0 bis 30 % ändern. AH-Preise sind gespeicherte Preisindikationen, keine zugesagten Verkaufserlöse oder verfügbaren Kaufangebote. Fehlende, undatierte oder über drei Tage alte relevante Preise verhindern einen als belastbar markierten Vorteil. Endproduktverkäufe und mögliche verlorene Einstellgebühren sind nicht eingerechnet. Der Vergleich bewertet direkte Zutaten, keine rekursiven Zwischenprodukte. Er ist eine Entscheidungshilfe für den nächsten Schritt, keine globale Optimierung bis Skill 300. Bestehende Pläne reservieren hier keine Bestände.

**Als Einkaufsplan übernehmen** ersetzt den aktuellen Plan durch die ausgewählte Variante. Über **Vorherigen Einkaufsplan wiederherstellen** im Clever skillen lässt sich diese Übernahme einmal rückgängig machen. Käufe, Verkäufe und Herstellung bleiben manuell. Herstellungen sind ganzzahlig; Preise je erwartetem Skillpunkt sind wegen der geschätzten Skillchance keine garantierten Kosten.

Unter **Camping → Einkauf** werden Objekte aller Berufe gemeinsam geplant. Ein Objekt aufklappen und +1 oder +5 wählen. Gleiche Zutaten werden addiert und Tasche/berücksichtigte Bankbestände einmal von der Gesamtsumme abgezogen. Eine geplante Objektzeile anklicken reduziert ihre Menge um eins. Unbekannte Materialien und fehlende Preise bleiben sichtbar; nicht erlernte Objekte dürfen geplant werden und bleiben entsprechend gekennzeichnet.

Für Berufe ohne feste Etappenübersicht erscheinen zusätzlich aktuelle erlernte Skillrezepte aus dem Client. Vollständige künftige Skillwege und zusätzliche unbestätigte Lehrerstandorte sind damit weiterhin nicht abgedeckt.

## Updates ohne CurseForge

Ab 0.12 tauscht CraftPilot beim Betreten der Spielwelt und bei Gruppen-/Gildenänderungen seine Versionsnummer über Addon-Nachrichten mit Gruppe, Raid oder Gilde aus. Eine neuere gemeldete Version erzeugt einmal pro Charakter und Versionsstand einen lokalen Chat-Hinweis; in Einstellungen steht der gemeldete Stand mit anklickbarem Kopierfenster für den festen GitHub-Release-Link.

Beide Seiten benötigen mindestens 0.12 für dieses Protokoll. Ein einmaliges manuelles Update von älteren Versionen ist erforderlich. Ohne Kontakt zu einer neueren Version entsteht kein Hinweis. Meldungen sind Versionsangaben anderer Spieler, keine authentifizierte GitHub-Abfrage. Es werden weder Dateien heruntergeladen noch Updates automatisch installiert. Nachrichten sind auf kurze Versionsnummern begrenzt und pro Kanal gedrosselt; fremde URLs und Inhalte werden nicht übernommen. Fehlende Kommunikations-APIs verhindern nicht die Nutzung des restlichen Addons.

## Neu in 0.12.1: Rezeptfarben und Berufsabgleich

Rezeptzeilen zeigen die aktuelle Clientfarbe und getrennt davon die Grenzen **Orange von–bis, Gelb von–bis, Grün von–bis, Grau ab**. Die Intervalle enden jeweils einen Punkt vor Beginn der nächsten Farbe. Leere Intervalle erscheinen als Strich. Fehlende, widersprüchliche oder zur eingelesenen Farbe abweichende Grenzen sind gekennzeichnet; ältere Grenzwerte sind keine Live-Bestätigung. Aufgeklappte Camping- und Clever skillen-Rezepte zeigen dieselben Informationen.

In Einstellungen ist **Orange/Gelb bevorzugen** standardmäßig aktiv. Bei der Standardsortierung und automatischen Route stehen bekannte, bewertbare orange/gelbe Rezepte vor grünen. Unvollständig bewertete Rezepte gewinnen dadurch nicht automatisch. Grün bleibt sichtbar, manuell auswählbar und im Clever skillen wirtschaftlich vergleichbar. Bewusste Rezeptauswahlen bleiben erhalten. Alte automatisch berechnete Routen werden beim ersten Start dieser Version verworfen; manuelle Pläne bleiben erhalten.

**Einstellungen → Berufsdaten prüfen** zeigt alle zwölf Berufe, verfügbare Grenzwerte und Abweichungen zu eingelesenen Clientfarben. Ein eigener Beruf lässt sich dort direkt öffnen. Für aktuelle Farben die eigenen Berufsfenster einmal öffnen; ohne Zugriff auf diese Fenster kann kein externer Abgleich alle live gültigen Rezeptstände bestätigen. Der Abgleich und seine Grenzen stehen in [Berufsstatus](docs/PROFESSION_STATUS.md).

Für Kochen und Erste Hilfe sind nur 162 zusätzliche Zahlenreihen aus den bereits gepinnten Eingaben ergänzt, keine vollständigen neuen Rezept-, Händler- oder Sammeldatenbanken. Reproduktion: `python tools/import_skill_ranges.py --source-dir work/camping-inputs --check` nach dem vorhandenen Camping-Import.

## Neu in 0.12.2: Clever skillen

Der wirtschaftliche Rezeptvergleich heißt jetzt **Clever skillen** (englisch: **Smart Skilling**). Die Implementierung liegt in `Economy.lua`. Vorhandener AH-Abzug, Rezeptauswahl, geöffneter Bereich und der rückgängig machbare Einkaufsplan werden automatisch übernommen. Die Berechnungen und das bestehende Design bleiben in dieser Version unverändert.

## Neu in 0.13: Kaufrezepte und direkte Rezeptwahl

In **Jetzt skillen** erscheinen passende, noch nicht erlernte Kaufrezepte aus den vorhandenen Katalogen. Der Filter **Kaufrezepte** zeigt sie mit einem Klick allein; **Alle Rezepte** kehrt zurück. Eine Kaufrezeptzeile anklicken zeigt Händler, bekannten Rezeptpreis und Standort unmittelbar darunter. Ein Händlerklick setzt TomTom oder den vorhandenen Kartenwegpunkt. Fehlt ein gültiger Standort, wird kein Ziel erfunden. Fraktion, Skill, bekannte Ruf-/Spezialisierungsbedingungen, Feiertage und besondere Währungen begrenzen die einfachen Kaufvorschläge. Bestände, Preise und Live-Angebote sind vor Ort zu prüfen; die Vorschläge garantieren keine Verfügbarkeit oder günstigste Route.

Erlernte Rezepte öffnen beim bewussten Rezeptklick die direkte Auswahl im eigenen Berufsfenster, sofern der Client `C_TradeSkillUI.OpenRecipe` anbietet. Im Kampf wird dieser Aufruf unterlassen. Ohne Direktwahl-API bleibt die allgemeine Berufsöffnung mit einem erklärenden Hinweis. Das Addon stellt nichts automatisch her. Nach Einlesen eines inzwischen erlernten Kaufrezepts wechselt die Auswahl zurück zum normalen Rezept. Ein noch nicht gelerntes Kaufrezept wird nicht als erlernte Planoption behandelt.

71 gezielt ausgewählte Händlerrezepte aus Kochen und Erster Hilfe ergänzen die bereits enthaltenen Herstellungsdaten. Ihr Import enthält nur diese Rezepte und referenzierte NPCs; die Eingaben sind bereits hash-gepinnt. Reproduzieren: `python tools/import_vendor_recipes.py --source-dir work/camping-inputs --check`.

### Optionale QuestieDB-Anbindung

Ein zusätzlich installiertes QuestieDB wird lokal und nur lesend über seine öffentliche API angesprochen. CraftPilot prüft den unterstützten API-Vertrag und den aktiven Forever-Datenstand. Geeignete NPC-Namen und Standorte können Händlerangaben ergänzen; zusätzliche Item-Händler werden nur aufgenommen, wenn ihre Fraktionszuordnung bereits im vorhandenen Katalog bekannt ist. Die AreaID-/UiMap-Zuordnung wird getrennt ausgewertet; Prozentwerte werden für Wegpunkte normalisiert. Ungültige, nicht zuordenbare und ausdrücklich phasenabhängige Punkte werden verworfen. Fehlende oder inkompatible Zusatzdaten fallen auf die vorhandenen Angaben zurück.

Unter Einstellungen steht, ob das optionale Modul verfügbar, ausgeschaltet oder im Entwicklungsmodus ist. Dort lässt sich seine Verwendung abschalten. Kein QuestieDB-Code und keine QuestieDB-Datenbank werden in CraftPilot gebündelt. Die API-Abfragen senden keine Spieler- oder Kontodaten an einen Server und schreiben keine Datenkorrekturen ins andere Addon. Eine vollständige Funktions- oder Datenprüfung im Forever-Client ist damit nicht behauptet.

## Neu in 0.14: Kostenkalkulation

Die Schaltfläche **Kostenkalkulation** oben öffnet ein eigenständiges, verschiebbares Fenster für das gewählte Rezept, einen Einkaufsvorschlag oder den aktuellen Plan. Im Einkaufsplan, Camping-Einkauf und beim ausgewählten Vergleich in Clever skillen stehen zusätzliche hervorgehobene Summenkarten mit direktem Zugriff. Kein weiteres Untermenü ist nötig; Escape schließt das Kostenfenster.

Die große Summe **Zusätzlich bezahlen** enthält Material-Zukauf und bekannte einmalige Rezeptkosten. Daneben stehen der Netto-AH-Wert verbrauchter eigener Vorräte und der **wirtschaftliche Aufwand**. Vorratswert ist kein zusätzlicher Geldabfluss und wird nicht nochmals als Zukauf gezählt. Bereits erlernte Rezepte verursachen keine erneuten Erwerbskosten; ein vorhandenes Rezeptbuch wird als eigener Vorrat berücksichtigt. Die eingestellte AH-Abgabe gilt für mögliche Nettoerlöse.

Bei Clever skillen werden gegebenenfalls gegenüber der Vergleichsvariante freigesetzte Vorräte separat als möglicher Verkauf und bedingter Saldo dargestellt. Dieser Erlös wird nicht von dem Geld abgezogen, das vor dem Einkauf benötigt wird. Unvollständige oder alte Vergleichspreise verhindern diese Verkaufsgutschrift. Endprodukte, Reiseaufwand und verlorene Einstellgebühren sind nicht eingerechnet. Fehlende Preise/Materialien stehen als unbekannte Anteile und werden nicht als kostenlose Positionen dargestellt.

**Neu berechnen** liest die Kalkulation erneut mit den aktuellen verfügbaren Beständen und Preisen. Bei Auto-Routen bleiben die Mengen die des gespeicherten Vorschlags; eine geänderte Herstellungsroute muss weiterhin über Auto-Route neu erzeugt werden. Neu erzeugte Routen erfassen den Verbrauch ursprünglicher Vorräte getrennt von hergestellten Zwischenprodukten. Alte Auto-Vorschläge ohne diese Information werden beim Update entfernt; manuelle Pläne bleiben erhalten.

Seit 0.15 berücksichtigt die Kalkulation gemeinsame Vorratsreservierungen über getrennte Berufs- und Campingpläne hinweg. Die Priorität lässt sich in Einstellungen ändern; Einzelheiten stehen im folgenden Abschnitt.

## Gemeinsame Planung und Fehlerberichte

Berufs- und Campingpläne teilen sich einen Vorrat. Unter **Einstellungen → Vorratsreservierungen** lässt sich ein Plan mit einem Klick priorisieren. Andere Pläne rechnen reservierte Mengen als zusätzlichen Zukauf; Taschen- und Bankbestände bleiben separat sichtbar. Die Reservierung ist eine Rechenhilfe und sperrt keine Gegenstände im Spiel.

**Plan geändert → neu bewerten** erscheint bei geänderten Preisen, Beständen, Reservierungen, Rezepten oder Skillständen. Manuelle Rezeptmengen bleiben erhalten; Auto-Routen werden auf Wunsch ab dem aktuellen Skill neu erstellt. Erkannte erfolgreiche Herstellungen reduzieren manuelle Berufs- und Campingmengen. Auto-Routen zeigen den Herstellungsfortschritt und bleiben bis zur Neubewertung als alter Rechenstand erkennbar.

Aufgeklappte Kaufrezepte vergleichen einen Herstellungsblock bei heutiger Skillfarbe einschließlich einmaligem Rezeptkauf. Der wirtschaftliche Vorteil je erwartetem Skillpunkt berücksichtigt den Netto-AH-Wert verbrauchter Vorräte. Fehlende oder veraltete Angaben erlauben keine positive Vorteilsbehauptung. Reisezeit und zukünftige Farbwechsel sind nicht eingepreist.

**Einstellungen → Fehler melden** sammelt bis zu 20 unterschiedliche CraftPilot-Fehler lokal. Unterstützt werden ein vorhandener nativer Lua-Fehlerlistener, optionales !BugGrabber und gesperrte CraftPilot-Aktionen. Ohne nativen Listener wird !BugGrabber für Lua-Stacks benötigt. Der Bericht enthält Version, Client-Build, Sprache, gewählte Ansicht und Berufsskill; keine Chat-/Inventardaten oder BugGrabber-Locals. Erkannte Spielernamen, E-Mail-Adressen, URLs und lokale Pfade werden gefiltert. Freitext vor dem Teilen selbst prüfen.

Der Nutzer prüft/ergänzt die Vorschau, wählt **GitHub-Link kopieren**, drückt **Strg+C** und öffnet den Link im Browser. Bereits beim Öffnen enthält die Anfrage den Bericht; das Issue wird anschließend mit einem eigenen GitHub-Konto abgeschickt. Es gibt keinen automatischen Upload und keinen externen Meldedienst. Bei langen Berichten wird der Link gekürzt; der vollständige Vorschautext lässt sich separat kopieren. Lokale Fehler können im selben Fenster gelöscht werden.

### Kompatibilitätskorrekturen in 0.15.1

Gepackte QuestieDB-Versionen können über `ModeIndicator.GetStatus()` keine Erweiterung melden. CraftPilot prüft dann im Baked-Modus die `X-Flavor`-Kennung des tatsächlich geladenen Pakets. Eine ausdrücklich andere Erweiterung wird weiterhin abgelehnt. Der Schalter erlaubt die optionale Anbindung; er beweist allein keine verfügbaren Daten. API-, Datenstand- und Paketkennungsprobleme werden getrennt angezeigt. QuestieDB wird weiterhin separat installiert.

Fehlt ein gelernter Beruf in den Rückgaben der älteren Berufsliste, fragt CraftPilot zusätzlich `C_TradeSkillUI.GetProfessionInfoBySkillLineID` ab. Ein positiver aktueller Skill mit passender Berufs-ID und Kapazität zählt als eigener Beruf, auch bei Erste Hilfe. Gespeicherte Referenzwerte und fremde verlinkte Berufsfenster zählen nicht als Besitznachweis. Änderungen an erlernten Fähigkeiten aktualisieren die Anzeige.

## Marktpreise, Bestände und Auctionator in 0.16

Dieser gemeinsame Release enthält auch die Korrekturen für **QuestieDB Baked/Forever** und **Erste Hilfe als eigenen Beruf**. Es genügt, diese Version zu installieren. QuestieDB bleibt separat installiert und optional.

Rezepte zeigen den gespeicherten **AH-Stückpreis**, dessen Alter, den möglichen **Netto-Stückerlös nach AH-Abzug** und den getrennten **Händlerankaufspreis**. Diese Angaben erscheinen auch an Materialkarten, Campingobjekten, eingeplanten Rezeptschritten und in der Kostenkalkulation. Ein Händler-Verkaufspreis ist kein Händler-Kaufpreis. Nicht zugeordnete Ergebnisse, Verzauberungsdienste, kalte Item-Caches und fehlende Scanwerte werden nicht als Nullpreis ausgegeben. Die Preise sind je Stück, kein pauschaler Gewinn pro Herstellung. Mögliche Ergebnisverkäufe werden nicht automatisch vom benötigten Einkaufsbudget abgezogen.

Die Rezeptzeile zeigt Zutaten mit Symbolen und **Tasche/Bank**; beim Überfahren stehen die einzelnen Namen, Bestände, Reservierungen und Fehlmengen im Tooltip. In der Materialansicht und Kalkulation stehen dieselben Bestände ausgeschrieben. Eine ausgeschaltete Bank wird markiert. Ein Bankwert bleibt der letzte erfasste Stand.

**Behalten/Verkaufen:** explizite Planmengen haben Vorrang. Weitere erlernte Skillrezepte und mögliche Katalog-Folgerezepte bis zum geplanten Ziel, sonst höchstens 25 Skillpunkte voraus, liefern einen Hinweis zum Vormerken. Das ist keine zusätzlich reservierte Menge und keine Zusage, dass das Referenzrezept aktuell verfügbar ist. Ohne Bedarfshinweis wird der AH-Netto-Stückpreis mit dem Händlerankauf verglichen. Fehlende, undatierte oder über drei Tage alte AH-Preise verhindern eine positive Vergleichsempfehlung. Bekannte Binde-beim-Aufheben-/Questgegenstände werden nicht fürs AH empfohlen; die tatsächliche Bindung eines vorhandenen Exemplars und eigene Nutzung bleiben selbst zu prüfen. Nachfrage und verlorene AH-Einstellgebühren sind nicht modelliert.

### Einkaufsliste für einen Skillbereich

1. **Einkaufsplan** öffnen und **Start Y / Ziel X** wählen.
2. **Auto-Route** erstellen oder erlernte Rezeptschritte mit ihren Mengen selbst planen. Der manuelle Plan exportiert genau diese Schritte, keine automatisch ergänzte vollständige Skillroute.
3. **Auctionator-Einkaufsliste erstellen** anklicken. Ist noch kein Schritt geplant, wird für den gewählten Bereich eine Auto-Route erzeugt. Geänderte Auto-Routen werden vor dem Export neu bewertet; ein bereits fortgeschrittener Charakter beginnt dabei am aktuellen Skill.
4. Die Liste **CraftPilot - Beruf Y-X** steht in Auctionator mit exakten Suchnamen und Fehlmengen. Tasche, einbezogene Bank und andere Planreservierungen werden berücksichtigt. Gleiche Listennamen werden aktualisiert; andere Listen bleiben erhalten. Gibt es keine Fehlmengen mehr, wird die gleichnamige CraftPilot-Liste geleert. Der Kauf bleibt manuell.

Auto-Routen verrechnen die geplante Herstellungskette. Manuelle Pläne ordnen ausdrücklich eingeplante Zwischenprodukte vor ihren Verbrauchern ein und rechnen die aktuell erfasste Mindest-Ausbeute an. Diese Zwischenprodukte werden dann nicht nochmals eingekauft. Es werden keine zusätzlichen manuellen Herstellungsschritte erfunden. Ungeklärte Zutaten/Ausbeuten, zyklische Ketten, nicht auflösbare Itemnamen oder eine vor dem Ziel abbrechende Auto-Route sperren den Export mit einem Hinweis. Vorhandene Pläne bleiben nutzbar; für die neue Ausbeute-Erfassung die eigenen Berufsfenster einmal öffnen.

Unter **Camping → Einkauf** steht derselbe Export für fehlende Camping-Zutaten. Er benötigt eine aktivierte kompatible Auctionator-Version mit öffentlicher Einkaufslisten-API. Das AH muss zum Erstellen der Liste nicht offen sein; Auctionator kann bei offenem AH bereits die Suche starten. Es wird keine Auctionator-Datenbank direkt verändert oder mitgeliefert.

## Nicht gelernte Lehrerrezepte und vollständige Ansicht (0.17)

**Jetzt skillen** und **Clever skillen** berücksichtigen passende, noch nicht gelernte Lehrerrezepte. Material-Zukauf und einmalige Lerngebühr werden mit erlernten Optionen verglichen. Mögliche Zukaufvorteile stehen vorn; unbekannte oder geschätzte Gebühren gelten nicht als gesicherte Ersparnis. Die Beispielmenge umfasst etwa fünf erwartete Punkte bei heutiger Skillfarbe, keine Simulation künftiger Farbwechsel. Reise und eventuell neu benötigte Werkzeuge sind nicht eingepreist. In Clever skillen kann ein fehlender Goldbetrag erscheinen.

Unter dem Vorschlag steht ein passender Lehrer mit direktem Wegpunkt. Aktuelle Karte und dortige Koordinatennähe haben Vorrang. Explizite Lehrerbeschränkungen werden beachtet; ein allgemeiner Berufs-Lehrer ist nur ein mögliches Ziel. Aktuelles Angebot vor Ort prüfen. Noch nicht gelernte Rezepte werden nicht als bereits erlernte manuelle Herstellungsoptionen behandelt.

Der Ansichtsknopf wechselt **Sinnvolle Rezepte → Nicht gelernt → Alle Rezepte**. Alle zeigt zusätzlich zukünftige und andere im vorhandenen Katalog oder Client-Snapshot enthaltene Rezepte, ausgegraut mit Lernskill. Die Anzeige verspricht keinen vollständigen aktuellen Spielkatalog; fehlende Quellen/Voraussetzungen bleiben zu prüfen.
