# Release toolchain — Cineus

This document is the source of truth for the toolchain used to build and validate Cineus releases.

## Pinned Flutter baseline

- Flutter: **3.47.2 stable**
- Flutter revision: `d3b14c876900e553bc736ca19295fc09e3853e8e`
- Dart: Flutter 3.47.2 bundled Dart SDK
- Local version hint: `.flutter-version`

Do not validate a release with an arbitrary local Flutter installation. Use 3.47.2 or update this document, `.flutter-version`, `.metadata`, Android tooling and CI together in one dedicated toolchain upgrade.

## Android

- Minimum Android API: **24**
- Compile SDK: **36**
- Target SDK: **36**
- Java/JVM: **17**
- Gradle: **9.3.1**
- Android Gradle Plugin: **9.1.0**
- Kotlin Gradle Plugin: **2.4.0**
- NDK: **28.2.13676358**

The compile and target SDK values are explicit in `android/app/build.gradle.kts` so Google Play compliance cannot silently change because a developer has a different Flutter SDK installed.

Release signing credentials are intentionally not committed. CI validates the release build using the project's existing debug-signing fallback when no `android/key.properties` is present. A store upload must still use the real upload key.

## iOS

- Minimum deployment target: **iOS 15.0**
- Release builder: **Xcode 26 or newer**
- Required SDK: **iOS 26 or newer**
- CI runner: `macos-26`

`ios/Flutter/Debug.xcconfig`, `ios/Flutter/Release.xcconfig` and `ios/Flutter/AppFrameworkInfo.plist` keep the app and Flutter framework on the same iOS 15 minimum.

The CI iOS job builds with `--no-codesign`; App Store signing remains a release-machine/App Store Connect concern.

## Required validation

A release candidate must pass all CI jobs:

1. **Analyze & test** — `flutter analyze --fatal-infos` and the complete `flutter test` suite.
2. **Web release build** — `flutter build web --release`.
3. **Android API 36 release build** — `flutter build appbundle --release` under Java 17 and the pinned Android toolchain.
4. **iOS 26 SDK release build** — `flutter build ios --release --no-codesign` on a macOS 26 runner with Xcode/iOS SDK 26+.

The workflow lives in `.github/workflows/ci.yml` and runs for pushes to `main`, pull requests targeting `main`, manual dispatches, and the Phase 0 migration branch while it is being stabilized.

## Local smoke commands

```bash
flutter --version
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter build web --release
flutter build appbundle --release
```

On macOS with Xcode 26+:

```bash
xcodebuild -version
xcrun --sdk iphoneos --show-sdk-version
flutter build ios --release --no-codesign
```

When a toolchain upgrade is needed, perform it separately from product features so regressions can be attributed to infrastructure changes rather than gameplay changes.
