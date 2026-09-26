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
import 'package:url_launcher/url_launcher.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The profile on desktop: an identity card beside a statistics dashboard.
///
/// The phone splits this over two screens — a four-number summary with a
/// "full statistics" push — because it has no room. Here every statistic, the
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
    ]);
    if (!mounted) return;
    setState(() {
      _completionRate = results[0] as double;
      _totalRereads = results[1] as int;
      _finishRate = results[2] as double;
      _highestRated = results[3] as LibraryEntryWithSeries?;
      _mostReread = results[4] as LibraryEntryWithSeries?;
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
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, 'Logout failed: $e', isError: true);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), SettingsManager()]),
      builder: (context, _) {
        final l10n = LocalizationService();

        if (loading) return const Center(child: CircularProgressIndicator());
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
                                    children: [_overview(l10n)],
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

  /// Width of the right-hand overview column, and the page width from which it
  /// is shown there rather than inline under the identity card.
  static const double _sidebarWidth = 372;
  static const double _sidebarMinWidth = 1080;

  /// Everything but the overview: identity, standout picks, recent activity.
  /// With [inline] the overview is included too, after the identity card.
  Widget _mainColumn(LocalizationService l10n, {required bool inline}) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        DesktopTokens.pagePadding,
        0,
        // Beside the sidebar the gutter between the two is the sidebar's; on
        // its own the column keeps the page's right gutter.
        inline ? DesktopTokens.pagePadding : DesktopTokens.pagePadding * 0.75,
        48,
      ),
      children: [
        _IdentityCard(
          name: _displayName(l10n),
          username: profile!.preferredUsername,
          role: profile!.role,
          avatarUrl: profile!.avatarUrl,
          onLogout: _logout,
        ),
        if (inline) ...[
          const SizedBox(height: DesktopTokens.sectionGap),
          _overview(l10n, twoColumns: true),
        ],
        if (_highestRated != null || _mostReread != null) ...[
          const SizedBox(height: DesktopTokens.sectionGap),
          DesktopSectionTitle(title: l10n.translate('standout_picks')),
          _standouts(l10n),
        ],
        const SizedBox(height: DesktopTokens.sectionGap),
        _activity(
          l10n.translate('recently_changed'),
          recentlyChanged,
          onNearEnd: fetchRecentlyChanged,
          loading: isLoadingChanged && recentlyChanged.isEmpty,
        ),
        const SizedBox(height: DesktopTokens.sectionGap),
        _activity(
          l10n.translate('recently_added'),
          recentlyAdded,
          onNearEnd: fetchRecentlyAdded,
          loading: isLoadingAdded && recentlyAdded.isEmpty,
        ),
      ],
    );
  }

  String _displayName(LocalizationService l10n) {
    final p = profile!;
    if (p.nickname?.isNotEmpty == true) return p.nickname!;
    if (p.preferredUsername?.isNotEmpty == true) return p.preferredUsername!;
    return l10n.translate('your_profile');
  }

  /// The reading overview as one card of labelled figures.
  ///
  /// A column of rows rather than the phone's tile grid: in the sidebar it is
  /// narrow and tall, so each statistic reads as "label … value" down the card.
  /// With [twoColumns] — inline, across the page — the rows are split over two
  /// columns instead, so the card is not a tall strip of empty space.
  Widget _overview(LocalizationService l10n, {bool twoColumns = false}) {
    final rows = [
      (
        Icons.book_rounded,
        l10n.translate('total_series'),
        NumberUtils.formatCount(totalSeries),
      ),
      (
        Icons.article_rounded,
        l10n.translate('chapters_read'),
        NumberUtils.formatCount(chaptersRead),
      ),
      (
        Icons.library_books_rounded,
        l10n.translate('volumes_read'),
        NumberUtils.formatCount(volumesRead),
      ),
      (
        Icons.star_rounded,
        l10n.translate('mean_score'),
        meanScore.toStringAsFixed(1),
      ),
      (
        Icons.check_circle_rounded,
        l10n.translate('completion'),
        '${_completionRate.toStringAsFixed(1)}%',
      ),
      (
        Icons.flag_rounded,
        l10n.translate('finish_rate'),
        '${_finishRate.toStringAsFixed(1)}%',
      ),
      (
        Icons.replay_rounded,
        l10n.translate('total_rereads'),
        NumberUtils.formatCount(_totalRereads),
      ),
    ];

    Widget column(List<(IconData, String, String)> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) Divider(height: 1, color: context.colors.border),
          _OverviewRow(
            icon: items[i].$1,
            label: items[i].$2,
            value: items[i].$3,
          ),
        ],
      ],
    );

    // The larger half first, so an odd count leaves the short column on the
    // right.
    final split = (rows.length + 1) ~/ 2;

    return DesktopCard(
      showBorder: false,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopSectionTitle(
            title: l10n.translate('reading_stats'),
            padding: const EdgeInsets.only(bottom: 6),
          ),
          if (twoColumns)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: column(rows.sublist(0, split))),
                const SizedBox(width: 40),
                Expanded(child: column(rows.sublist(split))),
              ],
            )
          else
            column(rows),
        ],
      ),
    );
  }

  Widget _standouts(LocalizationService l10n) {
    final cards = <Widget>[
      if (_highestRated != null)
        _StandoutCard(
          entry: _highestRated!,
          label: l10n.translate('highest_rated'),
          icon: Icons.star_rounded,
          value:
              '${l10n.translate('score')}: ${_highestRated!.libraryEntry.rating ?? 0}',
        ),
      if (_mostReread != null)
        _StandoutCard(
          entry: _mostReread!,
          label: l10n.translate('most_reread'),
          icon: Icons.replay_rounded,
          value:
              '${_mostReread!.libraryEntry.numberOfRereads} ${l10n.translate('rereads')}',
        ),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: cards[i]),
        ],
        if (cards.length == 1) const Spacer(),
      ],
    );
  }

  Widget _activity(
    String title,
    List<LibraryEntry> entries, {
    required VoidCallback onNearEnd,
    required bool loading,
  }) {
    if (!loading && entries.isEmpty) return const SizedBox.shrink();
    final textArea = DesktopCoverCard.textAreaHeight(context);
    return DesktopCarousel(
      title: title,
      loading: loading,
      itemCount: entries.length,
      // Stretched so a whole number of covers exactly fills the row, lining
      // up with the identity card above.
      itemWidth: 130,
      stretch: true,
      itemHeight: (width) => width * 1.5 + textArea,
      onNearEnd: onNearEnd,
      itemBuilder: (context, i) => DesktopCoverCard(
        series: entries[i].series,
        heroTag: 'profile_${title}_$i',
        caption: LocalizationService().translate(entries[i].state),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final String name;
  final String? username;
  final String role;
  final String? avatarUrl;
  final VoidCallback onLogout;

  const _IdentityCard({
    required this.name,
    required this.username,
    required this.role,
    this.avatarUrl,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return DesktopCard(
      showBorder: false,
      padding: const EdgeInsets.all(28),
      // The account buttons beside the name while it keeps its room,
      // beneath it in a narrow window or at a large text size.
      child: BesideOrBelow(
        gap: 24,
        minBodyWidth: 220,
        leading: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: context.colors.accent,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? WidgetUtils.networkImage(
                    url: avatarUrl!,
                    fit: BoxFit.cover,
                    width: 88,
                    height: 88,
                    errorWidget: Center(
                      child: Text(
                        name.isEmpty ? '?' : name[0].toUpperCase(),
                        style: AppTypography.display(
                          color: context.colors.onAccent,
                          fontSize: 40,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: AppTypography.display(
                        color: context.colors.onAccent,
                        fontSize: 40,
                      ),
                    ),
                  ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.display(
                color: context.colors.text,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (username != null && username != name) ...[
                  // Usernames have no length limit; the role pill keeps
                  // its place and the name gives way.
                  Flexible(
                    child: Text(
                      '@$username',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (role.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceRaised,
                      borderRadius: BorderRadius.circular(
                        AppConstants.pillRadius,
                      ),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: AppTypography.monoLabel(
                        color: context.colors.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DesktopPillButton(
              label: l10n.translate('account_settings'),
              icon: Icons.open_in_new_rounded,
              onPressed: () => launchUrl(
                Uri.parse('https://mangabaka.org/my/settings/profile'),
                mode: LaunchMode.externalApplication,
              ),
            ),
            DesktopIconButton(
              icon: Icons.logout_rounded,
              filled: true,
              color: context.colors.error,
              tooltip: l10n.translate('logout'),
              onPressed: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _OverviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.colors.textMuted),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.monoLabel(
                color: context.colors.textMuted,
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            maxLines: 1,
            style: AppTypography.display(
              color: context.colors.text,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _StandoutCard extends StatelessWidget {
  final LibraryEntryWithSeries entry;
  final String label;
  final IconData icon;
  final String value;

  const _StandoutCard({
    required this.entry,
    required this.label,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final series = DbToApiMapper.seriesFromDb(entry.series);
    return DesktopHoverSurface(
      onTap: () => openSeriesDetail(context, series, heroTag: 'standout'),
      idleColor: context.colors.surface,
      hoverColor: context.colors.surfaceRaised,
      borderRadius: BorderRadius.circular(DesktopTokens.panelRadius),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: WidgetUtils.networkImage(
              url: series.coverUrl,
              blurred: WidgetUtils.isRatingBlurred(series.contentRating),
              width: 72,
              height: 108,
              memCacheWidth: 160,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: context.colors.star),
                    const SizedBox(width: 6),
                    Text(
                      label.toUpperCase(),
                      style: AppTypography.monoLabel(
                        color: context.colors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  series.getDisplayTitle(
                    SettingsManager().defaultTitleLanguage,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(
                    color: context.colors.text,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: AppTypography.sans(
                    color: context.colors.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
