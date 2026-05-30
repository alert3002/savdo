#!/bin/sh
# macOS / Codemagic: синхрони CocoaPods ПОСЛЕ flutter build ios --config-only
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

flutter pub get
flutter build ios --config-only --release

cd ios
rm -rf Pods .symlinks
if [ -f Gemfile ]; then
  bundle install
  bundle exec pod install --repo-update
else
  pod install --repo-update
fi

echo "OK. Next:"
echo "  cd .. && flutter build ipa --release --no-pub"
echo "Optional: git add ios/Podfile.lock && git commit"
