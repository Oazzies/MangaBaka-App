part of 'desktop_library_screen.dart';

extension _DesktopLibraryMain on DesktopLibraryScreenState {
  Widget _main(
    LocalizationService l10n,
    LibraryFilterHelper? helper,
    int total,
  ) {
    final statusLabel = _status == DesktopLibraryScreenState.allKey
        ? l10n.translate('all')
        : l10n.translate(_status);
    final scoped = scopedList;

    return ValueListenableBuilder<LibrarySyncStatus>(
      valueListenable: _libraryService.syncStatus,
      builder: (context, status, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesktopPageHeader(
              leading: scoped == null
                  ? null
                  : DesktopIconButton(
                      key: const ValueKey('desktop_list_clear_scope'),
                      icon: Icons.close_rounded,
                      tooltip: l10n.translate('lists_show_all'),
                      onPressed: () => scopeTo(null),
                    ),
              title: scoped?.name ?? l10n.translate('library'),
              subtitle: helper == null
                  ? null
                  : [
                      statusLabel,
                      l10n
                          .translate('series_count')
                          .replaceAll(
                            '{count}',
                            NumberUtils.formatCount(
                              helper.getByTabOrAll(_status).length,
                            ),
                          ),
                      if (scoped?.isPrivate ?? false)
                        l10n.translate('lists_private'),
                    ].join(' · '),
              actions: scoped != null
                  ? scopedHeaderActions(l10n, scoped, status, _session.refresh)
                  : [
                      DesktopPillButton(
                        label: l10n.translate('import_export_title'),
                        icon: Icons.import_export_rounded,
                        onPressed: () => ImportExportScreen.open(context),
                      ),
                      DesktopPillButton(
                        label: l10n.translate(
                          status.isSyncing ? 'syncing' : 'sync_now',
                        ),
                        icon: Icons.sync_rounded,
                        onPressed: status.isSyncing ? null : _session.refresh,
                      ),
                    ],
            ),
            LibraryStatusBanners(
              status: status,
              isIncomplete: _session.isIncomplete,
              onRetrySync: _session.refresh,
              onDismissError: () => _libraryService.syncStatus.value =
                  _libraryService.syncStatus.value.copyWith(clearError: true),
              onImportFullLibrary: _libraryService.importFullLibrary,
            ),
            _DesktopLibraryToolbar(
              searchFocus: _searchFocus,
              session: _session,
              filters: _filters,
              onQueryChanged: _setQuery,
              onResultSelected: _onResultSelected,
              onFiltersChanged: _setFilters,
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _DesktopLibraryGrid(
                      helper: helper,
                      status: _status,
                      scrollController: _scrollFor('${listScope}_$_status'),
                      onRefresh: _session.refresh,
                      onItemTap: _openDetail,
                      deps: _listDeps,
                      selectedIds: selectedSeries,
                      onItemLongPress: scoped == null ? null : toggleSeries,
                      emptyScope: scopedEmpty(l10n),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 8,
                    child: selectionBar(l10n),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
