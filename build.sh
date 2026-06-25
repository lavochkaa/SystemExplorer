#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$PROJECT_DIR/SysExplorer/SysExplorer.xcodeproj"
ENTITLEMENTS="$PROJECT_DIR/SysExplorer/SysExplorer.entitlements"
ARCHIVE="/tmp/SysExplorer.xcarchive"
BUILD_DIR="/tmp/tipa_build"
OUTPUT="$HOME/Desktop/SysExplorer.tipa"

echo "▶ Building..."
xcodebuild -project "$PROJECT" \
  -scheme SysExplorer \
  -configuration Release \
  -archivePath "$ARCHIVE" \
  archive \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  | grep -E "error:|warning:|ARCHIVE"

APP=$(find "$ARCHIVE/Products" -name "*.app" | head -1)

echo "▶ Signing with ldid..."
ldid -S"$ENTITLEMENTS" "$APP/SysExplorer"

echo "▶ Packaging .tipa..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/Payload"
cp -r "$APP" "$BUILD_DIR/Payload/"
cd "$BUILD_DIR"
zip -r SysExplorer.tipa Payload/ -x "*.DS_Store" > /dev/null

cp "$BUILD_DIR/SysExplorer.tipa" "$OUTPUT"
echo "✅ Done: $OUTPUT"
