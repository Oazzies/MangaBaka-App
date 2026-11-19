import 'package:flutter/widgets.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/stacks/models/stack_detail.dart';

class EditableStackEntry {
  final String seriesId;
  final Series? series;
  final StackEntryIssue? issue;
  final String? mergedWith;
  String note;

  final Key key = UniqueKey();

  EditableStackEntry({
    required this.seriesId,
    this.series,
    this.issue,
    this.mergedWith,
    this.note = '',
  });

  /// Publishing counts only live series, and a save holding a gone one may be refused.
  bool get unavailable => issue != null;

  String get title => series?.title ?? '#$seriesId';
}

enum StackEditorProblem {
  titleMissing,
  titleTooLong,
  descriptionTooLong,
  noteTooLong,
  tooManyEntries,

  tooFewToPublish,

  /// The rating is below the moderator's floor.
  ratingBelowMinimum,
}
