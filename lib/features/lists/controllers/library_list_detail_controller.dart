import 'package:flutter/foundation.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/library/helpers/library_filter_helper.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/lists/controllers/library_lists_controller.dart';
import 'package:mangabaka_app/features/lists/models/library_list.dart';

/// One list's series: its own search, sort and selection over the shared [lists] data.
class LibraryListDetailController extends ChangeNotifier {
  static const String defaultSort = 'name_asc';

  final LibraryListsController lists;
  final int listId;

  LibraryListDetailController({required this.lists, required this.listId}) {
    lists.addListener(_onLists);
  }

  String _query = '';
  String _sortBy = defaultSort;
  final Set<String> _selected = {};
  bool _disposed = false;

  String get query => _query;
  String get sortBy => _sortBy;
  Set<String> get selected => Set.unmodifiable(_selected);
  bool get isSelecting => _selected.isNotEmpty;

  LibraryList? get list => lists.byId(listId);
  bool get isBusy => lists.isBusy(listId);

  int get total => lists.countOf(listId);

  List<LibraryEntry> get items => LibraryFilterHelper(
    allEntries: lists.entriesOn(listId),
    query: _query,
    contentPreferences: SettingsManager().contentPreferences,
    filters: SearchFilters(sortBy: _sortBy),
  ).getFilteredAndSorted();

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    _notify();
  }

  void setSort(String value) {
    if (value == _sortBy) return;
    _sortBy = value;
    _notify();
  }

  void toggle(String seriesId) {
    if (!_selected.remove(seriesId)) _selected.add(seriesId);
    _notify();
  }

  void selectAll() {
    _selected.addAll(items.map((e) => e.series.id));
    _notify();
  }

  void clearSelection() {
    if (_selected.isEmpty) return;
    _selected.clear();
    _notify();
  }

  /// Returns null on success, otherwise an l10n key.
  Future<String?> removeSelected() async {
    final ids = _selected.toList();
    if (ids.isEmpty) return null;
    final (failed, error) = await lists.setMembershipMany(
      listId,
      ids,
      member: false,
    );
    if (failed == 0) clearSelection();
    return error;
  }

  void _onLists() {
    final members = {for (final e in lists.entriesOn(listId)) e.series.id};
    _selected.removeWhere((id) => !members.contains(id));
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    lists.removeListener(_onLists);
    super.dispose();
  }
}
