import 'package:flutter/material.dart';
import 'package:bakahyou/features/news/models/news.dart';
import 'package:bakahyou/features/news/widgets/news_list.item.dart';
import 'package:bakahyou/features/series/widgets/series_section_header.dart';

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
    if (news!.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No news available.')));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: const SeriesSectionHeader(title: 'Series News'),
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
