#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/markleaf-recovery-open.XXXXXX")"
trap 'rm -rf "$BUILD_DIR"' EXIT
SDK_PATH="${SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
cp "$ROOT_DIR/script/tests/RecoveryOpenPolicyTest.swift" "$BUILD_DIR/main.swift"
swiftc -sdk "$SDK_PATH" -module-cache-path "$BUILD_DIR/module-cache" \
  "$ROOT_DIR/Sources/MarkLeaf/Services/MultiTabModePolicy.swift" \
  "$ROOT_DIR/Sources/MarkLeaf/Services/ExternalFileOpenMode.swift" \
  "$ROOT_DIR/Sources/MarkLeaf/Services/RecoveryOpenPolicy.swift" \
  "$BUILD_DIR/main.swift" \
  -o "$BUILD_DIR/recovery-open-policy-test"
"$BUILD_DIR/recovery-open-policy-test"

MANAGER="$ROOT_DIR/Sources/MarkLeaf/App/AppWindowManager.swift"
WINDOW_CONTROLLER="$ROOT_DIR/Sources/MarkLeaf/Views/EditorWindowController.swift"
RECOVERY_CONTROLLER="$ROOT_DIR/Sources/MarkLeaf/Views/RecoveryWindowController.swift"

grep -Fq 'func openRecoverySnapshot' "$MANAGER" || {
  echo 'FAIL: AppWindowManager must expose recovery snapshot opening' >&2
  exit 1
}
grep -Fq 'func openRecoverySnapshot' "$WINDOW_CONTROLLER" || {
  echo 'FAIL: editor window must support opening a recovery snapshot without disk write' >&2
  exit 1
}
grep -Fq 'initialDirty: true' "$WINDOW_CONTROLLER" || {
  echo 'FAIL: opened recovery snapshots must remain unsaved' >&2
  exit 1
}
grep -Fq 'openButton' "$RECOVERY_CONTROLLER" || {
  echo 'FAIL: recovery dialog must expose an Open button' >&2
  exit 1
}
grep -Fq 'onOpen?(snapshot)' "$RECOVERY_CONTROLLER" || {
  echo 'FAIL: recovery Open button must invoke its host callback' >&2
  exit 1
}
