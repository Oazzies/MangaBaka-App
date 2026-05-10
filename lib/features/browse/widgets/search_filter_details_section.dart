import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/features/profile/widgets/settings_components.dart';
import 'package:mangabaka_app/features/browse/widgets/search_filter_dialogs.dart';

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
                onStatusSelected: (val) => onFiltersChanged(filters.copyWithIsLicensed(val)),
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
                        l10n.translate('rating_range'),
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${filters.ratingLower.toInt()} - ${filters.ratingUpper.toInt()}',
                        style: TextStyle(
                          color: AppConstants.accentColor,
                          fontWeight: FontWeight.bold,
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
                    activeColor: AppConstants.accentColor,
                    inactiveColor: AppConstants.borderColor.withValues(alpha: 0.2),
                    onChanged: (values) => onFiltersChanged(filters.copyWith(
                      ratingLower: values.start,
                      ratingUpper: values.end,
                    )),
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
                        l10n.translate('publication_year'),
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${filters.publishedYearLower ?? l10n.translate('any')} - ${filters.publishedYearUpper ?? l10n.translate('any')}',
                        style: TextStyle(
                          color: AppConstants.accentColor,
                          fontWeight: FontWeight.bold,
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
                    activeColor: AppConstants.accentColor,
                    inactiveColor: AppConstants.borderColor.withValues(alpha: 0.2),
                    onChanged: (values) => onFiltersChanged(filters.copyWith(
                      publishedYearLower: values.start.toInt() == minYear ? null : values.start.toInt(),
                      publishedYearUpper: values.end.toInt() == maxYear ? null : values.end.toInt(),
                    )),
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
