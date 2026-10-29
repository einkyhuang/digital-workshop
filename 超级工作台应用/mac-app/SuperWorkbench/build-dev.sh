#!/bin/bash
# DEV-ONLY build. Never touches ~/Desktop/超级工作台.app.
# Executable + bundle id are distinct from production (com.ky.superworkbench.dev / 超级工作台-dev).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
MAC_APP_DIR="$(cd "$ROOT/.." && pwd)"
cd "$ROOT"

DESKTOP_APP="${HOME}/Desktop/超级工作台.app"
if [[ "${SW_ALLOW_DESKTOP_BUILD:-}" != "1" ]]; then
  # Refuse any accidental Desktop path
  case "${SW_DEV_APP_OUT:-}/tmp/超级工作台-dev.app" in
    *"/Desktop/超级工作台.app"*) echo "REFUSE: will not write Desktop production app"; exit 2 ;;
  esac
fi

echo "==> swift build (dev product SuperWorkbench → executable name 超级工作台-dev)"
swift build -c release --product SuperWorkbench

BIN="$ROOT/.build/release/SuperWorkbench"
APP_OUT="${SW_DEV_APP_OUT:-/tmp/超级工作台-dev.app}"
# Absolute safety: never allow Desktop
if [[ "$APP_OUT" == "$DESKTOP_APP" || "$APP_OUT" == *"Desktop/超级工作台.app"* ]]; then
  echo "REFUSE: APP_OUT resolves to Desktop production bundle"; exit 2
fi
APP_OUT2="$MAC_APP_DIR/超级工作台-dev.app"
rm -rf "$APP_OUT" "$APP_OUT2"
mkdir -p "$APP_OUT/Contents/MacOS" "$APP_OUT/Contents/Resources"

# Distinct executable basename from production「超级工作台」
cp "$BIN" "$APP_OUT/Contents/MacOS/超级工作台-dev"
chmod +x "$APP_OUT/Contents/MacOS/超级工作台-dev"
if [[ -f "$ROOT/Assets/AppIcon.icns" ]]; then
  cp "$ROOT/Assets/AppIcon.icns" "$APP_OUT/Contents/Resources/AppIcon.icns"
fi
BRIDGE_JS="$ROOT/Sources/SuperWorkbench/magichub-bridge.js"
if [[ -f "$BRIDGE_JS" ]]; then
  cp "$BRIDGE_JS" "$APP_OUT/Contents/Resources/magichub-bridge.js"
fi

cat > "$APP_OUT/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>超级工作台-dev</string>
  <key>CFBundleDisplayName</key><string>超级工作台-dev</string>
  <key>CFBundleIdentifier</key><string>com.ky.superworkbench.dev</string>
  <key>CFBundleVersion</key><string>1.0-dev</string>
  <key>CFBundleShortVersionString</key><string>1.0-dev</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleExecutable</key><string>超级工作台-dev</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

codesign --force --deep -s - "$APP_OUT" >/dev/null
ditto "$APP_OUT" "$APP_OUT2"
echo "Built DEV only (Desktop untouched): $APP_OUT"
echo "Also: $APP_OUT2"
echo "Do NOT open or replace $DESKTOP_APP from this script."
