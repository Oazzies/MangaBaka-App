import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/news/models/news.dart';
import 'package:bakahyou/features/news/widgets/news_list.item.dart';

class SeriesNewsTab extends StatelessWidget {
  final List<News>? news;

  const SeriesNewsTab({super.key, this.news});

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
        _buildSectionHeader('Series News'),
        ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: news!.length,
          itemBuilder: (context, index) {
            return NewsListItem(news: news![index], showReferencedSeries: false);
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConstants.textColor, letterSpacing: 0.5)),
    );
  }
}
