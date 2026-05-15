#!/bin/bash

# Configuration
APP_NAME="TahoeCape"
BUNDLE_NAME="${APP_NAME}.app"

echo "🚀 Building TahoeCape..."

# 1. Build the Swift Package
swift build -c release

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

# Find the binary
BINARY_PATH=$(swift build -c release --show-bin-path)/${APP_NAME}

# 2. Create the App Bundle structure
mkdir -p "${BUNDLE_NAME}/Contents/MacOS"
mkdir -p "${BUNDLE_NAME}/Contents/Resources"

# 3. Copy the binary
cp "${BINARY_PATH}" "${BUNDLE_NAME}/Contents/MacOS/"

# 4. Copy the Icon if it exists
if [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "${BUNDLE_NAME}/Contents/Resources/"
fi

# 5. Create Info.plist
cat > "${BUNDLE_NAME}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.tahoecape.app</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "✅ ${BUNDLE_NAME} created successfully!"
