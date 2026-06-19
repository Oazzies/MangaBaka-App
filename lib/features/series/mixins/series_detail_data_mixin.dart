import 'package:flutter/material.dart';
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
  List<Series>? related;
  List<Series>? similar;
  List<News>? news;
  List<SeriesCollection>? collections;
  List<SeriesWork>? works;

  List<SeriesLink>? enrichedLinks;
  Series? fullSeries;
  bool isDataLoaded = false;
  bool fetchError = false;

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
    try {
      final results = await Future.wait([
        seriesService.fetchSeriesLinks(series.id),
        seriesService.fetchSeries(series.id),
      ]);
      
      if (selectedTab != 'Info') {
        fetchTabData(selectedTab);
      }
      
      if (mounted) {
        setState(() {
          enrichedLinks = results[0] as List<SeriesLink>?;
          fullSeries = results[1] as Series?;
          isDataLoaded = true;
          fetchError = false;
        });
      }
    } catch (e) {
      seriesService.logger.warning('Error fetching full data: $e');
      if (mounted) {
        setState(() {
          isDataLoaded = true; 
          fetchError = true;
        });
      }
    }
  }
}
