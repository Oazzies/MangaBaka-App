import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';

class ShortcutButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const ShortcutButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppConstants.secondaryBackground,
      borderRadius: BorderRadius.circular(AppConstants.largeRadius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, color: AppConstants.textColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppConstants.textMutedColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
