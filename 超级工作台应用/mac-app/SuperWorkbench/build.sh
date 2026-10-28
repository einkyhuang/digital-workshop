#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
MAC_APP_DIR="$(cd "$ROOT/.." && pwd)"
cd "$ROOT"

echo "==> swift build"
swift build -c release --product SuperWorkbench

BIN="$ROOT/.build/release/SuperWorkbench"
APP_OUT="$MAC_APP_DIR/超级工作台.app"
rm -rf "$APP_OUT"
mkdir -p "$APP_OUT/Contents/MacOS" "$APP_OUT/Contents/Resources"

cp "$BIN" "$APP_OUT/Contents/MacOS/超级工作台"
chmod +x "$APP_OUT/Contents/MacOS/超级工作台"
if [[ -f "$ROOT/Assets/AppIcon.icns" ]]; then
  cp "$ROOT/Assets/AppIcon.icns" "$APP_OUT/Contents/Resources/AppIcon.icns"
fi

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
