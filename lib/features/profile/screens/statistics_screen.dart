import 'package:mangabaka_app/features/profile/widgets/statistics/statistics_data_mixin.dart';
import 'package:mangabaka_app/features/profile/widgets/statistics/standout_pick_card.dart';
import 'package:mangabaka_app/features/profile/widgets/statistic_card.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/theme/theme_manager.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/library/services/mappers/db_to_api_mapper.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with StatisticsDataMixin {
  @override
  void initState() {
    super.initState();
    initStatistics();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), ThemeManager()]),
      builder: (context, _) {
        final l10n = LocalizationService();

        return Scaffold(
          backgroundColor: AppConstants.primaryBackground,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: AppConstants.primaryBackground,
            elevation: 0,
            centerTitle: true,
            title: Text(
              l10n.translate('statistics'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          body: WidgetUtils.responsiveConstraint(
            loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('reading_stats'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                          context,
                          [
                            _StatData(
                              icon: Icons.book,
                              label: l10n.translate('total_series'),
                              value: '$totalSeries',
                            ),
                            _StatData(
                              icon: Icons.article,
                              label: l10n.translate('chapters_read'),
                              value: '$chaptersRead',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                          context,
                          [
                            _StatData(
                              icon: Icons.library_books,
                              label: l10n.translate('volumes_read'),
                              value: '$volumesRead',
                            ),
                            _StatData(
                              icon: Icons.check_circle,
                              label: l10n.translate('completion'),
                              value: '${completionRate.toStringAsFixed(1)}%',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                          context,
                          [
                            _StatData(
                              icon: Icons.replay,
                              label: l10n.translate('total_rereads'),
                              value: '$totalRereads',
                            ),
                            _StatData(
                              icon: Icons.star,
                              label: l10n.translate('mean_score'),
                              value: meanScore.toStringAsFixed(1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                          context,
                          [
                            _StatData(
                              icon: Icons.flag,
                              label: l10n.translate('finish_rate'),
                              value: '${finishRate.toStringAsFixed(1)}%',
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          l10n.translate('standout_picks'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (highestRated != null)
                          StandoutPickCard(
                            icon: Icons.star_rounded,
                            label: l10n.translate('highest_rated'),
                            title: highestRated!.series.title,
                            value: '${l10n.translate('score')}: ${highestRated!.libraryEntry.rating ?? 0}',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SeriesDetailScreen(
                                    series: DbToApiMapper.seriesFromDb(highestRated!.series),
                                  ),
                                ),
                              );
                            },
                          ),
                        if (mostReread != null) ...[
                          const SizedBox(height: 16),
                          StandoutPickCard(
                            icon: Icons.replay_rounded,
                            label: l10n.translate('most_reread'),
                            title: mostReread!.series.title,
                            value: '${mostReread!.libraryEntry.numberOfRereads} ${l10n.translate('rereads')}',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SeriesDetailScreen(
                                    series: DbToApiMapper.seriesFromDb(mostReread!.series),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildStatRow(BuildContext context, List<_StatData> stats) {
    return Row(
      children: stats.map((stat) {
        final isLast = stats.indexOf(stat) == stats.length - 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 16),
            child: StatisticCard(
              icon: stat.icon,
              label: stat.label,
              value: stat.value,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatData {
  final IconData icon;
  final String label;
  final String value;

  _StatData({required this.icon, required this.label, required this.value});
}
