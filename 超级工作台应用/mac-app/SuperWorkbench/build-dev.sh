#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
MAC_APP_DIR="$(cd "$ROOT/.." && pwd)"
cd "$ROOT"

echo "==> swift build (dev)"
swift build -c release --product SuperWorkbench

BIN="$ROOT/.build/release/SuperWorkbench"
# Prefer /tmp for fast iterate; also copy under mac-app for persistence
APP_OUT="${SW_DEV_APP_OUT:-/tmp/超级工作台-dev.app}"
APP_OUT2="$MAC_APP_DIR/超级工作台-dev.app"
rm -rf "$APP_OUT" "$APP_OUT2"
mkdir -p "$APP_OUT/Contents/MacOS" "$APP_OUT/Contents/Resources"

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
echo "Built DEV (do not replace Desktop): $APP_OUT"
echo "Also: $APP_OUT2"
