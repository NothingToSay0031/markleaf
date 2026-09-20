#!/usr/bin/env bash
set -euo pipefail

MACOS_DIR="${1:?macOS directory is required}"
APP_BUNDLE="${2:?app bundle is required}"
CONFIG="${MARKLEAF_QUICKLOOK_CONFIG:-debug}"

MACOS_DIR="$(cd "$MACOS_DIR" && pwd)"
SWIFT_BUILD_FLAGS=()
if [[ "${MARKLEAF_DISABLE_SWIFT_SANDBOX:-0}" == "1" ]]; then
  SWIFT_BUILD_FLAGS+=(--disable-sandbox)
fi

swift build ${SWIFT_BUILD_FLAGS[@]+"${SWIFT_BUILD_FLAGS[@]}"} \
  --package-path "$MACOS_DIR" -c "$CONFIG" --product MarkLeafQuickLook
PRODUCT_DIR="$(swift build ${SWIFT_BUILD_FLAGS[@]+"${SWIFT_BUILD_FLAGS[@]}"} --package-path "$MACOS_DIR" -c "$CONFIG" --show-bin-path)"
EXECUTABLE="$PRODUCT_DIR/MarkLeafQuickLook"
[[ -x "$EXECUTABLE" ]] || { echo "Quick Look executable is missing: $EXECUTABLE" >&2; exit 1; }

CLEAN_STAGE="$(mktemp -d "${TMPDIR:-/tmp}/markleaf-quicklook-stage.XXXXXX")"
trap 'rm -rf "$CLEAN_STAGE"' EXIT
APP_EX="$CLEAN_STAGE/MarkLeafQuickLook.appex"
mkdir -p "$APP_EX/Contents/MacOS" "$APP_EX/Contents/Resources"
cp -X "$EXECUTABLE" "$APP_EX/Contents/MacOS/MarkLeafQuickLook"
chmod +x "$APP_EX/Contents/MacOS/MarkLeafQuickLook"
bash "$MACOS_DIR/script/quicklook/write-extension-info-plist.sh" "$APP_EX/Contents/Info.plist"
xattr -cr "$APP_EX"
codesign --force --options runtime --entitlements "$MACOS_DIR/Sources/QuickLook/entitlements.plist" --sign - "$APP_EX" >/dev/null
codesign --verify --strict "$APP_EX"

DEST="$APP_BUNDLE/Contents/PlugIns/MarkLeafQuickLook.appex"
rm -rf "$DEST"
mkdir -p "$(dirname "$DEST")"
ditto "$APP_EX" "$DEST"
codesign --verify --strict "$DEST"
