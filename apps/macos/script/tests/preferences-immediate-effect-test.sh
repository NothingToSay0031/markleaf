#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1]) / 'Sources/MarkLeaf/Views'
prefs = (root / 'PreferencesWindowController.swift').read_text()
theme = (root / 'ThemeSettingsWindowController.swift').read_text()

for legacy in ('okAction', 'cancelAction', 'applyButton', 'NSButton(title: L10n.t("应用更改")'):
    assert legacy not in prefs, f'preferences must not keep deferred-action legacy API: {legacy}'
assert 'private func commitControlChanges()' in prefs, 'preferences must commit valid edits immediately'
assert 'syncOpenModeControlStates()\n        commitControlChanges()' in prefs, \
    'control changes must commit after dependent control states are synchronized'
assert 'invalidNumericFieldLabel() == nil else { return }' in prefs, \
    'invalid numeric text must not be committed while editing'
assert 'commitControlChanges()' in prefs[prefs.find('func controlTextDidEndEditing'):], \
    'valid numeric edits must commit when editing ends'

assert 'let closeButton = NSButton(title: L10n.t("关闭")' not in theme, \
    'theme settings must rely on the native close control instead of a bottom Close button'
assert '@objc private func closeWindow()' not in theme, \
    'theme settings must not retain the legacy bottom-close action'
assert 'constant: -20)' in theme, 'theme content should reclaim the retired bottom action area'

print('PASS')
PY
