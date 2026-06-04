# Codemagic — имзои iOS (code signing)

## Хатои шумо

```
Did not find matching provisioning profiles for code signing!
Provisioning Profiles: []
No valid code signing certificates were found
```

Ин маънои онро дорад: **дар Codemagic сертификат/profile барои `com.grass.grass.app` нест.**

Pods ва prepare аллакай мегузаранд — танҳо **имзо** мондааст.

---

## Вариант 1 (тавсия): App Store Connect API key

### 1. Apple Developer

1. [developer.apple.com](https://developer.apple.com) → **Account** → **Integrations** → **App Store Connect API**
2. **Keys** → **+** → Role: **App Manager** (ё Admin)
3. `.p8` файлро зеркашӣ кунед, **Key ID** ва **Issuer ID**-ро нигоҳ доред

### 2. Codemagic

1. **Teams** → **Personal account / team** → **Team integrations**
2. **App Store Connect** → **Add key**
3. Ном (мисол): `grass_asc`
4. Issuer ID, Key ID, `.p8` upload

### 3. `codemagic.yaml`

Инро кушоед ва номи integration-ро иваз кунед:

```yaml
integrations:
  app_store_connect: grass_asc   # ҳамон ном дар Codemagic
environment:
  ios_signing:
    distribution_type: app_store   # TestFlight / App Store
    bundle_identifier: com.grass.grass.app
```

Барои тест дар дастгоҳ: `distribution_type: ad_hoc`

### 4. Push + build

```bash
git add codemagic.yaml
git commit -m "ci: enable iOS code signing"
git push
```

Workflow: **grass-ios**

---

## Вариант 2: дастӣ (certificate + profile)

1. Codemagic → **Code signing identities**
2. **iOS certificate** (.p12) + парол upload
3. **Provisioning profile** (.mobileprovision) барои `com.grass.grass.app`
4. Дар `codemagic.yaml` reference кунед (ба мувофиқи [документация](https://docs.codemagic.io/yaml-code-signing/signing-ios/))

---

## Санҷиш дар лог

Пас аз `xcode-project use-profiles` бояд набошад:

```
Provisioning Profiles: []
Signing Certificate: 
```

Бояд profile ва certificate пур бошанд.

---

## Bundle ID

Дар лоиҳа: **`com.grass.grass.app`** (`ios/Runner.xcodeproj`)

Дар Apple Developer/App Store Connect ҳамин ID бояд сабт шуда бошад.

---

## Огоҳии CocoaPods

`warn_for_unused_master_specs_repo` — танҳо огоҳинома, хато нест. Дар `Podfile` ислоҳ шуд.
