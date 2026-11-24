import 'package:drift/drift.dart' show Value;
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/database/database.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/lists/models/library_list.dart';
import 'package:mangabaka_app/features/lists/services/library_lists_api.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';

/// Writes go to the API first, then the answer is mirrored into the local copy the UI watches.
class LibraryListsService {
  final AppDatabase _db;
  final LibraryListsApi _api;

  LibraryListsService({
    required AppDatabase database,
    LibraryListsApi? api,
    http.Client? client,
    ProfileAuthService Function()? auth,
  }) : _db = database,
       _api =
           api ??
           LibraryListsApi(
             client: client ?? http.Client(),
             auth: auth ?? () => getIt<ProfileAuthService>(),
           );

  LibraryListsDao get _dao => _db.libraryListsDao;

  Stream<List<LibraryList>> watchLists() =>
      _dao.watchLists().map((rows) => [for (final r in rows) _fromRow(r)]);

  /// List id to the series on it.
  Stream<Map<int, Set<String>>> watchMembers() =>
      _dao.watchMemberships().map((rows) {
        final out = <int, Set<String>>{};
        for (final r in rows) {
          (out[r.listId] ??= <String>{}).add(r.seriesId);
        }
        return out;
      });

  Stream<Set<int>> watchListIdsForSeries(String seriesId) =>
      _dao.watchListIdsForSeries(seriesId);

  Future<void> refresh() async {
    final lists = await _api.fetchAll();
    await _dao.replaceAllLists([for (final l in lists) _companion(l)]);
  }

  Future<LibraryList> create(String name, {bool isPrivate = false}) async {
    final list = await _api.create(
      LibraryListRules.normalize(name),
      isPrivate: isPrivate,
    );
    await _dao.upsertLists([_companion(list)]);
    return list;
  }

  Future<LibraryList> rename(int id, String name) =>
      _update(id, name: LibraryListRules.normalize(name));

  Future<LibraryList> setPrivate(int id, {required bool isPrivate}) =>
      _update(id, isPrivate: isPrivate);

  Future<LibraryList> edit(int id, {String? name, bool? isPrivate}) => _update(
    id,
    name: name == null ? null : LibraryListRules.normalize(name),
    isPrivate: isPrivate,
  );

  Future<LibraryList> _update(int id, {String? name, bool? isPrivate}) async {
    final list = await _api.update(id, name: name, isPrivate: isPrivate);
    await _dao.upsertLists([_companion(list)]);
    return list;
  }

  Future<void> delete(int id) async {
    await _api.delete(id);
    await _dao.deleteLists([id]);
  }

  /// Chunks stay all-or-nothing on the server; each one is mirrored as soon as it lands.
  Future<void> setPrivateMany(
    Iterable<int> ids, {
    required bool isPrivate,
  }) async {
    for (final chunk in _chunks(ids)) {
      await _api.batchSetPrivacy(chunk, isPrivate: isPrivate);
      await _dao.setPrivacy(chunk, isPrivate: isPrivate);
    }
  }

  Future<void> deleteMany(Iterable<int> ids) async {
    for (final chunk in _chunks(ids)) {
      await _api.batchDelete(chunk);
      await _dao.deleteLists(chunk);
    }
  }

  /// Returns the ids of every list the series is on afterwards.
  Future<Set<int>> setMembership(
    String seriesId,
    int listId, {
    required bool member,
  }) async {
    final lists = await _api.setMembership(seriesId, listId, member: member);
    final ids = {for (final l in lists) l.id};
    await _db.transaction(() async {
      await _dao.upsertLists([for (final l in lists) _membershipCompanion(l)]);
      await _dao.setMemberships({seriesId: ids});
    });
    return ids;
  }

  /// One request per series: there is no batch membership endpoint besides library writes.
  Future<List<String>> setMembershipMany(
    int listId,
    Iterable<String> seriesIds, {
    required bool member,
    void Function(int done)? onProgress,
  }) async {
    final failed = <String>[];
    var done = 0;
    Object? firstError;
    for (final id in seriesIds) {
      try {
        await setMembership(id, listId, member: member);
      } catch (e) {
        firstError ??= e;
        failed.add(id);
      }
      onProgress?.call(++done);
    }
    if (failed.isNotEmpty && failed.length == done && firstError != null) {
      throw firstError;
    }
    return failed;
  }

  Iterable<List<int>> _chunks(Iterable<int> ids) sync* {
    final all = ids.toSet().toList();
    for (var i = 0; i < all.length; i += LibraryListRules.batchMax) {
      yield all.sublist(
        i,
        (i + LibraryListRules.batchMax).clamp(0, all.length),
      );
    }
  }

  static LibraryList _fromRow(LibraryListsTableData row) => LibraryList(
    id: row.id,
    name: row.name,
    isPrivate: row.isPrivate,
    createdAt: row.createdAt == null ? null : DateTime.tryParse(row.createdAt!),
    updatedAt: row.updatedAt == null ? null : DateTime.tryParse(row.updatedAt!),
  );

  static LibraryListsTableCompanion _companion(LibraryList l) =>
      LibraryListsTableCompanion(
        id: Value(l.id),
        name: Value(l.name),
        isPrivate: Value(l.isPrivate),
        createdAt: Value(l.createdAt?.toUtc().toIso8601String()),
        updatedAt: Value(l.updatedAt?.toUtc().toIso8601String()),
      );

  /// The membership answer carries no timestamps, so stored ones are kept.
  static LibraryListsTableCompanion _membershipCompanion(LibraryList l) =>
      LibraryListsTableCompanion(
        id: Value(l.id),
        name: Value(l.name),
        isPrivate: Value(l.isPrivate),
      );
}
