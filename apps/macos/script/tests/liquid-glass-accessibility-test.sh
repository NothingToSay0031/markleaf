#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

require() {
  local file="$1" text="$2" message="$3"
  grep -Fq "$text" "$file" || { echo "FAIL: $message" >&2; exit 1; }
}

require "$ROOT_DIR/Sources/MarkLeaf/Views/GlassSurfaceView.swift" \
  'NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency' \
  'glass must fall back when transparency is reduced'
require "$ROOT_DIR/Sources/MarkLeaf/Views/EditorTabStripMaterial.swift" \
  'accessibilityDisplayShouldReduceTransparency' \
  'tab selection material must own its reduced-transparency fallback'
require "$ROOT_DIR/Sources/MarkLeaf/Views/WindowTitleTransitionView.swift" \
  'NSWorkspace.shared.accessibilityDisplayShouldReduceMotion' \
  'title state changes must respect Reduce Motion'
require "$ROOT_DIR/Sources/MarkLeaf/Views/FloatingWindowChrome.swift" \
  'window.isOpaque = true' \
  'floating windows must keep an opaque readable fallback'

echo PASS
