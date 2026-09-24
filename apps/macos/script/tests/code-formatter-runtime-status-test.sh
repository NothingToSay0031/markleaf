#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MANAGER="$ROOT/Sources/MarkLeaf/Views/CodeFormatterManagerWindowController.swift"
SERVICE="$ROOT/Sources/MarkLeaf/Services/ExternalCodeFormatterService.swift"

for text in \
  '已配置 JAR，但缺少 Java 运行时' \
  '自定义路径无效' \
  '获取 Java…' \
  'ExternalCodeFormatterCatalog.availability'; do
  grep -Fq "$text" "$MANAGER" || { echo "FAIL: missing manager runtime status: $text" >&2; exit 1; }
done

grep -Fq 'jarMissingJavaRuntime' "$MANAGER" || {
  echo 'FAIL: manager must map the missing-Java runtime state' >&2
  exit 1
}

grep -Fq 'latexMissingPerlRuntime' "$MANAGER" || {
  echo 'FAIL: manager must map the missing-Perl runtime state' >&2
  exit 1
}

grep -Fq '已安装，但缺少 Perl 模块 File::HomeDir' "$MANAGER" || {
  echo 'FAIL: manager must explain the missing File::HomeDir module' >&2
  exit 1
}

grep -Fq 'javaRuntimeDownloadURL' "$MANAGER" || {
  echo 'FAIL: manager must link to the Java runtime download page' >&2
  exit 1
}

grep -Fq 'lastKnownLanguages' "$MANAGER" || {
  echo 'FAIL: manager must remember scanned formatter languages' >&2
  exit 1
}

grep -Fq 'availabilityDidChange' "$MANAGER" || {
  echo 'FAIL: manager must rescan formatter availability when opened' >&2
  exit 1
}

grep -Fq 'probeButton' "$MANAGER" || {
  echo 'FAIL: manager must expose a formatter probe' >&2
  exit 1
}

grep -Fq 'ExternalCodeFormatterProbeService' apps/macos/Sources/MarkLeaf/Services/*.swift || {
  echo 'FAIL: formatter probe must have a dedicated service' >&2
  exit 1
}

grep -Fq 'func probe(' apps/macos/Sources/MarkLeaf/Services/ExternalCodeFormatterProbeService.swift || {
  echo 'FAIL: formatter probe must support probing a selected tool' >&2
  exit 1
}

if grep -Fq '✅ 探测通过' "$MANAGER"; then
  echo 'FAIL: selected status must keep showing the formatter path' >&2
  exit 1
fi

grep -Fq 'probeResults' "$MANAGER" || {
  echo 'FAIL: probe results must be shown inside the manager table' >&2
  exit 1
}

if grep -Fq 'presentProbeResults' "$MANAGER"; then
  echo 'FAIL: formatter probe must not open a result window' >&2
  exit 1
fi

if grep -Fq 'alert.runModal' "$MANAGER"; then
  echo 'FAIL: formatter manager must not use a probe result modal' >&2
  exit 1
fi

grep -Fq 'Java 运行时不可用，无法格式化 Java 代码。' "$SERVICE" || {
  echo 'FAIL: formatter service must provide a friendly missing-Java failure' >&2
  exit 1
}

echo 'Code formatter runtime status tests passed'
