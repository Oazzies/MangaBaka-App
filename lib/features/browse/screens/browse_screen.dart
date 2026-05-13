import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/app_shortcuts.dart';
import 'package:mangabaka_app/features/browse/widgets/mb_search_bar.dart';
import 'package:mangabaka_app/features/browse/widgets/browse_content.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/browse/screens/browse_results_screen.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/features/browse/screens/barcode_scanner_screen.dart';
import 'package:mangabaka_app/utils/theme/theme_manager.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/transitions/app_transitions.dart';
import 'package:mangabaka_app/features/browse/controllers/browse_controller.dart';
import 'package:mangabaka_app/features/browse/utils/browse_helpers.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/features/browse/widgets/filter_chips_row.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  static final _logger = LoggingService.logger;
  late final BrowseController _controller;
  final FocusNode _searchFocusNode = FocusNode();

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

  void _navigateToBrowseResults(String header, String sortBy, {String? type}) {
    _logger.info('Navigating to BrowseResults: header=$header, sortBy=$sortBy, type=$type');
    final double? randomSeed = sortBy == 'random' ? BrowseController.generateRandomSeed() : null;

    Navigator.push(
      context,
      AppTransitions.slideRight(BrowseResultsScreen(
        sortType: header,
        sortBy: sortBy,
        type: type,
        randomSeed: randomSeed,
      )),
    );
  }

  void _navigateToDetail(Series series) {
    _logger.info('Navigating to SeriesDetail: ${series.title} (ID: ${series.id})');
    Navigator.push(
      context,
      AppTransitions.slideUp(SeriesDetailScreen(series: series)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().translate('camera_permission_denied')),
            action: SnackBarAction(
              label: LocalizationService().translate('settings'),
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return;
      }

      if (!status.isGranted) {
        _logger.warning('Camera permission denied (status: $status)');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService().translate('camera_permission_denied'))),
        );
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
        _logger.warning('Barcode scan handling failed with error key: $errorKey');
        String message = LocalizationService().translate(errorKey);
        if (errorKey == 'no_series_found_for') {
          final title = _controller.searchController.text;
          message = message.replaceAll('{title}', title);
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      } else if (_controller.searchResults.isNotEmpty) {
        _logger.info('Successfully handled barcode scan, navigating to first result');
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
      listenable: Listenable.merge([LocalizationService(), ThemeManager(), _controller]),
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
            body: WidgetUtils.responsiveConstraint(
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppConstants.horizontalPadding,
                  right: AppConstants.horizontalPadding,
                  top: AppConstants.verticalPadding,
                  bottom: 8.0,
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 64),
                      child: Column(
                        children: [
                          FilterChipsRow(
                            filters: _controller.currentFilters,
                            onFiltersChanged: _controller.updateFilters,
                          ),
                          BrowseContent(
                            searchResults: _controller.searchResults,
                            isLoading: _controller.isLoading,
                            isLoadingMore: _controller.isLoadingMore,
                            error: _controller.error,
                            scrollController: _controller.scrollController,
                            onRetry: _controller.searchSeries,
                            onNavigateToDetail: _navigateToDetail,
                            onNavigateToResults: _navigateToBrowseResults,
                          ),
                        ],
                      ),
                    ),
                    MBSearchBar(
                      focusNode: _searchFocusNode,
                      controller: _controller.searchController,
                      initialFilters: _controller.currentFilters,
                      onScanTap: _handleBarcodeScan,
                      onResultSelected: _handleResultSelected,
                      onChanged: _controller.updateSearchQuery,
                      onSubmitted: (_) => _controller.searchSeries(),
                      onFilterApplied: _controller.updateFilters,
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: _controller.showBackToTop
              ? FloatingActionButton(
                  onPressed: _controller.scrollToTop,
                  backgroundColor: AppConstants.accentColor,
                  tooltip: LocalizationService().translate('back_to_top'),
                  child: Icon(Icons.arrow_upward, color: AppConstants.primaryBackground),
                )
              : null,
        ),
      );
    },
  );
}
}
