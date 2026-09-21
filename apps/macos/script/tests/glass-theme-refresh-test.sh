#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
GLASS="$ROOT_DIR/Sources/MarkLeaf/Views/GlassSurfaceView.swift"
SESSION="$ROOT_DIR/Sources/MarkLeaf/Services/EditorSession.swift"

grep -Fq 'glassEffectView?.appearance = themedAppearance' "$GLASS" \
  || { echo "FAIL: Liquid Glass backing must receive the themed appearance directly" >&2; exit 1; }
grep -Fq 'DispatchQueue.main.async { GlassSurfaceRegistry.shared.refreshAll(forceDark: dark) }' "$SESSION" \
  || { echo "FAIL: editor theme changes must pass the explicit theme darkness to Liquid Glass" >&2; exit 1; }

echo PASS
