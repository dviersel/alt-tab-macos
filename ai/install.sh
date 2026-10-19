#!/bin/bash
# Builds the Release app and installs it into /Applications, replacing any running copy.
# Release.xcconfig pins the upstream author's Developer ID, which isn't in our keychain, so we sign with
# SIGN_IDENTITY instead (default "-" = ad-hoc). Override with e.g. SIGN_IDENTITY="Local Self-Signed".
set -euo pipefail

cd "$(dirname "$0")/.."
identity="${SIGN_IDENTITY:--}"
app="DerivedData/Build/Products/Release/AltTab.app"
dest="/Applications/AltTab.app"

xcodebuild \
  -project alt-tab-macos.xcodeproj \
  -scheme Release \
  -configuration Release \
  -derivedDataPath DerivedData \
  CODE_SIGN_IDENTITY="$identity" \
  OTHER_CODE_SIGN_FLAGS="--timestamp=none" \
  | tail -n 20

pkill -x AltTab || true
rm -rf "$dest"
ditto "$app" "$dest"
open "$dest"
echo "Installed $dest (signed with '$identity')"
