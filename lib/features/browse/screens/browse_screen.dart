import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/features/browse/controllers/browse_controller.dart';
import 'package:mangabaka_app/features/browse/models/browse_type.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/screens/browse_results_screen.dart';
import 'package:mangabaka_app/features/browse/screens/mix_screen.dart';
import 'package:mangabaka_app/features/home/screens/discovery_queue_screen.dart';
import 'package:mangabaka_app/features/browse/services/camera_scan_launcher.dart';
import 'package:mangabaka_app/features/browse/utils/browse_helpers.dart';
import 'package:mangabaka_app/features/browse/widgets/browse_app_bar.dart';
import 'package:mangabaka_app/features/browse/widgets/browse_type_tabs.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/filter_chips_row.dart';
import 'package:mangabaka_app/features/browse/widgets/results/browse_content.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/shared/widgets/app_shortcuts.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Search and discovery. Owns the [BrowseController] and the search-mode
/// state; the results themselves live in [BrowseContent].
class BrowseScreen extends StatefulWidget {
  static final GlobalKey<BrowseScreenState> browseScreenKey =
      GlobalKey<BrowseScreenState>();

  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => BrowseScreenState();
}

class BrowseScreenState extends State<BrowseScreen> {
  static final _logger = LoggingService.logger;

  late final BrowseController _controller;
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  // ─── Public surface ──────────────────────────────────────────────────────

  FocusNode get searchFocusNode => _searchFocusNode;
  BrowseController get controller => _controller;

  void enterSearchMode() {
    setState(() => _isSearching = true);
    _searchFocusNode.requestFocus();
  }

  Future<void> handleBarcodeScan() async {
    final isbn = await CameraScanLauncher.scan(context);
    if (isbn == null || !mounted) return;
    await _resolveScannedIsbn(isbn);
  }

  void handleResultSelected(AutocompleteSeriesResult result) {
    _logger.info('Autocomplete result selected: ${result.title}');
    _navigateToDetail(BrowseHelpers.convertAutocompleteToSeries(result));
  }

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _controller = BrowseController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ─── Search ──────────────────────────────────────────────────────────────

  /// Leaves search mode and clears everything it set. Reached from the search
  /// bar's back button and from a system back gesture, which must agree.
  void _exitSearch() {
    setState(() => _isSearching = false);
    _controller.searchController.clear();
    _controller.updateSearchQuery('');
    _controller.updateFilters(SearchFilters());
    _controller.resetSearchState();
  }

  /// Runs a scanned ISBN through the controller and acts on the outcome:
  /// straight to the series when one was found, a snack bar when not.
  Future<void> _resolveScannedIsbn(String isbn) async {
    final errorKey = await _controller.handleBarcodeScan(isbn);
    if (!mounted) return;

    if (errorKey == null) {
      if (_controller.searchResults.isEmpty) return;
      _logger.info(
        'Successfully handled barcode scan, navigating to first result',
      );
      _navigateToDetail(_controller.searchResults.first);
      return;
    }

    _logger.warning('Barcode scan handling failed with error key: $errorKey');
    var message = LocalizationService().translate(errorKey);
    // This one message names the title that was searched for.
    if (errorKey == 'no_series_found_for') {
      message = message.replaceAll(
        '{title}',
        _controller.searchController.text,
      );
    }
    AppSnackBar.show(context, message, isError: true);
  }

  // ─── Navigation ──────────────────────────────────────────────────────────

  void _navigateToBrowseResults(
    String header,
    String sortBy, {
    String? type,
    String? staff,
    String? publisher,
  }) {
    _logger.info(
      'Navigating to BrowseResults: header=$header, sortBy=$sortBy, '
      'type=$type, staff=$staff, publisher=$publisher',
    );
    Navigator.push(
      context,
      AppTransitions.slideRight(
        BrowseResultsScreen(
          sortType: header,
          sortBy: sortBy,
          type: type,
          staff: staff,
          publisher: publisher,
          // A random sort needs a seed fixed up front, so paging through the
          // results does not reshuffle them between pages.
          randomSeed: sortBy == 'random'
              ? BrowseController.generateRandomSeed()
              : null,
        ),
      ),
    );
  }

