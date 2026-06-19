import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/database/database.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/mixins/profile_data_mixin.dart';
import 'package:mangabaka_app/features/profile/models/mb_profile.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/services/snapshot_service.dart';
import 'package:mangabaka_app/features/profile/services/statistics_service.dart';

// ─── Fakes ───────────────────────────────────────────────────────────────────

MbProfile _profile() => MbProfile(
      id: 'u1',
      role: 'user',
      scopes: [],
      preferredUsername: 'testuser',
    );

class _FakeAuth extends Fake implements ProfileAuthService {
  @override
  bool get isLoggedIn => false;

  @override
  Future<MbProfile> fetchProfile({bool forceRefresh = false}) async => _profile();
}

class _FakeStats extends Fake implements StatisticsService {
  @override
  Future<int> getTotalSeries({List<String>? contentPreferences}) async => 10;

  @override
  Future<int> getChaptersRead({List<String>? contentPreferences}) async => 500;

  @override
  Future<int> getVolumesRead({List<String>? contentPreferences}) async => 30;

  @override
  Future<double> getMeanScore({List<String>? contentPreferences}) async => 78.5;
}

class _FakeSnapshotService extends Fake implements SnapshotService {
  @override
  Future<List<LibraryEntry>> fetchSnapshot({
    required String sortBy,
    int page = 1,
    int limit = 10,
  }) async =>
      const [];
}

// ─── Host widget ─────────────────────────────────────────────────────────────

class _TestWidget extends StatefulWidget {
  final ProfileAuthService auth;
  final StatisticsService stats;
  final SnapshotService snapshot;
  final LibraryService library;

  const _TestWidget({
    required this.auth,
    required this.stats,
    required this.snapshot,
    required this.library,
  });

  @override
  State<_TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<_TestWidget>
    with ProfileDataMixin<_TestWidget> {
  @override
  ProfileAuthService get auth => widget.auth;

  @override
  LibraryService get libraryService => widget.library;

  @override
  StatisticsService get statisticsService => widget.stats;

  @override
  SnapshotService get snapshotService => widget.snapshot;

  @override
  Widget build(BuildContext context) => Container();
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;
  late LibraryService libraryService;

  setUpAll(() async => LoggingService.setup());

  setUp(() async {
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());
    db = AppDatabase.forTesting(NativeDatabase.memory());
    getIt.registerSingleton<AppDatabase>(db);
    libraryService = LibraryService(auth: _FakeAuth(), database: db);
  });

  tearDown(() async {
    await db.close();
    await resetServiceLocator();
  });

  Widget buildTestWidget({
    ProfileAuthService? auth,
    StatisticsService? stats,
    SnapshotService? snapshot,
  }) {
    return MaterialApp(
      home: _TestWidget(
        auth: auth ?? _FakeAuth(),
        stats: stats ?? _FakeStats(),
        snapshot: snapshot ?? _FakeSnapshotService(),
        library: libraryService,
      ),
    );
  }

  group('ProfileDataMixin.fetchStatistics', () {
    testWidgets('populates totalSeries, chaptersRead, volumesRead, meanScore',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));

      await state.fetchStatistics();
      await tester.pump();

      expect(state.totalSeries, 10);
      expect(state.chaptersRead, 500);
      expect(state.volumesRead, 30);
      expect(state.meanScore, 78.5);
    });
  });

  group('ProfileDataMixin.fetchRecentlyChanged', () {
    testWidgets('is a no-op when isLoadingChanged is true', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));

      state.isLoadingChanged = true;
      await state.fetchRecentlyChanged();
      await tester.pump();
      expect(state.recentlyChanged, isEmpty);
    });

    testWidgets('is a no-op when hasMoreChanged is false', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));

      state.hasMoreChanged = false;
      await state.fetchRecentlyChanged();
      await tester.pump();
      expect(state.recentlyChanged, isEmpty);
    });

    testWidgets('sets hasMoreChanged false when snapshot returns empty',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(snapshot: _FakeSnapshotService()));
      final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));

      await state.fetchRecentlyChanged();
      await tester.pump();
      expect(state.hasMoreChanged, isFalse);
    });
  });

  group('ProfileDataMixin.fetchRecentlyAdded', () {
    testWidgets('increments pageAdded after fetch', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));

      expect(state.pageAdded, 1);
      await state.fetchRecentlyAdded();
      await tester.pump();
      expect(state.pageAdded, 2);
    });
  });
}
