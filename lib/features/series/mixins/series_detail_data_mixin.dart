import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/related_series.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/models/series_cover.dart';
import 'package:mangabaka_app/features/news/models/news.dart';
import 'package:mangabaka_app/features/series/models/series_collection.dart';
import 'package:mangabaka_app/features/series/models/series_work.dart';
import 'package:mangabaka_app/features/series/models/series_link.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';

mixin SeriesDetailDataMixin<T extends StatefulWidget> on State<T> {
  SeriesService get seriesService;
  Series get series;
  String get selectedTab;

  List<SeriesCover>? covers;
  List<RelatedSeries>? related;
  List<Series>? similar;
  List<Series>? readersAlsoLike;
  List<News>? news;
  List<SeriesCollection>? collections;
  List<SeriesWork>? works;

  List<SeriesLink>? enrichedLinks;
  Series? fullSeries;
  bool isDataLoaded = false;
  bool fetchError = false;

  /// Override to hold fetched data until the push transition is over, so a setState never drops frames.
  @protected
  Future<void> whenReadyToApplyData() async {}

  Future<void> fetchTabData(String tab) async {
    if (!mounted) return;
    final id = series.id;

    try {
      switch (tab) {
        case 'Covers':
          if (covers == null) {
            final data = await seriesService.fetchSeriesCovers(id);
            if (mounted) setState(() => covers = data);
          }
          break;
        case 'Related':
          if (related == null) {
            final data = await seriesService.fetchSeriesRelated(id);
            if (mounted) setState(() => related = data);
          }
          break;
        case 'News':
          if (news == null) {
            final data = await seriesService.fetchSeriesNews(id);
            if (mounted) setState(() => news = data);
          }
          break;
        case 'Collections':
          if (collections == null) {
            final data = await seriesService.fetchSeriesCollections(id);
            if (mounted) setState(() => collections = data);
          }
          break;
        case 'Works':
          if (works == null) {
            final data = await seriesService.fetchSeriesWorks(id);
            if (mounted) setState(() => works = data);
          }
          break;
        case 'Similar':
          // Not awaited: the beta readers-also-like endpoint must never hold up or take down the similar list.
          if (readersAlsoLike == null) {
            seriesService
                .fetchSeriesReadersAlsoLike(id)
                .then((data) {
                  if (mounted) setState(() => readersAlsoLike = data);
                })
                .catchError((Object e) {
                  seriesService.logger.warning(
                    'Error fetching readers-also-like: $e',
                  );
                  if (mounted) setState(() => readersAlsoLike = const []);
                });
          }
          if (similar == null) {
            final data = await seriesService.fetchSeriesSimilar(id);
            if (mounted) setState(() => similar = data);
          }
          break;
      }
    } catch (e) {
      seriesService.logger.warning('Error fetching tab "$tab" data: $e');
      if (mounted) setState(() => fetchError = true);
    }
  }

  Future<void> fetchFullData() async {
    // Not Future.wait: a links failure must not fail the page; only a failed series fetch does.
    final linksFuture = seriesService
        .fetchSeriesLinks(series.id)
        .then<List<SeriesLink>?>((links) => links)
        .catchError((Object e) {
          seriesService.logger.warning('Error fetching series links: $e');
          return null;
        });
    final seriesFuture = seriesService.fetchSeries(series.id);

    try {
      // Series first: its error, arriving while nothing awaited it yet, would be reported as unhandled.
      final full = await seriesFuture;
      final links = await linksFuture;

      if (selectedTab != 'Info') {
        fetchTabData(selectedTab);
      }

      await whenReadyToApplyData();

      if (mounted) {
        setState(() {
          enrichedLinks = links;
          fullSeries = full;
          isDataLoaded = true;
          fetchError = false;
        });
      }
    } catch (e) {
      seriesService.logger.warning('Error fetching full data: $e');
      await whenReadyToApplyData();
      if (mounted) {
        setState(() {
          isDataLoaded = true;
          fetchError = true;
        });
      }
    }
  }
}
