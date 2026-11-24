part of 'desktop_library_screen.dart';

/// A list picked in the side panel scopes the whole page: statuses, search and grid.
mixin _DesktopLibraryListsScope on State<DesktopLibraryScreen> {
  late final LibraryListsController lists = LibraryListsController(
    service: getIt<LibraryListsService>(),
    library: getIt<LibraryService>(),
    watchEntries: false,
  );
  late final LibraryListFlows listFlows = LibraryListFlows(
    lists,
    search: getIt<SeriesSearchService>(),
  );
  int? listScope;
  final Set<String> selectedSeries = {};

  LibraryList? get scopedList =>
      listScope == null ? null : lists.byId(listScope!);

  void initLists() {
    lists.addListener(_onListsChanged);
    if (getIt<ProfileAuthService>().isLoggedIn) lists.refresh();
  }

  void disposeLists() {
    lists.removeListener(_onListsChanged);
    lists.dispose();
  }

  void _onListsChanged() {
    if (!mounted) return;
    setState(() {
      final scope = listScope;
      if (scope == null) return;
      if (lists.isLoaded && lists.byId(scope) == null) {
        listScope = null;
        selectedSeries.clear();
        return;
      }
      final members = {for (final e in lists.entriesOn(scope)) e.series.id};
      selectedSeries.removeWhere((id) => !members.contains(id));
    });
  }

  List<LibraryEntry> scopedEntries(List<LibraryEntry> entries) =>
      listScope == null ? entries : lists.entriesOn(listScope!);

  /// The owner shows every status: a list spans them all.
  void didScopeToList();

  void scopeTo(int? id) => setState(() {
    listScope = id;
    selectedSeries.clear();
    if (id != null) didScopeToList();
  });

  void toggleSeries(api.Series series) => setState(() {
    if (!selectedSeries.remove(series.id)) selectedSeries.add(series.id);
  });

  Future<void> openListsPage() => Navigator.of(context).push(
    AppTransitions.fade(
      DesktopListsPage(
        lists: lists,
        flows: listFlows,
        onOpenList: (id) {
          Navigator.of(context).maybePop();
          scopeTo(id);
        },
      ),
    ),
  );

  Future<void> createList() async {
    final created = await listFlows.create(context);
    if (created != null && mounted) scopeTo(created.id);
  }

  Future<void> _removeSelected(LibraryList list) async {
    final l10n = LocalizationService();
    final count = selectedSeries.length;
    final (failed, error) = await lists.setMembershipMany(
      list.id,
      selectedSeries.toList(),
      member: false,
    );
    if (!mounted) return;
    if (failed == 0) setState(selectedSeries.clear);
    AppSnackBar.show(
      context,
      error != null
          ? l10n.translate(error)
          : l10n
                .translate('lists_removed_many')
                .replaceAll('{count}', '$count'),
      isError: error != null,
    );
  }

  List<Widget> scopedHeaderActions(
    LocalizationService l10n,
    LibraryList list,
    LibrarySyncStatus status,
    VoidCallback onSync,
  ) => [
    DesktopPillButton(
      key: const ValueKey('desktop_list_add_series'),
      label: l10n.translate('lists_add_series'),
      icon: Icons.playlist_add_rounded,
      onPressed: () => listFlows.addSeries(context, list),
    ),
    Builder(
      builder: (context) => DesktopIconButton(
        key: const ValueKey('desktop_list_menu'),
        icon: Icons.more_horiz_rounded,
        tooltip: l10n.translate('more_options'),
        onPressed: () => listFlows.showMenu(
          context,
          list,
          anchor: globalRectOf(context),
          onDeleted: () => scopeTo(null),
        ),
      ),
    ),
    DesktopPillButton(
      label: l10n.translate(status.isSyncing ? 'syncing' : 'sync_now'),
      icon: Icons.sync_rounded,
      onPressed: status.isSyncing ? null : onSync,
    ),
  ];

  Widget? scopedEmpty(LocalizationService l10n) {
    final list = scopedList;
    if (list == null) return null;
    return DesktopEmptyState(
      icon: Icons.playlist_add_rounded,
      message: l10n.translate('lists_empty_series'),
      action: DesktopPillButton(
        label: l10n.translate('lists_add_series'),
        icon: Icons.playlist_add_rounded,
        primary: true,
        onPressed: () => listFlows.addSeries(context, list),
      ),
    );
  }

  Widget selectionBar(LocalizationService l10n) {
    final list = scopedList;
    return ListsSelectionBar(
      visible: list != null && selectedSeries.isNotEmpty,
      count: selectedSeries.length,
      busy: list != null && lists.isBusy(list.id),
      onClose: () => setState(selectedSeries.clear),
      actions: [
        SelectionAction(
          icon: Icons.playlist_remove_rounded,
          label: l10n.translate('lists_remove_from_list'),
          destructive: true,
          onPressed: list == null ? null : () => _removeSelected(list),
        ),
      ],
    );
  }
}
