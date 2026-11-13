import 'dart:io';

import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:win32_registry/win32_registry.dart';

class DeepLinkRegistrar {
  static final _logger = LoggingService.logger;

  /// Registers [scheme]`://` in HKCU\Software\Classes so Windows launches
  /// this executable when the scheme is opened.
  static Future<void> registerWindows(String scheme) async {
    try {
      final appPath = Platform.resolvedExecutable;
      final regKeyPath = 'Software\\Classes\\$scheme';
      final command = '"$appPath" "%1"';

      if (_windowsCommand(regKeyPath) == command) return;

      _logger.info('DeepLinkService: registering $scheme:// on Windows');

      final key = CURRENT_USER.create(regKeyPath);
      key.setValue('', RegistryValue.string('URL:MangaBaka'));
      key.setValue('URL Protocol', RegistryValue.string(''));

      final commandKey = key.create('shell\\open\\command');
      commandKey.setValue('', RegistryValue.string(command));

      commandKey.close();
      key.close();

      _logger.info('DeepLinkService: Windows protocol registration done');
    } catch (e) {
      _logger.warning(
        'DeepLinkService: Windows protocol registration failed: $e',
      );
    }
  }

  static String? _windowsCommand(String regKeyPath) {
    try {
      final key = CURRENT_USER.open('$regKeyPath\\shell\\open\\command');
      try {
        final value = key.getValue('');
        return value is StringValue ? value.value : null;
      } finally {
        key.close();
      }
    } catch (e) {
      _logger.fine('DeepLinkService: Windows registry lookup skipped: $e');
      return null;
    }
  }

  /// Registers [scheme]`://` on Linux via a .desktop file and `xdg-mime`.
  static Future<void> registerLinux(String scheme) async {
    try {
      final homeDir = Platform.environment['HOME'];
      if (homeDir == null) return;

      final appDir = Directory('$homeDir/.local/share/applications');
      if (!appDir.existsSync()) appDir.createSync(recursive: true);

      final desktopFile = File('${appDir.path}/mangabaka.desktop');
      final execPath = Platform.resolvedExecutable;

      final iconDir = Directory(
        '$homeDir/.local/share/icons/hicolor/512x512/apps',
      );
      final targetIcon = File('${iconDir.path}/mangabaka.png');
      if (!targetIcon.existsSync()) {
        final exeDir = File(execPath).parent;
        final assetIcon = File(
          '${exeDir.path}/data/flutter_assets/assets/mangabaka512.png',
        );
        if (assetIcon.existsSync()) {
          iconDir.createSync(recursive: true);
          try {
            assetIcon.copySync(targetIcon.path);
          } catch (e) {
            _logger.warning('DeepLinkService: failed to copy desktop icon: $e');
          }
        }
      }

      final contents =
          '''
[Desktop Entry]
Type=Application
Name=MangaBaka
Exec="$execPath" %u
Icon=mangabaka
Terminal=false
Categories=Utility;Network;Viewer;
MimeType=x-scheme-handler/$scheme;x-scheme-handler/dev.oazzies.mangabaka;
StartupWMClass=dev.oazzies.mangabaka_app
''';

      if (!desktopFile.existsSync() ||
          desktopFile.readAsStringSync() != contents) {
        desktopFile.writeAsStringSync(contents);
      }

      await Process.run('xdg-mime', [
        'default',
        'mangabaka.desktop',
        'x-scheme-handler/$scheme',
      ]);
      await Process.run('xdg-mime', [
        'default',
        'mangabaka.desktop',
        'x-scheme-handler/dev.oazzies.mangabaka',
      ]);
      await Process.run('update-desktop-database', [appDir.path]);

      _logger.info('DeepLinkService: Linux protocol registration done');
    } catch (e) {
      _logger.warning(
        'DeepLinkService: Linux protocol registration failed: $e',
      );
    }
  }
}
