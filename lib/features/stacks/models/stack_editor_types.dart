import 'package:flutter/widgets.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/stacks/models/stack_detail.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';

/// One series in the editor's working list.
class EditableStackEntry {
  final String seriesId;
  final Series? series;
  final StackEntryIssue? issue;
  final String? mergedWith;
  String note;

  /// Stable across reorders, for the reorderable list.
  final Key key = UniqueKey();

  EditableStackEntry({
    required this.seriesId,
    this.series,
    this.issue,
    this.mergedWith,
    this.note = '',
  });

  /// Whether the series is gone (merged or deleted): publishing counts only
  /// live series, and a save with one may be refused.
  bool get unavailable => issue != null;

  String get title => series?.title ?? '#$seriesId';
}

/// Why the editor will not save yet.
enum StackEditorProblem {
  titleMissing,
  titleTooLong,
  descriptionTooLong,
  noteTooLong,
  tooManyEntries,

  /// Public or unlisted with fewer than [StackLimits.publishMin] live series.
  tooFewToPublish,

  /// The rating is below the moderator's floor.
  ratingBelowMinimum,
}
