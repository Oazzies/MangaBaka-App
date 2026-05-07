import 'package:bakahyou/features/series/services/series_id_service.dart';
import 'package:flutter/material.dart';
import 'package:bakahyou/features/browse/widgets/mb_search_bar.dart';
import 'package:bakahyou/features/library/models/library_entry.dart';
import 'package:bakahyou/features/library/models/library_sync_status.dart';
import 'package:bakahyou/features/library/screens/library_filter_helper.dart';
import 'package:bakahyou/features/library/screens/library_screen_constants.dart';
import 'package:bakahyou/features/library/services/library_service.dart';
import 'package:bakahyou/features/profile/services/profile_auth_service.dart';
import 'package:bakahyou/features/series/screens/series_detail_screen.dart';
import 'package:bakahyou/features/series/widgets/entry_list_item.dart';
import 'package:bakahyou/features/series/models/series.dart' as api;
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';
import 'package:bakahyou/utils/settings/settings_enums.dart';
import 'package:bakahyou/utils/exceptions/app_exceptions.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:bakahyou/features/profile/widgets/mb_login_prompt.dart';
import 'package:bakahyou/features/browse/models/search_filters.dart';
import 'package:bakahyou/features/series/widgets/series_list_skeleton.dart';
import 'package:bakahyou/utils/transitions/app_transitions.dart';


class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with TickerProviderStateMixin {
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
    _scrollControllers = {
      for (final tab in LibraryScreenConstants.tabs)
        tab.key: ScrollController(),
    };
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthStateChanged);
    _tabController.dispose();
    for (var c in _scrollControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _bootstrap() {
    _loggedIn = _auth.isLoggedIn;

    if (_loggedIn) {
      _setupStreamAndSync();
    }
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
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
    setState(() {
      _entriesStream = _libraryService.watchEntriesFromDb();
    });
    // Full import only on first load; recents sync on subsequent ones.
    _libraryService.performInitialSyncIfNeeded().then((_) async {
      final incomplete = await _libraryService.isLibraryIncomplete();
      if (mounted) setState(() => _isLibraryIncomplete = incomplete);
    }).catchError((_) {});
  }

  Future<void> _loginAndReload() async {
    try {
      await _auth.login();
      if (!mounted) return;
      setState(() => _loggedIn = true);
      _setupStreamAndSync();
    } catch (e) {
      if (e is AuthCancelledException) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Please try again.')),
      );
    }
  }

  Future<void> _onRefresh() async {
    await _libraryService.syncLibrary();
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
                  if (status.isServerDown) _buildServerDownWarning(),
                  if (!status.isServerDown && status.error != null)
                    _buildSyncErrorWarning(status.error!),
                  if (_isLibraryIncomplete) _buildIncompleteWarning(),
                  Expanded(child: _buildBody()),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildIncompleteWarning() {
    final isDark = ThemeManager().isDarkMode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppConstants.warningColor.withValues(alpha: isDark ? 0.12 : 0.18),
        border: Border(
          bottom: BorderSide(color: AppConstants.warningColor.withValues(alpha: 0.25)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppConstants.warningColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your library exceeds 1,000,000 entries. Only the first 1,000,000 could be imported.',
              style: TextStyle(
                color: AppConstants.warningColor, 
                fontSize: 12,
                fontWeight: isDark ? FontWeight.normal : FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _libraryService.importFullLibrary(),
            child: Text('Re-import', style: TextStyle(color: AppConstants.warningColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildServerDownWarning() {
    final isDark = ThemeManager().isDarkMode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppConstants.errorColor.withValues(alpha: isDark ? 0.12 : 0.18),
        border: Border(
          bottom: BorderSide(color: AppConstants.errorColor.withValues(alpha: 0.25)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: AppConstants.errorColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'MangaBaka is currently unreachable. Using local library.',
              style: TextStyle(
                color: AppConstants.errorColor, 
                fontSize: 12,
                fontWeight: isDark ? FontWeight.normal : FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _onRefresh(),
            child: Text('Retry', style: TextStyle(color: AppConstants.errorColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncErrorWarning(String message) {
    final isDark = ThemeManager().isDarkMode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppConstants.errorColor.withValues(alpha: isDark ? 0.12 : 0.18),
        border: Border(
          bottom: BorderSide(color: AppConstants.errorColor.withValues(alpha: 0.25)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppConstants.errorColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sync failed: $message',
              style: TextStyle(
                color: AppConstants.errorColor, 
                fontSize: 12,
                fontWeight: isDark ? FontWeight.normal : FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppConstants.errorColor, size: 16),
            onPressed: () => _libraryService.syncStatus.value = 
                _libraryService.syncStatus.value.copyWith(clearError: true),
          ),
        ],
      ),
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

  Widget _buildBody() {
    final l10n = LocalizationService();
    if (!_loggedIn) return _buildLoginPrompt();
    if (_entriesStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<LibraryEntry>>(
      stream: _entriesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          final settings = SettingsManager();
          final isGrid = settings.separateListStyles
              ? settings.libraryListStyle.isGrid
              : settings.currentListStyle.isGrid;
          return SeriesListSkeleton(isGrid: isGrid);
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              '${l10n.translate('failed_to_load')}: ${snapshot.error}',
              style: TextStyle(color: LibraryScreenConstants.errorColor),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(l10n.translate('empty_library')));
        }

        return ListenableBuilder(
          listenable: SettingsManager(),
          builder: (context, _) {
            final filterHelper = LibraryFilterHelper(
              allEntries: snapshot.data!,
              query: _query,
              filters: _filters,
              contentPreferences: SettingsManager().contentPreferences,
            );

            return TabBarView(
              controller: _tabController,
              children: LibraryScreenConstants.tabs.map((tab) {
                final items = filterHelper.getByTab(tab.key);
                return _buildTabContent(items, tab.key);
              }).toList(),
            );
          },
        );
      },
    );
  }


  Widget _buildLoginPrompt() {
    final l10n = LocalizationService();
    return MBLoginPrompt(
      onLogin: _loginAndReload,
      message: l10n.translate('login_prompt_library'),
    );
  }

  Widget _buildTabContent(List<LibraryEntry> items, String tabKey) {
    if (items.isEmpty) {
      final l10n = LocalizationService();
      return Center(
        child: Text(
          l10n.translate('no_results'),
          style: TextStyle(color: AppConstants.textMutedColor),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListenableBuilder(
        listenable: SettingsManager(),
        builder: (context, _) {
          final settings = SettingsManager();
          final isGrid = settings.separateListStyles
              ? settings.libraryListStyle.isGrid
              : settings.currentListStyle.isGrid;

          if (isGrid) {
            return GridView.builder(
              controller: _scrollControllers[tabKey],
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                childAspectRatio: 0.65,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final entry = items[index];
                return GestureDetector(
                  onTap: () => _navigateToSeriesDetail(entry.series),
                  child: EntryListItem(series: entry.series, isLibrary: true),
                );
              },
            );
          }

          return ListView.builder(
            controller: _scrollControllers[tabKey],
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final entry = items[index];
              return GestureDetector(
                onTap: () => _navigateToSeriesDetail(entry.series),
                child: EntryListItem(series: entry.series, isLibrary: true),
              );
            },
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
