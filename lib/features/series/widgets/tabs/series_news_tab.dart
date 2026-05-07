import 'package:flutter/material.dart';
import 'package:bakahyou/features/news/models/news.dart';
import 'package:bakahyou/features/news/widgets/news_list.item.dart';
import 'package:bakahyou/features/series/widgets/series_section_header.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';

class SeriesNewsTab extends StatelessWidget {
  final List<News>? news;
  final double horizontalPadding;

  const SeriesNewsTab({
    super.key, 
    this.news, 
    this.horizontalPadding = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    if (news == null) {
      return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
    }
    final l10n = LocalizationService();
    if (news!.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text(l10n.translate('no_news_available'))));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: SeriesSectionHeader(title: l10n.translate('tab_news')),
        ),
        ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: news!.length,
          itemBuilder: (context, index) {
            // NewsListItem already has a horizontal margin of 16.0
            return NewsListItem(news: news![index], showReferencedSeries: false);
          },
        ),
      ],
    );
  }
}
