import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/database/database.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/backend_health_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_theme.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/presets/theme_presets.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/shell/desktop_shell.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_window_frame.dart';
import 'package:mangabaka_app/features/browse/services/book_lookup_service.dart';
import 'package:mangabaka_app/features/browse/services/mix_service.dart';
import 'package:mangabaka_app/features/collections/services/collection_service.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/news/services/news_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/services/snapshot_service.dart';
import 'package:mangabaka_app/features/publisher/services/publisher_search_service.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/features/updates/services/update_service.dart';
import 'package:mangabaka_app/shared/widgets/app_shortcuts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';
import 'fake_services.dart';
import 'fixtures.dart';

/// The state of the world a sweep runs in.
class Environment {
  final bool signedIn;

  /// Whether the backend (and the signed-in library) hold data.
  final bool populated;

  /// `en`, or `de` — the language whose strings run longest.
  final String language;

  final AppListStyle listStyle;

  const Environment({
    this.signedIn = true,
    this.populated = true,
    this.language = 'en',
    this.listStyle = AppListStyle.comfortable,
  });

  String get label => [
    signedIn ? 'signed in' : 'signed out',
    if (!populated) 'empty',
    language,
    if (listStyle != AppListStyle.comfortable) listStyle.name,
  ].join(', ');
}

/// Loads the fonts the app bundles, so text measures as it does for users
/// rather than in the test font, where every glyph is a 1em square.
Future<void> loadAppFonts() async {
  AppTypography.setTestMode(false);
  const fonts = {
    'BakbakOne': ['assets/fonts/BakbakOne-Regular.ttf'],
    'Outfit': [
      'assets/fonts/Outfit-Regular.ttf',
      'assets/fonts/Outfit-Medium.ttf',
      'assets/fonts/Outfit-SemiBold.ttf',
      'assets/fonts/Outfit-Bold.ttf',
    ],
    'PhosphorRegular': ['assets/fonts/Phosphor-Regular.ttf'],
    'PhosphorFill': ['assets/fonts/Phosphor-Fill.ttf'],
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      loader.addFont(rootBundle.load(path));
    }
    await loader.load();
  }
  // Icons measure the same either way (a square the icon's size), but load
  // the real glyphs when the SDK has them, for faithful screenshots.
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final icons = File(
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (icons.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
      await loader.load();
    }
  }
}

/// Sets up [env]: preferences, translations, the fake backend and every
/// service the desktop pages reach for. Call from `setUp` (real async — the
/// translation files are large enough to be decoded on an isolate).
Future<FakeBackend> setUpEnvironment(Environment env) async {
  SharedPreferences.setMockInitialValues({});
  SettingsManager.resetForTesting();
  await SettingsManager().init();
  await SettingsManager().setListStyle(env.listStyle);

  LocalizationService.resetForTesting();
  await LocalizationService().init();
  if (env.language != 'en') {
    await LocalizationService().setLanguage(env.language);
  }

  DesktopLayout.debugOverride = null;
  DesktopWindowFrame.debugOverride = true;

  final backend = FakeBackend(populated: env.populated);
  HttpOverrides.global = backend;

  final library = env.populated ? Fixtures.library(60) : <LibraryEntry>[];

  await resetServiceLocator();
  getIt
    ..registerSingleton<LoggingService>(LoggingService())
    ..registerSingleton<BackendHealthService>(
      BackendHealthService(),
      dispose: (s) => s.dispose(),
    )
    ..registerSingleton<AppDatabase>(
      AppDatabase.forTesting(NativeDatabase.memory()),
      dispose: (db) => db.close(),
    )
    ..registerSingleton<ProfileAuthService>(FakeAuth(signedIn: env.signedIn))
    ..registerSingleton<MetadataService>(MetadataService())
    ..registerSingleton<SnapshotService>(FakeSnapshots(library))
    ..registerLazySingleton<SeriesService>(SeriesService.new)
    ..registerLazySingleton<SeriesSearchService>(SeriesSearchService.new)
    ..registerSingleton<LibraryService>(FakeLibrary(library))
    ..registerLazySingleton<NewsService>(NewsService.new)
    ..registerLazySingleton<PublisherSearchService>(PublisherSearchService.new)
    ..registerLazySingleton<CollectionService>(CollectionService.new)
    ..registerLazySingleton<MixService>(MixService.new)
    ..registerLazySingleton<BookLookupService>(BookLookupService.new)
    ..registerLazySingleton<UpdateService>(UpdateService.new);
  return backend;
}

Future<void> tearDownEnvironment() async {
  await resetServiceLocator();
  HttpOverrides.global = null;
  DesktopWindowFrame.debugOverride = null;
  DesktopLayout.debugOverride = null;
}

/// The app as `main.dart` assembles it for a desktop window: the custom
/// window frame (title bar and window buttons over the content) around the
/// desktop shell open at [destination].
Widget desktopApp({int destination = 0}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.build(inkPalette, showTooltips: true),
  builder: (context, child) => DesktopLayoutScope(
    child: DesktopWindowFrame(child: AppShortcuts(child: child!)),
  ),
  home: DesktopShell(initialIndex: destination),
);

/// Lets the app's loading finish: real async for isolate work (JSON decoding,
/// the database) interleaved with frames for everything scheduled on them.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Tears the app down and flushes timers it left behind (debounces, entrance
/// animations), so the test ends clean.
Future<void> disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 5));
}
