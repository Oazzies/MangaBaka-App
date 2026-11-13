part of 'search_utils.dart';

/// A pre-normalized search query for matching against candidate strings.
class PreparedQuery {
  final String rawLower;
  final bool keepApostrophes;
  final String normalized;
  final List<String> words;
  final String compact;

  PreparedQuery._(String query)
    : this._fromNormalized(
        rawLower: query.trim().toLowerCase(),
        keepApostrophes: SearchUtils.containsApostrophe(query),
        normalized: SearchUtils.normalize(
          query,
          keepApostrophes: SearchUtils.containsApostrophe(query),
        ),
      );

  PreparedQuery._fromNormalized({
    required this.rawLower,
    required this.keepApostrophes,
    required this.normalized,
  }) : words = _splitWords(normalized),
       compact = normalized.replaceAll(' ', '');

  static List<String> _splitWords(String normalized) =>
      normalized.isEmpty ? const [] : normalized.split(' ');

  /// True when the query has no non-whitespace characters.
  bool get isEmpty => rawLower.isEmpty;

  /// True when [candidate] matches this query.
  bool matches(String candidate) {
    if (isEmpty) return true;
    if (candidate.isEmpty) return false;
    if (normalized.isEmpty) {
      return candidate.toLowerCase().contains(rawLower);
    }
    final norm = SearchUtils.normalize(
      candidate,
      keepApostrophes: keepApostrophes,
    );
    if (norm.isEmpty) return false;
    if (words.length <= 1) {
      return norm.contains(normalized) ||
          norm.replaceAll(' ', '').contains(compact);
    }
    return words.every(norm.contains) ||
        norm.replaceAll(' ', '').contains(compact);
  }

  /// True when [candidate] starts with this query after normalization.
  bool startsWith(String candidate) {
    if (isEmpty) return true;
    if (candidate.isEmpty) return false;
    if (normalized.isEmpty) {
      return candidate.toLowerCase().startsWith(rawLower);
    }
    final norm = SearchUtils.normalize(
      candidate,
      keepApostrophes: keepApostrophes,
    );
    if (norm.isEmpty) return false;
    return norm.startsWith(normalized) ||
        norm.replaceAll(' ', '').startsWith(compact);
  }

  /// True when [candidate] is an exact match for this query after normalization.
  bool exactMatch(String candidate) {
    if (isEmpty) return candidate.trim().isEmpty;
    if (candidate.isEmpty) return false;
    if (normalized.isEmpty) {
      return candidate.trim().toLowerCase() == rawLower;
    }
    final norm = SearchUtils.normalize(
      candidate,
      keepApostrophes: keepApostrophes,
    );
    if (norm.isEmpty) return false;
    return norm == normalized || norm.replaceAll(' ', '') == compact;
  }
}
