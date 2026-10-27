import 'dart:async';
import 'dart:convert';
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
import 'package:mangabaka_app/features/stacks/models/stack_draft.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/models/stack_status.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/services/stack_exceptions.dart';

/// Reads and writes MangaBaka Stacks (`/v2/stacks`, `/v2/my/stacks`).
///
/// Listings and stack pages are public; everything under `/v2/my` needs the
/// `stack.read` / `stack.write` scopes (see
/// [ProfileAuthService.hasStackScopes]). Every refusal is thrown as a
/// [StackApiException] carrying the API's reason code.
class StackService {
  static const String _base = AppConstants.baseApiUrlV2;
  static const int defaultLimit = 24;

  static final _logger = LoggingService.logger;

  final ApiClient _api;
  final http.Client _http;
  final bool _ownsHttp;
  final ProfileAuthService? _authOverride;

  StackService({http.Client? client, ApiClient? api, ProfileAuthService? auth})
    : _api = api ?? ApiClient(healthContext: 'stacks', client: client),
      _http = client ?? http.Client(),
      _ownsHttp = client == null,
      _authOverride = auth;

  ProfileAuthService get _auth => _authOverride ?? getIt<ProfileAuthService>();

  /// The ratings listings are limited to: the user's content preference.
  /// Empty (no preference) leaves it to the server, which lists every rating.
  static List<String> get _ratings => SettingsManager().contentPreferences;

  // ── Public reads ──────────────────────────────────────────────────────────

  /// Public stacks, newest first. [featured] keeps only staff picks.
  Future<PagedList<StackSummary>> browse({
    int page = 1,
    int limit = defaultLimit,
    bool featured = false,
  }) => _list(
    '$_base/stacks',
    {'featured': featured ? 'true' : null},
    page: page,
    limit: limit,
    operation: featured ? 'fetch featured stacks' : 'fetch stacks',
  );

  /// Public stacks that include a series.
  Future<PagedList<StackSummary>> forSeries(
    String seriesId, {
    int page = 1,
    int limit = defaultLimit,
    StackSort sort = StackSort.mostVoted,
    StackSpoilerFilter spoilers = StackSpoilerFilter.exclude,
  }) => _list(
    '$_base/series/$seriesId/stacks',
    {'sort_by': sort.apiValue, 'spoilers': spoilers.apiValue},
    page: page,
    limit: limit,
    operation: 'fetch stacks for series',
  );

  /// A user's public and unlisted stacks.
  Future<PagedList<StackSummary>> byUser(
    String username, {
    int page = 1,
    int limit = defaultLimit,
  }) => _list(
    '$_base/users/${Uri.encodeComponent(username)}/stacks',
    const {},
    page: page,
    limit: limit,
    operation: 'fetch user stacks',
  );

  /// A public or unlisted stack with its entries. Every entry comes back
  /// whatever its rating; the UI blurs per the user's settings.
  Future<StackDetail> fetch(int id) => _guard(
    () => _api.getJson(
      ApiClient.uri('$_base/stacks/$id'),
      operation: 'fetch stack',
      parse: _detail,
    ),
  );

  // ── The signed-in user's stacks ───────────────────────────────────────────

  /// The user's own stacks, drafts and hidden ones included.
  Future<PagedList<StackSummary>> mine({
    int page = 1,
    int limit = defaultLimit,
  }) => _myList('$_base/my/stacks', page, limit, 'fetch my stacks');

  Future<PagedList<StackSummary>> saved({
    int page = 1,
    int limit = defaultLimit,
  }) => _myList('$_base/my/stacks/saved', page, limit, 'fetch saved stacks');

  Future<PagedList<StackSummary>> followed({
    int page = 1,
    int limit = defaultLimit,
  }) => _myList(
    '$_base/my/stacks/followed',
    page,
    limit,
    'fetch followed stacks',
  );

  /// One of the user's stacks, with the `token` the next update needs.
  Future<StackDetail> fetchForEdit(int id) async {
    final body = await _authed(
      'fetch stack for editing',
      (h) => _http.get(Uri.parse('$_base/my/stacks/$id'), headers: h),
    );
    return ApiClient.decode(
      body,
      operation: 'fetch stack for editing',
      parse: _detail,
    );
  }

  /// Every stack the user owns, and where [seriesId] sits in each.
  Future<List<MySeriesStack>> myStacksForSeries(String seriesId) async {
    final body = await _authed(
      'fetch my stacks for series',
      (h) =>
          _http.get(Uri.parse('$_base/my/series/$seriesId/stacks'), headers: h),
    );
    return ApiClient.decode(
      body,
      operation: 'fetch my stacks for series',
      parse: (json) => parseDataList(json, MySeriesStack.fromJson),
    );
  }

