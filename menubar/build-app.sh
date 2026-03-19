#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

OUTPUT_PATH="${1:-$SCRIPT_DIR/build/TamaclaudechiMenuBar.app}"
mkdir -p "$(dirname "$OUTPUT_PATH")"

swift build -c release >/dev/null

BIN="$SCRIPT_DIR/.build/release/TamaclaudechiMenuBar"
if [ ! -f "$BIN" ]; then
  echo "❌ Could not find compiled binary at $BIN" >&2
  exit 1
fi

rm -rf "$OUTPUT_PATH"
mkdir -p "$OUTPUT_PATH/Contents/MacOS" "$OUTPUT_PATH/Contents/Resources"

cat > "$OUTPUT_PATH/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>TamaclaudechiMenuBar</string>
  <key>CFBundleIdentifier</key>
  <string>com.base44.tamaclaudechi-menubar</string>
  <key>CFBundleName</key>
  <string>Tamaclaudechi Menu Bar</string>
  <key>CFBundleDisplayName</key>
  <string>Tamaclaudechi Menu Bar</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

cp "$SCRIPT_DIR/Resources"/MascotTemplate*.png "$OUTPUT_PATH/Contents/Resources/"
cp "$SCRIPT_DIR/../assets/claude.png" "$OUTPUT_PATH/Contents/Resources/MascotColor.png"

cp "$BIN" "$OUTPUT_PATH/Contents/MacOS/TamaclaudechiMenuBar"
chmod +x "$OUTPUT_PATH/Contents/MacOS/TamaclaudechiMenuBar"

echo "✅ Built Tamaclaudechi Menu Bar at $OUTPUT_PATH"
