import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mangabaka_app/features/news/models/news.dart';
import 'package:mangabaka_app/features/news/widgets/referenced_list_item.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';

class NewsListItem extends StatelessWidget {
  final News news;
  final bool showReferencedSeries;

  const NewsListItem({
    super.key,
    required this.news,
    this.showReferencedSeries = true,
  });

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final dt = DateTime.parse(date);
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final publishedDate = _formatDate(news.publishedAt);

    return Card(
      color: AppConstants.secondaryBackground,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(news.url)),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      news.source.toUpperCase(),
                      style: TextStyle(
                        color: AppConstants.accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    publishedDate,
                    style: TextStyle(
                      color: AppConstants.textMutedColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                news.title,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              if (news.author.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${l10n.translate('by_author')} ${news.author}',
                  style: TextStyle(
                    color: AppConstants.textMutedColor,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (showReferencedSeries && news.series.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  '${l10n.translate('series_referenced')} (${news.series.length})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textColor.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: news.series.map((s) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: ReferencedListItem(
                          key: ValueKey('ref_${news.id}_${s.id}'),
                          series: s,
                          compact: true,
                        ),
                      );
                    }).toList(),
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


