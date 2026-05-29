#!/bin/sh
# Run on macOS before `flutter build ipa` (Codemagic pre-build or locally).
set -e
cd "$(dirname "$0")"

rm -rf Pods Podfile.lock .symlinks
pod repo update
pod install --repo-update

echo "CocoaPods synced. Commit Podfile.lock after local builds:"
echo "  git add Podfile.lock && git commit -m 'chore(ios): update Podfile.lock'"
