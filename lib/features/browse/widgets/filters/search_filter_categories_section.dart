import 'package:mangabaka_app/core/widgets/adaptive_form.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_components.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/filter_list_dialog.dart';

class SearchFilterCategoriesSection extends StatelessWidget {
  final SearchFilters filters;
  final ValueChanged<SearchFilters> onFiltersChanged;
  final LocalizationService l10n;
  final List<Map<String, dynamic>> genres;
  final List<Map<String, dynamic>> tags;

  const SearchFilterCategoriesSection({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    required this.l10n,
    required this.genres,
    required this.tags,
  });

  void _showFilterForm(
    BuildContext context, {
    required String title,
    required String searchHint,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    required List<String> includes,
    required List<String> excludes,
    required Function(List<String>, List<String>) onApply,
  }) {
    showAdaptiveForm<void>(
      context: context,
      title: title,
      scrollable: false,
      builder: (context) => FilterListDialog(
        title: title,
        searchHint: searchHint,
        items: items,
        idKey: idKey,
        nameKey: nameKey,
        initialIncludes: includes,
        initialExcludes: excludes,
        onApply: onApply,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.translate('categories')),
        SettingsGroup(
          children: [
            SettingsItem(
              icon: Icons.category_outlined,
              title: l10n.translate('genres'),
              subtitle: filters.genre.isEmpty && filters.genreNot.isEmpty
                  ? l10n.translate('any')
                  : '${filters.genre.length} ${l10n.translate('included')}, ${filters.genreNot.length} ${l10n.translate('excluded')}',
              isFirst: true,
              onTap: () => _showFilterForm(
                context,
                title: l10n.translate('genres'),
                searchHint: l10n.translate('search_genres'),
                items: genres,
                idKey: 'value',
                nameKey: 'label',
                includes: filters.genre,
                excludes: filters.genreNot,
                onApply: (inc, exc) => onFiltersChanged(
                  filters.copyWith(genre: inc, genreNot: exc),
                ),
              ),
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.label_outline,
              title: l10n.translate('tags'),
              subtitle: filters.tag.isEmpty && filters.tagNot.isEmpty
                  ? l10n.translate('any')
                  : '${filters.tag.length} ${l10n.translate('included')}, ${filters.tagNot.length} ${l10n.translate('excluded')}',
              isLast: true,
              onTap: () => _showFilterForm(
                context,
                title: l10n.translate('tags'),
                searchHint: l10n.translate('search_tags'),
                items: tags,
                idKey: 'id',
                nameKey: 'name',
                includes: filters.tag,
                excludes: filters.tagNot,
                onApply: (inc, exc) =>
                    onFiltersChanged(filters.copyWith(tag: inc, tagNot: exc)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
