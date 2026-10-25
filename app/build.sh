#!/usr/bin/env bash
# Build "iX500 Scan.app" into ./build. With "install", also copy it to /Applications.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
app="$here/build/iX500 Scan.app"

swift build -c release --package-path "$here"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$here/.build/release/IX500Scan" "$app/Contents/MacOS/IX500Scan"
cp "$here/../scan-ix500" "$app/Contents/Resources/scan-ix500"
chmod +x "$app/Contents/Resources/scan-ix500"

cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>iX500 Scan</string>
  <key>CFBundleDisplayName</key><string>iX500 Scan</string>
  <key>CFBundleIdentifier</key><string>io.github.cptcool.ix500scan</string>
  <key>CFBundleExecutable</key><string>IX500Scan</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.1</string>
  <key>CFBundleVersion</key><string>2</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$app"
echo "Built: $app"

if [[ "${1:-}" == "install" ]]; then
  rm -rf "/Applications/iX500 Scan.app"
  cp -R "$app" /Applications/
  echo "Installed: /Applications/iX500 Scan.app"
fi
