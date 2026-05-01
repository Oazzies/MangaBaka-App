import 'package:bakahyou/features/series/services/series_id_service.dart';
import 'package:flutter/material.dart';
import 'package:bakahyou/features/browse/widgets/mb_search_bar.dart';
import 'package:bakahyou/features/library/models/library_entry.dart';
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
    // Only sync if it's the first time; otherwise use cached data
    _libraryService.performInitialSyncIfNeeded();
  }

  Future<void> _loginAndReload() async {
    try {
      await _auth.login();
      if (!mounted) return;
      setState(() => _loggedIn = true);
      _setupStreamAndSync();
    } catch (e) {
      if (e is AuthCancelledException) return;
      // Handle login error
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
          body: _buildBody(),
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

  Widget _buildBody() {
    final l10n = LocalizationService();
    if (!_loggedIn) return _buildLoginPrompt();
    if (_entriesStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<LibraryEntry>>(
      stream: _entriesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
      child: () {
        final isGrid = SettingsManager().currentListStyle == AppListStyle.grid;

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
              )
                  .animate(delay: Duration(milliseconds: 50 * index))
                  .fadeIn(duration: const Duration(milliseconds: 300))
                  .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.easeOutCubic);
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
            )
                .animate(delay: Duration(milliseconds: 50 * index))
                .fadeIn(duration: const Duration(milliseconds: 300))
                .slideX(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
          },
        );
      }(),
    );
  }

  Future<void> _navigateToSeriesDetail(api.Series series) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final fullSeries = await SeriesService.fetchSeries(series.id);
      if (!mounted) return;

      Navigator.of(context).pop();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SeriesDetailScreen(series: fullSeries),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load details: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }
}
