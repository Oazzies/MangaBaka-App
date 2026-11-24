import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/lists/widgets/series_lists_sheet.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/widgets/complete_progress_dialog.dart';
import 'package:mangabaka_app/features/series/widgets/layouts/series_detail_mobile_layout.dart';
import 'package:mangabaka_app/features/series/widgets/layouts/series_detail_wide_layout.dart';
import 'package:mangabaka_app/features/series/widgets/series_detail_app_bar.dart';
import 'package:mangabaka_app/features/series/widgets/series_detail_error_banner.dart';
import 'package:mangabaka_app/features/series/widgets/series_detail_tab_content.dart';
import 'package:mangabaka_app/shared/widgets/app_shortcuts.dart';

class SeriesDetailBody extends StatelessWidget {
  /// Passed whole, not as a dozen fields: it changes as a unit on every fetch.
  final SeriesDetailScreenState state;

  final Stream<LibraryEntry?>? entryStream;
  final SettingsManager settings;
  final LocalizationService l10n;

  final bool embedded;

  final Widget? rightRail;

  final VoidCallback onRetry;
  final ValueChanged<String> onTabChanged;
  final ValueChanged<String> onAuthorTap;
  final ValueChanged<String> onPublisherTap;

  static const double _tabletBreakpoint = 600;
  static const double wideBreakpoint = 900;

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
    // Not the window width: on desktop the page sits beside the sidebar.
    return LayoutBuilder(
      builder: (context, constraints) => _build(context, constraints.maxWidth),
    );
  }

  Widget _build(BuildContext context, double width) {
    final isWide = width > wideBreakpoint;
    final isTablet = width > _tabletBreakpoint && width <= wideBreakpoint;

    // Most entrances hand over a full Series, so the skeleton only covers a bare reference.
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
                  onShare: (anchor) => state.shareLink(anchor: anchor),
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
                        context: context,
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
    required BuildContext context,
    required Series series,
    required LibraryEntry? entry,
    required bool isLoaded,
    required bool isWide,
  }) {
    final title = series.getDisplayTitle(settings.defaultTitleLanguage);
    final id = series.id;

    final library = state.libraryService;
    Future<void> setState(String value) async {
      final totalChapters = int.tryParse(series.totalChapters);
      final totalVolumes = int.tryParse(series.finalVolume);

      if (value == 'completed' &&
          settings.autoCompleteChapterProgress ==
              AutoCompleteProgressMode.prompt) {
        final currentChapter = entry?.progressChapter ?? 0;
        final currentVolume = entry?.progressVolume ?? 0;
        final chaptersCanUpdate =
            totalChapters != null &&
            totalChapters > 0 &&
            currentChapter < totalChapters;
        final volumesCanUpdate =
            totalVolumes != null &&
            totalVolumes > 0 &&
            currentVolume < totalVolumes;

        if (chaptersCanUpdate || volumesCanUpdate) {
          final choice = await showCompleteProgressDialog(
            context,
            currentChapter: currentChapter,
            totalChapters: totalChapters,
            currentVolume: currentVolume,
            totalVolumes: totalVolumes,
          );
          await library.updateLibraryEntryState(
            id,
            value,
            totalChapters: totalChapters,
            totalVolumes: totalVolumes,
            completeChapters: choice?.updateChapters ?? false,
            completeVolumes: choice?.updateVolumes ?? false,
          );
          return;
        }
      }

      await library.updateLibraryEntryState(
        id,
        value,
        totalChapters: totalChapters,
        totalVolumes: totalVolumes,
      );
    }
    void setRating(int rating) => library.updateLibraryEntryRating(id, rating);

    void updateChapter() => entry == null
        ? null
        : state.showUpdateProgressDialog(entry, isChapter: true);
    void updateVolume() => entry == null
        ? null
        : state.showUpdateProgressDialog(entry, isChapter: false);
    void updateRating() =>
        entry == null ? null : state.showUpdateRatingDialog(entry);
    void updateNote() =>
        entry == null ? null : state.showUpdateNoteDialog(entry);
    void editLists() => showSeriesListsSheet(
      context,
      service: state.listsService,
      library: library,
      series: series,
    );

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
      deps: state.listDeps,
      metadata: state.metadata,
      stackService: state.stackService,
      stackStatus: state.stackStatus,
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
        isLoggedIn: state.isLoggedIn,
        metadata: state.metadata,
        isAdding: state.isAdding,
        onAdd: state.addSeriesToLibrary,
        onUpdateChapter: updateChapter,
        onUpdateVolume: updateVolume,
        onUpdateRating: updateRating,
        onUpdateNote: updateNote,
        listsService: state.listsService,
        onEditLists: editLists,
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
      metadata: state.metadata,
      onTabChanged: onTabChanged,
      onStateChanged: setState,
      onRatingChanged: setRating,
      onUpdateChapter: updateChapter,
      onUpdateVolume: updateVolume,
      onUpdateRating: updateRating,
      onUpdateNote: updateNote,
      listsService: state.listsService,
      onEditLists: editLists,
      onAuthorTap: onAuthorTap,
      onPublisherTap: onPublisherTap,
      buildTabContent: (hPadding) => tabContent(hPadding: hPadding),
    );
  }
}
