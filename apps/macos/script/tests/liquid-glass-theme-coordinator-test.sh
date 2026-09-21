#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_DIR="$(mktemp -d /tmp/markleaf-glass-theme-coordinator.XXXXXX)"
trap 'rm -rf "$BUILD_DIR"' EXIT

COORDINATOR="$ROOT_DIR/Sources/MarkLeaf/Services/LiquidGlassThemeCoordinator.swift"
test -f "$COORDINATOR" || { echo "FAIL: LiquidGlassThemeCoordinator.swift is required" >&2; exit 1; }

cat > "$BUILD_DIR/main.swift" <<'SWIFT'
import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

expect(LiquidGlassThemeCoordinator.resolve(followSystem: true, systemDark: false, explicitDark: true) == .light, "follow system must ignore the prior manual theme")
expect(LiquidGlassThemeCoordinator.resolve(followSystem: true, systemDark: true, explicitDark: false) == .dark, "follow system must choose system dark")
expect(LiquidGlassThemeCoordinator.resolve(followSystem: false, systemDark: true, explicitDark: false) == .light, "manual light must override system dark")
expect(LiquidGlassThemeCoordinator.resolve(followSystem: false, systemDark: false, explicitDark: true) == .dark, "manual dark must override system light")
print("PASS")
SWIFT

SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
swiftc -sdk "$SDK_PATH" -module-cache-path "$BUILD_DIR/module-cache" \
  "$ROOT_DIR/Sources/MarkLeaf/Views/GlassSurfaceView.swift" \
  "$COORDINATOR" "$BUILD_DIR/main.swift" -o "$BUILD_DIR/test"
"$BUILD_DIR/test"
