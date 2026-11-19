import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/network/api_client.dart';
import 'package:mangabaka_app/core/network/api_envelope.dart';
import 'package:mangabaka_app/core/network/paged_list.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/stacks/models/stack_detail.dart';
import 'package:mangabaka_app/features/stacks/models/stack_draft.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/models/stack_status.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/services/stack_authed_client.dart';

/// Everything under `/v2/my` needs the `stack.read` / `stack.write` scopes.
class StackService {
  static const String _base = AppConstants.baseApiUrlV2;
  static const int defaultLimit = 24;

  final ApiClient _api;
  final http.Client _http;
  final bool _ownsHttp;
  final StackAuthedClient _client;

  StackService({http.Client? client, ApiClient? api, ProfileAuthService? auth})
    : _api = api ?? ApiClient(healthContext: 'stacks', client: client),
      _http = client ?? http.Client(),
      _ownsHttp = client == null,
      _client = StackAuthedClient(auth: auth);

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

  /// Entries come back whatever their rating; the UI blurs per the user's settings.
  Future<StackDetail> fetch(int id) => _guard(
    () => _api.getJson(
      ApiClient.uri('$_base/stacks/$id'),
      operation: 'fetch stack',
      parse: _detail,
    ),
  );

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

  Future<Map<int, StackStatus>> status(Iterable<int> ids) =>
      _client.fetchStatus(_http, _base, ids);

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

  /// Replaces the whole entry list; a stale [token] throws [StackErrorCode.staleToken].
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

  Future<void> delete(int id) async {
    await _authed(
      'delete stack',
      (h) => _http.delete(Uri.parse('$_base/my/stacks/$id'), headers: h),
      json: false,
    );
  }

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

  /// [contentRating] raises the stack's rating when the series is rated above what it allows.
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

  Future<StackStatus> _toggle(String what, int id, {required bool add}) =>
      _client.toggle(_http, _base, what, id, add: add);

  static StackDetail _detail(dynamic json) =>
      StackAuthedClient.decodeDetail(json);

  Future<PagedList<StackSummary>> _list(
    String url,
    Map<String, dynamic> params, {
    required int page,
    required int limit,
    required String operation,
  }) => _client.list(
    _api,
    url,
    params,
    page: page,
    limit: limit,
    operation: operation,
  );

  Future<PagedList<StackSummary>> _myList(
    String url,
    int page,
    int limit,
    String operation,
  ) => _client.myList(_http, url, page, limit, operation);

  Future<T> _guard<T>(Future<T> Function() run) => _client.guard(run);

  Future<String> _authed(
    String operation,
    Future<http.Response> Function(Map<String, String> headers) request, {
    Set<int> accepted = const {200},
    bool json = true,
  }) => _client.send(operation, request, accepted: accepted, json: json);

  void dispose() {
    _api.close();
    if (_ownsHttp) _http.close();
  }
}
