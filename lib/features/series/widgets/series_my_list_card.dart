import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/mb_card.dart';
import 'package:mangabaka_app/features/series/widgets/series_note_markdown.dart';
import 'package:mangabaka_app/features/series/widgets/state_selection_section.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The "My List" tracking card from the design: a full-width status selector,
/// chapter/volume progress bars, and a 5-star score (mapped from the app's
/// 0–100 scale). Mirrors the design's tracking widget while reusing the app's
/// existing state/progress/rating plumbing.
class SeriesMyListCard extends StatelessWidget {
  final Series series;
  final LibraryEntry entry;
  final LocalizationService l10n;
  final Function(String) onStateChanged;
  final VoidCallback onUpdateChapter;
  final VoidCallback onUpdateVolume;
  final VoidCallback onUpdateRating;
  final VoidCallback onUpdateNote;

  const SeriesMyListCard({
    super.key,
    required this.series,
    required this.entry,
    required this.l10n,
    required this.onStateChanged,
    required this.onUpdateChapter,
    required this.onUpdateVolume,
    required this.onUpdateRating,
    required this.onUpdateNote,
  });

  int? _parseTotal(String raw) {
    if (raw.isEmpty || raw == 'null') return null;
    return int.tryParse(raw);
  }

  @override
  Widget build(BuildContext context) {
    final chapterTotal = _parseTotal(series.totalChapters);
    final volumeTotal = _parseTotal(series.finalVolume);
    final hasChapters =
        series.totalChapters.isNotEmpty && series.totalChapters != 'null';
    final hasVolumes =
        series.finalVolume.isNotEmpty && series.finalVolume != 'null';

    final pct = (chapterTotal != null && chapterTotal > 0)
        ? ((entry.progressChapter ?? 0) / chapterTotal).clamp(0.0, 1.0)
        : null;

    final statusColor = context.colors.forState(entry.state);

    return MbCard(
      label: l10n.translate('library'),
      trailing: pct != null
          ? Text(
              '${(pct * 100).round()}%',
              style: AppTypography.sans(
                color: statusColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StateSelectionSection(
            currentState: entry.state,
            onStateChanged: onStateChanged,
          ),
          if (hasChapters) ...[
            const SizedBox(height: 18),
            _ProgressRow(
              label: l10n.translate('chapters'),
              value: entry.progressChapter ?? 0,
              total: chapterTotal,
              onTap: onUpdateChapter,
              statusColor: statusColor,
            ),
          ],
          if (hasVolumes) ...[
            const SizedBox(height: 16),
            _ProgressRow(
              label: l10n.translate('volumes'),
              value: entry.progressVolume ?? 0,
              total: volumeTotal,
              onTap: onUpdateVolume,
              statusColor: statusColor,
            ),
          ],
          const SizedBox(height: 16),
          _ScoreRow(
            label: l10n.translate('rating'),
            rating: entry.rating ?? 0,
            onTap: onUpdateRating,
            statusColor: statusColor,
          ),
          const SizedBox(height: 16),
          _NoteRow(
            label: l10n.translate('notes'),
            note: entry.note,
            l10n: l10n,
            onTap: onUpdateNote,
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int value;
  final int? total;
  final VoidCallback onTap;
  final Color statusColor;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.total,
    required this.onTap,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (total != null && total! > 0)
        ? (value / total!).clamp(0.0, 1.0)
        : 0.0;
    final totalLabel = total != null ? '$total' : '?';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTypography.monoLabel(
                    color: context.colors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$value',
                      style: AppTypography.sans(
                        color: statusColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: ' / $totalLabel',
                      style: AppTypography.sans(
                        color: context.colors.text,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.add, size: 16, color: context.colors.textMuted),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 7,
              decoration: BoxDecoration(
                color: context.colors.surfaceRaised,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: context.colors.border, width: 1),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      colors: [
                        statusColor,
                        context.colors.hoverOf(statusColor, 0.28),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int rating; // 0–100
  final VoidCallback onTap;
  final Color statusColor;

  const _ScoreRow({
    required this.label,
    required this.rating,
    required this.onTap,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (rating / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.colors.border, width: 1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: AppTypography.monoLabel(
                      color: context.colors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: rating > 0 ? '$rating' : '–',
                        style: AppTypography.sans(
                          color: statusColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: ' / 100',
                        style: AppTypography.sans(
                          color: context.colors.text,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.edit, size: 16, color: context.colors.textMuted),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 7,
                decoration: BoxDecoration(
                  color: context.colors.surfaceRaised,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: context.colors.border, width: 1),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: pct,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: [
                          statusColor,
                          context.colors.hoverOf(statusColor, 0.28),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteRow extends StatefulWidget {
  final String label;
  final String? note;
  final LocalizationService l10n;
  final VoidCallback onTap;

  const _NoteRow({
    required this.label,
    required this.note,
    required this.l10n,
    required this.onTap,
  });

  @override
  State<_NoteRow> createState() => _NoteRowState();
}

class _NoteRowState extends State<_NoteRow> {
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
