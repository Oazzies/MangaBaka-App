import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';

import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/features/browse/widgets/search_filter_details_section.dart';
import 'package:mangabaka_app/features/browse/widgets/search_filter_categories_section.dart';
import 'package:mangabaka_app/features/browse/widgets/search_filter_type_status_section.dart';
import 'package:mangabaka_app/features/browse/widgets/search_filter_sort_section.dart';

class SearchFilterBottomSheet extends StatefulWidget {
  final SearchFilters initialFilters;
  final ValueChanged<SearchFilters> onApply;
  final bool isDialog;
 
  const SearchFilterBottomSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
    this.isDialog = false,
  });
 
  @override
  State<SearchFilterBottomSheet> createState() =>
      _SearchFilterBottomSheetState();
}
 
class _SearchFilterBottomSheetState extends State<SearchFilterBottomSheet> {
  late SearchFilters _filters;
  late final SeriesSearchService _searchService;
 
  final List<String> _types = ['manga', 'manhwa', 'manhua', 'novel', 'oel'];
  final List<String> _statuses = [
    'ongoing',
    'releasing',
    'completed',
    'hiatus',
    'cancelled',
  ];
 
  Map<String, String> _getSortOptions(LocalizationService l10n) {
    return {
      'name_asc': l10n.translate('title_asc'),
      'name_desc': l10n.translate('title_desc'),
      'popularity_asc': l10n.translate('popularity_asc'),
      'popularity_desc': l10n.translate('popularity_desc'),
      'score_desc': l10n.translate('rating_desc'),
      'score_asc': l10n.translate('rating_asc'),
      'random': l10n.translate('random_sort'),
    };
  }
 
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
          height: widget.isDialog ? null : MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: widget.isDialog ? AppConstants.secondaryBackground : AppConstants.primaryBackground,
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
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppConstants.borderColor.withValues(alpha: 0.15),
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
                      child: Text(
                        l10n.translate('reset').toUpperCase(),
                        style: TextStyle(
                          color: AppConstants.textMutedColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      l10n.translate('filters'),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.onApply(_filters);
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor:
                            AppConstants.accentColor.withValues(alpha: 0.15),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        l10n.translate('apply').toUpperCase(),
                        style: TextStyle(
                          color: AppConstants.accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
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
                        child: Center(child: CircularProgressIndicator()),
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
                            onFiltersChanged: (newFilters) => setState(() => _filters = newFilters),
                            l10n: l10n,
                            sortOptions: sortOptions,
                          ),
                          const SizedBox(height: 8),
                          SearchFilterCategoriesSection(
                            filters: _filters,
                            onFiltersChanged: (newFilters) => setState(() => _filters = newFilters),
                            l10n: l10n,
                            genres: _genres,
                            tags: _tags,
                          ),
                          const SizedBox(height: 8),
                          SearchFilterTypeStatusSection(
                            filters: _filters,
                            onFiltersChanged: (newFilters) => setState(() => _filters = newFilters),
                            l10n: l10n,
                            types: _types,
                            statuses: _statuses,
                          ),
                          const SizedBox(height: 8),
                          SearchFilterDetailsSection(
                            filters: _filters,
                            onFiltersChanged: (newFilters) => setState(() => _filters = newFilters),
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
