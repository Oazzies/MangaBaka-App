# Architecture

MangaBaka App follows a **Feature-First** architecture built on native Flutter state primitives (`ChangeNotifier`, `ValueNotifier`, `ListenableBuilder`, `ValueListenableBuilder`) and `get_it` for dependency injection.

## Directory Layout

```text
lib/
├── core/
│   ├── constants/     # App-wide constants, endpoints, status icons
│   ├── database/      # Drift local database & DAOs
│   ├── di/            # get_it service locator setup (service_locator.dart)
│   ├── exceptions/    # Typed AppException hierarchy
│   ├── localization/  # LocalizationService & language loading
│   ├── logging/       # Centralized LoggingService (logging package + ring buffer)
│   ├── motion/        # Shared animation durations & curves
│   ├── network/       # ApiClient, retry/rate-limit policy, backend health
│   ├── settings/      # SettingsManager & persisted preferences
│   ├── theme/         # AppTheme, AppTypography, MbPalette presets
│   ├── utils/         # Shared helpers, formatters, search normalization
│   └── widgets/       # Reusable design-system primitives (Mb*, dialogs, banners)
├── desktop/           # Desktop-specific shell, screens, and pointer widgets
├── features/
│   └── <feature>/     # appearance, browse, collections, deeplinks, home,
│                      # library, navigation, news, profile, publisher,
│                      # series, stacks, updates
│       ├── controllers/   # Feature state controllers (ChangeNotifier)
│       ├── models/        # Data models & DTOs
│       ├── screens/       # Route-level screens
│       ├── services/      # Repositories & API/DB services
│       └── widgets/       # Feature-scoped widgets
├── shared/            # Cross-feature navigation transitions & shared UI
└── main.dart          # App entrypoint & root widget
```

## State Management & Dependency Injection

- **Service Locator (`lib/core/di/service_locator.dart`):** Services and repositories are registered as `registerLazySingleton`, and screen-scoped controllers are resolved via `registerFactory` or injected through constructors at the screen boundary.
- **No `getIt<T>()` in Deep Children:** Child widgets receive dependencies or callbacks through their constructors rather than reaching into `getIt` directly.
- **Native Primitives:** Controllers extend `ChangeNotifier` or expose `ValueNotifier`s, listened to narrowly via `ListenableBuilder` / `ValueListenableBuilder` to keep rebuilds scoped.
- **Lifecycle:** Stateful controllers, `TextEditingController`s, `ScrollController`s, and `AnimationController`s are disposed when their owning state or screen unmounts, and async callbacks check `mounted` before calling `setState` or using `BuildContext`.

## Error Handling & Logging

- **Typed Exceptions (`lib/core/exceptions/`):** Network, auth, parsing, and database failures map to typed `AppException` subclasses.
- **Logging (`lib/core/logging/logging_service.dart`):** All logs flow through `LoggingService.logger` (never raw `print()` or `debugPrint()`), with sensitive credentials and auth tokens omitted. Silent `catch (_) {}` blocks are avoided.

## Coding & Testing Conventions

- **Semi-Strict 300-Line Limit:** Every human-written `.dart` file in `lib/` and `test/` (excluding generated `.g.dart`, `.freezed.dart`, `.mocks.dart`) must be **≤ 300 lines**. Large screens or widgets are split into cohesive `part` files or extracted sub-widgets/helpers. Its just, if you are over it then its better to split things up.
- **Mirror Tests (`test/`):** Unit and widget tests mirror the `lib/` feature structure (`test/core/`, `test/features/<feature>/`, `test/desktop/`, `test/responsive/`), using interfaces/fakes rather than live network calls.
