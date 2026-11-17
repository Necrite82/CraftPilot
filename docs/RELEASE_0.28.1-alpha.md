# CraftPilot 0.28.1-alpha

Korrekturen aus den Screenshots des Spieltests:

- **Herstellen-Knopf:** Er zeigte „Herstellen: 18×“, obwohl Material fehlte. Liefert der Client keine Angabe, wie oft ein Rezept herstellbar ist, zählt CraftPilot jetzt selbst aus den Taschen. Bank und Twinks zählen dafür nicht, denn herstellen kann man nur aus der Tasche. Reicht es nicht, steht „Material fehlt“ auf dem Knopf.
- **„alles vorrätig“, obwohl das Berufsfenster 0/3 zeigt:** Liegt das Material in der Bank oder bei Twinks, heißt es jetzt „vorrätig · erst aus Bank/von Twinks holen“. Nur wenn alles in der Tasche ist, steht „alles in der Tasche“. Das gilt auch für die Empfehlung oben.
- **Punkte über den Materialnamen:** Die Taschenmarkierung erfasste auch CraftPilots eigene Materialzeilen. Eigene Fenster sind jetzt ausgenommen.
- **Kästchen statt Pfeil:** Die Spielschrift kennt das Zeichen „→“ nicht. Hinweise wie „Spezialisierung … siehe Lehrer & Händler, Bereich Spezialisierung“ kommen jetzt ohne Pfeil aus.
- **„Orange -“:** Farben, die ein Rezept überspringt, werden in den Farbbereichen nicht mehr angezeigt.
- **„zusätzlich einplanen 0“:** Heißt jetzt „Vorrat reicht“.

Validierung: vollständige Tests unter Lua 5.1 und 5.4, neu `tests/fix_0281.lua`.
