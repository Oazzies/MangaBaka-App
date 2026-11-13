part of 'library_service.dart';

Future<void> _saveEntriesImpl(
  LibraryService self,
  List<api.LibraryEntry> entries,
) async {
  if (entries.isEmpty) return;
  await self._db.transaction(() async {
    await self._db.seriesDao.upsertSeries(
      entries.map((e) => e.series).toList(),
    );
    await self._db.libraryEntriesDao.upsertLibraryEntries(entries);
  });
}

DateTime? _parseAsUtcImpl(String dateStr) {
  if (dateStr.isEmpty) return null;
  final numValue = int.tryParse(dateStr);
  if (numValue != null) {
    if (dateStr.length == 10) {
      return DateTime.fromMillisecondsSinceEpoch(numValue * 1000, isUtc: true);
    }
    if (dateStr.length == 13) {
      return DateTime.fromMillisecondsSinceEpoch(numValue, isUtc: true);
    }
  }
  return DateTime.tryParse(dateStr)?.toUtc();
}

Future<LibraryChangesPage> _fetchChangesImpl(
  LibraryService service,
  String? cursor, {
  int retryCount = 0,
}) async {
  final uri = Uri.parse('${AppConstants.baseApiUrlV2}/my/library/changes')
      .replace(
        queryParameters: {
          'limit': '${LibraryService._changesLimit}',
          if (cursor != null) 'cursor': cursor,
        },
      );
  service._logger.info('Fetching library changes. URL: $uri');

  try {
    final response = await service._auth.sendAuthorized(
      (token) => http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'User-Agent': LibraryConstants.userAgent,
            },
          )
          .timeout(Duration(seconds: AppConstants.networkTimeoutSeconds)),
    );

    if (response.statusCode == 429) {
      if (retryCount >= LibraryService._maxRateLimitRetries) {
        throw ApiException(
          message: 'Rate limited by server',
          statusCode: response.statusCode,
          code: 'RATE_LIMITED',
        );
      }
      final wait =
          int.tryParse(response.headers['retry-after'] ?? '') ??
          AppConstants.rateLimitRetryDelaySeconds;
      await Future.delayed(Duration(seconds: wait.clamp(1, 60)));
      return _fetchChangesImpl(service, cursor, retryCount: retryCount + 1);
    }
    if (response.statusCode == 400) {
      return const LibraryChangesPage(invalidCursor: true);
    }
    if (response.statusCode != 200) {
      throw ApiException(
        message: 'Fetch failed',
        statusCode: response.statusCode,
      );
    }

    final body = jsonDecode(response.body);
    final data = body is Map ? body['data'] : null;
    final pagination = body is Map ? body['pagination'] : null;
    if (data is! List) {
      throw ParseException(message: 'Library changes had no data list');
    }
    return LibraryChangesPage(
      items: [
        for (final item in data)
          if (item is Map) item.cast<String, dynamic>(),
      ],
      cursor: pagination is Map ? pagination['cursor']?.toString() : null,
      more: pagination is Map && pagination['more'] == true,
    );
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
  } on FormatException catch (e, st) {
    throw ParseException(
      message: 'Failed to parse library changes',
      originalError: e,
      stackTrace: st,
    );
  }
}

Future<List<api_series.Series>> _fetchSeriesBatchImpl(
  LibraryService service,
  List<String> ids,
) async {
  final result = <api_series.Series>[];
  for (var i = 0; i < ids.length; i += 50) {
    if (i > 0) {
      // A full scan of a big library is hundreds of these; spread them out
      // rather than trip the rate limit.
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    final chunk = ids.sublist(i, i + 50 > ids.length ? ids.length : i + 50);
    result.addAll(await _fetchSeriesChunkImpl(service, chunk));
  }
  return result;
}

Future<List<api_series.Series>> _fetchSeriesChunkImpl(
  LibraryService service,
  List<String> chunk, {
  int attempt = 0,
}) async {
  final uri = Uri.parse(
    '${AppConstants.baseApiUrl}/series/batch',
  ).replace(queryParameters: {'id': chunk});
  try {
    final response = await http
        .get(uri, headers: {'User-Agent': LibraryConstants.userAgent})
        .timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));
    final status = response.statusCode;

    if (status == 429 || status >= 500) {
      if (attempt >= 5) {
        throw ApiException(
          message: 'Series batch failed ($status)',
          statusCode: status,
        );
      }
      final wait =
          int.tryParse(response.headers['retry-after'] ?? '') ??
          (2 << attempt);
      service._logger.warning(
        'Series batch got $status; retrying in ${wait}s (attempt ${attempt + 1}).',
      );
      await Future<void>.delayed(Duration(seconds: wait.clamp(1, 60)));
      return _fetchSeriesChunkImpl(service, chunk, attempt: attempt + 1);
    }

    if (status != 200) {
      service._logger.warning(
        'Series batch got $status for ${chunk.length} ids: ${response.body}',
      );
      if (chunk.length == 1) return const [];
      final mid = chunk.length ~/ 2;
      return [
        ...await _fetchSeriesChunkImpl(service, chunk.sublist(0, mid)),
        ...await _fetchSeriesChunkImpl(service, chunk.sublist(mid)),
      ];
    }

    final data = (jsonDecode(response.body) as Map)['data'];
    final found = <api_series.Series>[];
    if (data is List) {
      for (final item in data) {
        try {
          found.add(
            api_series.Series.fromJson((item as Map).cast<String, dynamic>()),
          );
        } catch (e, st) {
          service._logger.warning('Skipping malformed series in batch', e, st);
        }
      }
    }
    return found;
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
  }
}

/// One page of the library change feed.
class LibraryChangesPage {
  final List<Map<String, dynamic>> items;

  /// Opaque position to send back for the next page; save it once applied.
  final String? cursor;
  final bool more;

  /// The server refused the cursor (or request): scan from the start.
  final bool invalidCursor;

  const LibraryChangesPage({
    this.items = const [],
    this.cursor,
    this.more = false,
    this.invalidCursor = false,
  });
}

class FetchPageResult {
  final List<api.LibraryEntry> entries;
  final bool isError;

  /// Entries on the page that could not be parsed and were left out. When
  /// non-zero the page is not a complete picture of the server's library.
  final int skipped;
  FetchPageResult({
    required this.entries,
    this.isError = false,
    this.skipped = 0,
  });
}

FetchPageResult _parseLibraryPage(String responseBody) {
  final body = jsonDecode(responseBody);
  final data = body is Map ? body['data'] : null;
  if (data is! List) return FetchPageResult(entries: []);
  // One malformed entry must cost that entry, not the page: a throw here
  // fails the whole sync, and it would fail identically on every retry.
  final entries = <api.LibraryEntry>[];
  var skipped = 0;
  for (final item in data) {
    try {
      entries.add(api.LibraryEntry.fromJson(item as Map<String, dynamic>));
    } catch (e, st) {
      LoggingService.logger.warning('Skipping malformed library entry', e, st);
      skipped++;
    }
  }
  return FetchPageResult(entries: entries, skipped: skipped);
}
