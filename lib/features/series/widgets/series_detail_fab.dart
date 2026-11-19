import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';

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
        // Matches the phone's extended FAB so the two read as the same action.
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          ),
          textStyle: AppTypography.display(fontSize: 15),
        ),
        icon: isAdding
            ? MbSpinner(
                size: 18,
                strokeWidth: 2,
                color: context.colors.onAccent.withValues(alpha: 0.5),
              )
            : const Icon(Icons.add_rounded, size: 20),
        label: Text(
          LocalizationService().translate('add_to_library').toUpperCase(),
        ),
      ),
    );
  }
}

class SeriesDetailFAB extends StatelessWidget {
  final bool isLoggedIn;
  final Stream<LibraryEntry?>? entryStream;
  final bool isAdding;
  final VoidCallback onAdd;

  const SeriesDetailFAB({
    super.key,
    required this.isLoggedIn,
    required this.entryStream,
    required this.isAdding,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
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
                  ? MbSpinner(
                      size: 18,
                      strokeWidth: 2,
                      color: context.colors.onAccent.withValues(alpha: 0.35),
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
