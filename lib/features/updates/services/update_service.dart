import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/updates/models/app_release.dart';
import 'package:mangabaka_app/features/updates/services/update_exceptions.dart';
import 'package:mangabaka_app/features/updates/services/update_installer.dart';

export 'package:mangabaka_app/features/updates/services/update_exceptions.dart';

/// "Later" is deliberately not persisted: the prompt returns each launch while behind.
class UpdateService {
  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  static final _logger = LoggingService.logger;
  final http.Client _client;

  bool _promptedThisLaunch = false;

  /// Store builds leave updates to the store, whose policy forbids self-update.
  static const bool isStoreBuild = bool.fromEnvironment('STORE_BUILD');

  static const _downloadStallTimeout = Duration(seconds: 30);

  bool get supportsInAppUpdate =>
      !isStoreBuild &&
      (Platform.isAndroid || Platform.isWindows || Platform.isLinux);

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

  Future<AppRelease?> checkForUpdate() async {
    // An unread version would parse as 0.0.0 and make every release look newer.
    if (AppConstants.appVersion.isEmpty) return null;
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

  bool shouldPrompt() {
    if (isStoreBuild) return false;
    if (_promptedThisLaunch) return false;
    _promptedThisLaunch = true;
    return true;
  }

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
      } on Exception catch (e) {
        _logger.warning('Could not resolve device ABI: $e');
      }
      const abiTokens = ['arm64-v8a', 'armeabi-v7a', 'x86_64', 'x86'];
      final universal = apks.where(
        (a) => !abiTokens.any((t) => a.name.toLowerCase().contains(t)),
      );
      return universal.isNotEmpty ? universal.first : apks.first;
    }

    if (Platform.isWindows) {
      String lower(ReleaseAsset a) => a.name.toLowerCase();
      final setup = release.assets.where(
        (a) => lower(a).contains('windows') && lower(a).endsWith('.exe'),
      );
      if (setup.isNotEmpty) return setup.first;
      final win = release.assets.where((a) => lower(a).contains('windows'));
      return win.isNotEmpty ? win.first : null;
    }

    if (Platform.isLinux) {
      String lower(ReleaseAsset a) => a.name.toLowerCase();
      final appImage = release.assets.where(
        (a) => lower(a).contains('linux') && lower(a).endsWith('.appimage'),
      );
      if (appImage.isNotEmpty) return appImage.first;
      final debOrRpm = release.assets.where(
        (a) =>
            lower(a).contains('linux') &&
            (lower(a).endsWith('.deb') ||
                lower(a).endsWith('.rpm') ||
                lower(a).endsWith('.tar.gz')),
      );
      if (debOrRpm.isNotEmpty) return debOrRpm.first;
      final lin = release.assets.where((a) => lower(a).contains('linux'));
      return lin.isNotEmpty ? lin.first : null;
    }

    return null;
  }

  /// No sha256, no download: the file runs as an installer and must be verifiable.
  Future<File> downloadAsset(
    ReleaseAsset asset, {
    void Function(double progress)? onProgress,
  }) async {
    final expected = asset.sha256;
    if (expected == null) {
      _logger.warning(
        'Release asset ${asset.name} has no published sha256; refusing to install it',
      );
      throw UpdateIntegrityException.unverifiable();
    }

    final dir = await getTemporaryDirectory();
    // Feed-supplied name: basename keeps the file inside the temp directory.
    final safeName = p.basename(asset.name);
    if (safeName.isEmpty || safeName == '.' || safeName == '..') {
      throw NetworkException(
        message: 'Invalid update file name: ${asset.name}',
      );
    }
    final file = File(p.join(dir.path, safeName));
    if (await file.exists()) {
      await file.delete();
    }

    final request = http.Request('GET', Uri.parse(asset.downloadUrl))
      ..headers['User-Agent'] = AppConstants.userAgent;

    final response = await _client
        .send(request)
        .timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));
    if (response.statusCode != 200) {
      throw NetworkException(
        message: 'Failed to download update (HTTP ${response.statusCode})',
      );
    }

    final total = response.contentLength ?? asset.size;
    var received = 0;
    final sink = file.openWrite();
    // Hashed as it streams, so verifying costs no second read of the file.
    final digestSink = _DigestSink();
    final hasher = sha256.startChunkedConversion(digestSink);
    var complete = false;
    try {
      // A stalled connection would otherwise hang the progress dialog forever.
      await for (final chunk in response.stream.timeout(
        _downloadStallTimeout,
      )) {
        received += chunk.length;
        sink.add(chunk);
        hasher.add(chunk);
        if (onProgress != null && total > 0) {
          onProgress((received / total).clamp(0.0, 1.0));
        }
      }
      await sink.flush();
      complete = true;
    } finally {
      await sink.close();
      if (!complete && await file.exists()) await file.delete();
    }

    // A cleanly dropped connection ends the stream without an error.
    if (total > 0 && received != total) {
      await file.delete();
      throw NetworkException(
        message: 'Update download incomplete ($received of $total bytes)',
      );
    }

    hasher.close();
    final actual = digestSink.value.toString();
    if (actual != expected) {
      await file.delete();
      _logger.severe(
        'Update checksum mismatch for ${asset.name}: expected $expected, got $actual',
      );
      throw UpdateIntegrityException();
    }
    _logger.info('Update checksum verified (sha256 $actual)');

    _logger.info('Downloaded update to ${file.path} ($received bytes)');
    return file;
  }

  Future<void> installDownloaded(File file) =>
      UpdateInstaller.installDownloaded(file);

  @visibleForTesting
  void dispose() => _client.close();
}

class _DigestSink implements Sink<Digest> {
  Digest? _value;

  Digest get value => _value!;

  @override
  void add(Digest data) => _value = data;

  @override
  void close() {}
}
