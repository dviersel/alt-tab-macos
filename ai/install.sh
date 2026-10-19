#!/bin/bash
# Builds the Release app and installs it into /Applications, replacing any running copy.
# Release.xcconfig pins the upstream author's Developer ID, which isn't in our keychain, so we sign with
# SIGN_IDENTITY instead. Default: "Local Self-Signed" (see ai/create-signing-cert.sh) when present, else "-" (ad-hoc,
# which changes every build and orphans the Accessibility / Screen Recording grants).
set -euo pipefail

cd "$(dirname "$0")/.."
default_identity="-"
security find-identity -v -p codesigning | grep -q '"Local Self-Signed"' && default_identity="Local Self-Signed"
identity="${SIGN_IDENTITY:-$default_identity}"
app="DerivedData/Build/Products/Release/AltTab.app"
dest="/Applications/AltTab.app"
# CI injects the version via local.xcconfig; without it CFBundleVersion is empty and App.version traps at launch.
version="$(grep -m1 -oE '[0-9]+\.[0-9]+\.[0-9]+' changelog.md)"

xcodebuild \
  -project alt-tab-macos.xcodeproj \
  -scheme Release \
  -configuration Release \
  -derivedDataPath DerivedData \
  CURRENT_PROJECT_VERSION="$version" \
  CODE_SIGN_IDENTITY="-" \
  OTHER_CODE_SIGN_FLAGS="--timestamp=none" \
  | tail -n 20

# Xcode applies the identity to the vendored resource bundles too, which then demand a development team, so
# we build ad-hoc and sign the finished bundle ourselves.
[ "$identity" = "-" ] || codesign --force --deep --options runtime --timestamp=none --entitlements alt_tab_macos.entitlements --sign "$identity" "$app"

pkill -x AltTab || true
rm -rf "$dest"
ditto "$app" "$dest"
open "$dest"
echo "Installed $dest (signed with '$identity')"
