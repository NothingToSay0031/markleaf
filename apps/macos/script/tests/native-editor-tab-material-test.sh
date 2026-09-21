#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
MATERIAL="$ROOT_DIR/Sources/MarkLeaf/Views/EditorTabStripMaterial.swift"
TAB_BAR="$ROOT_DIR/Sources/MarkLeaf/Views/TabBarController.swift"

test -f "$MATERIAL" || { echo "FAIL: EditorTabStripMaterial.swift is required" >&2; exit 1; }
grep -Fq 'enum EditorTabStripMaterial' "$MATERIAL" || {
  echo "FAIL: tab strip selection material must have one owner" >&2
  exit 1
}
grep -Fq 'GlassSurfaceView.systemSupportsGlass' "$MATERIAL" || {
  echo "FAIL: selection material must use the shared Liquid Glass capability check" >&2
  exit 1
}
grep -Fq 'accessibilityDisplayShouldReduceTransparency' "$MATERIAL" || {
  echo "FAIL: selection material must own the reduced-transparency fallback" >&2
  exit 1
}
grep -Fq 'static var supportsSystemSelectionMaterial' "$MATERIAL" || {
  echo "FAIL: tab selection must use the shared Liquid Glass capability check" >&2
  exit 1
}
grep -Fq 'private let glassSurface = GlassSurfaceView(style: .regular)' "$TAB_BAR" || {
  echo "FAIL: tab strip must use one shared regular glass backing" >&2
  exit 1
}
if grep -q 'selectionGlass' "$TAB_BAR"; then
  echo "FAIL: active tabs must not add a second glass layer" >&2
  exit 1
fi

echo PASS
