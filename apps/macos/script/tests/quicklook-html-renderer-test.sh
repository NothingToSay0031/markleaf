#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/markleaf-quicklook-html.XXXXXX")"
trap 'rm -rf "$BUILD_DIR"' EXIT

SDK_PATH="${SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
cp "$ROOT_DIR/script/tests/QuickLookHTMLRendererTest.swift" "$BUILD_DIR/main.swift"
swiftc \
  -sdk "$SDK_PATH" \
  -module-cache-path "$BUILD_DIR/module-cache" \
  "$ROOT_DIR/Sources/QuickLook/QuickLookDocumentPolicy.swift" \
  "$ROOT_DIR/Sources/QuickLook/QuickLookHTMLRenderer.swift" \
  "$BUILD_DIR/main.swift" \
  -o "$BUILD_DIR/html-renderer-test"

"$BUILD_DIR/html-renderer-test"
