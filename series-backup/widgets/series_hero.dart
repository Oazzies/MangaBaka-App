import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/features/series/models/series.dart';

/// Kicker (mono) + serif title + alternate titles + byline. Sits beside the
/// cover in the banner hero.
class SeriesTitleBlock extends StatelessWidget {
  final Series series;
  final String title;
  final bool isWide;
  final CrossAxisAlignment crossAxisAlignment;

  const SeriesTitleBlock({
    super.key,
    required this.series,
    required this.title,
    required this.isWide,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  String _buildKicker() {
    final parts = <String>[];
    if (series.type.isNotEmpty && series.type.toLowerCase() != 'null') {
      parts.add(series.type.toUpperCase());
    }
    final rating = series.rating;
    final parsed = double.tryParse(rating);
    if (parsed != null && parsed > 0) {
      parts.add('★ ${parsed.toStringAsFixed(1)}');
    }
    return parts.join('   ·   ');
  }

  String _buildByline(LocalizationService l10n) {
    final authors = series.authors.where((a) => a.trim().isNotEmpty).toList();
    final artists = series.artists.where((a) => a.trim().isNotEmpty).toList();
    if (authors.isEmpty && artists.isEmpty) return '';
    // Same person wrote & drew it → single "Story & Art by" credit.
    if (artists.isEmpty ||
        (authors.length == artists.length &&
            authors.toSet().containsAll(artists))) {
      return '${l10n.translate('story_and_art_by')} ${authors.join(', ')}';
    }
    final pieces = <String>[];
    if (authors.isNotEmpty) {
      pieces.add('${l10n.translate('story_by')} ${authors.join(', ')}');
    }
    if (artists.isNotEmpty) {
      pieces.add('${l10n.translate('art_by')} ${artists.join(', ')}');
    }
    return pieces.join('  ·  ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final kicker = _buildKicker();
    final byline = _buildByline(l10n);

    final otherTitles = <String>[];
    void addTitle(String t) {
      if (t.isNotEmpty && t != title && !otherTitles.contains(t)) {
        otherTitles.add(t);
      }
    }

    addTitle(series.nativeTitle);
    addTitle(series.romanizedTitle);

    final textAlign =
        crossAxisAlignment == CrossAxisAlignment.center ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (kicker.isNotEmpty) ...[
          Text(
            kicker,
            textAlign: textAlign,
            style: AppTypography.monoLabel(
              color: AppConstants.accentColor,
              fontSize: isWide ? 12 : 10.5,
            ),
          ),
          const SizedBox(height: 10),
        ],
        GestureDetector(
          onTap: () => Clipboard.setData(ClipboardData(text: title)),
          child: Text(
            title,
            textAlign: textAlign,
            style: AppTypography.serif(
              color: AppConstants.textColor,
              fontSize: isWide ? 42 : 27,
              fontWeight: FontWeight.w500,
              height: 1.04,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (otherTitles.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            otherTitles.first,
            textAlign: textAlign,
            style: AppTypography.sans(
              color: AppConstants.textMutedColor,
              fontSize: isWide ? 16 : 13.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (byline.isNotEmpty) ...[
          SizedBox(height: otherTitles.isNotEmpty ? 8 : 10),
          Text(
            byline,
            textAlign: textAlign,
            style: AppTypography.sans(
              color: AppConstants.textColor.withValues(alpha: 0.78),
              fontSize: isWide ? 14.5 : 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// Small helper so callers don't depend on WidgetUtils directly for the banner.
Widget seriesBannerImage(Series series, {required int memCacheWidth}) {
  return WidgetUtils.networkImage(
    url: series.coverUrl,
    fit: BoxFit.cover,
    memCacheWidth: memCacheWidth,
  );
}
