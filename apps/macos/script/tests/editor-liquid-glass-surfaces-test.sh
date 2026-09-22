#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
EDITOR="$ROOT_DIR/Sources/MarkLeaf/Views/EditorWindowController.swift"

grep -Fq 'private var titleBarGlassSurface: GlassSurfaceView?' "$EDITOR" \
  || { echo "FAIL: editor must retain a titlebar Liquid Glass surface" >&2; exit 1; }
grep -Fq 'let titleBarGlassSurface = GlassSurfaceView(' "$EDITOR" \
  || { echo "FAIL: titlebar must use the shared non-interactive glass surface" >&2; exit 1; }
grep -Fq 'preferredDark: session.currentThemeIsDark,' "$EDITOR" \
  || { echo "FAIL: editor glass surfaces must seed the resolved editor appearance" >&2; exit 1; }
grep -Fq 'fallbackBackgroundColor: .windowBackgroundColor' "$EDITOR" \
  || { echo "FAIL: editor glass surfaces must provide a first-frame fallback" >&2; exit 1; }
grep -Fq 'titleBarGlassSurface.bottomAnchor.constraint(equalTo: rightColumn.safeAreaLayoutGuide.topAnchor)' "$EDITOR" \
  || { echo "FAIL: titlebar glass must cover only the safe-area strip" >&2; exit 1; }
grep -Fq 'titleBarGlassSurface.topAnchor.constraint(equalTo: rightColumn.topAnchor)' "$EDITOR" \
  || { echo "FAIL: titlebar glass must extend behind the full-size titlebar" >&2; exit 1; }
grep -Fq 'sidebarContainer = GlassSurfaceView(' "$EDITOR" \
  || { echo "FAIL: sidebar must retain its sidebar glass style" >&2; exit 1; }
grep -Fq 'statusBarSurface = GlassSurfaceView(' "$EDITOR" \
  || { echo "FAIL: status bar must retain its glass surface" >&2; exit 1; }

echo PASS
