import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/shared/widgets/app_shortcuts.dart';
import 'package:mangabaka_app/features/browse/widgets/search/mb_search_bar.dart';
import 'package:mangabaka_app/features/browse/widgets/results/browse_content.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/browse/screens/browse_results_screen.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/features/browse/screens/barcode_scanner_screen.dart';
import 'package:mangabaka_app/core/theme/theme_manager.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/features/browse/controllers/browse_controller.dart';
import 'package:mangabaka_app/features/browse/utils/browse_helpers.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/filter_chips_row.dart';
import 'package:mangabaka_app/features/browse/widgets/browse_type_tabs.dart';
import 'package:mangabaka_app/features/browse/models/browse_type.dart';
import 'package:mangabaka_app/features/browse/screens/mix_screen.dart';
import 'package:mangabaka_app/features/navigation/screens/main_screen.dart';


class BrowseScreen extends StatefulWidget {
  static final GlobalKey<BrowseScreenState> browseScreenKey = GlobalKey<BrowseScreenState>();
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => BrowseScreenState();
}

class BrowseScreenState extends State<BrowseScreen> {
  static final _logger = LoggingService.logger;
  late final BrowseController _controller;
  final FocusNode _searchFocusNode = FocusNode();

  FocusNode get searchFocusNode => _searchFocusNode;
  BrowseController get controller => _controller;
  Future<void> handleBarcodeScan() => _handleBarcodeScan();
  void handleResultSelected(AutocompleteSeriesResult result) => _handleResultSelected(result);

  @override
  void initState() {
    super.initState();
    _controller = BrowseController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.findAncestorStateOfType<MainScreenState>()?.updateTopNavBar();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _navigateToBrowseResults(
    String header,
    String sortBy, {
    String? type,
    String? staff,
    String? publisher,
  }) {
    _logger.info(
      'Navigating to BrowseResults: header=$header, sortBy=$sortBy, type=$type, staff=$staff, publisher=$publisher',
    );
    final double? randomSeed = sortBy == 'random'
        ? BrowseController.generateRandomSeed()
        : null;

    Navigator.push(
      context,
      AppTransitions.slideRight(
        BrowseResultsScreen(
          sortType: header,
          sortBy: sortBy,
          type: type,
          staff: staff,
          publisher: publisher,
          randomSeed: randomSeed,
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
    Navigator.push(
      context,
      AppTransitions.slideRight(const MixScreen()),
    );
  }

  void _showCameraPermissionDeniedSnackBar({bool offerSettings = false}) {
    final l10n = LocalizationService();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.translate('camera_permission_denied')),
        action: offerSettings
            ? SnackBarAction(
                label: l10n.translate('settings'),
                onPressed: openAppSettings,
              )
            : null,
      ),
    );
  }

  Future<void> _handleBarcodeScan() async {
    _logger.info('Requested barcode scan');

    // permission_handler is not supported on macOS — the entitlement and the
    // system dialog shown on first camera access handle permissions there.
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.camera.request();

      if (status.isPermanentlyDenied) {
        _logger.warning('Camera permission permanently denied');
        if (!mounted) return;
        _showCameraPermissionDeniedSnackBar(offerSettings: true);
        return;
      }

      if (!status.isGranted) {
        _logger.warning('Camera permission denied (status: $status)');
        if (!mounted) return;
        _showCameraPermissionDeniedSnackBar();
        return;
      }
    }

    _logger.fine('Camera permission granted, opening scanner');
    if (!mounted) return;
    final isbn = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (isbn != null && isbn.isNotEmpty) {
      _logger.info('Scanned ISBN: $isbn');
      final errorKey = await _controller.handleBarcodeScan(isbn);

      if (!mounted) return;

      if (errorKey != null) {
        _logger.warning(
          'Barcode scan handling failed with error key: $errorKey',
        );
        String message = LocalizationService().translate(errorKey);
        if (errorKey == 'no_series_found_for') {
          final title = _controller.searchController.text;
          message = message.replaceAll('{title}', title);
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      } else if (_controller.searchResults.isNotEmpty) {
        _logger.info(
          'Successfully handled barcode scan, navigating to first result',
        );
        _navigateToDetail(_controller.searchResults.first);
      }
    } else {
      _logger.fine('Barcode scan cancelled or empty');
    }
  }

  void _handleResultSelected(AutocompleteSeriesResult result) {
    _logger.info('Autocomplete result selected: ${result.title}');
    final series = BrowseHelpers.convertAutocompleteToSeries(result);
    _navigateToDetail(series);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        LocalizationService(),
        ThemeManager(),
        _controller,
      ]),
      builder: (context, _) {
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
                _controller.searchSeries();
                return null;
              },
            ),
          },
          child: Scaffold(
            backgroundColor: AppConstants.primaryBackground,
            appBar: MainScreen.showSearchBarInTopNavBar(context)
                ? null
                : AppBar(
                    automaticallyImplyLeading: false,
                    centerTitle: true,
                    title: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: MBSearchBar(
                        focusNode: _searchFocusNode,
                        controller: _controller.searchController,
                        initialFilters: _controller.currentFilters,
                        onScanTap: _handleBarcodeScan,
                        onResultSelected: _handleResultSelected,
                        onChanged: _controller.updateSearchQuery,
                        onSubmitted: (_) => _controller.searchSeries(),
                        onFilterApplied: _controller.updateFilters,
                      ),
                    ),
                  ),
            body: NotificationListener<ScrollMetricsNotification>(
              onNotification: (notification) {
                _controller.checkScroll();
                return false;
              },
              child: WidgetUtils.responsiveConstraint(
                Padding(
                  padding: EdgeInsets.only(
                    left: AppConstants.horizontalPadding,
                    right: AppConstants.horizontalPadding,
                    top: 8.0,
                    bottom: 8.0,
                  ),
                  child: Column(
                    children: [
                      if (_controller.isSearchMode)
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
                      if (_controller.isSearchMode &&
                          _controller.totalResults > 0)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 4.0,
                            bottom: 4.0,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.article_outlined,
                                size: 14,
                                color: AppConstants.textMutedColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_controller.totalResults} ${LocalizationService().translate('series')}',
                                style: TextStyle(
                                  color: AppConstants.textMutedColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
            floatingActionButton: _controller.showBackToTop
                ? WidgetUtils.tooltip(
                    message: LocalizationService().translate('back_to_top'),
                    child: FloatingActionButton(
                      onPressed: _controller.scrollToTop,
                      backgroundColor: AppConstants.accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.pillRadius,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_upward,
                        color: AppConstants.primaryBackground,
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
