part of 'desktop_browse_screen.dart';

class _DesktopBrowseHeader extends StatelessWidget {
  final BrowseController controller;
  final FocusNode searchFocus;
  final LocalizationService l10n;
  final bool searching;
  final ValueChanged<AutocompleteSeriesResult> onResultSelected;
  final VoidCallback onClearSearch;

  const _DesktopBrowseHeader({
    required this.controller,
    required this.searchFocus,
    required this.l10n,
    required this.searching,
    required this.onResultSelected,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesktopTokens.pagePadding,
        10,
        DesktopLayout.isDesktopPlatform
            ? DesktopTokens.windowControlsClearance
            : DesktopTokens.pagePadding,
        0,
      ),
      child: DerivedLayoutBuilder<bool>(
        derive: (constraints) => constraints.maxWidth < 620,
        builder: (context, narrow) {
          final searchBar = ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: MBSearchBar(
              focusNode: searchFocus,
              controller: c.searchController,
              initialFilters: c.currentFilters,
              showFilterButton: false,
              suggestionsAllowed: c.currentType == BrowseType.series,
              onResultSelected: onResultSelected,
              onChanged: c.updateSearchQuery,
              onSubmitted: (_) => c.searchSeries(),
            ),
          );

          final clearButton = searching
              ? DesktopPillButton(
                  label: l10n.translate('clear_all'),
                  icon: Icons.close_rounded,
                  onPressed: onClearSearch,
                )
              : null;

          final titleText = Text(
            l10n.translate('browse').toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.display(
              color: context.colors.text,
              fontSize: 30,
            ),
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: titleText),
                    if (clearButton != null) clearButton,
                  ],
                ),
                const SizedBox(height: 12),
                searchBar,
              ],
            );
          }

          return Row(
            children: [
              titleText,
              const SizedBox(width: 28),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: searchBar,
                ),
              ),
              if (clearButton != null) ...[
                const SizedBox(width: 12),
                clearButton,
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DesktopBrowseControlsBar extends StatelessWidget {
  final BrowseController controller;
  final LocalizationService l10n;
  final bool searching;

  const _DesktopBrowseControlsBar({
    required this.controller,
    required this.l10n,
    required this.searching,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesktopTokens.pagePadding,
        18,
        DesktopTokens.pagePadding,
        10,
      ),
      child: Builder(
        builder: (context) {
          final leftControls = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (c.currentFilters.isEmpty)
                DesktopSegmented<BrowseType>(
                  value: c.currentType,
                  segments: [
                    (BrowseType.series, l10n.translate('series'), null),
                    (BrowseType.publishers, l10n.translate('publishers'), null),
                    (BrowseType.staff, l10n.translate('staff'), null),
                  ],
                  onChanged: c.setType,
                ),
              if (searching && c.totalResults > 0) ...[
                const SizedBox(width: 16),
                Text(
                  '${c.totalResults}${c.isTotalCapped ? '+' : ''} '
                  '${l10n.translate(c.currentType.name)}',
                  style: AppTypography.sans(
                    color: context.colors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          );

          final rightControls = c.currentType == BrowseType.series
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DesktopSortMenu(
                      filters: c.currentFilters,
                      onChanged: c.updateFilters,
                    ),
                    const SizedBox(width: 10),
                    const DesktopListStyleToggle(scope: DesktopListScope.browse),
                  ],
                )
              : c.currentType == BrowseType.publishers
              ? DesktopMenuButton<String>(
                  label: l10n.translate('sort_by'),
                  valueLabel: publisherSortOptions(
                    l10n,
                  ).firstWhere((o) => o.$1 == c.publisherSort).$2,
                  icon: Icons.sort_rounded,
                  selected: c.publisherSort ?? '',
                  items: [
                    for (final (value, label) in publisherSortOptions(l10n))
                      (value ?? '', label),
                  ],
                  onSelected: (key) =>
                      c.setPublisherSort(key.isEmpty ? null : key),
                )
              : null;

          if (rightControls == null) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: leftControls,
            );
          }

          return Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 10,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: leftControls,
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: rightControls,
              ),
            ],
          );
        },
      ),
    );
  }
}
