#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
EDITOR="$ROOT_DIR/Sources/MarkLeaf/Views/EditorWindowController.swift"

grep -Fq 'window.styleMask.insert(.fullSizeContentView)' "$EDITOR" \
  || { echo "FAIL: editor window must use full-size content for a full-height sidebar" >&2; exit 1; }
grep -Fq 'window.titlebarAppearsTransparent = true' "$EDITOR" \
  || { echo "FAIL: editor titlebar must stay transparent so the sidebar surface spans the left edge" >&2; exit 1; }
grep -Fq 'sidebarContainer.setContent(sidebarView)' "$EDITOR" \
  || { echo "FAIL: sidebar must keep its native glass-backed content surface" >&2; exit 1; }
grep -Fq 'splitView.addArrangedSubview(sidebarContainer)' "$EDITOR" \
  || { echo "FAIL: sidebar must remain the leading split-view pane" >&2; exit 1; }

echo PASS
