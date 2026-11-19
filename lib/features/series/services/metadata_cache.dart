import 'dart:convert';

import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Never throws: metadata is an enrichment, and the app works with raw genre keys.
class MetadataCache {
  static const String genresKey = 'cached_genres';
  static const String tagsKey = 'cached_tags';

  static final _logger = LoggingService.logger;

  /// A decode failure clears the entry, or a corrupt value fails on every launch.
  Future<List<Map<String, dynamic>>?> read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! List) throw const FormatException('expected a JSON list');
      return decoded
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    } catch (e) {
      _logger.warning('Discarding unreadable metadata cache "$key": $e');
      await _remove(key);
      return null;
    }
  }

  Future<void> write(String key, String encoded) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, encoded);
    } catch (e) {
      _logger.warning('Failed to cache metadata "$key": $e');
    }
  }

  Future<void> _remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e, st) {
      _logger.warning('Failed to remove metadata cache "$key"', e, st);
    }
  }
}
