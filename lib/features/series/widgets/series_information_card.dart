import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/mb_card.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';

/// The "Information" metadata card: a vertical list of label / value rows with
/// hairline dividers, matching the design's metadata sidebar.
class SeriesInformationCard extends StatelessWidget {
  final Series series;
  final LocalizationService l10n;
  final Function(String)? onAuthorTap;
  final Function(String)? onPublisherTap;

  const SeriesInformationCard({
    super.key,
    required this.series,
    required this.l10n,
    this.onAuthorTap,
    this.onPublisherTap,
  });

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');

  String? _validNum(String raw) =>
      (raw.isEmpty || raw == 'null') ? null : raw;

  @override
  Widget build(BuildContext context) {
    final detailState = SeriesDetailScreen.of(context);
    final isSelecting = detailState?.drawerFilters != null;

    final start = series.published?['start_date']?.toString() ?? '';
    final end = series.published?['end_date']?.toString() ?? '';
    String? dateRange;
    if (start.isNotEmpty || end.isNotEmpty) {
      dateRange = end.isNotEmpty && end != start ? '$start – $end' : start;
    }

    final yearVal = int.tryParse(start.split('-')[0]) ?? int.tryParse(series.year);

    final isTypeSelected = detailState?.drawerFilters?.type.contains(series.type) ?? false;
    final isStatusSelected = detailState?.drawerFilters?.status.contains(series.status) ?? false;
    final isYearSelected = yearVal != null &&
        detailState?.drawerFilters?.publishedYearLower == yearVal &&
        detailState?.drawerFilters?.publishedYearUpper == yearVal;

    final rows = <Widget>[
      if (series.type.isNotEmpty)
        _Row(
          label: l10n.translate('type'),
          value: _cap(series.type),
          isSelected: isTypeSelected,
          onTap: () {
            if (isSelecting) {
              detailState?.handleTypeToggle(series.type);
            } else {
              detailState?.executeSearchWithFilters(SearchFilters(type: [series.type]));
            }
          },
        ),
      if (series.status.isNotEmpty)
        _Row(
          label: l10n.translate('status'),
          value: _cap(series.status),
          accent: true,
          isSelected: isStatusSelected,
          onTap: () {
            if (isSelecting) {
              detailState?.handleStatusToggle(series.status);
            } else {
              detailState?.executeSearchWithFilters(SearchFilters(status: [series.status]));
            }
          },
        ),
      if (dateRange != null && dateRange.isNotEmpty)
        _Row(
          label: l10n.translate('published'),
          value: dateRange,
          isSelected: isYearSelected,
          onTap: yearVal == null ? null : () {
            if (isSelecting) {
              detailState?.handleYearToggle(yearVal);
            } else {
              detailState?.executeSearchWithFilters(SearchFilters(
                publishedYearLower: yearVal,
                publishedYearUpper: yearVal,
              ));
            }
          },
        ),
      if (series.year.isNotEmpty && series.year != 'null' && dateRange == null)
        _Row(
          label: l10n.translate('year'),
          value: series.year,
          isSelected: isYearSelected,
          onTap: yearVal == null ? null : () {
            if (isSelecting) {
              detailState?.handleYearToggle(yearVal);
            } else {
              detailState?.executeSearchWithFilters(SearchFilters(
                publishedYearLower: yearVal,
                publishedYearUpper: yearVal,
              ));
            }
          },
        ),
      if (_validNum(series.totalChapters) != null)
        _Row(label: l10n.translate('chapters'), value: series.totalChapters),
      if (_validNum(series.finalVolume) != null)
        _Row(label: l10n.translate('volumes'), value: series.finalVolume),
      if (series.authors.isNotEmpty)
        _LinkedRow(
          label: l10n.translate('authors'),
          items: series.authors,
          isSelected: (name) => detailState?.drawerFilters?.staff.contains(name) ?? false,
          onTap: (authorName) {
            if (isSelecting) {
              detailState?.handleStaffToggle(authorName);
            } else {
              onAuthorTap?.call(authorName);
            }
          },
        ),
      if (series.artists.isNotEmpty)
        _LinkedRow(
          label: l10n.translate('artists'),
          items: series.artists,
          isSelected: (name) => detailState?.drawerFilters?.staff.contains(name) ?? false,
          onTap: (artistName) {
            if (isSelecting) {
              detailState?.handleStaffToggle(artistName);
            } else {
              onAuthorTap?.call(artistName);
            }
          },
        ),
      if (series.publishers.isNotEmpty)
        _LinkedRow(
          label: l10n.translate('publishers'),
          items: series.publishers,
          isSelected: (name) => detailState?.drawerFilters?.publisher.contains(name) ?? false,
          onTap: (publisherName) {
            if (isSelecting) {
              detailState?.handlePublisherToggle(publisherName);
            } else {
              onPublisherTap?.call(publisherName);
            }
          },
        ),
      if (series.contentRating.isNotEmpty && series.contentRating != 'null')
        _Row(label: l10n.translate('content_rating'), value: _cap(series.contentRating)),
      _Row(label: 'MangaBaka ID', value: series.id),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i != rows.length - 1) {
        children.add(Divider(height: 1, thickness: 1, color: AppConstants.borderColor));
      }
    }

    return MbCard(
      label: l10n.translate('information'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;
  final VoidCallback? onTap;
  final bool isSelected;

  const _Row({
    required this.label,
    required this.value,
    this.accent = false,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected 
        ? AppConstants.accentColor 
        : (accent ? AppConstants.accentColor : AppConstants.textColor);
    final textWeight = isSelected ? FontWeight.bold : FontWeight.w500;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTypography.monoLabel(
                color: AppConstants.textMutedColor,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.sans(
                color: textColor,
                fontSize: 14,
                fontWeight: textWeight,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedRow extends StatelessWidget {
  final String label;
  final List<String> items;
  final Function(String)? onTap;
  final bool Function(String)? isSelected;

  const _LinkedRow({
    required this.label,
    required this.items,
    this.onTap,
    this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.monoLabel(color: AppConstants.textMutedColor, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Wrap(
            runSpacing: 2,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                GestureDetector(
                  onTap: onTap != null ? () => onTap!(items[i]) : null,
                  behavior: HitTestBehavior.opaque,
                  child: Builder(
                    builder: (context) {
                      final selected = isSelected?.call(items[i]) ?? false;
                      return Text(
                        items[i],
                        style: AppTypography.sans(
                          color: selected ? AppConstants.accentColor : AppConstants.textColor,
                          fontSize: 14,
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                          height: 1.4,
                        ),
                      );
                    }
                  ),
                ),
                if (i < items.length - 1)
                  Text(
                    ', ',
                    style: AppTypography.sans(
                      color: AppConstants.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
