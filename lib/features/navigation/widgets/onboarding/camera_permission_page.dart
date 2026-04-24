import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class CameraPermissionPage extends StatelessWidget {
  final VoidCallback onRequestPermission;

  const CameraPermissionPage({super.key, required this.onRequestPermission});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 80,
            color: AppConstants.accentColor,
          ),
          const SizedBox(height: 32),
          Text(
            'Barcode Scanner',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'We need camera access to let you scan manga volume barcodes to quickly find them in the app.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppConstants.textMutedColor,
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: onRequestPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.accentColor,
              foregroundColor: AppConstants.primaryBackground,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              ),
            ),
            child: const Text(
              'Grant Camera Permission',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
