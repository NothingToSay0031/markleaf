#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
HELPER="$ROOT_DIR/Sources/MarkLeaf/Views/CompactOverlayScrollView.swift"
test -f "$HELPER" || { echo "FAIL: CompactOverlayScrollView.swift is required" >&2; exit 1; }
grep -Fq 'static func configure(_ scrollView: NSScrollView)' "$HELPER" || {
  echo "FAIL: shared overlay scroll configuration is required" >&2
  exit 1
}

for file in \
  ShortcutWindowController.swift \
  OptionalFontsWindowController.swift \
  RecoveryWindowController.swift \
  ExportWindowController.swift \
  ThemeSettingsWindowController.swift; do
  path="$ROOT_DIR/Sources/MarkLeaf/Views/$file"
  grep -Fq 'CompactOverlayScrollView.configure(' "$path" || {
    echo "FAIL: $file must use the shared overlay scroll configuration" >&2
    exit 1
  }
done

SIDEBAR="$ROOT_DIR/Sources/MarkLeaf/Views/SidebarView.swift"
CSS="$ROOT_DIR/../../packages/editor-core/src/styles.css"
grep -Fq 'CompactOverlayScrollView.configure(' "$SIDEBAR" || {
  echo "FAIL: SidebarView.swift must use the shared overlay scroll configuration" >&2
  exit 1
}
if grep -q 'SidebarOverlayScroller' "$SIDEBAR"; then
  echo "FAIL: sidebar scrolling must not use a duplicate scroller implementation" >&2
  exit 1
fi
grep -Fq 'width: 6px;' "$CSS" || {
  echo "FAIL: editor overlay scrollbars must match the shared 6px width" >&2
  exit 1
}
grep -Fq 'static let overlayWidth: CGFloat = 6' "$HELPER" || {
  echo "FAIL: AppKit overlay scrollbars must match the shared 6px width" >&2
  exit 1
}

echo PASS
