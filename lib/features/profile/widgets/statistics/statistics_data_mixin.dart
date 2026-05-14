import 'package:flutter/material.dart';
import 'package:mangabaka_app/database/database.dart';
import 'package:mangabaka_app/features/profile/services/statistics_service.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';

mixin StatisticsDataMixin<T extends StatefulWidget> on State<T> {
  late final StatisticsService statisticsService;
  bool loading = true;

  int totalSeries = 0;
  int chaptersRead = 0;
  int volumesRead = 0;
  double completionRate = 0.0;
  int totalRereads = 0;
  double meanScore = 0.0;
  double finishRate = 0.0;
  LibraryEntryWithSeries? highestRated;
  LibraryEntryWithSeries? mostReread;

  void initStatistics() {
    statisticsService = StatisticsService(getIt<AppDatabase>());
    fetchStatistics();
  }

  Future<void> fetchStatistics() async {
    final contentPrefs = SettingsManager().contentPreferences;
    final results = await Future.wait([
      statisticsService.getTotalSeries(contentPreferences: contentPrefs),
      statisticsService.getChaptersRead(contentPreferences: contentPrefs),
      statisticsService.getVolumesRead(contentPreferences: contentPrefs),
      statisticsService.getCompletionRate(contentPreferences: contentPrefs),
      statisticsService.getTotalRereads(contentPreferences: contentPrefs),
      statisticsService.getMeanScore(contentPreferences: contentPrefs),
      statisticsService.getFinishRate(contentPreferences: contentPrefs),
      statisticsService.getHighestRatedSeries(contentPreferences: contentPrefs),
      statisticsService.getMostRereadSeries(contentPreferences: contentPrefs),
    ]);

    if (!mounted) return;

    setState(() {
      totalSeries = results[0] as int;
      chaptersRead = results[1] as int;
      volumesRead = results[2] as int;
      completionRate = results[3] as double;
      totalRereads = results[4] as int;
      meanScore = results[5] as double;
      finishRate = results[6] as double;
      highestRated = results[7] as LibraryEntryWithSeries?;
      mostReread = results[8] as LibraryEntryWithSeries?;
      loading = false;
    });
  }
}
