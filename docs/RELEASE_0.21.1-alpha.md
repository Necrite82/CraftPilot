# CraftPilot 0.21.1-alpha

Korrekturen nach dem ersten Test von 0.21.0 im Spiel:

- **Fenster lag hinter dem Interface:** CraftPilot liegt jetzt auf der Ebene „HIGH“, also über Einheitenfenstern und Aktionsleisten und weiterhin unter Dialogen wie Kostenkalkulation oder eigener Einkaufsliste.
- **Näher am abgestimmten Mockup:** Reiter, Umschalter (Lehrer/Händlerrezepte, Einkaufen/Herstellen/Details, Camping-Bereiche) und die goldenen Hauptaktionen zeichnet CraftPilot jetzt selbst. EllesmereUI hatte sie zu dunklen Blöcken mit unlesbarer Schrift umgefärbt; Fensterrahmen, Bildlaufleisten und normale Buttons übernimmt EllesmereUI weiterhin.
- Lehrer und lernbare Rezepte sind flache Zeilen mit Trennlinie statt einzelner Kästen, die Skillfarben werden als runde Punkte angezeigt.
- Pfeilzeichen, die die Spielschrift nicht enthält (erschienen als Kästchen, z. B. im Berufsmenü), sind durch Spieltexturen ersetzt.

Validierung: vollständige Tests unter Lua 5.1 und 5.4. Darstellung im Spielclient bitte erneut prüfen.
