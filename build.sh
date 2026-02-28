#!/bin/bash

# 拼音大冒险 - 一键打包 DMG 脚本
# 用法：./build.sh

set -e

echo "🚀 开始编译 Release 版本..."

# 编译 Release 版本
xcodebuild -project xuedazi.xcodeproj -scheme xuedazi -configuration Release build

echo "✅ 编译成功！"

# 查找 Release 产物
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -path "*/Release/xuedazi.app" -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ 错误：找不到编译产物"
    exit 1
fi

echo "📦 找到应用：$APP_PATH"

# 创建临时打包目录
DIST_DIR="./build/dist"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# 复制.app
echo "📋 复制应用..."
cp -R "$APP_PATH" "$DIST_DIR/xuedazi.app"

# 创建 DMG
echo "💿 创建 DMG 文件..."
DMG_NAME="拼音大冒险-$(date +%Y%m%d).dmg"
hdiutil create -volname "拼音大冒险" -srcfolder "$DIST_DIR" -ov -format UDZO "$DMG_NAME"

# 显示结果
echo ""
echo "========================================"
echo "✅ 打包完成！"
echo "========================================"
echo ""
ls -lh "$DMG_NAME"
echo ""
echo "📦 DMG 文件：$DMG_NAME"
echo "📱 App 大小：$(du -sh "$DIST_DIR/xuedazi.app" | cut -f1)"
echo ""
echo "🎉 可以直接发送给好友了！"
