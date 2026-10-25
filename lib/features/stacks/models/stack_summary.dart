import 'package:mangabaka_app/core/utils/json_utils.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';

int _int(Object? v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;

DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse('$v');

/// The person a stack belongs to.
class StackOwner {
  final String name;

  /// Null for an account that was deleted.
  final String? username;

  const StackOwner({required this.name, this.username});

  factory StackOwner.fromJson(Object? json) {
    if (json is! Map) return const StackOwner(name: '');
    final username = json['username']?.toString();
    final name = json['name']?.toString() ?? '';
    return StackOwner(
      name: name.isNotEmpty ? name : (username ?? ''),
      username: (username == null || username.isEmpty) ? null : username,
    );
  }

  /// What to print as the author: the display name, else the username.
  String get display => name.isNotEmpty ? name : (username ?? '');
}

/// One of the covers a stack listing shows as its preview.
class StackCover {
  final String seriesId;
  final String url;
  final String? blurhash;

  const StackCover({required this.seriesId, required this.url, this.blurhash});

  static StackCover? tryParse(Object? json) {
    if (json is! Map) return null;
    final map = json.cast<String, dynamic>();
    final url = JsonUtils.getCover(map);
    if (url.isEmpty) return null;
    final cover = map['cover'];
    return StackCover(
      seriesId: map['series_id']?.toString() ?? '',
      url: url,
      blurhash: cover is Map ? cover['blurhash']?.toString() : null,
    );
  }
}

/// A stack as listings return it: everything but the description and the
/// entries.
///
/// Counts in listings can be up to an hour old; the live figures come from
/// `GET /v2/my/stacks/status` (see `StackStatus`).
class StackSummary {
  final int id;
  final String title;
  final String canonicalUrl;
  final StackKind kind;
  final StackVisibility visibility;

  /// `safe` / `suggestive` / `erotica` / `pornographic`. At most 10% of the
  /// stack's series may be rated higher.
  final String contentRating;
  final bool isSpoiler;
  final bool isFeatured;
  final StackOwner owner;

  /// Entries, placeholders for merged or deleted series included.
  final int entryCount;
  final int voteCount;
  final int saveCount;
  final DateTime? firstPublishedAt;
  final DateTime? updatedAt;
  final List<StackCover> covers;

  const StackSummary({
    required this.id,
    required this.title,
    required this.canonicalUrl,
    this.kind = StackKind.personal,
    this.visibility = StackVisibility.public,
    this.contentRating = 'safe',
    this.isSpoiler = false,
    this.isFeatured = false,
    this.owner = const StackOwner(name: ''),
    this.entryCount = 0,
    this.voteCount = 0,
    this.saveCount = 0,
    this.firstPublishedAt,
    this.updatedAt,
    this.covers = const [],
  });

  factory StackSummary.fromJson(Map<String, dynamic> json) {
    final id = _int(json['id']);
    if (id <= 0) throw const FormatException('stack without an id');
    return StackSummary(
      id: id,
      title: json['title']?.toString() ?? '',
      canonicalUrl:
          json['canonical_url']?.toString() ??
          'https://mangabaka.org/stacks/$id',
      kind: StackKind.parse(json['kind']),
      visibility: StackVisibility.parse(json['visibility']),
      contentRating: JsonUtils.stringOr(json['content_rating'], 'safe'),
      isSpoiler: json['is_spoiler'] == true,
      isFeatured: json['is_featured'] == true,
      owner: StackOwner.fromJson(json['owner']),
      entryCount: _int(json['entry_count']),
      voteCount: _int(json['vote_count']),
      saveCount: _int(json['save_count']),
      firstPublishedAt: _date(json['first_published_at']),
      updatedAt: _date(json['updated_at']),
      covers: [
        for (final c in (json['covers'] is List ? json['covers'] as List : []))
          if (StackCover.tryParse(c) case final cover?) cover,
      ],
    );
  }

  StackSummary copyWith({
    String? title,
    StackVisibility? visibility,
    String? contentRating,
    bool? isSpoiler,
    int? entryCount,
    int? voteCount,
    int? saveCount,
    List<StackCover>? covers,
    DateTime? updatedAt,
  }) => StackSummary(
    id: id,
    title: title ?? this.title,
    canonicalUrl: canonicalUrl,
    kind: kind,
    visibility: visibility ?? this.visibility,
    contentRating: contentRating ?? this.contentRating,
    isSpoiler: isSpoiler ?? this.isSpoiler,
    isFeatured: isFeatured,
    owner: owner,
    entryCount: entryCount ?? this.entryCount,
    voteCount: voteCount ?? this.voteCount,
    saveCount: saveCount ?? this.saveCount,
    firstPublishedAt: firstPublishedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    covers: covers ?? this.covers,
  );
}

/// Shared parsing for the int helpers, for sibling model files.
int stackInt(Object? v) => _int(v);
DateTime? stackDate(Object? v) => _date(v);
