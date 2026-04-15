import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/widgets/chip.dart';

class ContentRatingChip extends StatelessWidget {
  final String rating;
  const ContentRatingChip({required this.rating, super.key});

  @override
  Widget build(BuildContext context) {
    if (rating.isEmpty) return SizedBox.shrink();

    final formatted = rating[0].toUpperCase() + rating.substring(1).toLowerCase();

    Color color;
    IconData icon;
    switch (rating.toLowerCase()) {
      case 'suggestive':
        color = const Color(0xFFFBC8CF);
        icon = Icons.whatshot;
        break;
      case 'erotica':
        color = const Color(0xFFF8617B);
        icon = Icons.whatshot; 
        break;
      case 'pornographic':
        color = const Color(0xFFE8003E);
        icon = Icons.whatshot; 
        break;
      case 'safe':
        color = const Color(0xFF6CD292);
        icon = Icons.local_hospital;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return ChipBase(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            formatted,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }
}