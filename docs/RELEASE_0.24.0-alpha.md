# CraftPilot 0.24.0-alpha

## Fehler behoben: ADDON_ACTION_BLOCKED „OpenTradeSkill()“

`C_TradeSkillUI.OpenTradeSkill` ist in WoW Forever für Addons gesperrt, auch direkt aus einem Klick. CraftPilot ruft die Funktion nicht mehr auf. Im Berufsmenü liegt über jedem erlernten Herstellungsberuf ein gesicherter Zauber-Button, der den Berufszauber wirkt – wie ein Klick im Zauberbuch – und gleichzeitig die CraftPilot-Ansicht wechselt. Die Buttons hängen nicht am CraftPilot-Fenster (es bleibt im Kampf schließbar) und werden bei Kampfbeginn ausgeblendet; im Kampf wechselt das Menü nur die Ansicht. Abschaltbar über „Berufsfenster automatisch öffnen“.

## Günstigster Weg nach AH-Preisen

Die Empfehlung beruht jetzt auf einer Rechnung **Skillpunkt für Skillpunkt bis zur Ausbildungsgrenze**:

- Je Punkt zählen die erwarteten Kosten: Herstellungskosten zu AH- bzw. Händlerpreisen geteilt durch die Chance der Farbe (Orange 100 %, Gelb ca. 70 %, Grün ca. 35 %). Ein gelbes Rezept mit 10 Kosten (≈14,3 je Punkt) verliert so gegen ein oranges mit 12.
- Eigene Vorräte werden zum Marktwert angesetzt und machen kein Rezept künstlich „kostenlos“; abgezogen werden sie erst beim Einkauf.
- Rezepte vom Lehrer oder Händler kommen nur in den Weg, wenn sie mehr sparen, als das Lernen kostet; die Lernkosten zählen einmal. Dann lautet die Empfehlung „Erst lernen: … · dann ca. N× bis Skill X“ mit „Wegpunkt zum Lernen“.
- Fehlen Materialpreise, wird das Rezept nicht geraten, sondern als „ohne vollständige Preise“ gemeldet; Zwischenprodukte ohne AH-Preis werden über ihre eigenen Materialien bewertet.
- Die Empfehlungsleiste zeigt „Günstigster Weg bis 300: ca. …“; mit der Maus darüber erscheint der ganze Weg Abschnitt für Abschnitt.
- Erlaubte Farben und Punktgrenzen aus den Einstellungen gelten weiter. „Orange/Gelb bevorzugen“ entscheidet bei der Empfehlung nur noch bei Gleichstand.

Die Rechnung braucht mit echten Daten unter 10 ms. Verkaufserlöse hergestellter Gegenstände sind nicht eingerechnet.

## Begleitfenster

- An der Kopfzeile **verschiebbar**, die Position wird gespeichert.
- **Minimieren** (Minus/Plus) klappt es auf die Kopfzeile zusammen; **Schließen** blendet es bis zum nächsten Öffnen des Berufsfensters aus.
- Ohne gespeicherte Position steht es neben den Berufssymbolen am Berufsfenster statt darauf.

Validierung: vollständige Tests unter Lua 5.1 und 5.4, darunter neue Tests für den Pfad (Orange gegen Gelb, Lernkosten nur bei Ersparnis und einmalig, fehlende Preise), die gesicherten Berufsbuttons (kein geschützter Aufruf, nicht im Kampf) und die Begleitfenster-Bedienung. Im Spielclient nicht getestet.
