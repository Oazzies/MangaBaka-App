part of 'library_crud_mixin.dart';

Future<void> _updateLibraryEntryRatingImpl(
  LibraryCrudMixin self,
  String seriesId,
  int rating,
) async {
  self.logger.info('Updating library entry rating for $seriesId to: $rating');
  final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
  try {
    final response = await self._sendAuthorized(
      'Update rating',
      (headers) => http.put(
        url,
        headers: headers,
        body: jsonEncode({'rating': rating}),
      ),
    );

    if (response.statusCode != 200) {
      self.logger.severe(
        'Failed to update entry rating for $seriesId. Status: ${response.statusCode}',
      );
      throw ApiException(
        message: 'Failed to update entry rating',
        statusCode: response.statusCode,
        responseBody: response.body,
        code: 'UPDATE_RATING_FAILED',
      );
    }

    await self.database.libraryEntriesDao.updateEntryRating(seriesId, rating);
    self.logger.info(
      'Successfully updated rating for $seriesId to $rating in DB',
    );
  } catch (e, st) {
    self._rethrowAsAppException(e, st, seriesId, 'update entry rating');
  }
}

Future<void> _updateLibraryEntryNoteImpl(
  LibraryCrudMixin self,
  String seriesId,
  String? note,
) async {
  final normalized = (note == null || note.trim().isEmpty) ? null : note.trim();
  self.logger.info('Updating library entry note for $seriesId');
  final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
  try {
    final response = await self._sendAuthorized(
      'Update note',
      (headers) => http.put(
        url,
        headers: headers,
        body: jsonEncode({'note': normalized}),
      ),
    );

    if (response.statusCode != 200) {
      self.logger.severe(
        'Failed to update entry note for $seriesId. Status: ${response.statusCode}',
      );
      throw ApiException(
        message: 'Failed to update entry note',
        statusCode: response.statusCode,
        responseBody: response.body,
        code: 'UPDATE_NOTE_FAILED',
      );
    }

    await self.database.libraryEntriesDao.updateEntryNote(seriesId, normalized);
    self.logger.info('Successfully updated note for $seriesId in DB');
  } catch (e, st) {
    self._rethrowAsAppException(e, st, seriesId, 'update entry note');
  }
}

Future<void> _rollbackProgressImpl(
  LibraryCrudMixin self,
  String seriesId,
  db.LibraryEntryWithSeries? snapshot, {
  int? wroteChapter,
  int? wroteVolume,
  String? wroteState,
}) async {
  if (snapshot == null) return;
  final current = await self.database.libraryEntriesDao.getEntryBySeriesId(
    seriesId,
  );
  if (current == null) return;
  if ((wroteChapter != null &&
          current.libraryEntry.progressChapter != wroteChapter) ||
      (wroteVolume != null &&
          current.libraryEntry.progressVolume != wroteVolume) ||
      (wroteState != null && current.libraryEntry.state != wroteState)) {
    self.logger.info(
      'Skipping progress rollback for $seriesId: superseded by a newer update',
    );
    return;
  }
  if (wroteState != null) {
    await self.database.libraryEntriesDao.updateEntryState(
      seriesId,
      snapshot.libraryEntry.state,
      progressChapter: snapshot.libraryEntry.progressChapter,
      progressVolume: snapshot.libraryEntry.progressVolume,
    );
  } else {
    await self.database.libraryEntriesDao.updateEntryProgress(
      seriesId,
      progressChapter: snapshot.libraryEntry.progressChapter,
      progressVolume: snapshot.libraryEntry.progressVolume,
    );
  }
}

Future<void> _createLibraryEntryImpl(
  LibraryCrudMixin self,
  String seriesId,
  String state,
) async {
  self.logger.info('Creating library entry for $seriesId with state: $state');
  final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
  try {
    final response = await self._sendAuthorized(
      'Create entry',
      (headers) => http.post(
        url,
        headers: headers,
        body: jsonEncode({'state': state}),
      ),
    );

    if (response.statusCode == 201) {
      self.logger.info(
        'Successfully created library entry for $seriesId. Syncing local DB...',
      );
      // The entry exists on the server now. A failed follow-up sync must
      // not be reported as a failed create — the caller would retry and
      // the UI would claim the series was not added when it was.
      try {
        await self.syncLibrary();
      } catch (e) {
        self.logger.warning('Sync after creating $seriesId failed: $e');
      }
    } else {
      self.logger.severe(
        'Failed to create library entry for $seriesId. Status: ${response.statusCode}',
      );
      throw ApiException(
        message: 'Failed to create library entry',
        statusCode: response.statusCode,
        responseBody: response.body,
        code: 'CREATE_ENTRY_FAILED',
      );
    }
  } catch (e, st) {
    self._rethrowAsAppException(e, st, seriesId, 'create library entry');
  }
}

