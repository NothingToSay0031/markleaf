#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PREFS="$ROOT_DIR/Sources/MarkLeaf/Views/PreferencesWindowController.swift"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

grep -Fq 'checkboxAlignmentControls: Set<NSButton>? = nil' "$PREFS" \
  || fail "form layout must support an explicit checkbox alignment group"

editor_body="$(sed -n '/private func editorPage()/,/private func appearancePage()/p' "$PREFS")"
required=(
  'let editorCenteredCheckboxes: Set<NSButton> = [visualCjkAutoSpacingCheck]'
  'let editorAlignedCheckboxes: Set<NSButton> = ['
  'multiTabCheck, ignoreMaxWidthCheck, blockHandleCheck, restoreZoomCheck, ctrlWheelZoomCheck,'
  ']'
  'checkboxAlignmentControls: editorAlignedCheckboxes'
)
for text in "${required[@]}"; do
  grep -Fq "$text" <<<"$editor_body" || fail "missing in editor page: $text"
done

echo PASS
