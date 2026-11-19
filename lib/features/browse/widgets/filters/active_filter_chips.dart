import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/filter_chip_badge.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';

List<Widget> buildActiveFilterChips({
  required SearchFilters filters,
  required ValueChanged<SearchFilters> onChanged,
  required LocalizationService l10n,
  required MetadataService metadata,
}) {
  final chips = <Widget>[];

  Widget chip(String label, VoidCallback onDeleted) =>
      FilterChipBadge(label: label, onDeleted: onDeleted);

  List<Widget> pair({
    required List<String> include,
    required List<String> exclude,
    required String Function(String) labelFor,
    required SearchFilters Function(List<String>) withInclude,
    required SearchFilters Function(List<String>) withExclude,
  }) => buildFilterPairChips(
    include: include,
    exclude: exclude,
    labelFor: labelFor,
    onRemoveInclude: (v) =>
        onChanged(withInclude(include.where((x) => x != v).toList())),
    onRemoveExclude: (v) =>
        onChanged(withExclude(exclude.where((x) => x != v).toList())),
  );

  String yesNo(bool value) => l10n.translate(value ? 'yes' : 'no');

  final sortBy = filters.sortBy;
  if (sortBy != null && sortBy.isNotEmpty) {
    chips.add(
      chip(
        filterSortLabel(sortBy, l10n),
        () => onChanged(filters.copyWithSortBy(null)),
      ),
    );
  }

  chips
    ..addAll(
      pair(
        include: filters.type,
        exclude: filters.typeNot,
        labelFor: (v) => l10n.translate('type_$v'),
        withInclude: (v) => filters.copyWith(type: v),
        withExclude: (v) => filters.copyWith(typeNot: v),
      ),
    )
    ..addAll(
      pair(
        include: filters.status,
        exclude: filters.statusNot,
        labelFor: (v) => l10n.translate('status_$v'),
        withInclude: (v) => filters.copyWith(status: v),
        withExclude: (v) => filters.copyWith(statusNot: v),
      ),
    )
    ..addAll(
      pair(
        include: filters.genre,
        exclude: filters.genreNot,
        labelFor: metadata.getGenreLabel,
        withInclude: (v) => filters.copyWith(genre: v),
        withExclude: (v) => filters.copyWith(genreNot: v),
      ),
    )
    ..addAll(
      pair(
        include: filters.tag,
        exclude: filters.tagNot,
        labelFor: (v) {
          final id = int.tryParse(v);
          return id == null ? v : metadata.getTagName(id);
        },
        withInclude: (v) => filters.copyWith(tag: v),
        withExclude: (v) => filters.copyWith(tagNot: v),
      ),
    );

  for (final v in filters.staff) {
    chips.add(
      chip(
        v,
        () => onChanged(
          filters.copyWith(staff: filters.staff.where((x) => x != v).toList()),
        ),
      ),
    );
  }

  for (final v in filters.publisher) {
    chips.add(
      chip(
        v,
        () => onChanged(
          filters.copyWith(
            publisher: filters.publisher.where((x) => x != v).toList(),
          ),
        ),
      ),
    );
  }

  if (filters.ratingLower > 0 || filters.ratingUpper < 100) {
    chips.add(
      chip(
        '${l10n.translate('rating_range')}: '
        '${filters.ratingLower.toInt()}-${filters.ratingUpper.toInt()}',
        () => onChanged(filters.copyWith(ratingLower: 0, ratingUpper: 100)),
      ),
    );
  }

  final isLicensed = filters.isLicensed;
  if (isLicensed != null) {
    chips.add(
      chip(
        '${l10n.translate('licensed_status')}: ${yesNo(isLicensed)}',
        () => onChanged(filters.copyWithIsLicensed(null)),
      ),
    );
  }

  final hasAnime = filters.hasAnime;
  if (hasAnime != null) {
    chips.add(
      chip(
        '${l10n.translate('has_anime')}: ${yesNo(hasAnime)}',
        () => onChanged(filters.copyWithHasAnime(null)),
      ),
    );
  }

  final lower = filters.publishedYearLower;
  final upper = filters.publishedYearUpper;
  if (lower != null || upper != null) {
    final yearText = lower != null && upper != null
        ? '$lower-$upper'
        : (lower != null ? '>= $lower' : '<= $upper');
    chips.add(
      chip(
        '${l10n.translate('publication_year')}: $yearText',
        () => onChanged(
          filters.copyWithYear(publishedYearLower: null, publishedYearUpper: null),
        ),
      ),
    );
  }

  return chips;
}
