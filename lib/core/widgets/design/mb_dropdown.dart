import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';

/// A labelled dropdown that suits the layout: on desktop the app's own
/// [DesktopMenuButton] (a menu under the pointer, as the Browse sort uses); on
/// a phone a pill that raises a bottom sheet of the options.
///
/// [value] is the selected option's key; options are `(key, label)` pairs.
class MbDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  final IconData icon;

  const MbDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.icon = Icons.filter_list_rounded,
  });

  String get _valueLabel =>
      options.firstWhere((o) => o.$1 == value, orElse: () => options.first).$2;

  @override
  Widget build(BuildContext context) {
    if (DesktopLayout.isActive(context)) {
      return DesktopMenuButton<T>(
        label: label,
        valueLabel: _valueLabel,
        icon: icon,
        selected: value,
        items: options,
        onSelected: onChanged,
      );
    }
    return _PhonePill<T>(
      label: label,
      valueLabel: _valueLabel,
      icon: icon,
      onTap: () => showMbOptionSheet<T>(
        context,
        title: label,
        options: options,
        current: value,
        onSelected: onChanged,
      ),
    );
  }
}

class _PhonePill<T> extends StatelessWidget {
  final String label;
  final String valueLabel;
  final IconData icon;
  final VoidCallback onTap;

  const _PhonePill({
    required this.label,
    required this.valueLabel,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MbTappable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colors.textMuted),
            const SizedBox(width: 8),
            Text(
              '${label.toUpperCase()}: ',
              style: AppTypography.monoLabel(
                color: colors.textMuted,
                fontSize: 11,
              ),
            ),
            Flexible(
              child: Text(
                valueLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.sans(
                  color: colors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// A bottom sheet listing [options], with the [current] one ticked.
Future<void> showMbOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<(T, String)> options,
  required T current,
  required ValueChanged<T> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: context.colors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppConstants.largeRadius),
      ),
    ),
    builder: (sheetContext) {
      final colors = sheetContext.colors;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: AppTypography.display(color: colors.text, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final (key, label) in options)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          label,
                          style: AppTypography.sans(
                            color: key == current ? colors.accent : colors.text,
                            fontWeight: key == current
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                        trailing: key == current
                            ? Icon(Icons.check_rounded, color: colors.accent)
                            : null,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          onSelected(key);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
