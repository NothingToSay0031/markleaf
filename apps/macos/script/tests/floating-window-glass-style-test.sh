#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_DIR="$(mktemp -d /tmp/markleaf-floating-window-glass-test.XXXXXX)"
trap 'rm -rf "$BUILD_DIR"' EXIT

CHROME="$ROOT_DIR/Sources/MarkLeaf/Views/FloatingWindowChrome.swift"
test -f "$CHROME" || { echo "FAIL: FloatingWindowChrome.swift is required" >&2; exit 1; }
if grep -q 'CGColor' "$CHROME"; then
  echo "FAIL: floating chrome must not freeze colors as CGColor" >&2
  exit 1
fi

cat > "$BUILD_DIR/main.swift" <<'SWIFT'
import AppKit

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

func makeWindow() -> NSWindow {
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 480, height: 320),
        styleMask: [.titled, .closable],
        backing: .buffered,
        defer: false
    )
    // Deliberately start with non-native chrome to prove the helper resets it.
    window.titlebarAppearsTransparent = true
    window.titleVisibility = .hidden
    window.titlebarSeparatorStyle = .none
    window.isOpaque = false
    window.backgroundColor = .clear
    return window
}

for classification in [FloatingWindowClassification.navigation, .content, .preview] {
    let window = makeWindow()
    FloatingWindowChrome.configure(window, classification: classification)

    expect(window.titleVisibility == .visible, "\(classification) must keep its native title")
    expect(window.titlebarAppearsTransparent == false, "\(classification) must keep native titlebar material")
    expect(window.isOpaque, "\(classification) must keep an opaque window backing")
    expect(window.backgroundColor == .windowBackgroundColor, "\(classification) must use the system window background")
    expect(window.standardWindowButton(.closeButton)?.isHidden == false, "\(classification) must keep the native close button")

    let body = NSView()
    let root = FloatingWindowChrome.installOpaqueBody(body, in: window)
    expect(root.window === window, "\(classification) body root must be installed in the window")
    expect(body.translatesAutoresizingMaskIntoConstraints == false, "\(classification) body must participate in layout")
    expect(window.contentView === root, "\(classification) body root must become the content view")
    window.contentView?.layoutSubtreeIfNeeded()
    expect(abs(body.frame.width - window.contentView!.bounds.width) < 0.5, "\(classification) body must span the content view")
}

expect(
    FloatingWindowChrome.titlebarSeparator(for: .navigation) == .line,
    "navigation windows must separate glass navigation from opaque content"
)
expect(
    FloatingWindowChrome.titlebarSeparator(for: .content) == .line,
    "content windows must separate native titlebar glass from dense content"
)
expect(
    FloatingWindowChrome.titlebarSeparator(for: .preview) == .automatic,
    "preview windows should let AppKit choose the native preview separator"
)

print("PASS")
SWIFT

SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
swiftc -sdk "$SDK_PATH" -module-cache-path "$BUILD_DIR/module-cache" \
  "$CHROME" "$BUILD_DIR/main.swift" \
  -o "$BUILD_DIR/floating-window-glass-style-test"
"$BUILD_DIR/floating-window-glass-style-test"

CHROME_REQUIREMENTS=(
  "FontSettingsWindowController.swift|FloatingWindowChrome.configure(window, classification: .navigation)"
  "MarkdownBehaviorSettingsWindowController.swift|FloatingWindowChrome.configure(window, classification: .navigation)"
  "StatusBarSettingsWindowController.swift|FloatingWindowChrome.configure(window, classification: .navigation)"
  "ShortcutWindowController.swift|FloatingWindowChrome.configure(window, classification: .content)"
  "OptionalFontsWindowController.swift|FloatingWindowChrome.configure(window, classification: .content)"
  "DocumentStatisticsWindowController.swift|FloatingWindowChrome.configure(window, classification: .content)"
  "RecoveryWindowController.swift|FloatingWindowChrome.configure(window, classification: .content)"
  "ExportWindowController.swift|FloatingWindowChrome.configure(window, classification: .content)"
)
for requirement in "${CHROME_REQUIREMENTS[@]}"; do
  file="${requirement%%|*}"
  required="${requirement#*|}"
  path="$ROOT_DIR/Sources/MarkLeaf/Views/$file"
  grep -Fq "$required" "$path" || {
    echo "FAIL: $file must use the shared floating-window chrome contract" >&2
    exit 1
  }
done

for file in ShortcutWindowController.swift OptionalFontsWindowController.swift RecoveryWindowController.swift ExportWindowController.swift ThemeSettingsWindowController.swift; do
  path="$ROOT_DIR/Sources/MarkLeaf/Views/$file"
  grep -Fq 'CompactOverlayScrollView.configure(' "$path" || {
    echo "FAIL: $file must use compact overlay scrolling" >&2
    exit 1
  }
done
