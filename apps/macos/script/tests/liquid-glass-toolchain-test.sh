#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_SCRIPT="$ROOT_DIR/script/build_and_run.sh"
PACKAGE_SCRIPT="$ROOT_DIR/script/release/package.sh"

for script in "$BUILD_SCRIPT" "$PACKAGE_SCRIPT"; do
  grep -Fq 'Xcode.app/Contents/Developer' "$script" \
    || { echo "FAIL: $script must prefer the stable Xcode toolchain that enables current Liquid Glass" >&2; exit 1; }
  grep -Fq 'Xcode-beta.app/Contents/Developer' "$script" \
    || { echo "FAIL: $script must retain the Xcode beta fallback" >&2; exit 1; }
  grep -Fq -- '-platform_version' "$script" \
    || { echo "FAIL: $script must preserve the current SDK in LC_BUILD_VERSION" >&2; exit 1; }
  grep -Fq 'show-sdk-version' "$script" \
    || { echo "FAIL: $script must derive the linker SDK version from the selected Xcode" >&2; exit 1; }
done

echo PASS
