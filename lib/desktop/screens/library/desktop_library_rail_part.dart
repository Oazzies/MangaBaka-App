part of 'desktop_library_screen.dart';

class _DesktopLibraryToolbar extends StatelessWidget {
  final FocusNode searchFocus;
  final LibrarySession session;
  final SearchFilters filters;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<AutocompleteSeriesResult> onResultSelected;
  final ValueChanged<SearchFilters> onFiltersChanged;

  const _DesktopLibraryToolbar({
    required this.searchFocus,
    required this.session,
    required this.filters,
    required this.onQueryChanged,
    required this.onResultSelected,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesktopTokens.pagePadding,
        0,
        DesktopTokens.pagePadding,
        12,
      ),
      child: BesideOrBelow(
        minBodyWidth: 280,
        body: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: LibrarySearchBar(
            focusNode: searchFocus,
            entriesStream: session.entriesStream,
            onChanged: onQueryChanged,
            onResultSelected: onResultSelected,
            initialFilters: filters,
            showFilterButton: false,
          ),
        ),
        trailing: Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DesktopSortMenu(
              filters: filters,
              onChanged: onFiltersChanged,
              library: true,
            ),
            const DesktopListStyleToggle(scope: DesktopListScope.library),
          ],
        ),
      ),
    );
  }
}

extension on LibraryFilterHelper {
  List<LibraryEntry> getByTabOrAll(String key) =>
      key == DesktopLibraryScreenState.allKey
      ? getFilteredAndSorted()
      : getByTab(key);
}

/// The status list at the top of the library panel.
class _StatusList extends StatelessWidget {
  final String selected;
  final Map<String, int> counts;
  final int total;
  final ValueChanged<String> onSelected;

  const _StatusList({
    required this.selected,
    required this.counts,
    required this.total,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            l10n.translate('status').toUpperCase(),
            style: AppTypography.display(
              color: context.colors.text,
              fontSize: 17,
            ),
          ),
        ),
        _StatusRow(
          label: l10n.translate('all'),
          color: context.colors.textMuted,
          icon: Icons.apps_rounded,
          count: total,
          selected: selected == DesktopLibraryScreenState.allKey,
          onTap: () => onSelected(DesktopLibraryScreenState.allKey),
        ),
        for (final tab in LibraryScreenConstants.tabs)
          _StatusRow(
            label: l10n.translate(tab.key),
            color: context.colors.forState(tab.key),
            icon: StatusIcons.forState(tab.key),
            count: counts[tab.key] ?? 0,
            selected: selected == tab.key,
            onTap: () => onSelected(tab.key),
          ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _StatusRow({
    required this.label,
    required this.color,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: DesktopHoverSurface(
        onTap: onTap,
        selected: selected,
        selectedColor: context.colors.surfaceRaised,
        hoverColor: context.colors.surface,
        borderRadius: BorderRadius.circular(10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.sans(
                  color: selected
                      ? context.colors.text
                      : context.colors.text.withValues(alpha: 0.85),
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            Text(
              NumberUtils.formatCount(count),
              style: AppTypography.sans(
                color: selected ? color : context.colors.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopLibraryGrid extends StatelessWidget {
  final LibraryFilterHelper? helper;
  final String status;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final void Function(api.Series) onItemTap;

  const _DesktopLibraryGrid({
    required this.helper,
    required this.status,
    required this.scrollController,
    required this.onRefresh,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    if (helper == null) {
      return SeriesListSkeleton(
        isGrid: SettingsManager().resolvedLibraryListStyle.isGrid,
      );
    }
    if (helper!.allEntries.isEmpty) {
      return DesktopEmptyState(
        icon: Icons.library_books_outlined,
        message: l10n.translate('empty_library'),
      );
    }

    final items = helper!.getByTabOrAll(status);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesktopTokens.pagePadding - 12,
      ),
      child: LibraryGridList(
        key: ValueKey('desktop_library_$status'),
        items: items,
        tabKey: status,
        scrollController: scrollController,
        onRefresh: onRefresh,
        onItemTap: onItemTap,
      ),
    );
  }
}
