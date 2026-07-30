#!/bin/bash
# Macraft 构建脚本
# 用 Swift 命令行工具链编译并打包成标准 macOS .app 束 + .dmg（无需完整 Xcode）
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
APP_NAME="Macraft"
DIST="$ROOT/dist"
APP_BUNDLE="$DIST/$APP_NAME.app"
DMG_PATH="$DIST/$APP_NAME.dmg"

echo "==> 清理旧产物"
rm -rf "$APP_BUNDLE" "$DMG_PATH"
mkdir -p "$DIST"

echo "==> 以 Release 模式编译"
swift build -c release

BIN="$ROOT/.build/release/$APP_NAME"
if [[ ! -f "$BIN" ]]; then
    echo "错误：找不到编译产物 $BIN" >&2
    exit 1
fi

echo "==> 组装 .app 束"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$ROOT/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# 图标（若存在）
if [[ -f "$ROOT/Resources/AppIcon.icns" ]]; then
    cp "$ROOT/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    echo "    已包含应用图标"
else
    echo "    提示：未找到 AppIcon.icns，使用系统默认图标"
fi

# 让二进制可执行
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

echo "==> 打包 .dmg"
DMG_TEMP="$DIST/.dmg_temp"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"
cp -R "$APP_BUNDLE" "$DMG_TEMP/"
ln -s /Applications "$DMG_TEMP/Applications"

hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_TEMP" -ov -format UDZO "$DMG_PATH" -quiet
rm -rf "$DMG_TEMP"

echo "==> 完成"
echo "    .app: $APP_BUNDLE"
echo "    .dmg: $DMG_PATH"
echo "    运行：open \"$APP_BUNDLE\""
#!/bin/bash
# Macraft 构建脚本
# 用 Swift 命令行工具链编译并打包成标准 macOS .app 束（无需完整 Xcode）
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
APP_NAME="Macraft"
DIST="$ROOT/dist"
APP_BUNDLE="$DIST/$APP_NAME.app"

echo "==> 清理旧产物"
rm -rf "$APP_BUNDLE"

echo "==> 以 Release 模式编译"
swift build -c release

BIN="$ROOT/.build/release/$APP_NAME"
if [[ ! -f "$BIN" ]]; then
    echo "错误：找不到编译产物 $BIN" >&2
    exit 1
fi

echo "==> 组装 .app 束"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$ROOT/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# 图标（若存在）
if [[ -f "$ROOT/Resources/AppIcon.icns" ]]; then
    cp "$ROOT/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    echo "    已包含应用图标"
else
    echo "    提示：未找到 AppIcon.icns，使用系统默认图标"
fi

# 让二进制可执行
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

echo "==> 完成：$APP_BUNDLE"
echo "    可直接运行：open \"$APP_BUNDLE\""
