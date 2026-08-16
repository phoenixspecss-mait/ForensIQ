#!/bin/bash
set -e

# Ensure script is operating inside the frontend directory containing pubspec.yaml & lib/main.dart
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "Current directory: $(pwd)"
echo "Directory contents:"
ls -la

echo "Downloading Flutter SDK..."
if [ ! -d "../flutter_sdk" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 ../flutter_sdk
fi
export PATH="$(pwd)/../flutter_sdk/bin:$PATH"

echo "Checking Flutter version..."
flutter --version

echo "Building Flutter Web release..."
BACKEND_URL="${API_BASE_URL:-https://forensiq-backend.onrender.com}"
flutter build web lib/main.dart --release --dart-define=API_BASE_URL="$BACKEND_URL"

echo "Build complete!"
