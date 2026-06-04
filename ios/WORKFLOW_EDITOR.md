# Codemagic — ҳамон усули қадим (Workflow Editor, бе yaml)

Агар пеш **`Workflow Editor`** кор мекард ва танҳо `flutter build ipa` мезадед — **ҳаминро баргардонед**.

`codemagic.yaml` дар git **лозим нест** (ва барои `savdo` файлҳои `grass/codemagic.yaml` дар репои дигар ҳам аср намекунанд).

---

## 1. Танзимоти Codemagic

1. **App settings → Build**
2. Интихоб кунед: **Workflow Editor** (на `codemagic.yaml`)
3. **Save**

Имзо (сертификат) — **ҳамон ҷо**, ки пеш кор мекард:
- Workflow → **iOS code signing** / App Store Connect / Certificates  
- Bundle ID: `com.grass.grass.app`

---

## 2. Build script (содда — мисли қадим)

Танҳо як қадам, агар хатои `Podfile.lock` набошад:

```bash
flutter pub get
flutter build ipa --release
```

---

## 3. Агар боз `Podfile.lock` ё SPM хато диҳад

**Pre-build script** (қабл аз build):

```bash
flutter config --no-enable-swift-package-manager
flutter pub get
flutter build ios --config-only --release --no-codesign
cd ios
rm -rf Pods .symlinks
pod install --repo-update
cd ..
```

**Build script** (ба ҷои `flutter build ipa` танҳо):

```bash
cd ios && pod install && cd ..
flutter build ipa --release --no-pub
```

Қадами дублии автоматии `Flutter build ipa`-ро **хомӯш** кунед.

---

## 4. Дар `pubspec.yaml` (дар git монад)

```yaml
flutter:
  config:
    enable-swift-package-manager: false
```

Ин барои хатои SPM/Podfile.lock аст, ба Workflow Editor зарар намерасонад.

---

## 5. `codemagic.yaml` дар репо

- Барои **`savdo`**: агар Workflow Editor истифода мебаред — `codemagic.yaml`-ро **push накунед** ё аз git нест кунед.
- `grass/codemagic.yaml` — танҳо барои репои **`grassback`** (папкаи `app/` зери root), на барои `savdo`.

---

## Хулоса

| Усул | Вақте |
|------|--------|
| **Workflow Editor** + `flutter build ipa` | Пеш норм буд, барои update-ҳои оддӣ |
| `codemagic.yaml` + скриптҳои дароз | Вақте хатоҳои Pods/SPM такрор шаванд |

Барои 2–3 тағйири оддӣ дар app — **Workflow Editor кофист**.
