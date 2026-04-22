import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

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
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, color: AppConstants.textColor, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: AppConstants.textColor, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
