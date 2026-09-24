#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD="$(mktemp -d /tmp/markleaf-formatter-launch.XXXXXX)"
trap 'rm -rf "$BUILD"' EXIT
cp "$ROOT/script/tests/ExternalCodeFormatterLaunchTest.swift" "$BUILD/main.swift"

DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}" \
  CLANG_MODULE_CACHE_PATH="$BUILD/cache" \
  xcrun swiftc \
  "$BUILD/main.swift" \
  "$ROOT/Sources/MarkLeaf/Services/SQLFormatterDialect.swift" \
  "$ROOT/Sources/MarkLeaf/Services/CodeBlockLanguageCatalog.swift" \
  "$ROOT/Sources/MarkLeaf/Services/ExternalCodeFormatterCatalog.swift" \
  -o "$BUILD/test"
"$BUILD/test"
