import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/screens/home/desktop_trending_board.dart';
import 'package:mangabaka_app/desktop/screens/home/desktop_upcoming_rail.dart';
import 'package:mangabaka_app/desktop/shell/desktop_shell.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_carousel.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_cover_card.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/browse/screens/browse_results_screen.dart';
import 'package:mangabaka_app/features/home/services/home_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Home on desktop: Trending as a ranked board — a featured #1 beside the
/// rest of the top ten — then the discovery rails as paged carousels.
///
/// Loads through the same [HomeService] as the phone feed.
class DesktopHomeScreen extends StatefulWidget {
  static final GlobalKey<DesktopHomeScreenState> stateKey =
      GlobalKey<DesktopHomeScreenState>();

  const DesktopHomeScreen({super.key});

  @override
  State<DesktopHomeScreen> createState() => DesktopHomeScreenState();
}

class DesktopHomeScreenState extends State<DesktopHomeScreen>
    implements DesktopRefreshable {
  late final HomeService _home;
  late final ProfileAuthService _auth;

  List<Series> _forYou = const [];
  List<Series> _trending = const [];
  List<Series> _rising = const [];
  List<Series> _hiddenGems = const [];
  List<Series> _newReleases = const [];
  List<TopGenreRail> _genreRails = const [];

  String? _trendingType;
  int _trendingWindow = 7;

  bool _loadingRails = true;
  bool _loadingTrending = true;
  bool _showForYou = false;

  @override
  void initState() {
    super.initState();
    _home = HomeService();
    _auth = getIt<ProfileAuthService>();
    _auth.addListener(_onAuthChanged);
    refresh();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) refresh();
  }

  @override
  Future<void> refresh() async {
    setState(() {
      _loadingRails = true;
      _loadingTrending = true;
    });

    final readiness = await _home.fetchForYouReadiness();
    final wantsForYou = readiness?.isReady ?? false;

    final results = await Future.wait([
      wantsForYou ? _home.fetchForYou() : Future.value(<Series>[]),
      _home.fetchTrending(type: _trendingType, windowDays: _trendingWindow),
      _home.fetchRising(),
      _home.fetchHiddenGems(),
      _home.fetchNewReleases(),
      _home.fetchTopGenreRails(),
    ]);

    if (!mounted) return;
    setState(() {
      _forYou = results[0] as List<Series>;
      _trending = results[1] as List<Series>;
      _rising = results[2] as List<Series>;
      _hiddenGems = results[3] as List<Series>;
      _newReleases = results[4] as List<Series>;
      _genreRails = results[5] as List<TopGenreRail>;
      _showForYou = wantsForYou;
      _loadingRails = false;
      _loadingTrending = false;
    });
  }

  Future<void> _reloadTrending() async {
    setState(() => _loadingTrending = true);
    final list = await _home.fetchTrending(
      type: _trendingType,
      windowDays: _trendingWindow,
    );
    if (!mounted) return;
    setState(() {
      _trending = list;
      _loadingTrending = false;
    });
  }

  void _openTrendingAll() {
    Navigator.of(context).push(
      AppTransitions.slideRight(
        BrowseResultsScreen(
          sortType: LocalizationService().translate('trending'),
          sortBy: _trendingWindow == 30 ? 'trending_30d' : 'trending_7d',
          type: _trendingType,
        ),
      ),
    );
  }

  void _openGenreAll(TopGenre genre) {
    Navigator.of(context).push(
      AppTransitions.slideRight(
        BrowseResultsScreen(
          sortType: LocalizationService()
              .translate('top_in_genre')
              .replaceAll('{genre}', genre.name),
          sortBy: 'score_desc',
          tag: genre.tagId.toString(),
        ),
      ),
    );
  }

  static const double _railMinWidth = 1100;
  static const double _railWidth = 320;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), SettingsManager()]),
      builder: (context, _) {
        final l10n = LocalizationService();

        return LayoutBuilder(
          builder: (context, constraints) {
            final showRail = constraints.maxWidth >= _railMinWidth;
            final feed = ListView(
              padding: const EdgeInsets.only(bottom: 48),
              children: [
                DesktopPageHeader(
                  title: l10n.translate('home'),
                  subtitle: l10n.translate('home_subtitle'),
                  actions: [
                    DesktopIconButton(
                      icon: Icons.refresh_rounded,
                      filled: true,
                      tooltip: '${l10n.translate('retry')}  (Ctrl+R)',
                      onPressed: refresh,
                    ),
                  ],
                ),
                _padded(
                  DesktopTrendingBoard(
                    series: _trending,
                    loading: _loadingTrending,
                    selectedType: _trendingType,
                    window: _trendingWindow,
                    onTypeChanged: (type) {
                      if (type == _trendingType) return;
                      setState(() => _trendingType = type);
                      _reloadTrending();
                    },
                    onWindowChanged: (days) {
                      if (days == _trendingWindow) return;
                      setState(() => _trendingWindow = days);
                      _reloadTrending();
                    },
                    onViewAll: _openTrendingAll,
                  ),
                ),
                if (_showForYou || _loadingRails)
                  _rail(
                    l10n.translate('for_you'),
                    _forYou,
                    loading: _loadingRails && _showForYou,
                  ),
                for (final rail in _genreRails)
                  _rail(
                    l10n
                        .translate('top_in_genre')
                        .replaceAll('{genre}', rail.genre.name),
                    rail.series,
                    onViewAll: () => _openGenreAll(rail.genre),
                  ),
                _rail(l10n.translate('rising'), _rising),
                _rail(l10n.translate('hidden_gems'), _hiddenGems),
                _rail(l10n.translate('new_releases'), _newReleases),
              ],
            );

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: feed),
                if (showRail)
                  Container(
                    width: _railWidth,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: context.colors.border),
                      ),
                    ),
                    child: const DesktopUpcomingRail(),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _padded(Widget child) => Padding(
    padding: const EdgeInsets.fromLTRB(
      DesktopTokens.pagePadding,
      0,
      DesktopTokens.pagePadding,
      DesktopTokens.sectionGap,
    ),
    child: child,
  );

  Widget _rail(
    String title,
    List<Series> series, {
    bool? loading,
    VoidCallback? onViewAll,
  }) {
    final isLoading = loading ?? _loadingRails;
    // A rail that resolved to nothing is dropped rather than shown empty.
    if (!isLoading && series.isEmpty) return const SizedBox.shrink();

    const width = 156.0;
    return _padded(
      DesktopCarousel(
        title: title,
        loading: isLoading,
        onViewAll: onViewAll,
        itemCount: series.length,
        itemWidth: width,
        height: width * 1.5 + DesktopCoverCard.textAreaHeight(context),
        itemBuilder: (context, i) => DesktopCoverCard(
          series: series[i],
          width: width,
          heroTag: 'home_${title}_$i',
        ),
      ),
    );
  }
}
