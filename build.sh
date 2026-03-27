#!/bin/bash
set -e

echo "Building MacTapa..."
swift build -c release

APP_NAME="MacTapa"
APP_DIR="$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

# Clean previous build
rm -rf "$APP_DIR"

# Create .app bundle structure
mkdir -p "$MACOS" "$RESOURCES"

# Copy binary
cp .build/release/MacTapa "$MACOS/MacTapa"

# Copy Info.plist
cp Sources/MacTapa/Info.plist "$CONTENTS/Info.plist"

# Copy sound resources
cp -R Resources/Sounds "$RESOURCES/Sounds"

echo ""
echo "Built $APP_DIR successfully!"
echo ""
echo "To run: sudo $APP_DIR/Contents/MacOS/MacTapa"
echo "Or:     sudo open $APP_DIR"
