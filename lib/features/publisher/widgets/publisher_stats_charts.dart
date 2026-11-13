import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/publisher/utils/format_count.dart';

export 'package:mangabaka_app/features/publisher/widgets/share_bar_row.dart';

/// One labelled value in a chart.
class ChartEntry {
  final String label;
  final int count;

  /// Overrides the chart's colour for this entry (stacked bars).
  final Color? color;

  const ChartEntry(this.label, this.count, {this.color});
}

/// Vertical columns for ordered, time-like data (releases per decade): the
/// eye reads left to right as time, so the bars keep their order and share a
/// baseline. The tallest column carries the accent colour.
class ColumnChart extends StatelessWidget {
  final List<ChartEntry> entries;
  final double height;

  const ColumnChart({super.key, required this.entries, this.height = 120});

  @override
  Widget build(BuildContext context) {
    final max = entries.fold<int>(0, (m, e) => e.count > m ? e.count : m);
    if (max == 0) return const SizedBox.shrink();
    final colors = context.colors;

    return SizedBox(
      height: height + 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final e in entries)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      formatCount(e.count),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: AppTypography.sans(
                        color: colors.textMuted,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      height: (height * e.count / max).clamp(2.0, height),
                      decoration: BoxDecoration(
                        color: e.count == max
                            ? colors.accent
                            : colors.accent.withValues(alpha: 0.45),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      e.label,
                      maxLines: 1,
                      style: AppTypography.sans(
                        color: colors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One horizontal bar per category, scaled to the largest — for unordered
/// categories where the comparison between them is the point (media types).
class BarChartRows extends StatelessWidget {
  final List<ChartEntry> entries;

  const BarChartRows({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final max = entries.fold<int>(0, (m, e) => e.count > m ? e.count : m);
    if (max == 0) return const SizedBox.shrink();
    final total = entries.fold<int>(0, (s, e) => s + e.count);
    final colors = context.colors;
    return Column(
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 84,
                  child: Text(
                    e.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(
                      color: colors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: e.count / max,
                      minHeight: 8,
                      backgroundColor: colors.surfaceRaised,
                      valueColor: AlwaysStoppedAnimation(colors.accent),
                    ),
                  ),
                ),
                SizedBox(
                  width: 92,
                  child: Text(
                    '${formatCount(e.count)} · ${_percent(e.count, total)}',
                    textAlign: TextAlign.end,
                    style: AppTypography.sans(
                      color: colors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A single bar divided into segments with a legend — for a few categories
/// that make up a whole (publication status, content rating).
class StackedBarChart extends StatelessWidget {
  final List<ChartEntry> entries;

  const StackedBarChart({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<int>(0, (s, e) => s + e.count);
    if (total == 0) return const SizedBox.shrink();
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                for (final e in entries)
                  if (e.count > 0)
                    Expanded(
                      flex: e.count,
                      child: Container(
                        margin: const EdgeInsets.only(right: 1),
                        color: e.color ?? colors.accent,
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (final e in entries)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: e.color ?? colors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${e.label} ${_percent(e.count, total)}',
                    style: AppTypography.sans(
                      color: colors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

String _percent(int part, int total) {
  if (total == 0) return '0%';
  final p = part * 100 / total;
  return '${p.toStringAsFixed(p < 10 ? 1 : 0)}%';
}
