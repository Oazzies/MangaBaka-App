import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/models/library_sync_status.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/lists/models/library_list.dart';
import 'package:mangabaka_app/features/lists/services/library_lists_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';

/// In-memory lists with replaying streams, so late subscribers see the current state.
class FakeListsService extends Fake implements LibraryListsService {
  List<LibraryList> lists;
  Map<int, Set<String>> members;
  final List<String> calls = [];

  /// Thrown by the next write, then cleared.
  Object? failNext;
  int _nextId = 900;

  FakeListsService({List<LibraryList>? lists, Map<int, Set<String>>? members})
    : lists = lists ?? [],
      members = members ?? {};

  final Set<MultiStreamController<List<LibraryList>>> _listSinks = {};
  final Set<MultiStreamController<Map<int, Set<String>>>> _memberSinks = {};

  Map<int, Set<String>> _copyMembers() => {
    for (final e in members.entries) e.key: {...e.value},
  };

  void emit() {
    for (final c in _listSinks) {
      c.add(List.of(lists));
    }
    for (final c in _memberSinks) {
      c.add(_copyMembers());
    }
  }

  void _write(String call) {
    calls.add(call);
    final error = failNext;
    failNext = null;
    if (error != null) throw error;
  }

  @override
  Stream<List<LibraryList>> watchLists() => Stream.multi((c) {
    c.add(List.of(lists));
    _listSinks.add(c);
    c.onCancel = () => _listSinks.remove(c);
  });

  @override
  Stream<Map<int, Set<String>>> watchMembers() => Stream.multi((c) {
    c.add(_copyMembers());
    _memberSinks.add(c);
    c.onCancel = () => _memberSinks.remove(c);
  });

  @override
  Stream<Set<int>> watchListIdsForSeries(String seriesId) => watchMembers().map(
    (m) => {
      for (final e in m.entries)
        if (e.value.contains(seriesId)) e.key,
    },
  );

  @override
  Future<void> refresh() async => calls.add('refresh');

  @override
  Future<LibraryList> create(String name, {bool isPrivate = false}) async {
    _write('create ${LibraryListRules.normalize(name)} $isPrivate');
    final list = LibraryList(
      id: _nextId++,
      name: LibraryListRules.normalize(name),
      isPrivate: isPrivate,
      createdAt: DateTime(2026, 11, 21),
    );
    lists = [...lists, list];
    emit();
    return list;
  }

  @override
  Future<LibraryList> edit(int id, {String? name, bool? isPrivate}) async {
    _write('edit $id ${name ?? '-'} ${isPrivate ?? '-'}');
    late LibraryList updated;
    lists = [
      for (final l in lists)
        if (l.id == id)
          updated = l.copyWith(name: name, isPrivate: isPrivate)
        else
          l,
    ];
    emit();
    return updated;
  }

  @override
  Future<LibraryList> setPrivate(int id, {required bool isPrivate}) =>
      edit(id, isPrivate: isPrivate);

  @override
  Future<void> delete(int id) async {
    _write('delete $id');
    lists = [
      for (final l in lists)
        if (l.id != id) l,
    ];
    members.remove(id);
    emit();
  }

  @override
  Future<void> setPrivateMany(
    Iterable<int> ids, {
    required bool isPrivate,
  }) async {
    final set = ids.toSet();
    _write('privacy ${set.toList()..sort()} $isPrivate');
    lists = [
      for (final l in lists)
        set.contains(l.id) ? l.copyWith(isPrivate: isPrivate) : l,
    ];
    emit();
  }

  @override
  Future<void> deleteMany(Iterable<int> ids) async {
    final set = ids.toSet();
    _write('deleteMany ${set.toList()..sort()}');
    lists = [
      for (final l in lists)
        if (!set.contains(l.id)) l,
    ];
    members.removeWhere((k, _) => set.contains(k));
    emit();
  }

  @override
  Future<Set<int>> setMembership(
    String seriesId,
    int listId, {
    required bool member,
  }) async {
    _write('${member ? 'add' : 'remove'} $seriesId $listId');
    final set = members[listId] ??= {};
    member ? set.add(seriesId) : set.remove(seriesId);
    emit();
    return {
      for (final e in members.entries)
        if (e.value.contains(seriesId)) e.key,
    };
  }

  @override
  Future<List<String>> setMembershipMany(
    int listId,
    Iterable<String> seriesIds, {
    required bool member,
    void Function(int done)? onProgress,
  }) async {
    for (final id in seriesIds) {
      await setMembership(id, listId, member: member);
    }
    return const [];
  }
}

class FakeEntriesLibrary extends Fake implements LibraryService {
  List<LibraryEntry> entries;
  int syncs = 0;

  FakeEntriesLibrary(this.entries);

  final ValueNotifier<LibrarySyncStatus> _status = ValueNotifier(
    const LibrarySyncStatus(),
  );

  @override
  ValueNotifier<LibrarySyncStatus> get syncStatus => _status;

  @override
  Stream<List<LibraryEntry>> watchEntriesFromDb() =>
      Stream.multi((c) => c.add(entries));

  @override
  Stream<LibraryEntry?> watchEntryFromDb(String seriesId) => Stream.multi(
    (c) => c.add(entries.where((e) => e.series.id == seriesId).firstOrNull),
  );

  @override
  Future<void> syncLibrary({String? state, bool deep = false}) async => syncs++;

  final List<String> created = [];

  /// Thrown by the next create, then cleared.
  Object? failCreate;

  @override
  Future<void> createLibraryEntry(String seriesId, String state) async {
    final error = failCreate;
    failCreate = null;
    if (error != null) throw error;
    created.add('$seriesId $state');
  }
}

class FakeSeriesSearch extends Fake implements SeriesSearchService {
  final List<Series> results;
  final List<String> queries = [];

  FakeSeriesSearch(this.results);

  @override
  Future<List<Series>> searchSeriesByName(
    String query, {
    String? sortBy,
    String? type,
    Map<String, dynamic>? extraParams,
  }) async {
    queries.add(query);
    return results;
  }
}

ApiException apiError(int status) =>
    ApiException(message: 'Failed', statusCode: status);
