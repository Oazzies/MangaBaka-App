import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/features/library/constants/library_constants.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/database/database.dart' as db;
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _isIncompleteKey =
    '${AppConstants.prefixStorageKey}library_is_incomplete';

mixin LibraryCrudMixin on LibraryServiceBase {
  // ── Shared HTTP helpers ───────────────────────────────────────────────────

  /// Standard headers for every library API request.
  Map<String, String> _buildAuthHeaders(String token, {bool json = true}) => {
    'Authorization': 'Bearer $token',
    'User-Agent': LibraryConstants.userAgent,
    if (json) 'Content-Type': 'application/json',
  };

  /// Sends an authenticated library request with the standard timeout. A 401
  /// never comes back from here: [ProfileAuthService.sendAuthorized] refreshes
  /// the session and retries, or throws [SessionExpiredException].
  Future<http.Response> _sendAuthorized(
    String description,
    Future<http.Response> Function(Map<String, String> headers) request, {
    bool json = true,
  }) {
    return auth.sendAuthorized(
      (token) => request(_buildAuthHeaders(token, json: json)).timeout(
        const Duration(seconds: AppConstants.networkTimeoutSeconds),
        onTimeout: () =>
            throw TimeoutException('$description request timed out'),
      ),
    );
  }

  /// Re-throws [e] as an appropriate [AppException] subtype.
  /// Call this from the catch block of every CRUD operation.
  Never _rethrowAsAppException(
    Object e,
    StackTrace st,
    String seriesId,
    String operation,
  ) {
    logger.severe('$operation failed for $seriesId', e, st);
    if (e is AppException) throw e;
    if (e is http.ClientException || e is SocketException) {
      throw NetworkException(
        message: 'Network error.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    }
    if (e is TimeoutException) {
      throw NetworkException(
        message: 'Request timed out.',
        code: 'TIMEOUT',
        originalError: e,
        stackTrace: st,
      );
    }
    throw AppError(
      message: 'Failed to $operation',
      originalError: e,
      stackTrace: st,
    );
  }

  // ── CRUD operations ───────────────────────────────────────────────────────

  Future<void> updateLibraryEntryState(
    String seriesId,
    String state, {
    int? totalChapters,
    int? totalVolumes,
    bool? completeChapters,
    bool? completeVolumes,
  }) async {
    logger.info('Updating library entry state for $seriesId to: $state');
    int? autoProgressChapter;
    int? autoProgressVolume;
    if (state == 'completed') {
      final mode = SettingsManager().autoCompleteChapterProgress;
      final shouldCompleteChapters =
          completeChapters ?? (mode == AutoCompleteProgressMode.always);
      final shouldCompleteVolumes =
          completeVolumes ?? (mode == AutoCompleteProgressMode.always);

      if (shouldCompleteChapters || shouldCompleteVolumes) {
        final existing = await database.libraryEntriesDao.getEntryBySeriesId(
          seriesId,
        );
        if (shouldCompleteChapters) {
          final resolvedTotal =
              totalChapters ??
              int.tryParse(existing?.series.totalChapters ?? '');
          final currentProgress = existing?.libraryEntry.progressChapter ?? 0;
          if (resolvedTotal != null &&
              resolvedTotal > 0 &&
              currentProgress < resolvedTotal) {
            autoProgressChapter = resolvedTotal;
          }
        }
        if (shouldCompleteVolumes) {
          final resolvedVolumes =
              totalVolumes ?? int.tryParse(existing?.series.finalVolume ?? '');
          final currentVolume = existing?.libraryEntry.progressVolume ?? 0;
          if (resolvedVolumes != null &&
              resolvedVolumes > 0 &&
              currentVolume < resolvedVolumes) {
            autoProgressVolume = resolvedVolumes;
          }
        }
      }
    }

    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    try {
      final body = <String, dynamic>{
        'state': state,
        if (autoProgressChapter != null)
          'progress_chapter': autoProgressChapter,
        if (autoProgressVolume != null) 'progress_volume': autoProgressVolume,
      };
      final response = await _sendAuthorized(
        'Update state',
        (headers) => http.put(url, headers: headers, body: jsonEncode(body)),
      );

      if (response.statusCode != 200) {
        logger.severe(
          'Failed to update entry state for $seriesId. Status: ${response.statusCode}',
        );
        throw ApiException(
          message: 'Failed to update entry state',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'UPDATE_STATE_FAILED',
        );
      }

      await database.libraryEntriesDao.updateEntryState(
        seriesId,
        state,
        progressChapter: autoProgressChapter,
        progressVolume: autoProgressVolume,
      );
      logger.info('Successfully updated state for $seriesId to $state in DB');
    } catch (e, st) {
      _rethrowAsAppException(e, st, seriesId, 'update entry state');
    }
  }

  Future<void> updateLibraryEntryRating(String seriesId, int rating) async {
    logger.info('Updating library entry rating for $seriesId to: $rating');
    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    try {
      final response = await _sendAuthorized(
        'Update rating',
        (headers) => http.put(
          url,
          headers: headers,
          body: jsonEncode({'rating': rating}),
        ),
      );

      if (response.statusCode != 200) {
        logger.severe(
          'Failed to update entry rating for $seriesId. Status: ${response.statusCode}',
        );
        throw ApiException(
          message: 'Failed to update entry rating',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'UPDATE_RATING_FAILED',
        );
      }

      await database.libraryEntriesDao.updateEntryRating(seriesId, rating);
      logger.info('Successfully updated rating for $seriesId to $rating in DB');
    } catch (e, st) {
      _rethrowAsAppException(e, st, seriesId, 'update entry rating');
    }
  }

  /// Updates the user's personal note on a library entry.
  ///
  /// Blank or whitespace-only strings are normalized to `null` so the server
  /// and local database clear the note consistently.
  Future<void> updateLibraryEntryNote(String seriesId, String? note) async {
    final normalized = (note == null || note.trim().isEmpty)
        ? null
        : note.trim();
    logger.info('Updating library entry note for $seriesId');
    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    try {
      final response = await _sendAuthorized(
        'Update note',
        (headers) => http.put(
          url,
          headers: headers,
          body: jsonEncode({'note': normalized}),
        ),
      );

      if (response.statusCode != 200) {
        logger.severe(
          'Failed to update entry note for $seriesId. Status: ${response.statusCode}',
        );
        throw ApiException(
          message: 'Failed to update entry note',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'UPDATE_NOTE_FAILED',
        );
      }

      await database.libraryEntriesDao.updateEntryNote(seriesId, normalized);
      logger.info('Successfully updated note for $seriesId in DB');
    } catch (e, st) {
      _rethrowAsAppException(e, st, seriesId, 'update entry note');
    }
  }

  /// Restores local progress to the values captured before an optimistic update.
  ///
  /// Skipped when the row no longer holds what this update wrote: a later
  /// update has landed since (rapid +1 taps), and rolling back to this
  /// update's snapshot would overwrite that newer, possibly successful value.
  Future<void> _rollbackProgress(
    String seriesId,
    db.LibraryEntryWithSeries? snapshot, {
    int? wroteChapter,
    int? wroteVolume,
    String? wroteState,
  }) async {
    if (snapshot == null) return;
    final current = await database.libraryEntriesDao.getEntryBySeriesId(
      seriesId,
    );
    if (current == null) return;
    if ((wroteChapter != null &&
            current.libraryEntry.progressChapter != wroteChapter) ||
        (wroteVolume != null &&
            current.libraryEntry.progressVolume != wroteVolume) ||
        (wroteState != null && current.libraryEntry.state != wroteState)) {
      logger.info(
        'Skipping progress rollback for $seriesId: superseded by a newer update',
      );
      return;
    }
    if (wroteState != null) {
      await database.libraryEntriesDao.updateEntryState(
        seriesId,
        snapshot.libraryEntry.state,
        progressChapter: snapshot.libraryEntry.progressChapter,
        progressVolume: snapshot.libraryEntry.progressVolume,
      );
    } else {
      await database.libraryEntriesDao.updateEntryProgress(
        seriesId,
        progressChapter: snapshot.libraryEntry.progressChapter,
        progressVolume: snapshot.libraryEntry.progressVolume,
      );
    }
  }

  Future<void> updateLibraryEntryProgress(
    String seriesId, {
    int? progressChapter,
    int? progressVolume,
  }) async {
    // Progress is a count; a negative value from a stepper or a typed field
    // would be written locally and sent to the server as-is.
    if (progressChapter != null && progressChapter < 0) progressChapter = 0;
    if (progressVolume != null && progressVolume < 0) progressVolume = 0;

    // Capture state for rollback and auto-completion checks.
    final snapshot = await database.libraryEntriesDao.getEntryBySeriesId(
      seriesId,
    );

    String? autoState;
    if (SettingsManager().autoCompleteSeriesStatus ==
            AutoCompleteProgressMode.always &&
        snapshot != null &&
        snapshot.series.status?.toLowerCase() == 'completed' &&
        snapshot.libraryEntry.state != 'completed') {
      final totalChapters = int.tryParse(snapshot.series.totalChapters ?? '');
      final totalVolumes = int.tryParse(snapshot.series.finalVolume ?? '');
      final prevChapter = snapshot.libraryEntry.progressChapter ?? 0;
      final prevVolume = snapshot.libraryEntry.progressVolume ?? 0;
      final reachedChapters =
          progressChapter != null &&
          totalChapters != null &&
          totalChapters > 0 &&
          prevChapter < totalChapters &&
          progressChapter >= totalChapters;
      final reachedVolumes =
          progressVolume != null &&
          totalVolumes != null &&
          totalVolumes > 0 &&
          prevVolume < totalVolumes &&
          progressVolume >= totalVolumes;

      if (reachedChapters || reachedVolumes) {
        autoState = 'completed';
        if (progressVolume == null &&
            totalVolumes != null &&
            totalVolumes > 0 &&
            prevVolume < totalVolumes) {
          progressVolume = totalVolumes;
        }
        if (progressChapter == null &&
            totalChapters != null &&
            totalChapters > 0 &&
            prevChapter < totalChapters) {
          progressChapter = totalChapters;
        }
      }
    }

    logger.info(
      'Updating library entry progress for $seriesId — Ch: $progressChapter, Vol: $progressVolume${autoState != null ? ', State: $autoState' : ''} (optimistic)',
    );

    if (autoState != null) {
      await database.libraryEntriesDao.updateEntryState(
        seriesId,
        autoState,
        progressChapter: progressChapter,
        progressVolume: progressVolume,
      );
    } else {
      await database.libraryEntriesDao.updateEntryProgress(
        seriesId,
        progressChapter: progressChapter,
        progressVolume: progressVolume,
      );
    }

    try {
      final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');

      final body = <String, dynamic>{
        if (autoState != null) 'state': autoState,
        if (progressChapter != null) 'progress_chapter': progressChapter,
        if (progressVolume != null) 'progress_volume': progressVolume,
      };

      final response = await _sendAuthorized(
        'Update progress',
        (headers) => http.put(url, headers: headers, body: jsonEncode(body)),
      );

      if (response.statusCode != 200) {
        logger.severe(
          'Failed to update entry progress for $seriesId. Status: ${response.statusCode}',
        );
        // Rolled back once, in the catch below.
        throw ApiException(
          message: 'Failed to update entry progress',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'UPDATE_PROGRESS_FAILED',
        );
      }

      logger.info('Successfully updated progress for $seriesId on server');
    } catch (e, st) {
      logger.severe('Error updating entry progress for $seriesId', e, st);
      try {
        await _rollbackProgress(
          seriesId,
          snapshot,
          wroteChapter: progressChapter,
          wroteVolume: progressVolume,
          wroteState: autoState,
        );
      } catch (rollbackError, rollbackStack) {
        // Logged, not thrown: the original failure is the one to report.
        logger.severe(
          'Progress rollback failed for $seriesId',
          rollbackError,
          rollbackStack,
        );
      }
      _rethrowAsAppException(e, st, seriesId, 'update entry progress');
    }
  }

  Future<void> createLibraryEntry(String seriesId, String state) async {
    logger.info('Creating library entry for $seriesId with state: $state');
    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    try {
      final response = await _sendAuthorized(
        'Create entry',
        (headers) => http.post(
          url,
          headers: headers,
          body: jsonEncode({'state': state}),
        ),
      );

      if (response.statusCode == 201) {
        logger.info(
          'Successfully created library entry for $seriesId. Syncing local DB...',
        );
        // The entry exists on the server now. A failed follow-up sync must
        // not be reported as a failed create — the caller would retry and
        // the UI would claim the series was not added when it was.
        try {
          await syncLibrary();
        } catch (e) {
          logger.warning('Sync after creating $seriesId failed: $e');
        }
      } else {
        logger.severe(
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
      _rethrowAsAppException(e, st, seriesId, 'create library entry');
    }
  }

  /// Most entries the batch endpoint takes in one request.
  static const int batchLimit = 100;

  /// Adds many series to the library at once, each in [state].
  ///
  /// Uses `POST /my/library/batch`, which creates missing entries but *patches*
  /// existing ones - so callers should leave out series already in the library,
  /// or their state would be overwritten. Each request is atomic (one bad
  /// series fails its whole chunk of up to [batchLimit]); chunks already
  /// accepted stay accepted, and the local database is re-synced either way.
  ///
  /// Returns how many entries the server reports as newly created.
  Future<int> createLibraryEntriesBatch(
    List<String> seriesIds,
    String state,
  ) async {
    final ids = [
      for (final id in seriesIds)
        if (int.tryParse(id) != null) int.parse(id),
    ];
    if (ids.isEmpty) return 0;

    logger.info('Batch-adding ${ids.length} series with state: $state');
    final url = Uri.parse('${LibraryConstants.baseUrl}/batch');
    var created = 0;
    var anyAccepted = false;

    try {
      for (var i = 0; i < ids.length; i += batchLimit) {
        final chunk = ids.sublist(i, min(i + batchLimit, ids.length));
        final response = await _sendAuthorized(
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
          logger.severe('Batch add failed. Status: ${response.statusCode}');
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
          logger.warning('Batch add response was not JSON: $e');
        }
        if (data is List) {
          created += data
              .where((e) => e is Map && e['action'] == 'created')
              .length;
        }
      }
    } catch (e, st) {
      _rethrowAsAppException(e, st, 'batch', 'batch add to library');
    } finally {
      if (anyAccepted) {
        try {
          await syncLibrary();
        } catch (e) {
          logger.warning('Sync after batch add failed: $e');
        }
      }
    }
    return created;
  }

  Future<void> deleteEntry(String seriesId) async {
    logger.info('Deleting library entry for $seriesId');
    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    try {
      // Headers without Content-Type — DELETE has no body.
      final response = await _sendAuthorized(
        'Delete entry',
        (headers) => http.delete(url, headers: headers),
        json: false,
      );

      if (response.statusCode == 200 || response.statusCode == 404) {
        // 404 means already deleted on the server — still clean up locally.
        logger.info(
          'Entry $seriesId deleted from server (or already gone). Updating DB...',
        );
        await database.libraryEntriesDao.deleteEntry(seriesId);
      } else {
        logger.severe(
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
      _rethrowAsAppException(e, st, seriesId, 'delete library entry');
    }
  }

  Future<void> clearLibrary() async {
    logger.info('User requested full library clear');
    try {
      setIsSyncCancelled(true);
      resetInitialSyncTask();
      // The invalidated sync loop exits without updating the status, so the
      // syncing flag has to be dropped here or the next sync would be refused.
      syncStatus.value = syncStatus.value.copyWith(
        isSyncing: false,
        clearError: true,
      );
      await database.libraryEntriesDao.deleteAllEntries();
      logger.info('Local library database cleared');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.lastSyncKey);
      await prefs.remove(AppConstants.libraryCursorKey);
      await prefs.remove(_isIncompleteKey);
      logger.info('Library sync preferences reset');
    } catch (e, st) {
      logger.severe('Failed to clear library', e, st);
    }
  }
}
