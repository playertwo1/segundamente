# Build Guide

Memex uses region flavors (`global`) and Android channel flavors
(`stable`, `early`, `dev`). Android currently defines six Gradle product
flavors. iOS currently defines two schemes: `global`.

## Flavors

### Android

| Flavor | Android Package | Channel | Intended Use |
|--------|-----------------|---------|--------------|
| `globalDev` | `com.memexlab.memex.dev` | Dev | Local overseas development; isolated package/data |
| `globalEarly` | `com.memexlab.memex.early` | Early | Overseas early/pre-release Android builds |
| `global` | `com.memexlab.memex` | Stable | Overseas stable release; avoid for local dev |

### iOS

| Flavor | iOS Bundle ID | Intended Use |
|--------|---------------|--------------|
| `global` | `com.memexlab.memex` | Overseas builds |

## Prerequisites

- Flutter SDK ≥ 3.6.0
- Xcode 15+ (iOS)
- Android Studio (Android)

```bash
git clone https://github.com/memex-lab/memex.git
cd memex
flutter pub get
cd ios && pod install && cd ..
```

## Run

### Android local development

```bash
# Overseas dev, isolated package/data
flutter run --flavor globalDev

# China dev, isolated package/data
```

### Android early or stable channels

```bash
flutter run --flavor globalEarly

# Stable release flavors; avoid for local development
flutter run --flavor global
```

### iOS

```bash
flutter run --flavor global
```

## Build

### Android

```bash
# Local debug APKs
flutter build apk --flavor globalDev --debug

# Release APKs
flutter build apk --flavor global --release
flutter build apk --flavor globalEarly --release

# Release App Bundles
flutter build appbundle --flavor global --release
flutter build appbundle --flavor globalEarly --release
```

Output path: `build/app/outputs/flutter-apk/memex_<flavor>_<version>_<build>.apk`

### iOS

```bash
flutter build ipa --flavor global --release
```

Or use the deploy script:

```bash
./deploy_ios.sh global
./deploy_ios.sh global
```

## Signing

### Android

Release signing configs live under `android/`. Dev flavors use debug signing for
debug builds and do not define release signing configs.

| Flavor(s) | Properties File | Signing Config |
|-----------|-----------------|----------------|
| `global` | `android/key-global.properties` | `globalRelease` |

Properties file format:

```properties
storeFile=<keystore-file>
storePassword=<your_password>
keyAlias=<your_alias>
keyPassword=<your_password>
```

Generate a new keystore:

```bash
keytool -genkeypair -v \
  -keystore android/app/<keystore-file> \
  -alias <your_alias> \
  -keyalg RSA -keysize 2048 \
  -validity 10000
```

View signing info (MD5 / SHA1 / SHA256):

```bash
keytool -list -v -keystore android/app/<keystore-file>
```

> ⚠️ Keystore and properties files are excluded in `.gitignore`. Never commit them to the repository.

### iOS

iOS signing is managed through your Apple Developer account. Register the App
IDs (`com.memexlab.memex`) and create Provisioning
Profiles in Xcode or the Apple Developer Portal.

## Flavor Detection in Dart

Use `AppFlavor` to branch on the current flavor at runtime:

```dart
import 'package:memex/config/app_flavor.dart';

if (AppFlavor.isDev) {
  // Development-channel logic
}
```
