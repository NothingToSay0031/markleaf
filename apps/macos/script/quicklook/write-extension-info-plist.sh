#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MACOS_DIR="$(cd "$HERE/../.." && pwd)"
REPO_DIR="$(cd "$MACOS_DIR/.." && pwd)"
INFO_PLIST="${1:?Info.plist output path is required}"

source "$MACOS_DIR/script/release_version.sh"
source "$MACOS_DIR/script/build_metadata.sh"
APP_VERSION="$(resolve_markleaf_version)"
APP_BUILD="$(resolve_markleaf_build_number "$REPO_DIR")"

cat > "$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleIdentifier</key><string>com.markleaf.app.QuickLook</string>
  <key>CFBundleExecutable</key><string>MarkLeafQuickLook</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>MarkLeaf Quick Look</string>
  <key>CFBundleDisplayName</key><string>MarkLeaf Quick Look</string>
  <key>CFBundlePackageType</key><string>XPC!</string>
  <key>CFBundleShortVersionString</key><string>$APP_VERSION</string>
  <key>CFBundleVersion</key><string>$APP_BUILD</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>CFBundleSupportedPlatforms</key>
  <array><string>MacOSX</string></array>
  <key>NSExtension</key>
  <dict>
    <key>NSExtensionAttributes</key>
    <dict>
      <key>QLIsDataBasedPreview</key>
      <true/>
      <key>QLSupportsSearchableItems</key>
      <false/>
      <key>QLSupportedContentTypes</key>
      <array>
        <string>net.daringfireball.markdown</string>
        <string>public.plain-text</string>
      </array>
    </dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.quicklook.preview</string>
  <key>NSExtensionPrincipalClass</key>
  <string>PreviewViewController</string>
  </dict>
</dict>
</plist>
PLIST
