import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/mb_card.dart';
import 'package:mangabaka_app/features/series/widgets/state_selection_section.dart';

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

  const SeriesMyListCard({
    super.key,
    required this.series,
    required this.entry,
    required this.l10n,
    required this.onStateChanged,
    required this.onUpdateChapter,
    required this.onUpdateVolume,
    required this.onUpdateRating,
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

    return MbCard(
      label: l10n.translate('library'),
      trailing: pct != null
          ? Text(
              '${(pct * 100).round()}%',
              style: AppTypography.mono(
                color: AppConstants.accentColor,
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
            ),
          ],
          if (hasVolumes) ...[
            const SizedBox(height: 16),
            _ProgressRow(
              label: l10n.translate('volumes'),
              value: entry.progressVolume ?? 0,
              total: volumeTotal,
              onTap: onUpdateVolume,
            ),
          ],
          const SizedBox(height: 16),
          _ScoreRow(
            label: l10n.translate('rating'),
            rating: entry.rating ?? 0,
            onTap: onUpdateRating,
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

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.total,
    required this.onTap,
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
                  label,
                  style: AppTypography.sans(
                    color: AppConstants.textMutedColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$value',
                      style: AppTypography.mono(
                        color: AppConstants.accentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: ' / $totalLabel',
                      style: AppTypography.mono(
                        color: AppConstants.textColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.add, size: 16, color: AppConstants.textMutedColor),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 7,
              decoration: BoxDecoration(
                color: AppConstants.tertiaryBackground,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppConstants.borderColor, width: 1),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.accentColor,
                        Color.lerp(
                          AppConstants.accentColor,
                          Colors.white,
                          0.28,
                        )!,
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

  const _ScoreRow({
    required this.label,
    required this.rating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (rating / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppConstants.borderColor, width: 1),
        ),
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
                    label,
                    style: AppTypography.sans(
                      color: AppConstants.textMutedColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: rating > 0 ? '$rating' : '–',
                        style: AppTypography.mono(
                          color: AppConstants.accentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: ' / 100',
                        style: AppTypography.mono(
                          color: AppConstants.textColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.edit, size: 16, color: AppConstants.textMutedColor),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 7,
                decoration: BoxDecoration(
                  color: AppConstants.tertiaryBackground,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppConstants.borderColor, width: 1),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: pct,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: [
                          AppConstants.accentColor,
                          Color.lerp(
                            AppConstants.accentColor,
                            Colors.white,
                            0.28,
                          )!,
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
