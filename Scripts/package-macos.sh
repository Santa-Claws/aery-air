#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
output_dir="$root_dir/dist"
stage_dir="$output_dir/stage"
app_dir="$stage_dir/Aery Air.app"

rm -rf "$output_dir"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"

binary_dir="$(cd "$root_dir" && swift build -c release --show-bin-path)"
cp "$binary_dir/AeryAir" "$app_dir/Contents/MacOS/AeryAir"
cp "$root_dir/Packaging/Info.plist" "$app_dir/Contents/Info.plist"

# Ad-hoc signing makes the bundle structurally valid without an Apple Developer certificate.
codesign --force --deep --sign - "$app_dir"
hdiutil create -volname "Aery Air" -srcfolder "$app_dir" -ov -format UDZO "$output_dir/AeryAir-macOS.dmg"
