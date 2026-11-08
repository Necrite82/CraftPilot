# Changelog

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
