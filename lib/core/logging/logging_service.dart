import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:mangabaka_app/core/logging/log_redactor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class LoggingService {
  static final Logger _logger = Logger('MangaBakaApp');
  static final List<String> _logBuffer = [];
  static const int _maxLogs = 1000;
  static const int _maxLogFileBytes = 10 * 1024 * 1024;
  static const Duration _flushInterval = Duration(seconds: 2);

  static File? _logFile;
  static StreamSubscription<LogRecord>? _subscription;
  static Timer? _flushTimer;

  // Flushed in batches: a synchronous disk flush per record was a real performance drain.
  static final Queue<String> _pendingWrites = Queue<String>();

  // Single writer, so concurrent flushes never interleave on the file handle.
  static Future<void> _writeChain = Future<void>.value();

  @visibleForTesting
  static void resetForTesting() {
    _logBuffer.clear();
    _pendingWrites.clear();
    _flushTimer?.cancel();
    _flushTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _writeChain = Future<void>.value();
    _logFile = null;
  }

  static Future<void> setup() async {
    // FINE traces every request; in release it only bloats a file users are asked to share.
    Logger.root.level = kReleaseMode ? Level.INFO : Level.ALL;

    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File(p.join(directory.path, 'app_logs.txt'));

      if (await _logFile!.exists() &&
          await _logFile!.length() > _maxLogFileBytes) {
        await _logFile!.writeAsString('');
      }
    } catch (e, st) {
      if (kDebugMode) {
        developer.log(
          'Failed to initialize log file: $e',
          name: 'MangaBakaApp',
          error: e,
          stackTrace: st,
        );
      }
    }

    // setup() can run more than once; re-subscribing duplicated every log line.
    _subscription ??= Logger.root.onRecord.listen(_onRecord);
    _flushTimer ??= Timer.periodic(_flushInterval, (_) => _flush());
  }

  static void _onRecord(LogRecord record) {
    final buffer = StringBuffer()
      ..write('[${record.level.name}] ${record.time}: ${record.message}');
    if (record.error != null) buffer.write('\nError: ${record.error}');
    if (record.stackTrace != null) {
      buffer.write('\nStackTrace: ${record.stackTrace}');
    }
    // Before console, viewer and file alike: all three end up in shared bug reports.
    final logMessage = LogRedactor.redact(buffer.toString());

    // Profile builds only ever run from `flutter run`, where console logs aid field diagnosis.
    if (kDebugMode || kProfileMode) {
      developer.log(
        logMessage,
        name: 'MangaBakaApp',
        level: record.level.value,
      );
    }

    _logBuffer.add(logMessage);
    if (_logBuffer.length > _maxLogs) {
      _logBuffer.removeAt(0);
    }

    if (_logFile != null) {
      _pendingWrites.add(logMessage);
    }
  }

  static Future<void> _flush() {
    if (_logFile == null || _pendingWrites.isEmpty) return Future<void>.value();

    final payload = '${_pendingWrites.join('\n')}\n';
    _pendingWrites.clear();

    _writeChain = _writeChain.then((_) async {
      try {
        await _logFile!.writeAsString(payload, mode: FileMode.append);
      } catch (e, st) {
        if (kDebugMode) {
          developer.log(
            'Failed to write to log file: $e',
            name: 'MangaBakaApp',
            error: e,
            stackTrace: st,
          );
        }
      }
    });
    return _writeChain;
  }

  static Logger get logger => _logger;
  static List<String> get logs => List.unmodifiable(_logBuffer);

  static Future<void> flush() => _flush();

  static Future<void> clearLogs() async {
    _logBuffer.clear();
    _pendingWrites.clear();
    // A fresh chain drops queued writes, so the file ends up empty regardless.
    _writeChain = Future<void>.value();
    try {
      await _logFile?.writeAsString('');
    } catch (e, st) {
      if (kDebugMode) {
        developer.log(
          'Failed to clear log file: $e',
          name: 'MangaBakaApp',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  static Future<String?> getLogFilePath() async {
    // The caller reads the file next, so buffered lines must be on disk.
    await flush();
    return _logFile?.path;
  }
}
