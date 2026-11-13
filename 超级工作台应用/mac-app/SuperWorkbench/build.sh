#!/bin/bash
# Builds into mac-app/超级工作台.app only. Does NOT open, ditto, or replace ~/Desktop/超级工作台.app.
# NEVER auto-copy to Desktop — one-shot Desktop replace is a manual user-approved step only.
set -euo pipefail
if [[ "${1:-}" == "--desktop" ]]; then
  echo "REFUSE: --desktop disabled. Copy manually only after explicit user approval."; exit 2
fi
case "${SW_APP_OUT:-}" in
  *"/Desktop/超级工作台.app"*) echo "REFUSE: --desktop disabled. Copy manually only after explicit user approval."; exit 2 ;;
esac
ROOT="$(cd "$(dirname "$0")" && pwd)"
MAC_APP_DIR="$(cd "$ROOT/.." && pwd)"
cd "$ROOT"
DESKTOP_APP="${HOME}/Desktop/超级工作台.app"

echo "==> swift build"
swift build -c release --product SuperWorkbench

BIN="$ROOT/.build/release/SuperWorkbench"
APP_OUT="$MAC_APP_DIR/超级工作台.app"
if [[ "$APP_OUT" == "$DESKTOP_APP" ]]; then
  echo "REFUSE: output resolved to the Desktop app"; exit 2
fi
# Release arm64 is often ~3–5MB. The Nov 12 Desktop binary was ~9.9MB; that size
# difference is not proof the modules were stripped. Confirm the literals below.
python3 - "$BIN" << 'PY'
import sys
data = open(sys.argv[1], "rb").read()
missing = []
for label in ("外贸工作台", "资产管理"):
    if label.encode() not in data and label.encode("utf-16le") not in data:
        missing.append(label)
if missing:
    sys.stderr.write("REFUSE: executable is missing " + " ".join(missing) + "\n")
    sys.exit(1)
PY
BYTES=$(wc -c < "$BIN" | tr -d ' ')
if [[ "$BYTES" -lt 1000000 ]]; then
  echo "REFUSE: executable is only ${BYTES} bytes"; exit 1
fi
echo "Executable bytes: $BYTES (Desktop app is not modified)"
rm -rf "$APP_OUT"
mkdir -p "$APP_OUT/Contents/MacOS" "$APP_OUT/Contents/Resources"

cp "$BIN" "$APP_OUT/Contents/MacOS/超级工作台"
chmod +x "$APP_OUT/Contents/MacOS/超级工作台"
if [[ -f "$ROOT/Assets/AppIcon.icns" ]]; then
  cp "$ROOT/Assets/AppIcon.icns" "$APP_OUT/Contents/Resources/AppIcon.icns"
fi
BRIDGE_JS="$ROOT/Sources/SuperWorkbench/magichub-bridge.js"
if [[ -f "$BRIDGE_JS" ]]; then
  cp "$BRIDGE_JS" "$APP_OUT/Contents/Resources/magichub-bridge.js"
fi
WB_JSON="$ROOT/../../data/workbenches.json"
if [[ -f "$WB_JSON" ]]; then
  cp "$WB_JSON" "$APP_OUT/Contents/Resources/workbenches.json"
fi
cat > "$APP_OUT/Contents/Resources/BUILD_MANIFEST.txt" << MANIFEST
bundle-id: com.ky.superworkbench
executable-bytes: ${BYTES}
required-strings: 外贸工作台 资产管理
resources: AppIcon.icns magichub-bridge.js workbenches.json
magichub-runtime: 超级工作台应用/app/magichub/index.html (not inside this bundle)
desktop-copy: refused
MANIFEST

cat > "$APP_OUT/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>超级工作台</string>
  <key>CFBundleDisplayName</key><string>超级工作台</string>
  <key>CFBundleIdentifier</key><string>com.ky.superworkbench</string>
  <key>CFBundleVersion</key><string>1.0</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleExecutable</key><string>超级工作台</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

echo "==> ad-hoc codesign"
codesign --force --deep -s - "$APP_OUT"
codesign -dv "$APP_OUT" 2>&1 | head -5
echo "Built: $APP_OUT"
