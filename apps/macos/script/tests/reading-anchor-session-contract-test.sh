#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$ROOT_DIR/Sources/MarkLeaf/Services/SessionManifest.swift"
SNAPSHOT="$ROOT_DIR/Sources/MarkLeaf/Services/SnapshotRequestQueue.swift"
FRONTEND="$ROOT_DIR/../../packages/editor-web/src/main.ts"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

grep -Fq 'struct ReadingAnchor: Codable, Equatable' "$MANIFEST" \
  || fail "session manifest must define ReadingAnchor"
grep -Fq 'var readingAnchor: ReadingAnchor?' "$MANIFEST" \
  || fail "session tab record must persist a reading anchor"
grep -Fq 'var readingAnchor: ReadingAnchor?' "$SNAPSHOT" \
  || fail "editor snapshots must carry a reading anchor"
grep -Fq 'readingAnchor: captureReadingAnchor()' "$FRONTEND" \
  || fail "snapshots must capture the current reading anchor"

echo PASS
