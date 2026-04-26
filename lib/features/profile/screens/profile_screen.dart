import 'package:bakahyou/database/database.dart';
import 'package:bakahyou/features/library/models/library_entry.dart';
import 'package:bakahyou/features/profile/services/snapshot_service.dart';
import 'package:bakahyou/features/profile/services/statistics_service.dart';
import 'package:bakahyou/features/profile/widgets/snapshot_list.dart';
import 'package:bakahyou/features/profile/widgets/statistic_card.dart';
import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/profile/models/mb_profile.dart';
import 'package:bakahyou/features/profile/screens/settings_screen.dart';
import 'package:bakahyou/features/profile/services/profile_auth_service.dart';
import 'package:bakahyou/features/library/services/library_service.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';
import 'package:bakahyou/utils/exceptions/app_exceptions.dart';
import 'package:bakahyou/features/profile/widgets/mb_login_prompt.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileAuthService _auth;
  late final StatisticsService _statisticsService;
  late final SnapshotService _snapshotService;

  bool _loading = true;
  String? _error;
  MbProfile? _profile;

  int _totalSeries = 0;
  int _chaptersRead = 0;
  int _volumesRead = 0;
  double _completionRate = 0.0;
  int _totalRereads = 0;

  final List<LibraryEntry> _recentlyChanged = [];
  final List<LibraryEntry> _recentlyAdded = [];

  bool _isLoadingChanged = false;
  bool _isLoadingAdded = false;
  bool _hasMoreChanged = true;
  bool _hasMoreAdded = true;
  int _pageChanged = 1;
  int _pageAdded = 1;

  @override
  void initState() {
    super.initState();
    _auth = getIt<ProfileAuthService>();
    _auth.addListener(_onAuthStateChanged);
    _statisticsService = StatisticsService(getIt<AppDatabase>());
    _snapshotService = SnapshotService();

    // Instantly show cached profile — no loading spinner
    _profile = _auth.cachedProfile;
    if (_profile != null) {
      _loading = false;
      // Fire all data fetches in parallel
      _fetchStatistics();
      _fetchRecentlyChanged(initial: true);
      _fetchRecentlyAdded(initial: true);
      // Silently refresh profile in background
      _auth.fetchProfile(forceRefresh: true).then((p) {
        if (mounted) setState(() => _profile = p);
      }).catchError((_) {});
    } else if (_auth.isLoggedIn) {
      // Logged in but no cached profile yet — full load
      _bootstrap();
    } else {
      // Not logged in — show login prompt instantly
      _loading = false;
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    setState(() {
      _profile = _auth.cachedProfile;
      if (!_auth.isLoggedIn) {
        // Clear all state on logout
        _totalSeries = 0;
        _chaptersRead = 0;
        _volumesRead = 0;
        _completionRate = 0.0;
        _totalRereads = 0;
        _recentlyChanged.clear();
        _recentlyAdded.clear();
        _error = null;
        _loading = false;
        _profile = null;
      } else if (_profile == null && _auth.isLoggedIn) {
        // Logged in but profile not fetched yet — full load
        _bootstrap();
      }
    });
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await _auth.fetchProfile(forceRefresh: true);
      if (!mounted) return;
      setState(() => _profile = profile);

      // Ensure library is synced before fetching statistics
      await getIt<LibraryService>().performInitialSyncIfNeeded();

      // Fetch all data in parallel
      await Future.wait([
        _fetchStatistics(),
        _fetchRecentlyChanged(initial: true),
        _fetchRecentlyAdded(initial: true),
      ]);

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchStatistics() async {
    // Run all DB queries in parallel instead of sequentially
    final results = await Future.wait([
      _statisticsService.getTotalSeries(),
      _statisticsService.getChaptersRead(),
      _statisticsService.getVolumesRead(),
      _statisticsService.getCompletionRate(),
      _statisticsService.getTotalRereads(),
    ]);
    if (!mounted) return;
    setState(() {
      _totalSeries = results[0] as int;
      _chaptersRead = results[1] as int;
      _volumesRead = results[2] as int;
      _completionRate = results[3] as double;
      _totalRereads = results[4] as int;
    });
  }

  Future<void> _fetchRecentlyChanged({bool initial = false}) async {
    if (_isLoadingChanged || !_hasMoreChanged) return;
    setState(() => _isLoadingChanged = true);

    try {
      final entries = await _snapshotService.fetchSnapshot(
        sortBy: 'updated_at_desc',
        page: _pageChanged,
      );
      setState(() {
        if (initial) _recentlyChanged.clear();
        _recentlyChanged.addAll(entries);
        _pageChanged++;
        _hasMoreChanged = entries.isNotEmpty;
        _isLoadingChanged = false;
      });
    } catch (e) {
      setState(() => _isLoadingChanged = false);
    }
  }

  Future<void> _fetchRecentlyAdded({bool initial = false}) async {
    if (_isLoadingAdded || !_hasMoreAdded) return;
    setState(() => _isLoadingAdded = true);

    try {
      final entries = await _snapshotService.fetchSnapshot(
        sortBy: 'created_at_desc',
        page: _pageAdded,
      );
      setState(() {
        if (initial) _recentlyAdded.clear();
        _recentlyAdded.addAll(entries);
        _pageAdded++;
        _hasMoreAdded = entries.isNotEmpty;
        _isLoadingAdded = false;
      });
    } catch (e) {
      setState(() => _isLoadingAdded = false);
    }
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.login();
      await _bootstrap();
    } catch (e) {
      if (e is AuthCancelledException) {
        setState(() => _loading = false);
        return;
      }
      setState(() {
        _error = 'Login failed: $e';
        _loading = false;
      });
    }
  }

  String _getPossessiveName(String name) {
    final lang = LocalizationService().currentLanguage;
    if (lang == 'es') {
      return name;
    }
    return "$name's";
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), ThemeManager()]),
      builder: (context, _) {
        final l10n = LocalizationService();
        final username = _profile?.nickname?.isNotEmpty == true
            ? _profile!.nickname
            : _profile?.preferredUsername;

        return Scaffold(
          backgroundColor: AppConstants.primaryBackground,
          appBar: AppBar(
            backgroundColor: AppConstants.primaryBackground,
            elevation: 0,
            title: Text(
              _profile == null
                  ? l10n.translate('profile')
                  : l10n.currentLanguage == 'es'
                      ? '${l10n.translate('profile_title_suffix')} de $username'
                      : '${_getPossessiveName(username ?? 'User')} ${l10n.translate('profile_title_suffix')}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : _profile == null
              ? _buildLoginPrompt()
              : RefreshIndicator(
                  onRefresh: _bootstrap,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            l10n.translate('at_a_glance'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
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
                                  value: '$_totalSeries',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: StatisticCard(
                                  icon: Icons.article,
                                  label: l10n.translate('chapters_read'),
                                  value: '$_chaptersRead',
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
                                  value: '$_volumesRead',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: StatisticCard(
                                  icon: Icons.check_circle,
                                  label: l10n.translate('completion'),
                                  value: '${_completionRate.toStringAsFixed(1)}%',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: StatisticCard(
                                  icon: Icons.replay,
                                  label: l10n.translate('total_rereads'),
                                  value: '$_totalRereads',
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.translate('library_snapshot'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.translate('snapshot_desc'),
                            style: TextStyle(color: AppConstants.textMutedColor),
                          ),
                          const SizedBox(height: 16),
                          SnapshotList(
                            title: l10n.translate('recently_changed'),
                            entries: _recentlyChanged,
                            hasMore: _hasMoreChanged,
                            onFetchMore: _fetchRecentlyChanged,
                          ),
                          const SizedBox(height: 16),
                          SnapshotList(
                            title: l10n.translate('recently_added'),
                            entries: _recentlyAdded,
                            hasMore: _hasMoreAdded,
                            onFetchMore: _fetchRecentlyAdded,
                          ),
                        ],
                      ),
                    ),
          ),
        );
      },
    );
  }

  Widget _buildLoginPrompt() {
    final l10n = LocalizationService();
    return MBLoginPrompt(
      onLogin: _login,
      message: l10n.translate('login_prompt_profile'),
    );
  }
}
