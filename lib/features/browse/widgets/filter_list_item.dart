import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/features/browse/widgets/tri_state_chip.dart';

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
                  style: TextStyle(
                    color: state != TriState.off ? AppConstants.textColor : AppConstants.textMutedColor,
                    fontSize: 16,
                    fontWeight: state != TriState.off ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              _buildActionIcon(
                icon: Icons.check_circle,
                isActive: state == TriState.include,
                activeColor: AppConstants.accentColor,
                onTap: onToggleInclude,
              ),
              const SizedBox(width: 8),
              _buildActionIcon(
                icon: Icons.cancel,
                isActive: state == TriState.exclude,
                activeColor: AppConstants.errorColor,
                onTap: onToggleExclude,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon({
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
          color: isActive ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? activeColor : AppConstants.borderColor.withValues(alpha: 0.3),
          size: 26,
        ),
      ),
    );
  }
}
