import 'package:flutter/material.dart';
import '../chip.dart';

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    if (status.isEmpty) return SizedBox.shrink();

    final lower = status.toLowerCase();
    final formatted = status[0].toUpperCase() + status.substring(1).toLowerCase();

    Color? bgColor;
    IconData? icon;
    TextStyle? textStyle;
    Color? iconColor;

    if (lower == 'releasing') {
      bgColor = const Color(0xFF0d542b);
      icon = Icons.play_arrow_outlined;
      textStyle = const TextStyle(color: Color(0xFF81e6ca));
      iconColor = const Color(0xFF81e6ca);
    } else if (lower == 'completed') {
      bgColor = const Color(0xFF314158);
      icon = Icons.check_circle_outline_outlined;
      textStyle = const TextStyle(color: Colors.white);
      iconColor = Colors.white;
    } else if (lower == 'hiatus') {
      bgColor = const Color(0xFF733e0a);
      icon = Icons.pause_circle_outline;
      textStyle = const TextStyle(color: Color(0xFFFCE96E));
      iconColor = const Color(0xFFFCE96E);
    }

    return ChipBase(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 4),
          ],
          Text(formatted, style: textStyle),
        ],
      ),
      backgroundColor: bgColor,
    );
  }
}