import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';

class FilterChipsRow extends StatelessWidget {
  final SearchFilters filters;
  final ValueChanged<SearchFilters> onFiltersChanged;

  const FilterChipsRow({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) {
        final l10n = LocalizationService();
        final metadata = getIt<MetadataService>();
        final chips = <Widget>[];

        // Sort By
        if (filters.sortBy != null && filters.sortBy!.isNotEmpty) {
          final label = _getSortLabel(filters.sortBy!, l10n);
          chips.add(_buildChip(label, () {
            onFiltersChanged(filters.copyWithSortBy(null));
          }));
        }

        // Types
        for (final t in filters.type) {
          chips.add(_buildChip(l10n.translate('type_$t'), () {
            onFiltersChanged(filters.copyWith(type: filters.type.where((x) => x != t).toList()));
          }));
        }
        for (final t in filters.typeNot) {
          chips.add(_buildChip('- ${l10n.translate('type_$t')}', () {
            onFiltersChanged(filters.copyWith(typeNot: filters.typeNot.where((x) => x != t).toList()));
          }, isNegative: true));
        }

        // Status
        for (final s in filters.status) {
          chips.add(_buildChip(l10n.translate('status_$s'), () {
            onFiltersChanged(filters.copyWith(status: filters.status.where((x) => x != s).toList()));
          }));
        }
        for (final s in filters.statusNot) {
          chips.add(_buildChip('- ${l10n.translate('status_$s')}', () {
            onFiltersChanged(filters.copyWith(statusNot: filters.statusNot.where((x) => x != s).toList()));
          }, isNegative: true));
        }

        // Genres
        for (final g in filters.genre) {
          chips.add(_buildChip(metadata.getGenreLabel(g), () {
            onFiltersChanged(filters.copyWith(genre: filters.genre.where((x) => x != g).toList()));
          }));
        }
        for (final g in filters.genreNot) {
          chips.add(_buildChip('- ${metadata.getGenreLabel(g)}', () {
            onFiltersChanged(filters.copyWith(genreNot: filters.genreNot.where((x) => x != g).toList()));
          }, isNegative: true));
        }

        // Tags
        for (final t in filters.tag) {
          final tagName = metadata.getTagName(int.tryParse(t) ?? 0);
          chips.add(_buildChip(tagName, () {
            onFiltersChanged(filters.copyWith(tag: filters.tag.where((x) => x != t).toList()));
          }));
        }
        for (final t in filters.tagNot) {
          final tagName = metadata.getTagName(int.tryParse(t) ?? 0);
          chips.add(_buildChip('- $tagName', () {
            onFiltersChanged(filters.copyWith(tagNot: filters.tagNot.where((x) => x != t).toList()));
          }, isNegative: true));
        }

        // Rating
        if (filters.ratingLower > 0 || filters.ratingUpper < 100) {
          chips.add(_buildChip('${l10n.translate('rating_range')}: ${filters.ratingLower.toInt()}-${filters.ratingUpper.toInt()}', () {
            onFiltersChanged(filters.copyWith(ratingLower: 0, ratingUpper: 100));
          }));
        }

        // Licensed Status
        if (filters.isLicensed != null) {
          chips.add(_buildChip('${l10n.translate('licensed_status')}: ${filters.isLicensed! ? l10n.translate('yes') : l10n.translate('no')}', () {
            onFiltersChanged(filters.copyWithIsLicensed(null));
          }));
        }

        // Year
        if (filters.publishedYearLower != null || filters.publishedYearUpper != null) {
          final yearText = filters.publishedYearLower != null && filters.publishedYearUpper != null
              ? '${filters.publishedYearLower}-${filters.publishedYearUpper}'
              : (filters.publishedYearLower != null ? '>= ${filters.publishedYearLower}' : '<= ${filters.publishedYearUpper}');
          chips.add(_buildChip('${l10n.translate('publication_year')}: $yearText', () {
            onFiltersChanged(filters.copyWithYear(publishedYearLower: null, publishedYearUpper: null));
          }));
        }

        if (chips.isEmpty) return const SizedBox.shrink();
 
        return Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...chips,
              GestureDetector(
                onTap: () => onFiltersChanged(SearchFilters()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppConstants.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 16, color: AppConstants.errorColor),
                      const SizedBox(width: 8),
                      Text(
                        l10n.translate('reset').toUpperCase(),
                        style: TextStyle(
                          color: AppConstants.errorColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
 
  Widget _buildChip(String label, VoidCallback onDeleted, {bool isNegative = false}) {
    final color = isNegative ? AppConstants.errorColor : AppConstants.textColor;
    final bgColor = isNegative 
        ? AppConstants.errorColor.withValues(alpha: 0.1) 
        : AppConstants.secondaryBackground;

    return RawChip(
      label: Text(label.toUpperCase()),
      onDeleted: onDeleted,
      deleteIcon: Icon(Icons.close_rounded, size: 14, color: color),
      backgroundColor: bgColor,
      labelStyle: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide.none,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  String _getSortLabel(String sortBy, LocalizationService l10n) {
    switch (sortBy) {
      case 'name_asc': return l10n.translate('title_asc');
      case 'name_desc': return l10n.translate('title_desc');
      case 'popularity_asc': return l10n.translate('popularity_asc');
      case 'popularity_desc': return l10n.translate('popularity_desc');
      case 'random': return l10n.translate('random_sort');
      default: return sortBy;
    }
  }
}
