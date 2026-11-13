Looking to report an issue/bug or make a feature request? Please refer to the [README file](https://github.com/Oazzies/MangaBaka-App/blob/main/README.md).

---

Thanks for your interest in contributing to the MangaBaka app!


# Code contributions

Pull requests are welcome!

If you're interested in taking on [an open issue](https://github.com/Oazzies/MangaBaka-App/issues), please comment on it so others are aware.
You do not need to ask for permission nor an assignment.

## Prerequisites

Before you start, please note that the ability to use following technologies is **required** and that existing contributors will not actively teach them to you.

- [Flutter](https://flutter.dev/)
- [Dart](https://dart.dev/)

### Tools

- Any code editor
- Emulator or phone with developer options enabled to test changes.

### Linux Desktop Prerequisites

If developing or building for Linux, install the required native development libraries:

```sh
sudo apt update
sudo apt install -y ninja-build cmake clang pkg-config \
  libgtk-3-dev libblkid-dev liblzma-dev libsecret-1-dev libjsoncpp-dev
```

## Local setup

The app bundles a `.env` file as an asset, but the file itself is gitignored. On a fresh clone, create it before building or running tests (an empty file is enough unless you need OAuth login):

```sh
cp .env.example .env
```

Without it, `flutter build`, `flutter run`, and `flutter test` fail with `No file or variants found for asset: .env`.

## Workflow & Quality Checks

1. Create a feature branch from `main`.
2. Keep every human-written `.dart` file in `lib/` and `test/` **at or below 300 lines** (see [ARCHITECTURE.md](ARCHITECTURE.md)).
3. Use `LoggingService.logger` instead of `print()` / `debugPrint()`, and avoid silent `catch (_)` blocks.
4. When adding a new feature, place it under `lib/features/<feature_name>/` (`models/`, `services/`, `controllers/`, `screens/`, `widgets/`) and mirror its tests under `test/features/<feature_name>/`.
5. Before opening a PR, verify zero analyzer issues and passing tests:
   ```sh
   flutter analyze
   flutter test
   ```

## Getting help

- Join [the Discord server](https://mangabaka.org/discord) for online help and to ask questions while developing.

# Translations

Translations are currently done done within the app inside the [languages.json](https://github.com/Oazzies/MangaBaka-App/blob/main/assets/lang/languages.json) file. You can copy the english section and add your own language.


# Forks

Forks are allowed so long as they abide by [the project's LICENSE](https://github.com/Oazzies/MangaBaka-App/blob/main/LICENSE).

When creating a fork, remember to:

- To avoid confusion with the main app:
    - Change the name in pubspec.yaml
    - Change the App Icon (currently located in [assets/](https://github.com/Oazzies/MangaBaka-App/tree/main/assets) and updated via the [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) package if you use it).
- To avoid installation conflicts:
    - Android: Change the applicationId in [android/app/build.gradle](https://github.com/Oazzies/MangaBaka-App/blob/main/android/app/build.gradle.kts).
    - iOS: Change the PRODUCT_BUNDLE_IDENTIFIER in [ios/Runner.xcodeproj/project.pbxproj](https://github.com/Oazzies/MangaBaka-App/blob/main/ios/Runner.xcodeproj/project.pbxproj) (or via Xcode).
