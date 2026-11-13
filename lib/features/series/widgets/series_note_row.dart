import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/series/widgets/series_note_markdown.dart';

/// Expandable Markdown note row inside [SeriesMyListCard].
class SeriesNoteRow extends StatefulWidget {
  final String label;
  final String? note;
  final LocalizationService l10n;
  final VoidCallback onTap;

  const SeriesNoteRow({
    super.key,
    required this.label,
    required this.note,
    required this.l10n,
    required this.onTap,
  });

  @override
  State<SeriesNoteRow> createState() => _SeriesNoteRowState();
}

class _SeriesNoteRowState extends State<SeriesNoteRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final trimmed = widget.note?.trim() ?? '';
    final hasNote = trimmed.isNotEmpty;
    final isLong =
        trimmed.length > 240 || '\n'.allMatches(trimmed).length > 4;

    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label.toUpperCase(),
                      style: AppTypography.monoLabel(
                        color: c.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Icon(
                    hasNote ? Icons.edit : Icons.add,
                    size: 16,
                    color: c.textMuted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (!hasNote)
            InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    widget.l10n.translate('series_note_placeholder'),
                    style: AppTypography.sans(
                      color: c.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            )
          else ...[
            if (isLong && !_expanded)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 140),
                child: ClipRect(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: SeriesNoteMarkdown(data: trimmed),
                  ),
                ),
              )
            else
              SeriesNoteMarkdown(data: trimmed),
            if (isLong)
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    widget.l10n.translate(
                      _expanded
                          ? 'series_note_show_less'
                          : 'series_note_show_more',
                    ),
                    style: AppTypography.sans(
                      color: c.accent,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
