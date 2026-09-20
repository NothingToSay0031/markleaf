#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MENU="$ROOT_DIR/Sources/MarkLeaf/Support/NativeMenuBuilder.swift"
FRONTEND="$ROOT_DIR/../../packages/editor-web/src/main.ts"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

view_menu="$(sed -n '/private func viewMenu()/,/^    private func helpMenu()/p' "$MENU")"
minimal_to_zoom="$(sed -n '/L10n.t("最简模式")/,/设置缩放/p' <<<"$view_menu")"

grep -Fq 'L10n.t("只读模式")' <<<"$minimal_to_zoom" \
    || fail "the read-only toggle must sit between Minimal Mode and zoom"

read -r first_command second_command <<EOF
$(sed -n '/L10n.t("只读模式")/,/设置缩放/p' <<<"$view_menu" | grep -o 'commandItem(\|toggleReadOnlyMode\|设置缩放' | head -4 | tr '\n' ' ')
EOF

grep -Fq '"toggleReadOnlyMode"' <<<"$minimal_to_zoom" \
    || fail "the read-only item must route to toggleReadOnlyMode"

toggle_dispatch_block="$(sed -n '/case "toggleReadOnlyMode":/,/case "learnMarkdown":/p' "$MENU")"
grep -Fq 'session?.toggleReadOnlyMode()' <<<"$toggle_dispatch_block" || {
    echo "FAIL: toggleReadOnlyMode must dispatch to the active editor session" >&2
    exit 1
}

validation_block="$(sed -n '/case "toggleReadOnlyMode":/,/case "restoreClosedTab":/p' "$MENU")"
grep -Fq 'menuItem.state = session.isReadOnly ? .on : .off' <<<"$validation_block" \
    && grep -Fq 'return ReadOnlyModePolicy.action' <<<"$validation_block" || {
    echo "FAIL: toggleReadOnlyMode must expose its checked state" >&2
    exit 1
}

grep -Fq "payload.command === 'setReadOnly'" "$FRONTEND" \
    || fail "the editor must accept a host setReadOnly command"
grep -Fq "setReadOnly" "$ROOT_DIR/../../packages/editor-core/src/host-command-policy.ts" \
    || fail "setReadOnly must remain allowed while already read-only"
grep -Fq "setReadOnly" "$ROOT_DIR/../../packages/editor-core/src/source-editor.ts" \
    || fail "SourceEditor must support runtime read-only changes"

echo PASS
