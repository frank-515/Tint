#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

if [ ! -d FolderCustomizer.xcodeproj ]; then
  echo "==> Generating Xcode project (xcodegen)"
  xcodegen generate
fi

echo "==> Building (Release)"
xcodebuild -project FolderCustomizer.xcodeproj -scheme FolderCustomizer \
  -configuration Release -derivedDataPath .build/DerivedData \
  CODE_SIGNING_ALLOWED=NO build

APP=".build/DerivedData/Build/Products/Release/Tint.app"

# The build output may sit under a synced folder (e.g. iCloud Desktop), whose
# file provider re-tags files with FinderInfo asynchronously. Sign a copy in a
# neutral location, then move it back.
SIGN_DIR=$(mktemp -d /tmp/tint-sign.XXXXXX)
cp -R "$APP" "$SIGN_DIR/Tint.app"

strip_detritus() {
  find "$1" -print0 | while IFS= read -r -d '' f; do
    xattr -d com.apple.FinderInfo "$f" 2>/dev/null || true
    xattr -d com.apple.fileprovider.fpfs#P "$f" 2>/dev/null || true
  done
}

strip_detritus "$SIGN_DIR/Tint.app"
codesign --force --deep --sign - "$SIGN_DIR/Tint.app"
codesign --verify "$SIGN_DIR/Tint.app"

rm -rf "$APP"
mv "$SIGN_DIR/Tint.app" "$APP"
rm -rf "$SIGN_DIR"
echo "==> Built: $APP"

if [ "${1:-}" = "dmg" ]; then
  mkdir -p dist
  rm -f dist/Tint.dmg
  hdiutil create -volname Tint -srcfolder "$APP" \
    -ov -format UDZO dist/Tint.dmg
  echo "==> DMG: dist/Tint.dmg"
fi
