#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PREFS="$ROOT_DIR/Sources/MarkLeaf/Views/PreferencesWindowController.swift"
L10N="$ROOT_DIR/Sources/MarkLeaf/Services/L10n.swift"

python3 - "$PREFS" "$L10N" <<'PY'
import pathlib
import sys

prefs = pathlib.Path(sys.argv[1]).read_text()
l10n = pathlib.Path(sys.argv[2]).read_text()
start = prefs.index('@objc private func clearHistory()')
end = prefs.index('@objc private func openThemeFolder()', start)
action = prefs[start:end]

required = [
    'let alert = NSAlert()',
    'alert.messageText = L10n.t("确定要清除历史记录吗？")',
    'alert.informativeText = L10n.t("此操作会删除最近的文件和文件夹记录。")',
    'alert.alertStyle = .warning',
    'alert.addButton(withTitle: L10n.t("清除"))',
    'alert.addButton(withTitle: L10n.t("取消"))',
    'alert.buttons.first?.hasDestructiveAction = true',
    'alert.beginSheetModal(for: window!)',
    'guard response == .alertFirstButtonReturn else { return }',
    'SettingsService.shared.update',
    'infoAlert(L10n.t("历史记录已清除"))',
]
for text in required:
    assert text in action, f'missing confirmation contract: {text}'

translations = [
    '"确定要清除历史记录吗？": "履歴を消去しますか？"',
    '"确定要清除历史记录吗？": "確定要清除歷史記錄嗎？"',
    '"确定要清除历史记录吗？": "Clear history?"',
    '"此操作会删除最近的文件和文件夹记录。": "最近のファイルとフォルダの記録を削除します。"',
    '"此操作会删除最近的文件和文件夹记录。": "此操作會刪除最近的檔案和資料夾記錄。"',
    '"此操作会删除最近的文件和文件夹记录。": "This will delete recent file and folder history."',
]
for text in translations:
    assert text in l10n, f'missing localized copy: {text}'

print('PASS')
PY
