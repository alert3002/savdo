#!/bin/bash
# Codemagic iOS — як скрипт. Дар UI танҳо инро истифода баред (flutter build ipa-и автоматиро хомӯш кунед).
set -euo pipefail

echo "=== GRASS iOS BUILD (custom script) ==="

if [ -f pubspec.yaml ]; then
  APP_DIR=.
elif [ -f app/pubspec.yaml ]; then
  APP_DIR=app
else
  echo "ERROR: pubspec.yaml not found"; exit 1
fi
cd "$APP_DIR"
echo "APP_DIR=$APP_DIR"

# Танҳо CocoaPods — бе SPM (ина хатои Podfile.lock-ро бартараф мекунад)
flutter config --no-enable-swift-package-manager

flutter pub get
# Бе имзо — барои CI (ина сертификат намехоҳад)
flutter build ios --config-only --release --no-codesign

cd ios
rm -rf Pods .symlinks
if [ -f Gemfile ]; then
  bundle install --quiet
  bundle exec pod install --repo-update
else
  pod install --repo-update
fi
cd ..

# Sync пеш аз archive
cd ios && pod install && cd ..

# Имзо — бояд дар codemagic.yaml: integrations.app_store_connect + ios_signing
if command -v xcode-project >/dev/null 2>&1; then
  xcode-project use-profiles
else
  echo "WARN: xcode-project not found, signing may fail"
fi

if ! security find-identity -v -p codesigning 2>/dev/null | grep -qE "Apple (Distribution|Development)"; then
  echo "ERROR: No Apple code signing certificate in keychain."
  echo "See ios/CODEMAGIC_SIGNING.md — add App Store Connect API key in Codemagic."
  exit 1
fi

if [ -f /Users/builder/export_options.plist ]; then
  flutter build ipa --release --no-pub \
    --export-options-plist=/Users/builder/export_options.plist
else
  flutter build ipa --release --no-pub
fi

echo "=== GRASS iOS BUILD DONE ==="
