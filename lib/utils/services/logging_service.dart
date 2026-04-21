import 'package:logging/logging.dart';

class LoggingService {
  static final Logger _logger = Logger('BakaHyouApp');

  static void setup() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  static Logger get logger => _logger;
}
