import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';

/// Coarse view of whether the MangaBaka backend is currently usable.
enum BackendHealthStatus {
  /// A request has succeeded recently — assume the backend is fine.
  healthy,

  /// Nothing conclusive yet (app just started, no request has finished).
  unknown,

  /// Several server-side failures in a row — the backend is treated as down
  /// until a request (or the recovery probe) succeeds.
  down,
}

/// Tracks the health of `api.mangabaka.org` from the outcomes of the requests
/// the app already makes, flips to [BackendHealthStatus.down] after a run of
/// server-side failures, and then actively probes until the origin recovers.
///
/// This is deliberately passive at the call sites: a service reports the
/// outcome of a request it was going to make anyway via [reportSuccess] /
/// [reportServerFailure] (or the [reportApiOutcome] free function), and the
/// UI listens to [status]. Client-side conditions (404, 403, 429) are **not**
/// treated as the backend being down — only 5xx, transport errors and timeouts.
class BackendHealthService {
  BackendHealthService({
    http.Client? client,
    Duration? probeInterval,
    int? failureThreshold,
  })  : _client = client ?? http.Client(),
        _probeInterval = probeInterval ?? const Duration(seconds: 15),
        _failureThreshold = failureThreshold ?? 3;

  static final _logger = LoggingService.logger;

  final http.Client _client;
  final Duration _probeInterval;

  /// Consecutive server-side failures needed before the backend is called down.
  final int _failureThreshold;

  final ValueNotifier<BackendHealthStatus> status =
      ValueNotifier<BackendHealthStatus>(BackendHealthStatus.unknown);

  int _consecutiveFailures = 0;
  Timer? _probeTimer;
  int _probeAttempt = 0;
  bool _probing = false;
  bool _disposed = false;

  bool get isDown => status.value == BackendHealthStatus.down;

  /// Report that a backend request completed normally (any 2xx/3xx, or a
  /// deliberate 4xx like "not found"). Clears the failure streak and, if the
  /// backend was considered down, brings it back up.
  void reportSuccess() {
    // A probe or request can finish after disposal; touching the disposed
    // notifier would throw.
    if (_disposed) return;
    _consecutiveFailures = 0;
    _probeAttempt = 0;
    _stopProbe();

    final previous = status.value;
    if (previous != BackendHealthStatus.healthy) {
      status.value = BackendHealthStatus.healthy;
      if (previous == BackendHealthStatus.down) {
        _logger.info('Backend health: DOWN → OK — a request succeeded');
      } else {
        _logger.info('Backend health: OK');
      }
    }
  }

  /// Report a server-side failure: a 5xx status, a transport error or a
  /// timeout. [context] is a short tag for the log (e.g. `series-search`).
  ///
  /// Pass the HTTP [statusCode] when there was a response. A 429 is logged but
  /// does not count toward the backend being down — it means the client is
  /// sending too fast, not that the origin is unreachable.
  void reportServerFailure({
    required String context,
    int? statusCode,
    Object? error,
  }) {
    if (_disposed) return;
    if (statusCode == 429) {
      _logger.fine('Backend health: rate-limited (HTTP 429) on $context — '
          'not counted against backend health');
      return;
    }

    final detail = statusCode != null
        ? '$context HTTP $statusCode'
        : '$context ${error ?? 'transport error'}';
    _consecutiveFailures++;

    if (status.value != BackendHealthStatus.down &&
        _consecutiveFailures >= _failureThreshold) {
      final previous = status.value;
      status.value = BackendHealthStatus.down;
      _logger.warning(
        'Backend health: ${previous == BackendHealthStatus.healthy ? 'OK' : 'UNKNOWN'} → DOWN '
        '— $_consecutiveFailures consecutive server failures (last: $detail)',
      );
      _startProbe();
    } else if (status.value != BackendHealthStatus.down) {
      _logger.fine(
        'Backend health: server failure $_consecutiveFailures/$_failureThreshold ($detail)',
      );
    }
  }

  /// Force an immediate recovery check (e.g. the user tapped "Retry").
  Future<void> checkNow() async {
    _logger.info('Backend health: manual recovery check requested');
    await _probeOnce();
  }

  void _startProbe() {
    if (_disposed) return;
    _probeTimer ??= Timer.periodic(_probeInterval, (_) => _probeOnce());
  }

  void _stopProbe() {
    _probeTimer?.cancel();
    _probeTimer = null;
  }

  Future<void> _probeOnce() async {
    if (_probing) return;
    _probing = true;
    _probeAttempt++;
    try {
      // Any HTTP response below 500 means the origin behind Cloudflare is
      // answering — even a 404 proves the backend is reachable. 5xx, a
      // transport error or a timeout means it is still down.
      final response = await _client
          .get(
            Uri.parse(AppConstants.baseApiUrl),
            headers: {'User-Agent': AppConstants.userAgent},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode < 500) {
        _logger.info(
          'Backend health: DOWN → OK — recovery probe #$_probeAttempt '
          'succeeded (HTTP ${response.statusCode})',
        );
        reportSuccess();
      } else {
        _logger.info(
          'Backend health: recovery probe #$_probeAttempt — still down '
          '(HTTP ${response.statusCode})',
        );
      }
    } catch (e) {
      _logger.info(
        'Backend health: recovery probe #$_probeAttempt — still down ($e)',
      );
    } finally {
      _probing = false;
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _stopProbe();
    _client.close();
    status.dispose();
  }
}

/// Route the outcome of a backend request to [BackendHealthService] without the
/// call site needing to resolve the service itself. A no-op when the service
/// is not registered (e.g. in unit tests that don't need it).
///
/// [ok] is true for any response the app can act on (2xx/3xx and deliberate
/// 4xx such as 404/403). Pass [statusCode] when there was an HTTP response and
/// [error] for transport failures/timeouts.
void reportApiOutcome({
  required bool ok,
  required String context,
  int? statusCode,
  Object? error,
}) {
  if (!getIt.isRegistered<BackendHealthService>()) return;
  final health = getIt<BackendHealthService>();
  if (ok) {
    health.reportSuccess();
  } else {
    health.reportServerFailure(
      context: context,
      statusCode: statusCode,
      error: error,
    );
  }
}

/// True when [statusCode] indicates the server itself failed (5xx). 429 and
/// other 4xx are client-side conditions and are handled separately.
bool isServerErrorStatus(int statusCode) => statusCode >= 500;
