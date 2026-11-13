import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/search_filter_categories_section.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/search_filter_details_section.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/search_filter_sort_section.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/search_filter_type_status_section.dart';
import 'package:mangabaka_app/features/series/controllers/series_filter_drawer_controller.dart';
import 'package:mangabaka_app/features/series/widgets/series_filter_drawer.dart';

/// Filter sections body shared between [SeriesFilterDrawer] and the desktop
/// filter panel.
class SeriesFilterSections extends StatelessWidget {
  final SeriesFilterDrawerController controller;

  const SeriesFilterSections({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final filters = controller.filters;
    if (filters == null) return const SizedBox.shrink();

    if (controller.isLoadingMetadata) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: MbSpinner()),
      );
    }

    final l10n = LocalizationService();
    final onChanged = controller.replaceFilters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SearchFilterSortSection(
          filters: filters,
          onFiltersChanged: onChanged,
          l10n: l10n,
          sortOptions: SeriesFilterDrawer.sortOptions(l10n),
        ),
        const SizedBox(height: 8),
        SearchFilterCategoriesSection(
          filters: filters,
          onFiltersChanged: onChanged,
          l10n: l10n,
          genres: controller.genres,
          tags: controller.tags,
        ),
        const SizedBox(height: 8),
        SearchFilterTypeStatusSection(
          filters: filters,
          onFiltersChanged: onChanged,
          l10n: l10n,
          types: SeriesFilterDrawer.types,
          statuses: SeriesFilterDrawer.statuses,
        ),
        const SizedBox(height: 8),
        SearchFilterDetailsSection(
          filters: filters,
          onFiltersChanged: onChanged,
          l10n: l10n,
        ),
        SizedBox(height: 32 + MediaQuery.paddingOf(context).bottom),
      ],
    );
  }
}
