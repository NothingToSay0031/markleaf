#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/MarkLeaf.app"
APP_EX="$APP_BUNDLE/Contents/PlugIns/MarkLeafQuickLook.appex"

bash "$ROOT_DIR/script/build_and_run.sh" --build-only

EXECUTABLE="$APP_EX/Contents/MacOS/MarkLeafQuickLook"
INFO_PLIST="$APP_EX/Contents/Info.plist"
[[ -x "$EXECUTABLE" ]] || { echo "FAIL: Quick Look executable is missing" >&2; exit 1; }
[[ "$(/usr/libexec/PlistBuddy -c 'Print :NSExtension:NSExtensionPointIdentifier' "$INFO_PLIST")" == 'com.apple.quicklook.preview' ]] || {
  echo 'FAIL: Quick Look extension point is missing' >&2
  exit 1
}

codesign --verify --deep --strict "$APP_BUNDLE"
[[ "$(codesign -dv --verbose=2 "$APP_EX" 2>&1 | grep -o 'Signature=.*' | head -1)" == 'Signature=adhoc' ]] || {
  echo 'FAIL: extension signature is not adhoc' >&2
  exit 1
}
codesign -dv --verbose=2 "$APP_EX" 2>&1 | grep -q '^Runtime Version=' || {
  echo 'FAIL: extension is not signed with runtime' >&2
  exit 1
}
[[ "$(codesign -dv --verbose=2 "$APP_BUNDLE" 2>&1 | grep -o 'Signature=.*' | head -1)" == 'Signature=adhoc' ]] || {
  echo 'FAIL: app signature is not adhoc' >&2
  exit 1
}
echo PASS
