#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
CHROME="$ROOT_DIR/Sources/MarkLeaf/Views/FloatingWindowChrome.swift"
FIND="$ROOT_DIR/Sources/MarkLeaf/Views/FindPanelController.swift"
THEME="$ROOT_DIR/Sources/MarkLeaf/Views/ThemeSettingsWindowController.swift"
PREFERENCES="$ROOT_DIR/Sources/MarkLeaf/Views/PreferencesWindowController.swift"

require() {
  local file="$1" text="$2" message="$3"
  grep -Fq "$text" "$file" || { echo "FAIL: $message" >&2; exit 1; }
}

require "$CHROME" 'static func classification(for window: NSWindow)' \
  'floating windows must expose their Liquid Glass classification'
require "$FIND" 'FloatingWindowChrome.register(' \
  'find and replace must participate in the floating-window contract'
require "$FIND" 'classification: .navigation' \
  'find and replace must be classified as navigation'
require "$FIND" 'preservesCustomBacking: true' \
  'compact find and replace must preserve its clear floating-card backing'
require "$THEME" 'FloatingWindowChrome.configure(window, classification: .navigation)' \
  'theme settings must use the shared navigation floating-window contract'
require "$PREFERENCES" 'FloatingWindowChrome.configure(window, classification: .navigation)' \
  'preferences must use the shared navigation floating-window contract'

echo PASS
