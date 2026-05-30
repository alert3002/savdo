# Codemagic iOS — хатои Podfile.lock

## Аломат

```
Adding Swift Package Manager integration... 45s
Running pod install... 860ms
Error: The sandbox is not in sync with the Podfile.lock
```

Ин маънои онро дорад, ки **workflow-и кӯҳна** истифода мешавад (`flutter build ipa` дар UI), на `codemagic.yaml`.

---

## Ҳал (тавсия)

### 1. Push файлу

```bash
git add pubspec.yaml codemagic.yaml scripts/codemagic_build_ios.sh ios/
git commit -m "ci: disable SPM, fix CocoaPods sync for iOS"
git push
```

### 2. Codemagic settings

1. **App settings → Build → Use codemagic.yaml from the repository** = ON
2. Workflow: **grass-ios**
3. **Хомӯш кунед** қадами автоматии:
   - `Flutter build ipa`
   - `Build` (агар дубли мешавад)

### 3. Санҷиш дар лог

Бояд аввалин сатр бошад:

```
=== GRASS iOS BUILD (custom script) ===
```

Агар ин сатр **набошад** — yaml ҳанӯз истифода намешавад.

---

## Вариант 2: танҳо UI (бе yaml)

**Як Pre-build script** (пурра):

```bash
#!/bin/bash
set -e
flutter config --no-enable-swift-package-manager
flutter pub get
flutter config --no-enable-swift-package-manager
flutter build ios --config-only --release --no-codesign
cd ios
rm -rf Pods .symlinks
pod install --repo-update
cd ..
```

**Як Build script**:

```bash
#!/bin/bash
set -e
cd ios && pod install && cd ..
flutter build ipa --release --no-pub
```

Қадами автоматии `flutter build ipa`-ро **хомӯш** кунед.

---

## Чаро SPM хомӯш кардем?

Дар `pubspec.yaml`:

```yaml
flutter:
  config:
    enable-swift-package-manager: false
```

Firebase ва плагинҳо бо **CocoaPods** кор мекунанд; ин хатои sync-ро дар Codemagic бартараф мекунад.
