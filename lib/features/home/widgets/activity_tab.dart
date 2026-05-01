import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/features/library/models/library_entry.dart';
import 'package:bakahyou/features/profile/services/snapshot_service.dart';
import 'package:bakahyou/features/profile/services/profile_auth_service.dart';
import 'package:bakahyou/features/series/widgets/entry_list_item.dart';
import 'package:bakahyou/features/series/screens/series_detail_screen.dart';
import 'package:bakahyou/features/profile/widgets/mb_login_prompt.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/utils/exceptions/app_exceptions.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ActivityTab extends StatefulWidget {
  const ActivityTab({super.key});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> with AutomaticKeepAliveClientMixin {
  final _snapshotService = getIt<SnapshotService>();
  final _authService = getIt<ProfileAuthService>();
  List<LibraryEntry> _activities = [];
  bool _isLoading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Load from cache first
    if (_snapshotService.cachedActivities != null) {
      _activities = _snapshotService.cachedActivities!;
    }

    if (_authService.isLoggedIn) {
      _fetchActivity(isInitial: _activities.isEmpty);
    }
    _authService.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    if (_authService.isLoggedIn) {
      _fetchActivity(isInitial: true);
    } else {
      _snapshotService.clearCache();
      setState(() {
        _activities.clear();
        _isLoading = false;
        _error = null;
      });
    }
  }

  Future<void> _fetchActivity({bool isInitial = false}) async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch both recently updated and recently added entries from the USER'S library
      final results = await Future.wait([
        _snapshotService.fetchSnapshot(
          sortBy: 'updated_at_desc',
          limit: 20,
        ),
        _snapshotService.fetchSnapshot(
          sortBy: 'created_at_desc',
          limit: 20,
        ),
      ]);

      final recentlyUpdated = results[0];
      final recentlyAdded = results[1];

      // Merge results and remove duplicates using a Map
      final Map<String, LibraryEntry> mergedMap = {};
      
      for (var entry in recentlyUpdated) {
        mergedMap[entry.series.id] = entry;
      }
      for (var entry in recentlyAdded) {
        if (!mergedMap.containsKey(entry.series.id)) {
          mergedMap[entry.series.id] = entry;
        }
      }

      final mergedList = mergedMap.values.toList();
      
      // Sort by interaction time (updatedAt or createdAt) descending
      mergedList.sort((a, b) {
        final dateA = a.updatedAt ?? a.createdAt ?? '';
        final dateB = b.updatedAt ?? b.createdAt ?? '';
        return dateB.compareTo(dateA);
      });

      // Update cache
      _snapshotService.setCachedActivities(mergedList);

      if (!mounted) return;
      setState(() {
        _activities = mergedList;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        // Only show error if we don't have any data to show (even cached)
        if (_activities.isEmpty) {
          _error = e.toString();
        }
      });
    }
  }

  void _navigateToDetail(Series series) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeriesDetailScreen(series: series),
      ),
    );
  }

  Future<void> _handleLogin() async {
    try {
      await _authService.login();
      // _onAuthChanged will handle the data fetch
    } catch (e) {
      if (e is AuthCancelledException) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), _authService, ThemeManager()]),
      builder: (context, _) {
        final l10n = LocalizationService();

        if (!_authService.isLoggedIn) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: MBLoginPrompt(
              onLogin: _handleLogin,
              message: l10n.translate('login_prompt_library'),
            ),
          );
        }

        // Show spinner only if loading and we have no data yet
        if (_isLoading && _activities.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (_error != null && _activities.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: AppConstants.errorColor, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: AppConstants.errorColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _fetchActivity(isInitial: true),
                    child: Text(l10n.translate('retry')),
                  ),
                ],
              ),
            ),
          );
        }

        if (_activities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.library_books_outlined, color: AppConstants.textMutedColor, size: 48),
                const SizedBox(height: 16),
                Text(
                  l10n.translate('empty_library'),
                  style: TextStyle(color: AppConstants.textMutedColor),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _fetchActivity,
          color: AppConstants.accentColor,
          backgroundColor: AppConstants.secondaryBackground,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            itemCount: _activities.length,
            itemBuilder: (context, index) {
              final entry = _activities[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () => _navigateToDetail(entry.series),
                  borderRadius: BorderRadius.circular(8),
                  child: EntryListItem(series: entry.series),
                ),
              )
                  .animate(delay: Duration(milliseconds: 50 * index))
                  .fadeIn(duration: const Duration(milliseconds: 300))
                  .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
            },
          ),
        );
      },
    );
  }
}
