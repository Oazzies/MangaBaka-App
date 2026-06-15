import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/mb_card.dart';

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
    final start = series.published?['start_date']?.toString() ?? '';
    final end = series.published?['end_date']?.toString() ?? '';
    String? dateRange;
    if (start.isNotEmpty || end.isNotEmpty) {
      dateRange = end.isNotEmpty && end != start ? '$start – $end' : start;
    }

    final rows = <Widget>[
      if (series.type.isNotEmpty)
        _Row(label: l10n.translate('type'), value: _cap(series.type)),
      if (series.status.isNotEmpty)
        _Row(label: l10n.translate('status'), value: _cap(series.status), accent: true),
      if (dateRange != null && dateRange.isNotEmpty)
        _Row(label: l10n.translate('published'), value: dateRange),
      if (series.year.isNotEmpty && series.year != 'null' && dateRange == null)
        _Row(label: l10n.translate('year'), value: series.year),
      if (_validNum(series.totalChapters) != null)
        _Row(label: l10n.translate('chapters'), value: series.totalChapters),
      if (_validNum(series.finalVolume) != null)
        _Row(label: l10n.translate('volumes'), value: series.finalVolume),
      if (series.authors.isNotEmpty)
        _LinkedRow(
          label: l10n.translate('authors'),
          items: series.authors,
          onTap: onAuthorTap,
        ),
      if (series.artists.isNotEmpty)
        _LinkedRow(
          label: l10n.translate('artists'),
          items: series.artists,
          onTap: onAuthorTap,
        ),
      if (series.publishers.isNotEmpty)
        _LinkedRow(
          label: l10n.translate('publishers'),
          items: series.publishers,
          onTap: onPublisherTap,
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

  const _Row({
    required this.label,
    required this.value,
    this.accent = false,
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
            style: AppTypography.monoLabel(
              color: AppConstants.textMutedColor,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.sans(
              color: accent ? AppConstants.accentColor : AppConstants.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkedRow extends StatelessWidget {
  final String label;
  final List<String> items;
  final Function(String)? onTap;

  const _LinkedRow({
    required this.label,
    required this.items,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final plainStyle = AppTypography.sans(
      color: AppConstants.textColor,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.4,
    );

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
                  child: Text(items[i], style: plainStyle),
                ),
                if (i < items.length - 1)
                  Text(', ', style: plainStyle),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
