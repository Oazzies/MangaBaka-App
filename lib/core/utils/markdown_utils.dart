import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Utility for cleaning, normalizing, and rendering Markdown and rich text
/// found in manga and series descriptions.
class MarkdownUtils {
  static final _logger = LoggingService.logger;

  /// Map of common HTML entities to their characters.
  static const Map<String, String> _htmlEntities = {
    '&quot;': '"',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&#39;': "'",
    '&#039;': "'",
    '&apos;': "'",
    '&nbsp;': ' ',
    '&ndash;': '–',
    '&mdash;': '—',
    '&hellip;': '…',
    '&lsquo;': '‘',
    '&rsquo;': '’',
    '&ldquo;': '“',
    '&rdquo;': '”',
    '&copy;': '©',
    '&reg;': '®',
    '&trade;': '™',
  };

  /// Common UTF-8 mojibake replacements (from improperly decoded Windows-1252/ISO-8859-1).
  static const Map<String, String> _mojibake = {
    'â€™': '’',
    'â€˜': '‘',
    'â€œ': '“',
    'â€ ': '”',
    'â€”': '—',
    'â€“': '–',
    'â€¦': '…',
    'â™¥': '♥',
    'Ã©': 'é',
    'Ã¨': 'è',
    'Ã ': 'à',
    'Ã§': 'ç',
  };

