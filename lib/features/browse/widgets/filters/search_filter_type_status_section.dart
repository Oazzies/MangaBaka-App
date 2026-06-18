import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_components.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/filter_list_dialog.dart';

class SearchFilterTypeStatusSection extends StatelessWidget {
  final SearchFilters filters;
  final ValueChanged<SearchFilters> onFiltersChanged;
  final LocalizationService l10n;
  final List<String> types;
  final List<String> statuses;

  const SearchFilterTypeStatusSection({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    required this.l10n,
    required this.types,
    required this.statuses,
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
    bool showSearch = true,
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
            showSearch: showSearch,
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
        SettingsGroup(
          children: [
            SettingsItem(
              icon: Icons.auto_awesome_outlined,
              title: l10n.translate('type'),
              subtitle: filters.type.isEmpty && filters.typeNot.isEmpty
                  ? l10n.translate('any')
                  : '${filters.type.length} ${l10n.translate('included')}, ${filters.typeNot.length} ${l10n.translate('excluded')}',
              isFirst: true,
              onTap: () => _showFilterDialog(
                context,
                title: l10n.translate('type'),
                items: types.map((t) => {'value': t, 'label': l10n.translate('type_$t')}).toList(),
                idKey: 'value',
                nameKey: 'label',
                includes: filters.type,
                excludes: filters.typeNot,
                onApply: (inc, exc) => onFiltersChanged(
                  filters.copyWith(type: inc, typeNot: exc),
                ),
                showSearch: false,
              ),
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.history_outlined,
              title: l10n.translate('status'),
              subtitle: filters.status.isEmpty && filters.statusNot.isEmpty
                  ? l10n.translate('any')
                  : '${filters.status.length} ${l10n.translate('included')}, ${filters.statusNot.length} ${l10n.translate('excluded')}',
              isLast: true,
              onTap: () => _showFilterDialog(
                context,
                title: l10n.translate('status'),
                items: statuses.map((s) => {'value': s, 'label': l10n.translate('status_$s')}).toList(),
                idKey: 'value',
                nameKey: 'label',
                includes: filters.status,
                excludes: filters.statusNot,
                onApply: (inc, exc) => onFiltersChanged(
                  filters.copyWith(status: inc, statusNot: exc),
                ),
                showSearch: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
