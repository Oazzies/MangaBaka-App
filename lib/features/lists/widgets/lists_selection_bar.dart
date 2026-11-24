import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';

class SelectionAction {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool destructive;

  const SelectionAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });
}

/// Overlaid at the bottom of its Stack, so the content under it never moves.
class ListsSelectionBar extends StatelessWidget {
  final bool visible;
  final int count;
  final bool busy;
  final List<SelectionAction> actions;
  final VoidCallback onClose;
  final VoidCallback? onSelectAll;

  const ListsSelectionBar({
    super.key,
    required this.visible,
    required this.count,
    required this.actions,
    required this.onClose,
    this.onSelectAll,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = LocalizationService();
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 1.5),
        duration: AppMotion.base,
        curve: visible ? AppMotion.enter : AppMotion.exit,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: AppMotion.fast,
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.border),
                    boxShadow: c.softShadow,
                  ),
                  child: DerivedLayoutBuilder<bool>(
                    derive: (constraints) => constraints.maxWidth >= 560,
                    builder: (context, roomy) => Padding(
                      padding: const EdgeInsets.all(6),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: l10n.translate('close'),
                            icon: Icon(Icons.close_rounded, color: c.text),
                            onPressed: onClose,
                          ),
                          Expanded(
                            child: Text(
                              l10n
                                  .translate('lists_selected_count')
                                  .replaceAll('{count}', '$count'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.sans(
                                color: c.text,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (onSelectAll != null)
                            IconButton(
                              tooltip: l10n.translate('select_all'),
                              icon: Icon(
                                Icons.select_all_rounded,
                                color: c.text,
                              ),
                              onPressed: busy ? null : onSelectAll,
                            ),
                          if (busy)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: MbSpinner(size: 20),
                            )
                          else
                            for (final a in actions)
                              roomy ? _labelled(context, a) : _icon(context, a),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _colorOf(MbPalette c, SelectionAction a) {
    if (a.onPressed == null) return c.textMuted.withValues(alpha: 0.5);
    return a.destructive ? c.error : c.text;
  }

  Widget _labelled(BuildContext context, SelectionAction a) {
    final c = context.colors;
    final color = _colorOf(c, a);
    return TextButton.icon(
      onPressed: a.onPressed,
      icon: Icon(a.icon, size: 19, color: color),
      label: Text(
        a.label,
        style: AppTypography.sans(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _icon(BuildContext context, SelectionAction a) {
    final c = context.colors;
    return IconButton(
      tooltip: a.label,
      icon: Icon(a.icon, color: _colorOf(c, a)),
      onPressed: a.onPressed,
    );
  }
}
