import 'package:flutter/widgets.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/utils/content_rating_filter.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_status_controller.dart';
import 'package:mangabaka_app/features/stacks/models/stack_detail.dart';
import 'package:mangabaka_app/features/stacks/models/stack_draft.dart';
import 'package:mangabaka_app/features/stacks/models/stack_editor_types.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';

export 'package:mangabaka_app/features/stacks/models/stack_editor_types.dart';

class StackEditorController extends ChangeNotifier {
  final int? stackId;
  final StackService _service;

  StackEditorController({this.stackId, StackService? service})
    : _service = service ?? getIt<StackService>() {
    title.addListener(_touch);
    description.addListener(_touch);
  }

  final TextEditingController title = TextEditingController();
  final TextEditingController description = TextEditingController();
  String contentRating = 'safe';
  bool isSpoiler = false;
  bool commentsEnabled = true;
  StackVisibility visibility = StackVisibility.draft;
  final List<EditableStackEntry> entries = [];

  String? _token;
  bool isSpoilerLocked = false;
  String? minContentRating;

  bool loading = false;
  bool saving = false;
  Object? loadError;
  bool _dirty = false;
  bool _suppressTouch = false;

  bool get isNew => stackId == null;
  bool get dirty => _dirty;

  int get liveCount => entries.where((e) => !e.unavailable).length;

  bool containsSeries(String id) => entries.any((e) => e.seriesId == id);

  void _touch() {
    if (_suppressTouch) return;
    _dirty = true;
    notifyListeners();
  }

  Future<void> load() async {
    final id = stackId;
    if (id == null) return;
    loading = true;
    loadError = null;
    notifyListeners();
    try {
      _apply(await _service.fetchForEdit(id));
    } catch (e) {
      loadError = e;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _apply(StackDetail detail) {
    _suppressTouch = true;
    title.text = detail.title;
    description.text = detail.description ?? '';
    _suppressTouch = false;
    contentRating = detail.summary.contentRating;
    isSpoiler = detail.summary.isSpoiler;
    commentsEnabled = detail.isCommentsEnabled;
    visibility = detail.summary.visibility;
    isSpoilerLocked = detail.isSpoilerLocked;
    minContentRating = detail.minContentRating;
    _token = detail.token;
    entries
      ..clear()
      ..addAll([
        for (final e in detail.entries)
          if (e.seriesId != null)
            EditableStackEntry(
              seriesId: e.seriesId!,
              series: e.series,
              issue: e.issue,
              mergedWith: e.mergedWith,
              note: e.note ?? '',
            ),
      ]);
    _dirty = false;
  }

  bool add(Series series) {
    if (containsSeries(series.id) || entries.length >= StackLimits.entriesMax) {
      return false;
    }
    entries.add(EditableStackEntry(seriesId: series.id, series: series));
    _touch();
    return true;
  }

  void removeAt(int index) {
    entries.removeAt(index);
    _touch();
  }

  /// [newIndex] follows the `onReorderItem` convention: the index after the move.
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final e = entries.removeAt(oldIndex);
    entries.insert(newIndex, e);
    _touch();
  }

  void move(int index, int delta) {
    final to = (index + delta).clamp(0, entries.length - 1);
    if (to == index) return;
    final e = entries.removeAt(index);
    entries.insert(to, e);
    _touch();
  }

  void setNote(int index, String note) {
    entries[index].note = note;
    _touch();
  }

  void replace(int index, Series series) {
    final old = entries[index];
    entries[index] = EditableStackEntry(
      seriesId: series.id,
      series: series,
      note: old.note,
    );
    _touch();
  }

  void setRating(String rating) {
    contentRating = rating;
    _touch();
  }

  void setSpoiler(bool value) {
    if (isSpoilerLocked && !value) return;
    isSpoiler = value;
    _touch();
  }

  void setComments(bool value) {
    commentsEnabled = value;
    _touch();
  }

  void setVisibility(StackVisibility value) {
    visibility = value;
    _touch();
  }

  static int _ratingIndex(String r) => ContentRatingFilter.all.indexOf(r);

  List<StackEditorProblem> get problems {
    final t = title.text.trim();
    final min = minContentRating;
    return [
      if (t.isEmpty) StackEditorProblem.titleMissing,
      if (t.length > StackLimits.titleMax) StackEditorProblem.titleTooLong,
      if (description.text.trim().length > StackLimits.descriptionMax)
        StackEditorProblem.descriptionTooLong,
      if (entries.any((e) => e.note.trim().length > StackLimits.noteMax))
        StackEditorProblem.noteTooLong,
      if (entries.length > StackLimits.entriesMax)
        StackEditorProblem.tooManyEntries,
      if (visibility.isListed && liveCount < StackLimits.publishMin)
        StackEditorProblem.tooFewToPublish,
      if (min != null && _ratingIndex(contentRating) < _ratingIndex(min))
        StackEditorProblem.ratingBelowMinimum,
    ];
  }

  bool get canSave => !saving && problems.isEmpty;

  /// The API refuses a stack with over 10% of its series rated above it (`rating_below_floor`).
  bool get ratingTooLow {
    final rated = entries.where((e) => e.series != null).toList();
    if (rated.isEmpty) return false;
    final mine = _ratingIndex(contentRating);
    final above = rated
        .where(
          (e) => _ratingIndex(e.series!.contentRating.toLowerCase()) > mine,
        )
        .length;
    return above > rated.length * 0.1;
  }

  String get suggestedRating {
    final ratings =
        entries
            .map(
              (e) => _ratingIndex(e.series?.contentRating.toLowerCase() ?? ''),
            )
            .where((i) => i >= 0)
            .toList()
          ..sort();
    if (ratings.isEmpty) return contentRating;
    final allowedAbove = (ratings.length * 0.1).floor();
    final idx = ratings[ratings.length - 1 - allowedAbove];
    return ContentRatingFilter.all[idx];
  }

  StackDraft get draft => StackDraft(
    title: title.text,
    description: description.text,
    contentRating: contentRating,
    isSpoiler: isSpoiler,
    isCommentsEnabled: commentsEnabled,
    visibility: visibility,
    entries: [
      for (final e in entries)
        StackDraftEntry(seriesId: e.seriesId, note: e.note),
    ],
  );

  /// [overwrite] follows a stale-token refusal: it re-reads the token and sends this copy anyway.
  Future<StackDetail> save({bool overwrite = false}) async {
    saving = true;
    notifyListeners();
    try {
      final StackDetail saved;
      final id = stackId;
      if (id == null) {
        var created = await _service.create(draft);
        if (visibility != StackVisibility.draft) {
          await _service.setVisibility(created.id, visibility);
          created = created.copyWith(
            summary: created.summary.copyWith(visibility: visibility),
          );
        }
        saved = created;
      } else {
        var token = _token;
        if (overwrite || token == null) {
          token = (await _service.fetchForEdit(id)).token;
        }
        saved = await _service.update(id, draft, token ?? '');
      }
      _token = saved.token ?? _token;
      _dirty = false;
      getIt<StackStatusController>().markListsChanged();
      return saved;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> reload() => load();

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }
}
