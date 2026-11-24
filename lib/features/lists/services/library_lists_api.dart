import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/api_client.dart';
import 'package:mangabaka_app/core/network/api_envelope.dart';
import 'package:mangabaka_app/core/network/backend_health_service.dart';
import 'package:mangabaka_app/core/network/paged_list.dart';
import 'package:mangabaka_app/features/lists/models/library_list.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';

/// The `/v2/my/library/lists` endpoints. Writes are never retried: a create is not idempotent.
class LibraryListsApi {
  static final _logger = LoggingService.logger;
  static const String _base = '${AppConstants.baseApiUrlV2}/my/library';
  static const int pageLimit = 1000;

  final http.Client _http;
  final ProfileAuthService Function() _auth;

  LibraryListsApi({
    required http.Client client,
    required ProfileAuthService Function() auth,
  }) : _http = client,
       _auth = auth;

  Future<List<LibraryList>> fetchAll() async {
    final out = <LibraryList>[];
    for (var page = 1; ; page++) {
      final uri = ApiClient.uri('$_base/lists', {
        'page': page,
        'limit': pageLimit,
      });
      final body = await _send(
        'fetch lists',
        (h) => _http.get(uri, headers: h),
      );
      final json = _decode(body, 'fetch lists');
      out.addAll(parseDataList(json, LibraryList.fromJson));
      final more = hasNextPage(json) && dataList(json).isNotEmpty;
      if (!more) return out;
    }
  }

  Future<LibraryList> create(String name, {required bool isPrivate}) async {
    final body = await _send(
      'create list',
      (h) => _http.post(
        Uri.parse('$_base/lists'),
        headers: h,
        body: jsonEncode({'name': name, 'is_private': isPrivate}),
      ),
    );
    return _list(body, 'create list');
  }

  Future<LibraryList> update(int id, {String? name, bool? isPrivate}) async {
    final body = await _send(
      'update list',
      (h) => _http.patch(
        Uri.parse('$_base/lists/$id'),
        headers: h,
        body: jsonEncode({'name': ?name, 'is_private': ?isPrivate}),
      ),
    );
    return _list(body, 'update list');
  }

  Future<void> delete(int id) => _send(
    'delete list',
    (h) => _http.delete(Uri.parse('$_base/lists/$id'), headers: h),
    json: false,
  );

  Future<void> batchSetPrivacy(List<int> ids, {required bool isPrivate}) =>
      _send(
        'set list visibility',
        (h) => _http.post(
          Uri.parse('$_base/lists/batch'),
          headers: h,
          body: jsonEncode({
            'action': 'set_visibility',
            'ids': ids,
            'is_private': isPrivate,
          }),
        ),
      );

  Future<void> batchDelete(List<int> ids) => _send(
    'delete lists',
    (h) => _http.post(
      Uri.parse('$_base/lists/batch'),
      headers: h,
      body: jsonEncode({'action': 'delete', 'ids': ids}),
    ),
  );

  /// Returns every list the series is on after the change.
  Future<List<LibraryList>> setMembership(
    String seriesId,
    int listId, {
    required bool member,
  }) async {
    final uri = Uri.parse('$_base/$seriesId/lists/$listId');
    final operation = member ? 'add series to list' : 'remove series from list';
    final body = await _send(
      operation,
      (h) =>
          member ? _http.put(uri, headers: h) : _http.delete(uri, headers: h),
      json: false,
    );
    return parseDataList(_decode(body, operation), LibraryList.fromJson);
  }

  LibraryList _list(String body, String operation) {
    final data = dataObject(_decode(body, operation));
    if (data == null) {
      throw ParseException(message: '$operation response had no data');
    }
    try {
      return LibraryList.fromJson(data);
    } on FormatException catch (e, st) {
      throw ParseException(
        message: 'Failed to parse $operation response',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  dynamic _decode(String body, String operation) =>
      ApiClient.decode(body, operation: operation, parse: (json) => json);

  Future<String> _send(
    String operation,
    Future<http.Response> Function(Map<String, String> headers) request, {
    bool json = true,
  }) async {
    final auth = _auth();
    if (!auth.isLoggedIn) throw SessionExpiredException();
    _logger.info('Lists: $operation');
    try {
      final response = await auth.sendAuthorized(
        (token) =>
            request({
              'Authorization': 'Bearer $token',
              'User-Agent': AppConstants.userAgent,
              if (json) 'Content-Type': 'application/json',
            }).timeout(
              const Duration(seconds: AppConstants.networkTimeoutSeconds),
              onTimeout: () => throw TimeoutException('$operation timed out'),
            ),
      );
      final status = response.statusCode;
      _report(ok: !isServerErrorStatus(status), statusCode: status);
      if (status != 200) {
        _logger.severe('Lists: $operation failed. Status: $status');
        throw ApiException(
          message: 'Failed to $operation',
          statusCode: status,
          responseBody: response.body,
          code: 'REQUEST_FAILED',
        );
      }
      return response.body;
    } on AppException {
      rethrow;
    } on TimeoutException catch (e, st) {
      _report(ok: false, error: 'timeout');
      throw NetworkException(
        message: 'Request timed out.',
        code: 'TIMEOUT',
        originalError: e,
        stackTrace: st,
      );
    } on http.ClientException catch (e, st) {
      _report(ok: false, error: e);
      throw NetworkException(
        message: 'Network error.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on SocketException catch (e, st) {
      _report(ok: false, error: e);
      throw NetworkException(
        message: 'Network error.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  void _report({required bool ok, int? statusCode, Object? error}) =>
      reportApiOutcome(
        ok: ok,
        context: 'lists',
        statusCode: statusCode,
        error: error,
      );
}
