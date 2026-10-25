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
[[ -f "$here/icon/AppIcon.icns" ]] && cp "$here/icon/AppIcon.icns" "$app/Contents/Resources/"
# German and English system menus
mkdir -p "$app/Contents/Resources/de.lproj" "$app/Contents/Resources/en.lproj"

# Bundle SANE (scanimage + fujitsu backend) so the app runs without Homebrew
"$here/scripts/bundle-sane.sh" "$app/Contents/Resources/sane"

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
  <key>CFBundleShortVersionString</key><string>2.0</string>
  <key>CFBundleVersion</key><string>4</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleLocalizations</key><array><string>de</string><string>en</string></array>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$app"
echo "Built: $app"

if [[ "${1:-}" == "zip" ]]; then
  version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app/Contents/Info.plist")"
  zip="$here/build/iX500-Scan-$version.zip"
  rm -f "$zip"
  ditto -c -k --keepParent "$app" "$zip"
  echo "Zipped: $zip"
fi

if [[ "${1:-}" == "install" ]]; then
  rm -rf "/Applications/iX500 Scan.app"
  cp -R "$app" /Applications/
  echo "Installed: /Applications/iX500 Scan.app"
fi
