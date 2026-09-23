import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/widgets/layouts/series_detail_mobile_layout.dart';
import 'package:mangabaka_app/features/series/widgets/layouts/series_detail_wide_layout.dart';
import 'package:mangabaka_app/features/series/widgets/series_detail_app_bar.dart';
import 'package:mangabaka_app/features/series/widgets/series_detail_error_banner.dart';
import 'package:mangabaka_app/features/series/widgets/series_detail_tab_content.dart';
import 'package:mangabaka_app/shared/widgets/app_shortcuts.dart';

/// The scrolling content of the series detail page: app bar, an error banner
/// when the refresh failed, and the width-appropriate layout.
///
/// The two layouts take the same fifteen arguments, so the wiring is built
/// once here and handed to whichever is chosen. Inline in the screen it was
/// two near-identical 30-line argument lists, where a change to one routinely
/// missed the other.
class SeriesDetailBody extends StatelessWidget {
  /// The screen's state, read for the fetched series and tab payloads. Passed
  /// as a whole rather than as a dozen fields because it changes as a unit on
  /// every fetch.
  final SeriesDetailScreenState state;

  final Stream<LibraryEntry?>? entryStream;
  final SettingsManager settings;
  final LocalizationService l10n;

  /// Rendered inside a host screen: the app bar drops its back control and the
  /// page stops reserving space for a FAB it does not have.
  final bool embedded;

  /// Optional content for a right-hand rail in the wide layout, scrolling
  /// alongside the page. Used by the Discovery Queue.
  final Widget? rightRail;

  final VoidCallback onRetry;
  final ValueChanged<String> onTabChanged;
  final ValueChanged<String> onAuthorTap;
  final ValueChanged<String> onPublisherTap;

  /// Below this the mobile layout is used; above [_wideBreakpoint] the app bar
  /// also switches to its roomier arrangement.
  static const double _tabletBreakpoint = 600;
  static const double wideBreakpoint = 900;

  /// Content stops widening here so lines stay readable on a desktop window.
  static const double _maxContentWidth = 1400;

  const SeriesDetailBody({
    super.key,
    required this.state,
    required this.entryStream,
    required this.settings,
    required this.l10n,
    this.embedded = false,
    this.rightRail,
    required this.onRetry,
    required this.onTabChanged,
    required this.onAuthorTap,
    required this.onPublisherTap,
  });

  @override
  Widget build(BuildContext context) {
    // The space this page actually has, not the window: on desktop it sits
    // beside the sidebar, and the window width overstated it by the sidebar.
    return LayoutBuilder(
      builder: (context, constraints) => _build(context, constraints.maxWidth),
    );
  }

