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

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with TickerProviderStateMixin {
  late final ProfileAuthService _auth;
  late final LibraryService _libraryService;
  late TabController _tabController;
  late final Map<String, ScrollController> _scrollControllers;

  bool _loggedIn = false;
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
    _auth = ProfileAuthService();
    _libraryService = LibraryService(auth: _auth);
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
    _scrollControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final hasSession = await _auth.hasSession();
    if (!mounted) return;

    setState(() => _loggedIn = hasSession);

    if (hasSession) {
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
      tabs: LibraryScreenConstants.tabs.map((t) => Tab(text: t.label)).toList(),
      indicatorColor: LibraryScreenConstants.accentColor,
      labelColor: LibraryScreenConstants.accentColor,
      unselectedLabelColor: Colors.white,
    );
  }

  Widget _buildBody() {
    if (!_loggedIn) return _buildLoginPrompt();
    if (_entriesStream == null)
      return const Center(child: CircularProgressIndicator());

    return StreamBuilder<List<LibraryEntry>>(
      stream: _entriesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('Your library is empty. Start by adding some series!'),
          );
        }

        final allEntries = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: LibraryScreenConstants.accentColor,
          child: TabBarView(
            controller: _tabController,
            children: LibraryScreenConstants.tabs.map((tab) {
              final filterHelper = LibraryFilterHelper(
                allEntries: allEntries,
                query: _query,
              );
              final items = filterHelper.getByTab(tab.key);
              return _buildTabContent(items, tab.key);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'You are not logged in.',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loginAndReload,
            style: ElevatedButton.styleFrom(
              backgroundColor: LibraryScreenConstants.accentColor,
            ),
            child: const Text('Login with MangaBaka'),
          ),
        ],
      ),
    );
  }

    Widget _buildTabContent(List<LibraryEntry> items, String tabKey) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No entries in this list.',
          style: TextStyle(color: Colors.grey[400]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: LibraryScreenConstants.accentColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView.builder(
          controller: _scrollControllers[tabKey],
          itemCount: items.length,
          itemBuilder: (context, index) {
            final entry = items[index];
            return GestureDetector(
              onTap: () => _navigateToSeriesDetail(entry.series),
              child: EntryListItem(series: entry.series),
            );
          },
        ),
      ),
    );
  }

  void _navigateToSeriesDetail(api.Series series) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SeriesDetailScreen(series: series),
      ),
    );
  }
}
