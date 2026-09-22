import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/list_customization_scope.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The Library / Browse switch at the top of the list customization panel.
///
/// A sliding pill rather than two buttons, so the selected side is legible at
/// a glance and the transition matches the panel sliding beneath it.
class ListScopeTabSelector extends StatelessWidget {
  final ListScopeTab active;
  final String libraryLabel;
  final String browseLabel;
  final ValueChanged<ListScopeTab> onChanged;

  static const Duration _pillDuration = Duration(milliseconds: 180);
  static const Duration _labelDuration = Duration(milliseconds: 150);

  const ListScopeTabSelector({
    super.key,
    required this.active,
    required this.libraryLabel,
    required this.browseLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 38,
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: context.colors.surfaceRaised, width: 1.5),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                alignment: active.isLibrary
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                duration: _pillDuration,
                curve: Curves.easeOutCubic,
                child: Container(
                  width: constraints.maxWidth / 2,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: context.colors.accent,
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              Row(
                children: [
                  _Tab(
                    label: libraryLabel,
                    isActive: active.isLibrary,
                    onTap: () => onChanged(ListScopeTab.library),
                  ),
                  _Tab(
                    label: browseLabel,
                    isActive: !active.isLibrary,
                    onTap: () => onChanged(ListScopeTab.browse),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        // Opaque so the whole half is tappable, not just the text.
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: ListScopeTabSelector._labelDuration,
            curve: Curves.easeInOut,
            style: AppTypography.sans(
              // The active label sits on the accent pill, so it inverts to the
              // page background colour to stay readable.
              color: isActive ? context.colors.background : context.colors.text,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
