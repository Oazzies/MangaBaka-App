import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Add-to-library for the wide (desktop) layout: a full-width button that sits
/// in the sidebar under the information card, instead of floating over the
/// page as a FAB does on a phone.
///
/// Shows only for a signed-in user whose series is not yet in the library,
/// like the FAB; the caller decides where it goes.
class SeriesAddToLibraryButton extends StatelessWidget {
  final bool isAdding;
  final VoidCallback onAdd;

  const SeriesAddToLibraryButton({
    super.key,
    required this.isAdding,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        key: const Key('add_to_library_button'),
        onPressed: isAdding ? null : onAdd,
        icon: isAdding
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.colors.onAccent.withValues(alpha: 0.5),
                ),
              )
            : const Icon(Icons.add_rounded, size: 18),
        label: Text(
          LocalizationService().translate('add_to_library').toUpperCase(),
        ),
      ),
    );
  }
}

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
              backgroundColor: isAdding
                  ? context.colors.accent.withValues(alpha: 0.35)
                  : context.colors.accent,
              foregroundColor: isAdding
                  ? context.colors.onAccent.withValues(alpha: 0.35)
                  : context.colors.onAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.pillRadius),
              ),
              label: Text(
                LocalizationService().translate('add_to_library').toUpperCase(),
                style: AppTypography.display(
                  color: isAdding
                      ? context.colors.onAccent.withValues(alpha: 0.35)
                      : context.colors.onAccent,
                  fontSize: 15,
                ),
              ),
              icon: isAdding
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          context.colors.onAccent.withValues(alpha: 0.35),
                        ),
                      ),
                    )
                  : const Icon(Icons.add_rounded, size: 18),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
