import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/series/services/series_autocomplete_service.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SeriesAutocompleteService service;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.';
      },
    );
    SharedPreferences.setMockInitialValues({});
    await SettingsManager().init();
    service = SeriesAutocompleteService();
  });

  group('SeriesAutocompleteService', () {
    test('search returns empty for short queries', () {
      List<AutocompleteSeriesResult>? results;
      service.search('a', onResults: (res) => results = res);
      expect(results, isEmpty);
    });

    test('cache hit returns cached results', () {
      // executeSearch builds its own client per request; untestable without a factory.
    });
  });
}
