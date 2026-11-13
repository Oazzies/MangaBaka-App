import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

export 'package:mangabaka_app/features/series/widgets/series_note_row.dart';

/// Chapter / volume progress bar row inside [SeriesMyListCard].
class SeriesProgressRow extends StatelessWidget {
  final String label;
  final int value;
  final int? total;
  final VoidCallback onTap;
  final Color statusColor;

  const SeriesProgressRow({
    super.key,
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

/// 0-100 rating row inside [SeriesMyListCard].
class SeriesScoreRow extends StatelessWidget {
  final String label;
  final int rating;
  final VoidCallback onTap;
  final Color statusColor;

  const SeriesScoreRow({
    super.key,
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
