import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/features/profile/widgets/statistic_card.dart';
import 'package:mangabaka_app/features/profile/screens/statistics_screen.dart';

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
              l10n.translate('at_a_glance'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
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
                style: TextStyle(
                  color: AppConstants.accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.translate('overview_desc'),
          style: TextStyle(color: AppConstants.textMutedColor),
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
