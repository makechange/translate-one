#!/bin/bash

# Exit on error
set -e

echo "=== TranslateOne Build Script ==="

# Define target app structure
APP_NAME="TranslateOne"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"

echo "1. Cleaning previous build..."
rm -rf "${APP_BUNDLE}"
rm -f "${APP_NAME}"

echo "2. Compiling Swift sources..."
SDK_PATH=$(xcrun --show-sdk-path)
swiftc -O -sdk "${SDK_PATH}" \
    -o "${APP_NAME}" \
    main.swift \
    AppDelegate.swift \
    HotkeyManager.swift \
    ServiceProvider.swift \
    TranslationHUDController.swift \
    TranslationHUDView.swift \
    Language.swift

echo "3. Creating application bundle structure..."
mkdir -p "${MACOS}"
mkdir -p "${RESOURCES}"

echo "4. Moving executable and resources..."
mv "${APP_NAME}" "${MACOS}/"
cp Info.plist "${CONTENTS}/"
if [ -f AppIcon.icns ]; then
    cp AppIcon.icns "${RESOURCES}/"
fi

echo "5. Code-signing the bundle (Ad-Hoc)..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "=== Build Successful! ==="
echo "You can launch the app by running: open ${APP_BUNDLE}"
echo "Or double-click ${APP_BUNDLE} in Finder."
