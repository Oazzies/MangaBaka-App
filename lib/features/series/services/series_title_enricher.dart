import 'dart:async';
import 'dart:collection';

import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/api_client.dart';
import 'package:mangabaka_app/core/network/api_envelope.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/models/series_titles.dart';

/// Gives series from the v2 endpoints their canonical (v1) titles.
///
/// v2 lists (Home rails, publisher shelves, "similar", "readers also like")
/// carry no server-chosen title, only a per-language list, so the title shown
/// there is a guess that can differ from the detail page. [canonicalize]
/// replaces the guesses with the real titles from `/v1/series/batch`.
///
/// Written to be gentle on the API:
///
/// * Only series whose canonical title is **not yet known** are requested.
///   Anything from a v1 payload, the library database, or an earlier lookup
///   costs nothing (see [SeriesTitles.remember]).
/// * Requests from different callers within [window] are **merged** into
///   shared batches of up to [batchSize] ids, so a Home screen with six rails
///   makes a couple of requests, not six.
/// * An id already being fetched is **awaited, not asked for again**; ids the
///   server did not return (merged or deleted) are not asked for again.
/// * Batches are **spaced** by [batchGap].
/// * After a failure (including a 429) enrichment **pauses** with exponential
///   backoff. Callers then keep the guessed titles; nothing retries in a
///   loop and nothing throws.
/// * Callers wait at most [waitBudget]; the fetch carries on in the
///   background so the next list benefits.
class SeriesTitleEnricher {
  SeriesTitleEnricher({
    ApiClient? api,
    this.window = const Duration(milliseconds: 40),
    this.batchGap = const Duration(milliseconds: 150),
    this.waitBudget = const Duration(seconds: 4),
    this.batchSize = 50,
    this.maxPending = 300,
    DateTime Function()? now,
  }) : _apiOrNull = api,
       _now = now ?? DateTime.now;

  /// The instance the app's services use.
  static SeriesTitleEnricher shared = SeriesTitleEnricher();

  /// An enricher that never touches the network, for tests and previews.
  factory SeriesTitleEnricher.disabled() = _DisabledEnricher;

  static final _logger = LoggingService.logger;

  final Duration window;
  final Duration batchGap;
  final Duration waitBudget;
  final int batchSize;
  final int maxPending;
  final DateTime Function() _now;

  final ApiClient? _apiOrNull;
  ApiClient? _lazyApi;
  ApiClient get _api =>
      _apiOrNull ??
      (_lazyApi ??= ApiClient(
        healthContext: 'titles',
        // Enrichment runs its own pause-with-backoff and must see the 429.
        maxRateLimitRetries: 0,
      ));

  final Set<String> _queue = <String>{};
  final Map<String, Completer<void>> _inFlight = {};
  final LinkedHashSet<String> _missing = LinkedHashSet<String>();
  Timer? _flushTimer;
  bool _flushing = false;

  int _failures = 0;
  DateTime? _pausedUntil;

  bool get _paused {
    final until = _pausedUntil;
    return until != null && _now().isBefore(until);
  }

  /// [series] with canonical titles wherever they could be obtained; the
  /// input is returned as is for the rest. Never throws.
  Future<List<Series>> canonicalize(List<Series> series) async {
    if (series.isEmpty) return series;
    final wanted = <String>{
      for (final s in series)
        if (_wantsLookup(s.id)) s.id,
    };

    if (wanted.isNotEmpty && !_paused) {
      final waits = [for (final id in wanted) _request(id)];
      try {
        await Future.wait(waits).timeout(waitBudget);
      } on TimeoutException {
        _logger.fine(
          'Title lookup exceeded ${waitBudget.inSeconds}s; showing '
          'provisional titles for now.',
        );
      }
    }

    return [for (final s in series) _apply(s)];
  }

  bool _wantsLookup(String id) =>
      int.tryParse(id) != null &&
      SeriesTitles.lookup(id) == null &&
      !_missing.contains(id);

  Series _apply(Series s) {
    final known = SeriesTitles.lookup(s.id);
    if (known == null) return s;
    if (known.main == s.title &&
        known.native == s.nativeTitle &&
        known.romanized == s.romanizedTitle) {
      return s;
    }
    return s.copyWithTitles(known);
  }

  Future<void> _request(String id) {
    final existing = _inFlight[id];
    if (existing != null) return existing.future;
    // A flood of distinct ids is not worth chasing; they keep their guess.
    if (_inFlight.length >= maxPending) return Future.value();

    final completer = Completer<void>();
    _inFlight[id] = completer;
    _queue.add(id);
    _scheduleFlush();
    return completer.future;
  }

  void _scheduleFlush() {
    _flushTimer ??= Timer(window, () {
      _flushTimer = null;
      unawaited(_flush());
    });
  }

  Future<void> _flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      var first = true;
      while (_queue.isNotEmpty) {
        final batch = _queue.take(batchSize).toList();
        _queue.removeAll(batch);

        if (!first) await Future<void>.delayed(batchGap);
        first = false;

        if (_paused) {
          _finish(batch);
          continue;
        }
        await _fetch(batch);
      }
    } finally {
      _flushing = false;
      // Ids queued while the last batch was in flight still need a flush.
      if (_queue.isNotEmpty) _scheduleFlush();
    }
  }

  Future<void> _fetch(List<String> ids) async {
    try {
      final found = await _api.getJson(
        ApiClient.uri('${AppConstants.baseApiUrl}/series/batch', {'id': ids}),
        operation: 'fetch canonical titles',
        // Parsing is what records each canonical title.
        parse: (json) => parseDataList(json, Series.fromJson),
      );
      _failures = 0;
      _pausedUntil = null;
      final returned = {for (final s in found) s.id};
      for (final id in ids) {
        if (!returned.contains(id)) _markMissing(id);
      }
    } catch (e) {
      _failures++;
      final seconds = (30 * (1 << (_failures - 1).clamp(0, 5))).clamp(30, 600);
      _pausedUntil = _now().add(Duration(seconds: seconds));
      _logger.warning(
        'Title lookup failed ($e); pausing for ${seconds}s. Lists keep their '
        'provisional titles meanwhile.',
      );
    } finally {
      _finish(ids);
    }
  }

  void _markMissing(String id) {
    _missing.add(id);
    while (_missing.length > 2000) {
      _missing.remove(_missing.first);
    }
  }

  void _finish(List<String> ids) {
    for (final id in ids) {
      _inFlight.remove(id)?.complete();
    }
  }

  void dispose() {
    _flushTimer?.cancel();
    _lazyApi?.close();
  }
}

class _DisabledEnricher extends SeriesTitleEnricher {
  _DisabledEnricher() : super();

  @override
  Future<List<Series>> canonicalize(List<Series> series) async => series;
}
