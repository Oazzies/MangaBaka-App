import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/widgets/tabs/series_covers_tab.dart';
import 'package:mangabaka_app/features/series/widgets/tabs/series_related_tab.dart';
import 'package:mangabaka_app/features/series/widgets/tabs/series_news_tab.dart';
import 'package:mangabaka_app/features/series/widgets/tabs/series_collections_tab.dart';
import 'package:mangabaka_app/features/series/widgets/tabs/series_works_tab.dart';
import 'package:mangabaka_app/features/series/widgets/series_details_grid.dart';
import 'package:mangabaka_app/features/series/models/series_cover.dart';
import 'package:mangabaka_app/features/news/models/news.dart';
import 'package:mangabaka_app/features/series/models/series_collection.dart';
import 'package:mangabaka_app/features/series/models/series_work.dart';
import 'package:mangabaka_app/features/series/models/series_link.dart';

class SeriesDetailTabContent extends StatelessWidget {
  final Series series;
  final LibraryEntry? entry;
  final LocalizationService l10n;
  final String selectedTab;
  final List<SeriesCover>? covers;
  final List<Series>? related;
  final List<News>? news;
  final List<SeriesCollection>? collections;
  final List<SeriesWork>? works;
  final List<SeriesLink>? enrichedLinks;
  final bool isWide;
  final double hPadding;
  final bool wideRightPaddingOnly;

  final Function(String)? onAuthorTap;
  final Function(String)? onPublisherTap;
  final VoidCallback? onAddToLibrary;
  final Function(String)? onStateChanged;
  final Function(int)? onRatingChanged;
  final VoidCallback? onUpdateChapter;
  final VoidCallback? onUpdateVolume;

  const SeriesDetailTabContent({
    super.key,
    required this.series,
    required this.entry,
    required this.l10n,
    required this.selectedTab,
    this.covers,
    this.related,
    this.news,
    this.collections,
    this.works,
    this.enrichedLinks,
    this.isWide = false,
    this.hPadding = 16.0,
    this.wideRightPaddingOnly = false,
    this.onAuthorTap,
    this.onPublisherTap,
    this.onAddToLibrary,
    this.onStateChanged,
    this.onRatingChanged,
    this.onUpdateChapter,
    this.onUpdateVolume,
  });

  @override
  Widget build(BuildContext context) {
    final tabPadding = selectedTab == 'News' ? 0.0 : hPadding;

    switch (selectedTab) {
      case 'Covers':
        return SeriesCoversTab(
          covers: covers,
          horizontalPadding: tabPadding,
          contentRating: series.contentRating,
        );
      case 'Related':
        return SeriesRelatedTab(
          related: related,
          l10n: l10n,
          horizontalPadding: tabPadding,
          currentSeriesId: series.id,
          heroTagPrefix: 'related',
        );
      case 'News':
        return SeriesNewsTab(news: news, horizontalPadding: hPadding);
      case 'Collections':
        return SeriesCollectionsTab(collections: collections, horizontalPadding: tabPadding);
      case 'Works':
        return SeriesWorksTab(works: works, horizontalPadding: tabPadding);
      case 'Information':
      default:
        return SeriesDetailsGrid(
          series: series,
          enrichedLinks: enrichedLinks,
          l10n: l10n,
          isWide: isWide,
          horizontalPadding: tabPadding,
          onAuthorTap: onAuthorTap,
          onPublisherTap: onPublisherTap,
          entry: entry,
          onAddToLibrary: onAddToLibrary,
          isInLibrary: entry != null,
          status: series.status,
          relatedSeries: related,
          onStateChanged: onStateChanged,
          onRatingChanged: onRatingChanged,
          onUpdateChapter: onUpdateChapter,
          onUpdateVolume: onUpdateVolume,
        );
    }
  }
}
