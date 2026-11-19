import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/paged_list.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_status_controller.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/screens/stacks_list_screen.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';
import 'package:mangabaka_app/features/stacks/widgets/stacks_grid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../responsive/support/fake_services.dart';
import 'fake_stack_service.dart';
import 'stack_fixtures.dart';

class _HeldStacksService extends FakeStacksService {
  final List<Completer<PagedList<StackSummary>>> pending = [];

  @override
  Future<PagedList<StackSummary>> forSeries(
    String seriesId, {
    int page = 1,
    int limit = 24,
    StackSort sort = StackSort.mostVoted,
    StackSpoilerFilter spoilers = StackSpoilerFilter.exclude,
  }) {
    final next = Completer<PagedList<StackSummary>>();
    pending.add(next);
    return next.future;
  }
}

PagedList<StackSummary> _page(List<int> ids) => PagedList([
  for (final id in ids) StackSummary.fromJson(stackSummaryJson(id: id)),
], hasNext: false);

void main() {
  late _HeldStacksService stacks;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();
    await resetServiceLocator();
    LocalizationService.resetForTesting();
    await LocalizationService().init();
    getIt.registerSingleton<LoggingService>(LoggingService());
    stacks = _HeldStacksService();
    final auth = FakeAuth(signedIn: true);
    getIt
      ..registerSingleton<ProfileAuthService>(auth)
      ..registerSingleton<StackService>(stacks)
      ..registerSingleton<StackStatusController>(
        StackStatusController(service: stacks, auth: auth),
      );
  });

  tearDown(() {
    DesktopLayout.debugOverride = null;
    return resetServiceLocator();
  });

  testWidgets('a reload keeps the current stacks until the new page lands', (
    tester,
  ) async {
    DesktopLayout.debugOverride = false;
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: StacksListScreen(
          source: StacksListSource.series('217', 'Mushoku Tensei'),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(StackCardSkeleton), findsWidgets);

    stacks.pending.single.complete(_page([100, 101]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Stack 100'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    tester.state<StacksPagedViewState>(find.byType(StacksPagedView)).reload();
    await tester.pump();
    expect(find.text('Stack 100'), findsOneWidget);
    expect(find.byType(StackCardSkeleton), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    stacks.pending.last.complete(_page([200]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Stack 100'), findsNothing);
    expect(find.text('Stack 200'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