Future<int> _createLibraryEntriesBatchImpl(
  LibraryCrudMixin self,
  List<String> seriesIds,
  String state,
) async {
  final ids = [
    for (final id in seriesIds)
      if (int.tryParse(id) != null) int.parse(id),
  ];
  if (ids.isEmpty) return 0;

  self.logger.info('Batch-adding ${ids.length} series with state: $state');
  final url = Uri.parse('${LibraryConstants.baseUrl}/batch');
  var created = 0;
  var anyAccepted = false;

  try {
    for (var i = 0; i < ids.length; i += LibraryCrudMixin.batchLimit) {
      final chunk = ids.sublist(
        i,
        min(i + LibraryCrudMixin.batchLimit, ids.length),
      );
      final response = await self._sendAuthorized(
        'Batch add',
        (headers) => http.post(
          url,
          headers: headers,
          body: jsonEncode([
            for (final id in chunk) {'series_id': id, 'state': state},
          ]),
        ),
      );

      if (response.statusCode != 200) {
        self.logger.severe('Batch add failed. Status: ${response.statusCode}');
        throw ApiException(
          message: 'Failed to add series to library',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'BATCH_CREATE_FAILED',
        );
      }
      anyAccepted = true;
      // The chunk is already accepted; an unexpected body only costs the
      // count, not the remaining chunks.
      Object? data;
      try {
        final decoded = jsonDecode(response.body);
        data = decoded is Map ? decoded['data'] : null;
      } on FormatException catch (e) {
        self.logger.warning('Batch add response was not JSON: $e');
      }
      if (data is List) {
        created += data
            .where((e) => e is Map && e['action'] == 'created')
            .length;
      }
    }
  } catch (e, st) {
    self._rethrowAsAppException(e, st, 'batch', 'batch add to library');
  } finally {
    if (anyAccepted) {
      try {
        await self.syncLibrary();
      } catch (e) {
        self.logger.warning('Sync after batch add failed: $e');
      }
    }
  }
  return created;
}

Future<void> _deleteEntryImpl(LibraryCrudMixin self, String seriesId) async {
  self.logger.info('Deleting library entry for $seriesId');
  final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
  try {
    // Headers without Content-Type — DELETE has no body.
    final response = await self._sendAuthorized(
      'Delete entry',
      (headers) => http.delete(url, headers: headers),
      json: false,
    );

    if (response.statusCode == 200 || response.statusCode == 404) {
      // 404 means already deleted on the server — still clean up locally.
      self.logger.info(
        'Entry $seriesId deleted from server (or already gone). Updating DB...',
      );
      await self.database.libraryEntriesDao.deleteEntry(seriesId);
    } else {
      self.logger.severe(
        'Failed to delete entry for $seriesId. Status: ${response.statusCode}',
      );
      throw ApiException(
        message: 'Failed to delete library entry',
        statusCode: response.statusCode,
        responseBody: response.body,
        code: 'DELETE_ENTRY_FAILED',
      );
    }
  } catch (e, st) {
    self._rethrowAsAppException(e, st, seriesId, 'delete library entry');
  }
}

Future<void> _clearLibraryImpl(LibraryCrudMixin self) async {
  self.logger.info('User requested full library clear');
  try {
    self.setIsSyncCancelled(true);
    self.resetInitialSyncTask();
    // The invalidated sync loop exits without updating the status, so the
    // syncing flag has to be dropped here or the next sync would be refused.
    self.syncStatus.value = self.syncStatus.value.copyWith(
      isSyncing: false,
      clearError: true,
    );
    await self.database.libraryEntriesDao.deleteAllEntries();
    self.logger.info('Local library database cleared');

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.lastSyncKey);
    await prefs.remove(AppConstants.libraryCursorKey);
    await prefs.remove(_isIncompleteKey);
    self.logger.info('Library sync preferences reset');
  } catch (e, st) {
    self.logger.severe('Failed to clear library', e, st);
  }
}
