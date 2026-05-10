import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/features/profile/widgets/settings_components.dart';
import 'package:mangabaka_app/features/browse/widgets/search_filter_dialogs.dart';

class SearchFilterSortSection extends StatelessWidget {
  final SearchFilters filters;
  final ValueChanged<SearchFilters> onFiltersChanged;
  final LocalizationService l10n;
  final Map<String, String> sortOptions;

  const SearchFilterSortSection({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    required this.l10n,
    required this.sortOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.translate('sort_by')),
        SettingsGroup(
          children: [
            SettingsItem(
              icon: Icons.sort_outlined,
              title: l10n.translate('sort_by'),
              subtitle: filters.sortBy == null
                  ? l10n.translate('default')
                  : sortOptions[filters.sortBy!],
              isFirst: true,
              isLast: true,
              onTap: () => SearchFilterDialogs.showSortSelectionDialog(
                context: context,
                l10n: l10n,
                sortOptions: sortOptions,
                currentFilters: filters,
                onSortSelected: (val) => onFiltersChanged(filters.copyWith(sortBy: val)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
