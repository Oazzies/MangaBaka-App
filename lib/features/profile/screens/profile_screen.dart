import 'package:mangabaka_app/database/database.dart';
import 'package:mangabaka_app/features/profile/services/snapshot_service.dart';
import 'package:mangabaka_app/features/profile/services/statistics_service.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/features/profile/screens/settings_screen.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/theme/theme_manager.dart';
import 'package:mangabaka_app/features/profile/widgets/mb_login_prompt.dart';
import 'package:mangabaka_app/features/profile/widgets/profile_statistics_section.dart';
import 'package:mangabaka_app/features/profile/widgets/profile_snapshot_section.dart';
import 'package:mangabaka_app/features/profile/mixins/profile_data_mixin.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with ProfileDataMixin {
  late final ProfileAuthService _auth;
  late final LibraryService _libraryService;
  late final StatisticsService _statisticsService;
  late final SnapshotService _snapshotService;

  bool _wasSyncing = false;

  @override
  ProfileAuthService get auth => _auth;

  @override
  LibraryService get libraryService => _libraryService;

  @override
  StatisticsService get statisticsService => _statisticsService;

  @override
  SnapshotService get snapshotService => _snapshotService;



  @override
  void initState() {
    super.initState();
    _auth = getIt<ProfileAuthService>();
    _auth.addListener(_onAuthStateChanged);
    _libraryService = getIt<LibraryService>();
    _libraryService.syncStatus.addListener(_onSyncStatusChanged);
    _statisticsService = StatisticsService(getIt<AppDatabase>());
    _snapshotService = SnapshotService();

    // Instantly show cached profile — no loading spinner
    profile = _auth.cachedProfile;
    if (profile != null) {
      loading = false;
      // Fire all data fetches in parallel
      fetchStatistics();
      fetchRecentlyChanged(initial: true);
      fetchRecentlyAdded(initial: true);
      // Silently refresh profile in background
      _auth.fetchProfile(forceRefresh: true).then((p) {
        if (mounted) setState(() => profile = p);
      }).catchError((_) {});
    } else if (_auth.isLoggedIn) {
      // Logged in but no cached profile yet — full load
      bootstrap();
    } else {
      // Not logged in — show login prompt instantly
      loading = false;
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthStateChanged);
    _libraryService.syncStatus.removeListener(_onSyncStatusChanged);
    super.dispose();
  }

  void _onSyncStatusChanged() {
    if (!mounted) return;
    final isSyncing = _libraryService.syncStatus.value.isSyncing;
    
    // Only trigger refresh when sync transitions from true -> false
    if (_wasSyncing && !isSyncing && _auth.isLoggedIn) {
      fetchStatistics();
      fetchRecentlyChanged(initial: true);
      fetchRecentlyAdded(initial: true);
    }
    
    _wasSyncing = isSyncing;
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    setState(() {
      profile = _auth.cachedProfile;
      if (!_auth.isLoggedIn) {
        // Clear all state on logout
        totalSeries = 0;
        chaptersRead = 0;
        volumesRead = 0;
        meanScore = 0.0;
        recentlyChanged.clear();
        recentlyAdded.clear();
        error = null;
        loading = false;
        profile = null;
      } else if (profile == null && _auth.isLoggedIn) {
        // Logged in but profile not fetched yet — full load
        bootstrap();
      }
    });
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
        final username = profile?.nickname?.isNotEmpty == true
            ? profile!.nickname
            : profile?.preferredUsername;

        return Scaffold(
          backgroundColor: AppConstants.primaryBackground,
          appBar: AppBar(
            backgroundColor: AppConstants.primaryBackground,
            elevation: 0,
            centerTitle: true,
            title: Text(
              () {
                if (profile == null) return l10n.translate('profile');
                if (username == null) return l10n.translate('yourprofile');
                
                final suffix = l10n.translate('profile_title_suffix');
                switch (l10n.currentLanguage) {
                  case 'es':
                  case 'fr':
                    return '$suffix de $username';
                  case 'ja':
                    return '$usernameの$suffix';
                  default:
                    return '${_getPossessiveName(username)} $suffix';
                }
              }(),
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
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(child: Text(error!))
              : profile == null
              ? _buildLoginPrompt()
              : RefreshIndicator(
                  onRefresh: bootstrap,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                            ProfileStatisticsSection(
                              totalSeries: totalSeries,
                              chaptersRead: chaptersRead,
                              volumesRead: volumesRead,
                              meanScore: meanScore,
                            ),
                            const SizedBox(height: 24),
                            ProfileSnapshotSection(
                              recentlyChanged: recentlyChanged,
                              hasMoreChanged: hasMoreChanged,
                              onFetchMoreChanged: () => fetchRecentlyChanged(),
                              recentlyAdded: recentlyAdded,
                              hasMoreAdded: hasMoreAdded,
                              onFetchMoreAdded: () => fetchRecentlyAdded(),
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
      onLogin: login,
      message: l10n.translate('login_prompt_profile'),
    );
  }
}
