# CraftPilot 0.26.0-alpha

Das letzte Funktionspaket vor der Beta: Hinweise zum Aufheben, Preisgrenzen, Händler-Helfer, Tooltips, Verwerten und Budget-Modus.

## Aufheben für spätere Schritte

Was ein Planschritt herstellt und ein späterer Schritt wieder braucht, wird deutlich markiert:

- **Plan → Herstellen**: Bereich „Aufheben für spätere Schritte“ mit Menge, Rezept und Skill, ab dem es gebraucht wird.
- **Rezeptdetails**: „Behalten: 6× Bronzene Röhre für … ab Skill 120 · nicht verkaufen“.
- **Nach dem Herstellen**: Hinweis im Begleitfenster und in der Bildschirmmitte.
- **Tooltip** des Gegenstands: „Nicht verkaufen: 6 für deinen Plan (ab Skill 120)“.
- **Schon genug da** (Taschen, Bank, Twinks): „Schon vorhanden … nicht erneut herstellen“.
- **Verwerten** schlägt geplante oder aufzuhebende Gegenstände nie zum Verkauf vor.

Grundlage ist der gespeicherte Plan; ohne Plan der günstigste Weg bis zur Ausbildungsgrenze.

## Preisgrenze je Material

Der günstigste Weg rechnet mit, bis zu welchem Preis ein Material lohnt, bevor ein anderes Rezept je Skillpunkt günstiger wird. Die Grenze erscheint an zwei Stellen:

- unter Plan → Einkaufen („Kupferbarren: lohnt sich bis 12s · darüber ist … günstiger“, rot, wenn das AH darüber liegt)
- im Tooltip des Gegenstands

## Händler-Helfer

Am Händler zeigt ein kleines Fenster, was deine Pläne und die Empfehlung noch brauchen und dieser Händler verkauft. „Kaufen“ kauft genau die fehlende Menge; Händler mit vorgepackten Stapeln werden berücksichtigt. Mit mehreren Posten gibt es zusätzlich „Alles kaufen“. Gekauft wird nur auf deinen Klick.

## Tooltips an Gegenständen

Jeder Gegenstands-Tooltip zeigt bei Bedarf:

- Planbedarf und Fehlmenge
- „Nicht verkaufen“
- Bestände reichweitiger Twinks
- die Preisgrenze

Abschaltbar unter Einstellungen → „Hinweise in Gegenstands-Tooltips“.

## Hergestelltes verwerten

Neue Seite Plan → **Verwerten**: Hergestellte Gegenstände in den Taschen, die kein Plan mehr braucht, mit Vergleich von AH netto (abzüglich AH-Abzug) und Händlerpreis. Bei Rüstung und Waffen kommt „Entzaubern lassen“ dazu, wenn ein Verzauberer auf dem Account ist und das AH wenig bringt. Ein Klick am AH zeigt die aktuellen Angebote.

## Budget-Modus

Plan → Details → **Budget**: Regler bis 500 Gold. CraftPilot zeigt, bis zu welchem Skill der günstigste Weg damit reicht, und die drei teuersten Abschnitte je Punkt.

Validierung: vollständige Tests unter Lua 5.1 und 5.4, darunter `tests/features_026.lua` für alle Punkte. Im Spielclient nicht getestet; besonders Händler-Kauf (Stapelgrößen) und Tooltips bitte prüfen.
