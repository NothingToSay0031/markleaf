#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
MENU="$ROOT_DIR/Sources/MarkLeaf/Support/NativeMenuBuilder.swift"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

method_body() {
  awk -v name="$1" '
    $0 ~ ("private func " name "\\()") { inbody=1 }
    inbody {
      print
      if ($0 ~ /^    }$/) { exit }
    }
  ' "$MENU"
}

app_menu="$(method_body appMenu)"
app_menu_sequence="$(printf '%s\n' "$app_menu" | grep 'menu.addItem' | sed 's/^[[:space:]]*//')"
expected_app_menu_sequence=$'menu.addItem(commandItem(L10n.t("关于 MarkLeaf"), "showAbout"))\nmenu.addItem(commandItem(L10n.t("检查更新…"), "checkForUpdates"))\nmenu.addItem(.separator())\nmenu.addItem(commandItem(L10n.t("偏好设置…"), "showPreferences", key: ","))\nmenu.addItem(.separator())\nmenu.addItem(servicesMenuItem())\nmenu.addItem(.separator())\nmenu.addItem(item(L10n.t("隐藏 MarkLeaf"), #selector(NSApplication.hide(_:)), target: NSApp, key: "h"))\nmenu.addItem(item(L10n.t("隐藏其他"), #selector(NSApplication.hideOtherApplications(_:)), target: NSApp, key: "h", mask: [.command, .option]))\nmenu.addItem(item(L10n.t("全部显示"), #selector(NSApplication.unhideAllApplications(_:)), target: NSApp))\nmenu.addItem(.separator())\nmenu.addItem(item(L10n.t("退出 MarkLeaf"), #selector(NSApplication.terminate(_:)), target: NSApp, key: "q"))'
[[ "$app_menu_sequence" == "$expected_app_menu_sequence" ]] \
  || fail "app menu must follow the macOS About/Updates/Preferences/Services order"

grep -Fq 'NSApp.servicesMenu = servicesItem.submenu' "$MENU" \
  || fail "builder must register the standard macOS Services submenu"

help_menu="$(method_body helpMenu)"
printf '%s' "$help_menu" | grep -Fq '检查更新…' \
  && fail "Check for Updates must move out of Help" || true

echo PASS
