import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/tri_state_chip.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class FilterListItem extends StatelessWidget {
  final String name;
  final TriState state;
  final VoidCallback onToggleInclude;
  final VoidCallback onToggleExclude;

  const FilterListItem({
    super.key,
    required this.name,
    required this.state,
    required this.onToggleInclude,
    required this.onToggleExclude,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggleInclude,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: AppTypography.sans(
                    color: state != TriState.off
                        ? context.colors.text
                        : context.colors.textMuted,
                    fontSize: 16,
                    fontWeight: state != TriState.off
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              _buildActionIcon(
                context,
                icon: Icons.check_circle,
                isActive: state == TriState.include,
                activeColor: context.colors.accent,
                onTap: onToggleInclude,
              ),
              const SizedBox(width: 8),
              _buildActionIcon(
                context,
                icon: Icons.cancel,
                isActive: state == TriState.exclude,
                activeColor: context.colors.error,
                onTap: onToggleExclude,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon(
    BuildContext context, {
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive
              ? activeColor
              : context.colors.border.withValues(alpha: 0.3),
          size: 26,
        ),
      ),
    );
  }
}
