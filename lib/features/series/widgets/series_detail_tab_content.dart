import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/related_series.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/widgets/tabs/series_covers_tab.dart';
import 'package:mangabaka_app/features/series/widgets/tabs/series_related_tab.dart';
import 'package:mangabaka_app/features/series/widgets/tabs/series_similar_tab.dart';
import 'package:mangabaka_app/features/series/widgets/tabs/series_news_tab.dart';
import 'package:mangabaka_app/features/series/widgets/tabs/series_collections_tab.dart';
import 'package:mangabaka_app/features/series/widgets/tabs/series_works_tab.dart';
import 'package:mangabaka_app/features/series/widgets/series_details_grid.dart';
import 'package:mangabaka_app/features/series/models/series_cover.dart';
import 'package:mangabaka_app/features/news/models/news.dart';
import 'package:mangabaka_app/features/series/models/series_collection.dart';
import 'package:mangabaka_app/features/series/models/series_work.dart';
import 'package:mangabaka_app/features/series/models/series_link.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/series/services/series_list_deps.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_status_controller.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';
import 'package:mangabaka_app/features/stacks/widgets/series_stacks_tab.dart';

class SeriesDetailTabContent extends StatelessWidget {
  final Series series;
  final LibraryEntry? entry;
  final LocalizationService l10n;
  final String selectedTab;
  final List<SeriesCover>? covers;
  final List<RelatedSeries>? related;
  final List<Series>? similar;
  final List<Series>? readersAlsoLike;
  final List<News>? news;
  final List<SeriesCollection>? collections;
  final List<SeriesWork>? works;
  final List<SeriesLink>? enrichedLinks;
  final SeriesListDeps deps;
  final MetadataService metadata;
  final StackService stackService;
  final StackStatusController stackStatus;
  final bool isWide;
  final double hPadding;
  final bool wideRightPaddingOnly;

  const SeriesDetailTabContent({
    super.key,
    required this.series,
    required this.entry,
    required this.l10n,
    required this.selectedTab,
    this.covers,
    this.related,
    this.similar,
    this.readersAlsoLike,
    this.news,
    this.collections,
    this.works,
    this.enrichedLinks,
    required this.deps,
    required this.metadata,
    required this.stackService,
    required this.stackStatus,
    this.isWide = false,
    this.hPadding = 16.0,
    this.wideRightPaddingOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (selectedTab) {
      case 'Covers':
        return SeriesCoversTab(
          covers: covers,
          horizontalPadding: hPadding,
          contentRating: series.contentRating,
        );
      case 'Related':
        return SeriesRelatedTab(
          related: related,
          l10n: l10n,
          deps: deps,
          horizontalPadding: hPadding,
          currentSeriesId: series.id,
          heroTagPrefix: 'related',
        );
      case 'Similar':
        return SeriesSimilarTab(
          similar: similar,
          readersAlsoLike: readersAlsoLike,
          l10n: l10n,
          deps: deps,
          horizontalPadding: hPadding,
          currentSeriesId: series.id,
        );
      case 'Stacks':
        return SeriesStacksTab(
          series: series,
          service: stackService,
          status: stackStatus,
          horizontalPadding: hPadding,
        );
      case 'News':
        return SeriesNewsTab(news: news, prefetch: deps.prefetch);
      case 'Collections':
        return SeriesCollectionsTab(
          collections: collections,
          horizontalPadding: hPadding,
        );
      case 'Works':
        return SeriesWorksTab(
          works: works,
          horizontalPadding: hPadding,
          fallbackCoverUrl: series.coverUrl,
        );
      case 'Info':
      default:
        return SeriesDetailsGrid(
          series: series,
          enrichedLinks: enrichedLinks,
          l10n: l10n,
          metadata: metadata,
          isWide: isWide,
          horizontalPadding: hPadding,
        );
    }
  }
}
