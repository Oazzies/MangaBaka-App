import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/updates/models/app_release.dart';

/// Handles checking GitHub for a newer release, downloading the right asset
/// for the current platform, and applying the update.
///
/// The update prompt is shown once per app launch and is *not* persisted as
/// "dismissed": tapping "Later" simply closes it, so it reappears on the next
/// launch as long as the installed version is still behind the latest release.
class UpdateService {
  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  static final _logger = LoggingService.logger;
  final http.Client _client;

  bool _promptedThisLaunch = false;

  /// Whether this platform can download and apply an update in-app. Other
  /// platforms fall back to opening the release page in a browser.
  bool get supportsInAppUpdate => Platform.isAndroid || Platform.isWindows;

  /// Returns the newest non-draft release (including pre-releases), or `null` on failure.
  Future<AppRelease?> fetchLatestRelease() async {
    final url = '${AppConstants.githubReleasesApi}?per_page=5';
    try {
      final response = await _client
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent': AppConstants.userAgent,
              'Accept': 'application/vnd.github+json',
            },
          )
          .timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));

      if (response.statusCode != 200) {
        _logger.warning(
          'Update check failed (HTTP ${response.statusCode}) for $url',
        );
        return null;
      }

      final List data = jsonDecode(response.body) as List;
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final release = AppRelease.fromJson(item);
          if (!release.draft) return release; // newest non-draft release
        }
      }
      return null;
    } catch (e, st) {
      _logger.warning('Update check failed: $e', e, st);
      return null;
    }
  }

  /// Returns the latest release if it is newer than the installed version,
  /// otherwise `null`.
  Future<AppRelease?> checkForUpdate() async {
    final latest = await fetchLatestRelease();
    if (latest == null) return null;

    final current = AppVersion.parse(AppConstants.appVersion);
    if (latest.version.isNewerThan(current)) {
      _logger.info(
        'Update available: ${latest.tagName} (installed ${AppConstants.appVersion})',
      );
      return latest;
    }
    _logger.fine('App is up to date (${AppConstants.appVersion}).');
    return null;
  }

  /// Returns `true` once per launch if an update check should be performed.
  /// Marks the launch as prompted so callers don't re-trigger on rebuilds.
  bool shouldPrompt() {
    if (_promptedThisLaunch) return false;
    _promptedThisLaunch = true;
    return true;
  }

  /// Picks the asset matching the current platform, or `null` if none fits.
  Future<ReleaseAsset?> selectAssetForPlatform(AppRelease release) async {
    if (release.assets.isEmpty) return null;

    if (Platform.isAndroid) {
      final apks = release.assets
          .where((a) => a.name.toLowerCase().endsWith('.apk'))
          .toList();
      if (apks.isEmpty) return null;
      if (apks.length == 1) return apks.first;

      // Match the device's preferred ABI (supportedAbis is best-first).
      try {
        final info = await DeviceInfoPlugin().androidInfo;
        for (final abi in info.supportedAbis) {
          final token = abi.toLowerCase();
          final match = apks.where((a) => a.name.toLowerCase().contains(token));
          if (match.isNotEmpty) return match.first;
        }
      } catch (e) {
        _logger.warning('Could not resolve device ABI: $e');
      }
      // Prefer a universal apk (no abi token) if present, else the first.
      const abiTokens = ['arm64-v8a', 'armeabi-v7a', 'x86_64', 'x86'];
      final universal = apks.where(
        (a) => !abiTokens.any((t) => a.name.toLowerCase().contains(t)),
      );
      return universal.isNotEmpty ? universal.first : apks.first;
    }

    if (Platform.isWindows) {
      String lower(ReleaseAsset a) => a.name.toLowerCase();
      // The Inno Setup installer is the preferred Windows artifact.
      final setup = release.assets.where(
        (a) => lower(a).contains('windows') && lower(a).endsWith('.exe'),
      );
      if (setup.isNotEmpty) return setup.first;
      final win = release.assets.where((a) => lower(a).contains('windows'));
      return win.isNotEmpty ? win.first : null;
    }

    return null;
  }

  /// Downloads [asset] to a temporary file, reporting progress in `[0, 1]`.
  Future<File> downloadAsset(
    ReleaseAsset asset, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}${asset.name}');
    if (await file.exists()) {
      await file.delete();
    }

    final request = http.Request('GET', Uri.parse(asset.downloadUrl))
      ..headers['User-Agent'] = AppConstants.userAgent;

    final response = await _client.send(request);
    if (response.statusCode != 200) {
      throw NetworkException(
        message: 'Failed to download update (HTTP ${response.statusCode})',
      );
    }

    final total = response.contentLength ?? asset.size;
    var received = 0;
    final sink = file.openWrite();
    try {
      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (onProgress != null && total > 0) {
          onProgress((received / total).clamp(0.0, 1.0));
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    _logger.info('Downloaded update to ${file.path} ($received bytes)');
    return file;
  }

  /// Applies a downloaded update file. On Android this launches the system
  /// package installer; on Windows it runs the installer and quits the app so
  /// it can replace the running files.
  Future<void> installDownloaded(File file) async {
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
      await Process.start(
        file.path,
        const [],
        mode: ProcessStartMode.detached,
      );
      // Give the installer a moment to spawn, then quit so it can overwrite
      // the running executable.
      await Future.delayed(const Duration(milliseconds: 500));
      exit(0);
    }

    throw NetworkException(
      message: 'In-app updates are not supported on this platform.',
    );
  }

  @visibleForTesting
  void dispose() => _client.close();
}

/// Thrown when the user denies the "install unknown apps" permission required
/// to apply an Android update.
class InstallPermissionException extends AppException {
  InstallPermissionException()
      : super(message: 'Install permission was denied.');
}
