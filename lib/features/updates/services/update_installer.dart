import 'dart:io';

import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/features/updates/services/update_exceptions.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateInstaller {
  /// Applies a downloaded update file. On Android this launches the system
  /// package installer; on Windows it runs the installer and quits the app so
  /// it can replace the running files.
  static Future<void> installDownloaded(File file) async {
    if (Platform.isAndroid) {
      var status = await Permission.requestInstallPackages.status;
      if (!status.isGranted) {
        status = await Permission.requestInstallPackages.request();
      }
      if (!status.isGranted) {
        throw InstallPermissionException();
      }
      final result = await OpenFilex.open(
        file.path,
        type: 'application/vnd.android.package-archive',
      );
      if (result.type != ResultType.done) {
        throw NetworkException(
          message: 'Could not open the installer: ${result.message}',
        );
      }
      return;
    }

    if (Platform.isWindows) {
      await Process.start(file.path, const [], mode: ProcessStartMode.detached);
      // Give the installer a moment to spawn, then quit so it can overwrite
      // the running executable.
      await Future.delayed(const Duration(milliseconds: 500));
      exit(0);
    }

    if (Platform.isLinux) {
      final lowerPath = file.path.toLowerCase();
      if (lowerPath.endsWith('.appimage')) {
        await Process.run('chmod', ['+x', file.path]);
        await Process.start(
          file.path,
          const [],
          mode: ProcessStartMode.detached,
        );
        await Future.delayed(const Duration(milliseconds: 500));
        exit(0);
      }
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        throw NetworkException(
          message: 'Could not open the update file: ${result.message}',
        );
      }
      return;
    }

    throw NetworkException(
      message: 'In-app updates are not supported on this platform.',
    );
  }
}
