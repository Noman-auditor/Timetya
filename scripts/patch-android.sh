#!/bin/bash
# ============================================================
# NORA TUNNEL — Patch Capacitor Android Project
# Adds VPN permissions, custom theme, SDK config
# ============================================================

set -e

echo "🔧 Patching Capacitor Android project for NORA TUNNEL..."
echo ""

# ---- Check android dir ----
if [ ! -d "android" ]; then
    echo "❌ android/ directory not found!"
    exit 1
fi

MANIFEST="android/app/src/main/AndroidManifest.xml"

# ---- 1. Patch AndroidManifest.xml ----
if [ -f "$MANIFEST" ]; then
    echo "  📝 Patching AndroidManifest.xml..."

    # Add VPN permissions (before <application)
    if ! grep -q "FOREGROUND_SERVICE" "$MANIFEST"; then
        sed -i 's|<application|    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />\n    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />\n    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />\n    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />\n    <application|' "$MANIFEST"
        echo "    ✅ Added VPN permissions"
    else
        echo "    ⏭️  VPN permissions already present"
    fi

    # Set usesCleartextTraffic to false
    if grep -q "usesCleartextTraffic" "$MANIFEST"; then
        sed -i 's|android:usesCleartextTraffic="true"|android:usesCleartextTraffic="false"|' "$MANIFEST"
        echo "    ✅ Disabled cleartext traffic"
    fi
else
    echo "  ⚠️  AndroidManifest.xml not found!"
fi

# ---- 2. Patch strings.xml ----
STRINGS_FILE="android/app/src/main/res/values/strings.xml"
if [ -f "$STRINGS_FILE" ]; then
    echo "  📝 Patching strings.xml..."
    sed -i 's|<string name="app_name">[^<]*</string>|<string name="app_name">NORA TUNNEL</string>|' "$STRINGS_FILE"
    sed -i 's|<string name="title_activity_main">[^<]*</string>|<string name="title_activity_main">NORA TUNNEL</string>|' "$STRINGS_FILE"
    echo "    ✅ Updated app name"
fi

# ---- 3. Patch styles.xml for dark theme ----
STYLES_FILE="android/app/src/main/res/values/styles.xml"
if [ -f "$STYLES_FILE" ]; then
    echo "  📝 Patching styles.xml for dark theme..."
    # Replace any existing windowBackground
    sed -i 's|android:windowBackground">[^<]*</item>|android:windowBackground">#06061a</item>|g' "$STYLES_FILE" 2>/dev/null || true
    echo "    ✅ Updated theme"
fi

# ---- 4. Add network_security_config.xml ----
SECURITY_DIR="android/app/src/main/res/xml"
mkdir -p "$SECURITY_DIR"
cat > "$SECURITY_DIR/network_security_config.xml" << 'XMLEOF'
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">localhost</domain>
    </domain-config>
</network-security-config>
XMLEOF
echo "  ✅ Added network security config"

# ---- 5. Patch app/build.gradle ----
APP_BUILD="android/app/build.gradle"
if [ -f "$APP_BUILD" ]; then
    echo "  📝 Patching app/build.gradle..."
    # Update compileSdk
    sed -i 's|compileSdk[[:space:]]*=.*|compileSdk 34|' "$APP_BUILD" 2>/dev/null || true
    sed -i 's|compileSdk[[:space:]].*|compileSdk 34|' "$APP_BUILD" 2>/dev/null || true
    # Update minSdk  
    sed -i 's|minSdk[[:space:]]*=.*|minSdk 29|' "$APP_BUILD" 2>/dev/null || true
    sed -i 's|minSdk[[:space:]].*|minSdk 29|' "$APP_BUILD" 2>/dev/null || true
    # Update targetSdk
    sed -i 's|targetSdk[[:space:]]*=.*|targetSdk 34|' "$APP_BUILD" 2>/dev/null || true
    sed -i 's|targetSdk[[:space:]].*|targetSdk 34|' "$APP_BUILD" 2>/dev/null || true
    echo "    ✅ Updated SDK versions (29-34)"
fi

# ---- 6. Patch root build.gradle ----
ROOT_BUILD="android/build.gradle"
if [ -f "$ROOT_BUILD" ]; then
    echo "  📝 Patching root build.gradle..."
    sed -i 's|com.android.tools.build:gradle:.*|com.android.tools.build:gradle:8.2.2"|' "$ROOT_BUILD" 2>/dev/null || true
    echo "    ✅ Updated AGP version"
fi

# ---- 7. Patch gradle-wrapper.properties ----
WRAPPER_PROPS="android/gradle/wrapper/gradle-wrapper.properties"
if [ -f "$WRAPPER_PROPS" ]; then
    echo "  📝 Patching gradle-wrapper.properties..."
    sed -i 's|distributionUrl=.*|distributionUrl=https\\://services.gradle.org/distributions/gradle-8.5-all.zip|' "$WRAPPER_PROPS"
    echo "    ✅ Updated Gradle to 8.5"
fi

# ---- 8. Patch gradle.properties ----
GRADLE_PROPS="android/gradle.properties"
if [ -f "$GRADLE_PROPS" ]; then
    echo "  📝 Ensuring gradle.properties has required properties..."
    if ! grep -q "android.useAndroidX=true" "$GRADLE_PROPS"; then
        echo "android.useAndroidX=true" >> "$GRADLE_PROPS"
    fi
    if ! grep -q "android.enableJetifier=true" "$GRADLE_PROPS"; then
        echo "android.enableJetifier=true" >> "$GRADLE_PROPS"
    fi
    echo "    ✅ Gradle properties OK"
fi

echo ""
echo "✅ Android project patched successfully!"
