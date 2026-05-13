import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/features/library/services/library_constants.dart';
import 'package:mangabaka_app/utils/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin LibraryCrudMixin on LibraryServiceBase {
  
  Future<void> updateLibraryEntryState(String seriesId, String state) async {
    logger.info('Updating library entry state for $seriesId to: $state');
    final token = await auth.getValidAccessToken();
    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    try {
      final response = await http
          .put(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'User-Agent': LibraryConstants.userAgent,
            },
            body: jsonEncode({'state': state}),
          )
          .timeout(
            const Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Update state request timed out'),
          );

      if (response.statusCode == 401) {
        logger.severe('Unauthorized update state request for $seriesId');
        throw AuthException(message: 'Authentication failed.', code: 'AUTH_FAILED');
      }
      if (response.statusCode != 200) {
        logger.severe('Failed to update entry state for $seriesId. Status: ${response.statusCode}, Body: ${response.body}');
        throw ApiException(
          message: 'Failed to update entry state',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'UPDATE_STATE_FAILED',
        );
      }

      await database.libraryEntriesDao.updateEntryState(seriesId, state);
      logger.info('Successfully updated state for $seriesId to $state in DB');
    } on http.ClientException catch (e, st) {
      logger.severe('ClientException updating entry state for $seriesId', e, st);
      throw NetworkException(message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on SocketException catch (e, st) {
      logger.severe('SocketException updating entry state for $seriesId', e, st);
      throw NetworkException(message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on TimeoutException catch (e, st) {
      logger.severe('TimeoutException updating entry state for $seriesId', e, st);
      throw NetworkException(message: 'Request timed out.', code: 'TIMEOUT', originalError: e, stackTrace: st);
    } catch (e, st) {
      logger.severe('Unexpected error updating entry state for $seriesId', e, st);
      if (e is AppException) rethrow;
      throw AppError(message: 'Failed to update entry state', originalError: e, stackTrace: st);
    }
  }

  Future<void> updateLibraryEntryRating(String seriesId, int rating) async {
    logger.info('Updating library entry rating for $seriesId to: $rating');
    final token = await auth.getValidAccessToken();
    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    try {
      final response = await http
          .put(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'User-Agent': LibraryConstants.userAgent,
            },
            body: jsonEncode({'rating': rating}),
          )
          .timeout(
            const Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Update rating request timed out'),
          );

      if (response.statusCode == 401) {
        logger.severe('Unauthorized update rating request for $seriesId');
        throw AuthException(message: 'Authentication failed.', code: 'AUTH_FAILED');
      }
      if (response.statusCode != 200) {
        logger.severe('Failed to update entry rating for $seriesId. Status: ${response.statusCode}, Body: ${response.body}');
        throw ApiException(
          message: 'Failed to update entry rating',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'UPDATE_RATING_FAILED',
        );
      }

      await database.libraryEntriesDao.updateEntryRating(seriesId, rating);
      logger.info('Successfully updated rating for $seriesId to $rating in DB');
    } on http.ClientException catch (e, st) {
      logger.severe('ClientException updating entry rating for $seriesId', e, st);
      throw NetworkException(message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on SocketException catch (e, st) {
      logger.severe('SocketException updating entry rating for $seriesId', e, st);
      throw NetworkException(message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on TimeoutException catch (e, st) {
      logger.severe('TimeoutException updating entry rating for $seriesId', e, st);
      throw NetworkException(message: 'Request timed out.', code: 'TIMEOUT', originalError: e, stackTrace: st);
    } catch (e, st) {
      logger.severe('Unexpected error updating entry rating for $seriesId', e, st);
      if (e is AppException) rethrow;
      throw AppError(message: 'Failed to update entry rating', originalError: e, stackTrace: st);
    }
  }

  Future<void> updateLibraryEntryProgress(String seriesId, {int? progressChapter, int? progressVolume}) async {
    logger.info('Updating library entry progress for $seriesId - Ch: $progressChapter, Vol: $progressVolume');
    final token = await auth.getValidAccessToken();
    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    
    final body = <String, dynamic>{};
    if (progressChapter != null) body['progress_chapter'] = progressChapter;
    if (progressVolume != null) body['progress_volume'] = progressVolume;

    try {
      final response = await http
          .put(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'User-Agent': LibraryConstants.userAgent,
            },
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Update progress request timed out'),
          );

      if (response.statusCode == 401) {
        logger.severe('Unauthorized update progress request for $seriesId');
        throw AuthException(message: 'Authentication failed.', code: 'AUTH_FAILED');
      }
      if (response.statusCode != 200) {
        logger.severe('Failed to update entry progress for $seriesId. Status: ${response.statusCode}, Body: ${response.body}');
        throw ApiException(
          message: 'Failed to update entry progress',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'UPDATE_PROGRESS_FAILED',
        );
      }

      await database.libraryEntriesDao.updateEntryProgress(seriesId, progressChapter: progressChapter, progressVolume: progressVolume);
      logger.info('Successfully updated progress for $seriesId in DB');
    } on http.ClientException catch (e, st) {
      logger.severe('ClientException updating entry progress for $seriesId', e, st);
      throw NetworkException(message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on SocketException catch (e, st) {
      logger.severe('SocketException updating entry progress for $seriesId', e, st);
      throw NetworkException(message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on TimeoutException catch (e, st) {
      logger.severe('TimeoutException updating entry progress for $seriesId', e, st);
      throw NetworkException(message: 'Request timed out.', code: 'TIMEOUT', originalError: e, stackTrace: st);
    } catch (e, st) {
      logger.severe('Unexpected error updating entry progress for $seriesId', e, st);
      if (e is AppException) rethrow;
      throw AppError(message: 'Failed to update entry progress', originalError: e, stackTrace: st);
    }
  }

  Future<void> createLibraryEntry(String seriesId, String state) async {
    logger.info('Creating library entry for $seriesId with state: $state');
    final token = await auth.getValidAccessToken();
    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'User-Agent': LibraryConstants.userAgent,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'state': state}),
          )
          .timeout(
            const Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Create entry request timed out'),
          );

      if (response.statusCode == 401) {
        logger.severe('Unauthorized create entry request for $seriesId');
        throw AuthException(message: 'Authentication failed.', code: 'AUTH_FAILED');
      }
      if (response.statusCode == 201) {
        logger.info('Successfully created library entry for $seriesId on server. Syncing local DB...');
        await syncLibrary();
      } else {
        logger.severe('Failed to create library entry for $seriesId. Status: ${response.statusCode}, Body: ${response.body}');
        throw ApiException(
          message: 'Failed to create library entry',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'CREATE_ENTRY_FAILED',
        );
      }
    } on http.ClientException catch (e, st) {
      logger.severe('ClientException creating library entry for $seriesId', e, st);
      throw NetworkException(message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on SocketException catch (e, st) {
      logger.severe('SocketException creating library entry for $seriesId', e, st);
      throw NetworkException(message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on TimeoutException catch (e, st) {
      logger.severe('TimeoutException creating library entry for $seriesId', e, st);
      throw NetworkException(message: 'Request timed out.', code: 'TIMEOUT', originalError: e, stackTrace: st);
    } catch (e, st) {
      logger.severe('Unexpected error creating entry for $seriesId', e, st);
      if (e is AppException) rethrow;
      throw AppError(message: 'Failed to create library entry', originalError: e, stackTrace: st);
    }
  }

  Future<void> deleteEntry(String seriesId) async {
    logger.info('Deleting library entry for $seriesId');
    final token = await auth.getValidAccessToken();
    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    try {
      final response = await http
          .delete(url, headers: {
            'Authorization': 'Bearer $token',
            'User-Agent': LibraryConstants.userAgent,
          })
          .timeout(
            const Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Delete entry request timed out'),
          );

      if (response.statusCode == 401) {
        logger.severe('Unauthorized delete request for $seriesId');
        throw AuthException(message: 'Authentication failed.', code: 'AUTH_FAILED');
      }
      if (response.statusCode == 200 || response.statusCode == 404) {
        logger.info('Successfully deleted entry $seriesId from server (or already gone). Updating DB...');
        await database.libraryEntriesDao.deleteEntry(seriesId);
      } else {
        logger.severe('Failed to delete entry for $seriesId. Status: ${response.statusCode}, Body: ${response.body}');
        throw ApiException(
          message: 'Failed to delete library entry',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'DELETE_ENTRY_FAILED',
        );
      }
    } on http.ClientException catch (e, st) {
      logger.severe('ClientException deleting entry for $seriesId', e, st);
      throw NetworkException(message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on SocketException catch (e, st) {
      logger.severe('SocketException deleting entry for $seriesId', e, st);
      throw NetworkException(message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on TimeoutException catch (e, st) {
      logger.severe('TimeoutException deleting entry for $seriesId', e, st);
      throw NetworkException(message: 'Request timed out.', code: 'TIMEOUT', originalError: e, stackTrace: st);
    } catch (e, st) {
      logger.severe('Unexpected error deleting entry for $seriesId', e, st);
      if (e is AppException) rethrow;
      throw AppError(message: 'Failed to delete library entry', originalError: e, stackTrace: st);
    }
  }

  Future<void> clearLibrary() async {
    logger.info('User requested full library clear');
    try {
      setIsSyncCancelled(true);
      resetInitialSyncTask();
      await database.libraryEntriesDao.deleteAllEntries();
      logger.info('Local library database cleared');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.lastSyncKey);
      await prefs.remove('${AppConstants.prefixStorageKey}library_is_incomplete');
      logger.info('Library sync preferences reset');
    } catch (e, st) {
      logger.severe('Failed to clear library', e, st);
    }
  }
}
