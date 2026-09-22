import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/features/browse/screens/browse_results_screen.dart';
import 'package:mangabaka_app/features/home/services/home_service.dart';
import 'package:mangabaka_app/features/home/widgets/home_rail.dart';
import 'package:mangabaka_app/features/home/widgets/home_trending_section.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/features/profile/screens/settings_screen.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The Home feed: a rotating spotlight of what's hot, then progressively broader
/// discovery — personalised, then trending, then the long tail. Mirrors the
/// sections of the web `/discover` page.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final _logger = LoggingService.logger;

  late final HomeService _homeService;
  late final ProfileAuthService _auth;

  List<Series> _forYou = const [];
  List<Series> _trending = const [];
  List<Series> _rising = const [];
  List<Series> _hiddenGems = const [];
  List<Series> _newReleases = const [];
  List<TopGenreRail> _genreRails = const [];

  /// API `type` filter for the Trending rail; null means every type.
  String? _trendingType;

  /// Trending window in days — 7 or 30.
  int _trendingWindow = 7;

  bool _loadingRails = true;
  bool _loadingTrending = true;
  bool _showForYou = false;

  @override
  void initState() {
    super.initState();
    _homeService = HomeService();
    _auth = getIt<ProfileAuthService>();
    _auth.addListener(_onAuthChanged);
    _loadRails();
    _logger.info('HomeScreen initialized');
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    _loadRails();
  }

  Future<void> _loadRails() async {
    if (mounted) {
      setState(() {
        _loadingRails = true;
        _loadingTrending = true;
      });
    }

    // The public rails always load; "For You" is gated on the readiness probe
    // so a cold profile shows nothing rather than an empty rail.
    final readiness = await _homeService.fetchForYouReadiness();
    final wantsForYou = readiness?.isReady ?? false;

    final results = await Future.wait([
      wantsForYou ? _homeService.fetchForYou() : Future.value(<Series>[]),
      _homeService.fetchTrending(
        type: _trendingType,
        windowDays: _trendingWindow,
      ),
      _homeService.fetchRising(),
      _homeService.fetchHiddenGems(),
      _homeService.fetchNewReleases(),
      _homeService.fetchTopGenreRails(),
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

  /// Re-fetch only the Trending rail after a type / window change. The old
  /// results stay on screen (behind a skeleton) so the spotlight doesn't blink.
  Future<void> _reloadTrending() async {
    setState(() => _loadingTrending = true);
    final list = await _homeService.fetchTrending(
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
    final l10n = LocalizationService();
    Navigator.of(context).push(
      AppTransitions.slideRight(
        BrowseResultsScreen(
          sortType: l10n.translate('trending'),
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), SettingsManager()]),
      builder: (context, _) {
        final l10n = LocalizationService();

        return Scaffold(
          backgroundColor: context.colors.background,
          appBar: mbScreenAppBar(
            title: l10n.translate('home'),
            isRoot: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => SettingsScreen.show(context),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: RefreshIndicator(
            color: context.colors.accent,
            backgroundColor: context.colors.surface,
            onRefresh: _loadRails,
            child: WidgetUtils.responsiveConstraint(
              ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                children: [
                  if (_showForYou || _loadingRails)
                    HomeRail(
                      title: l10n.translate('for_you'),
                      series: _forYou,
                      loading: _loadingRails && _showForYou,
                    ),
                  for (final rail in _genreRails)
                    HomeRail(
                      title: l10n
                          .translate('top_in_genre')
                          .replaceAll('{genre}', rail.genre.name),
                      series: rail.series,
                      onViewAll: () => _openGenreAll(rail.genre),
                    ),
                  HomeTrendingSection(
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
                  HomeRail(
                    title: l10n.translate('rising'),
                    series: _rising,
                    loading: _loadingRails,
                  ),
                  HomeRail(
                    title: l10n.translate('hidden_gems'),
                    series: _hiddenGems,
                    loading: _loadingRails,
                  ),
                  HomeRail(
                    title: l10n.translate('new_releases'),
                    series: _newReleases,
                    loading: _loadingRails,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
