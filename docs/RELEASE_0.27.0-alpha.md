# CraftPilot 0.27.0-alpha

## Markierung reservierter Gegenstände in Taschen und Bank

WoW erlaubt Addons nicht, Gegenstände gegen Verkauf zu sperren. CraftPilot markiert sie deshalb und fängt Fehlgriffe ab:

- **Punkt in der Ecke des Taschenfelds**:
  - Gold: Ein späterer Planschritt braucht den Gegenstand. Aufheben, auch wenn schon genug da ist.
  - Blau: Dein Plan braucht ihn jetzt.
- **Unabhängig vom Taschen-Addon**: CraftPilot erkennt Gegenstandsfelder an dem, was sie anbieten (Tasche und Platz oder Gegenstand), statt an einem bestimmten Addon. Damit funktionieren die Standardtaschen, EllesmereUI und die üblichen Taschen-Addons wie Baganator, Bagnon oder AdiBags ohne eigene Anpassung.
- **Abschaltbar** unter Einstellungen → „Markierung in Taschen und Bank“.
- **Verkauft trotzdem**: Am Händler meldet CraftPilot sofort „Achtung: 6× … verkauft · gebraucht für … ab Skill …“ und bietet „Zurückkaufen“ aus dem Rückkauf des Händlers an.
- **Auktionshaus**: Nimmst du dort einen reservierten Gegenstand auf oder legst ihn ins Verkaufsfeld, erscheint „Nicht einstellen: … wird für … gebraucht.“

Im Kampf werden keine Markierungen geändert. Validierung: vollständige Tests unter Lua 5.1 und 5.4, neu `tests/marks_027.lua` (verschiedene Arten von Taschenfeldern, Rückkauf, AH-Warnung). Im Spielclient nicht getestet – besonders die Markierung in EllesmereUI-Taschen bitte prüfen.
