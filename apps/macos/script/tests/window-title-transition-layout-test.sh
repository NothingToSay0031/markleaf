#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_DIR="$(mktemp -d /tmp/markleaf-window-title-transition-layout-test.XXXXXX)"
trap 'rm -rf "$BUILD_DIR"' EXIT
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"

# The layout behavior under test is independent of localization; inline the
# localized label so this contract can compile the view in isolation.
sed 's/L10n\.t("已修改")/"已修改"/g' \
  "$ROOT_DIR/Sources/MarkLeaf/Views/WindowTitleTransitionView.swift" \
  > "$BUILD_DIR/WindowTitleTransitionView.swift"
cp "$ROOT_DIR/script/tests/WindowTitleTransitionLayoutTest.swift" "$BUILD_DIR/main.swift"

swiftc -sdk "$SDK_PATH" -module-cache-path "$BUILD_DIR/module-cache" \
  "$BUILD_DIR/WindowTitleTransitionView.swift" "$BUILD_DIR/main.swift" \
  -o "$BUILD_DIR/window-title-transition-layout-test"
"$BUILD_DIR/window-title-transition-layout-test"
