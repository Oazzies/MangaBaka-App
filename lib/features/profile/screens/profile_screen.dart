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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileAuthService _auth = ProfileAuthService();
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
    _statisticsService = StatisticsService(AppDatabase());
    _snapshotService = SnapshotService();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final loggedIn = await _auth.hasSession();
      if (!loggedIn) {
        setState(() => _loading = false);
        return;
      }

      final profile = await _auth.fetchProfile();
      setState(() {
        _profile = profile;
      });

      await _fetchStatistics();
      await Future.wait([
        _fetchRecentlyChanged(initial: true),
        _fetchRecentlyAdded(initial: true),
      ]);

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: $e';
        _loading = false;
      });
    }
  }

  Future<void> _fetchStatistics() async {
    final totalSeries = await _statisticsService.getTotalSeries();
    final chaptersRead = await _statisticsService.getChaptersRead();
    final volumesRead = await _statisticsService.getVolumesRead();
    final completionRate = await _statisticsService.getCompletionRate();
    final totalRereads = await _statisticsService.getTotalRereads();
    setState(() {
      _totalSeries = totalSeries;
      _chaptersRead = chaptersRead;
      _volumesRead = volumesRead;
      _completionRate = completionRate;
      _totalRereads = totalRereads;
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
      setState(() {
        _error = 'Login failed: $e';
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
    setState(() {
      _profile = null;
      _totalSeries = 0;
      _chaptersRead = 0;
      _volumesRead = 0;
      _completionRate = 0;
      _totalRereads = 0;
      _recentlyChanged.clear();
      _recentlyAdded.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final username = _profile?.nickname?.isNotEmpty == true
        ? _profile!.nickname
        : _profile?.preferredUsername;

    return Scaffold(
      backgroundColor: AppConstants.primaryBackground,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _profile == null
          ? _buildLoginPrompt()
          : RefreshIndicator(
              onRefresh: _bootstrap,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${username ?? 'User'} Profile',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'At a Glance',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'A quick overview of your reading statistics.',
                        style: TextStyle(color: AppConstants.textMutedColor),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          StatisticCard(
                            icon: Icons.book,
                            label: 'Total Series',
                            value: '$_totalSeries',
                          ),
                          const SizedBox(width: 16),
                          StatisticCard(
                            icon: Icons.article,
                            label: 'Chapters Read',
                            value: '$_chaptersRead',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          StatisticCard(
                            icon: Icons.library_books,
                            label: 'Volumes Read',
                            value: '$_volumesRead',
                          ),
                          const SizedBox(width: 16),
                          StatisticCard(
                            icon: Icons.check_circle,
                            label: 'Completion',
                            value: '${_completionRate.toStringAsFixed(1)}%',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          StatisticCard(
                            icon: Icons.replay,
                            label: 'Total Rereads',
                            value: '$_totalRereads',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Library Snapshot',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Two quick ways to scan what has been added lately, what is rated highest, and what has seen recent reading progress.',
                        style: TextStyle(color: AppConstants.textMutedColor),
                      ),
                      const SizedBox(height: 16),
                      SnapshotList(
                        title: 'Recently Changed',
                        entries: _recentlyChanged,
                        hasMore: _hasMoreChanged,
                        onFetchMore: _fetchRecentlyChanged,
                      ),
                      const SizedBox(height: 16),
                      SnapshotList(
                        title: 'Recently Added',
                        entries: _recentlyAdded,
                        hasMore: _hasMoreAdded,
                        onFetchMore: _fetchRecentlyAdded,
                      ),
                      SizedBox(height: 32),
                      if (_profile != null)
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _logout,
                            icon: Icon(Icons.logout),
                            label: Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.errorColor,
                              foregroundColor: AppConstants.textColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Text(
            'Login with MangaBaka to see your profile.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _login,
            label: Text('Login with MangaBaka'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.successColor,
              foregroundColor: AppConstants.textColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
