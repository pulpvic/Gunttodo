#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Gunttodo"
VERSION="${1:-0.1.0}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
RELEASE_DIR="$ROOT_DIR/release"
STAGE_DIR="$DIST_DIR/dmg-stage"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
ZIP_PATH="$RELEASE_DIR/$APP_NAME-macOS.zip"
DMG_PATH="$RELEASE_DIR/$APP_NAME-macOS.dmg"

cd "$ROOT_DIR"

GUNTTODO_VERSION="$VERSION" "$ROOT_DIR/script/build_and_run.sh" --build

codesign --force --deep --sign - "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"

rm -rf "$RELEASE_DIR" "$STAGE_DIR"
mkdir -p "$RELEASE_DIR" "$STAGE_DIR"

ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"

cp -R "$APP_BUNDLE" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

rm -rf "$STAGE_DIR"

echo "Created:"
echo "  $APP_BUNDLE"
echo "  $ZIP_PATH"
echo "  $DMG_PATH"
echo
echo "Signing: ad-hoc. This is runnable locally, but not notarized for Gatekeeper."
