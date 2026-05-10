import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/features/profile/widgets/settings_components.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/features/browse/widgets/filter_list_dialog.dart';

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

  void _showFilterDialog(
    BuildContext context, {
    required String title,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    required List<String> includes,
    required List<String> excludes,
    required Function(List<String>, List<String>) onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppConstants.primaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: FilterListDialog(
            title: title,
            items: items,
            idKey: idKey,
            nameKey: nameKey,
            initialIncludes: includes,
            initialExcludes: excludes,
            onApply: onApply,
          ),
        );
      },
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
              onTap: () => _showFilterDialog(
                context,
                title: l10n.translate('genres'),
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
              onTap: () => _showFilterDialog(
                context,
                title: l10n.translate('tags'),
                items: tags,
                idKey: 'id',
                nameKey: 'name',
                includes: filters.tag,
                excludes: filters.tagNot,
                onApply: (inc, exc) => onFiltersChanged(
                  filters.copyWith(tag: inc, tagNot: exc),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
