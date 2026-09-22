import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_components.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/search_filter_dialogs.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class SearchFilterDetailsSection extends StatelessWidget {
  final SearchFilters filters;
  final ValueChanged<SearchFilters> onFiltersChanged;
  final LocalizationService l10n;

  const SearchFilterDetailsSection({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final int minYear = 1950;
    final int maxYear = DateTime.now().year + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.translate('details')),
        SettingsGroup(
          children: [
            SettingsItem(
              icon: Icons.verified_user_outlined,
              title: l10n.translate('licensed_status'),
              subtitle: filters.isLicensed == null
                  ? l10n.translate('any')
                  : (filters.isLicensed == true
                        ? l10n.translate('yes')
                        : l10n.translate('no')),
              isFirst: true,
              onTap: () => SearchFilterDialogs.showLicensedStatusDialog(
                context: context,
                l10n: l10n,
                currentFilters: filters,
                onStatusSelected: (val) =>
                    onFiltersChanged(filters.copyWithIsLicensed(val)),
              ),
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.live_tv_outlined,
              title: l10n.translate('has_anime'),
              subtitle: filters.hasAnime == null
                  ? l10n.translate('any')
                  : (filters.hasAnime == true
                        ? l10n.translate('yes')
                        : l10n.translate('no')),
              onTap: () => SearchFilterDialogs.showHasAnimeDialog(
                context: context,
                l10n: l10n,
                currentFilters: filters,
                onStatusSelected: (val) =>
                    onFiltersChanged(filters.copyWithHasAnime(val)),
              ),
            ),
            const SettingsDivider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.translate('rating_range').toUpperCase(),
                        style: AppTypography.display(
                          color: context.colors.text,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${filters.ratingLower.toInt()} - ${filters.ratingUpper.toInt()}',
                        style: AppTypography.display(
                          color: context.colors.accent,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(
                      filters.ratingLower,
                      filters.ratingUpper,
                    ),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: context.colors.accent,
                    inactiveColor: context.colors.border.withValues(alpha: 0.2),
                    onChanged: (values) => onFiltersChanged(
                      filters.copyWith(
                        ratingLower: values.start,
                        ratingUpper: values.end,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SettingsDivider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.translate('publication_year').toUpperCase(),
                        style: AppTypography.display(
                          color: context.colors.text,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${filters.publishedYearLower ?? l10n.translate('any')} - ${filters.publishedYearUpper ?? l10n.translate('any')}',
                        style: AppTypography.display(
                          color: context.colors.accent,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(
                      (filters.publishedYearLower ?? minYear).toDouble(),
                      (filters.publishedYearUpper ?? maxYear).toDouble(),
                    ),
                    min: minYear.toDouble(),
                    max: maxYear.toDouble(),
                    divisions: maxYear - minYear,
                    activeColor: context.colors.accent,
                    inactiveColor: context.colors.border.withValues(alpha: 0.2),
                    onChanged: (values) => onFiltersChanged(
                      filters.copyWith(
                        publishedYearLower: values.start.toInt() == minYear
                            ? null
                            : values.start.toInt(),
                        publishedYearUpper: values.end.toInt() == maxYear
                            ? null
                            : values.end.toInt(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
