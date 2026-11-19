/// `unlisted`: anyone with the link; listed on the owner's profile, never in browse or on series pages.
enum StackVisibility {
  draft,
  unlisted,
  public;

  static StackVisibility parse(Object? raw) => switch (raw?.toString()) {
    'public' => StackVisibility.public,
    'unlisted' => StackVisibility.unlisted,
    _ => StackVisibility.draft,
  };

  String get apiValue => name;

  String get labelKey => 'stacks_visibility_$name';

  bool get isListed => this != StackVisibility.draft;
}

/// `community` is reserved by the API and not in use yet.
enum StackKind {
  personal,
  community,
  official;

  static StackKind parse(Object? raw) => switch (raw?.toString()) {
    'official' => StackKind.official,
    'community' => StackKind.community,
    _ => StackKind.personal,
  };
}

enum StackSort {
  mostVoted('vote_count_desc', 'stacks_sort_most_voted'),
  mostSaved('save_count_desc', 'stacks_sort_most_saved'),
  recentlyUpdated('updated_at_desc', 'stacks_sort_recently_updated'),
  newest('first_published_at_desc', 'stacks_sort_newest');

  final String apiValue;
  final String labelKey;

  const StackSort(this.apiValue, this.labelKey);
}

enum StackSpoilerFilter {
  exclude,
  include,
  only;

  String get apiValue => name;
  String get labelKey => 'stacks_spoilers_$name';
}

enum StackEntrySort {
  stackFirst('stacks_entry_sort_first'),
  stackLast('stacks_entry_sort_last'),
  ratingHigh('stacks_entry_sort_rating_high'),
  ratingLow('stacks_entry_sort_rating_low');

  final String labelKey;

  const StackEntrySort(this.labelKey);
}

/// Values of the error body's `code` when a stack endpoint refuses a request.
abstract final class StackErrorCode {
  static const tooFewEntries = 'too_few_entries';
  static const seriesUnavailable = 'series_unavailable';
  static const ratingBelowFloor = 'rating_below_floor';
  static const ratingBelowMinimum = 'rating_below_minimum';
  static const stackFull = 'stack_full';
  static const duplicateEntry = 'duplicate_entry';
  static const staleToken = 'stale_token';
  static const stackLocked = 'stack_locked';
  static const spoilerLocked = 'spoiler_locked';
  static const usernameRequired = 'username_required';
  static const rateLimited = 'rate_limited';

  /// Every code with a translated message (`stacks_error_<code>`).
  static const known = {
    tooFewEntries,
    seriesUnavailable,
    ratingBelowFloor,
    ratingBelowMinimum,
    stackFull,
    duplicateEntry,
    staleToken,
    stackLocked,
    spoilerLocked,
    usernameRequired,
    rateLimited,
  };
}

/// Mirrors the API's limits so the editor can warn before saving.
abstract final class StackLimits {
  static const int titleMax = 200;
  static const int descriptionMax = 10000;
  static const int noteMax = 5000;
  static const int entriesMax = 100;

  static const int publishMin = 5;

  /// Most stacks `GET /v2/my/stacks/status` takes in one request.
  static const int statusBatch = 50;

  /// Most rows any stack listing returns per page.
  static const int pageMax = 50;
}
