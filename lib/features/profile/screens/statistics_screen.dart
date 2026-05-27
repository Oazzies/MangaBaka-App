import 'package:mangabaka_app/features/profile/widgets/statistics/statistics_data_mixin.dart';
import 'package:mangabaka_app/features/profile/widgets/statistics/standout_pick_card.dart';
import 'package:mangabaka_app/features/profile/widgets/statistic_card.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/theme/theme_manager.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/library/services/mappers/db_to_api_mapper.dart';
import 'package:mangabaka_app/database/database.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with StatisticsDataMixin {
  @override
  void initState() {
    super.initState();
    initStatistics();
  }

  void _openSeriesDetail(LibraryEntryWithSeries entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeriesDetailScreen(
          series: DbToApiMapper.seriesFromDb(entry.series),
        ),
      ),
    );
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
            centerTitle: true,
            title: Text(
              l10n.translate('statistics'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: -0.5,
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
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow([
                          _StatData(Icons.book, l10n.translate('total_series'), '$totalSeries'),
                          _StatData(Icons.article, l10n.translate('chapters_read'), '$chaptersRead'),
                        ]),
                        const SizedBox(height: 16),
                        _buildStatRow([
                          _StatData(Icons.library_books, l10n.translate('volumes_read'), '$volumesRead'),
                          _StatData(Icons.check_circle, l10n.translate('completion'), '${completionRate.toStringAsFixed(1)}%'),
                        ]),
                        const SizedBox(height: 16),
                        _buildStatRow([
                          _StatData(Icons.replay, l10n.translate('total_rereads'), '$totalRereads'),
                          _StatData(Icons.star, l10n.translate('mean_score'), meanScore.toStringAsFixed(1)),
                        ]),
                        const SizedBox(height: 16),
                        _buildStatRow([
                          _StatData(Icons.flag, l10n.translate('finish_rate'), '${finishRate.toStringAsFixed(1)}%'),
                        ]),
                        const SizedBox(height: 32),
                        Text(
                          l10n.translate('standout_picks'),
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (highestRated != null)
                          StandoutPickCard(
                            icon: Icons.star_rounded,
                            label: l10n.translate('highest_rated'),
                            title: highestRated!.series.title,
                            value: '${l10n.translate('score')}: ${highestRated!.libraryEntry.rating ?? 0}',
                            onTap: () => _openSeriesDetail(highestRated!),
                          ),
                        if (mostReread != null) ...[
                          const SizedBox(height: 16),
                          StandoutPickCard(
                            icon: Icons.replay_rounded,
                            label: l10n.translate('most_reread'),
                            title: mostReread!.series.title,
                            value: '${mostReread!.libraryEntry.numberOfRereads} ${l10n.translate('rereads')}',
                            onTap: () => _openSeriesDetail(mostReread!),
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

  Widget _buildStatRow(List<_StatData> stats) {
    return Row(
      children: [
        for (int i = 0; i < stats.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < stats.length - 1 ? 16 : 0),
              child: StatisticCard(
                icon: stats[i].icon,
                label: stats[i].label,
                value: stats[i].value,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatData {
  final IconData icon;
  final String label;
  final String value;

  const _StatData(this.icon, this.label, this.value);
}
