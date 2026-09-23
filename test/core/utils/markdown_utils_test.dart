import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/utils/markdown_utils.dart';
import 'package:mangabaka_app/core/theme/app_theme.dart';
import 'package:mangabaka_app/core/theme/presets/theme_presets.dart';

Widget _buildTestHost(Widget child) {
  final palette = ThemePresets.fallback.dark!;
  return MaterialApp(
    theme: AppTheme.build(palette, showTooltips: false),
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MarkdownUtils.normalizeDescription', () {
    test('leaves out-of-range numeric entities instead of throwing', () {
      expect(
        MarkdownUtils.normalizeDescription('a &#99999999; b &#xD800; c &#65;'),
        'a &#99999999; b &#xD800; c A',
      );
    });

    test('handles bold markdown and bold html', () {
      final input = '**Original Webtoon:** <b>Official</b>';
      final output = MarkdownUtils.normalizeDescription(input);
      expect(output, '**Original Webtoon:** **Official**');
    });

    test('handles italic markdown and italic html', () {
      final input = '*Note: Translated* <i>Source</i>';
      final output = MarkdownUtils.normalizeDescription(input);
      expect(output, '*Note: Translated* *Source*');
    });

    test('converts html br and p to newlines', () {
      final input = 'Line 1<br>Line 2<br/>Line 3<p>Line 4</p>';
      final output = MarkdownUtils.normalizeDescription(input);
      expect(output, 'Line 1\nLine 2\nLine 3\n\nLine 4');
    });

    test('decodes html entities and mojibake', () {
      final input = '&quot;I am a dopamine addict.&quot; â€” It&#39;s &amp; more';
      final output = MarkdownUtils.normalizeDescription(input);
      expect(output, '"I am a dopamine addict." — It\'s & more');
    });

    test('unescapes backslashes before markdown characters and pipes', () {
      final input = r'\*\*Original Webtoon:\*\* \| \[KakaoPage\](https://page.kakao.com/content/69460106)';
      final output = MarkdownUtils.normalizeDescription(input);
      expect(
        output,
        '**Original Webtoon:** | [KakaoPage](https://page.kakao.com/content/69460106)',
      );
    });

    test('cleans corrupted stray backslashes surrounding tokens', () {
      final input = r'\Original Webtoon:\|\KakaoPage\';
      final output = MarkdownUtils.normalizeDescription(input);
      expect(output, 'Original Webtoon:|KakaoPage');
    });

    test('fixes malformed nested URLs in markdown links', () {
      final input =
          '[KakaoPage]([https://page.kakao.com/content/69460106](https://page.kakao.com/content/69460106))';
      final output = MarkdownUtils.normalizeDescription(input);
      expect(
        output,
        '[KakaoPage](https://page.kakao.com/content/69460106)',
      );
    });

    test('fixes angle bracket URLs inside link parentheses', () {
      final input =
          '[KakaoPage](<https://page.kakao.com/content/69460106>)';
      final output = MarkdownUtils.normalizeDescription(input);
      expect(
        output,
        '[KakaoPage](https://page.kakao.com/content/69460106)',
      );
    });

    test('preserves non-HTML angle bracket titles', () {
      final input = 'Possessed into the game <Apocalypse: Safe Zone>';
      final output = MarkdownUtils.normalizeDescription(input);
      expect(output, 'Possessed into the game <Apocalypse: Safe Zone>');
    });
  });

  group('MarkdownUtils.toPlainText', () {
    test('strips links and bold to clean plain text', () {
      final input =
          '**Original Webtoon:** [KakaoPage](https://page.kakao.com/content/69460106), [Daum](https://webtoon.kakao.com/)';
      final plain = MarkdownUtils.toPlainText(input);
      expect(plain, 'Original Webtoon: KakaoPage, Daum');
    });

    test('strips italic and code', () {
      final input = '*Note:* Check `code` text';
      final plain = MarkdownUtils.toPlainText(input);
      expect(plain, 'Note: Check code text');
    });
  });

  group('MarkdownUtils.buildTextSpans', () {
    testWidgets('builds bold and link spans correctly', (tester) async {
      await tester.pumpWidget(
        _buildTestHost(
          Builder(
            builder: (context) {
              final spans = MarkdownUtils.buildTextSpans(
                text: '**Original Webtoon:** [KakaoPage](https://page.kakao.com/content/69460106)',
                context: context,
                onLinkTap: (_) {},
              );

              expect(spans, isNotEmpty);
              final boldSpans = spans.where((s) => s.style?.fontWeight == FontWeight.bold).toList();
              expect(boldSpans, isNotEmpty);

              final linkSpans = spans.where((s) => s is TextSpan && s.children != null && s.children!.isNotEmpty).toList();
              expect(linkSpans, isNotEmpty);

              return Text.rich(TextSpan(children: spans));
            },
          ),
        ),
      );
    });

    testWidgets('triggers onLinkTap when link recognizer is tapped', (tester) async {
      String? tappedUrl;
      final recognizers = <GestureRecognizer>[];

      await tester.pumpWidget(
        _buildTestHost(
          Builder(
            builder: (context) {
              final spans = MarkdownUtils.buildTextSpans(
                text: 'Visit [KakaoPage](https://page.kakao.com/content/69460106) now',
                context: context,
                onLinkTap: (url) => tappedUrl = url,
                registerRecognizer: (r) => recognizers.add(r),
              );

              return Text.rich(TextSpan(children: spans));
            },
          ),
        ),
      );

      expect(recognizers, isNotEmpty);
      final tapRecognizer = recognizers.first as TapGestureRecognizer;
      tapRecognizer.onTap?.call();
      expect(tappedUrl, 'https://page.kakao.com/content/69460106');

      for (final r in recognizers) {
        r.dispose();
      }
    });

    testWidgets('handles raw URLs and angle bracket URLs', (tester) async {
      await tester.pumpWidget(
        _buildTestHost(
          Builder(
            builder: (context) {
              final spans = MarkdownUtils.buildTextSpans(
                text: 'See https://mangabaka.org and <https://page.kakao.com>',
                context: context,
              );

              expect(spans.length, greaterThanOrEqualTo(3));
              return Text.rich(TextSpan(children: spans));
            },
          ),
        ),
      );
    });

    testWidgets('handles strikethrough and inline code', (tester) async {
      await tester.pumpWidget(
        _buildTestHost(
          Builder(
            builder: (context) {
              final spans = MarkdownUtils.buildTextSpans(
                text: 'Old ~~deleted~~ and `code`',
                context: context,
              );

              expect(spans, isNotEmpty);
              return Text.rich(TextSpan(children: spans));
            },
          ),
        ),
      );
    });

    testWidgets('handles nested bold links', (tester) async {
      await tester.pumpWidget(
        _buildTestHost(
          Builder(
            builder: (context) {
              final spans = MarkdownUtils.buildTextSpans(
                text: '**[Original Novel](https://page.kakao.com/content/64422082)**',
                context: context,
              );

              expect(spans, isNotEmpty);
              return Text.rich(TextSpan(children: spans));
            },
          ),
        ),
      );
    });
  });
}
