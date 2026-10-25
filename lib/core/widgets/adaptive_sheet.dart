import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';

/// Whether panels should open as a centred dialog rather than rising from the
/// bottom edge: a bottom sheet is a phone-in-the-hand gesture, and in
/// landscape or on desktop it is a long way from the pointer and stretches
/// across the whole window.
bool prefersDialogSheet(BuildContext context) =>
    DesktopLayout.isActive(context) ||
    MediaQuery.orientationOf(context) == Orientation.landscape;

/// [showModalBottomSheet] in portrait; a centred, width-limited dialog (fade
/// and scale) in landscape and on desktop. Takes the sheet's arguments so a
/// call site only changes its name.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  bool isScrollControlled = false,
  bool showDragHandle = false,
  ShapeBorder? shape,
  bool useSafeArea = false,
  BoxConstraints? constraints,
  double? elevation,
  bool isDismissible = true,
}) {
  if (!prefersDialogSheet(context)) {
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      backgroundColor: backgroundColor,
      isScrollControlled: isScrollControlled,
      showDragHandle: showDragHandle,
      shape: shape,
      useSafeArea: useSafeArea,
      constraints: constraints,
      elevation: elevation,
      isDismissible: isDismissible,
    );
  }
  return showDialog<T>(
    context: context,
    barrierDismissible: isDismissible,
    builder: (dialogContext) {
      final transparent = backgroundColor == null || backgroundColor.a == 0;
      final maxWidth = constraints?.maxWidth;
      return Dialog(
        backgroundColor: transparent
            ? dialogContext.colors.surface
            : backgroundColor,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: (maxWidth != null && maxWidth.isFinite && maxWidth < 560)
                ? maxWidth
                : 560,
            maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.9,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: builder(dialogContext),
          ),
        ),
      );
    },
  );
}
