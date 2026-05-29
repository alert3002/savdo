#!/bin/sh
# macOS / Codemagic: синхрони CocoaPods ПОСЛЕ flutter build ios --config-only
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

flutter pub get
flutter build ios --config-only --release

cd ios
rm -rf Pods Podfile.lock .symlinks
pod repo update
pod install --repo-update

echo "OK. Next: flutter build ipa --release --no-pub"
echo "Commit Podfile.lock: git add ios/Podfile.lock"
