import 'package:mangabaka_app/features/series/widgets/entry_list_item_content.dart';
import 'package:mangabaka_app/features/series/widgets/series_quick_action_button.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/series_list_deps.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
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
  final SeriesListDeps deps;

  const EntryListItem({
    super.key,
    required this.series,
    required this.deps,
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
  bool _hovered = false;

  // The DB watch stream is cached: created in build it re-registers a drift watch query every rebuild.
  Stream<LibraryEntry?>? _entryStream;

  @override
  void initState() {
    super.initState();
    widget.deps.auth.addListener(_onAuthChanged);
    _updateEntryStream();
  }

  @override
  void didUpdateWidget(EntryListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deps.auth != widget.deps.auth) {
      oldWidget.deps.auth.removeListener(_onAuthChanged);
      widget.deps.auth.addListener(_onAuthChanged);
    }
    if (oldWidget.series.id != widget.series.id ||
        oldWidget.deps.library != widget.deps.library) {
      _updateEntryStream();
    }
    if (oldWidget.listStyle != widget.listStyle) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.deps.auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    setState(_updateEntryStream);
  }

  void _updateEntryStream() {
    _entryStream = widget.deps.auth.isLoggedIn
        ? widget.deps.library.watchEntryFromDb(widget.series.id)
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
    final item = _buildItem(
      context,
      style,
      l10n,
      displayTitle,
      settings,
      entry,
    );
    if (widget.ranking == null || style.isGrid) return item;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 34,
          child: Text(
            '${widget.ranking}',
            textAlign: TextAlign.center,
            style: AppTypography.display(
              color: context.colors.accent,
              fontSize: 17,
            ),
          ),
        ),
        Expanded(child: item),
      ],
    );
  }

  Widget _buildItem(
    BuildContext context,
    AppListStyle style,
    LocalizationService l10n,
    String displayTitle,
    SettingsManager settings,
    LibraryEntry? entry,
  ) {
    final isInLibrary = entry != null;
    final showBadge = widget.ranking != null && style.isGrid;

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
                  ? EntryProgressBar(
                      series: widget.series,
                      entry: entry,
                      optimisticProgress: _optimisticProgress,
                    )
                  : null,
              trailing: settings.showQuickProgress
                  ? SeriesQuickActionButton(
                      series: widget.series,
                      entry: entry,
                      library: widget.deps.library,
                      onOptimisticProgressChanged: (val) {
                        setState(() {
                          _optimisticProgress = val;
                        });
                      },
                    )
                  : null,
            ),
          ],
        ),
      );
    }

    return SeriesHoverPreview(
      series: widget.series,
      child: MouseRegion(
        onEnter: style.isGrid ? (_) => setState(() => _hovered = true) : null,
        onExit: style.isGrid ? (_) => setState(() => _hovered = false) : null,
        child: Stack(
          children: [
            EntryListItemContent(
              series: widget.series,
              library: widget.deps.library,
              style: style,
              l10n: l10n,
              displayTitle: displayTitle,
              entry: entry,
              heroTagPrefix: widget.heroTagPrefix,
              optimisticProgress: _optimisticProgress,
              hovered: _hovered,
            ),

            if (!style.isGrid &&
                isInLibrary &&
                (settings.showLibraryProgress ||
                    settings.showRemainingProgress))
              Positioned(
                bottom: style == AppListStyle.comfortable ? 6 : 4,
                left:
                    (style == AppListStyle.minimalList
                        ? 48.0
                        : (style == AppListStyle.compact ? 60.0 : 72.0)) +
                    12,
                right: 12,
                child: EntryProgressBar(
                  series: widget.series,
                  entry: entry,
                  optimisticProgress: _optimisticProgress,
                ),
              ),

            if (!style.isGrid && settings.showQuickProgress)
              Positioned(
                bottom: style == AppListStyle.comfortable ? 12 : 8,
                right: style == AppListStyle.comfortable ? 12 : 10,
                child: SeriesQuickActionButton(
                  series: widget.series,
                  entry: entry,
                  library: widget.deps.library,
                  onOptimisticProgressChanged: (val) {
                    setState(() {
                      _optimisticProgress = val;
                    });
                  },
                ),
              ),

            if (showBadge) EntryRankingBadge(ranking: widget.ranking!),
          ],
        ),
      ),
    );
  }
}
