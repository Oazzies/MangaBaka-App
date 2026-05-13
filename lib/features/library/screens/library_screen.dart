import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/library/widgets/library_search_bar.dart';
import 'package:mangabaka_app/utils/app_shortcuts.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/models/library_sync_status.dart';
import 'package:mangabaka_app/features/library/screens/library_screen_constants.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/models/series.dart' as api;
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/theme/theme_manager.dart';
import 'package:mangabaka_app/utils/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/utils/transitions/app_transitions.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';
import 'package:mangabaka_app/features/library/widgets/library_status_banner.dart';
import 'package:mangabaka_app/features/library/widgets/library_body.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/utils/settings/settings_enums.dart';
import 'package:mangabaka_app/features/profile/screens/settings_screen.dart';
import 'package:mangabaka_app/utils/number_utils.dart';
import 'package:mangabaka_app/features/browse/widgets/filter_chips_row.dart';
import 'package:mangabaka_app/features/library/screens/library_filter_helper.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/features/browse/utils/browse_helpers.dart';


class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with TickerProviderStateMixin {
  static final _logger = LoggingService.logger;
  late final ProfileAuthService _auth;
  late final LibraryService _libraryService;
  late TabController _tabController;
  late final Map<String, ScrollController> _scrollControllers;
  final FocusNode _searchFocusNode = FocusNode();

  late bool _loggedIn;
  String _query = '';
  SearchFilters _filters = SearchFilters();
  Stream<List<LibraryEntry>>? _entriesStream;
  StreamSubscription<List<LibraryEntry>>? _entriesSubscription;
  List<LibraryEntry> _lastEntries = [];
  bool _isLibraryIncomplete = false;

  @override
  void initState() {
    super.initState();
    _logger.info('Library screen initialized');
    _initializeServices();
    _auth.addListener(_onAuthStateChanged);
    _initializeControllers();
    _bootstrap();
  }

  void _initializeServices() {
    _auth = getIt<ProfileAuthService>();
    _libraryService = getIt<LibraryService>();
  }

