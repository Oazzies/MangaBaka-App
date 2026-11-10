import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/features/series/services/series_title_enricher.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUpAll(() {
    AppTypography.setTestMode(true);
    // Tests must never reach the real API for canonical titles.
    SeriesTitleEnricher.shared = SeriesTitleEnricher.disabled();
  });
  tearDownAll(() {
    AppTypography.setTestMode(false);
  });
  await testMain();
}
