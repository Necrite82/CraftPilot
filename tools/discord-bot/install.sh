#!/usr/bin/env bash
# Installs or updates the Discord bug bot (CraftPilot, GearPilot) on Debian/Ubuntu (e.g. a Proxmox LXC).
# Run as root from this folder:  bash install.sh
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST=/opt/craftpilot-bot

apt-get update -qq
apt-get install -y -qq python3 python3-venv >/dev/null

id craftpilot-bot >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin craftpilot-bot

mkdir -p "$DEST"
install -m 644 "$SRC/bot.py" "$SRC/requirements.txt" "$DEST/"
[ -d "$DEST/venv" ] || python3 -m venv "$DEST/venv"
"$DEST/venv/bin/pip" install -q --upgrade pip
"$DEST/venv/bin/pip" install -q -r "$DEST/requirements.txt"

if [ ! -f /etc/craftpilot-bot.env ]; then
  install -m 600 -o root -g root "$SRC/.env.example" /etc/craftpilot-bot.env
  echo ">> /etc/craftpilot-bot.env angelegt – bitte jetzt ausfüllen: nano /etc/craftpilot-bot.env"
fi

install -m 644 "$SRC/craftpilot-bot.service" /etc/systemd/system/craftpilot-bot.service
systemctl daemon-reload
systemctl enable craftpilot-bot >/dev/null

if grep -q '^DISCORD_TOKEN=.\+' /etc/craftpilot-bot.env; then
  systemctl restart craftpilot-bot
  echo ">> Bot (neu) gestartet. Log: journalctl -u craftpilot-bot -f"
else
  echo ">> Danach starten mit: systemctl start craftpilot-bot"
fi
