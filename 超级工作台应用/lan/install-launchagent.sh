#!/bin/bash
# Install LaunchAgent com.ky.superworkbench.lan — does NOT touch Desktop 超级工作台.app
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LABEL=com.ky.superworkbench.lan
PLIST_SRC="$ROOT/超级工作台应用/lan/com.ky.superworkbench.lan.plist"
DEST="$HOME/Library/LaunchAgents/${LABEL}.plist"
LAN_DIR="$ROOT/超级工作台应用/data/private/lan"
mkdir -p "$LAN_DIR" "$HOME/Library/LaunchAgents"

# Ensure node exists
if ! command -v node >/dev/null 2>&1 && [[ ! -x /usr/bin/node ]]; then
  echo "REFUSE: need /usr/bin/node or node in PATH"; exit 1
fi
NODE="$(command -v node || echo /usr/bin/node)"

TMP="$(mktemp)"
sed "s|REPO_PLACEHOLDER|$ROOT|g" "$PLIST_SRC" > "$TMP"
# If node is not /usr/bin/node, rewrite ProgramArguments first string
if [[ "$NODE" != "/usr/bin/node" ]]; then
  /usr/bin/python3 - "$TMP" "$NODE" <<'PY'
import sys
from pathlib import Path
p = Path(sys.argv[1]); node = sys.argv[2]
t = p.read_text()
t = t.replace("<string>/usr/bin/node</string>", f"<string>{node}</string>", 1)
p.write_text(t)
PY
fi

# unload if present
launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true
launchctl unload "$DEST" 2>/dev/null || true

cp "$TMP" "$DEST"
rm -f "$TMP"
launchctl bootstrap "gui/$(id -u)" "$DEST" 2>/dev/null || launchctl load "$DEST"
launchctl enable "gui/$(id -u)/${LABEL}" 2>/dev/null || true
launchctl kickstart -k "gui/$(id -u)/${LABEL}" 2>/dev/null || launchctl start "$LABEL" || true

echo "Installed LaunchAgent: $DEST"
echo "Label: $LABEL"
echo "Passcode file (chmod 600): $LAN_DIR/passcode"
echo "Do NOT print passcode. curl http://127.0.0.1:18787/login"
