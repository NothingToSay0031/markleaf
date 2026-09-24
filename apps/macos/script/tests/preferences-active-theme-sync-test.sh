#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANAGER="$ROOT_DIR/Sources/MarkLeaf/App/AppWindowManager.swift"
PREFS="$ROOT_DIR/Sources/MarkLeaf/Views/PreferencesWindowController.swift"

grep -Fq 'func syncActiveTheme(_ themeID: String?)' "$PREFS" || {
  echo 'FAIL: preferences must support syncing the active theme' >&2
  exit 1
}

grep -Fq 'activeWindowController?.windowSession?.activeTabSession?.currentThemeId' "$MANAGER" || {
  echo 'FAIL: active theme must be read from the active editor session' >&2
  exit 1
}

if grep -Fq 'preferencesController?.syncActiveTheme(activeViewStateSession' "$MANAGER"; then
  echo 'FAIL: preferences must not sync from a stale non-active session' >&2
  exit 1
fi

if awk '/func refreshThemeSettings\(\)/,/^\    \}/' "$MANAGER" | grep -Fq 'syncActiveTheme'; then
  echo 'FAIL: refreshThemeSettings must not override a manual theme from stale state' >&2
  exit 1
fi

if sed -n '/func syncActiveTheme/,/^    }$/p' "$PREFS" |
   grep -Fq 'guard SettingsService.shared.settings.followSystemTheme'; then
  echo 'FAIL: active theme cache must stay current in manual-theme mode' >&2
  exit 1
fi

apply_order=$(sed -n '/func applyThemeModeToAll/,/^    }$/p' "$MANAGER")
active_line=$(printf '%s\n' "$apply_order" | grep -n 'preferencesController?.syncActiveTheme' | head -1 | cut -d: -f1)
follow_line=$(printf '%s\n' "$apply_order" | grep -n 'preferencesController?.syncFollowSystemThemeState' | head -1 | cut -d: -f1)

if [[ -z "$active_line" || -z "$follow_line" || "$active_line" -ge "$follow_line" ]]; then
  echo 'FAIL: active theme must be refreshed before follow-system control state' >&2
  exit 1
fi

grep -Fq 'func applyThemeModeToAll(preservesRenderedTheme: Bool = false)' "$MANAGER" || {
  echo 'FAIL: disabling system sync must be able to preserve the rendered theme' >&2
  exit 1
}

grep -Fq 'let disabledSystemSync = oldFollowSystemTheme && !collected.followSystemTheme' "$PREFS" || {
  echo 'FAIL: preferences must distinguish disabling sync from a manual theme change' >&2
  exit 1
}

grep -Fq 'applyThemeModeToAll(preservesRenderedTheme: disabledSystemSync)' "$PREFS" || {
  echo 'FAIL: disabling sync must preserve the current theme until the user chooses one' >&2
  exit 1
}

echo 'Preferences active theme sync tests passed'
