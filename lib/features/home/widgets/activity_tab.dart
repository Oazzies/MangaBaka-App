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
import 'package:bakahyou/utils/settings/settings_manager.dart';
import 'package:bakahyou/utils/settings/settings_enums.dart';
import 'package:bakahyou/features/series/widgets/series_list_skeleton.dart';
import 'package:bakahyou/utils/transitions/app_transitions.dart';

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
          _error = 'Failed to load activity. Please try again.';
        }
      });
    }
  }

  void _navigateToDetail(Series series) {
    Navigator.push(
      context,
      AppTransitions.slideUp(SeriesDetailScreen(series: series)),
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
        const SnackBar(content: Text('Login failed. Please try again.')),
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

        final settings = SettingsManager();
        final isGrid = settings.currentListStyle.isGrid;

        Widget content;

        if (!_authService.isLoggedIn) {
          content = Padding(
            key: const ValueKey('login'),
            padding: const EdgeInsets.all(24.0),
            child: MBLoginPrompt(
              onLogin: _handleLogin,
              message: l10n.translate('login_prompt_library'),
            ),
          );
        } else if (_isLoading && _activities.isEmpty) {
          content = SeriesListSkeleton(key: const ValueKey('skeleton'), isGrid: isGrid);
        } else if (_error != null && _activities.isEmpty) {
          content = Center(
            key: const ValueKey('error'),
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
        } else if (_activities.isEmpty) {
          content = Center(
            key: const ValueKey('empty'),
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
        } else {
          content = RefreshIndicator(
            key: const ValueKey('list'),
            onRefresh: _fetchActivity,
            color: AppConstants.accentColor,
            backgroundColor: AppConstants.secondaryBackground,
            child: isGrid 
              ? GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 160,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _activities.length,
                  itemBuilder: (context, index) {
                    final entry = _activities[index];
                    return InkWell(
                      onTap: () => _navigateToDetail(entry.series),
                      child: EntryListItem(series: entry.series),
                    );
                  },
                )
              : ListView.builder(
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
                    );
                  },
                ),
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.topCenter,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: content,
        );
      },
    );
  }
}
