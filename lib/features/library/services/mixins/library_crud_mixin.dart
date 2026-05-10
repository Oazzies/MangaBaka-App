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
        throw AuthException(message: 'Authentication failed.', code: 'AUTH_FAILED');
      }
      if (response.statusCode != 200) {
        throw ApiException(
          message: 'Failed to update entry state',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'UPDATE_STATE_FAILED',
        );
      }

      await database.libraryEntriesDao.updateEntryState(seriesId, state);
    } on http.ClientException catch (e, st) {
      throw NetworkException(message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on SocketException catch (e, st) {
      throw NetworkException(message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on TimeoutException catch (e, st) {
      throw NetworkException(message: 'Request timed out.', code: 'TIMEOUT', originalError: e, stackTrace: st);
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      logger.severe('Unexpected error updating entry state: $e\n$st');
      throw AppError(message: 'Failed to update entry state', originalError: e, stackTrace: st);
    }
  }

  Future<void> updateLibraryEntryRating(String seriesId, int rating) async {
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
        throw AuthException(message: 'Authentication failed.', code: 'AUTH_FAILED');
      }
      if (response.statusCode != 200) {
        throw ApiException(
          message: 'Failed to update entry rating',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'UPDATE_RATING_FAILED',
        );
      }

      await database.libraryEntriesDao.updateEntryRating(seriesId, rating);
    } on http.ClientException catch (e, st) {
      throw NetworkException(message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on SocketException catch (e, st) {
      throw NetworkException(message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on TimeoutException catch (e, st) {
      throw NetworkException(message: 'Request timed out.', code: 'TIMEOUT', originalError: e, stackTrace: st);
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      logger.severe('Unexpected error updating entry rating: $e\n$st');
      throw AppError(message: 'Failed to update entry rating', originalError: e, stackTrace: st);
    }
  }

  Future<void> createLibraryEntry(String seriesId, String state) async {
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
        throw AuthException(message: 'Authentication failed.', code: 'AUTH_FAILED');
      }
      if (response.statusCode == 201) {
        await syncLibrary();
      } else {
        logger.severe('Failed to create library entry. Status: ${response.statusCode}');
        throw ApiException(
          message: 'Failed to create library entry',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'CREATE_ENTRY_FAILED',
        );
      }
    } on http.ClientException catch (e, st) {
      throw NetworkException(message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on SocketException catch (e, st) {
      throw NetworkException(message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on TimeoutException catch (e, st) {
      throw NetworkException(message: 'Request timed out.', code: 'TIMEOUT', originalError: e, stackTrace: st);
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      logger.severe('Unexpected error creating entry: $e\n$st');
      throw AppError(message: 'Failed to create library entry', originalError: e, stackTrace: st);
    }
  }

  Future<void> deleteEntry(String seriesId) async {
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
        throw AuthException(message: 'Authentication failed.', code: 'AUTH_FAILED');
      }
      if (response.statusCode == 200 || response.statusCode == 404) {
        await database.libraryEntriesDao.deleteEntry(seriesId);
      } else {
        logger.severe('Failed to delete entry. Status: ${response.statusCode}');
        throw ApiException(
          message: 'Failed to delete library entry',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'DELETE_ENTRY_FAILED',
        );
      }
    } on http.ClientException catch (e, st) {
      throw NetworkException(message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on SocketException catch (e, st) {
      throw NetworkException(message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on TimeoutException catch (e, st) {
      throw NetworkException(message: 'Request timed out.', code: 'TIMEOUT', originalError: e, stackTrace: st);
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      logger.severe('Unexpected error deleting entry: $e\n$st');
      throw AppError(message: 'Failed to delete library entry', originalError: e, stackTrace: st);
    }
  }

  Future<void> clearLibrary() async {
    try {
      setIsSyncCancelled(true);
      resetInitialSyncTask();
      await database.libraryEntriesDao.deleteAllEntries();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.lastSyncKey);
      await prefs.remove('${AppConstants.prefixStorageKey}library_is_incomplete');
    } catch (e, st) {
      logger.severe('Failed to clear library: $e\n$st');
    }
  }
}
