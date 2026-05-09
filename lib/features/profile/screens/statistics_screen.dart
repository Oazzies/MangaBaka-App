import 'package:bakahyou/database/database.dart';
import 'package:bakahyou/features/profile/services/statistics_service.dart';
import 'package:bakahyou/features/profile/widgets/statistic_card.dart';
import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';
import 'package:bakahyou/features/series/screens/series_detail_screen.dart';
import 'package:bakahyou/features/library/services/mappers/db_to_api_mapper.dart';
import 'package:bakahyou/features/series/models/series.dart' as api;

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late final StatisticsService _statisticsService;
  bool _loading = true;

  int _totalSeries = 0;
  int _chaptersRead = 0;
  int _volumesRead = 0;
  double _completionRate = 0.0;
  int _totalRereads = 0;
  double _meanScore = 0.0;
  double _finishRate = 0.0;
  LibraryEntryWithSeries? _highestRated;
  LibraryEntryWithSeries? _mostReread;

  @override
  void initState() {
    super.initState();
    _statisticsService = StatisticsService(getIt<AppDatabase>());
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    final results = await Future.wait([
      _statisticsService.getTotalSeries(),
      _statisticsService.getChaptersRead(),
      _statisticsService.getVolumesRead(),
      _statisticsService.getCompletionRate(),
      _statisticsService.getTotalRereads(),
      _statisticsService.getMeanScore(),
      _statisticsService.getFinishRate(),
      _statisticsService.getHighestRatedSeries(),
      _statisticsService.getMostRereadSeries(),
    ]);

    if (!mounted) return;

    setState(() {
      _totalSeries = results[0] as int;
      _chaptersRead = results[1] as int;
      _volumesRead = results[2] as int;
      _completionRate = results[3] as double;
      _totalRereads = results[4] as int;
      _meanScore = results[5] as double;
      _finishRate = results[6] as double;
      _highestRated = results[7] as LibraryEntryWithSeries?;
      _mostReread = results[8] as LibraryEntryWithSeries?;
      _loading = false;
    });
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
          body: _loading
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
                            value: '$_totalSeries',
                          ),
                          _StatData(
                            icon: Icons.article,
                            label: l10n.translate('chapters_read'),
                            value: '$_chaptersRead',
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
                            value: '$_volumesRead',
                          ),
                          _StatData(
                            icon: Icons.check_circle,
                            label: l10n.translate('completion'),
                            value: '${_completionRate.toStringAsFixed(1)}%',
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
                            value: '$_totalRereads',
                          ),
                          _StatData(
                            icon: Icons.star,
                            label: l10n.translate('mean_score'),
                            value: _meanScore.toStringAsFixed(1),
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
                            value: '${_finishRate.toStringAsFixed(1)}%',
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
                      if (_highestRated != null)
                        _buildStandoutItem(
                          context,
                          icon: Icons.star_rounded,
                          label: l10n.translate('highest_rated'),
                          title: _highestRated!.series.title,
                          value: '${l10n.translate('score')}: ${_highestRated!.libraryEntry.rating ?? 0}',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SeriesDetailScreen(
                                  series: DbToApiMapper.seriesFromDb(_highestRated!.series),
                                ),
                              ),
                            );
                          },
                        ),
                      if (_mostReread != null) ...[
                        const SizedBox(height: 16),
                        _buildStandoutItem(
                          context,
                          icon: Icons.replay_rounded,
                          label: l10n.translate('most_reread'),
                          title: _mostReread!.series.title,
                          value: '${_mostReread!.libraryEntry.numberOfRereads} ${l10n.translate('rereads')}',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SeriesDetailScreen(
                                  series: DbToApiMapper.seriesFromDb(_mostReread!.series),
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
        );
      },
    );
  }

  Widget _buildStandoutItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppConstants.textColor, size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: AppConstants.textMutedColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Text(
              title,
              style: TextStyle(
                color: AppConstants.accentColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
