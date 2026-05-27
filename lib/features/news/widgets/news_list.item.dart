import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mangabaka_app/features/news/models/news.dart';
import 'package:mangabaka_app/features/news/widgets/referenced_list_item.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/services/series_id_service.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';

/// Parses an ISO-8601 date string into a human-readable "MMM d, yyyy" label.
/// Returns the raw string on parse failure, or empty string for empty input.
String _formatDate(String date) {
  if (date.isEmpty) return '';
  try {
    return DateFormat('MMM d, yyyy').format(DateTime.parse(date));
  } catch (_) {
    return date;
  }
}

class NewsListItem extends StatelessWidget {
  final News news;
  final bool showReferencedSeries;

  const NewsListItem({
    super.key,
    required this.news,
    this.showReferencedSeries = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final publishedDate = _formatDate(news.publishedAt);

    return Card(
      color: AppConstants.secondaryBackground,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
      ),
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(news.url)),
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.tertiaryBackground,
                      borderRadius: BorderRadius.circular(AppConstants.pillRadius),
                    ),
                    child: Text(
                      news.source.toUpperCase(),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    publishedDate,
                    style: TextStyle(
                      color: AppConstants.textMutedColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                news.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              if (news.author.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '${l10n.translate('by_author')} ${news.author}',
                  style: TextStyle(
                    color: AppConstants.textMutedColor,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
              if (showReferencedSeries && news.series.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  '${l10n.translate('series_referenced')} (${news.series.length})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppConstants.textMutedColor,
                  ),
                ),
                const SizedBox(height: 10),
                RepaintBoundary(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: news.series.map((s) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: MouseRegion(
                            onEnter: (_) => getIt<SeriesService>().fetchSeries(s.id),
                            child: ReferencedListItem(
                              key: ValueKey('ref_${news.id}_${s.id}'),
                              series: s,
                              compact: true,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
