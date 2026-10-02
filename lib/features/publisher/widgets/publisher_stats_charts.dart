import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/publisher/utils/format_count.dart';

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

/// A tag's share of the publisher's catalog against its share of the whole
/// site. The bar is the publisher's share; the tick marks the site-wide share,
/// so a bar well past its tick is something the publisher is *known for*.
class ShareBarRow extends StatelessWidget {
  final String label;
  final double share;
  final double catalogShare;
  final int count;
  final VoidCallback? onTap;

  const ShareBarRow({
    super.key,
    required this.label,
    required this.share,
    required this.catalogShare,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        child: Row(
          children: [
            SizedBox(
              width: 112,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.sans(
                  color: onTap == null ? colors.textMuted : colors.text,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final tick = (catalogShare.clamp(0.0, 1.0) * w);
                  return SizedBox(
                    height: 12,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors.surfaceRaised,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          height: 8,
                          width: share.clamp(0.0, 1.0) * w,
                          decoration: BoxDecoration(
                            color: colors.accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Positioned(
                          left: tick - 1,
                          child: Container(
                            width: 2,
                            height: 12,
                            color: colors.text.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: 64,
              child: Text(
                '${(share * 100).toStringAsFixed(share < 0.1 ? 1 : 0)}%',
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
    );
  }
}

String _percent(int part, int total) {
  if (total == 0) return '0%';
  final p = part * 100 / total;
  return '${p.toStringAsFixed(p < 10 ? 1 : 0)}%';
}
