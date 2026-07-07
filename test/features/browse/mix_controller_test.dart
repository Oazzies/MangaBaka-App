import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/browse/controllers/mix_controller.dart';
import 'package:mangabaka_app/features/browse/models/mix_result.dart';
import 'package:mangabaka_app/features/browse/services/mix_service.dart';
import 'package:mangabaka_app/features/profile/models/mb_profile.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockMixService extends Fake implements MixService {
  MixResult mixResult = const MixResult(series: [], dna: [], seedCount: 0);
  List<AutocompleteSeriesResult> seedSuggestions = [];
  Object? mixError;
  int fetchMixCalls = 0;
  int fetchSeedCalls = 0;
  Map<String, dynamic>? lastFetchMixArgs;

  /// When set, fetchMix returns this future instead of [mixResult] (used to
  /// simulate a slow request that overlaps a newer one).
  Future<MixResult>? pendingMixResponse;

  @override
  Future<MixResult> fetchMix({
    required List<int> seriesIds,
    int limit = 24,
    List<String>? contentRating,
    bool strict = false,
    String? blendUserId,
    String? excludeUserLibrary,
  }) async {
    fetchMixCalls++;
    lastFetchMixArgs = {
      'ids': seriesIds,
      'strict': strict,
      'blendUserId': blendUserId,
      'excludeUserLibrary': excludeUserLibrary,
      'contentRating': contentRating,
    };
    final pending = pendingMixResponse;
    if (pending != null) {
      pendingMixResponse = null;
      return pending;
    }
    if (mixError != null) throw mixError!;
    return mixResult;
  }

  @override
  Future<List<AutocompleteSeriesResult>> fetchSeedSuggestions(List<int> seriesIds) async {
    fetchSeedCalls++;
    return seedSuggestions;
  }
}

class _MockAuth extends Fake implements ProfileAuthService {
  @override
  bool get isLoggedIn => true;
  @override
  MbProfile? get cachedProfile =>
      MbProfile(id: 'user-42', role: 'user', scopes: const []);
  @override
  void addListener(VoidCallback l) {}
  @override
  void removeListener(VoidCallback l) {}
}