  /// Normalizes description text by decoding HTML entities, cleaning HTML tags,
  /// correcting mojibake, unescaping backslashes, and repairing corrupted tokens.
  static String normalizeDescription(String raw) {
    if (raw.isEmpty) return '';

    String text = raw;

    // 1. Repair common UTF-8 mojibake
    for (final entry in _mojibake.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }

    // 2. Decode HTML entities
    for (final entry in _htmlEntities.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    // Numeric decimal entities: &#123;
    text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      final code = int.tryParse(match.group(1)!);
      return code != null ? String.fromCharCode(code) : match.group(0)!;
    });
    // Numeric hex entities: &#x1f;
    text = text.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
      final code = int.tryParse(match.group(1)!, radix: 16);
      return code != null ? String.fromCharCode(code) : match.group(0)!;
    });

    // 3. Normalize HTML break tags into newlines
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<p\b[^>]*>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n');

    // 4. Convert basic HTML formatting into Markdown
    text = text.replaceAll(RegExp(r'</?(?:b|strong)>', caseSensitive: false), '**');
    text = text.replaceAll(RegExp(r'</?(?:i|em)>', caseSensitive: false), '*');
    text = text.replaceAllMapped(
      RegExp(r'<a\s+[^>]*href=["\x27]([^"\x27]+)["\x27][^>]*>(.*?)</a>', caseSensitive: false),
      (match) => '[${match.group(2)}](${match.group(1)})',
    );

    // 5. Strip any remaining valid HTML tags (without stripping `<Title>` or `<url>` or `<3`)
    // Matches standard HTML tag names
    text = text.replaceAll(
      RegExp(r'</?(?:div|span|h[1-6]|ul|ol|li|blockquote|pre|code|hr|table|tr|td|th|tbody|thead|tfoot|img|font|small|sub|sup)\b[^>]*>', caseSensitive: false),
      '',
    );

    // 6. Unescape backslashes before Markdown characters & punctuation
    // e.g. \*\* -> **, \** -> **, \* -> *, \[ -> [, \] -> ], \| -> |
    text = text.replaceAll(r'\*\*', '**');
    text = text.replaceAll(r'\**', '**');
    text = text.replaceAll(r'**\', '**');
    text = text.replaceAll(r'\*', '*');
    text = text.replaceAll(r'\_', '_');
    text = text.replaceAll(r'\[', '[');
    text = text.replaceAll(r'\]', ']');
    text = text.replaceAll(r'\|', '|');
    text = text.replaceAll(r'\\', r'\');

    // 7. Fix corrupted / stray backslashes surrounding tokens
    // e.g. \Original Webtoon:\|\KakaoPage\ -> Original Webtoon:|KakaoPage
    // Backslashes before ASCII letters or after words/punctuation (not escaping Markdown)
    text = text.replaceAllMapped(RegExp(r'\\([a-zA-Z])'), (m) => m.group(1)!);
    text = text.replaceAllMapped(RegExp(r'([a-zA-Z0-9_:])\\'), (m) => m.group(1)!);

    // 8. Fix malformed nested URLs in Markdown links
    // e.g. [KakaoPage]([https://page.kakao.com/...](https://page.kakao.com/...))
    // or [KakaoPage](<https://page.kakao.com/...>)
    text = text.replaceAllMapped(
      RegExp(r'\[(.*?)\]\(\[?(https?://[^\s\)]+?)\]?\((?:https?://[^\s\)]+?)\)\)'),
      (match) => '[${match.group(1)}](${match.group(2)})',
    );
    text = text.replaceAllMapped(
      RegExp(r'\[(.*?)\]\(<(https?://[^\s>]+?)>\)'),
      (match) => '[${match.group(1)}](${match.group(2)})',
    );

    // 9. Clean excessive empty lines (more than 2 consecutive newlines)
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text.trim();
  }

  /// Converts Markdown description into clean plain text for synopsis previews or clipboard.
  static String toPlainText(String raw) {
    if (raw.isEmpty) return '';

    String text = normalizeDescription(raw);

    // Links: [text](url) -> text
    text = text.replaceAllMapped(
      RegExp(r'\[(.*?)\]\(.*?\)'),
      (match) => match.group(1)!,
    );

    // Angle bracket URLs: <https://...> -> https://...
    text = text.replaceAllMapped(
      RegExp(r'<(https?://[^\s>]+)>'),
      (match) => match.group(1)!,
    );

    // Bold & italic: ***text*** -> text, **text** -> text, *text* -> text
    text = text.replaceAllMapped(RegExp(r'\*{1,3}(.*?)\*{1,3}'), (m) => m.group(1)!);
    text = text.replaceAllMapped(RegExp(r'_{1,3}(.*?)_{1,3}'), (m) => m.group(1)!);

    // Strikethrough: ~~text~~ -> text
    text = text.replaceAllMapped(RegExp(r'~~(.*?)~~'), (m) => m.group(1)!);

    // Inline code: `code` -> code
    text = text.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m.group(1)!);

    // Collapsed whitespace
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');

    return text.trim();
  }

  /// Opens an external URL safely using [launchUrl].
  static Future<void> openUrl(String url) async {
    try {
      String clean = url.trim();
      if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
        clean = 'https://$clean';
      }
      final uri = Uri.parse(clean);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _logger.warning('Could not launch external URL: $clean');
      }
    } catch (e, st) {
      _logger.warning('Failed to launch URL: $url', e, st);
    }
  }

  /// Builds a tree of [InlineSpan]s from a normalized or raw Markdown string.
  ///
  /// [registerRecognizer] should be used by StatefulWidget parents to track
  /// gesture recognizers for proper disposal in [State.dispose].
  static List<InlineSpan> buildTextSpans({
    required String text,
    required BuildContext context,
    TextStyle? baseStyle,
    void Function(String url)? onLinkTap,
    void Function(GestureRecognizer recognizer)? registerRecognizer,
  }) {
    final normalized = normalizeDescription(text);
    if (normalized.isEmpty) return const [];

    final theme = Theme.of(context);
    final fallbackStyle = baseStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          height: 1.72,
          color: context.colors.text.withValues(alpha: 0.88),
          fontSize: 15.5,
        ) ??
        const TextStyle(fontSize: 15.5, height: 1.72);

    final linkStyle = fallbackStyle.copyWith(
      color: context.colors.accent,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: context.colors.accent.withValues(alpha: 0.6),
    );

    return _parseSpans(
      input: normalized,
      baseStyle: fallbackStyle,
      linkStyle: linkStyle,
      onLinkTap: onLinkTap,
      registerRecognizer: registerRecognizer,
    );
  }

  /// Internal recursive parser for inline spans.
  static List<InlineSpan> _parseSpans({
    required String input,
    required TextStyle baseStyle,
    required TextStyle linkStyle,
    void Function(String url)? onLinkTap,
    void Function(GestureRecognizer recognizer)? registerRecognizer,
  }) {
    if (input.isEmpty) return const [];

    final spans = <InlineSpan>[];

    // Master regex matching markdown elements in order of priority:
    // 1. Markdown link: [text](url)
    // 2. Angle bracket URL: <https://...>
    // 3. Raw URL: https://...
    // 4. Bold + Italic: ***...*** or ___...___
    // 5. Bold: **...** or __...__
    // 6. Italic: *...* or _..._
    // 7. Strikethrough: ~~...~~
    // 8. Inline code: `...`
    final pattern = RegExp(
      r'(\[(?:[^\]]+)\]\((?:[^\)]+)\))|' // group 1: link
      r'(<(?:https?://[^\s>]+)>)|' // group 2: angle URL
      r'(\bhttps?://[^\s<>\)\]]+)|' // group 3: raw URL
      r'(\*\*\*(?:.+?)\*\*\*|___(?:.+?)___)|' // group 4: bold italic
      r'(\*\*(?:.+?)\*\*|__(?:.+?)__)|' // group 5: bold
      r'((?<!\*)\*(?!\*)(?:[^\*\n]+?)(?<!\*)\*(?!\*)|(?<!_)_(?!_)(?:[^_\n]+?)(?<!_)_(?!_))|' // group 6: italic
      r'(~~(?:.+?)~~)|' // group 7: strike
      r'(`(?:[^`]+)`)', // group 8: code
      dotAll: true,
    );

    int currentIndex = 0;
    for (final match in pattern.allMatches(input)) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: input.substring(currentIndex, match.start),
          style: baseStyle,
        ));
      }

      final matchedText = match.group(0)!;

      if (match.group(1) != null) {
        // Markdown link: [text](url)
        final linkMatch = RegExp(r'^\[(.*?)\]\((.*?)\)$', dotAll: true).firstMatch(matchedText);
        if (linkMatch != null) {
          final linkText = linkMatch.group(1) ?? '';
          final rawUrl = (linkMatch.group(2) ?? '').trim();
          final cleanUrl = _extractCleanUrl(rawUrl);

          final recognizer = TapGestureRecognizer()
            ..onTap = () {
              if (onLinkTap != null) {
                onLinkTap(cleanUrl);
              } else {
                openUrl(cleanUrl);
              }
            };
          registerRecognizer?.call(recognizer);

          // Recursively parse inner link text (e.g. [**Bold Link**](url))
          final innerSpans = _parseSpans(
            input: linkText,
            baseStyle: linkStyle,
            linkStyle: linkStyle,
            onLinkTap: onLinkTap,
            registerRecognizer: registerRecognizer,
          );

          spans.add(TextSpan(
            children: innerSpans,
            recognizer: recognizer,
            mouseCursor: SystemMouseCursors.click,
          ));
        } else {
          spans.add(TextSpan(text: matchedText, style: baseStyle));
        }
      } else if (match.group(2) != null) {
        // Angle bracket URL: <url>
        final rawUrl = matchedText.substring(1, matchedText.length - 1).trim();
        final recognizer = TapGestureRecognizer()
          ..onTap = () {
            if (onLinkTap != null) {
              onLinkTap(rawUrl);
            } else {
              openUrl(rawUrl);
            }
          };
        registerRecognizer?.call(recognizer);

        spans.add(TextSpan(
          text: rawUrl,
          style: linkStyle,
          recognizer: recognizer,
          mouseCursor: SystemMouseCursors.click,
        ));
      } else if (match.group(3) != null) {
        // Raw URL
        final url = matchedText.trim();
        final recognizer = TapGestureRecognizer()
          ..onTap = () {
            if (onLinkTap != null) {
              onLinkTap(url);
            } else {
              openUrl(url);
            }
          };
        registerRecognizer?.call(recognizer);

        spans.add(TextSpan(
          text: url,
          style: linkStyle,
          recognizer: recognizer,
          mouseCursor: SystemMouseCursors.click,
        ));
      } else if (match.group(4) != null) {
        // Bold + Italic: ***...*** or ___...___
        final inner = matchedText.substring(3, matchedText.length - 3);
        final style = baseStyle.copyWith(
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        );
        spans.addAll(_parseSpans(
          input: inner,
          baseStyle: style,
          linkStyle: linkStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
          onLinkTap: onLinkTap,
          registerRecognizer: registerRecognizer,
        ));
      } else if (match.group(5) != null) {
        // Bold: **...** or __...__
        final inner = matchedText.substring(2, matchedText.length - 2);
        final style = baseStyle.copyWith(fontWeight: FontWeight.bold);
        spans.addAll(_parseSpans(
          input: inner,
          baseStyle: style,
          linkStyle: linkStyle.copyWith(fontWeight: FontWeight.bold),
          onLinkTap: onLinkTap,
          registerRecognizer: registerRecognizer,
        ));
      } else if (match.group(6) != null) {
        // Italic: *...* or _..._
        final inner = matchedText.substring(1, matchedText.length - 1);
        final style = baseStyle.copyWith(fontStyle: FontStyle.italic);
        spans.addAll(_parseSpans(
          input: inner,
          baseStyle: style,
          linkStyle: linkStyle.copyWith(fontStyle: FontStyle.italic),
          onLinkTap: onLinkTap,
          registerRecognizer: registerRecognizer,
        ));
      } else if (match.group(7) != null) {
        // Strikethrough: ~~...~~
        final inner = matchedText.substring(2, matchedText.length - 2);
        final style = baseStyle.copyWith(decoration: TextDecoration.lineThrough);
        spans.addAll(_parseSpans(
          input: inner,
          baseStyle: style,
          linkStyle: linkStyle.copyWith(decoration: TextDecoration.lineThrough),
          onLinkTap: onLinkTap,
          registerRecognizer: registerRecognizer,
        ));
      } else if (match.group(8) != null) {
        // Inline code: `...`
        final inner = matchedText.substring(1, matchedText.length - 1);
        spans.add(TextSpan(
          text: inner,
          style: baseStyle.copyWith(
            fontFamily: 'monospace',
            backgroundColor: baseStyle.color?.withValues(alpha: 0.1),
          ),
        ));
      }

      currentIndex = match.end;
    }

    if (currentIndex < input.length) {
      spans.add(TextSpan(
        text: input.substring(currentIndex),
        style: baseStyle,
      ));
    }

    return spans;
  }

  /// Extracts a clean URL from potentially malformed or wrapped URLs
  /// such as `<https://...>` or nested links.
  static String _extractCleanUrl(String raw) {
    String url = raw.trim();
    if (url.startsWith('<') && url.endsWith('>')) {
      url = url.substring(1, url.length - 1).trim();
    }
    final urlMatch = RegExp(r'https?://[^\s\)<>\]]+').firstMatch(url);
    if (urlMatch != null) {
      return urlMatch.group(0)!;
    }
    return url;
  }
}
