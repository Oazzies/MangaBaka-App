import 'package:mangabaka_app/core/widgets/adaptive_sheet.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_components.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/filter_list_dialog.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/content_rating_filter.dart';

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
    showAdaptiveSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.background,
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

  Future<void> _askPublisher(BuildContext context) async {
    final text = TextEditingController(text: filters.publisher.join(', '));
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(l10n.translate('filter_publisher')),
        content: TextField(
          controller: text,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.translate('filter_publisher_hint'),
          ),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(text.text),
            child: Text(l10n.translate('apply')),
          ),
        ],
      ),
    );
    text.dispose();
    if (result == null) return;
    onFiltersChanged(
      filters.copyWith(
        publisher: [
          for (final p in result.split(','))
            if (p.trim().isNotEmpty) p.trim(),
        ],
      ),
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
                items: types
                    .map(
                      (t) => {'value': t, 'label': l10n.translate('type_$t')},
                    )
                    .toList(),
                idKey: 'value',
                nameKey: 'label',
                includes: filters.type,
                excludes: filters.typeNot,
                onApply: (inc, exc) =>
                    onFiltersChanged(filters.copyWith(type: inc, typeNot: exc)),
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
              onTap: () => _showFilterDialog(
                context,
                title: l10n.translate('status'),
                items: statuses
                    .map(
                      (s) => {'value': s, 'label': l10n.translate('status_$s')},
                    )
                    .toList(),
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
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.shield_outlined,
              title: l10n.translate('content_rating'),
              subtitle:
                  filters.contentRating.isEmpty &&
                      filters.contentRatingNot.isEmpty
                  ? l10n.translate('any')
                  : '${filters.contentRating.length} ${l10n.translate('included')}, ${filters.contentRatingNot.length} ${l10n.translate('excluded')}',
              onTap: () => _showFilterDialog(
                context,
                title: l10n.translate('content_rating'),
                items: ContentRatingFilter.all
                    .map((r) => {'value': r, 'label': l10n.translate(r)})
                    .toList(),
                idKey: 'value',
                nameKey: 'label',
                includes: filters.contentRating,
                excludes: filters.contentRatingNot,
                onApply: (inc, exc) => onFiltersChanged(
                  filters.copyWith(contentRating: inc, contentRatingNot: exc),
                ),
                showSearch: false,
              ),
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.business_outlined,
              title: l10n.translate('filter_publisher'),
              subtitle: filters.publisher.isEmpty
                  ? l10n.translate('any')
                  : filters.publisher.join(', '),
              isLast: true,
              onTap: () => _askPublisher(context),
            ),
          ],
        ),
      ],
    );
  }
}
