import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';
import 'package:mangabaka_app/models/series.dart';

class SeriesDetailScreen extends StatelessWidget {
  final Series series;

  const SeriesDetailScreen({Key? key, required this.series}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(series.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (series.coverUrl.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(series.coverUrl, height: 250),
                  ),
                ),
              const SizedBox(height: 16),
              Text(series.title, style: Theme.of(context).textTheme.headlineSmall),
              if (series.nativeTitle.isNotEmpty)
                Text(series.nativeTitle, style: Theme.of(context).textTheme.bodyMedium),
              if (series.romanizedTitle.isNotEmpty)
                Text(series.romanizedTitle, style: Theme.of(context).textTheme.bodySmall),
              if (series.secondaryTitles.isNotEmpty)
                WidgetUtils.chipWrap('Secondary Titles', series.secondaryTitles),
              WidgetUtils.infoRow('ID', series.id),
              WidgetUtils.infoRow('State', series.state),
              if (series.mergedWith?.isNotEmpty == true)
                WidgetUtils.infoRow('Merged With', series.mergedWith!),
              WidgetUtils.infoRow('Year', series.year),
              WidgetUtils.infoRow('Status', series.status),
              WidgetUtils.infoRow('Type', series.type),
              WidgetUtils.infoRow('Content Rating', series.contentRating),
              WidgetUtils.infoRow('Rating', series.rating),
              WidgetUtils.infoRow('Final Volume', series.finalVolume),
              WidgetUtils.infoRow('Total Chapters', series.totalChapters),
              WidgetUtils.infoRow('Is Licensed', series.isLicensed),
              WidgetUtils.infoRow('Has Anime', series.hasAnime),
              WidgetUtils.infoRow('Last Updated', series.lastUpdated),
              if (series.authors.isNotEmpty) WidgetUtils.chipWrap('Authors', series.authors),
              if (series.artists.isNotEmpty) WidgetUtils.chipWrap('Artists', series.artists),
              if (series.publishers.isNotEmpty) WidgetUtils.chipWrap('Publishers', series.publishers),
              WidgetUtils.chipWrap('Genres', series.genres),
              WidgetUtils.chipWrap('Tags', series.tags, color: Colors.grey[200]),
              const SizedBox(height: 8),
              if (series.description.isNotEmpty)
                Text(series.description, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              if (series.links.isNotEmpty) WidgetUtils.linkList(series.links),
              WidgetUtils.mapSection('Published', series.published),
              WidgetUtils.mapSection('Anime', series.anime),
              WidgetUtils.mapSection('Relationships', series.relationships),
              WidgetUtils.mapSection('Source', series.source),
            ],
          ),
        ),
      ),
    );
  }
}