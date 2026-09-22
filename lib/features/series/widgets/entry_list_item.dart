import 'package:mangabaka_app/features/series/widgets/entry_list_item_layouts.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item_list_layouts.dart';
import 'package:mangabaka_app/features/series/widgets/series_quick_action_button.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_series_row.dart';
import 'package:mangabaka_app/desktop/widgets/series_hover_preview.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class EntryListItem extends StatefulWidget {
  final Series series;
  final int? ranking;
  final bool isLibrary;
  final String? heroTagPrefix;
  final AppListStyle? listStyle;
  final LibraryEntry? previewEntry;

  const EntryListItem({
    super.key,
    required this.series,
    this.ranking,
    this.isLibrary = false,
    this.heroTagPrefix,
    this.listStyle,
    this.previewEntry,
  });

  @override
  State<EntryListItem> createState() => _EntryListItemState();
}

class _EntryListItemState extends State<EntryListItem> {
  int? _optimisticProgress;

  // The DB watch stream is created once and cached. Creating it inline in
  // build() would tear down and re-register a drift watch query on every
  // rebuild of every visible list item — a real cost while scrolling,
  // especially on older devices.
  late final ProfileAuthService _auth;
  late final LibraryService _libraryService;
  Stream<LibraryEntry?>? _entryStream;

  @override
  void initState() {
    super.initState();
    _auth = getIt<ProfileAuthService>();
    _libraryService = getIt<LibraryService>();
    _auth.addListener(_onAuthChanged);
    _updateEntryStream();
  }

  @override
  void didUpdateWidget(EntryListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.series.id != widget.series.id) {
      _updateEntryStream();
    }
    if (oldWidget.listStyle != widget.listStyle) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    setState(_updateEntryStream);
  }

  void _updateEntryStream() {
    _entryStream = _auth.isLoggedIn
        ? _libraryService.watchEntryFromDb(widget.series.id)
        : Stream<LibraryEntry?>.value(null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final settings = SettingsManager();
    final displayTitle = widget.series.getDisplayTitle(
      settings.defaultTitleLanguage,
    );
    final style =
        widget.listStyle ??
        (widget.isLibrary
            ? settings.resolvedLibraryListStyle
            : settings.resolvedBrowseListStyle);

    if (widget.previewEntry != null) {
      return _buildStack(
        context,
        style,
        l10n,
        displayTitle,
        settings,
        widget.previewEntry,
      );
    }

    return StreamBuilder<LibraryEntry?>(
      stream: _entryStream,
      builder: (context, snapshot) {
        final entry = snapshot.data;

        // Reset optimistic progress if the DB entry catches up
        if (entry != null &&
            _optimisticProgress != null &&
            entry.progressChapter == _optimisticProgress) {
          _optimisticProgress = null;
        }

        return _buildStack(context, style, l10n, displayTitle, settings, entry);
      },
    );
  }

  Widget _buildStack(
    BuildContext context,
    AppListStyle style,
    LocalizationService l10n,
    String displayTitle,
    SettingsManager settings,
    LibraryEntry? entry,
  ) {
    final isInLibrary = entry != null;

    // On desktop the list styles are table rows, not the phone's cards: the
    // row lays out its own progress bar and quick-progress control in columns
    // instead of having them stacked over it.
    if (!style.isGrid && DesktopLayout.isActive(context)) {
      return SeriesHoverPreview(
        series: widget.series,
        child: Stack(
          children: [
            DesktopSeriesRow(
              series: widget.series,
              style: style,
              displayTitle: displayTitle,
              heroTagPrefix: widget.heroTagPrefix,
              progress:
                  isInLibrary &&
                      (settings.showLibraryProgress ||
                          settings.showRemainingProgress)
                  ? _buildProgressBar(context, entry, style)
                  : null,
              trailing: settings.showQuickProgress
                  ? SeriesQuickActionButton(
                      series: widget.series,
                      entry: entry,
                      onOptimisticProgressChanged: (val) {
                        setState(() {
                          _optimisticProgress = val;
                        });
                      },
                    )
                  : null,
            ),
            if (widget.ranking != null) _rankingBadge(),
          ],
        ),
      );
    }

    return SeriesHoverPreview(
      series: widget.series,
      child: Stack(
        children: [
          _buildContent(context, style, l10n, displayTitle, entry),

          if (!style.isGrid &&
              isInLibrary &&
              (settings.showLibraryProgress || settings.showRemainingProgress))
            Positioned(
              bottom: style == AppListStyle.comfortable ? 6 : 4,
              left:
                  (style == AppListStyle.minimalList
                      ? 48.0
                      : (style == AppListStyle.compact ? 60.0 : 72.0)) +
                  12,
              right: 12,
              child: _buildProgressBar(context, entry, style),
            ),

          if (!style.isGrid && settings.showQuickProgress)
            Positioned(
              bottom: style == AppListStyle.comfortable ? 12 : 8,
              right: style == AppListStyle.comfortable ? 12 : 10,
              child: SeriesQuickActionButton(
                series: widget.series,
                entry: entry,
                onOptimisticProgressChanged: (val) {
                  setState(() {
                    _optimisticProgress = val;
                  });
                },
              ),
            ),

          if (widget.ranking != null) _rankingBadge(),
        ],
      ),
    );
  }

  Widget _rankingBadge() {
    return Positioned(
      top: 0,
      left: 0,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.accent,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          '${widget.ranking}',
          style: AppTypography.display(
            color: context.colors.onAccent,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    LibraryEntry entry,
    AppListStyle style,
  ) {
    final totalChapters = int.tryParse(widget.series.totalChapters) ?? 0;
    if (totalChapters <= 0) return const SizedBox.shrink();

    final progress = _optimisticProgress ?? entry.progressChapter ?? 0;
    final percentage = (progress / totalChapters).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: percentage,
        backgroundColor: context.colors.surfaceRaised,
        valueColor: AlwaysStoppedAnimation<Color>(context.colors.accent),
        minHeight: 3,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppListStyle style,
    LocalizationService l10n,
    String displayTitle,
    LibraryEntry? entry,
  ) {
    switch (style) {
      case AppListStyle.coverOnlyGrid:
        return CoverOnlyGridItem(
          series: widget.series,
          heroTagPrefix: widget.heroTagPrefix,
          entry: entry,
          progressOverride: _optimisticProgress,
        );
      case AppListStyle.compactGrid:
        return CompactGridItem(
          series: widget.series,
          heroTagPrefix: widget.heroTagPrefix,
          displayTitle: displayTitle,
          entry: entry,
          progressOverride: _optimisticProgress,
        );
      case AppListStyle.minimalList:
        return MinimalListItem(
          series: widget.series,
          heroTagPrefix: widget.heroTagPrefix,
          displayTitle: displayTitle,
        );
      case AppListStyle.compact:
        return CompactListItem(
          series: widget.series,
          heroTagPrefix: widget.heroTagPrefix,
          displayTitle: displayTitle,
          l10n: l10n,
        );
      case AppListStyle.comfortable:
        return ComfortableListItem(
          series: widget.series,
          heroTagPrefix: widget.heroTagPrefix,
          displayTitle: displayTitle,
          l10n: l10n,
        );
    }
  }
}
