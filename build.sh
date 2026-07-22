#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

T0=$(date +%s)

PROJECT_DIR="$(pwd)"
PROJECT="$PROJECT_DIR/SysExplorer/SysExplorer.xcodeproj"
ENTITLEMENTS="$PROJECT_DIR/SysExplorer/SysExplorer.entitlements"
DERIVED_DATA="$PROJECT_DIR/.build/DerivedData"
APP_NAME="SysExplorer"

echo "==> building $APP_NAME"

LOG=$(mktemp)
trap 'rm -f "$LOG"' EXIT

if ! xcodebuild -project "$PROJECT" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath "$DERIVED_DATA" \
  build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  2>&1 | tee "$LOG" | grep -E "error:|warning:|BUILD "; then
    echo ""
    echo "==> BUILD FAILED — full log:"
    cat "$LOG"
    exit 1
fi

APP="$DERIVED_DATA/Build/Products/Release-iphoneos/$APP_NAME.app"
if [ ! -d "$APP" ]; then
    echo "ERROR: app bundle not found at $APP"
    exit 1
fi

echo ""
echo "==> signing with ldid"
ldid -S"$ENTITLEMENTS" "$APP/$APP_NAME"

echo ""
echo "==> packaging tipa"

rm -f "packages/$APP_NAME.tipa"
mkdir -p packages

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"; rm -f "$LOG"' EXIT

mkdir -p "$WORK/Payload"
cp -a "$APP" "$WORK/Payload/"
(cd "$WORK" && zip -rq "$APP_NAME.tipa" Payload -x "*.DS_Store")
mv "$WORK/$APP_NAME.tipa" packages/

T1=$(date +%s)
DT=$((T1 - T0))

echo "==> done in ${DT}s"
ls -lh "packages/$APP_NAME.tipa"
