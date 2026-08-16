#!/bin/bash
set -e
echo "Downloading Flutter SDK..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1 ../flutter_sdk
export PATH="$PATH:$(pwd)/../flutter_sdk/bin"

echo "Checking Flutter version..."
flutter --version

echo "Building Flutter Web release..."
BACKEND_URL="${API_BASE_URL:-https://forensiq-backend.onrender.com}"
flutter build web --release --dart-define=API_BASE_URL="$BACKEND_URL"

echo "Build complete!"
