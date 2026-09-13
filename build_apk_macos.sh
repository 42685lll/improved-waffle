#!/bin/bash
# ============================================
#   StarHoshino - 本地 APK 构建脚本 (macOS/Linux)
# ============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  StarHoshino - 本地 APK 构建脚本${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""

# === 1. 检查环境 ===
echo -e "${YELLOW}[1/6]${NC} 检查环境..."

# Android SDK
if [ -z "$ANDROID_HOME" ] && [ -z "$ANDROID_SDK_ROOT" ]; then
    # 尝试常见路径
    if [ -d "$HOME/Library/Android/sdk" ]; then
        export ANDROID_HOME="$HOME/Library/Android/sdk"
    elif [ -d "$HOME/Android/Sdk" ]; then
        export ANDROID_HOME="$HOME/Android/Sdk"
    else
        echo -e "${RED}[ERROR]${NC} 未找到 ANDROID_HOME"
        echo "请设置环境变量 ANDROID_HOME 指向你的 Android SDK 目录"
        echo "常见位置："
        echo "  macOS:   ~/Library/Android/sdk"
        echo "  Linux:   ~/Android/Sdk"
        echo "  Windows: %LOCALAPPDATA%\\Android\\Sdk"
        exit 1
    fi
fi

[ -z "$ANDROID_HOME" ] && export ANDROID_HOME="$ANDROID_SDK_ROOT"

echo "  ANDROID_HOME = $ANDROID_HOME"

# Java
if ! command -v java &> /dev/null; then
    echo -e "${RED}[ERROR]${NC} 未安装 Java JDK 17"
    echo "安装方式："
    echo "  macOS:  brew install openjdk@17"
    echo "  Linux:  sudo apt install openjdk-17-jdk"
    exit 1
fi

# === 2. 检查 SDK 组件 ===
echo ""
echo -e "${YELLOW}[2/6]${NC} 检查 SDK 组件..."

SDK_MANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
if [ ! -f "$SDK_MANAGER" ]; then
    SDK_MANAGER="$ANDROID_HOME/tools/bin/sdkmanager"
fi

if [ -f "$SDK_MANAGER" ]; then
    echo "y" | "$SDK_MANAGER" --sdk_root="$ANDROID_HOME" "platforms;android-35" "build-tools;35.0.0" "platform-tools" 2>/dev/null || true
else
    echo -e "${YELLOW}[WARN]${NC} sdkmanager 未找到，请确保已安装："
    echo "  platforms;android-35"
    echo "  build-tools;35.0.0"
    echo "  platform-tools"
fi

# === 3. 检查/生成 gradle wrapper ===
echo ""
echo -e "${YELLOW}[3/6]${NC} 检查 Gradle Wrapper..."

if [ ! -f "gradlew" ]; then
    echo "未找到 gradlew..."
    if command -v gradle &> /dev/null; then
        gradle wrapper --gradle-version 8.7
    else
        echo -e "${YELLOW}[WARN]${NC} 未安装 Gradle，尝试下载..."
        GRADLE_ZIP="gradle-8.7-bin.zip"
        GRADLE_URL="https://services.gradle.org/distributions/${GRADLE_ZIP}"
        
        if command -v curl &> /dev/null; then
            curl -L -o "$GRADLE_ZIP" "$GRADLE_URL"
        elif command -v wget &> /dev/null; then
            wget -O "$GRADLE_ZIP" "$GRADLE_URL"
        else
            echo -e "${RED}[ERROR]${NC} 需要 curl 或 wget 来下载 Gradle"
            echo "或者直接安装 Gradle: https://gradle.org/install/"
            exit 1
        fi
        
        mkdir -p gradle
        unzip -q "$GRADLE_ZIP" -d gradle
        export PATH="$(pwd)/gradle/gradle-8.7/bin:$PATH"
    fi
fi

# === 4. 准备构建 ===
echo ""
echo -e "${YELLOW}[4/6]${NC} 准备构建..."

if [ -f "gradlew" ]; then
    chmod +x gradlew
    GRADLE_CMD="./gradlew"
else
    GRADLE_CMD="gradle"
fi

# === 5. 构建 APK ===
echo ""
echo -e "${YELLOW}[5/6]${NC} 开始构建 APK..."

echo "选择构建类型："
echo "  1) Debug (推荐首版测试)"
echo "  2) Release (需要签名配置)"
read -p "请输入选项 (默认 1): " BUILD_CHOICE

if [ "$BUILD_CHOICE" = "2" ]; then
    echo "构建 Release APK..."
    $GRADLE_CMD assembleRelease --no-daemon --stacktrace
    APK_DIR="app/build/outputs/apk/release"
else
    echo "构建 Debug APK..."
    $GRADLE_CMD assembleDebug --no-daemon --stacktrace
    APK_DIR="app/build/outputs/apk/debug"
fi

# === 6. 显示结果 ===
echo ""
echo -e "${YELLOW}[6/6]${NC} 构建完成！"
echo "============================================"
echo -e "${GREEN}APK 输出位置：${NC}"
echo ""

if [ -d "$APK_DIR" ]; then
    ls -la "$APK_DIR"/*.apk 2>/dev/null || echo "未找到 APK 文件"
else
    echo "未找到输出目录: $APK_DIR"
    echo "尝试查找所有 APK..."
    find . -name "*.apk" -type f 2>/dev/null
fi

echo ""
echo "============================================"
echo -e "${GREEN}安装到设备：${NC}"
echo "  adb install -r $APK_DIR/app-debug.apk"
echo ""
echo -e "${GREEN}或直接拖拽 APK 到手机安装${NC}"
echo ""
