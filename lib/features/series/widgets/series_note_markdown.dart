import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:url_launcher/url_launcher.dart';

/// Renders a series note using full Markdown (CommonMark / GFM) styled to
/// match the active MangaBaka theme.
class SeriesNoteMarkdown extends StatelessWidget {
  final String data;
  final bool selectable;

  const SeriesNoteMarkdown({
    super.key,
    required this.data,
    this.selectable = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bodyStyle = AppTypography.sans(
      color: c.text,
      fontSize: 13.5,
      height: 1.5,
    );

    return MarkdownBody(
      data: data,
      selectable: selectable,
      softLineBreak: true,
      onTapLink: (text, href, title) {
        if (href == null) return;
        final uri = Uri.tryParse(href);
        if (uri != null &&
            (uri.scheme == 'http' || uri.scheme == 'https')) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: bodyStyle,
        pPadding: const EdgeInsets.only(bottom: 6),
        a: bodyStyle.copyWith(
          color: c.accent,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: c.accent,
        ),
        strong: bodyStyle.copyWith(fontWeight: FontWeight.w700),
        em: bodyStyle.copyWith(fontStyle: FontStyle.italic),
        del: bodyStyle.copyWith(
          decoration: TextDecoration.lineThrough,
          color: c.textMuted,
        ),
        h1: AppTypography.display(
          color: c.text,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        h2: AppTypography.display(
          color: c.text,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        h3: AppTypography.display(
          color: c.text,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
        h4: bodyStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
        h5: bodyStyle.copyWith(fontWeight: FontWeight.w700),
        h6: bodyStyle.copyWith(
          color: c.textMuted,
          fontWeight: FontWeight.w700,
        ),
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12.5,
          color: c.text,
          backgroundColor: c.surfaceRaised,
        ),
        codeblockDecoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.border),
        ),
        codeblockPadding: const EdgeInsets.all(10),
        blockquote: bodyStyle.copyWith(color: c.textMuted),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: c.accent.withValues(alpha: 0.7),
              width: 3,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
        listBullet: bodyStyle.copyWith(color: c.textMuted),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.border, width: 1)),
        ),
        tableBorder: TableBorder.all(color: c.border, width: 1),
        tableHead: bodyStyle.copyWith(fontWeight: FontWeight.w700),
        tableBody: bodyStyle,
        checkbox: TextStyle(color: c.accent),
      ),
    );
  }
}
