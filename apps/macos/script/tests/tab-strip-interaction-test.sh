#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TAB_BAR="$ROOT_DIR/Sources/MarkLeaf/Views/TabBarController.swift"
WINDOW="$ROOT_DIR/Sources/MarkLeaf/Views/EditorWindowController.swift"

require() {
    local text="$1"
    local file="$2"
    local message="$3"
    if ! grep -Fq "$text" "$file"; then
        echo "FAIL: $message" >&2
        exit 1
    fi
}

# Browser-style creation must have a direct, accessible tab-bar control.
require 'private let newTabButton' "$TAB_BAR" 'tab strip must expose a new-tab button'
require 'glassSurface = GlassSurfaceView(style: .regular)' "$TAB_BAR" 'tab strip must use one rounded Liquid Glass backing'
require 'onNewTab?()' "$TAB_BAR" 'new-tab button must call the window action'
require 'tabBar.onNewTab' "$WINDOW" 'window must create an untitled tab from the plus button'

# A right click belongs to the tab cell, not to the editor behind it.
require 'override func rightMouseDown(with event: NSEvent)' "$TAB_BAR" 'tab cell must receive secondary clicks'
require 'onContextAction' "$TAB_BAR" 'tab context actions must reach the window controller'
require 'closeOtherTabs' "$WINDOW" 'window must support close-other-tabs from the context menu'
require 'closeTabsToRight' "$WINDOW" 'window must support close-tabs-to-right from the context menu'

# Middle-click must follow the normal close path, so unsaved-document protection remains active.
require 'override func otherMouseDown(with event: NSEvent)' "$TAB_BAR" 'tab cell must receive middle clicks'
require 'event.buttonNumber == 2' "$TAB_BAR" 'only the middle mouse button closes a tab'
require 'onClose?()' "$TAB_BAR" 'middle click must invoke the normal close action'

# Safari-style layout keeps the tab strip full-width and splits available space equally.
require 'stack.distribution = .fillEqually' "$TAB_BAR" 'tabs must divide the available strip width equally'
require 'glassSurface.trailingAnchor.constraint(equalTo: newTabButton.leadingAnchor' "$TAB_BAR" 'glass-backed tab strip must consume all space before the plus button'
require 'glassSurface.setBackingHidden(tabStore.tabs.isEmpty)' "$TAB_BAR" 'empty tab strips must hide all glass backing layers'
require 'func setBackingHidden' "$ROOT_DIR/Sources/MarkLeaf/Views/GlassSurfaceView.swift" 'empty tab strips must hide the private effect subview'
require 'TabAnimationPolicy.duration(for: .insertRemoveReorder' "$TAB_BAR" 'new tabs must use the existing smooth layout animation policy'

echo "PASS"
