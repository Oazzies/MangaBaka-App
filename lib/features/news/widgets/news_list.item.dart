import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bakahyou/features/news/models/news.dart';
import 'package:bakahyou/features/news/widgets/referenced_list_item.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';


class NewsListItem extends StatelessWidget {
  final News news;

  const NewsListItem({super.key, required this.news});

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final dt = DateTime.parse(date);
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return date;
    }
  }

  String _formatAuthorLine(LocalizationService l10n) {
    final publishedDate = _formatDate(news.publishedAt);
    if (news.author.isEmpty) {
      return '${l10n.translate('published_on')} $publishedDate - ${news.source}';
    }
    return '${l10n.translate('by_author')} ${news.author} ${l10n.translate('published_on').toLowerCase()} $publishedDate - ${news.source}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) {
        final l10n = LocalizationService();
        return Card(
          color: AppConstants.secondaryBackground,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.article_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () => launchUrl(
                              Uri.parse(news.url),
                              mode: SettingsManager().openLinksInApp
                                  ? LaunchMode.platformDefault
                                  : LaunchMode.externalApplication,
                            ),
                            child: Text(
                              news.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatAuthorLine(l10n),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(l10n.translate('series_referenced')),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: GridView.builder(
                    scrollDirection: Axis.horizontal,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      childAspectRatio: 1.5,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: news.series.length,
                    itemBuilder: (context, index) {
                      return ReferencedListItem(series: news.series[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
