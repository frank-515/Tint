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

APP=".build/DerivedData/Build/Products/Release/FolderCustomizer.app"

# The build output may sit under a synced folder (e.g. iCloud Desktop), whose
# file provider re-tags files with FinderInfo asynchronously. Sign a copy in a
# neutral location, then move it back.
SIGN_DIR=$(mktemp -d /tmp/foldercustomizer-sign.XXXXXX)
cp -R "$APP" "$SIGN_DIR/FolderCustomizer.app"

strip_detritus() {
  find "$1" -print0 | while IFS= read -r -d '' f; do
    xattr -d com.apple.FinderInfo "$f" 2>/dev/null || true
    xattr -d com.apple.fileprovider.fpfs#P "$f" 2>/dev/null || true
  done
}

strip_detritus "$SIGN_DIR/FolderCustomizer.app"
codesign --force --deep --sign - "$SIGN_DIR/FolderCustomizer.app"
codesign --verify "$SIGN_DIR/FolderCustomizer.app"

rm -rf "$APP"
mv "$SIGN_DIR/FolderCustomizer.app" "$APP"
rm -rf "$SIGN_DIR"
echo "==> Built: $APP"

if [ "${1:-}" = "dmg" ]; then
  mkdir -p dist
  rm -f dist/FolderCustomizer.dmg
  hdiutil create -volname FolderCustomizer -srcfolder "$APP" \
    -ov -format UDZO dist/FolderCustomizer.dmg
  echo "==> DMG: dist/FolderCustomizer.dmg"
fi
