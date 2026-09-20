#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/markleaf-quicklook-metadata.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT

INFO_PLIST="$TEST_DIR/Info.plist"
bash "$ROOT_DIR/script/quicklook/write-extension-info-plist.sh" "$INFO_PLIST"

PLIST_BUDDY=/usr/libexec/PlistBuddy
expect_value() {
  local key="$1" expected="$2" actual
  actual="$("$PLIST_BUDDY" -c "Print :$key" "$INFO_PLIST")"
  [[ "$actual" == "$expected" ]] || {
    echo "FAIL: $key is $actual, expected $expected" >&2
    exit 1
  }
}

expect_value CFBundleIdentifier com.markleaf.app.QuickLook
expect_value CFBundleExecutable MarkLeafQuickLook
expect_value CFBundlePackageType XPC!
expect_value NSExtension:NSExtensionPointIdentifier com.apple.quicklook.preview
expect_value NSExtension:NSExtensionPrincipalClass PreviewViewController
expect_value NSExtension:NSExtensionAttributes:QLIsDataBasedPreview true
expect_value NSExtension:NSExtensionAttributes:QLSupportsSearchableItems false
expect_value NSExtension:NSExtensionAttributes:QLSupportedContentTypes:0 net.daringfireball.markdown
expect_value NSExtension:NSExtensionAttributes:QLSupportedContentTypes:1 public.plain-text

plutil -lint "$INFO_PLIST" >/dev/null
plutil -lint "$ROOT_DIR/Sources/QuickLook/entitlements.plist" >/dev/null
echo PASS
