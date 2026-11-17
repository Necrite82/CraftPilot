# CraftPilot 0.22.0-alpha

## Empfehlung oben in „Jetzt“

Über der Rezeptliste steht jetzt der eine nächste Schritt: zum Beispiel „Empfehlung: 5× Genaues Zielfernrohr bis Skill 210 · Fehlt: 5 Jade, 5 Citrin, 5 Bronzeröhre · ca. 1g 23s“.

- **Im AH suchen:** Am offenen Auktionshaus sucht Auctionator alle fehlenden Materialien auf einmal. An anderen Orten legt CraftPilot die Einkaufsliste „CraftPilot - Empfehlung“ mit den Mengen in Auctionator an, die du am Auktionshaus öffnest. Ist alles vorrätig, öffnet der Button direkt das Berufsfenster.
- **Auswählen** zeigt das empfohlene Rezept im Detailbereich, falls gerade ein anderes gewählt ist.
- Gibt es ein Lehrerrezept, das inklusive Lernkosten günstiger ist, steht ein Tipp dabei.
- Grundlage ist die gespeicherte Route, sonst das günstigste erlernte Rezept nach der gewohnten Rangfolge. Die Empfehlung erscheint nur mit aktuell eingelesenen Skillfarben.

## Korrekturen und Feinschliff

- **Kosten-Details** als saubere Zeilen (Zukauf für N×, AH netto / Stück, Händler / Stück) statt drei enger Kästen, in denen Beschriftung und Beträge überliefen.
- **Kostenspalte:** Lehrerrezepte zeigen die Kosten je erwartetem Punkt inklusive Lernkosten statt „?“; Kaufrezepte „—“ (Preis steht darunter); vollständig vorrätige Rezepte „vorrätig“ statt „0“.
- „1 Teil fehlt“ statt „1 Teile fehlen“; Prozentwerte ohne Tilde.
- Im Detailbereich steht der nächste Rezeptwechsel („Danach: … ab Skill …“).

Validierung: vollständige Tests unter Lua 5.1 und 5.4, darunter neue Tests für Empfehlung, Kostenspalte, Kosten-Details und die Auctionator-Suche bzw. -Liste. Die Auctionator-Mehrfachsuche ist gegen die dokumentierte API v1 geschrieben und noch nicht im Spiel beobachtet.
