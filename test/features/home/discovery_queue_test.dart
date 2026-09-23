import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/home/controllers/discovery_queue_controller.dart';
import 'package:mangabaka_app/features/home/screens/discovery_queue_screen.dart';
import 'package:mangabaka_app/features/home/services/home_service.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/models/mb_profile.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';

Series _makeSeries(String id, String title) => Series(
      id: id,
      state: 'published',
      title: title,
      nativeTitle: '',
      romanizedTitle: '',
      secondaryTitles: const [],
      coverUrl: 'https://example.com/$id.jpg',
      rawCoverUrl: 'https://example.com/$id.jpg',
      authors: const ['Author A'],
      artists: const ['Artist A'],
      description: 'A great description for $title',
      year: '2024',
      status: 'releasing',
      isLicensed: 'no',
      hasAnime: 'no',
      contentRating: 'safe',
      type: 'manga',
      rating: '8.5',
      finalVolume: '',
      totalChapters: '50',
      links: const [],
      publishers: const [],
      genres: const ['Action', 'Fantasy'],
      tags: const ['Magic'],
      lastUpdated: '',
    );

class FakeAuthService extends Fake implements ProfileAuthService {
  bool loggedIn = true;
  @override
  bool get isLoggedIn => loggedIn;
  @override
  MbProfile? get cachedProfile => null;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

class FakeHomeService extends Fake implements HomeService {
  ForYouReadiness? readiness = const ForYouReadiness(
    coldStart: false,
    profileStale: false,
    libraryCount: 15,
  );
  List<Series> forYouSeries = [
    _makeSeries('s1', 'Series One'),
    _makeSeries('s2', 'Series Two'),
  ];

  @override
  Future<ForYouReadiness?> fetchForYouReadiness() async => readiness;

  @override
  Future<List<Series>> fetchForYou({int limit = 20}) async => forYouSeries;

  @override
  void dispose() {}
}

class FakeLibraryService extends Fake implements LibraryService {
  final List<String> added = [];

  @override
  Future<void> createLibraryEntry(String seriesId, String state) async {
    added.add('$seriesId:$state');
  }
}

void main() {
  late FakeAuthService auth;
  late FakeHomeService home;
  late FakeLibraryService library;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await resetServiceLocator();
    setupServiceLocator();
  });

  setUp(() {
    auth = FakeAuthService();
    home = FakeHomeService();
    library = FakeLibraryService();

    if (getIt.isRegistered<ProfileAuthService>()) {
      getIt.unregister<ProfileAuthService>();
    }
    getIt.registerSingleton<ProfileAuthService>(auth);
  });

  group('DiscoveryQueueController', () {
    test('reports not ready if user is logged out', () async {
      auth.loggedIn = false;
      final controller = DiscoveryQueueController(
        homeService: home,
        libraryService: library,
        authService: auth,
      );

      await controller.loadQueue();

      expect(controller.isReady, isFalse);
      expect(controller.errorMessage, 'import_login_required');
      expect(controller.queue, isEmpty);
    });

    test('reports not ready if readiness probe indicates coldStart', () async {
      home.readiness = const ForYouReadiness(
        coldStart: true,
        profileStale: false,
        libraryCount: 1,
      );
      final controller = DiscoveryQueueController(
        homeService: home,
        libraryService: library,
        authService: auth,
      );

      await controller.loadQueue();

      expect(controller.isReady, isFalse);
      expect(controller.queue, isEmpty);
    });

    test('loads recommendations and steps through queue', () async {
      final controller = DiscoveryQueueController(
        homeService: home,
        libraryService: library,
        authService: auth,
      );

      await controller.loadQueue();

      expect(controller.isReady, isTrue);
      expect(controller.totalCount, 2);
      expect(controller.currentIndex, 0);
      expect(controller.currentSeries?.id, 's1');
      expect(controller.remainingCount, 2);
      expect(controller.isCompleted, isFalse);

      // Skip first
      controller.skip();
      expect(controller.currentIndex, 1);
      expect(controller.reviewedCount, 1);
      expect(controller.currentSeries?.id, 's2');
      expect(controller.remainingCount, 1);
      expect(controller.isCompleted, isFalse);

      // Add second
      final added = await controller.addToLibrary('reading');
      expect(added, isTrue);
      expect(library.added, ['s2:reading']);
      expect(controller.currentIndex, 2);
      expect(controller.reviewedCount, 2);
      expect(controller.addedCount, 1);
      expect(controller.isCompleted, isTrue);
    });
  });

  group('DiscoveryQueueScreen', () {
    Widget buildScreen(DiscoveryQueueController controller) => MaterialApp(
          home: DiscoveryQueueScreen(
            controller: controller,
            previewBuilder: (_, __) => const SizedBox.shrink(),
          ),
        );

    testWidgets('shows queue controls and handles skip',
        (WidgetTester tester) async {
      final controller = DiscoveryQueueController(
        homeService: home,
        libraryService: library,
        authService: auth,
      );
      await controller.loadQueue();

      await tester.pumpWidget(buildScreen(controller));
      await tester.pump();

      expect(find.text('DISCOVERY_QUEUE_SKIP'), findsOneWidget);
      expect(find.text('DISCOVERY_QUEUE_NOT_INTERESTED'), findsOneWidget);

      // Tap skip
      await tester.tap(find.text('DISCOVERY_QUEUE_SKIP'));
      await tester.pump();

      expect(controller.currentIndex, 1);
      expect(controller.currentSeries?.id, 's2');
    });

    testWidgets('not interested dismisses the series and advances',
        (WidgetTester tester) async {
      SettingsManager.resetForTesting();
      final controller = DiscoveryQueueController(
        homeService: home,
        libraryService: library,
        authService: auth,
      );
      await controller.loadQueue();

      await tester.pumpWidget(buildScreen(controller));
      await tester.pump();

      await tester.tap(find.text('DISCOVERY_QUEUE_NOT_INTERESTED'));
      await tester.pump();

      expect(controller.currentIndex, 1);
      expect(controller.currentSeries?.id, 's2');
      expect(SettingsManager().dismissedRecommendations, contains('s1'));
    });

    testWidgets('shows completed screen when queue finishes',
        (WidgetTester tester) async {
      final controller = DiscoveryQueueController(
        homeService: home,
        libraryService: library,
        authService: auth,
      );
      await controller.loadQueue();

      await tester.pumpWidget(buildScreen(controller));
      await tester.pump();

      // Skip both items
      controller.skip();
      controller.skip();
      await tester.pump();

      expect(find.text('DISCOVERY_QUEUE_COMPLETE_TITLE'), findsOneWidget);
    });
  });
}
