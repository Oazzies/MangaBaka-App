import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/features/browse/screens/barcode_scanner_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScanLauncher {
  CameraScanLauncher._();

  static final _logger = LoggingService.logger;

  /// Null for any non-result; where there was something to say, a snack bar already said it.
  static Future<String?> scan(BuildContext context) async {
    _logger.info('Requested barcode scan');

    if (!await _ensurePermission(context)) return null;

    _logger.fine('Camera permission granted, opening scanner');
    if (!context.mounted) return null;

    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (code == null || code.isEmpty) {
      _logger.fine('Barcode scan cancelled or empty');
      return null;
    }
    _logger.info('Scanned ISBN: $code');
    return code;
  }

  /// permission_handler lacks macOS support and desktops prompt on first use, so only mobile asks.
  static Future<bool> _ensurePermission(BuildContext context) async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    final status = await Permission.camera.request();
    if (status.isGranted) return true;
    if (!context.mounted) return false;

    // A permanent denial can only be undone in system settings, so offer a way there.
    final permanent = status.isPermanentlyDenied;
    _logger.warning(
      permanent
          ? 'Camera permission permanently denied'
          : 'Camera permission denied (status: $status)',
    );
    _showDeniedSnackBar(context, offerSettings: permanent);
    return false;
  }

  static void _showDeniedSnackBar(
    BuildContext context, {
    required bool offerSettings,
  }) {
    final l10n = LocalizationService();
    AppSnackBar.show(
      context,
      l10n.translate('camera_permission_denied'),
      isError: true,
      action: offerSettings
          ? SnackBarAction(
              label: l10n.translate('settings'),
              onPressed: openAppSettings,
            )
          : null,
    );
  }
}
