# Codemagic iOS — ҳалли хатои Podfile.lock

Агар `codemagic.yaml` дар git **небошад**, Codemagic workflow-и кӯҳна мезанад:
`flutter build ipa` → SPM → `pod install` → **хато**.

## Вариант 1 (тавсия): `codemagic.yaml` дар git

1. `git add codemagic.yaml app/ios/ci_prepare_pods.sh app/ios/Gemfile`
2. `git commit -m "ci: fix iOS CocoaPods order for Codemagic"`
3. `git push`
4. Codemagic → **App settings** → **Build** → **Use codemagic.yaml from the repository**
5. Workflow: **grass-ios**

## Вариант 2: танҳо UI (бе yaml)

**Pre-build script** (пурра иваз кунед):

```bash
#!/bin/bash
set -e
# Агар root = app/ бошад, cd app-ро незанед
if [ -f app/pubspec.yaml ]; then cd app; fi
flutter pub get
flutter build ios --config-only --release
cd ios
rm -rf Pods .symlinks
pod install --repo-update
cd ..
```

**Build script** (ба ҷои `flutter build ipa`):

```bash
#!/bin/bash
set -e
if [ -f app/pubspec.yaml ]; then cd app; fi
flutter build ipa --release --no-pub
```

**Муҳим:** дар UI қадами автоматии «Flutter build ipa»-ро хомӯш кунед, агар ду бор build мешавад.
