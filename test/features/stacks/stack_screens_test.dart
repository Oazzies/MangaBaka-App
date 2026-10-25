import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/paged_list.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_status_controller.dart';
import 'package:mangabaka_app/features/stacks/models/stack_detail.dart';
import 'package:mangabaka_app/features/stacks/models/stack_draft.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/models/stack_status.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/screens/my_stacks_screen.dart';
import 'package:mangabaka_app/features/stacks/screens/stack_detail_screen.dart';
import 'package:mangabaka_app/features/stacks/screens/stack_editor_screen.dart';
import 'package:mangabaka_app/features/stacks/screens/stacks_hub_screen.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';
import 'package:mangabaka_app/features/stacks/widgets/add_to_stack_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../responsive/support/fake_services.dart';
import '../../responsive/support/fixtures.dart' as rf;
import 'stack_fixtures.dart';

class _FakeStacks extends Fake implements StackService {
  StackDetail detail = StackDetail.fromJson(stackDetailJson());
  List<MySeriesStack> mineForSeries = const [];
  final List<String> calls = [];

  PagedList<StackSummary> _page(int n) => PagedList([
    for (var i = 0; i < n; i++)
      StackSummary.fromJson(stackSummaryJson(id: 100 + i)),
  ], hasNext: false);

  @override
  Future<PagedList<StackSummary>> browse({
    int page = 1,
    int limit = 24,
    bool featured = false,
  }) async => featured ? _page(0) : _page(3);

  @override
  Future<PagedList<StackSummary>> mine({int page = 1, int limit = 24}) async =>
      _page(2);
  @override
  Future<PagedList<StackSummary>> saved({int page = 1, int limit = 24}) async =>
      _page(0);
  @override
  Future<PagedList<StackSummary>> followed({
    int page = 1,
    int limit = 24,
  }) async => _page(1);

  @override
  Future<StackDetail> fetch(int id) async => detail;

  @override
  Future<StackDetail> fetchForEdit(int id) async =>
      StackDetail.fromJson(ownerStackDetailJson(id: id));

  @override
  Future<Map<int, StackStatus>> status(Iterable<int> ids) async => {
    for (final id in ids)
      id: StackStatus(id: id, libraryCount: 1, voteCount: 9),
  };

  @override
  Future<StackStatus> vote(int id) async {
    calls.add('vote $id');
    return StackStatus(id: id, hasVoted: true, voteCount: 10);
  }

  @override
  Future<List<MySeriesStack>> myStacksForSeries(String seriesId) async =>
      mineForSeries;

  @override
  Future<int> addEntry(
    int stackId,
    String seriesId, {
    String? note,
    int? rank,
    String? contentRating,
  }) async {
    calls.add('add $seriesId to $stackId');
    return 3;
  }

  @override
  Future<StackDetail> create(StackDraft draft) async {
    calls.add('create ${draft.title}');
    return StackDetail.fromJson(ownerStackDetailJson(id: 99));
  }
}

