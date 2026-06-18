import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
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
          chips.add(
            _buildChip(label, () {
              onFiltersChanged(filters.copyWithSortBy(null));
            }),
          );
        }

        // Types
        chips.addAll(_buildFilterPairChips(
          include: filters.type,
          exclude: filters.typeNot,
          labelFor: (v) => l10n.translate('type_$v'),
          onRemoveInclude: (v) => onFiltersChanged(
            filters.copyWith(type: filters.type.where((x) => x != v).toList()),
          ),
          onRemoveExclude: (v) => onFiltersChanged(
            filters.copyWith(typeNot: filters.typeNot.where((x) => x != v).toList()),
          ),
        ));

        // Status
        chips.addAll(_buildFilterPairChips(
          include: filters.status,
          exclude: filters.statusNot,
          labelFor: (v) => l10n.translate('status_$v'),
          onRemoveInclude: (v) => onFiltersChanged(
            filters.copyWith(status: filters.status.where((x) => x != v).toList()),
          ),
          onRemoveExclude: (v) => onFiltersChanged(
            filters.copyWith(statusNot: filters.statusNot.where((x) => x != v).toList()),
          ),
        ));

        // Genres
        chips.addAll(_buildFilterPairChips(
          include: filters.genre,
          exclude: filters.genreNot,
          labelFor: metadata.getGenreLabel,
          onRemoveInclude: (v) => onFiltersChanged(
            filters.copyWith(genre: filters.genre.where((x) => x != v).toList()),
          ),
          onRemoveExclude: (v) => onFiltersChanged(
            filters.copyWith(genreNot: filters.genreNot.where((x) => x != v).toList()),
          ),
        ));

        // Tags
        chips.addAll(_buildFilterPairChips(
          include: filters.tag,
          exclude: filters.tagNot,
          labelFor: (v) {
            final id = int.tryParse(v);
            if (id == null) return v;
            return metadata.getTagName(id);
          },
          onRemoveInclude: (v) => onFiltersChanged(
            filters.copyWith(tag: filters.tag.where((x) => x != v).toList()),
          ),
          onRemoveExclude: (v) => onFiltersChanged(
            filters.copyWith(tagNot: filters.tagNot.where((x) => x != v).toList()),
          ),
        ));

        // Staff / Authors / Artists
        if (filters.staff.isNotEmpty) {
          chips.addAll(filters.staff.map((v) => _buildChip(
            v,
            () => onFiltersChanged(
              filters.copyWith(staff: filters.staff.where((x) => x != v).toList()),
            ),
          )));
        }

        // Publisher
        if (filters.publisher.isNotEmpty) {
          chips.addAll(filters.publisher.map((v) => _buildChip(
            v,
            () => onFiltersChanged(
              filters.copyWith(publisher: filters.publisher.where((x) => x != v).toList()),
            ),
          )));
        }

        // Rating
        if (filters.ratingLower > 0 || filters.ratingUpper < 100) {
          chips.add(
            _buildChip(
              '${l10n.translate('rating_range')}: ${filters.ratingLower.toInt()}-${filters.ratingUpper.toInt()}',
              () {
                onFiltersChanged(
                  filters.copyWith(ratingLower: 0, ratingUpper: 100),
                );
              },
            ),
          );
        }

        // Licensed Status
        if (filters.isLicensed != null) {
          chips.add(
            _buildChip(
              '${l10n.translate('licensed_status')}: ${filters.isLicensed! ? l10n.translate('yes') : l10n.translate('no')}',
              () {
                onFiltersChanged(filters.copyWithIsLicensed(null));
              },
            ),
          );
        }

        // Year
        if (filters.publishedYearLower != null ||
            filters.publishedYearUpper != null) {
          final yearText =
              filters.publishedYearLower != null &&
                  filters.publishedYearUpper != null
              ? '${filters.publishedYearLower}-${filters.publishedYearUpper}'
              : (filters.publishedYearLower != null
                    ? '>= ${filters.publishedYearLower}'
                    : '<= ${filters.publishedYearUpper}');
          chips.add(
            _buildChip('${l10n.translate('publication_year')}: $yearText', () {
              onFiltersChanged(
                filters.copyWithYear(
                  publishedYearLower: null,
                  publishedYearUpper: null,
                ),
              );
            }),
          );
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 16,
                        color: AppConstants.errorColor,
                      ),
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

  /// Builds include and exclude chips for a single filter category.
  /// Returns chips for every value in [include] (positive style) followed by
  /// every value in [exclude] (negative / red style).
  List<Widget> _buildFilterPairChips({
    required List<String> include,
    required List<String> exclude,
    required String Function(String) labelFor,
    required void Function(String) onRemoveInclude,
    required void Function(String) onRemoveExclude,
  }) {
    return [
      for (final v in include)
        _buildChip(labelFor(v), () => onRemoveInclude(v)),
      for (final v in exclude)
        _buildChip('- ${labelFor(v)}', () => onRemoveExclude(v), isNegative: true),
    ];
  }

  Widget _buildChip(
    String label,
    VoidCallback onDeleted, {
    bool isNegative = false,
  }) {
    final color = isNegative ? AppConstants.errorColor : AppConstants.textColor;
    final bgColor = isNegative
        ? AppConstants.errorColor.withValues(alpha: 0.12)
        : AppConstants.tertiaryBackground;

    return RawChip(
      label: Text(label.toUpperCase()),
      onDeleted: onDeleted,
      deleteIcon: Icon(Icons.close_rounded, size: 14, color: color),
      backgroundColor: bgColor,
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  String _getSortLabel(String sortBy, LocalizationService l10n) {
    switch (sortBy) {
      case 'name_asc':
        return l10n.translate('title_asc');
      case 'name_desc':
        return l10n.translate('title_desc');
      case 'popularity_asc':
        return l10n.translate('popularity_asc');
      case 'popularity_desc':
        return l10n.translate('popularity_desc');
      case 'score_desc':
        return l10n.translate('rating_desc');
      case 'score_asc':
        return l10n.translate('rating_asc');
      case 'chapters_desc':
        return l10n.translate('chapters_desc');
      case 'chapters_asc':
        return l10n.translate('chapters_asc');
      case 'unread_desc':
        return l10n.translate('unread_desc');
      case 'unread_asc':
        return l10n.translate('unread_asc');
      case 'random':
        return l10n.translate('random_sort');
      default:
        return sortBy;
    }
  }
}
