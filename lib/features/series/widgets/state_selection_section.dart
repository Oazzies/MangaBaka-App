import 'package:bakahyou/features/library/screens/library_screen_constants.dart';
import 'package:flutter/material.dart';

class StateSelectionSection extends StatelessWidget {
  final String? currentState;
  final Function(String) onStateChanged;

  const StateSelectionSection({
    super.key,
    required this.currentState,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (currentState == null) {
      return const SizedBox.shrink();
    }

    final dropdownWidth = MediaQuery.of(context).size.width / 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: dropdownWidth,
          child: Container(
            height: 38, // Slightly taller
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0a0a0a),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: const Color(0xFF3f3f46), width: 1.5),
            ),
            child: DropdownButton<String>(
              value: currentState,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              dropdownColor: const Color(0xFF0a0a0a),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              itemHeight: 48,
              menuMaxHeight:
                  MediaQuery.of(context).size.height * 0.7, 
              onChanged: (value) {
                if (value != null && value != currentState) {
                  onStateChanged(value);
                }
              },
              items: LibraryScreenConstants.tabs.map((tab) {
                return DropdownMenuItem(
                  value: tab.key,
                  child: Row(
                    children: [
                      Icon(
                        _getIconForState(tab.key),
                        color: _getColorForState(tab.key),
                      ),
                      const SizedBox(width: 8),
                      Text(tab.label),
                    ],
                  ),
                );
              }).toList(),
              selectedItemBuilder: (BuildContext context) {
                return LibraryScreenConstants.tabs.map<Widget>((tab) {
                  return Row(
                    children: [
                      Icon(
                        _getIconForState(tab.key),
                        color: _getColorForState(tab.key),
                      ),
                      const SizedBox(width: 8),
                      Text(tab.label),
                    ],
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForState(String state) {
    switch (state) {
      case 'reading':
        return Icons.play_arrow_outlined;
      case 'rereading':
        return Icons.refresh;
      case 'completed':
        return Icons.check_circle_outline_outlined;
      case 'paused':
        return Icons.pause_circle_outline;
      case 'dropped':
        return Icons.delete_outline;
      case 'plan_to_read':
        return Icons.bookmark_border;
      case 'considering':
        return Icons.lightbulb_outline;
      default:
        return Icons.help_outline;
    }
  }

  Color _getColorForState(String state) {
    switch (state) {
      case 'reading':
      case 'rereading':
        return const Color(0xFF81e6ca);
      case 'completed':
        return Colors.white;
      case 'paused':
        return const Color(0xFFffc83e);
      case 'dropped':
        return Colors.red;
      case 'plan_to_read':
        return Colors.blue;
      case 'considering':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
