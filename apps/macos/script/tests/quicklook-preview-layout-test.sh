#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_DIR="$(mktemp -d /tmp/markleaf-quicklook-layout.XXXXXX)"
trap 'rm -rf "$BUILD_DIR"' EXIT

LAYOUT="$ROOT_DIR/Sources/QuickLook/QuickLookPreviewLayout.swift"
test -f "$LAYOUT" || { echo "FAIL: QuickLookPreviewLayout.swift is required" >&2; exit 1; }

cat > "$BUILD_DIR/main.swift" <<'SWIFT'
import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

let large = QuickLookPreviewLayout.contentSize(visible: CGSize(width: 1800, height: 1200))
expect(large.width <= 720 && large.height <= 560, "large screens must not create an oversized default preview")
let laptop = QuickLookPreviewLayout.contentSize(visible: CGSize(width: 1512, height: 950))
expect(laptop.width <= 720 && laptop.height <= 560, "laptop screens must use a compact preview")
expect(laptop.width >= 560 && laptop.height >= 420, "the compact preview must remain readable")
let tiny = QuickLookPreviewLayout.contentSize(visible: CGSize(width: 300, height: 200))
expect(tiny.width >= 480 && tiny.height >= 360, "very small screens still need a usable preview")
let fallback = QuickLookPreviewLayout.contentSize(visible: nil)
expect(fallback == CGSize(width: 680, height: 500), "the fallback preview must be compact and deterministic")
print("PASS")
SWIFT

SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
swiftc -sdk "$SDK_PATH" -module-cache-path "$BUILD_DIR/module-cache" \
  "$LAYOUT" "$BUILD_DIR/main.swift" -o "$BUILD_DIR/test"
"$BUILD_DIR/test"
