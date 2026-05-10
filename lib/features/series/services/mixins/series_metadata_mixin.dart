import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/models/series_link.dart';
import 'package:mangabaka_app/features/series/models/series_cover.dart';
import 'package:mangabaka_app/features/series/models/series_collection.dart';
import 'package:mangabaka_app/features/series/models/series_work.dart';
import 'package:mangabaka_app/features/news/models/news.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

mixin SeriesMetadataMixin {
  final _logger = LoggingService.logger;

  Future<List<SeriesLink>> fetchSeriesLinks(String id) async {
    try {
      final url = Uri.parse("${AppConstants.baseApiUrl}/series/$id/links");
      final response = await http
          .get(url, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Series links fetch timed out'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawData = data['data'];
        if (rawData is List) {
          return rawData.map((l) => SeriesLink.fromJson(l)).toList();
        }
      }
      return [];
    } catch (e) {
      _logger.warning('Error fetching links for $id: $e');
      return [];
    }
  }

  Future<List<SeriesCover>> fetchSeriesCovers(String id) async {
    try {
      final url = Uri.parse("${AppConstants.baseApiUrl}/series/$id/images?limit=50");
      final response = await http
          .get(url, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Series covers fetch timed out'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawData = data['data'];
        if (rawData is List) {
          return rawData.map((l) => SeriesCover.fromJson(l)).toList();
        }
      }
      return [];
    } catch (e) {
      _logger.warning('Error fetching covers for $id: $e');
      return [];
    }
  }

  Future<List<Series>> fetchSeriesRelated(String id) async {
    try {
      final url = Uri.parse("${AppConstants.baseApiUrl}/series/$id/related");
      final response = await http
          .get(url, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Series related fetch timed out'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawData = data['data'];
        if (rawData is List) {
          return rawData.map((l) => Series.fromJson(l)).toList();
        }
      }
      return [];
    } catch (e) {
      _logger.warning('Error fetching related for $id: $e');
      return [];
    }
  }

  Future<List<News>> fetchSeriesNews(String id) async {
    try {
      final url = Uri.parse("${AppConstants.baseApiUrl}/series/$id/news");
      final response = await http
          .get(url, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Series news fetch timed out'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawData = data['data'];
        if (rawData is List) {
          return rawData.map((l) => News.fromJson(l)).toList();
        }
      }
      return [];
    } catch (e) {
      _logger.warning('Error fetching news for $id: $e');
      return [];
    }
  }

  Future<List<SeriesCollection>> fetchSeriesCollections(String id) async {
    try {
      final url = Uri.parse("${AppConstants.baseApiUrl}/series/$id/collections");
      final response = await http
          .get(url, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Series collections fetch timed out'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawData = data['data'];
        if (rawData is List) {
          return rawData.map((l) => SeriesCollection.fromJson(l)).toList();
        }
      }
      return [];
    } catch (e) {
      _logger.warning('Error fetching collections for $id: $e');
      return [];
    }
  }

  Future<List<SeriesWork>> fetchSeriesWorks(String id) async {
    try {
      final url = Uri.parse("${AppConstants.baseApiUrl}/series/$id/works");
      final response = await http
          .get(url, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Series works fetch timed out'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawData = data['data'];
        if (rawData is List) {
          return rawData.map((l) => SeriesWork.fromJson(l)).toList();
        }
      }
      return [];
    } catch (e) {
      _logger.warning('Error fetching works for $id: $e');
      return [];
    }
  }
}
