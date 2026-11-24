part of 'library_lists_controller.dart';

/// Each action returns null on success, otherwise an l10n key for the failure.
extension LibraryListsActions on LibraryListsController {
  /// Notifies nobody itself: screens call it from initState, and the database answers.
  Future<String?> refresh() async {
    if (_refreshing) return null;
    _refreshing = true;
    try {
      await service.refresh();
      return null;
    } catch (e, st) {
      LibraryListsController._logger.warning('Lists: refresh failed', e, st);
      return listErrorKey(e, ListOp.load);
    } finally {
      _refreshing = false;
    }
  }

  /// Pull to refresh: list metadata from the API, memberships from the library feed.
  Future<void> syncAll() async {
    await Future.wait([
      refresh(),
      library.syncLibrary().catchError((Object e, StackTrace st) {
        // The library's own status banner reports sync failures.
        LibraryListsController._logger.warning('Lists: sync failed', e, st);
      }),
    ]);
  }

  Future<(LibraryList?, String?)> create(
    String name, {
    bool isPrivate = false,
  }) async {
    final invalid = LibraryListRules.validate(name, all);
    if (invalid != null) return (null, invalid);
    try {
      return (await service.create(name, isPrivate: isPrivate), null);
    } catch (e) {
      return (null, listErrorKey(e, ListOp.create));
    }
  }

  Future<String?> rename(int id, String name) async {
    final invalid = LibraryListRules.validate(name, all, editingId: id);
    if (invalid != null) return invalid;
    final current = byId(id);
    if (current != null && current.name == LibraryListRules.normalize(name)) {
      return null;
    }
    return _run(id, ListOp.rename, () => service.rename(id, name));
  }

  /// Sends only what changed; nothing changed is a success without a request.
  Future<String?> edit(int id, String name, {required bool isPrivate}) async {
    final invalid = LibraryListRules.validate(name, all, editingId: id);
    if (invalid != null) return invalid;
    final current = byId(id);
    final normalized = LibraryListRules.normalize(name);
    final newName = current?.name == normalized ? null : normalized;
    final newPrivate = current?.isPrivate == isPrivate ? null : isPrivate;
    if (newName == null && newPrivate == null) return null;
    return _run(
      id,
      newName != null ? ListOp.rename : ListOp.privacy,
      () => service.edit(id, name: newName, isPrivate: newPrivate),
    );
  }

  Future<String?> setPrivate(int id, {required bool isPrivate}) => _run(
    id,
    ListOp.privacy,
    () => service.setPrivate(id, isPrivate: isPrivate),
  );

  Future<String?> delete(int id) =>
      _run(id, ListOp.delete, () => service.delete(id));

  Future<String?> setSelectedPrivate({required bool isPrivate}) async {
    final ids = _selected.toList();
    if (ids.isEmpty) return null;
    final error = await _runMany(
      ids,
      ListOp.batch,
      () => service.setPrivateMany(ids, isPrivate: isPrivate),
    );
    if (error == null) clearSelection();
    return error;
  }

  Future<String?> deleteSelected() async {
    final ids = _selected.toList();
    if (ids.isEmpty) return null;
    final error = await _runMany(
      ids,
      ListOp.batch,
      () => service.deleteMany(ids),
    );
    if (error == null) clearSelection();
    return error;
  }

  Future<String?> setMembership(
    String seriesId,
    int listId, {
    required bool member,
  }) async {
    if (member &&
        !listIdsOf(seriesId).contains(listId) &&
        listIdsOf(seriesId).length >= LibraryListRules.listsPerSeriesMax) {
      return 'lists_error_too_many_lists';
    }
    return _run(
      listId,
      member ? ListOp.addSeries : ListOp.removeSeries,
      () => service.setMembership(seriesId, listId, member: member),
    );
  }

  /// The API only puts series that are in the library on a list, so the entry comes first.
  Future<String?> addToLibraryAndList(
    String seriesId,
    int listId, {
    required String state,
  }) async {
    try {
      await library.createLibraryEntry(seriesId, state);
    } catch (e, st) {
      LibraryListsController._logger.warning(
        'Lists: adding $seriesId to the library failed',
        e,
        st,
      );
      return 'failed_to_add';
    }
    return setMembership(seriesId, listId, member: true);
  }

  /// Returns how many series failed, or throws the error when none succeeded.
  Future<(int failed, String? error)> setMembershipMany(
    int listId,
    Iterable<String> seriesIds, {
    required bool member,
  }) async {
    final op = member ? ListOp.addSeries : ListOp.removeSeries;
    _busy.add(listId);
    _notify();
    try {
      final failed = await service.setMembershipMany(
        listId,
        seriesIds,
        member: member,
      );
      return (failed.length, failed.isEmpty ? null : 'lists_error_partial');
    } catch (e) {
      return (seriesIds.length, listErrorKey(e, op));
    } finally {
      _busy.remove(listId);
      _notify();
    }
  }

  Future<String?> _run(int id, ListOp op, Future<Object?> Function() run) =>
      _runMany([id], op, run);

  Future<String?> _runMany(
    List<int> ids,
    ListOp op,
    Future<Object?> Function() run,
  ) async {
    _busy.addAll(ids);
    _notify();
    try {
      await run();
      return null;
    } catch (e, st) {
      LibraryListsController._logger.warning('Lists: ${op.name} failed', e, st);
      return listErrorKey(e, op);
    } finally {
      _busy.removeAll(ids);
      _notify();
    }
  }
}
