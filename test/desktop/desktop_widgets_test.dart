import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_filter_panel.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/browse/models/sort_options.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/tri_state_chip.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  tearDown(() => DesktopLayout.debugOverride = null);

  group('DesktopLayout', () {
    testWidgets('override forces the decision either way', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_host(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));

      DesktopLayout.debugOverride = true;
      expect(DesktopLayout.isActive(ctx), isTrue);
      DesktopLayout.debugOverride = false;
      expect(DesktopLayout.isActive(ctx), isFalse);
    });
  });

  group('DesktopTriChip', () {
    Future<List<TriState>> tapThrough(
      WidgetTester tester,
      TriState start, {
      bool secondary = false,
    }) async {
      final seen = <TriState>[];
      await tester.pumpWidget(_host(DesktopTriChip(
        label: 'Manga',
        state: start,
        onChanged: seen.add,
      )));
      if (secondary) {
        await tester.tap(find.text('Manga'), buttons: kSecondaryButton);
      } else {
        await tester.tap(find.text('Manga'));
      }
      return seen;
    }

    testWidgets('click cycles off → include → exclude → off', (tester) async {
      expect(await tapThrough(tester, TriState.off), [TriState.include]);
      expect(await tapThrough(tester, TriState.include), [TriState.exclude]);
      expect(await tapThrough(tester, TriState.exclude), [TriState.off]);
    });

    testWidgets('right-click excludes directly and toggles back',
        (tester) async {
      expect(
        await tapThrough(tester, TriState.off, secondary: true),
        [TriState.exclude],
      );
      expect(
        await tapThrough(tester, TriState.exclude, secondary: true),
        [TriState.off],
      );
    });
  });

  group('DesktopSegmented', () {
    testWidgets('reports the tapped segment', (tester) async {
      int? picked;
      await tester.pumpWidget(_host(DesktopSegmented<int>(
        value: 7,
        segments: const [(7, '7d', null), (30, '30d', null)],
        onChanged: (v) => picked = v,
      )));
      await tester.tap(find.text('30D'));
      expect(picked, 30);
    });
  });

  group('searchSortOptions', () {
    test('library swaps popularity for unread sorts', () {
      final l10n = LocalizationService();
      final browse = searchSortOptions(l10n);
      final library = searchSortOptions(l10n, library: true);

      expect(browse.keys, contains('popularity_desc'));
      expect(browse.keys, isNot(contains('unread_desc')));
      expect(browse.keys, isNot(contains('my_score_desc')));
      expect(browse.keys, isNot(contains('my_score_asc')));
      expect(library.keys, contains('unread_desc'));
      expect(library.keys, contains('my_score_desc'));
      expect(library.keys, contains('my_score_asc'));
      expect(library.keys, isNot(contains('popularity_desc')));
      expect(library.keys.last, 'random');
    });
  });
}
