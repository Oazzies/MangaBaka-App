import 'dart:convert';

import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Disk persistence for the genre and tag vocabularies.
///
/// Split out of `MetadataService` so the service holds only the in-memory
/// indexes and the fetch policy, and the `SharedPreferences` details — key
/// names, encoding, and the fact that a corrupt entry must not be fatal — live
/// in one place.
///
/// Every method degrades rather than throws: metadata is an enrichment layer,
/// and the app is fully usable with raw genre keys if the cache is unreadable.
class MetadataCache {
  static const String genresKey = 'cached_genres';
  static const String tagsKey = 'cached_tags';

  static final _logger = LoggingService.logger;

  /// Reads a cached vocabulary, returning null when it is absent or unusable.
  ///
  /// A decode failure clears the entry: a corrupt value would otherwise fail
  /// on every launch, while dropping it lets the next fetch repopulate it.
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

  /// Writes [encoded] under [key]. A write failure is logged and swallowed —
  /// the in-memory data is already correct, and the only cost is refetching on
  /// the next launch.
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
