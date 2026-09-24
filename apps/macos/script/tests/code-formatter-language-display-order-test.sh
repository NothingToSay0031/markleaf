#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/markleaf-formatter-display-order.XXXXXX")"
trap 'rm -rf "$BUILD_DIR"' EXIT
cp "$ROOT_DIR/script/tests/CodeFormatterLanguageDisplayOrderTest.swift" "$BUILD_DIR/main.swift"
DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}" \
  CLANG_MODULE_CACHE_PATH="$BUILD_DIR/cache" \
  xcrun swiftc \
  "$ROOT_DIR/Sources/MarkLeaf/Services/CodeBlockLanguageCatalog.swift" \
  "$ROOT_DIR/Sources/MarkLeaf/Services/SQLFormatterDialect.swift" \
  "$ROOT_DIR/Sources/MarkLeaf/Services/ExternalCodeFormatterCatalog.swift" \
  "$BUILD_DIR/main.swift" \
  -o "$BUILD_DIR/test"
"$BUILD_DIR/test"
