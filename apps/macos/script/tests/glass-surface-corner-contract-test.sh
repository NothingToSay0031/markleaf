#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_DIR="$(mktemp -d /tmp/markleaf-glass-corner.XXXXXX)"
trap 'rm -rf "$BUILD_DIR"' EXIT

GLASS="$ROOT_DIR/Sources/MarkLeaf/Views/GlassSurfaceView.swift"

cat > "$BUILD_DIR/main.swift" <<'SWIFT'
import AppKit

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

func makeSurface(_ style: GlassSurfaceView.Style) -> GlassSurfaceView {
    let surface = GlassSurfaceView(style: style)
    surface.setContent(NSView())
    return surface
}

expect(makeSurface(.interactive).glassCornerRadiusForTesting == 12, "interactive controls must use a rounded glass capsule")
expect(makeSurface(.regular).glassCornerRadiusForTesting == 0, "full-bleed window glass must keep square edges")
expect(makeSurface(.sidebar).glassCornerRadiusForTesting == 0, "sidebar glass must keep square edges")
print("PASS")
SWIFT

SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
swiftc -sdk "$SDK_PATH" -module-cache-path "$BUILD_DIR/module-cache" \
  "$GLASS" "$BUILD_DIR/main.swift" -o "$BUILD_DIR/test"
"$BUILD_DIR/test"
