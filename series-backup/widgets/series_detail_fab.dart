import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';

class SeriesDetailFAB extends StatelessWidget {
  final Stream<LibraryEntry?>? entryStream;
  final bool isAdding;
  final VoidCallback onAdd;

  const SeriesDetailFAB({
    super.key,
    required this.entryStream,
    required this.isAdding,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = getIt<ProfileAuthService>().isLoggedIn;
    if (!isLoggedIn) return const SizedBox.shrink();
    
    return StreamBuilder<LibraryEntry?>(
      stream: entryStream,
      builder: (context, snapshot) {
        if (snapshot.data == null) {
          return WidgetUtils.tooltip(
            message: LocalizationService().translate('add_to_library'),
            child: FloatingActionButton.extended(
              key: const Key('add_to_library_fab'),
              onPressed: isAdding ? null : onAdd,
              backgroundColor: AppConstants.accentColor,
              foregroundColor: AppConstants.primaryBackground,
              label: isAdding 
                ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.primaryBackground))
                : Text(LocalizationService().translate('add_to_library'), style: const TextStyle(fontWeight: FontWeight.bold)),
              icon: isAdding ? null : const Icon(Icons.add),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
