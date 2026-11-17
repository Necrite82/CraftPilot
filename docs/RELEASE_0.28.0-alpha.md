# CraftPilot 0.28.0-alpha

Letzte Runde vor der Beta: Fehlerbehebung, Herstellen aus dem Begleitfenster, Einkaufsrunde am AH, erster Start und eine neue Hilfe.

## Fehler behoben: „attempt to compare … secret number value“ (Marks.lua)

Die Suche nach Taschenfeldern las die Größe beliebiger Fenster aus, z. B. des Schadensmessers. Neuere Clients geben solche Werte an Addons nur geschützt heraus. Jetzt gilt:

- CraftPilot liest nur noch, was ein Gegenstandsfeld anbietet (Tasche und Platz oder Gegenstand), keine Größen oder Positionen fremder Fenster.
- Geschützte Werte werden erkannt und übersprungen.
- Markierungen werden in einer eigenen Tabelle geführt statt als Feld an fremden Knöpfen.

## Herstellen aus dem Begleitfenster

„Herstellen: N×“ stellt die empfohlene Menge her (begrenzt durch das vorhandene Material), „1×“ genau eine. Fehlt Material, zeigt der Knopf „Material fehlt“. Danach rechnet die Empfehlung von selbst weiter.

Falls WoW Forever das Herstellen für Addons sperrt, erscheint ein klarer Hinweis statt eines Fehlers – bitte melden.

## Einkaufsrunde am Auktionshaus

Beim Öffnen des Auktionshauses bietet ein kleines Fenster die Einkaufsrunde für alle fehlenden Materialien deiner Pläne an:

- Posten für Posten mit „Noch N×“, letztem AH-Preis und Preisgrenze („lohnt sich bis …“).
- Auctionator sucht den Posten.
- Gekauftes wird aus den Taschen abgezählt. Fertige Posten gehen von selbst weiter.
- „Zurück“, „Weiter“ und „Runde beenden“ jederzeit.

## Erster Start und Hilfe

- **Erster Start**: Beim ersten Öffnen erscheint die Hilfe mit einer Willkommenskarte, drei ersten Schritten und dem Hinweis, ob Auctionator installiert ist. „Los geht's“ blendet die Willkommenskarte aus.
- **Neue Hilfe**: über „?“ in der Kopfzeile oder `/cp hilfe`. Die alte Hilfe zeigte nur noch die Einstellungen; die neue beschreibt den aktuellen Stand:
  - Erste Schritte
  - alle fünf Reiter
  - Begleitfenster und Herstellen
  - Auktionshaus, Händler, Bank, Briefkasten, Markierungen und Tooltips
  - Skillweg, Farben und Chancen, Preise als Schätzung
  - Befehle und Fehler melden

  Viele Karten öffnen per Klick den passenden Bereich.
- Die Befehlsübersicht im Chat ist bereinigt (keine veralteten Befehle mehr).

Validierung: vollständige Tests unter Lua 5.1 und 5.4, neu `tests/beta_028.lua` (Herstellen, Einkaufsrunde, erster Start) und geschützte Werte in `tests/marks_027.lua`. Im Spielclient nicht getestet – besonders den Herstellen-Knopf und die Einkaufsrunde bitte prüfen.
