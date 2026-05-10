import 'package:logging/logging.dart';

class LoggingService {
  static final Logger _logger = Logger('MangaBakaApp');
  static final List<String> _logBuffer = [];
  static const int _maxLogs = 1000;

  static void setup() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      final logMessage = '[${record.level.name}] ${record.time}: ${record.message}${record.error != null ? '\nError: ${record.error}' : ''}${record.stackTrace != null ? '\nStackTrace: ${record.stackTrace}' : ''}';
      // ignore: avoid_print
      print(logMessage);
      
      _logBuffer.add(logMessage);
      if (_logBuffer.length > _maxLogs) {
        _logBuffer.removeAt(0);
      }
    });
  }

  static Logger get logger => _logger;
  static List<String> get logs => List.unmodifiable(_logBuffer);
  static void clearLogs() => _logBuffer.clear();
}
