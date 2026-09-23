import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/utils/browse_helpers.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/filter_chips_row.dart';
import 'package:mangabaka_app/features/library/constants/library_screen_constants.dart';
import 'package:mangabaka_app/features/library/controllers/library_session.dart';
import 'package:mangabaka_app/features/library/controllers/library_tab_coordinator.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/models/library_sync_status.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/library/widgets/library_app_bar.dart';
import 'package:mangabaka_app/features/library/widgets/library_body.dart';
import 'package:mangabaka_app/features/library/widgets/library_status_banners.dart';
import 'package:mangabaka_app/features/library/widgets/library_tab_bar.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/features/series/models/series.dart' as api;
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/shared/widgets/app_shortcuts.dart';

/// The user's library, tabbed by reading status.
///
/// Holds the search and filter state and the widgets that display it.
/// [LibrarySession] owns the account connection — the entries stream, the
/// sync, sign-in — and [LibraryTabCoordinator] decides which tab should be
/// showing and what each one's badge reads.
class LibraryScreen extends StatefulWidget {
  static final GlobalKey<LibraryScreenState> libraryScreenKey =
      GlobalKey<LibraryScreenState>();

  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen>
    with TickerProviderStateMixin {
  static final _logger = LoggingService.logger;

  /// Widest the list grows before it is centred. Grids are left unbounded —
  /// they use the extra width for more columns, where a list would just get
  /// unreadably long lines.
  static const double _maxListWidth = 800;

  late final LibraryService _libraryService;
  late final LibrarySession _session;
  late final LibraryTabCoordinator _tabs;
  late final TabController _tabController;
  late final Map<String, ScrollController> _scrollControllers;

  final FocusNode _searchFocusNode = FocusNode();

  String _query = '';
  SearchFilters _filters = SearchFilters();
  bool _isSearching = false;

  // ─── Public surface ──────────────────────────────────────────────────────

  FocusNode get searchFocusNode => _searchFocusNode;
  Stream<List<LibraryEntry>>? get entriesStream => _session.entriesStream;
  SearchFilters get filters => _filters;
  String get query => _query;

  void enterSearchMode() {
    setState(() => _isSearching = true);
    _searchFocusNode.requestFocus();
  }

  void updateQuery(String value) {
    setState(() => _query = value);
    _tabs.setQuery(value);
    _tabs.autoSwitch();
  }

  void updateFilters(SearchFilters filters) {
    setState(() => _filters = filters);
    _tabs.setFilters(filters);
    _tabs.autoSwitch();
  }

  void handleResultSelected(AutocompleteSeriesResult result) {
    _logger.info('Library autocomplete result selected: ${result.title}');
    _navigateToSeriesDetail(BrowseHelpers.convertAutocompleteToSeries(result));
  }

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _logger.info('Library screen initialized');

    _libraryService = getIt<LibraryService>();

    _tabController = TabController(
      length: LibraryScreenConstants.tabs.length,
      vsync: this,
    );
    _tabController.addListener(_handleTabSelection);
    _tabs = LibraryTabCoordinator(controller: _tabController);
    _scrollControllers = {
      for (final tab in LibraryScreenConstants.tabs)
        tab.key: ScrollController(),
    };

    _session = LibrarySession(onEntries: _onEntriesUpdate);
    _session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    _session.dispose();
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging) return;
    _logger.info('Library tab switched to: ${_tabController.index}');
  }

  void _onSessionChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onEntriesUpdate(List<LibraryEntry> entries) {
    if (!mounted) return;
    _tabs.setEntries(entries);
    _tabs.autoSwitch();
  }

  Future<void> _login() async {
    final errorKey = await _session.login();
    if (errorKey == null || !mounted) return;
    AppSnackBar.show(
      context,
      LocalizationService().translate(errorKey),
      isError: true,
    );
  }

  // ─── Search ──────────────────────────────────────────────────────────────

  void _exitSearch() {
    setState(() {
      _isSearching = false;
      _query = '';
      _filters = SearchFilters();
    });
    _tabs.reset();
  }

  void _navigateToSeriesDetail(api.Series series) {
    Navigator.of(context)
        .push(AppTransitions.slideUp(SeriesDetailScreen(series: series)));
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), SettingsManager()]),
      builder: (context, _) {
        final isGrid = SettingsManager().resolvedLibraryListStyle.isGrid;

        return PopScope(
          // Back leaves search before it leaves the tab.
          canPop: !_isSearching,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _exitSearch();
          },
          child: Scaffold(
            backgroundColor: context.colors.background,
            appBar: _buildAppBar(context),
            body: ValueListenableBuilder<LibrarySyncStatus>(
              valueListenable: _libraryService.syncStatus,
              builder: (context, status, _) => Actions(
                actions: <Type, Action<Intent>>{
                  SearchIntent: CallbackAction<SearchIntent>(
                    onInvoke: (_) {
                      enterSearchMode();
                      return null;
                    },
                  ),
                  RefreshIntent: CallbackAction<RefreshIntent>(
                    onInvoke: (_) {
                      _session.refresh();
                      return null;
                    },
                  ),
                },
                child: WidgetUtils.responsiveConstraint(
                  _buildContent(status),
                  maxWidth: isGrid ? double.infinity : _maxListWidth,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(LibrarySyncStatus status) {
    return Column(
      children: [
        LibraryStatusBanners(
          status: status,
          isIncomplete: _session.isIncomplete,
          onRetrySync: _session.refresh,
          onDismissError: () => _libraryService.syncStatus.value =
              _libraryService.syncStatus.value.copyWith(clearError: true),
          onImportFullLibrary: _libraryService.importFullLibrary,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: FilterChipsRow(
            filters: _filters,
            onFiltersChanged: updateFilters,
          ),
        ),
        Expanded(
          child: LibraryBody(
            loggedIn: _session.isLoggedIn,
            entriesStream: _session.entriesStream,
            query: _query,
            filters: _filters,
            tabController: _tabController,
            scrollControllers: _scrollControllers,
            onRefresh: _session.refresh,
            onLogin: _login,
            onItemTap: _navigateToSeriesDetail,
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context) {
    return LibraryAppBar(
      isSearching: _isSearching,
      isLandscape: MediaQuery.orientationOf(context) == Orientation.landscape,
      searchFocusNode: _searchFocusNode,
      entriesStream: _session.entriesStream,
      filters: _filters,
      onEnterSearch: enterSearchMode,
      onExitSearch: _exitSearch,
      onQueryChanged: updateQuery,
      onFiltersChanged: updateFilters,
      onResultSelected: handleResultSelected,
      bottom: _buildTabBar(context),
    );
  }

  PreferredSizeWidget _buildTabBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: StreamBuilder<List<LibraryEntry>>(
        stream: _session.entriesStream,
        builder: (context, snapshot) => LibraryTabBar(
          controller: _tabController,
          counts: _tabs.countsFor(snapshot.data ?? const []),
          isLandscape:
              MediaQuery.orientationOf(context) == Orientation.landscape,
        ),
      ),
    );
  }
}
