# Discord-Bot (Bug-Brücke) für CraftPilot und GearPilot

Kleiner Bot, der bestätigte Bugs aus den Discord-Bug-Foren nach GitHub bringt – jeweils ins richtige Repo – und zurückmeldet, wenn sie behoben sind.

Welches Repo? Jedes Forum hat sein Repo (`BUG_FORUMS`, z. B. `#craftpilot-bugs` → CraftPilot, `#gearpilot-bugs` → GearPilot).
Zusätzlich kann ein Addon-Tag am Post (`REPO_TAGS`, z. B. Tag „GearPilot“) das Repo bestimmen – damit landet auch ein GearPilot-Bug, der im CraftPilot-Forum gepostet wurde, im richtigen Repo, sobald ein Moderator den Tag setzt.
Ein gemeinsames Forum ohne festes Repo geht auch (`BUG_FORUMS=ID=`): Fehlt dort der Addon-Tag, fragt der Bot im Thread danach und übernimmt den Post, sobald der Tag gesetzt ist.
Er ist **nicht** Teil des Addons: `tools/build_release.py` packt nur die Dateien aus seiner Allowlist ins Release.

## Ablauf

1. Jemand postet einen Fehler im Bug-Forum seines Addons.
2. Ein Moderator prüft ihn und setzt den Tag **„Bestätigt“**.
3. Der Bot legt im passenden Repo ein GitHub-Issue mit Label `bug` an (Text, Anhänge, Link zum Discord-Post) und antwortet im Thread mit dem Issue-Link.
4. Wird das Issue geschlossen – z. B. per Commit `Fixes #12` –, setzt der Bot innerhalb von ~5 Minuten den Tag **„Behoben / Fixed“** und schreibt einen Hinweis in den Thread.
   Wird es als „not planned“ geschlossen, schreibt er nur einen Hinweis und lässt die Tags in Ruhe.

GitHub wird regelmäßig abgefragt: Der Bot braucht **keinen offenen Port** und keine Portfreigabe.
Ins Issue kommt kein Discord-Name, nur der Text des Posts und der Link.

## 1. Discord-Bot anlegen

1. <https://discord.com/developers/applications> → **New Application** → Name z. B. „Pilot Bot“ (ein Bot für beide Addons).
2. Links **Bot**:
   - **Reset Token** → Token kopieren und sicher aufbewahren (wird nur einmal angezeigt).
   - Unter *Privileged Gateway Intents* **Message Content Intent** einschalten → speichern.
   - *Public Bot* ausschalten (nur du sollst ihn einladen können).
3. Links **OAuth2 → URL Generator**:
   - Scopes: `bot`
   - Bot Permissions: **View Channels**, **Send Messages in Threads**, **Read Message History**, **Manage Threads**
     (Manage Threads braucht er, um Tags an fremden Posts zu ändern.)
   - Unten erzeugte URL öffnen → den Server wählen → Autorisieren.
4. Forum-IDs holen: Discord → Einstellungen → **Erweitert → Entwicklermodus** an.
   Dann Rechtsklick auf jedes Bug-Forum → **Kanal-ID kopieren**.
5. In jedem Bug-Forum die Tags **„Bestätigt“** und **„Behoben / Fixed“** anlegen (genau so geschrieben), für Addon-Tags zusätzlich **„CraftPilot“** und **„GearPilot“**.

## 2. GitHub-Token anlegen

GitHub → Settings → Developer settings → **Personal access tokens → Fine-grained tokens → Generate new token**

- Repository access: **Only select repositories** → `CraftPilot` und `GearPilot`
- Repository permissions: **Issues → Read and write** (sonst nichts)
- Ablaufdatum notieren und rechtzeitig erneuern – danach kann der Bot keine Issues mehr anlegen.

## 3. LXC auf Proxmox

Im Proxmox-Webinterface **Create CT**:

| Einstellung | Wert |
|---|---|
| Template | Debian 12 oder 13 (Standard-Template) |
| Unprivileged | ja |
| CPU / RAM / Disk | 1 Kern, 512 MB, 4 GB |
| Netzwerk | DHCP (nur ausgehend nötig) |

Container starten, **Console** öffnen, als root:

```bash
apt-get update && apt-get install -y git
git clone https://github.com/Necrite82/CraftPilot.git /root/CraftPilot
cd /root/CraftPilot/tools/discord-bot
bash install.sh
nano /etc/craftpilot-bot.env      # DISCORD_TOKEN, BUG_FORUMS, REPO_TAGS, GITHUB_TOKEN eintragen
systemctl start craftpilot-bot
journalctl -u craftpilot-bot -f   # Log ansehen, Strg+C beendet die Anzeige
```

Im Log sollte je Forum eine Zeile stehen, z. B. `Bereit als Pilot Bot#… – beobachte #gearpilot-bugs (Necrite82/GearPilot)`.
Steht dort `Tag … fehlt im Forum`, stimmt `CONFIRMED_TAG` bzw. `FIXED_TAG` nicht exakt mit dem Tag-Namen in Discord überein.

## 4. Testen

1. In jedem Bug-Forum einen Testpost anlegen (Tag DE oder EN).
2. Tag **„Bestätigt“** hinzufügen → nach wenigen Sekunden antwortet der Bot mit dem Issue-Link – prüfen, dass das Issue im richtigen Repo liegt.
3. Das Issue auf GitHub schließen → spätestens nach 5 Minuten wechselt der Tag auf **„Behoben / Fixed“**.
4. Testpost und Test-Issue danach löschen.

## Von einem Forum auf beide Addons umstellen

Die alte `.env` (`BUG_FORUM_ID` + `GITHUB_REPO`) läuft unverändert weiter. Für GearPilot:

1. GitHub-Token um das Repo **GearPilot** erweitern (Token bearbeiten → Repository access) oder neu erzeugen.
2. Auf dem LXC den Code aktualisieren (siehe unten).
3. In `/etc/craftpilot-bot.env` die Zeilen `BUG_FORUM_ID`/`GITHUB_REPO` durch `BUG_FORUMS=…` ersetzen und `REPO_TAGS=…` ergänzen, dann `systemctl restart craftpilot-bot`.

Bisherige Zuordnungen in `state.json` bleiben gültig (sie gehören zum ersten Repo in `BUG_FORUMS`, also CraftPilot zuerst eintragen).

## Aktualisieren

```bash
cd /root/CraftPilot && git pull
bash tools/discord-bot/install.sh   # übernimmt neuen Code, startet neu, .env bleibt
```

## Gut zu wissen

- Die Zuordnung Post ↔ Issue liegt in `/var/lib/craftpilot-bot/state.json`. Nicht löschen, sonst gehen die Zuordnungen verloren.
- War der Bot offline, holt er beim Start „Bestätigt“-Tags an **aktiven** Posts nach. Archivierte Posts, die in der Zeit bestätigt wurden, einmal kurz den Tag entfernen und neu setzen.
- Tokens stehen nur in `/etc/craftpilot-bot.env` (Rechte 600, root). Diese Datei nie ins Repo oder in Discord kopieren. Bei Verdacht Token im Developer Portal bzw. auf GitHub neu erzeugen.
- Tests (offline): `python3 -m unittest test_bot.py` im Ordner `tools/discord-bot` (mit installiertem discord.py).
