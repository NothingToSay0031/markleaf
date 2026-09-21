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
grep -Fq 'static func selectionBackgroundColor(isActive: Bool) -> CGColor' "$MATERIAL" || {
  echo "FAIL: tab cells must ask the material owner for selection color" >&2
  exit 1
}
grep -Fq 'EditorTabStripMaterial.selectionBackgroundColor(isActive:' "$TAB_BAR" || {
  echo "FAIL: tab cells must not own selection colors directly" >&2
  exit 1
}
if grep -q 'NSColor.controlBackgroundColor.cgColor' "$TAB_BAR"; then
  echo "FAIL: tab cells must not freeze selection colors locally" >&2
  exit 1
fi
if grep -q 'NSGlassEffectView' "$TAB_BAR"; then
  echo "FAIL: individual tab cells must not add their own glass layers" >&2
  exit 1
fi

echo PASS
