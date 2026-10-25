#!/usr/bin/env bash
# Render icon.svg into AppIcon.icns (all macOS sizes).
set -euo pipefail
cd "$(dirname "$0")"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
src="$tmp/icon.png"
swift render.swift icon.svg "$src" 1024
set="$tmp/AppIcon.iconset"
mkdir "$set"
for s in 16 32 128 256 512; do
  sips -z $s $s "$src" --out "$set/icon_${s}x${s}.png" >/dev/null
  sips -z $((s * 2)) $((s * 2)) "$src" --out "$set/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$set" -o AppIcon.icns
echo "Wrote $(pwd)/AppIcon.icns"
