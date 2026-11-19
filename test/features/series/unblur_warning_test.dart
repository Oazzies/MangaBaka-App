import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_cover_card.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/unblur_warning.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();
  });

  group('isRatingBlurred', () {
    test('follows the blurred content ratings, ignoring case', () async {
      expect(WidgetUtils.isRatingBlurred('erotica'), isFalse);
      await SettingsManager().setBlurredContentRatings(['erotica']);
      expect(WidgetUtils.isRatingBlurred('erotica'), isTrue);
      expect(WidgetUtils.isRatingBlurred('Erotica'), isTrue);
      expect(WidgetUtils.isRatingBlurred('safe'), isFalse);
    });
  });

  group('confirmUnblur', () {
    Future<bool?> ask(WidgetTester tester, String button) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await confirmUnblur(context),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('UNBLUR_COVER_TITLE'), findsOneWidget);
      await tester.tap(find.text(button));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('going ahead resolves true', (tester) async {
      expect(await ask(tester, 'unblur_cover_confirm'), isTrue);
    });

    testWidgets('cancelling resolves false', (tester) async {
      expect(await ask(tester, 'cancel'), isFalse);
    });
  });

  group('desktop cover card', () {
    Series series(String rating) => Series.fromJson({
      'id': '1',
      'title': 'T',
      'state': 'active',
      'content_rating': rating,
      // An asset path, so the image needs no network.
      'cover': {'x350': 'assets/series_222_cover.jpg'},
    });

    Future<void> pump(WidgetTester tester, Series s) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DesktopCoverCard(series: s, width: 140, prefetch: (_) {}),
        ),
      ),
    );

    testWidgets('blurs the cover of a blurred rating', (tester) async {
      DesktopLayout.debugOverride = true;
      addTearDown(() => DesktopLayout.debugOverride = null);
      await SettingsManager().setBlurredContentRatings(['erotica']);

      await pump(tester, series('erotica'));
      expect(find.byType(ImageFiltered), findsOneWidget);

      await pump(tester, series('safe'));
      expect(find.byType(ImageFiltered), findsNothing);
    });
  });
}
