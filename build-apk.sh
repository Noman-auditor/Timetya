#!/bin/bash
# ============================================================
# NORA TUNNEL — Local APK Build Script
# ============================================================

set -e

echo ""
echo "🛡️  NORA TUNNEL — APK Build"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ---- Prerequisites Check ----
echo "🔍 Checking prerequisites..."

if command -v node &> /dev/null; then
    echo "  ✅ Node.js: $(node --version)"
else
    echo "  ❌ Node.js not found → https://nodejs.org"
    exit 1
fi

if command -v java &> /dev/null; then
    echo "  ✅ Java: $(java -version 2>&1 | head -1)"
else
    echo "  ❌ Java 17 not found → https://adoptium.net"
    exit 1
fi

if [ -n "$ANDROID_HOME" ]; then
    echo "  ✅ Android SDK: $ANDROID_HOME"
elif [ -d "$HOME/Android/Sdk" ]; then
    export ANDROID_HOME="$HOME/Android/Sdk"
    echo "  ✅ Android SDK: $ANDROID_HOME"
else
    echo "  ⚠️  ANDROID_HOME not set"
    echo "     Install Android Studio: https://developer.android.com/studio"
    echo "     Then: export ANDROID_HOME=\$HOME/Android/Sdk"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ---- Step 1: NPM Install ----
echo ""
echo "📦 [1/6] Installing dependencies..."
npm install

# ---- Step 2: Build Web ----
echo ""
echo "🌐 [2/6] Building web app..."
npm run build

# ---- Step 3: Add Android Platform ----
echo ""
echo "📱 [3/6] Setting up Android platform..."
if [ -d "android" ]; then
    echo "  Android platform exists — removing and re-adding for clean state..."
    rm -rf android
fi
npx cap add android

# ---- Step 4: Sync ----
echo ""
echo "🔄 [4/6] Syncing Capacitor..."
npx cap copy android
npx cap sync android

# ---- Step 5: Patch ----
echo ""
echo "🔧 [5/6] Patching Android project..."
chmod +x scripts/patch-android.sh
bash scripts/patch-android.sh

# ---- Step 6: Build APK ----
echo ""
echo "🔨 [6/6] Building APK..."
cd android
chmod +x gradlew

BUILD_TYPE="${1:-debug}"

if [ "$BUILD_TYPE" = "release" ]; then
    echo "  Building RELEASE APK..."
    ./gradlew assembleRelease --no-daemon
    APK_PATH="app/build/outputs/apk/release/app-release-unsigned.apk"
else
    echo "  Building DEBUG APK..."
    ./gradlew assembleDebug --no-daemon
    APK_PATH="app/build/outputs/apk/debug/app-debug.apk"
fi

cd ..

# ---- Result ----
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "android/$APK_PATH" ]; then
    SIZE=$(du -h "android/$APK_PATH" | cut -f1)
    echo "✅ APK Build Complete!"
    echo ""
    echo "📱 Path: android/$APK_PATH"
    echo "📊 Size: $SIZE"
    echo ""
    echo "📲 Install:"
    echo "  1. Transfer APK to your Android device"
    echo "  2. Enable 'Install from unknown sources'"
    echo "  3. Install the APK"
else
    echo "❌ APK build failed!"
    exit 1
fi
