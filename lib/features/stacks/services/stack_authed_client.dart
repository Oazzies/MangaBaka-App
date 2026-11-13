import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/api_client.dart';
import 'package:mangabaka_app/core/network/api_envelope.dart';
import 'package:mangabaka_app/core/network/paged_list.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/stacks/models/stack_detail.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/models/stack_status.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/services/stack_exceptions.dart';

/// Shared HTTP guard and authorized request helper for [StackService].
class StackAuthedClient {
  static final _logger = LoggingService.logger;

  final ProfileAuthService? _authOverride;

  const StackAuthedClient({ProfileAuthService? auth}) : _authOverride = auth;

  ProfileAuthService get auth => _authOverride ?? getIt<ProfileAuthService>();

  static StackDetail decodeDetail(dynamic json) {
    final data = dataObject(json);
    if (data == null) {
      throw const FormatException('stack response without data');
    }
    return StackDetail.fromJson(data);
  }

  static PagedList<StackSummary> decodePage(dynamic json) => PagedList(
    parseDataList(json, StackSummary.fromJson),
    hasNext: hasNextPage(json),
    total: totalCount(json),
  );

  Future<PagedList<StackSummary>> list(
    ApiClient api,
    String url,
    Map<String, dynamic> params, {
    required int page,
    required int limit,
    required String operation,
  }) => guard(
    () => api.getJson(
      ApiClient.uri(url, {
        ...params,
        'page': page,
        'limit': limit.clamp(1, StackLimits.pageMax),
        'content_rating': SettingsManager().contentPreferences,
      }),
      operation: operation,
      parse: decodePage,
    ),
  );

  Future<PagedList<StackSummary>> myList(
    http.Client httpClient,
    String url,
    int page,
    int limit,
    String operation,
  ) async {
    final uri = ApiClient.uri(url, {
      'page': page,
      'limit': limit.clamp(1, StackLimits.pageMax),
      'content_rating': SettingsManager().contentPreferences,
    });
    final body = await send(operation, (h) => httpClient.get(uri, headers: h));
    return ApiClient.decode(body, operation: operation, parse: decodePage);
  }

  Future<StackStatus> toggle(
    http.Client httpClient,
    String baseUrl,
    String what,
    int id, {
    required bool add,
  }) async {
    final uri = Uri.parse('$baseUrl/my/stacks/$what/$id');
    final operation = '${add ? 'set' : 'clear'} stack $what';
    final body = await send(
      operation,
      (h) => add ? httpClient.put(uri, headers: h) : httpClient.delete(uri, headers: h),
      json: false,
    );
    return ApiClient.decode(
      body,
      operation: operation,
      parse: (json) => StackStatus.fromJson(dataObject(json) ?? const {}),
    );
  }

  Future<Map<int, StackStatus>> fetchStatus(
    http.Client httpClient,
    String baseUrl,
    Iterable<int> ids,
  ) async {
    final unique = ids.toSet().toList();
    final out = <int, StackStatus>{};
    for (var i = 0; i < unique.length; i += StackLimits.statusBatch) {
      final chunk = unique.sublist(
        i,
        (i + StackLimits.statusBatch).clamp(0, unique.length),
      );
      final uri = ApiClient.uri('$baseUrl/my/stacks/status', {'id': chunk});
      final body = await send(
        'fetch stack status',
        (h) => httpClient.get(uri, headers: h),
      );
      final list = ApiClient.decode(
        body,
        operation: 'fetch stack status',
        parse: (json) => parseDataList(json, StackStatus.fromJson),
      );
      for (final s in list) {
        out[s.id] = s;
      }
    }
    return out;
  }

  /// Runs a public read, turning a refused request into a [StackApiException].
  Future<T> guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on StackApiException {
      rethrow;
    } on ApiException catch (e) {
      throw StackApiException.fromApi(e);
    }
  }

  /// Sends a request that needs the user's token and returns the body of an
  /// accepted response. A 401 is recovered from by [ProfileAuthService]
  /// (or ends in [SessionExpiredException]); any other refusal becomes a
  /// [StackApiException].
  Future<String> send(
    String operation,
    Future<http.Response> Function(Map<String, String> headers) request, {
    Set<int> accepted = const {200},
    bool json = true,
  }) async {
    final profileAuth = auth;
    if (!profileAuth.isLoggedIn) throw SessionExpiredException();
    _logger.info('Stacks: $operation');
    try {
      final response = await profileAuth.sendAuthorized(
        (token) => request({
          'Authorization': 'Bearer $token',
          'User-Agent': AppConstants.userAgent,
          if (json) 'Content-Type': 'application/json',
        }).timeout(
          const Duration(seconds: AppConstants.networkTimeoutSeconds),
          onTimeout: () => throw TimeoutException('$operation timed out'),
        ),
      );
      if (!accepted.contains(response.statusCode)) {
        _logger.severe(
          'Stacks: $operation failed. Status: ${response.statusCode}',
        );
        throw StackApiException.fromResponse(
          response.statusCode,
          response.body,
          operation: operation,
        );
      }
      return response.body;
    } on AppException {
      rethrow;
    } on TimeoutException catch (e, st) {
      throw NetworkException(
        message: 'Request timed out.',
        code: 'TIMEOUT',
        originalError: e,
        stackTrace: st,
      );
    } on http.ClientException catch (e, st) {
      throw NetworkException(
        message: 'Network error.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on SocketException catch (e, st) {
      throw NetworkException(
        message: 'Network error.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } catch (e, st) {
      throw AppError(
        message: 'Failed to $operation',
        originalError: e,
        stackTrace: st,
      );
    }
  }
}
