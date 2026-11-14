#!/bin/sh
# Збирає «Мітки.app» у ~/Applications. Потрібні лише Command Line Tools (swiftc, sips, iconutil).
# Запуск: sh app/build.sh
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build"
APP="$OUT/Мітки.app"
DEST="${1:-$HOME/Applications}"

rm -rf "$OUT"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$OUT/icon.iconset"

swiftc -O -swift-version 5 -module-cache-path "$OUT/modcache" -o "$APP/Contents/MacOS/mitky" "$ROOT/app/main.swift" -framework Cocoa -framework WebKit
cp "$ROOT/index.html" "$APP/Contents/Resources/index.html"

swiftc -swift-version 5 -module-cache-path "$OUT/modcache" -o "$OUT/mkicon" "$ROOT/app/icon.swift" -framework Cocoa
"$OUT/mkicon" "$OUT/icon.png"
for s in 16 32 128 256 512; do
  sips -z $s $s "$OUT/icon.png" --out "$OUT/icon.iconset/icon_${s}x${s}.png" >/dev/null
  d=$((s * 2))
  sips -z $d $d "$OUT/icon.png" --out "$OUT/icon.iconset/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$OUT/icon.iconset" -o "$APP/Contents/Resources/icon.icns"

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Мітки</string>
  <key>CFBundleDisplayName</key><string>Мітки</string>
  <key>CFBundleIdentifier</key><string>com.mitky.app</string>
  <key>CFBundleExecutable</key><string>mitky</string>
  <key>CFBundleIconFile</key><string>icon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
</dict>
</plist>
EOF

codesign --force --sign - "$APP" >/dev/null 2>&1 || true
mkdir -p "$DEST"
rm -rf "$DEST/Мітки.app"
cp -R "$APP" "$DEST/"
echo "Готово: $DEST/Мітки.app"
