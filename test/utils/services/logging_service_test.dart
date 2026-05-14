import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() async {
    LoggingService.resetForTesting();
    tempDir = await Directory.systemTemp.createTemp('logging_test');
    
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory' || 
            methodCall.method == 'getApplicationSupportDirectory') {
          return tempDir.path;
        }
        return null;
      },
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('LoggingService', () {
    test('setup initializes log file', () async {
      await LoggingService.setup();
      LoggingService.logger.info('Initial log');
      await Future.delayed(const Duration(milliseconds: 100));
      
      final logFilePath = await LoggingService.getLogFilePath();
      expect(logFilePath, isNotNull);
      
      final logFile = File(logFilePath!);
      expect(await logFile.exists(), true);
    });

    test('logging messages adds to buffer and file', () async {
      await LoggingService.setup();
      
      LoggingService.logger.info('Test log message');
      
      // Wait for the async listener to process the log
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(LoggingService.logs.any((l) => l.contains('Test log message')), true);
      
      final logFilePath = await LoggingService.getLogFilePath();
      final content = await File(logFilePath!).readAsString();
      expect(content.contains('Test log message'), true);
    });

    test('clearLogs clears both buffer and file', () async {
      await LoggingService.setup();
      LoggingService.logger.info('Message to clear');
      await Future.delayed(const Duration(milliseconds: 100));
      
      await LoggingService.clearLogs();
      
      expect(LoggingService.logs, isEmpty);
      
      final logFilePath = await LoggingService.getLogFilePath();
      final content = await File(logFilePath!).readAsString();
      expect(content, isEmpty);
    });
  });
}
