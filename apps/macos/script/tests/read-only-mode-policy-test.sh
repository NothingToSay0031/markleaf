#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_DIR="$(mktemp -d /tmp/markleaf-read-only-policy-test.XXXXXX)"
trap 'rm -rf "$BUILD_DIR"' EXIT

cp "$ROOT_DIR/script/tests/ReadOnlyModePolicyTest.swift" "$BUILD_DIR/main.swift"
swiftc -module-cache-path "$BUILD_DIR/module-cache" \
  "$ROOT_DIR/Sources/MarkLeaf/Services/ReadOnlyModePolicy.swift" \
  "$BUILD_DIR/main.swift" \
  -o "$BUILD_DIR/read-only-mode-policy-test"
"$BUILD_DIR/read-only-mode-policy-test"
