import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/mb_card.dart';
import 'package:mangabaka_app/features/series/widgets/series_my_list_rows.dart';
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
            SeriesProgressRow(
              label: l10n.translate('chapters'),
              value: entry.progressChapter ?? 0,
              total: chapterTotal,
              onTap: onUpdateChapter,
              statusColor: statusColor,
            ),
          ],
          if (hasVolumes) ...[
            const SizedBox(height: 16),
            SeriesProgressRow(
              label: l10n.translate('volumes'),
              value: entry.progressVolume ?? 0,
              total: volumeTotal,
              onTap: onUpdateVolume,
              statusColor: statusColor,
            ),
          ],
          const SizedBox(height: 16),
          SeriesScoreRow(
            label: l10n.translate('rating'),
            rating: entry.rating ?? 0,
            onTap: onUpdateRating,
            statusColor: statusColor,
          ),
          const SizedBox(height: 16),
          SeriesNoteRow(
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
