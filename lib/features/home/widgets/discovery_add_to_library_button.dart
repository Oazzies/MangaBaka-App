import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';

/// Primary "add to library" pill with an attached dropdown for choosing the
/// target state. The dropdown only changes the button's label; the state is
/// applied when the main button is pressed.
class DiscoveryAddToLibraryButton extends StatelessWidget {
  final String selectedState;
  final List<String> states;
  final ValueChanged<String> onStateSelected;
  final VoidCallback? onAdd;
  final bool busy;
  final bool expand;

  const DiscoveryAddToLibraryButton({
    super.key,
    required this.selectedState,
    required this.states,
    required this.onStateSelected,
    required this.onAdd,
    this.busy = false,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final enabled = onAdd != null && !busy;
    final bg = enabled
        ? context.colors.accent
        : context.colors.accent.withValues(alpha: 0.35);
    final fg = context.colors.onAccent;

    final addSection = MbTappable(
      onTap: enabled ? onAdd : null,
      pressedScale: 0.975,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy) MbSpinner(size: 16, strokeWidth: 2, color: fg),
            if (busy) const SizedBox(width: 10),
            Flexible(
              child: Text(
                '+ ${l10n.translate(selectedState)}'.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: AppTypography.display(color: fg, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );

    final menuSection = PopupMenuButton<String>(
      enabled: !busy,
      tooltip: l10n.translate('import_add_as'),
      color: context.colors.surface,
      padding: EdgeInsets.zero,
      onSelected: onStateSelected,
      itemBuilder: (context) => [
        for (final state in states)
          PopupMenuItem(
            value: state,
            child: Text(
              l10n.translate(state),
              style: AppTypography.sans(color: context.colors.text),
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        child: Icon(Icons.arrow_drop_down_rounded, size: 22, color: fg),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      child: ColoredBox(
        color: bg,
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (expand) Expanded(child: addSection) else addSection,
            Container(width: 1, height: 24, color: fg.withValues(alpha: 0.3)),
            menuSection,
          ],
        ),
      ),
    );
  }
}
