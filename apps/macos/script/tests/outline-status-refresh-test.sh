#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PROTOCOL="$ROOT_DIR/../../packages/editor-web/src/protocol.ts"
WEB="$ROOT_DIR/../../packages/editor-web/src/main.ts"
SESSION="$ROOT_DIR/Sources/MarkLeaf/Services/EditorSession.swift"
WINDOW="$ROOT_DIR/Sources/MarkLeaf/Views/EditorWindowController.swift"

grep -Fq "'refreshOutline'" "$PROTOCOL" || {
  echo 'FAIL: refreshOutline must be part of the host protocol' >&2
  exit 1
}
grep -Fq "case 'refreshOutline':" "$WEB" || {
  echo 'FAIL: editor web must handle refreshOutline' >&2
  exit 1
}
grep -Fq "|| message.type === 'refreshOutline'" "$PROTOCOL" || {
  echo 'FAIL: runtime host-message validation must allow refreshOutline' >&2
  exit 1
}
grep -Fq 'if (!documentLoaded) break' "$WEB" || {
  echo 'FAIL: refreshOutline must be ignored before a document loads' >&2
  exit 1
}
grep -Fq 'func requestOutlineRefresh()' "$SESSION" || {
  echo 'FAIL: editor session must expose requestOutlineRefresh' >&2
  exit 1
}
grep -Fq 'send("refreshOutline")' "$SESSION" || {
  echo 'FAIL: editor session must request a fresh outline' >&2
  exit 1
}
grep -Fq 'requestOutlineRefresh()' "$WINDOW" || {
  echo 'FAIL: sidebar visibility changes must refresh outline status' >&2
  exit 1
}

echo PASS
