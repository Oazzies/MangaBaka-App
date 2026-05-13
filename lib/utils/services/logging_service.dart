import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class LoggingService {
  static final Logger _logger = Logger('MangaBakaApp');
  static final List<String> _logBuffer = [];
  static const int _maxLogs = 1000;
  static File? _logFile;

  static Future<void> setup() async {
    Logger.root.level = Level.ALL;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File(p.join(directory.path, 'app_logs.txt'));
      
      // Clear old logs if they get too large (e.g. > 10MB)
      if (await _logFile!.exists() && await _logFile!.length() > 10 * 1024 * 1024) {
        await _logFile!.writeAsString('');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Failed to initialize log file: $e');
    }

    Logger.root.onRecord.listen((record) async {
      final logMessage = '[${record.level.name}] ${record.time}: ${record.message}${record.error != null ? '\nError: ${record.error}' : ''}${record.stackTrace != null ? '\nStackTrace: ${record.stackTrace}' : ''}';
      
      // ignore: avoid_print
      print(logMessage);
      
      _logBuffer.add(logMessage);
      if (_logBuffer.length > _maxLogs) {
        _logBuffer.removeAt(0);
      }

      try {
        if (_logFile != null) {
          await _logFile!.writeAsString('$logMessage\n', mode: FileMode.append, flush: true);
        }
      } catch (e) {
        // ignore: avoid_print
        print('Failed to write to log file: $e');
      }
    });
  }

  static Logger get logger => _logger;
  static List<String> get logs => List.unmodifiable(_logBuffer);
  
  static Future<void> clearLogs() async {
    _logBuffer.clear();
    try {
      if (_logFile != null && await _logFile!.exists()) {
        await _logFile!.writeAsString('');
      }
    } catch (e) {
      _logger.severe('Failed to clear log file: $e');
    }
  }

  static Future<String?> getLogFilePath() async {
    if (_logFile != null && await _logFile!.exists()) {
      return _logFile!.path;
    }
    return null;
  }
}
