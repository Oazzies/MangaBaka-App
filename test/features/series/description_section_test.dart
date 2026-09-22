import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_theme.dart';
import 'package:mangabaka_app/core/theme/presets/theme_presets.dart';
import 'package:mangabaka_app/features/series/widgets/description_section.dart';

Widget _buildHost(Widget child) {
  final palette = ThemePresets.fallback.dark!;
  return MaterialApp(
    theme: AppTheme.build(palette, showTooltips: false),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalizationService().init();
  });

  group('DescriptionSection Widget Tests', () {
    testWidgets('renders markdown description with bold and link spans', (tester) async {
      final desc =
          '**Original Webtoon:** [KakaoPage](https://page.kakao.com/content/69460106)';

      await tester.pumpWidget(_buildHost(DescriptionSection(description: desc)));
      await tester.pumpAndSettle();

      expect(find.byType(DescriptionSection), findsOneWidget);
      expect(find.byType(RichText), findsWidgets);

      // Verify that rich text contains Original Webtoon and KakaoPage
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final hasKakao = richTexts.any((rt) => rt.text.toPlainText().contains('KakaoPage'));
      final hasBold = richTexts.any((rt) => rt.text.toPlainText().contains('Original Webtoon:'));
      expect(hasKakao, isTrue);
      expect(hasBold, isTrue);
    });

    testWidgets('handles long description with expand/collapse toggle', (tester) async {
      final longDesc = List.generate(12, (i) => 'Line $i of long description text for series synopsis testing.').join('\n');

      await tester.pumpWidget(_buildHost(DescriptionSection(description: longDesc)));
      await tester.pumpAndSettle();

      // Show more should be visible
      final showMoreFinder = find.text(LocalizationService().translate('show_more'));
      expect(showMoreFinder, findsOneWidget);

      // Tap show more
      await tester.tap(showMoreFinder);
      await tester.pumpAndSettle();

      // Now show less should be visible
      final showLessFinder = find.text(LocalizationService().translate('show_less'));
      expect(showLessFinder, findsOneWidget);

      // Scroll to ensure visible if needed and tap show less
      await tester.ensureVisible(showLessFinder);
      await tester.tap(showLessFinder);
      await tester.pumpAndSettle();

      expect(find.text(LocalizationService().translate('show_more')), findsOneWidget);
    });

    testWidgets('copy button is present and clickable', (tester) async {
      final desc = 'Short test description.';

      await tester.pumpWidget(_buildHost(DescriptionSection(description: desc)));
      await tester.pumpAndSettle();

      final copyButton = find.byIcon(Icons.copy_all);
      expect(copyButton, findsOneWidget);

      await tester.tap(copyButton);
      await tester.pumpAndSettle();
    });
  });
}
