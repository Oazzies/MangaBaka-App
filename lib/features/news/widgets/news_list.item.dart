import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mangabaka_app/features/news/models/news.dart';
import 'package:mangabaka_app/features/news/widgets/referenced_list_item.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsListItem extends StatelessWidget {
  final News news;

  const NewsListItem({Key? key, required this.news}) : super(key: key);

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final dt = DateTime.parse(date);
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
                        onTap: () => launchUrl(Uri.parse(news.url)),
                        child: Text(
                          news.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By ${news.author} published on ${_formatDate(news.publishedAt)} - ${news.source}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('This series was referenced:'),
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
  }
}
