# CraftPilot 0.28.2-alpha

## Übersichtlicher „Günstigster Weg“

Der Tooltip der Empfehlung war eine Wand aus umbrochenen Zeilen. Jetzt ist er zweispaltig:

- **Je Abschnitt eine Zeile:** Skillbereich, Menge und Rezept links, Kosten rechts, z. B. „225–230   5× Tödliches Zielfernrohr · 1g 20s“.
- **Lernen auf einer eigenen, eingerückten Zeile** („beim Lehrer lernen“, „beim Händler kaufen“ oder „im AH kaufen“) mit den Lernkosten rechts.
- **„Gesamt bis Skill 300“** abgesetzt in Gold.
- **Hinweise am Ende in Grau:** fehlende Preise, Twinks als Hersteller, Verkaufserlös, alte Preise.

## Als Nächstes lernen

Rezepte, die erst später lernbar sind (z. B. ab Skill 225), nimmt der günstigste Weg schon mit. Damit du den Lehrerbesuch rechtzeitig einplanen kannst, steht der nächste Lernschritt jetzt im Voraus da:

- ganz oben im Tooltip des Weges
- im Begleitfenster: „Als Nächstes lernen: Tödliches Zielfernrohr ab Skill 225 (Lehrer, 30s)“

Alle Lernhalte auf einmal plant weiterhin die Lerntour unter Lehrer & Händler.

Validierung: vollständige Tests unter Lua 5.1 und 5.4, neu `tests/fix_0282.lua`.
