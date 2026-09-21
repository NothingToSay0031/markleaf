#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PREFS="$ROOT_DIR/Sources/MarkLeaf/Views/PreferencesWindowController.swift"

grep -Fq 'window.toolbarStyle = .preference' "$PREFS" \
  || { echo "FAIL: preferences window must use the native Finder-style preference toolbar" >&2; exit 1; }
grep -Fq 'tabViewController.tabStyle = .toolbar' "$PREFS" \
  || { echo "FAIL: preference tabs must remain system-managed toolbar tabs" >&2; exit 1; }
grep -Fq 'window.titlebarSeparatorStyle = .line' "$PREFS" \
  || { echo "FAIL: preference toolbar must retain a visible separation from the opaque body" >&2; exit 1; }
grep -Fq 'window.isOpaque = true' "$PREFS" \
  || { echo "FAIL: preference window backing must stay opaque to prevent background windows bleeding through" >&2; exit 1; }
grep -Fq 'window.backgroundColor = .windowBackgroundColor' "$PREFS" \
  || { echo "FAIL: preference window must use the opaque window background like Finder Settings" >&2; exit 1; }
if grep -Fq 'root.layer?.backgroundColor' "$PREFS"; then
  echo "FAIL: preference form body must not freeze a CGColor across appearance changes" >&2
  exit 1
fi

echo PASS
