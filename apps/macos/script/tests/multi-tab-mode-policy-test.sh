#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/markleaf-multi-tab-policy-test.XXXXXX")"
trap 'rm -rf "$BUILD_DIR"' EXIT

SETTINGS="$ROOT_DIR/Sources/MarkLeaf/Services/AppSettings.swift"
PREFS="$ROOT_DIR/Sources/MarkLeaf/Views/PreferencesWindowController.swift"
WINDOW="$ROOT_DIR/Sources/MarkLeaf/Views/EditorWindowController.swift"

require() {
  grep -Fq "$2" "$1" || { echo "FAIL: $3" >&2; exit 1; }
}
require_text() {
  grep -Fq "$2" <<<"$1" || { echo "FAIL: $3" >&2; exit 1; }
}

method_body() {
  awk -v name="$2" '
    $0 ~ "private func " name "\\(\\)" { found=1; next }
    found && $0 == "    }" { exit }
    found { print }
  ' "$1"
}

MULTI_TAB_UI_BODY=$(method_body "$WINDOW" installMultiTabUI)
require_text "$MULTI_TAB_UI_BODY" 'tabBar.topAnchor.constraint(equalTo: rightColumn.safeAreaLayoutGuide.topAnchor)' \
  'the tab strip must stay below the fixed MarkLeaf titlebar'
if grep -Fq 'tabBar.topAnchor.constraint(equalTo: rightColumn.topAnchor)' <<<"$MULTI_TAB_UI_BODY"; then
  echo 'FAIL: the tab strip must not overlap the native titlebar' >&2
  exit 1
fi
WINDOW_TITLE_BODY=$(method_body "$WINDOW" applyWindowTitle)
require_text "$WINDOW_TITLE_BODY" 'windowTitleTransitionView?.setDocumentTitle(baseTitle)' \
  'single-tab mode must retain the existing filename title behavior'
require_text "$WINDOW_TITLE_BODY" 'windowTitleTransitionView?.setFixedApplicationTitle("MarkLeaf")' \
  'multi-tab mode must reserve zero status-marker space for the fixed application title'
require_text "$WINDOW_TITLE_BODY" 'windowTitleTransitionView?.setDocumentTitle(baseTitle)' \
  'single-document mode must reserve document status-marker space'
require "$WINDOW" 'private var isTitleTransitionReady = false' \
  'startup title updates must remain non-animated until the first run loop'
require "$WINDOW" 'transitionTitleStatusMarker(to: marker, animated: isTitleTransitionReady)' \
  'single-document startup must not trigger a title slide'
require "$WINDOW" 'transitionView.applyStartupStateWithoutAnimation()' \
  'titlebar layer attachment must synchronously restore the startup title state'

require "$SETTINGS" 'var multiTabEnabled = true' 'multi-tab must default to enabled'
require "$SETTINGS" 'forKey: .multiTabEnabled' 'legacy settings must decode multi-tab with a safe default'
require "$PREFS" 'private let multiTabCheck' 'preferences must expose the multi-tab switch'
require "$PREFS" 'settings.multiTabEnabled = multiTabEnabled' 'preferences must persist the multi-tab switch'
require "$PREFS" 'syncOpenModeControlStates()' \
  'preferences must keep file-open controls in sync with multi-tab mode'
require "$PREFS" 'MultiTabModePolicy.externalNewTabItemEnabled(multiTabEnabled:' \
  'external new-tab menu item must follow the multi-tab policy'
require "$PREFS" 'MultiTabModePolicy.workspaceControlsEnabled(' \
  'workspace open controls must follow the multi-tab policy'
require "$PREFS" 'MultiTabModePolicy.workspaceDisplayPrefersNewTab(' \
  'disabled workspace controls must display the default new-tab preference'
require "$PREFS" 'settings.externalFileOpenMode = savedExternalFileOpenMode' \
  'external new-tab selection must be normalized before persistence'
require "$PREFS" 'settings.workspaceOpenInNewTab = displayedWorkspaceOpensInNewTab' \
  'workspace preference must be normalized to match the disabled control display'
require "$PREFS" 'let editorAlignedCheckboxes: Set<NSButton> = [' 'editor checkboxes must use a shared alignment group'
PREFS_FILE_BODY=$(method_body "$PREFS" filePage)
PREFS_EDITOR_BODY=$(method_body "$PREFS" editorPage)
require_text "$PREFS_EDITOR_BODY" '.header(L10n.t("文档与标签"))' 'the editor page must contain a documents-and-tabs group'
require_text "$PREFS_EDITOR_BODY" '.checkboxGroup([multiTabCheck, ignoreMaxWidthCheck, blockHandleCheck])' \
  'the multi-tab switch must belong to the editor page group'
if grep -Fq '.checkboxGroup([multiTabCheck' <<<"$PREFS_FILE_BODY"; then
  echo 'FAIL: the multi-tab switch must not remain on the file page' >&2
  exit 1
fi
require "$WINDOW" 'func applyMultiTabMode(animated: Bool)' 'editor windows must apply the multi-tab mode'
require "$WINDOW" 'applyWindowTitle()' 'single-document windows must update the filename title'
require "$WINDOW" 'L10n.t("最简模式已开启")' 'minimal mode status must use the renamed state'
require "$WINDOW" 'L10n.t("最简模式已关闭")' 'minimal mode exit status must use the renamed state'

cp "$ROOT_DIR/script/tests/MultiTabModePolicyTest.swift" "$BUILD_DIR/main.swift"
swiftc -module-cache-path "$BUILD_DIR/module-cache" \
  "$ROOT_DIR/Sources/MarkLeaf/Services/ExternalFileOpenMode.swift" \
  "$ROOT_DIR/Sources/MarkLeaf/Services/MultiTabModePolicy.swift" \
  "$BUILD_DIR/main.swift" \
  -o "$BUILD_DIR/multi-tab-mode-policy-test"
"$BUILD_DIR/multi-tab-mode-policy-test"
