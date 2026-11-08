# Herkunftsprüfung vor einem CurseForge-Release

Prüfdatum: 2026-11-08. Geprüfter CraftPilot-Stand:
`daecfb866ed34d512ed0885e60d9dfa706459674` (0.8.0-alpha).

**Ergebnis: Die vollständige Rechtekette des mitgelieferten Rezeptkatalogs ist
derzeit nicht ausreichend belegt. Dieser Stand erhält aus dieser Prüfung keine
Freigabe für einen CurseForge-Upload oder automatische Paketveröffentlichung.**
Das ist eine dokumentierte Nachweislücke, keine Feststellung, dass sämtliche
Datensätze rechtswidrig wären. Öffentliche Erreichbarkeit, eine bestandene CI und
eine GPL-Datei im übergeordneten Projekt ersetzen den fehlenden Nachweis nicht.

Diese Änderung enthält ausschließlich einen Prüfbericht und ein Inventar. Sie
entfernt oder verändert keine Daten, Funktionen, Lizenztexte oder ZIP-Dateien.
Es wurde kein Herausgeber kontaktiert, keine Erlaubnis eingeholt und kein
CurseForge-Projekt verbunden oder veröffentlicht.

## Umfang und verifizierte Herkunft

Die sechs vollständigen Herstellungsdateien in `ThirdParty/CraftLadder` sind über
ihre Git-Blob-IDs identisch mit `CraftLadder/Data/` in
[Craft Ladder b9c61346](https://github.com/saintmodx/craft-ladder/tree/b9c61346ad4cf63245f35cadb1e0a88467fb6e75).
Die Identität ist im [Inventar](PROVENANCE_INVENTORY.json) festgehalten. Die
Revision gehört zu Craft Ladder 1.7.0; die Kopfkommentare nennen die älteren
Forever-Clientbuilds 1.60.1.70425 bzw. 1.60.1.70450.

`MiningSmelting.lua` ist dagegen ein bearbeiteter Auszug mit zehn Schmelzrezepten,
keine unveränderte Originaldatei. Er enthält keine `nodes`- oder `zones`-Tabellen
und damit nicht die im ursprünglichen Mining-Datensatz enthaltenen
GatherMate2-Sammelstandorte. Das beweist keine vollständige Rechtefreigabe seiner
anderen Datenbestandteile.

Alle sieben Katalogdateien werden von `CraftPilot.toc` geladen und liegen auch im
ZIP `dist/CraftPilot-0.8.0-alpha.zip`. Die vorhandenen ZIPs 0.4 bis 0.7 enthalten
keinen `ThirdParty/CraftLadder/`-Pfad. Daraus folgt keine vollständige Freigabe
dieser älteren Versionen; sie wurden nicht als Ersatzrelease zertifiziert.

## Prüfung der einzelnen Quellen

| Quelle | Verifizierter Befund | Bedeutung für den bestehenden Katalog |
| --- | --- | --- |
| Craft Ladder | Eigene GPL-3.0-Lizenz und Quellen-Credits an der übernommenen Revision vorhanden | Die direkte Herkunft ist belegt. Der Herausgeber kann damit keine fehlenden Rechte anderer Urheber ersetzen. |
| CMaNGOS classic-db | Der Builder pinnt `22b51464f1625f6ef6275771de1f5466c6f5d19e`; dort liegt GPLv3 | Lizenz grundsätzlich mit GPLv3 vereinbar. Kein Ersatz für die Prüfung anderer Eingänge. |
| AllTheThings | Der Builder pinnt `10164719738bdc1e7baa23dd854bef4c7184a6ac`; dort MIT, Copyright (c) 2026 AllTheThings WoW Addon | Original-MIT-Text ist bereits in den mitgelieferten Credits enthalten. Lizenz grundsätzlich GPL-kompatibel. |
| QuestieDB / Questie | Tatsächlich eingelesene Installation nicht revisionsgebunden; aktuelle Lizenz erklärt historische Rechte ausdrücklich als teilweise ungeklärt | Offener Freigabepunkt. Keine pauschale GPL-Freigabe des gesamten historischen Datenbestands ableitbar. |
| Blizzard-Clienttabellen über wago.tools | Builder liest CSV-Exporte unter anderem für Rezepte, Reagenzien, Skillfarben, Ergebnisse und Preise | Technischer Bezug ist nachweisbar, aber keine konkrete ausdrückliche Weiterverteilungserlaubnis für diese Exporte im geprüften Material. Offen, nicht automatisch verboten. |
| Spielerbeobachtungen von Craft Ladder | Builder benennt eigene gespeicherte Beobachtungen als Eingang; übergeordnete GPL-Erklärung vorhanden | Der genaue beitragende Datenstand und seine Zuordnung zu Feldern sind nicht als eigenständige vollständige Rechtekette belegt. |
| GatherMate2_Data | In den allgemeinen Credits und dem ursprünglichen Mining-Builder genannt | Keine pauschale Beanstandung des Schmelzauszugs wegen nicht enthaltener Sammelstandorte. Für spätere Sammelimporte separat prüfen. |

Originalnachweise:

- [Craft Ladder: Lizenz](https://github.com/saintmodx/craft-ladder/blob/b9c61346ad4cf63245f35cadb1e0a88467fb6e75/CraftLadder/LICENSE),
  [Credits](https://github.com/saintmodx/craft-ladder/blob/b9c61346ad4cf63245f35cadb1e0a88467fb6e75/CraftLadder/CREDITS.txt).
- [CMaNGOS: Lizenz an der tatsächlich gepinnten Revision](https://github.com/cmangos/classic-db/blob/22b51464f1625f6ef6275771de1f5466c6f5d19e/LICENSE.md).
- [AllTheThings: Lizenz an der tatsächlich gepinnten Revision](https://github.com/ATTWoWAddon/AllTheThings/blob/10164719738bdc1e7baa23dd854bef4c7184a6ac/LICENSE).
- [QuestieDB: Lizenz](https://github.com/Questie/QuestieDB/blob/f863e106c837f1e30e6dae0e44b166be9bceb5f1/LICENSE.md),
  [historische Herkunft](https://github.com/Questie/QuestieDB/blob/f863e106c837f1e30e6dae0e44b166be9bceb5f1/PROVENANCE.md).
- [Craft Ladder: Katalog-Builder](https://github.com/saintmodx/craft-ladder/blob/b9c61346ad4cf63245f35cadb1e0a88467fb6e75/tools/build_crafting.py),
  [QuestieDB-Leser](https://github.com/saintmodx/craft-ladder/blob/b9c61346ad4cf63245f35cadb1e0a88467fb6e75/tools/questiedb.py),
  [CMaNGOS-Pin](https://github.com/saintmodx/craft-ladder/blob/b9c61346ad4cf63245f35cadb1e0a88467fb6e75/tools/build_fishing.py),
  [ATT-Pin](https://github.com/saintmodx/craft-ladder/blob/b9c61346ad4cf63245f35cadb1e0a88467fb6e75/tools/att.py),
  [CSV-Bezug](https://github.com/saintmodx/craft-ladder/blob/b9c61346ad4cf63245f35cadb1e0a88467fb6e75/tools/wago.py),
  [Mining-Builder](https://github.com/saintmodx/craft-ladder/blob/b9c61346ad4cf63245f35cadb1e0a88467fb6e75/tools/build_mining.py).

Bei QuestieDB wurde zusätzlich der vollständige Baum der geprüften Revision auf
Lizenzdateien geprüft: es gibt keine separate Lizenzdatei im Forever-Unterbaum.
Die Kopfbereiche der dortigen NPC- und Itemtabellen enthalten keine abweichende
ausdrückliche Freigabe. Das belegt nicht den Lizenzstand der unbekannten früheren
Installation. Gerade diese Unsicherheit darf nicht durch einen aktuellen
Revisionswert ersetzt werden.

## Warum das Entfernen einzelner Felder nicht ausreicht

Der Katalog-Builder liest QuestieDB für:

- Itemnamen als Rückfallquelle (`build_crafting.py`, Zeile 218);
- Händler-, Quest- und Dropquellen von Rezeptgegenständen (ab Zeile 313);
- NPC-/Questinformationen und Spezialisierungsschritte;
- Auswahl verkäuflicher Werkzeuge (Zeile 515);
- Händlerzuordnung und Fraktionsabdeckung von Reagenzien sowie die Entscheidung,
  ob ein Reagenz als dauerhaft beim Händler erhältlich gilt (Zeilen 623–637).

Die letzte Abhängigkeit fließt in `vendorPrices` ein, also in Planungsgrundlagen.
Auch Auswahl und Verfügbarkeit eines Rezepts werden aus mehreren Quellen
abgeleitet. Die generierten Dateien besitzen keinen vollständigen, pro Feld
prüfbaren Herkunftsnachweis. Ein nachträgliches Löschen nur von `npcs` oder
`quests` würde deshalb keine unabhängig neu erzeugte Datenbasis schaffen.

## Blizzard-Schnittstellen: getrennte Nutzungsgrundlagen

Die im Spiel angebotene Add-on-Schnittstelle und die externe Battle.net-Web-API
sind getrennt zu betrachten. Die
[Add-on-Richtlinie](https://eu.forums.blizzard.com/en/wow/t/wow-user-interface-add-on-development-policy/1642)
beschreibt Bedingungen für Add-ons. Die
[Developer-API-Bedingungen](https://www.blizzard.com/en-us/legal/a2989b50-5f16-43b1-abec-2ae17cc09dd6/blizzard-developer-api-terms-of-use)
gelten für die Web-API und sind keine MIT-/GPL-Datenlizenz.

Weder die Berechtigung, Informationen im Berufsfenster für ein Add-on zu nutzen,
noch eine vorhandene Recipe-Web-API beweist automatisch, dass ein fremder
massiver CSV-/Clientdatenexport beliebig weiterverteilt werden darf. In dieser
Prüfung wurde kein authentifizierter Forever-Rezeptabruf durchgeführt und keine
vollständige Web-API-Abdeckung oder Zustimmung Blizzards bestätigt. Aus nicht
erreichbaren Dokumentationsseiten wird weder Erlaubnis noch Verbot abgeleitet.

## Getrennter Quellenentwurf für die nächste Version

[PR #5](https://github.com/Necrite82/CraftPilot/pull/5) enthält pfQuest-MIT- und
EG-Link-CC-BY-4.0-Referenzdaten mit eigenen Manifesten. Diese Lizenzen lösen die
Herkunftslücken des bestehenden Craft-Ladder-Katalogs nicht rückwirkend. Sie
erfassen nur die jeweiligen Rechte der Herausgeber und sind keine zusätzliche
Freigabe für Blizzard-Inhalte. PR #5 ist kein vollständiger neuer Rezeptkatalog
und bleibt getrennt von einer Releasefreigabe.

## Konkrete noch benötigte Nachweise

Für eine Fortsetzung mit dem vorhandenen Katalog sind folgende Punkte zu klären:

1. **Craft Ladder:** genaue QuestieDB-Version/Revision oder Artefakt-Prüfsumme der
   verwendeten Installation; Zuordnung der daraus übernommenen Felder und
   abgeleiteten Auswahlentscheidungen; dokumentierte Rechtebasis dieser Daten.
2. **QuestieDB / betroffene Rechteinhaber:** Nachweis, welcher konkret benötigte
   historische Ausschnitt ausdrücklich weiterverbreitet werden darf. Eine
   allgemeine Zustimmung eines Maintainers reicht nicht als Zustimmung aller
   anderen Rechteinhaber, soweit deren geschützte Beiträge betroffen sind.
3. **Clienttabellen:** tragfähige Nutzungsgrundlage für genau den verteilten
   Ausschnitt und seinen Bezugsweg; alternativ eine unabhängig aufgebaute,
   dokumentierte Datenbasis über dafür geeignete freigegebene Schnittstellen.
4. **Reproduzierbarkeit:** belegte Revisionen/Prüfsummen aller Eingänge und
   Dokumentation der Transformationen. Ein neuer Builder muss ungeklärte
   Quellen tatsächlich ausschließen, statt nur deren Namen zu entfernen.

Es wurden keine Anfragen versandt. Die folgenden Fragen sind als Vorbereitung
für eine mögliche Anfrage gedacht:

- Welche genaue QuestieDB-Installation wurde bei der Generierung der Dateien
  für Craft Ladder 1.7.0 verwendet?
- Gibt es für den verwendeten NPC-/Item-/Quest-Ausschnitt dokumentierte,
  ausreichend umfassende Weiterverbreitungsrechte einschließlich abgeleiteter
  Datensätze auf GitHub und CurseForge?
- Können die tatsächlich verwendeten Clienttabellen samt Build, Prüfsummen und
  ihrer Weiterverteilungsgrundlage benannt werden?
- Kann ein minimaler Ausschnitt unabhängig aus ausschließlich nachvollziehbar
  freigegebenen Quellen neu erzeugt werden?

## Grenze vor der CurseForge-Anbindung

Eine automatische Repo-Anbindung kann Commits oder Tags direkt paketieren.
Laut [CurseForge-Dokumentation](https://support.curseforge.com/support/solutions/articles/9000197281)
können auch ungetaggte Commits als Alpha veröffentlicht werden, wenn dies so
konfiguriert ist. Die
[Paketkonfiguration](https://support.curseforge.com/support/solutions/articles/9000197952-preparing-the-packagemeta-file)
kann Pfade ausschließen; das ist aktuell noch nicht eingerichtet und wurde
nicht auf CurseForge getestet.

Vor der Aktivierung sind daher zuerst die offenen Rechtefragen zu lösen und
anschließend das tatsächlich erzeugte Paket zu kontrollieren. `research/`,
`docs/`, Tests, Werkzeuge und alte `dist/`-Archive dürfen nicht versehentlich
als zusätzliches Datenpaket ausgeliefert werden. Ein Ausschluss vom TOC allein
verhindert keine Weiterverteilung im ZIP. Auch ein Alpha ist eine Veröffentlichung.

**Aktueller Status:** Prüfung abgeschlossen, Nachweise unvollständig,
Veröffentlichung zurückgestellt. Keine Datenbereinigung oder Veröffentlichung
im Rahmen dieses Prüfberichts.