Series _series(String id, {String title = 'Test'}) {
  return Series.fromJson({
    'id': id,
    'title': title,
    'native_title': '',
    'romanized_title': '',
    'secondary_titles': {},
    'authors': [],
    'artists': [],
    'description': '',
    'year': '',
    'status': '',
    'is_licensed': false,
    'has_anime': false,
    'content_rating': 'safe',
    'type': '',
    'rating': '',
    'final_volume': '',
    'total_chapters': '',
    'links': [],
    'publishers': [],
    'genres': [],
    'tags': [],
    'last_updated_at': '',
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockMixService mockMix;
  late MixController controller;

  setUp(() async {
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => '.',
    );
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();

    mockMix = _MockMixService();
    getIt.registerSingleton<MixService>(mockMix);
    getIt.registerSingleton<ProfileAuthService>(_MockAuth());

    controller = MixController();
  });

  group('MixController seeds', () {
    test('starts with no seeds and no results', () {
      expect(controller.seeds, isEmpty);
      expect(controller.results, isEmpty);
      expect(controller.hasSeeds, isFalse);
    });

    test('addSeed appends, triggers fetch, and refuses duplicates', () async {
      controller.addSeed(_series('1'));
      await Future<void>.delayed(Duration.zero);

      expect(controller.seeds.map((s) => s.id), ['1']);
      expect(controller.hasSeeds, isTrue);
      expect(mockMix.fetchMixCalls, 1);

      controller.addSeed(_series('1', title: 'Dup'));
      expect(controller.seeds, hasLength(1));
    });

    test('addSeed beyond 2 triggers seed suggestions', () async {
      controller.addSeed(_series('1'));
      controller.addSeed(_series('2'));
      await Future<void>.delayed(Duration.zero);
      expect(mockMix.fetchSeedCalls, greaterThanOrEqualTo(1));
    });

    test('removeSeed clears results when last seed removed', () async {
      mockMix.mixResult = MixResult(series: [_series('99')], dna: const [], seedCount: 1);
      controller.addSeed(_series('1'));
      await Future<void>.delayed(Duration.zero);
      expect(controller.results, isNotEmpty);

      controller.removeSeed(_series('1'));
      expect(controller.seeds, isEmpty);
      expect(controller.results, isEmpty);
      expect(controller.dna, isEmpty);
    });

    test('clearSeeds resets everything', () async {
      controller.addSeed(_series('1'));
      controller.addSeed(_series('2'));
      await Future<void>.delayed(Duration.zero);
      controller.clearSeeds();
      expect(controller.seeds, isEmpty);
      expect(controller.results, isEmpty);
      expect(controller.dna, isEmpty);
      expect(controller.seedSuggestions, isEmpty);
    });

    test('isSeed checks by int id', () {
      controller.addSeed(_series('7'));
      expect(controller.isSeed(7), isTrue);
      expect(controller.isSeed(8), isFalse);
    });
  });

  group('MixController fetch behavior', () {
    test('passes strict, blendUserId, excludeUserLibrary when enabled', () async {
      controller.setStrictMode(true);
      controller.setBlendUser(true);
      controller.setExcludeLibrary(true);
      controller.addSeed(_series('5'));
      await Future<void>.delayed(Duration.zero);

      final args = mockMix.lastFetchMixArgs!;
      expect(args['strict'], isTrue);
      expect(args['blendUserId'], 'user-42');
      expect(args['excludeUserLibrary'], 'user-42');
    });

    test('records error string on failure and clears results', () async {
      mockMix.mixError = Exception('mix down');
      controller.addSeed(_series('1'));
      await Future<void>.delayed(Duration.zero);
      expect(controller.error, contains('mix down'));
      expect(controller.results, isEmpty);
      expect(controller.isLoading, isFalse);
    });

    test('refresh re-fetches with the same seeds', () async {
      controller.addSeed(_series('1'));
      await Future<void>.delayed(Duration.zero);
      final calls = mockMix.fetchMixCalls;

      await controller.refresh();
      expect(mockMix.fetchMixCalls, calls + 1);
    });
  });

  group('MixController stale responses', () {
    test('slow mix response is discarded after seeds are cleared', () async {
      final slowResponse = Completer<MixResult>();
      mockMix.pendingMixResponse = slowResponse.future;

      controller.addSeed(_series('1'));
      await Future<void>.delayed(Duration.zero);
      expect(controller.isLoading, isTrue);

      controller.clearSeeds();
      expect(controller.isLoading, isFalse);

      slowResponse.complete(
        MixResult(series: [_series('99')], dna: const [], seedCount: 1),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.results, isEmpty);
      expect(controller.isLoading, isFalse);
    });

    test('slow mix response is discarded when a newer fetch finished', () async {
      final slowResponse = Completer<MixResult>();
      mockMix.pendingMixResponse = slowResponse.future;

      // First fetch hangs.
      controller.addSeed(_series('1'));
      await Future<void>.delayed(Duration.zero);

      // Second fetch resolves immediately with the fresh result.
      mockMix.mixResult =
          MixResult(series: [_series('2', title: 'Fresh')], dna: const [], seedCount: 2);
      controller.addSeed(_series('2'));
      await Future<void>.delayed(Duration.zero);
      expect(controller.results.map((s) => s.title), ['Fresh']);

      // The old response arrives late — it must not overwrite the fresh one.
      slowResponse.complete(
        MixResult(series: [_series('99', title: 'Stale')], dna: const [], seedCount: 1),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.results.map((s) => s.title), ['Fresh']);
      expect(controller.isLoading, isFalse);
    });
  });

  group('MixController seed suggestions', () {
    test('hides series that are already seeds', () async {
      mockMix.seedSuggestions = [
        const AutocompleteSeriesResult(id: 1, title: 'A', thumbnailUrl: ''),
        const AutocompleteSeriesResult(id: 999, title: 'B', thumbnailUrl: ''),
      ];
      controller.addSeed(_series('1'));
      controller.addSeed(_series('2'));
      await Future<void>.delayed(Duration.zero);

      expect(controller.seedSuggestions.map((s) => s.id), [999]);
    });
  });
}
