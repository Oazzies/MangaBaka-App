import 'package:mangabaka_app/core/widgets/design/mb_badge.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/models/sort_options.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';

import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/search_filter_details_section.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/search_filter_categories_section.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/search_filter_type_status_section.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/search_filter_sort_section.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';

class SearchFilterBottomSheet extends StatefulWidget {
  final SearchFilters initialFilters;
  final ValueChanged<SearchFilters> onApply;
  final bool isDialog;
  final bool showLibrarySorts;

  const SearchFilterBottomSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
    this.isDialog = false,
    this.showLibrarySorts = false,
  });

  @override
  State<SearchFilterBottomSheet> createState() =>
      _SearchFilterBottomSheetState();
}

class _SearchFilterBottomSheetState extends State<SearchFilterBottomSheet> {
  late SearchFilters _filters;
  late final SeriesSearchService _searchService;

  final List<String> _types = filterSeriesTypes;
  final List<String> _statuses = filterPublicationStatuses;

  Map<String, String> _getSortOptions(LocalizationService l10n) =>
      searchSortOptions(l10n, library: widget.showLibrarySorts);

  List<Map<String, dynamic>> _genres = [];
  List<Map<String, dynamic>> _tags = [];
  bool _isLoadingMetadata = true;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
    _searchService = getIt<SeriesSearchService>();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    try {
      final results = await Future.wait([
        _searchService.getGenres(),
        _searchService.getTags(),
      ]);
      if (mounted) {
        setState(() {
          _genres = results[0];
          _tags = results[1];
          _isLoadingMetadata = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMetadata = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) {
        final l10n = LocalizationService();
        final sortOptions = _getSortOptions(l10n);

        return Container(
          height: widget.isDialog
              ? null
              : MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: widget.isDialog
                ? context.colors.surface
                : context.colors.background,
            borderRadius: widget.isDialog
                ? BorderRadius.circular(24)
                : const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.isDialog) ...[
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.colors.surfaceRaised,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () =>
                          setState(() => _filters = SearchFilters()),
                      style: TextButton.styleFrom(
                        foregroundColor: context.colors.textMuted,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      child: Text(l10n.translate('reset').toUpperCase()),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.translate('filters').toUpperCase(),
                          style: AppTypography.display(
                            color: context.colors.text,
                            fontSize: 18,
                          ),
                        ),
                        // Active-filter count as an amber badge: countable
                        // state gets the accent everywhere in the system.
                        if (_filters.activeFiltersCount > 0) ...[
                          const SizedBox(width: 8),
                          MbBadge.accent(
                            label: '${_filters.activeFiltersCount}',
                          ),
                        ],
                      ],
                    ),
                    MbTappable(
                      pressedScale: 0.95,
                      onTap: () {
                        widget.onApply(_filters);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.accent,
                          borderRadius: BorderRadius.circular(
                            AppConstants.pillRadius,
                          ),
                        ),
                        child: Text(
                          l10n.translate('apply').toUpperCase(),
                          style: AppTypography.display(
                            color: context.colors.onAccent,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: _isLoadingMetadata
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: MbSpinner()),
                      )
                    : ListView(
                        shrinkWrap: widget.isDialog,
                        padding: EdgeInsets.only(
                          left: AppConstants.horizontalPadding,
                          right: AppConstants.horizontalPadding,
                          top: 8,
                          bottom: 40,
                        ),
                        children: [
                          SearchFilterSortSection(
                            filters: _filters,
                            onFiltersChanged: (newFilters) =>
                                setState(() => _filters = newFilters),
                            l10n: l10n,
                            sortOptions: sortOptions,
                          ),
                          const SizedBox(height: 8),
                          SearchFilterCategoriesSection(
                            filters: _filters,
                            onFiltersChanged: (newFilters) =>
                                setState(() => _filters = newFilters),
                            l10n: l10n,
                            genres: _genres,
                            tags: _tags,
                          ),
                          const SizedBox(height: 8),
                          SearchFilterTypeStatusSection(
                            filters: _filters,
                            onFiltersChanged: (newFilters) =>
                                setState(() => _filters = newFilters),
                            l10n: l10n,
                            types: _types,
                            statuses: _statuses,
                          ),
                          const SizedBox(height: 8),
                          SearchFilterDetailsSection(
                            filters: _filters,
                            onFiltersChanged: (newFilters) =>
                                setState(() => _filters = newFilters),
                            l10n: l10n,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
