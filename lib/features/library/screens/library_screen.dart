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
  Stream<List<LibraryEntry>>? _entriesStream;

  @override
  void initState() {
    super.initState();
    _initializeServices();
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
      // Handle login error
    }
  }

  Future<void> _onRefresh() async {
    await _libraryService.syncLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LibraryScreenConstants.backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: LibraryScreenConstants.backgroundColor,
      title: MBSearchBar(onChanged: (value) => setState(() => _query = value)),
      bottom: _buildTabBar(),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      tabs: LibraryScreenConstants.tabs
          .map((tab) => Tab(text: tab.label))
          .toList(),
    );
  }

  Widget _buildBody() {
    if (!_loggedIn) return _buildLoginPrompt();
    if (_entriesStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<LibraryEntry>>(
      stream: _entriesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: LibraryScreenConstants.errorColor),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Your library is empty.'));
        }

        return ListenableBuilder(
          listenable: SettingsManager(),
          builder: (context, _) {
            final filterHelper = LibraryFilterHelper(
              allEntries: snapshot.data!,
              query: _query,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Login with MangaBaka to see your Library',
            style: TextStyle(fontSize: 18, color: AppConstants.textColor),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loginAndReload,
            style: ElevatedButton.styleFrom(
              backgroundColor: LibraryScreenConstants.accentColor,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: Text(
              'Login with MangaBaka',
              style: TextStyle(fontSize: 16, color: AppConstants.textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(List<LibraryEntry> items, String tabKey) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No entries in this category.',
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
                child: EntryListItem(series: entry.series),
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
              child: EntryListItem(series: entry.series),
            );
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
