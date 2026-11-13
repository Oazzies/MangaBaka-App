/// Cleans, normalizes, and strips Markdown/HTML in series descriptions.
abstract final class MarkdownNormalizer {
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

  static String normalizeDescription(String raw) {
    if (raw.isEmpty) return '';

    String text = raw;

    for (final entry in _mojibake.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }

    for (final entry in _htmlEntities.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      final code = int.tryParse(match.group(1)!);
      return _isValidCodePoint(code)
          ? String.fromCharCode(code!)
          : match.group(0)!;
    });
    text = text.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
      final code = int.tryParse(match.group(1)!, radix: 16);
      return _isValidCodePoint(code)
          ? String.fromCharCode(code!)
          : match.group(0)!;
    });

    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<p\b[^>]*>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n');

    text = text.replaceAll(
      RegExp(r'</?(?:b|strong)>', caseSensitive: false),
      '**',
    );
    text = text.replaceAll(RegExp(r'</?(?:i|em)>', caseSensitive: false), '*');
    text = text.replaceAllMapped(
      RegExp(
        r'<a\s+[^>]*href=["\x27]([^"\x27]+)["\x27][^>]*>(.*?)</a>',
        caseSensitive: false,
      ),
      (match) => '[${match.group(2)}](${match.group(1)})',
    );

    text = text.replaceAll(
      RegExp(
        r'</?(?:div|span|h[1-6]|ul|ol|li|blockquote|pre|code|hr|table|tr|td|th|tbody|thead|tfoot|img|font|small|sub|sup)\b[^>]*>',
        caseSensitive: false,
      ),
      '',
    );

    text = text.replaceAll(r'\*\*', '**');
    text = text.replaceAll(r'\**', '**');
    text = text.replaceAll(r'**\', '**');
    text = text.replaceAll(r'\*', '*');
    text = text.replaceAll(r'\_', '_');
    text = text.replaceAll(r'\[', '[');
    text = text.replaceAll(r'\]', ']');
    text = text.replaceAll(r'\|', '|');
    text = text.replaceAll(r'\\', r'\');

    text = text.replaceAllMapped(RegExp(r'\\([a-zA-Z])'), (m) => m.group(1)!);
    text = text.replaceAllMapped(
      RegExp(r'([a-zA-Z0-9_:])\\'),
      (m) => m.group(1)!,
    );

    text = text.replaceAllMapped(
      RegExp(
        r'\[(.*?)\]\(\[?(https?://[^\s\)]+?)\]?\((?:https?://[^\s\)]+?)\)\)',
      ),
      (match) => '[${match.group(1)}](${match.group(2)})',
    );
    text = text.replaceAllMapped(
      RegExp(r'\[(.*?)\]\(<(https?://[^\s>]+?)>\)'),
      (match) => '[${match.group(1)}](${match.group(2)})',
    );

    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text.trim();
  }

  /// Rejects out-of-range or surrogate code points so untrusted HTML entities
  /// cannot crash text rendering.
  static bool _isValidCodePoint(int? code) =>
      code != null &&
      code >= 0 &&
      code <= 0x10FFFF &&
      (code < 0xD800 || code > 0xDFFF);

  static String toPlainText(String raw) {
    if (raw.isEmpty) return '';

    String text = normalizeDescription(raw);

    text = text.replaceAllMapped(
      RegExp(r'\[(.*?)\]\(.*?\)'),
      (match) => match.group(1)!,
    );
    text = text.replaceAllMapped(
      RegExp(r'<(https?://[^\s>]+)>'),
      (match) => match.group(1)!,
    );
    text = text.replaceAllMapped(
      RegExp(r'\*{1,3}(.*?)\*{1,3}'),
      (m) => m.group(1)!,
    );
    text = text.replaceAllMapped(
      RegExp(r'_{1,3}(.*?)_{1,3}'),
      (m) => m.group(1)!,
    );
    text = text.replaceAllMapped(RegExp(r'~~(.*?)~~'), (m) => m.group(1)!);
    text = text.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m.group(1)!);
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');

    return text.trim();
  }
}
