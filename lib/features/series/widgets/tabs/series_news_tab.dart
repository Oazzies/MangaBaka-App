import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/news/models/news.dart';
import 'package:mangabaka_app/features/news/widgets/news_list_item.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/services/series_list_deps.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';

class SeriesNewsTab extends StatelessWidget {
  final List<News>? news;
  final SeriesPrefetch prefetch;

  const SeriesNewsTab({super.key, this.news, required this.prefetch});

  @override
  Widget build(BuildContext context) {
    if (news == null) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(32.0), child: MbSpinner()),
      );
    }
    final l10n = LocalizationService();
    if (news!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(l10n.translate('no_news_available')),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: news!.length,
      itemBuilder: (context, index) {
        return NewsListItem(
          key: ValueKey('series_news_${news![index].id}'),
          news: news![index],
          showReferencedSeries: false,
          prefetch: prefetch,
        );
      },
    );
  }
}
