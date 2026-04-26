import 'package:flutter/material.dart';
import 'dart:math';
import 'package:bakahyou/features/browse/widgets/mb_search_bar.dart';
import 'package:bakahyou/features/browse/widgets/browse_content.dart';
import 'package:bakahyou/features/series/services/series_search_service.dart';
import 'package:bakahyou/features/series/screens/series_detail_screen.dart';
import 'package:bakahyou/features/browse/screens/browse_results_screen.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/features/browse/models/search_filters.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';
import 'package:bakahyou/features/profile/services/profile_auth_service.dart';
import 'package:bakahyou/features/browse/screens/barcode_scanner_screen.dart';
import 'package:bakahyou/features/browse/services/book_lookup_service.dart';
import 'package:bakahyou/features/series/models/autocomplete_series_result.dart';
import 'package:bakahyou/features/series/services/series_id_service.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  // Services & Controllers
  late final SeriesSearchService _searchService;
  late final ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();

  // Search State
  List<Series> _searchResults = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _currentSearchQuery = '';
  int _currentPage = 1;
  bool _hasMore = true;
  SearchFilters _currentFilters = SearchFilters();

  @override
  void initState() {
    super.initState();
    _searchService = getIt<SeriesSearchService>();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _resetSearchState() {
    setState(() {
      _searchResults = [];
      _error = null;
      _currentSearchQuery = '';
      _currentPage = 1;
      _hasMore = true;
      _isLoadingMore = false;
    });
  }

  void _onScroll() {
    final isNearEnd =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent -
            AppConstants.scrollThresholdPx;

    if (isNearEnd &&
        _hasMore &&
        !_isLoadingMore &&
        (_currentSearchQuery.isNotEmpty ||
            _currentFilters.toMap().isNotEmpty)) {
      _loadMoreResults();
    }
  }

  Future<void> _searchSeries() async {
    // If there is no query and no filters, reset
    if (_currentSearchQuery.trim().isEmpty && _currentFilters.toMap().isEmpty) {
      _resetSearchState();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _searchResults = [];
      _currentPage = 1;
      _hasMore = true;
      _isLoadingMore = false;
    });

    await _fetchSearchResults();
  }

  Future<void> _loadMoreResults() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });
    _currentPage++;
    await _fetchSearchResults();
  }

  Future<void> _fetchSearchResults() async {
    try {
      String? userId;
      if (SettingsManager().hideLibrarySeriesInBrowse) {
        final auth = getIt<ProfileAuthService>();
        if (auth.isLoggedIn) {
          final profile = auth.cachedProfile;
          if (profile != null) {
            // exclude_user_library expects a 32-character alphanumeric string.
            // UUIDs from the profile ID might contain hyphens, so we strip them.
            userId = profile.id.replaceAll('-', '');
          }
        }
      }

      final extraParams = <String, dynamic>{
        'page': _currentPage,
        'limit': AppConstants.defaultPageLimit,
        ..._currentFilters.toMap(),
      };

      if (userId != null && userId.isNotEmpty) {
        extraParams['exclude_user_library'] = userId;
      }

      final newResults = await _searchService.searchSeriesByName(
        _currentSearchQuery,
        extraParams: extraParams,
      );

      setState(() {
        _hasMore = newResults.length == AppConstants.defaultPageLimit;
        _isLoading = false;
        _isLoadingMore = false;
        _searchResults.addAll(newResults);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _error = e.toString();
      });
    }
  }

  int _generateRandomSeed() {
    return Random().nextInt(1000000);
  }


  void _navigateToBrowseResults(String header, String sortBy, {String? type}) {
    int? randomSeed;

    if (sortBy == 'random') {
      randomSeed = _generateRandomSeed();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BrowseResultsScreen(
          sortType: header,
          sortBy: sortBy,
          type: type,
          randomSeed: randomSeed,
        ),
      ),
    );
  }

  void _navigateToDetail(Series series) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SeriesDetailScreen(series: series)),
    );
  }

  String _cleanTitle(String title) {
    // Matches common suffixes like "Vol. 1", "Volume 2", "Part 3", "Deluxe Edition", "Omnibus"
    final regex = RegExp(
      r'(?:\s*[,-]?\s*(?:Vol\.|Volume|Part|Book)\s*\d+.*)|(?:\s*(?:Deluxe Edition|Omnibus|Box Set|Manga)\b.*)',
      caseSensitive: false,
    );
    final cleaned = title.replaceAll(regex, '').trim();
    // Remove trailing hyphens or colons
    return cleaned.replaceAll(RegExp(r'[\-:]$'), '').trim();
  }

  Future<void> _handleBarcodeScan() async {
    final isbn = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (isbn != null && isbn.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (!mounted) return;

      try {
        final lookupService = BookLookupService();
        final title = await lookupService.lookupTitleByIsbn(isbn);

        if (title != null && title.isNotEmpty) {
          _searchController.text = title;
          _currentSearchQuery = title;
          await _searchSeries();

          if (!mounted) return;

          if (_searchResults.isNotEmpty) {
            _navigateToDetail(_searchResults.first);
          } else {
            // Fallback: Try stripping volume numbers and edition names
            final cleanedTitle = _cleanTitle(title);
            if (cleanedTitle != title && cleanedTitle.isNotEmpty) {
              _searchController.text = cleanedTitle;
              _currentSearchQuery = cleanedTitle;
              await _searchSeries();

              if (!mounted) return;

              if (_searchResults.isNotEmpty) {
                _navigateToDetail(_searchResults.first);
                return;
              }
            }

             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No series found for "$cleanedTitle" on MangaBaka.')),
            );
          }
        } else {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not find book title for this ISBN.')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error looking up book: $e')),
        );
      }
    }
  }

  Future<void> _handleResultSelected(AutocompleteSeriesResult result) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fullSeries = await SeriesService.fetchSeries(result.id.toString());
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _navigateToDetail(fullSeries);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load series details: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), ThemeManager()]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppConstants.primaryBackground,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: AppConstants.horizontalPadding,
                right: AppConstants.horizontalPadding,
                top: AppConstants.verticalPadding,
                bottom: 8.0,
              ),
              child: Stack(
                children: [
                  // Main content sits below, with top padding for the search bar
                  Padding(
                    padding: const EdgeInsets.only(top: 64),
                    child: Column(
                      children: [
                        BrowseContent(
                          searchResults: _searchResults,
                          isLoading: _isLoading,
                          isLoadingMore: _isLoadingMore,
                          error: _error,
                          scrollController: _scrollController,
                          onRetry: _searchSeries,
                          onNavigateToDetail: _navigateToDetail,
                          onNavigateToResults: _navigateToBrowseResults,
                        ),
                      ],
                    ),
                  ),
                  // Search bar + suggestions float on top
                  MBSearchBar(
                    controller: _searchController,
                    initialFilters: _currentFilters,
                    onScanTap: _handleBarcodeScan,
                    onResultSelected: _handleResultSelected,
                    onChanged: (text) {
                      _currentSearchQuery = text;
                      if (text.isEmpty && _currentFilters.toMap().isEmpty) {
                        _resetSearchState();
                      }
                    },
                    onSubmitted: (text) {
                      _currentSearchQuery = text;
                      _searchSeries();
                    },
                    onFilterApplied: (filters) {
                      setState(() {
                        _currentFilters = filters;
                      });
                      _searchSeries();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
