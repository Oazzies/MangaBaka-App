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
    // Covers this narrow (e.g. from the profile page's responsive sizing)
    // reliably wrap a long title onto two lines, which previously blew
    // through a fixed pixel budget and threw a RenderFlex overflow.
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
                          height:
                              width * 1.5 +
                              DesktopCoverCard.textAreaHeight(context),
                          itemBuilder: (context, i) => DesktopCoverCard(
                            series: _series(_longTitle),
                            width: width,
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
    // The overflow bug came from guessing at real font/DPI/text-scale
    // metrics, which kept proving wrong in practice. The fix instead caps
    // the title and caption/rating area to a fixed size (independent of
    // what the text actually needs) and clips within it, so this equality
    // is guaranteed by construction rather than something that merely
    // happened not to overflow in this environment's font rendering.
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
