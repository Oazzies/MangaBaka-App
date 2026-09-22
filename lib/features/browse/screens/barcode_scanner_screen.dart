import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/fixed_colors.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  static final _logger = LoggingService.logger;
  final MobileScannerController _scannerController = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
    ], // ISBNs are usually EAN-13
  );

  bool _isScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? barcodeValue = barcodes.first.rawValue;
      if (barcodeValue != null && barcodeValue.isNotEmpty) {
        _logger.info('Barcode detected: $barcodeValue');
        setState(() {
          _isScanned = true;
        });
        Navigator.pop(context, barcodeValue);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) {
        final l10n = LocalizationService();
        return Scaffold(
          backgroundColor: FixedColors.imageScrim,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(l10n.translate('scan_isbn_barcode').toUpperCase()),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: context.colors.text),
            titleTextStyle: AppTypography.display(
              color: context.colors.text,
              fontSize: 18,
            ),
          ),
          body: Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
              ),
              // Scanner overlay
              Center(
                child: Container(
                  width: 300,
                  height: 150, // Typical proportion for 1D barcodes like ISBN
                  decoration: BoxDecoration(
                    border: Border.all(color: context.colors.accent, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: FixedColors.imageScrim.withValues(alpha: 0.54),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.translate('align_barcode'),
                      style: AppTypography.sans(
                        color: FixedColors.onImage,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
