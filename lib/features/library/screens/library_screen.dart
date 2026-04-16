import 'package:flutter/material.dart';
import 'package:bakahyou/features/browse/widgets/mb_search_bar.dart';
import 'package:bakahyou/features/library/models/library_entry.dart';
import 'package:bakahyou/features/library/screens/library_filter_helper.dart';
import 'package:bakahyou/features/library/screens/library_screen_constants.dart';
import 'package:bakahyou/features/library/services/library_service.dart';
import 'package:bakahyou/features/profile/services/profile_auth_service.dart';
import 'package:bakahyou/features/series/screens/series_detail_screen.dart';
import 'package:bakahyou/features/series/widgets/entry_list_item.dart';

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

  // State variables
  bool _loading = true;
  bool _loggedIn = false;
  String _query = '';
  String? _error;
  List<LibraryEntry> _allEntries = const [];

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
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    _setLoading(true);

    try {
      final hasSession = await _auth.hasSession();
      if (!hasSession) {
        _setLoggedIn(false);
        return;
      }

      _setLoggedIn(true);
      await _loadLibraryEntries();
    } catch (e) {
      _setError('Failed to initialize library: $e');
    }
  }

  Future<void> _loadLibraryEntries() async {
    _setLoading(true);

    try {
      var entries = await _libraryService.getEntriesFromDb();

      if (entries.isEmpty) {
        entries = await _libraryService.fetchAllEntriesAndSave();
      }

      if (!mounted) return;
      _setEntries(entries);
    } catch (e) {
      _setError('Failed to load library entries: $e');
    }
  }

  Future<void> _loginAndReload() async {
    _setLoading(true);

    try {
      await _auth.login();
      _setLoggedIn(true);
      await _loadLibraryEntries();
    } catch (e) {
      _setError('Failed to login: $e');
    }
  }

  // State setters to reduce boilerplate
  void _setLoading(bool value) => _updateState(() => _loading = value);
  void _setLoggedIn(bool value) => _updateState(() => _loggedIn = value);
  void _setError(String? value) => _updateState(() => _error = value);
  void _setEntries(List<LibraryEntry> entries) {
    _updateState(() {
      _allEntries = entries;
      _loading = false;
      _error = null;
    });
  }

  void _updateState(VoidCallback callback) {
    if (!mounted) return;
    setState(callback);
  }

  // UI Building Methods
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
      title: MBSearchBar(
        onChanged: (value) => _updateState(() => _query = value),
      ),
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
    if (_loading) return _buildLoadingIndicator();
    if (_error != null) return _buildErrorWidget();
    return _buildTabBarView();
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

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadLibraryEntries,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: LibraryScreenConstants.tabs
          .map((tab) => _buildTabContent(tab))
          .toList(),
    );
  }

  Widget _buildTabContent(LibraryTabDefinition tab) {
    final filterHelper = LibraryFilterHelper(
      allEntries: _allEntries,
      query: _query,
    );
    final items = filterHelper.getByTab(tab.key);

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No entries in this list.',
          style: TextStyle(color: Colors.grey[400]),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollControllers[tab.key],
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

  void _navigateToSeriesDetail(dynamic series) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SeriesDetailScreen(series: series),
      ),
    );
  }
}
