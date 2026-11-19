import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';

enum BackendHealthStatus {
  healthy,

  unknown,

  down,
}

/// Only 5xx, transport errors and timeouts count as down; 404, 403, 429 do not.
class BackendHealthService {
  BackendHealthService({
    http.Client? client,
    Duration? probeInterval,
    int? failureThreshold,
  }) : _client = client ?? http.Client(),
       _probeInterval = probeInterval ?? const Duration(seconds: 15),
       _failureThreshold = failureThreshold ?? 3;

  static final _logger = LoggingService.logger;

  final http.Client _client;
  final Duration _probeInterval;

  final int _failureThreshold;

  final ValueNotifier<BackendHealthStatus> status =
      ValueNotifier<BackendHealthStatus>(BackendHealthStatus.unknown);

  int _consecutiveFailures = 0;
  Timer? _probeTimer;
  int _probeAttempt = 0;
  bool _probing = false;
  bool _disposed = false;

  bool get isDown => status.value == BackendHealthStatus.down;

  void reportSuccess() {
    // A probe or request can finish after dispose; the notifier would throw.
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

  void reportServerFailure({
    required String context,
    int? statusCode,
    Object? error,
  }) {
    if (_disposed) return;
    if (statusCode == 429) {
      _logger.fine(
        'Backend health: rate-limited (HTTP 429) on $context — '
        'not counted against backend health',
      );
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
      // Any status under 500, even 404, means the origin behind Cloudflare is up.
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

/// [ok] includes deliberate 4xx such as 404/403: anything the app can act on.
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

bool isServerErrorStatus(int statusCode) => statusCode >= 500;
