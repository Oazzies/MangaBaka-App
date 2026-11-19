part of 'desktop_home_screen.dart';

extension _DesktopHomeRails on DesktopHomeScreenState {
  Widget _withUpcomingOverlay(Widget feed, {required bool showRail}) => showRail
      ? feed
      : DesktopUpcomingOverlay(
          feed: feed,
          railWidth: DesktopHomeScreenState._railWidth,
          open: _upcomingOpen,
          built: _upcomingBuilt,
          rail: _upcomingRail(topPadding: 16),
        );

  Widget _upcomingRail({double topPadding = 56}) => DesktopUpcomingRail(
    seriesService: getIt<SeriesService>(),
    library: getIt<LibraryService>(),
    topPadding: topPadding,
  );

  Widget _padded(Widget child) => Padding(
    padding: const EdgeInsets.fromLTRB(
      DesktopTokens.pagePadding,
      0,
      DesktopTokens.pagePadding,
      DesktopTokens.sectionGap,
    ),
    child: child,
  );

  Widget _publishersRail() => HomePublishersRail(
    service: getIt<PublisherSearchService>(),
    horizontalPadding: 0,
  );

  Widget _stacksRail() => HomeStacksRail(
    service: getIt<StackService>(),
    status: getIt<StackStatusController>(),
  );

  Widget _rail(
    String title,
    List<Series> series, {
    bool? loading,
    VoidCallback? onViewAll,
  }) => DesktopHomeRail(
    title: title,
    series: series,
    loading: loading ?? _loadingRails,
    onViewAll: onViewAll,
    prefetch: getIt<SeriesService>().fetchSeries,
  );
}
