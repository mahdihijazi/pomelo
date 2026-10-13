#!/bin/zsh
# Builds Pomelo.app (universal) into ./build
set -e
cd "$(dirname "$0")"
APP=build/Pomelo.app
rm -rf build && mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
for arch in arm64 x86_64; do
  swiftc -parse-as-library -O -target $arch-apple-macos14.0 Sources/*.swift -o build/Pomelo-$arch
done
lipo -create build/Pomelo-arm64 build/Pomelo-x86_64 -output "$APP/Contents/MacOS/Pomelo"
rm build/Pomelo-arm64 build/Pomelo-x86_64
swift Scripts/make_icon.swift build/AppIcon.iconset
iconutil -c icns build/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf build/AppIcon.iconset
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Pomelo</string>
  <key>CFBundleDisplayName</key><string>Pomelo</string>
  <key>CFBundleIdentifier</key><string>app.pomelo.focus</string>
  <key>CFBundleExecutable</key><string>Pomelo</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST
cp -R Resources/Sounds "$APP/Contents/Resources/Sounds"
codesign --force --deep --sign - "$APP"
echo "Built $APP"
