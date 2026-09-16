#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
VIEW="$ROOT_DIR/Sources/MarkLeaf/Views/EditorWebContainerView.swift"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

body="$(awk '/^final class EditorWebView:/{found=1} found{print} /^enum EditorAutoscrollPolicy/{exit}' "$VIEW")"
[[ -n "$body" ]] || fail "EditorWebView class body was not found"

grep -Fq 'override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation' <<<"$body" \
  || fail "EditorWebView must claim native file drags before WebKit swallows them"
grep -Fq 'override func performDragOperation(_ sender: NSDraggingInfo) -> Bool' <<<"$body" \
  || fail "EditorWebView must handle native file drops"
grep -Fq 'EditorDropPolicy.classify(urls)' <<<"$body" \
  || fail "EditorWebView drops must use the shared image/document classification"
grep -Fq 'editorSession?.insertImageFile(at: url)' <<<"$body" \
  || fail "image drops must reach the active editor session"

echo PASS
