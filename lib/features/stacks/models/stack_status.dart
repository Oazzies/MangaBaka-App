import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';

/// The signed-in reader's standing with one stack, and its live counts.
///
/// Returned by `GET /v2/my/stacks/status` and by every vote / save / follow
/// call. These counts are always current; the ones in listings can be up to
/// an hour old.
class StackStatus {
  final int id;
  final bool hasVoted;
  final bool hasSaved;
  final bool hasFollowed;

  /// How many of the stack's series are in the reader's library.
  final int libraryCount;
  final int voteCount;
  final int saveCount;
  final int followCount;

  const StackStatus({
    required this.id,
    this.hasVoted = false,
    this.hasSaved = false,
    this.hasFollowed = false,
    this.libraryCount = 0,
    this.voteCount = 0,
    this.saveCount = 0,
    this.followCount = 0,
  });

  factory StackStatus.fromJson(Map<String, dynamic> json) => StackStatus(
    id: stackInt(json['id']),
    hasVoted: json['has_voted'] == true,
    hasSaved: json['has_saved'] == true,
    hasFollowed: json['has_followed'] == true,
    libraryCount: stackInt(json['library_count']),
    voteCount: stackInt(json['vote_count']),
    saveCount: stackInt(json['save_count']),
    followCount: stackInt(json['follow_count']),
  );

  StackStatus copyWith({
    bool? hasVoted,
    bool? hasSaved,
    bool? hasFollowed,
    int? voteCount,
    int? saveCount,
    int? followCount,
  }) => StackStatus(
    id: id,
    hasVoted: hasVoted ?? this.hasVoted,
    hasSaved: hasSaved ?? this.hasSaved,
    hasFollowed: hasFollowed ?? this.hasFollowed,
    libraryCount: libraryCount,
    voteCount: voteCount ?? this.voteCount,
    saveCount: saveCount ?? this.saveCount,
    followCount: followCount ?? this.followCount,
  );

  /// What the server will answer after the reader toggles their vote, so
  /// the button can move before it does.
  StackStatus toggledVote() => copyWith(
    hasVoted: !hasVoted,
    voteCount: (voteCount + (hasVoted ? -1 : 1)).clamp(0, 1 << 31),
  );

  /// Saving is independent of following, but unsaving also unfollows.
  StackStatus toggledSave() {
    if (hasSaved) {
      return copyWith(
        hasSaved: false,
        hasFollowed: false,
        saveCount: (saveCount - 1).clamp(0, 1 << 31),
        followCount: hasFollowed ? (followCount - 1).clamp(0, 1 << 31) : null,
      );
    }
    return copyWith(hasSaved: true, saveCount: saveCount + 1);
  }

  /// Following also saves; unfollowing keeps the save.
  StackStatus toggledFollow() {
    if (hasFollowed) {
      return copyWith(
        hasFollowed: false,
        followCount: (followCount - 1).clamp(0, 1 << 31),
      );
    }
    return copyWith(
      hasFollowed: true,
      hasSaved: true,
      followCount: followCount + 1,
      saveCount: hasSaved ? null : saveCount + 1,
    );
  }
}

/// One of the reader's own stacks, seen from a series: whether the series is
/// in it, and whether it can be added.
class MySeriesStack {
  final int id;
  final String title;
  final StackVisibility visibility;
  final int entryCount;

  /// Where the series sits in this stack; null when it is not in it.
  final int? rank;

  /// False when the series is already in it, it is full, or it is locked.
  final bool canAdd;

  const MySeriesStack({
    required this.id,
    required this.title,
    required this.visibility,
    required this.entryCount,
    this.rank,
    this.canAdd = true,
  });

  factory MySeriesStack.fromJson(Map<String, dynamic> json) => MySeriesStack(
    id: stackInt(json['id']),
    title: json['title']?.toString() ?? '',
    visibility: StackVisibility.parse(json['visibility']),
    entryCount: stackInt(json['entry_count']),
    rank: json['rank'] is num ? (json['rank'] as num).toInt() : null,
    canAdd: json['can_add'] != false,
  );

  bool get contains => rank != null;
}
