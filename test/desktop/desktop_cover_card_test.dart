import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_carousel.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_cover_card.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:shared_preferences/shared_preferences.dart';

Series _series(String title) => Series.fromJson({
  'id': '1',
  'title': title,
  'state': 'active',
  'type': 'manga',
  'status': 'releasing',
  'year': 2020,
});

const _longTitle =
    'A Very Long Series Title That Definitely Wraps Onto Two Lines';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();
  });

  group('DesktopCoverCard.textAreaHeight', () {
    // Narrow covers wrap long titles to two lines, which once overflowed a fixed budget.
    for (final width in [90.0, 110.0, 130.0, 156.0]) {
      for (final textScale in [1.0, 1.3, 1.5, 2.0]) {
        testWidgets(
          'no overflow at width=$width textScale=$textScale',
          (tester) async {
            await tester.pumpWidget(
              MediaQuery(
                data: MediaQueryData(
                  textScaler: TextScaler.linear(textScale),
                ),
                child: MaterialApp(
                  home: Scaffold(
                    body: SizedBox(
                      width: 1400,
                      child: Builder(
                        builder: (context) => DesktopCarousel(
                          title: 'Recently Changed',
                          itemCount: 5,
                          itemWidth: width,
                          itemHeight: (w) =>
                              w * 1.5 +
                              DesktopCoverCard.textAreaHeight(context),
                          itemBuilder: (context, i) => DesktopCoverCard(
                            series: _series(_longTitle),
                            prefetch: (_) {},
                            caption: 'Reading',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });

  group('DesktopCoverCard natural height', () {
    // Text areas are fixed-size and clipped, so this equality holds by construction.
    for (final width in [90.0, 156.0]) {
      for (final textScale in [1.0, 2.0]) {
        testWidgets(
          'exactly matches textAreaHeight at width=$width '
          'textScale=$textScale',
          (tester) async {
            late double budgetedHeight;
            await tester.pumpWidget(
              MediaQuery(
                data: MediaQueryData(
                  textScaler: TextScaler.linear(textScale),
                ),
                child: MaterialApp(
                  home: Scaffold(
                    body: Align(
                      alignment: Alignment.topLeft,
                      child: Builder(
                        builder: (context) {
                          budgetedHeight =
                              width * 1.5 +
                              DesktopCoverCard.textAreaHeight(context);
                          return SizedBox(
                            width: width,
                            height: budgetedHeight,
                            child: DesktopCoverCard(
                              series: _series(_longTitle),
                              prefetch: (_) {},
                              width: width,
                              caption: 'Reading',
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
            final size = tester.getSize(find.byType(DesktopCoverCard));
            expect(size.height, closeTo(budgetedHeight, 0.5));
          },
        );
      }
    }
  });
}
