import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/core/constants/mock_series_data.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/series/mixins/series_detail_actions_mixin.dart';
import 'package:mangabaka_app/features/series/models/series.dart';

// ─── Fake ────────────────────────────────────────────────────────────────────

class _FakeLibraryService extends Fake implements LibraryService {
  bool throwOnCreate = false;
  bool throwOnDelete = false;
  String? lastCreatedId;
  String? lastDeletedId;

  @override
  Future<void> createLibraryEntry(String seriesId, String state) async {
    if (throwOnCreate) throw Exception('create failed');
    lastCreatedId = seriesId;
  }

  @override
  Future<void> deleteEntry(String seriesId) async {
    if (throwOnDelete) throw Exception('delete failed');
    lastDeletedId = seriesId;
  }

  @override
  Future<void> updateLibraryEntryRating(String seriesId, int rating) async {}

  @override
  Future<void> updateLibraryEntryProgress(
    String seriesId, {
    int? progressChapter,
    int? progressVolume,
  }) async {}
}

// ─── Host widget ─────────────────────────────────────────────────────────────

class _TestWidget extends StatefulWidget {
  final LibraryService libraryService;
  final Series? seriesOverride;
  const _TestWidget({required this.libraryService, this.seriesOverride});

  @override
  State<_TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<_TestWidget>
    with SeriesDetailActionsMixin<_TestWidget> {
  @override
  LibraryService get libraryService => widget.libraryService;

  @override
  Series get series => widget.seriesOverride ?? mockSeries222;

  @override
  bool isAdding = false;

  @override
  Widget build(BuildContext context) => Scaffold(body: Container());
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    await LoggingService.setup();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildWidget(_FakeLibraryService svc, {Series? seriesOverride}) =>
      MaterialApp(
        home: _TestWidget(libraryService: svc, seriesOverride: seriesOverride),
      );

  group('SeriesDetailActionsMixin.addSeriesToLibrary', () {
    testWidgets('is a no-op when isAdding is already true', (tester) async {
      final svc = _FakeLibraryService();
      await tester.pumpWidget(buildWidget(svc));
      final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));

      state.isAdding = true;
      await state.addSeriesToLibrary();
      await tester.pump();

      expect(svc.lastCreatedId, isNull);
    });

    testWidgets('calls createLibraryEntry with series id and resets isAdding',
        (tester) async {
      final svc = _FakeLibraryService();
      await tester.pumpWidget(buildWidget(svc));
      final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));

      await state.addSeriesToLibrary();
      await tester.pump();

      expect(svc.lastCreatedId, '222');
      expect(state.isAdding, isFalse);
    });

    testWidgets('shows error snackbar and resets isAdding on failure',
        (tester) async {
      final svc = _FakeLibraryService()..throwOnCreate = true;
      await tester.pumpWidget(buildWidget(svc));
      final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));

      await state.addSeriesToLibrary();
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(state.isAdding, isFalse);
    });
  });

  group('SeriesDetailActionsMixin.shareLink', () {
    testWidgets('shows no_sharing_link snackbar when series has no mangabaka link',
        (tester) async {
      // mockSeries222 has links: const [] — no mangabaka link present
      final svc = _FakeLibraryService();
      await tester.pumpWidget(buildWidget(svc));
      final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));

      state.shareLink();
      await tester.pump();

      // LocalizationService not initialised in tests; translate returns the key
      expect(find.text('no_sharing_link'), findsOneWidget);
    });
  });

  group('SeriesDetailActionsMixin.copyToClipboard', () {
    testWidgets('shows a snackbar with the copied text', (tester) async {
      final svc = _FakeLibraryService();
      await tester.pumpWidget(buildWidget(svc));
      final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));

      state.copyToClipboard('https://mangabaka.dev/series/222');
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('SeriesDetailActionsMixin.showDeleteConfirmationDialog', () {
    testWidgets('shows dialog with cancel and confirm buttons', (tester) async {
      final svc = _FakeLibraryService();
      await tester.pumpWidget(buildWidget(svc));
      final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));

      state.showDeleteConfirmationDialog();
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      // LocalizationService not initialised; translate returns the key
      expect(find.text('cancel'), findsOneWidget);
      expect(find.text('confirm'), findsOneWidget);
    });

    testWidgets('calls deleteEntry when confirm tapped', (tester) async {
      final svc = _FakeLibraryService();
      await tester.pumpWidget(buildWidget(svc));
      final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));

      state.showDeleteConfirmationDialog();
      await tester.pumpAndSettle();

      await tester.tap(find.text('confirm'));
      await tester.pumpAndSettle();

      expect(svc.lastDeletedId, '222');
    });

    testWidgets('shows error snackbar when deleteEntry throws', (tester) async {
      final svc = _FakeLibraryService()..throwOnDelete = true;
      await tester.pumpWidget(buildWidget(svc));
      final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));

      state.showDeleteConfirmationDialog();
      await tester.pumpAndSettle();

      await tester.tap(find.text('confirm'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