  void _navigateToDetail(Series series) {
    _logger.info(
      'Navigating to SeriesDetail: ${series.title} (ID: ${series.id})',
    );
    Navigator.push(
      context,
      AppTransitions.slideUp(SeriesDetailScreen(series: series)),
    );
  }

  void _navigateToMix() {
    _logger.info('Navigating to MixScreen');
    Navigator.push(context, AppTransitions.slideRight(const MixScreen()));
  }

  void _navigateToDiscoveryQueue() {
    _logger.info('Navigating to DiscoveryQueueScreen');
    Navigator.push(
      context,
      AppTransitions.slideRight(const DiscoveryQueueScreen()),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), _controller]),
      builder: (context, _) {
        return Actions(
          actions: <Type, Action<Intent>>{
            SearchIntent: CallbackAction<SearchIntent>(
              onInvoke: (_) {
                enterSearchMode();
                return null;
              },
            ),
            RefreshIntent: CallbackAction<RefreshIntent>(
              onInvoke: (_) {
                _controller.searchSeries();
                return null;
              },
            ),
          },
          child: PopScope(
            canPop: !_isSearching,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              _exitSearch();
            },
            child: Scaffold(
              backgroundColor: context.colors.background,
              appBar: BrowseAppBar(
                isSearching: _isSearching,
                controller: _controller,
                searchFocusNode: _searchFocusNode,
                onEnterSearch: enterSearchMode,
                onExitSearch: _exitSearch,
                onScanTap: handleBarcodeScan,
                onResultSelected: handleResultSelected,
              ),
              body: NotificationListener<ScrollMetricsNotification>(
                // A change in scroll extent — results arriving, or the window
                // resizing — can leave the list short enough that no scroll
                // event will ever fire to request the next page.
                onNotification: (_) {
                  _controller.checkScroll();
                  return false;
                },
                child: WidgetUtils.responsiveConstraint(_buildBody()),
              ),
              floatingActionButton: _buildBackToTop(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: EdgeInsets.only(
        left: AppConstants.horizontalPadding,
        right: AppConstants.horizontalPadding,
        top: 8.0,
        bottom: 8.0,
      ),
      child: Column(
        children: [
          // The type tabs are hidden while filters are set: filters only apply
          // to series, so the other tabs have nothing to offer.
          if (_controller.isSearchMode && _controller.currentFilters.isEmpty)
            BrowseTypeTabs(
              selectedType: _controller.currentType,
              onTypeChanged: _controller.setType,
            ),
          if (_controller.currentType == BrowseType.series)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: FilterChipsRow(
                filters: _controller.currentFilters,
                onFiltersChanged: _controller.updateFilters,
              ),
            ),
          if (_controller.isSearchMode && _controller.totalResults > 0)
            BrowseResultCount(
              total: _controller.totalResults,
              isCapped: _controller.isTotalCapped,
              typeLabel: LocalizationService().translate(
                _controller.currentType.name,
              ),
            ),
          BrowseContent(
            searchResults: _controller.searchResults,
            browseType: _controller.currentType,
            isLoading: _controller.isLoading,
            isLoadingMore: _controller.isLoadingMore,
            scrollController: _controller.scrollController,
            error: _controller.error,
            onRetry: _controller.searchSeries,
            onNavigateToDetail: _navigateToDetail,
            onNavigateToResults: _navigateToBrowseResults,
            onNavigateToMix: _navigateToMix,
            onNavigateToDiscoveryQueue: _navigateToDiscoveryQueue,
          ),
        ],
      ),
    );
  }

  Widget? _buildBackToTop() {
    if (!_controller.showBackToTop) return null;
    return WidgetUtils.tooltip(
      message: LocalizationService().translate('back_to_top'),
      child: FloatingActionButton(
        onPressed: _controller.scrollToTop,
        backgroundColor: context.colors.accent,
        child: Icon(Icons.arrow_upward, color: context.colors.background),
      ),
    );
  }
}
