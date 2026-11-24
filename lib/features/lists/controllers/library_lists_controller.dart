import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/lists/models/library_list.dart';
import 'package:mangabaka_app/features/lists/models/library_list_sort.dart';
import 'package:mangabaka_app/features/lists/services/library_list_errors.dart';
import 'package:mangabaka_app/features/lists/services/library_lists_service.dart';

part 'library_lists_actions_part.dart';

/// Lists, their members and the library entries behind them, mirrored from the local database.
class LibraryListsController extends ChangeNotifier {
  static final _logger = LoggingService.logger;

  final LibraryListsService service;
  final LibraryService library;

  /// [watchEntries] false: the owner already watches the library and feeds [setEntries].
  LibraryListsController({
    required this.service,
    required this.library,
    bool watchEntries = true,
  }) {
    _subs = [
      service.watchLists().listen(_onLists, onError: _onStreamError),
      service.watchMembers().listen(_onMembers, onError: _onStreamError),
      if (watchEntries)
        library.watchEntriesFromDb().listen(
          setEntries,
          onError: _onStreamError,
        ),
    ];
    SettingsManager().addListener(_onSettings);
  }

  late final List<StreamSubscription<Object?>> _subs;
  bool _disposed = false;

  List<LibraryList>? _lists;
  Map<int, Set<String>> _members = const {};
  Map<String, LibraryEntry> _entries = const {};
  List<String> _contentPreferences = SettingsManager().contentPreferences;

  String _query = '';
  LibraryListSort _sort = LibraryListSort.nameAsc;
  final Set<int> _selected = {};
  bool _refreshing = false;
  final Set<int> _busy = {};

  bool get isLoaded => _lists != null;
  List<LibraryList> get all => _lists ?? const [];
  String get query => _query;
  LibraryListSort get sort => _sort;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get isSelecting => _selected.isNotEmpty;
  bool isBusy(int id) => _busy.contains(id);

  LibraryList? byId(int id) {
    for (final l in all) {
      if (l.id == id) return l;
    }
    return null;
  }

  bool _visible(LibraryEntry e) =>
      _contentPreferences.isEmpty ||
      _contentPreferences.contains(e.series.contentRating.toLowerCase());

  /// Only series in the local library and allowed by the content settings count.
  List<LibraryEntry> entriesOn(int listId) => [
    for (final id in _members[listId] ?? const <String>{})
      if (_entries[id] case final LibraryEntry e when _visible(e)) e,
  ];

  int countOf(int listId) => entriesOn(listId).length;

  List<LibraryEntry> get libraryEntries => [
    for (final e in _entries.values)
      if (_visible(e)) e,
  ];

  /// Ignores the content settings: a hidden entry is still in the library.
  LibraryEntry? entryFor(String seriesId) => _entries[seriesId];

  Set<int> listIdsOf(String seriesId) => {
    for (final m in _members.entries)
      if (m.value.contains(seriesId)) m.key,
  };

  List<LibraryList> get visible {
    final q = LibraryListRules.key(_query).replaceAll(' ', '');
    final out = [
      for (final l in all)
        if (q.isEmpty ||
            LibraryListRules.key(l.name).replaceAll(' ', '').contains(q))
          l,
    ];
    final counts = {for (final l in out) l.id: countOf(l.id)};
    out.sort((a, b) => _sort.compare(a, b, (l) => counts[l.id] ?? 0));
    return out;
  }

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    _notify();
  }

  void setSort(LibraryListSort value) {
    if (value == _sort) return;
    _sort = value;
    _notify();
  }

  void toggleSelected(int id) {
    if (!_selected.remove(id)) _selected.add(id);
    _notify();
  }

  void selectAll(Iterable<int> ids) {
    _selected.addAll(ids);
    _notify();
  }

  void clearSelection() {
    if (_selected.isEmpty) return;
    _selected.clear();
    _notify();
  }

  void _onLists(List<LibraryList> lists) {
    _lists = lists;
    final ids = {for (final l in lists) l.id};
    _selected.removeWhere((id) => !ids.contains(id));
    _notify();
  }

  void _onMembers(Map<int, Set<String>> members) {
    _members = members;
    _notify();
  }

  void setEntries(List<LibraryEntry> entries) {
    _entries = {for (final e in entries) e.series.id: e};
    _notify();
  }

  void _onSettings() {
    final prefs = SettingsManager().contentPreferences;
    if (listEquals(prefs, _contentPreferences)) return;
    _contentPreferences = prefs;
    _notify();
  }

  void _onStreamError(Object e, StackTrace st) {
    _logger.severe('Lists: local stream failed', e, st);
    _lists ??= const [];
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    SettingsManager().removeListener(_onSettings);
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
