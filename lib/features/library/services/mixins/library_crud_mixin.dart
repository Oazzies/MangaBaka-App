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
  Map<String, String> _buildAuthHeaders(String token, {bool json = true}) => {
    'Authorization': 'Bearer $token',
    'User-Agent': LibraryConstants.userAgent,
    if (json) 'Content-Type': 'application/json',
  };

  /// Never returns a 401: [ProfileAuthService.sendAuthorized] refreshes and retries, or throws.
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

  Future<void> updateLibraryEntryNote(String seriesId, String? note) =>
      _updateLibraryEntryNoteImpl(this, seriesId, note);

  /// Skipped once a later update (rapid +1 taps) has overwritten this one's write.
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

  /// `POST /my/library/batch` *patches* existing entries: leave out series already in the library.
  /// Each chunk of up to [batchLimit] is atomic; returns how many the server reports as created.
  Future<int> createLibraryEntriesBatch(
    List<String> seriesIds,
    String state,
  ) => _createLibraryEntriesBatchImpl(this, seriesIds, state);

  Future<void> deleteEntry(String seriesId) => _deleteEntryImpl(this, seriesId);

  Future<void> clearLibrary() => _clearLibraryImpl(this);
}
