import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:win32_registry/win32_registry.dart';

/// Listens to incoming `https://mangabaka.org` and `mangabaka://` links,
/// then routes the user to the matching screen inside the app.
///
/// Platform registration:
///   Android  — intent filters in AndroidManifest.xml
///   iOS      — CFBundleURLSchemes in ios/Runner/Info.plist
///   macOS    — CFBundleURLTypes in macos/Runner/Info.plist
///   Windows  — `mangabaka://` registered in HKCU\Software\Classes at init
///   Linux    — `mangabaka://` registered via a .desktop file at init
///
/// The service respects the [SettingsManager.openLinksInApp] toggle; links
/// that arrive while the toggle is off are silently ignored.
class DeepLinkService {
  static final _logger = LoggingService.logger;
  static const _scheme = 'mangabaka';

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  Future<void> init() async {
    // Register the custom protocol with the OS on platforms that need it.
    if (Platform.isWindows) await _registerWindows();
    if (Platform.isLinux) await _registerLinux();

    // Handle the link that cold-started the app (if any).
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial);
    } catch (e) {
      _logger.warning('DeepLinkService: failed to read initial link: $e');
    }

    // Handle subsequent links while the app is running.
    _sub = _appLinks.uriLinkStream.listen(
      _handle,
      onError: (e) =>
          _logger.warning('DeepLinkService: link stream error: $e'),
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  // ─── OS-level protocol registration ──────────────────────────────────────

  /// Registers `mangabaka://` in the Windows registry under
  /// HKCU\Software\Classes so the OS knows to launch this executable when
  /// the scheme is opened. Identical to the pattern already used by
  /// [WindowsAuthHandler.registerProtocol].
  Future<void> _registerWindows() async {
    try {
      final appPath = Platform.resolvedExecutable;
      final regKeyPath = 'Software\\Classes\\$_scheme';

      _logger.info('DeepLinkService: registering $_scheme:// on Windows');

      final key = CURRENT_USER.create(regKeyPath);
      key.setValue('', RegistryValue.string('URL:MangaBaka'));
      key.setValue('URL Protocol', RegistryValue.string(''));

      final commandKey = key.create('shell\\open\\command');
      commandKey.setValue('', RegistryValue.string('"$appPath" "%1"'));

      commandKey.close();
      key.close();

      _logger.info('DeepLinkService: Windows protocol registration done');
    } catch (e) {
      _logger.warning('DeepLinkService: Windows protocol registration failed: $e');
    }
  }

  /// Registers `mangabaka://` on Linux via a .desktop file in
  /// ~/.local/share/applications and `xdg-mime`.
  Future<void> _registerLinux() async {
    try {
      final homeDir = Platform.environment['HOME'];
      if (homeDir == null) return;

      final appDir = Directory('$homeDir/.local/share/applications');
      if (!appDir.existsSync()) appDir.createSync(recursive: true);

      final desktopFile = File('${appDir.path}/mangabaka.desktop');
      final execPath = Platform.resolvedExecutable;

      desktopFile.writeAsStringSync('''
[Desktop Entry]
Type=Application
Name=MangaBaka
Exec="$execPath" %u
Icon=mangabaka
Terminal=false
Categories=Utility;
MimeType=x-scheme-handler/$_scheme;
''');

      await Process.run(
          'xdg-mime', ['default', 'mangabaka.desktop', 'x-scheme-handler/$_scheme']);
      await Process.run('update-desktop-database', [appDir.path]);

      _logger.info('DeepLinkService: Linux protocol registration done');
    } catch (e) {
      _logger.warning('DeepLinkService: Linux protocol registration failed: $e');
    }
  }

  // ─── Routing ─────────────────────────────────────────────────────────────

  void _handle(Uri uri) {
    if (!SettingsManager().openLinksInApp) {
      _logger.fine('DeepLinkService: ignoring link (toggle off): $uri');
      return;
    }
    _logger.info('DeepLinkService: handling link: $uri');

    // ── mangabaka://series/<id>  or  https://mangabaka.org/series/<id> ──
    final seriesId = _extractSeriesId(uri);
    if (seriesId != null) {
      _openSeries(seriesId);
      return;
    }

    _logger.fine('DeepLinkService: no handler for link: $uri');
  }

  /// Extracts a series ID from supported URL shapes:
  ///
  /// - `https://mangabaka.org/series/<id>`
  /// - `https://mangabaka.org/series/<id>/anything`
  /// - `mangabaka://series/<id>`
  String? _extractSeriesId(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'series') {
      final id = segments[1];
      if (id.isNotEmpty) return id;
    }
    // Custom scheme: mangabaka://series/<id>
    if (uri.scheme == _scheme &&
        uri.host == 'series' &&
        uri.pathSegments.isNotEmpty) {
      final id = uri.pathSegments.first;
      if (id.isNotEmpty) return id;
    }
    return null;
  }

  // ─── Navigation ──────────────────────────────────────────────────────────

  Future<void> _openSeries(String seriesId) async {
    _logger.info('DeepLinkService: opening series $seriesId');
    final context = AppConstants.navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      _logger.warning('DeepLinkService: no context available for navigation');
      return;
    }

    try {
      final series = await getIt<SeriesService>().fetchSeries(seriesId);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).push(
        AppTransitions.slideUp(SeriesDetailScreen(series: series)),
      );
    } catch (e) {
      _logger.warning('DeepLinkService: failed to open series $seriesId: $e');
      final ctx = AppConstants.navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        AppSnackBar.show(ctx, 'Could not open that link.', isError: true);
      }
    }
  }
}
