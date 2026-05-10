import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/browse/widgets/mb_search_bar.dart';
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
import 'package:mangabaka_app/features/library/widgets/library_status_banner.dart';
import 'package:mangabaka_app/features/library/widgets/library_body.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';

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

  late bool _loggedIn;
  String _query = '';
  SearchFilters _filters = SearchFilters();
  Stream<List<LibraryEntry>>? _entriesStream;
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
      } else {
        _setupStreamAndSync();
      }
    });
  }

  void _setupStreamAndSync() {
    _logger.info('Setting up library entries stream and sync tasks');
    setState(() {
      _entriesStream = _libraryService.watchEntriesFromDb();
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
    // We don't await here so the RefreshIndicator spinner disappears immediately.
    // The global SyncProgressOverlay handles the visual progress.
    _libraryService.syncLibrary().catchError((e) {
      _logger.severe('Manual refresh failed: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), ThemeManager()]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: LibraryScreenConstants.backgroundColor,
          appBar: _buildAppBar(),
          body: ValueListenableBuilder<LibrarySyncStatus>(
            valueListenable: _libraryService.syncStatus,
            builder: (context, status, _) {
              return Column(
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
            },
          ),
        );
      },
    );
  }


  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: LibraryScreenConstants.backgroundColor,
      title: MBSearchBar(
        onChanged: (value) => setState(() => _query = value),
        initialFilters: _filters,
        onFilterApplied: (filters) => setState(() => _filters = filters),
      ),
      bottom: _buildTabBar(),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    final l10n = LocalizationService();
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      tabs: LibraryScreenConstants.tabs
          .map((tab) => Tab(text: l10n.translate(tab.key)))
          .toList(),
    );
  }

  void _navigateToSeriesDetail(api.Series series) {
    Navigator.of(context).push(
      AppTransitions.slideUp(SeriesDetailScreen(series: series)),
    );
  }
}
