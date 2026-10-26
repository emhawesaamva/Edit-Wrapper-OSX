#!/bin/bash
# Builds "Edit OSX.app" into ./build
set -euo pipefail
cd "$(dirname "$0")"
swift build -c release
APP="build/Edit OSX.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$(swift build -c release --show-bin-path)/EditWrapper" "$APP/Contents/MacOS/EditWrapper"
cp Resources/Info.plist "$APP/Contents/Info.plist"
xattr -cr "$APP"
codesign --force --sign - "$APP"
echo "Built $APP"
