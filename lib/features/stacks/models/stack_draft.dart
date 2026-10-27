import 'package:mangabaka_app/features/stacks/models/stack_detail.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';

/// One series as the editor will send it.
class StackDraftEntry {
  final String seriesId;
  final String? note;

  const StackDraftEntry({required this.seriesId, this.note});

  Map<String, dynamic> toJson() => {
    'series_id': int.tryParse(seriesId) ?? seriesId,
    if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
  };
}

/// Everything a stack's owner can set, in the shape the write endpoints take.
///
/// `PUT /v2/my/stacks/{id}` replaces the whole stack, entries included, in
/// the order given, so an update always sends a complete draft.
class StackDraft {
  final String title;
  final String? description;
  final String contentRating;
  final bool isSpoiler;
  final bool isCommentsEnabled;
  final StackVisibility visibility;
  final List<StackDraftEntry> entries;

  const StackDraft({
    required this.title,
    this.description,
    this.contentRating = 'safe',
    this.isSpoiler = false,
    this.isCommentsEnabled = true,
    this.visibility = StackVisibility.draft,
    this.entries = const [],
  });

  /// The draft an existing stack would send unchanged. Entries whose series
  /// could not be read keep their id, so saving does not drop them.
  factory StackDraft.fromDetail(StackDetail detail) => StackDraft(
    title: detail.title,
    description: detail.description,
    contentRating: detail.summary.contentRating,
    isSpoiler: detail.summary.isSpoiler,
    isCommentsEnabled: detail.isCommentsEnabled,
    visibility: detail.summary.visibility,
    entries: [
      for (final e in detail.entries)
        if (e.seriesId != null)
          StackDraftEntry(seriesId: e.seriesId!, note: e.note),
    ],
  );

  String? get _description {
    final d = description?.trim();
    return (d == null || d.isEmpty) ? null : d;
  }

  /// Body for `POST /v2/my/stacks`. New stacks are always drafts.
  Map<String, dynamic> toCreateJson() => {
    'title': title.trim(),
    'description': _description,
    'content_rating': contentRating,
    'is_spoiler': isSpoiler,
    'is_comments_enabled': isCommentsEnabled,
    'entries': [for (final e in entries) e.toJson()],
  };

  /// Body for `PUT /v2/my/stacks/{id}`.
  Map<String, dynamic> toUpdateJson(String token) => {
    ...toCreateJson(),
    'visibility': visibility.apiValue,
    'token': token,
  };
}
