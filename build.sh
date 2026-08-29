#!/bin/bash
echo "Cloning Flutter..."
git clone https://github.com/flutter/flutter.git -b stable
echo "Adding Flutter to PATH..."
export PATH="$PATH:$PWD/flutter/bin"
echo "Building Flutter Web..."
flutter build web --release
