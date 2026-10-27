import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';

/// Why an entry no longer shows its series.
enum StackEntryIssue {
  /// Merged into another series ([StackEntry.mergedWith]).
  merged,

  /// Removed from MangaBaka.
  deleted,
}

/// One ranked place in a stack.
///
/// The public endpoint replaces a merged or deleted series with a bare
/// placeholder (`{kind: merged|deleted, rank}`); the owner's endpoint keeps
/// the series and reports the problem in `issue`. Both read into this shape:
/// [series] is null exactly when there is nothing left to show.
class StackEntry {
  final int rank;
  final String? note;
  final Series? series;
  final StackEntryIssue? issue;
  final String? mergedWith;

  /// Series id, kept even when [series] could not be read so the owner's
  /// editor can still send the entry back.
  final String? seriesId;

  const StackEntry({
    required this.rank,
    this.note,
    this.series,
    this.issue,
    this.mergedWith,
    this.seriesId,
  });

  factory StackEntry.fromJson(Map<String, dynamic> json) {
    final kind = json['kind']?.toString();
    final issueJson = json['issue'];
    final issueRaw = kind == 'merged' || kind == 'deleted'
        ? kind
        : (issueJson is Map ? issueJson['state']?.toString() : null);
    final issue = switch (issueRaw) {
      'merged' => StackEntryIssue.merged,
      'deleted' => StackEntryIssue.deleted,
      _ => null,
    };

    Series? series;
    final seriesJson = json['series'];
    if (seriesJson is Map) {
      try {
        series = Series.fromJson(seriesJson.cast<String, dynamic>());
      } catch (_) {
        series = null;
      }
    }
    final note = json['note']?.toString();
    return StackEntry(
      rank: stackInt(json['rank']),
      note: (note == null || note.trim().isEmpty) ? null : note,
      series: series,
      issue: issue,
      mergedWith: issueJson is Map
          ? issueJson['merged_with']?.toString()
          : null,
      seriesId: json['series_id']?.toString() ?? series?.id,
    );
  }

  /// A placeholder: nothing to show but the rank.
  bool get isPlaceholder => series == null;
}

/// A stack with its description and entries.
///
/// The owner-only fields ([token], [isHidden], [isDelisted],
/// [minContentRating], [isSpoilerLocked]) are only filled by
/// `GET /v2/my/stacks/{id}` and the write endpoints.
class StackDetail {
  final StackSummary summary;
  final String? description;
  final bool isCommentsEnabled;
  final List<StackEntry> entries;

  /// The concurrency token the next `PUT` needs. Null on public reads.
  final String? token;
  final bool isHidden;
  final bool isDelisted;
  final String? minContentRating;
  final bool isSpoilerLocked;

  const StackDetail({
    required this.summary,
    this.description,
    this.isCommentsEnabled = true,
    this.entries = const [],
    this.token,
    this.isHidden = false,
    this.isDelisted = false,
    this.minContentRating,
    this.isSpoilerLocked = false,
  });

  factory StackDetail.fromJson(Map<String, dynamic> json) {
    final entries = <StackEntry>[];
    for (final e in (json['entries'] is List ? json['entries'] as List : [])) {
      if (e is! Map) continue;
      try {
        entries.add(StackEntry.fromJson(e.cast<String, dynamic>()));
      } catch (_) {
        // One unreadable entry costs that entry, not the stack.
      }
    }
    entries.sort((a, b) => a.rank.compareTo(b.rank));
    final description = json['description']?.toString();
    final minRating = json['min_content_rating']?.toString();
    return StackDetail(
      summary: StackSummary.fromJson(json),
      description: (description == null || description.trim().isEmpty)
          ? null
          : description,
      isCommentsEnabled: json['is_comments_enabled'] != false,
      entries: entries,
      token: json['token']?.toString(),
      isHidden: json['is_hidden'] == true,
      isDelisted: json['is_delisted'] == true,
      minContentRating: (minRating == null || minRating.isEmpty)
          ? null
          : minRating,
      isSpoilerLocked: json['is_spoiler_locked'] == true,
    );
  }

  int get id => summary.id;
  String get title => summary.title;

  /// Entries that still show a series.
  Iterable<StackEntry> get liveEntries =>
      entries.where((e) => !e.isPlaceholder);

  StackDetail copyWith({StackSummary? summary, String? token}) => StackDetail(
    summary: summary ?? this.summary,
    description: description,
    isCommentsEnabled: isCommentsEnabled,
    entries: entries,
    token: token ?? this.token,
    isHidden: isHidden,
    isDelisted: isDelisted,
    minContentRating: minContentRating,
    isSpoilerLocked: isSpoilerLocked,
  );
}
