Looking to report an issue/bug or make a feature request? Please refer to the [README file](https://github.com/Oazzies/BakaHyou/blob/main/README.md).

---

Thanks for your interest in contributing to BakaHyou!


# Code contributions

Pull requests are welcome!

If you're interested in taking on [an open issue](https://github.com/Oazzies/BakaHyou/issues), please comment on it so others are aware.
You do not need to ask for permission nor an assignment.

## Prerequisites

Before you start, please note that the ability to use following technologies is **required** and that existing contributors will not actively teach them to you.

- [Flutter](https://flutter.dev/)
- [Dart](https://dart.dev/)

### Tools

- Any code editor
- Emulator or phone with developer options enabled to test changes.

## Getting help

- Join [the Discord server](https://mangabaka.org/discord) for online help and to ask questions while developing.

# Translations

Translations are currently done done within the app inside the [languages.json](https://github.com/Oazzies/BakaHyou/blob/main/assets/lang/languages.json) file. You can copy the english section and add your own language.


# Forks

Forks are allowed so long as they abide by [the project's LICENSE](https://github.com/Oazzies/BakaHyou/blob/main/LICENSE).

When creating a fork, remember to:

- To avoid confusion with the main app:
    - Change the name in pubspec.yaml
    - Change the App Icon (currently located in [assets/](https://github.com/Oazzies/BakaHyou/tree/main/assets) and updated via the [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) package if you use it).
- To avoid installation conflicts:
    - Android: Change the applicationId in [android/app/build.gradle](https://github.com/Oazzies/BakaHyou/blob/main/android/app/build.gradle.kts).
    - iOS: Change the PRODUCT_BUNDLE_IDENTIFIER in [ios/Runner.xcodeproj/project.pbxproj](https://github.com/Oazzies/BakaHyou/blob/main/ios/Runner.xcodeproj/project.pbxproj) (or via Xcode).
