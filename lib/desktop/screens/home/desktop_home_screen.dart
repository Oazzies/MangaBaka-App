import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/screens/home/desktop_home_widgets.dart';
import 'package:mangabaka_app/desktop/screens/home/desktop_trending_board.dart';
import 'package:mangabaka_app/desktop/screens/home/desktop_upcoming_rail.dart';
import 'package:mangabaka_app/desktop/shell/desktop_shell.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/browse/screens/browse_results_screen.dart';
import 'package:mangabaka_app/features/home/services/home_service.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/stacks/widgets/home_stacks_rail.dart';
import 'package:mangabaka_app/features/home/widgets/home_publishers_rail.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/publisher/services/publisher_search_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_status_controller.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

part 'desktop_home_rails_part.dart';

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
  int _trendingWindowDays = 7;

  bool _loadingRails = true;
  bool _loadingTrending = true;
  bool _showForYou = false;

  /// Only used when the window is too narrow to dock the rail beside the feed.
  bool _upcomingOpen = false;

  /// Built the first time it opens, so a closed sidebar costs no request.
  bool _upcomingBuilt = false;

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
      _home.fetchTrending(type: _trendingType, windowDays: _trendingWindowDays),
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
      windowDays: _trendingWindowDays,
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
          sortBy: _trendingWindowDays == 30 ? 'trending_30d' : 'trending_7d',
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
          tagId: genre.tagId.toString(),
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

        return DerivedLayoutBuilder<bool>(
          derive: (constraints) => constraints.maxWidth >= _railMinWidth,
          builder: (context, showRail) {
            final feed = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DesktopPageHeader(
                  title: l10n.translate('home'),
                  // With the rail shown, the window controls float over it, not over this header.
                  reserveWindowControls: !showRail,
                  actions: [
                    if (!showRail)
                      DesktopIconButton(
                        icon: Icons.event_note_rounded,
                        filled: _upcomingOpen,
                        tooltip: l10n.translate('upcoming_releases'),
                        onPressed: () => setState(() {
                          _upcomingOpen = !_upcomingOpen;
                          _upcomingBuilt = true;
                        }),
                      ),
                    DesktopIconButton(
                      icon: Icons.refresh_rounded,
                      filled: true,
                      tooltip: '${l10n.translate('refresh')}  (Ctrl+R)',
                      onPressed: refresh,
                    ),
                  ],
                ),
                Expanded(
                  child: _withUpcomingOverlay(
                    ListView(
                      padding: const EdgeInsets.only(bottom: 48),
                      children: [
                        _padded(
                          DesktopTrendingBoard(
                            series: _trending,
                            loading: _loadingTrending,
                            selectedType: _trendingType,
                            window: _trendingWindowDays,
                            onTypeChanged: (type) {
                              if (type == _trendingType) return;
                              setState(() => _trendingType = type);
                              _reloadTrending();
                            },
                            onWindowChanged: (days) {
                              if (days == _trendingWindowDays) return;
                              setState(() => _trendingWindowDays = days);
                              _reloadTrending();
                            },
                            onViewAll: _openTrendingAll,
                            metadata: getIt<MetadataService>(),
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
                        _padded(_publishersRail()),
                        _padded(_stacksRail()),
                        _rail(l10n.translate('rising'), _rising),
                        _rail(l10n.translate('hidden_gems'), _hiddenGems),
                        _rail(l10n.translate('new_releases'), _newReleases),
                      ],
                    ),
                    showRail: showRail,
                  ),
                ),
              ],
            );

            if (!showRail) return feed;

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
                    child: _upcomingRail(),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