  void _initializeControllers() {
    _tabController = TabController(
      length: LibraryScreenConstants.tabs.length,
      vsync: this,
    );
    _tabController.addListener(_handleTabSelection);
    _scrollControllers = {
      for (final tab in LibraryScreenConstants.tabs)
        tab.key: ScrollController(),
    };
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _logger.info('Library tab switched to: ${_tabController.index}');
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthStateChanged);
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    for (var c in _scrollControllers.values) {
      c.dispose();
    }
    _searchFocusNode.dispose();
    _entriesSubscription?.cancel();
    super.dispose();
  }

  void _bootstrap() {
    _loggedIn = _auth.isLoggedIn;
    _logger.fine('Library bootstrap: loggedIn=$_loggedIn');

    if (_loggedIn) {
      _setupStreamAndSync();
    }
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    _logger.info('Auth state changed in LibraryScreen. LoggedIn: ${_auth.isLoggedIn}');
    setState(() {
      _loggedIn = _auth.isLoggedIn;
      if (!_loggedIn) {
        _entriesStream = null;
        _entriesSubscription?.cancel();
        _entriesSubscription = null;
      } else {
        _setupStreamAndSync();
      }
    });
  }

  void _handleResultSelected(AutocompleteSeriesResult result) {
    _logger.info('Library autocomplete result selected: ${result.title}');
    final series = BrowseHelpers.convertAutocompleteToSeries(result);
    _navigateToSeriesDetail(series);
  }

  void _onEntriesUpdate(List<LibraryEntry> entries) {
    if (!mounted) return;
    _lastEntries = entries;
    _performAutoTabSwitching();
  }

  void _performAutoTabSwitching() {
    if (!mounted || (_query.isEmpty && _filters.isEmpty) || _tabController.indexIsChanging) return;

    final currentTabKey = LibraryScreenConstants.tabs[_tabController.index].key;
    
    final filterHelper = LibraryFilterHelper(
      allEntries: _lastEntries,
      query: _query,
      contentPreferences: SettingsManager().contentPreferences,
      filters: _filters,
    );
    
    final resultsInCurrentTab = filterHelper.getByTab(currentTabKey);
    
    if (resultsInCurrentTab.isEmpty) {
      _logger.info('Current tab ($currentTabKey) is empty while searching. Looking for other tabs...');
      // Try to find first tab with results
      for (int i = 0; i < LibraryScreenConstants.tabs.length; i++) {
        final tabKey = LibraryScreenConstants.tabs[i].key;
        if (filterHelper.getByTab(tabKey).isNotEmpty) {
          _logger.info('Auto-switching to tab: $tabKey (index $i)');
          _tabController.animateTo(i);
          break;
        }
      }
    }
  }

  void _setupStreamAndSync() {
    _logger.info('Setting up library entries stream and sync tasks');
    setState(() {
      _entriesStream = _libraryService.watchEntriesFromDb();
      _entriesSubscription?.cancel();
      _entriesSubscription = _entriesStream?.listen(_onEntriesUpdate);
    });
    // Full import only on first load; recents sync on subsequent ones.
    _libraryService.performInitialSyncIfNeeded().then((_) async {
      _logger.info('Initial sync task completed');
      final incomplete = await _libraryService.isLibraryIncomplete();
      if (mounted) setState(() => _isLibraryIncomplete = incomplete);
    }).catchError((e) {
      _logger.severe('Initial sync task failed: $e');
    });
  }

  Future<void> _loginAndReload() async {
    _logger.info('User attempting login from library screen');
    try {
      await _auth.login();
      if (!mounted) return;
      _logger.info('Login successful in library screen');
      setState(() => _loggedIn = true);
      _setupStreamAndSync();
    } catch (e) {
      if (e is AuthCancelledException) {
        _logger.info('Login cancelled by user in library screen');
        return;
      }
      _logger.severe('Login failed in library screen: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService().translate('login_failed_retry'))),
      );
    }
  }

  Future<void> _onRefresh() async {
    _logger.info('User triggered manual library refresh from screen');
    _libraryService.syncLibrary().catchError((e) {
      _logger.severe('Manual refresh failed: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        LocalizationService(),
        ThemeManager(),
        SettingsManager(),
      ]),
      builder: (context, _) {
        final settings = SettingsManager();
        final isGrid = settings.separateListStyles
            ? settings.libraryListStyle.isGrid
            : settings.currentListStyle.isGrid;

        return Scaffold(
          backgroundColor: LibraryScreenConstants.backgroundColor,
          appBar: _buildAppBar(),
          body: ValueListenableBuilder<LibrarySyncStatus>(
            valueListenable: _libraryService.syncStatus,
            builder: (context, status, _) {
              final content = Column(
                children: [
                  if (status.isServerDown) 
                    LibraryStatusBanner(
                      message: LocalizationService().translate('server_unreachable_warning'),
                      icon: Icons.cloud_off_rounded,
                      color: AppConstants.errorColor,
                      action: TextButton(
                        onPressed: _onRefresh,
                        child: Text(
                          LocalizationService().translate('retry'),
                          style: TextStyle(color: AppConstants.errorColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (!status.isServerDown && status.error != null)
                    LibraryStatusBanner(
                      message: LocalizationService().translate('sync_failed').replaceAll('{message}', status.error!),
                      icon: Icons.error_outline_rounded,
                      color: AppConstants.errorColor,
                      onClose: () => _libraryService.syncStatus.value = 
                          _libraryService.syncStatus.value.copyWith(clearError: true),
                    ),
                  if (_isLibraryIncomplete)
                    LibraryStatusBanner(
                      message: LocalizationService().translate('library_limit_warning'),
                      icon: Icons.warning_amber_rounded,
                      color: AppConstants.warningColor,
                      action: TextButton(
                        onPressed: () => _libraryService.importFullLibrary(),
                        child: Text(
                          LocalizationService().translate('re_import'),
                          style: TextStyle(color: AppConstants.warningColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: FilterChipsRow(
                      filters: _filters,
                      onFiltersChanged: (filters) {
                        setState(() => _filters = filters);
                        _performAutoTabSwitching();
                      },
                    ),
                  ),
                  Expanded(
                    child: LibraryBody(
                      loggedIn: _loggedIn,
                      entriesStream: _entriesStream,
                      query: _query,
                      filters: _filters,
                      tabController: _tabController,
                      scrollControllers: _scrollControllers,
                      onRefresh: _onRefresh,
                      onLogin: _loginAndReload,
                      onItemTap: _navigateToSeriesDetail,
                    ),
                  ),
                ],
              );

              return Actions(
                actions: <Type, Action<Intent>>{
                  SearchIntent: CallbackAction<SearchIntent>(
                    onInvoke: (intent) {
                      _searchFocusNode.requestFocus();
                      return null;
                    },
                  ),
                  RefreshIntent: CallbackAction<RefreshIntent>(
                    onInvoke: (intent) {
                      _onRefresh();
                      return null;
                    },
                  ),
                },
                child: WidgetUtils.responsiveConstraint(
                  content,
                  maxWidth: isGrid ? 1200 : 800,
                ),
              );
            },
          ),
        );
      },
    );
  }


  PreferredSizeWidget _buildAppBar() {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final settings = SettingsManager();
    final l10n = LocalizationService();

    final currentStyle = settings.separateListStyles
        ? settings.libraryListStyle
        : settings.currentListStyle;

    return AppBar(
      backgroundColor: LibraryScreenConstants.backgroundColor,
      elevation: 0,
      centerTitle: isLandscape,
      title: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: LibrarySearchBar(
          focusNode: _searchFocusNode,
          entriesStream: _entriesStream,
          onResultSelected: _handleResultSelected,
          onChanged: (value) {
            setState(() => _query = value);
            _performAutoTabSwitching();
          },
          initialFilters: _filters,
          onFilterApplied: (filters) {
            setState(() => _filters = filters);
            _performAutoTabSwitching();
          },
        ),
      ),
      actions: isLandscape
          ? [
              WidgetUtils.tooltip(
                message: l10n.translate('toggle_layout'),
                child: IconButton(
                  icon: Icon(currentStyle.icon, color: AppConstants.textColor),
                  onPressed: () {
                    final nextStyle = currentStyle.next;
                    if (settings.separateListStyles) {
                      settings.setLibraryListStyle(nextStyle);
                    } else {
                      settings.setListStyle(nextStyle);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
            ]
          : null,
      bottom: _buildTabBar(isLandscape),
    );
  }

  PreferredSizeWidget _buildTabBar(bool isLandscape) {
    final l10n = LocalizationService();
    return PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: StreamBuilder<List<LibraryEntry>>(
        stream: _entriesStream,
        builder: (context, snapshot) {
          final entries = snapshot.data ?? [];
          
          final settings = SettingsManager();
          final filterHelper = LibraryFilterHelper(
            allEntries: entries,
            query: _query,
            contentPreferences: settings.contentPreferences,
            filters: _filters,
          );
          final filteredEntries = filterHelper.getFilteredAndSorted();

          final counts = <String, int>{};
          for (final entry in filteredEntries) {
            counts[entry.state] = (counts[entry.state] ?? 0) + 1;
          }

          return TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: isLandscape ? TabAlignment.center : TabAlignment.start,
            tabs: LibraryScreenConstants.tabs.map((tab) {
              final count = counts[tab.key] ?? 0;
              final label = l10n.translate(tab.key);
              
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        NumberUtils.formatCount(count),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _navigateToSeriesDetail(api.Series series) {
    Navigator.of(context).push(
      AppTransitions.slideUp(SeriesDetailScreen(series: series)),
    );
  }
}
