import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/markdown_normalizer.dart';
import 'package:url_launcher/url_launcher.dart';

/// Utility for cleaning, normalizing, and rendering Markdown descriptions.
class MarkdownUtils {
  static final _logger = LoggingService.logger;

  static final RegExp _spanPattern = RegExp(
    r'(\[(?:[^\]]+)\]\((?:[^\)]+)\))|'
    r'(<(?:https?://[^\s>]+)>)|'
    r'(\bhttps?://[^\s<>\)\]]+)|'
    r'(\*\*\*(?:.+?)\*\*\*|___(?:.+?)___)|'
    r'(\*\*(?:.+?)\*\*|__(?:.+?)__)|'
    r'((?<!\*)\*(?!\*)(?:[^\*\n]+?)(?<!\*)\*(?!\*)|(?<!_)_(?!_)(?:[^_\n]+?)(?<!_)_(?!_))|'
    r'(~~(?:.+?)~~)|'
    r'(`(?:[^`]+)`)',
    dotAll: true,
  );

  static String normalizeDescription(String raw) =>
      MarkdownNormalizer.normalizeDescription(raw);

  static String toPlainText(String raw) => MarkdownNormalizer.toPlainText(raw);

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

  /// Builds [InlineSpan]s from a Markdown string.
  ///
  /// Pass [registerRecognizer] to track gesture recognizers for disposal.
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
    final fallbackStyle =
        baseStyle ??
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

  static TapGestureRecognizer _makeTapRecognizer(
    String url,
    void Function(String url)? onLinkTap,
    void Function(GestureRecognizer recognizer)? registerRecognizer,
  ) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () {
        if (onLinkTap != null) {
          onLinkTap(url);
        } else {
          openUrl(url);
        }
      };
    registerRecognizer?.call(recognizer);
    return recognizer;
  }

  static List<InlineSpan> _parseSpans({
    required String input,
    required TextStyle baseStyle,
    required TextStyle linkStyle,
    void Function(String url)? onLinkTap,
    void Function(GestureRecognizer recognizer)? registerRecognizer,
  }) {
    if (input.isEmpty) return const [];

    final spans = <InlineSpan>[];
    int currentIndex = 0;

    for (final match in _spanPattern.allMatches(input)) {
      if (match.start > currentIndex) {
        spans.add(
          TextSpan(
            text: input.substring(currentIndex, match.start),
            style: baseStyle,
          ),
        );
      }

      final matchedText = match.group(0)!;

      if (match.group(1) != null) {
        final linkMatch = RegExp(
          r'^\[(.*?)\]\((.*?)\)$',
          dotAll: true,
        ).firstMatch(matchedText);
        if (linkMatch != null) {
          final linkText = linkMatch.group(1) ?? '';
          final cleanUrl = _extractCleanUrl((linkMatch.group(2) ?? '').trim());
          final recognizer = _makeTapRecognizer(
            cleanUrl,
            onLinkTap,
            registerRecognizer,
          );
          final innerSpans = _parseSpans(
            input: linkText,
            baseStyle: linkStyle,
            linkStyle: linkStyle,
            onLinkTap: onLinkTap,
            registerRecognizer: registerRecognizer,
          );
          spans.add(
            TextSpan(
              children: innerSpans,
              recognizer: recognizer,
              mouseCursor: SystemMouseCursors.click,
            ),
          );
        } else {
          spans.add(TextSpan(text: matchedText, style: baseStyle));
        }
      } else if (match.group(2) != null) {
        final rawUrl = matchedText.substring(1, matchedText.length - 1).trim();
        final recognizer = _makeTapRecognizer(
          rawUrl,
          onLinkTap,
          registerRecognizer,
        );
        spans.add(
          TextSpan(
            text: rawUrl,
            style: linkStyle,
            recognizer: recognizer,
            mouseCursor: SystemMouseCursors.click,
          ),
        );
      } else if (match.group(3) != null) {
        final url = matchedText.trim();
        final recognizer = _makeTapRecognizer(
          url,
          onLinkTap,
          registerRecognizer,
        );
        spans.add(
          TextSpan(
            text: url,
            style: linkStyle,
            recognizer: recognizer,
            mouseCursor: SystemMouseCursors.click,
          ),
        );
      } else if (match.group(4) != null) {
        _addStyledInner(
          spans: spans,
          inner: matchedText.substring(3, matchedText.length - 3),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
          linkStyle: linkStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
          onLinkTap: onLinkTap,
          registerRecognizer: registerRecognizer,
        );
      } else if (match.group(5) != null) {
        _addStyledInner(
          spans: spans,
          inner: matchedText.substring(2, matchedText.length - 2),
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
          linkStyle: linkStyle.copyWith(fontWeight: FontWeight.bold),
          onLinkTap: onLinkTap,
          registerRecognizer: registerRecognizer,
        );
      } else if (match.group(6) != null) {
        _addStyledInner(
          spans: spans,
          inner: matchedText.substring(1, matchedText.length - 1),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          linkStyle: linkStyle.copyWith(fontStyle: FontStyle.italic),
          onLinkTap: onLinkTap,
          registerRecognizer: registerRecognizer,
        );
      } else if (match.group(7) != null) {
        _addStyledInner(
          spans: spans,
          inner: matchedText.substring(2, matchedText.length - 2),
          style: baseStyle.copyWith(decoration: TextDecoration.lineThrough),
          linkStyle: linkStyle.copyWith(decoration: TextDecoration.lineThrough),
          onLinkTap: onLinkTap,
          registerRecognizer: registerRecognizer,
        );
      } else if (match.group(8) != null) {
        spans.add(
          TextSpan(
            text: matchedText.substring(1, matchedText.length - 1),
            style: baseStyle.copyWith(
              fontFamily: 'monospace',
              backgroundColor: baseStyle.color?.withValues(alpha: 0.1),
            ),
          ),
        );
      }

      currentIndex = match.end;
    }

    if (currentIndex < input.length) {
      spans.add(
        TextSpan(text: input.substring(currentIndex), style: baseStyle),
      );
    }

    return spans;
  }

  static void _addStyledInner({
    required List<InlineSpan> spans,
    required String inner,
    required TextStyle style,
    required TextStyle linkStyle,
    void Function(String url)? onLinkTap,
    void Function(GestureRecognizer recognizer)? registerRecognizer,
  }) {
    spans.addAll(
      _parseSpans(
        input: inner,
        baseStyle: style,
        linkStyle: linkStyle,
        onLinkTap: onLinkTap,
        registerRecognizer: registerRecognizer,
      ),
    );
  }

  static String _extractCleanUrl(String raw) {
    String url = raw.trim();
    if (url.startsWith('<') && url.endsWith('>')) {
      url = url.substring(1, url.length - 1).trim();
    }
    final urlMatch = RegExp(r'https?://[^\s\)<>\]]+').firstMatch(url);
    return urlMatch?.group(0) ?? url;
  }
}