void main() {
  late _FakeStacks stacks;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();
    await resetServiceLocator();
    LocalizationService.resetForTesting();
    await LocalizationService().init();
    getIt.registerSingleton<LoggingService>(LoggingService());
    // A list layout, so notes sit under their entries rather than in a sheet.
    await SettingsManager().setListStyle(AppListStyle.comfortable);
    stacks = _FakeStacks();
  });

  tearDown(() {
    DesktopLayout.debugOverride = null;
    return resetServiceLocator();
  });

  void register({bool signedIn = true}) {
    final auth = FakeAuth(signedIn: signedIn);
    getIt
      ..registerSingleton<ProfileAuthService>(auth)
      ..registerSingleton<LibraryService>(FakeLibrary(rf.Fixtures.library(0)))
      ..registerSingleton<StackService>(stacks)
      ..registerSingleton<StackStatusController>(
        StackStatusController(service: stacks, auth: auth),
      );
  }

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    Size size = const Size(420, 900),
    bool desktop = false,
  }) async {
    DesktopLayout.debugOverride = desktop;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: home));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  String t(String key) => LocalizationService().translate(key);

  /// Text matching [label] in any case (pills and headers set display caps).
  Finder label(String text) => find.byWidgetPredicate(
    (w) => w is Text && (w.data ?? '').toLowerCase() == text.toLowerCase(),
  );

  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(
        finder,
        300,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );

  testWidgets('hub shows the reader\'s stacks and the newest', (tester) async {
    register();
    await pump(tester, const StacksHubScreen());
    expect(label(t('stacks_mine')), findsOneWidget);
    expect(find.text('Stack 100'), findsWidgets);
    // No staff picks: that rail drops out.
    expect(label(t('stacks_featured')), findsNothing);
  });

  testWidgets('hub asks a signed-out reader to sign in', (tester) async {
    register(signedIn: false);
    await pump(tester, const StacksHubScreen());
    expect(find.text(t('stacks_sign_in_title')), findsOneWidget);
    expect(label(t('stacks_mine')), findsNothing);
  });

  testWidgets('detail lists entries with notes and placeholders, and votes', (
    tester,
  ) async {
    register();
    await pump(tester, const StackDetailScreen(stackId: 18));
    expect(find.text('Stack 18'), findsOneWidget);
    expect(
      find.text(
        t(
          'stacks_library_progress',
        ).replaceAll('{n}', '1').replaceAll('{total}', '1'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('9'));
    await tester.pump();
    expect(stacks.calls, ['vote 18']);
    expect(find.text('10'), findsOneWidget);
    await scrollTo(tester, find.text('Return by death', findRichText: true));
    await scrollTo(tester, find.text(t('stacks_entry_merged')));
  });

  testWidgets('a spoiler stack hides its entries until revealed', (
    tester,
  ) async {
    register();
    stacks.detail = StackDetail.fromJson({
      ...stackDetailJson(),
      'is_spoiler': true,
    });
    await pump(tester, const StackDetailScreen(stackId: 18));
    await scrollTo(tester, find.text(t('stacks_spoiler_title')));
    expect(find.text('Return by death', findRichText: true), findsNothing);
    await tester.ensureVisible(find.text(t('stacks_spoiler_reveal')));
    await tester.tap(find.text(t('stacks_spoiler_reveal')));
    await tester.pump(const Duration(milliseconds: 600));
    await scrollTo(tester, find.text('Return by death', findRichText: true));
  });

  testWidgets('detail lays out in two panes when wide', (tester) async {
    register();
    await pump(
      tester,
      const StackDetailScreen(stackId: 18),
      size: const Size(1100, 700),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Stack 18'), findsOneWidget);
  });

  testWidgets('owner view shows visibility and the publish hint', (
    tester,
  ) async {
    register();
    await pump(tester, const StackDetailScreen(stackId: 7, asOwner: true));
    expect(label(t('stacks_visibility_draft')), findsWidgets);
    expect(find.byTooltip(t('stacks_edit')), findsOneWidget);
    expect(
      find.text(t('stacks_publish_needs').replaceAll('{n}', '5')),
      findsOneWidget,
    );
  });

  testWidgets('my stacks switches between mine, saved and followed', (
    tester,
  ) async {
    register();
    await pump(tester, const MyStacksScreen());
    expect(find.text('Stack 101'), findsOneWidget);
    await tester.tap(label(t('stacks_tab_saved')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Stack 101'), findsNothing);
    expect(find.text(t('stacks_empty')), findsOneWidget);
  });

  testWidgets('editor refuses to save without a title, then creates', (
    tester,
  ) async {
    register();
    await pump(tester, const StackEditorScreen());
    await tester.tap(label(t('save')));
    await tester.pump();
    expect(stacks.calls, isEmpty);
    expect(find.text(t('stacks_problem_title')), findsWidgets);

    await tester.enterText(find.byType(TextField).first, 'My stack');
    await tester.tap(label(t('save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(stacks.calls, ['create My stack']);
  });

  testWidgets('editor shows details beside entries when wide', (tester) async {
    register();
    await pump(
      tester,
      const StackEditorScreen(stackId: 7),
      size: const Size(1000, 800),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Mushoku Tensei'), findsOneWidget);
    expect(label(t('stacks_field_title')), findsOneWidget);
  });

  // Phone portrait, phone landscape, tablet portrait and landscape: every
  // Stacks screen must lay out without overflow or exceptions.
  const phoneAndTablet = [
    Size(360, 740),
    Size(740, 360),
    Size(800, 1280),
    Size(1280, 800),
  ];
  final screens = <String, Widget Function()>{
    'hub': () => const StacksHubScreen(),
    'detail': () => const StackDetailScreen(stackId: 18),
    'detail (owner)': () => const StackDetailScreen(stackId: 7, asOwner: true),
    'my stacks': () => const MyStacksScreen(),
    'editor (new)': () => const StackEditorScreen(),
    'editor (edit)': () => const StackEditorScreen(stackId: 7),
  };
  for (final MapEntry(key: name, value: build) in screens.entries) {
    testWidgets('$name lays out on phones and tablets', (tester) async {
      register();
      for (final size in phoneAndTablet) {
        await pump(tester, build(), size: size);
        expect(tester.takeException(), isNull, reason: '$name at $size');
        await tester.pumpWidget(const SizedBox());
      }
    });
  }

  testWidgets('add-to-stack adds the series to a chosen stack', (tester) async {
    register();
    stacks.mineForSeries = const [
      MySeriesStack(
        id: 4,
        title: 'Isekai',
        visibility: StackVisibility.public,
        entryCount: 6,
      ),
      MySeriesStack(
        id: 5,
        title: 'Full one',
        visibility: StackVisibility.draft,
        entryCount: 100,
        canAdd: false,
      ),
    ];
    final series = Series.fromJson(seriesJson(217, 'Mushoku Tensei'));
    await pump(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showAddToStackSheet(context, series),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Isekai'), findsOneWidget);
    expect(find.text('Full one'), findsOneWidget);

    await tester.tap(find.text('Full one'));
    await tester.pump();
    expect(stacks.calls, isEmpty, reason: 'a full stack cannot take more');

    await tester.tap(find.text('Isekai'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(stacks.calls, ['add 217 to 4']);
  });
}
