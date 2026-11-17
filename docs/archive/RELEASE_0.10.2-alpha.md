CraftPilot 0.10.2-alpha korrigiert die gemeldeten Darstellungs- und Bedienungsprobleme.

- Berufsfenster: direkter Aufruf aus dem Klickpfad vor der Oberflächenaktualisierung; kein `pcall` um die eingeschränkte Funktion. Die Kampfsperre bleibt bestehen.
- Auswahlmarkierungen: goldener Grafikstreifen und natives grünes Häkchen ersetzen die als Kästchen dargestellten Sonderzeichen.
- Logo: eigener untergeordneter Rahmen, damit EllesmereUIs Panel-Skin das Logo nicht ausblendet.
- Einstellungen: neue Schieberegler für Fensterbreite, Fensterhöhe und Minimap-Position.

Lua-Regressionsprüfungen und Installationspaket-Prüfung erfolgreich. Die Änderung am geschützten Berufsaufruf ist anhand des gemeldeten Fehlerpfads vorbereitet; das Ergebnis muss im Live-Client erneut geprüft werden.

Installation: den bestehenden CraftPilot-Ordner durch den Ordner aus `CraftPilot-0.10.2-alpha.zip` ersetzen und die Oberfläche neu laden.
