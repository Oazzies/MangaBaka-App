import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/publisher/utils/format_count.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_panel.dart';

class PublisherStatsStyleToggle extends StatelessWidget {
  final bool charts;

  const PublisherStatsStyleToggle({super.key, required this.charts});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget button(IconData icon, bool selected, PublisherStatsStyle style) =>
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => SettingsManager().setPublisherStatsStyle(style),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: selected ? colors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: selected ? colors.onAccent : colors.textMuted,
            ),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(Icons.bar_chart_rounded, charts, PublisherStatsStyle.charts),
        button(Icons.view_list_rounded, !charts, PublisherStatsStyle.list),
      ],
    );
  }
}

class PublisherStatTile extends StatelessWidget {
  final String label;
  final String value;

  const PublisherStatTile({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.display(
            color: context.colors.accent,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 2),
        PublisherSubLabel(label),
      ],
    );
  }
}

class PublisherStatBarList extends StatelessWidget {
  final List<(String, int)> entries;

  const PublisherStatBarList({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final max = entries.fold<int>(0, (m, e) => e.$2 > m ? e.$2 : m);
    if (max == 0) return const SizedBox.shrink();
    return Column(
      children: [
        for (final (label, count) in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 88,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(
                      color: context.colors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: count / max,
                      minHeight: 8,
                      backgroundColor: context.colors.surfaceRaised,
                      valueColor: AlwaysStoppedAnimation(context.colors.accent),
                    ),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    formatCount(count),
                    textAlign: TextAlign.end,
                    style: AppTypography.sans(
                      color: context.colors.text,
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