  /// The user's vote / save / follow state and live counts for [ids].
  Future<Map<int, StackStatus>> status(Iterable<int> ids) async {
    final unique = ids.toSet().toList();
    final out = <int, StackStatus>{};
    for (var i = 0; i < unique.length; i += StackLimits.statusBatch) {
      final chunk = unique.sublist(
        i,
        (i + StackLimits.statusBatch).clamp(0, unique.length),
      );
      final uri = ApiClient.uri('$_base/my/stacks/status', {'id': chunk});
      final body = await _authed(
        'fetch stack status',
        (h) => _http.get(uri, headers: h),
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

  // ── Writes ────────────────────────────────────────────────────────────────

  /// Creates a draft. It can be published once it has
  /// [StackLimits.publishMin] series.
  Future<StackDetail> create(StackDraft draft) async {
    final body = await _authed(
      'create stack',
      (h) => _http.post(
        Uri.parse('$_base/my/stacks'),
        headers: h,
        body: jsonEncode(draft.toCreateJson()),
      ),
      accepted: const {200, 201},
    );
    return ApiClient.decode(body, operation: 'create stack', parse: _detail);
  }

  /// Replaces the stack's details and its whole entry list. [token] is the
  /// one from the last read or update; a stale one throws with
  /// [StackErrorCode.staleToken].
  Future<StackDetail> update(int id, StackDraft draft, String token) async {
    final body = await _authed(
      'update stack',
      (h) => _http.put(
        Uri.parse('$_base/my/stacks/$id'),
        headers: h,
        body: jsonEncode(draft.toUpdateJson(token)),
      ),
    );
    return ApiClient.decode(body, operation: 'update stack', parse: _detail);
  }

  /// Deletes the stack. The user cannot undo it.
  Future<void> delete(int id) async {
    await _authed(
      'delete stack',
      (h) => _http.delete(Uri.parse('$_base/my/stacks/$id'), headers: h),
      json: false,
    );
  }

  /// Changes only who can see the stack.
  Future<StackVisibility> setVisibility(
    int id,
    StackVisibility visibility,
  ) async {
    final body = await _authed(
      'change stack visibility',
      (h) => _http.put(
        Uri.parse('$_base/my/stacks/$id/visibility'),
        headers: h,
        body: jsonEncode({'visibility': visibility.apiValue}),
      ),
    );
    return ApiClient.decode(
      body,
      operation: 'change stack visibility',
      parse: (json) => StackVisibility.parse(dataObject(json)?['visibility']),
    );
  }

  /// Adds one series at [rank] (null: the end). [contentRating] raises the
  /// stack's rating when the series is rated above what it allows.
  /// Returns the rank it landed at.
  Future<int> addEntry(
    int stackId,
    String seriesId, {
    String? note,
    int? rank,
    String? contentRating,
  }) async {
    final body = await _authed(
      'add series to stack',
      (h) => _http.post(
        Uri.parse('$_base/my/stacks/$stackId/entries'),
        headers: h,
        body: jsonEncode({
          'series_id': int.tryParse(seriesId) ?? seriesId,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
          'rank': ?rank,
          'content_rating': ?contentRating,
        }),
      ),
      accepted: const {200, 201},
    );
    return ApiClient.decode(
      body,
      operation: 'add series to stack',
      parse: (json) => stackInt(dataObject(json)?['rank']),
    );
  }

  Future<StackStatus> vote(int id) => _toggle('votes', id, add: true);
  Future<StackStatus> unvote(int id) => _toggle('votes', id, add: false);
  Future<StackStatus> save(int id) => _toggle('saved', id, add: true);
  Future<StackStatus> unsave(int id) => _toggle('saved', id, add: false);
  Future<StackStatus> follow(int id) => _toggle('followed', id, add: true);
  Future<StackStatus> unfollow(int id) => _toggle('followed', id, add: false);

  Future<StackStatus> _toggle(String what, int id, {required bool add}) async {
    final uri = Uri.parse('$_base/my/stacks/$what/$id');
    final operation = '${add ? 'set' : 'clear'} stack $what';
    final body = await _authed(
      operation,
      (h) => add ? _http.put(uri, headers: h) : _http.delete(uri, headers: h),
      json: false,
    );
    return ApiClient.decode(
      body,
      operation: operation,
      parse: (json) => StackStatus.fromJson(dataObject(json) ?? const {}),
    );
  }

  // ── Plumbing ──────────────────────────────────────────────────────────────

  static StackDetail _detail(dynamic json) {
    final data = dataObject(json);
    if (data == null) {
      throw const FormatException('stack response without data');
    }
    return StackDetail.fromJson(data);
  }

  static PagedList<StackSummary> _page(dynamic json) => PagedList(
    parseDataList(json, StackSummary.fromJson),
    hasNext: hasNextPage(json),
    total: totalCount(json),
  );

  Future<PagedList<StackSummary>> _list(
    String url,
    Map<String, dynamic> params, {
    required int page,
    required int limit,
    required String operation,
  }) => _guard(
    () => _api.getJson(
      ApiClient.uri(url, {
        ...params,
        'page': page,
        'limit': limit.clamp(1, StackLimits.pageMax),
        'content_rating': _ratings,
      }),
      operation: operation,
      parse: _page,
    ),
  );

  Future<PagedList<StackSummary>> _myList(
    String url,
    int page,
    int limit,
    String operation,
  ) async {
    final uri = ApiClient.uri(url, {
      'page': page,
      'limit': limit.clamp(1, StackLimits.pageMax),
      'content_rating': _ratings,
    });
    final body = await _authed(operation, (h) => _http.get(uri, headers: h));
    return ApiClient.decode(body, operation: operation, parse: _page);
  }

  /// Runs a public read, turning a refused request into a
  /// [StackApiException].
  Future<T> _guard<T>(Future<T> Function() run) async {
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
  Future<String> _authed(
    String operation,
    Future<http.Response> Function(Map<String, String> headers) request, {
    Set<int> accepted = const {200},
    bool json = true,
  }) async {
    final auth = _auth;
    if (!auth.isLoggedIn) throw SessionExpiredException();
    _logger.info('Stacks: $operation');
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

  void dispose() {
    _api.close();
    if (_ownsHttp) _http.close();
  }
}
