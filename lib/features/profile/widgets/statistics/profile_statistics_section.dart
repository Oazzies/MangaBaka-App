import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/profile/widgets/statistics/statistic_card.dart';
import 'package:mangabaka_app/features/profile/screens/statistics_screen.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class ProfileStatisticsSection extends StatelessWidget {
  final int totalSeries;
  final int chaptersRead;
  final int volumesRead;
  final double meanScore;

  const ProfileStatisticsSection({
    super.key,
    required this.totalSeries,
    required this.chaptersRead,
    required this.volumesRead,
    required this.meanScore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.translate('at_a_glance').toUpperCase(),
              style: AppTypography.display(
                color: context.colors.text,
                fontSize: 20,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StatisticsScreen(),
                  ),
                );
              },
              child: Text(
                l10n.translate('see_more_stats'),
                style: AppTypography.sans(
                  color: context.colors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.translate('overview_desc'),
          style: AppTypography.sans(color: context.colors.textMuted),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatisticCard(
                icon: Icons.book,
                label: l10n.translate('total_series'),
                value: '$totalSeries',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatisticCard(
                icon: Icons.article,
                label: l10n.translate('chapters_read'),
                value: '$chaptersRead',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatisticCard(
                icon: Icons.library_books,
                label: l10n.translate('volumes_read'),
                value: '$volumesRead',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatisticCard(
                icon: Icons.star,
                label: l10n.translate('mean_score'),
                value: meanScore.toStringAsFixed(1),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
