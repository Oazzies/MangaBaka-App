import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_theme.dart';
import 'package:mangabaka_app/core/theme/presets/theme_presets.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/navigation/models/nav_destinations.dart';
import 'package:mangabaka_app/features/navigation/screens/main_screen.dart';
import 'package:mangabaka_app/features/profile/services/snapshot_service.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';

import '../responsive/support/fake_services.dart';
import '../responsive/support/test_app.dart';
import 'support/screenshot_fixtures.dart';

void main() {
  final writeFiles = Platform.environment['GENERATE_SCREENSHOTS'] == '1';
  final outputDir =
      Platform.environment['SCREENSHOT_OUTPUT_DIR'] ??
      'build/readme-screenshots';

  setUpAll(() async {
    await loadAppFonts();
  });

  setUp(() async {
    await setUpEnvironment(const Environment());
    await SettingsManager().setDefaultStartPage(AppStartPage.library);

    final library = sampleLibrary();
    await getIt.unregister<LibraryService>();
    await getIt.unregister<SnapshotService>();
    getIt
      ..registerSingleton<LibraryService>(FakeLibrary(library))
      ..registerSingleton<SnapshotService>(FakeSnapshots(library));

    HttpOverrides.global = ScreenshotBackend();
  });

  tearDown(() async {
    await tearDownEnvironment();
  });

  testWidgets('renders README preview screens at phone viewport', (
    tester,
  ) async {
    usePhoneView(tester);
    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(inkPalette, showTooltips: false),
          home: MainScreen(),
        ),
      ),
    );
    await settle(tester);

    for (final (tab, file) in [
      (NavTabs.library, '01_library.png'),
      (NavTabs.browse, '02_browse.png'),
      (NavTabs.news, '04_news.png'),
    ]) {
      MainScreen.setTabIndex(tab);
      await settle(tester);
      await captureBoundary(tester, boundaryKey, file, writeFiles, outputDir);
    }

    // Series detail runs as a separate test so MainScreen disposes cleanly.
    await disposeApp(tester);
  });

  testWidgets('renders SeriesDetailScreen at phone viewport', (tester) async {
    usePhoneView(tester);
    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(inkPalette, showTooltips: false),
          home: SeriesDetailScreen(series: featuredSeries()),
        ),
      ),
    );
    await settle(tester);
    await captureBoundary(
      tester,
      boundaryKey,
      '03_series_detail.png',
      writeFiles,
      outputDir,
    );

    await disposeApp(tester);
  });
}
