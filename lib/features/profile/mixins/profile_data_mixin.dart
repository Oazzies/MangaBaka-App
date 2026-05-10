import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/profile/services/snapshot_service.dart';
import 'package:mangabaka_app/features/profile/services/statistics_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/models/mb_profile.dart';
import 'package:mangabaka_app/utils/exceptions/app_exceptions.dart';


mixin ProfileDataMixin<T extends StatefulWidget> on State<T> {
  ProfileAuthService get auth;
  LibraryService get libraryService;
  StatisticsService get statisticsService;
  SnapshotService get snapshotService;

  bool loading = true;
  String? error;
  MbProfile? profile;

  int totalSeries = 0;
  int chaptersRead = 0;
  int volumesRead = 0;
  double meanScore = 0.0;

  final List<LibraryEntry> recentlyChanged = [];
  final List<LibraryEntry> recentlyAdded = [];

  bool isLoadingChanged = false;
  bool isLoadingAdded = false;
  bool hasMoreChanged = true;
  bool hasMoreAdded = true;
  int pageChanged = 1;
  int pageAdded = 1;

  Future<void> fetchStatistics() async {
    final results = await Future.wait([
      statisticsService.getTotalSeries(),
      statisticsService.getChaptersRead(),
      statisticsService.getVolumesRead(),
      statisticsService.getCompletionRate(),
      statisticsService.getTotalRereads(),
      statisticsService.getMeanScore(),
    ]);
    if (!mounted) return;
    setState(() {
      totalSeries = results[0] as int;
      chaptersRead = results[1] as int;
      volumesRead = results[2] as int;
      meanScore = results[5] as double;
    });
  }

  Future<void> fetchRecentlyChanged({bool initial = false}) async {
    if (isLoadingChanged || !hasMoreChanged) return;
    setState(() => isLoadingChanged = true);

    try {
      final entries = await snapshotService.fetchSnapshot(
        sortBy: 'updated_at_desc',
        page: pageChanged,
      );
      if (!mounted) return;
      setState(() {
        if (initial) recentlyChanged.clear();
        recentlyChanged.addAll(entries);
        pageChanged++;
        hasMoreChanged = entries.isNotEmpty;
        isLoadingChanged = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingChanged = false);
    }
  }

  Future<void> fetchRecentlyAdded({bool initial = false}) async {
    if (isLoadingAdded || !hasMoreAdded) return;
    setState(() => isLoadingAdded = true);

    try {
      final entries = await snapshotService.fetchSnapshot(
        sortBy: 'created_at_desc',
        page: pageAdded,
      );
      if (!mounted) return;
      setState(() {
        if (initial) recentlyAdded.clear();
        recentlyAdded.addAll(entries);
        pageAdded++;
        hasMoreAdded = entries.isNotEmpty;
        isLoadingAdded = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingAdded = false);
    }
  }

  Future<void> bootstrap() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final fetchedProfile = await auth.fetchProfile(forceRefresh: true);
      if (!mounted) return;
      setState(() => profile = fetchedProfile);

      await libraryService.performInitialSyncIfNeeded();

      await Future.wait([
        fetchStatistics(),
        fetchRecentlyChanged(initial: true),
        fetchRecentlyAdded(initial: true),
      ]);

      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Failed to load profile: $e';
          loading = false;
        });
      }
    }
  }

  Future<void> login() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      await auth.login();
      await bootstrap();
    } catch (e) {
      if (e is AuthCancelledException) {
        setState(() => loading = false);
        return;
      }
      setState(() {
        error = 'Login failed: $e';
        loading = false;
      });
    }
  }
}