  Widget _build(BuildContext context, double width) {
    final isWide = width > wideBreakpoint;
    final isTablet = width > _tabletBreakpoint && width <= wideBreakpoint;

    // Render from the Series we were handed on the very first frame — the
    // common navigation paths (search, browse, library, home) all pass a
    // fully-populated, precached Series, so there is no network wait and
    // nothing to show a skeleton *for*. The richer `fullSeries` from the
    // network then swaps into the same widgets without a layout jump.
    //
    // The skeleton still covers sparse entrances — a bare reference with no
    // description or genres — until the fetch resolves.
    final series = state.fullSeries ?? state.series;
    final hasInitialContent =
        series.description.isNotEmpty || series.genres.isNotEmpty;
    final isLoaded = state.isDataLoaded || hasInitialContent;

    return Actions(
      actions: <Type, Action<Intent>>{
        RefreshIntent: CallbackAction<RefreshIntent>(
          onInvoke: (_) {
            onRetry();
            return null;
          },
        ),
      },
      child: StreamBuilder<LibraryEntry?>(
        stream: entryStream,
        builder: (context, snapshot) {
          return RepaintBoundary(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SeriesDetailAppBar(
                  series: series,
                  title: series.getDisplayTitle(settings.defaultTitleLanguage),
                  entry: snapshot.data,
                  isWide: isWide || isTablet,
                  embedded: embedded,
                  horizontalPadding: isWide ? 40.0 : 16.0,
                  onBack: () => Navigator.pop(context),
                  onShare: state.shareLink,
                  onDelete: state.showDeleteConfirmationDialog,
                  onCopy: state.copyToClipboard,
                  heroTagPrefix: state.widget.heroTagPrefix,
                ),
                if (state.fetchError) SeriesDetailErrorBanner(onRetry: onRetry),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _maxContentWidth,
                      ),
                      child: _layout(
                        series: series,
                        entry: snapshot.data,
                        isLoaded: isLoaded,
                        isWide: isWide,
                      ),
                    ),
                  ),
                ),
                // Clears the floating action button.
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _layout({
    required Series series,
    required LibraryEntry? entry,
    required bool isLoaded,
    required bool isWide,
  }) {
    final title = series.getDisplayTitle(settings.defaultTitleLanguage);
    final id = series.id;

    final library = state.libraryService;
    void setState(String value) => library.updateLibraryEntryState(id, value);
    void setRating(int rating) => library.updateLibraryEntryRating(id, rating);

    // Progress and rating dialogs need an entry to edit; without one in the
    // library there is nothing to update, so the callbacks are inert.
    void updateChapter() => entry == null
        ? null
        : state.showUpdateProgressDialog(entry, isChapter: true);
    void updateVolume() => entry == null
        ? null
        : state.showUpdateProgressDialog(entry, isChapter: false);
    void updateRating() =>
        entry == null ? null : state.showUpdateRatingDialog(entry);

    SeriesDetailTabContent tabContent({
      required double hPadding,
      bool isWide = false,
      bool wideRightPaddingOnly = false,
    }) => SeriesDetailTabContent(
      series: series,
      entry: entry,
      l10n: l10n,
      selectedTab: state.selectedTab,
      covers: state.covers,
      related: state.related,
      similar: state.similar,
      readersAlsoLike: state.readersAlsoLike,
      news: state.news,
      collections: state.collections,
      works: state.works,
      enrichedLinks: state.enrichedLinks,
      isWide: isWide,
      hPadding: hPadding,
      wideRightPaddingOnly: wideRightPaddingOnly,
    );

    if (isWide) {
      return SeriesDetailWideLayout(
        series: series,
        title: title,
        entry: entry,
        l10n: l10n,
        isDataLoaded: isLoaded,
        selectedTab: state.selectedTab,
        onAuthorTap: onAuthorTap,
        onPublisherTap: onPublisherTap,
        onTabChanged: onTabChanged,
        onStateChanged: setState,
        onRatingChanged: setRating,
        isAdding: state.isAdding,
        onAdd: state.addSeriesToLibrary,
        onUpdateChapter: updateChapter,
        onUpdateVolume: updateVolume,
        onUpdateRating: updateRating,
        rightRail: rightRail,
        buildTabContent:
            (hPadding, {isWide = false, wideRightPaddingOnly = false}) =>
                tabContent(
                  hPadding: hPadding,
                  isWide: isWide,
                  wideRightPaddingOnly: wideRightPaddingOnly,
                ),
      );
    }

    return SeriesDetailMobileLayout(
      series: series,
      title: title,
      entry: entry,
      l10n: l10n,
      isDataLoaded: isLoaded,
      selectedTab: state.selectedTab,
      onTabChanged: onTabChanged,
      onStateChanged: setState,
      onRatingChanged: setRating,
      onUpdateChapter: updateChapter,
      onUpdateVolume: updateVolume,
      onUpdateRating: updateRating,
      onAuthorTap: onAuthorTap,
      onPublisherTap: onPublisherTap,
      buildTabContent: (hPadding) => tabContent(hPadding: hPadding),
    );
  }
}
