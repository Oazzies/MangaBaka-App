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

part 'library_crud_batch_part.dart';
part 'library_crud_progress_part.dart';

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

  Future<void> updateLibraryEntryRating(String seriesId, int rating) =>
      _updateLibraryEntryRatingImpl(this, seriesId, rating);

  /// Updates the user's personal note on a library entry.
  ///
  /// Blank or whitespace-only strings are normalized to `null` so the server
  /// and local database clear the note consistently.
  Future<void> updateLibraryEntryNote(String seriesId, String? note) =>
      _updateLibraryEntryNoteImpl(this, seriesId, note);

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
  }) => _rollbackProgressImpl(
    this,
    seriesId,
    snapshot,
    wroteChapter: wroteChapter,
    wroteVolume: wroteVolume,
    wroteState: wroteState,
  );

  Future<void> updateLibraryEntryProgress(
    String seriesId, {
    int? progressChapter,
    int? progressVolume,
  }) => _updateLibraryEntryProgressImpl(
    this,
    seriesId,
    progressChapter: progressChapter,
    progressVolume: progressVolume,
  );

  Future<void> createLibraryEntry(String seriesId, String state) =>
      _createLibraryEntryImpl(this, seriesId, state);

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
  ) => _createLibraryEntriesBatchImpl(this, seriesIds, state);

  Future<void> deleteEntry(String seriesId) => _deleteEntryImpl(this, seriesId);

  Future<void> clearLibrary() => _clearLibraryImpl(this);
}
