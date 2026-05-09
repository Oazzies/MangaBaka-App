part of 'library_service.dart';

// ─── HTTP helpers ─────────────────────────────────────────────────────────

extension LibraryServiceApi on LibraryService {
  Future<_FetchPageResult> _fetchPage(
    String token,
    int page, {
    String? state,
    String? type,
    String? sortBy,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': LibraryConstants.pageLimit.toString(),
    };
    if (state != null) queryParams['state'] = state;
    if (type != null) queryParams['type'] = type;
    if (sortBy != null) queryParams['sort_by'] = sortBy;

    final uri = Uri.parse(LibraryConstants.baseUrl)
        .replace(queryParameters: queryParams);

    try {
      final response = await http
          .get(uri, headers: {
            'Authorization': 'Bearer $token',
            'User-Agent': LibraryConstants.userAgent,
          })
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Library fetch timed out'),
          );

      _logger.fine('Library fetch page $page completed (${response.statusCode})');

      if (response.statusCode == 429) {
        _logger.warning(
            'Rate limited on page $page. Waiting ${AppConstants.rateLimitRetryDelaySeconds}s...');
        await Future.delayed(
            Duration(seconds: AppConstants.rateLimitRetryDelaySeconds));
        return _fetchPage(token, page, state: state, sortBy: sortBy);
      }

      if (response.statusCode == 401) {
        throw AuthException(
          message: 'Authentication failed. Please log in again.',
          code: 'AUTH_FAILED',
        );
      }

      // 400 usually means "Bad Request" - often "Page out of range" or hitting a deep pagination limit.
      if (response.statusCode == 400) {
        _logger.warning('Page $page returned 400. Body: ${response.body}');
        return _FetchPageResult(entries: [], totalEntries: 0, isError: true);
      }

      if (response.statusCode != 200) {
        _logger.severe(
            'Failed to fetch library page. Status: ${response.statusCode}');
        throw ApiException(
          message: 'Failed to fetch library page',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'FETCH_PAGE_FAILED',
        );
      }

      try {
        final result = await compute(_parseLibraryPage, response.body);
        return result;
      } catch (e, st) {
        _logger.severe('Failed to parse library page: $e\n$st');
        throw ParseException(
          message: 'Failed to parse library page',
          originalError: e,
          stackTrace: st,
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException(
          message: 'Network error. Please check your connection.',
          code: 'NETWORK_ERROR',
          originalError: e);
    } on SocketException catch (e) {
      throw NetworkException(
          message: 'Network error. Please check your connection.',
          code: 'NETWORK_ERROR',
          originalError: e);
    } on TimeoutException catch (e) {
      throw NetworkException(
          message: 'Request timed out. Please try again.',
          code: 'TIMEOUT',
          originalError: e);
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on ParseException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      throw AppError(
          message: 'Unexpected error fetching library page',
          originalError: e,
          stackTrace: st);
    }
  }

  Future<void> _saveEntries(List<api.LibraryEntry> entries) async {
    if (entries.isEmpty) return;
    try {
      await _db.seriesDao.upsertSeries(entries.map((e) => e.series).toList());
      await _db.libraryEntriesDao.upsertLibraryEntries(entries);
    } catch (e, st) {
      _logger.severe('Failed to save entries to database: $e\n$st');
      throw DatabaseException(
        message: 'Failed to save entries',
        originalError: e,
        stackTrace: st,
      );
    }
  }
}

// ─── Private parse helpers (run in isolate) ──────────────────────────────────

class _FetchPageResult {
  final List<api.LibraryEntry> entries;
  final int totalEntries;
  final bool isError;

  _FetchPageResult({
    required this.entries,
    required this.totalEntries,
    this.isError = false,
  });
}

_FetchPageResult _parseLibraryPage(String responseBody) {
  final body = jsonDecode(responseBody) as Map<String, dynamic>;
  final data = (body['data'] as List<dynamic>? ?? const []);

  int total = 0;
  final pagination = body['pagination'] as Map<String, dynamic>?;
  if (pagination != null) {
    // API returns count = items on this page, not the grand total.
    // We use 'count' only for internal checks; there is no total exposed.
    total = (pagination['count'] as num?)?.toInt() ?? 0;
  }

  final entries = data
      .map((item) => api.LibraryEntry.fromJson(item as Map<String, dynamic>))
      .toList();

  return _FetchPageResult(entries: entries, totalEntries: total);
}

DateTime? _parseAsUtc(String dateStr) {
  if (dateStr.isEmpty) return null;
  
  // Try parsing as integer (Unix timestamp)
  final numValue = int.tryParse(dateStr);
  if (numValue != null) {
    // Stricter check: Unix timestamps are usually 10 digits (seconds) or 13 digits (ms)
    if (dateStr.length == 10) {
      return DateTime.fromMillisecondsSinceEpoch(numValue * 1000, isUtc: true);
    } else if (dateStr.length == 13) {
      return DateTime.fromMillisecondsSinceEpoch(numValue, isUtc: true);
    }
  }

  return DateTime.tryParse(dateStr)?.toUtc();
}
