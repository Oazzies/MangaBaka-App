import 'package:mangabaka_app/core/settings/settings_manager.dart';

/// Mix and hidden-gems take the deny-list (`not_content_rating`), so a rating the API adds
/// later is left to the server's default instead of ruled in or out by a stale allow-list.
abstract final class ContentRatingFilter {
  static const List<String> all = [
    'safe',
    'suggestive',
    'erotica',
    'pornographic',
  ];

  /// Empty when nothing was recorded (which permits everything) or every rating is allowed.
  static List<String> excluded(Iterable<String> allowed) {
    final allow = allowed.where((r) => r.isNotEmpty).toSet();
    if (allow.isEmpty) return const [];
    return [
      for (final rating in all)
        if (!allow.contains(rating)) rating,
    ];
  }

  static List<String> excludedByPreference() =>
      excluded(SettingsManager().contentPreferences);
}
