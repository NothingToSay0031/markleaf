#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_DIR="$(mktemp -d /tmp/markleaf-glass-performance.XXXXXX)"
trap 'rm -rf "$BUILD_DIR"' EXIT

POLICY="$ROOT_DIR/Sources/MarkLeaf/Services/LiquidGlassPerformancePolicy.swift"
test -f "$POLICY" || { echo "FAIL: LiquidGlassPerformancePolicy.swift is required" >&2; exit 1; }

cat > "$BUILD_DIR/main.swift" <<'SWIFT'
import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

for trigger in [
    GlassRefreshTrigger.windowAttached, .appearanceChanged, .themeChanged,
    .accessibilityChanged, .keyWindowChanged,
] {
    expect(LiquidGlassPerformancePolicy.shouldRefresh(trigger), "\(trigger) must refresh glass")
}

for trigger in [
    GlassRefreshTrigger.caretMoved, .selectionChanged, .contentChanged,
    .scrolled, .viewportResized,
] {
    expect(!LiquidGlassPerformancePolicy.shouldRefresh(trigger), "\(trigger) must not refresh glass")
}
print("PASS")
SWIFT

SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
swiftc -sdk "$SDK_PATH" -module-cache-path "$BUILD_DIR/module-cache" \
  "$POLICY" "$BUILD_DIR/main.swift" -o "$BUILD_DIR/test"
"$BUILD_DIR/test"
