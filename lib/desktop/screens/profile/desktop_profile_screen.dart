import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/widgets/beside_or_below.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/database/database.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/number_utils.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/shell/desktop_shell.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_carousel.dart';
import 'package:mangabaka_app/features/stacks/widgets/my_stacks_entry_card.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_cover_card.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_sign_in_prompt.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/library/services/mappers/db_to_api_mapper.dart';
import 'package:mangabaka_app/features/profile/mixins/profile_data_mixin.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/services/snapshot_service.dart';
import 'package:mangabaka_app/features/profile/services/statistics_service.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/logout_dialog.dart';
import 'package:mangabaka_app/features/publisher/utils/open_publisher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';

part 'desktop_profile_sections_part.dart';
part 'desktop_profile_cards_part.dart';

/// The profile on desktop: an identity card beside a statistics dashboard.
///
/// The phone splits this over two screens â€” a four-number summary with a
/// "full statistics" push â€” because it has no room. Here every statistic, the
/// standout picks and both recent-activity rows fit on one page.
class DesktopProfileScreen extends StatefulWidget {
  static final GlobalKey<DesktopProfileScreenState> stateKey =
      GlobalKey<DesktopProfileScreenState>();

  const DesktopProfileScreen({super.key});

  @override
  State<DesktopProfileScreen> createState() => DesktopProfileScreenState();
}

class DesktopProfileScreenState extends State<DesktopProfileScreen>
    with ProfileDataMixin
    implements DesktopRefreshable {
  static final _logger = LoggingService.logger;

  late final ProfileAuthService _auth;
  late final LibraryService _library;
  late final StatisticsService _stats;
  late final SnapshotService _snapshots;

  bool _wasSyncing = false;

  // The statistics the phone keeps on its separate statistics screen.
  double _completionRate = 0;
  int _totalRereads = 0;
  double _finishRate = 0;
  LibraryEntryWithSeries? _highestRated;
  LibraryEntryWithSeries? _mostReread;
  List<({String name, int count})> _topPublishers = const [];

  @override
  ProfileAuthService get auth => _auth;
  @override
  LibraryService get libraryService => _library;
  @override
  StatisticsService get statisticsService => _stats;
  @override
  SnapshotService get snapshotService => _snapshots;

  @override
  void initState() {
    super.initState();
    _auth = getIt<ProfileAuthService>();
    _library = getIt<LibraryService>();
    _stats = StatisticsService(getIt<AppDatabase>());
    _snapshots = getIt<SnapshotService>();
    _auth.addListener(_onAuthChanged);
    _library.syncStatus.addListener(_onSyncChanged);

    profile = _auth.cachedProfile;
    if (profile != null) {
      loading = false;
      _loadAll();
      _auth
          .fetchProfile(forceRefresh: true)
          .then((p) {
            if (mounted) setState(() => profile = p);
          })
          .catchError((Object e) {
            _logger.warning('Background profile refresh failed: $e');
          });
    } else if (_auth.isLoggedIn) {
      bootstrap().then((_) => _fetchExtendedStats());
    } else {
      loading = false;
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _library.syncStatus.removeListener(_onSyncChanged);
    super.dispose();
  }

  void _loadAll() {
    fetchStatistics();
    _fetchExtendedStats();
    _reloadSnapshots();
  }

  void _reloadSnapshots() {
    pageChanged = 1;
    pageAdded = 1;
    hasMoreChanged = true;
    hasMoreAdded = true;
    fetchRecentlyChanged(initial: true);
    fetchRecentlyAdded(initial: true);
  }

  @override
  Future<void> refresh() async {
    if (!_auth.isLoggedIn) return;
    await bootstrap();
    await _fetchExtendedStats();
  }

  Future<void> _fetchExtendedStats() async {
    final prefs = SettingsManager().contentPreferences;
    final results = await Future.wait<Object?>([
      _stats.getCompletionRate(contentPreferences: prefs),
      _stats.getTotalRereads(contentPreferences: prefs),
      _stats.getFinishRate(contentPreferences: prefs),
      _stats.getHighestRatedSeries(contentPreferences: prefs),
      _stats.getMostRereadSeries(contentPreferences: prefs),
      _stats.getTopPublishers(contentPreferences: prefs),
    ]);
    if (!mounted) return;
    setState(() {
      _completionRate = results[0] as double;
      _totalRereads = results[1] as int;
      _finishRate = results[2] as double;
      _highestRated = results[3] as LibraryEntryWithSeries?;
      _mostReread = results[4] as LibraryEntryWithSeries?;
      _topPublishers = results[5] as List<({String name, int count})>;
    });
  }

  void _onSyncChanged() {
    if (!mounted) return;
    final syncing = _library.syncStatus.value.isSyncing;
    if (_wasSyncing && !syncing && _auth.isLoggedIn) _loadAll();
    _wasSyncing = syncing;
  }

  void _onAuthChanged() {
    if (!mounted) return;
    setState(() {
      profile = _auth.cachedProfile;
      if (!_auth.isLoggedIn) {
        profile = null;
        totalSeries = 0;
        chaptersRead = 0;
        volumesRead = 0;
        meanScore = 0;
        recentlyChanged.clear();
        recentlyAdded.clear();
        _highestRated = null;
        _mostReread = null;
        _topPublishers = const [];
        loading = false;
        error = null;
      } else if (profile == null) {
        bootstrap().then((_) => _fetchExtendedStats());
      }
    });
  }

  Future<void> _logout() async {
    final confirmed = await LogoutDialog.showLogoutConfirmationDialog(context);
    if (confirmed != true) return;
    try {
      await _auth.logout();
    } on AppException {
      // logout() logs the cause and wraps every failure in AuthException.
      if (!mounted) return;
      AppSnackBar.show(
        context,
        LocalizationService().translate('logout_failed'),
        isError: true,
      );
    }
  }

  // â”€â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), SettingsManager()]),
      builder: (context, _) {
        final l10n = LocalizationService();

        if (loading) return const Center(child: MbSpinner());
        if (profile == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DesktopPageHeader(title: l10n.translate('profile')),
              Expanded(
                child: error != null
                    ? DesktopEmptyState(
                        icon: Icons.error_outline_rounded,
                        message: error!,
                        action: DesktopPillButton(
                          label: l10n.translate('retry'),
                          onPressed: login,
                        ),
                      )
                    : DesktopSignInPrompt(
                        title: l10n.translate('profile'),
                        message: l10n.translate('login_prompt_profile'),
                        onLogin: login,
                        icon: Icons.person_outline_rounded,
                      ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesktopPageHeader(title: l10n.translate('profile')),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: DesktopTokens.maxPageWidth,
                  ),
                  // The overview needs a column of its own only if the main
                  // column keeps a useful width beside it.
                  child: DerivedLayoutBuilder<bool>(
                    derive: (constraints) =>
                        constraints.maxWidth >= _sidebarMinWidth,
                    builder: (context, sidebar) {
                      return sidebar
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _mainColumn(l10n, inline: false),
                                ),
                                SizedBox(
                                  width: _sidebarWidth,
                                  child: ListView(
                                    padding: const EdgeInsets.fromLTRB(
                                      0,
                                      0,
                                      DesktopTokens.pagePadding,
                                      48,
                                    ),
                                    children: [
                                      _overview(l10n),
                                      if (_topPublishers.isNotEmpty) ...[
                                        const SizedBox(height: 20),
                                        _publishersCard(l10n),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : _mainColumn(l10n, inline: true);
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  static const double _sidebarWidth = 372;
  static const double _sidebarMinWidth = 1080;
}
