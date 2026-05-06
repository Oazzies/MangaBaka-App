import 'package:flutter/material.dart';
import 'package:bakahyou/features/library/screens/library_screen_constants.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';

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

    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) {
        final l10n = LocalizationService();
        return Container(
          height: 44, // Slightly taller for better touch target
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: AppConstants.secondaryBackground,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: DropdownButton<String>(
            value: currentState,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: AppConstants.secondaryBackground,
            icon: Icon(Icons.arrow_drop_down, color: AppConstants.textColor),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            itemHeight: 48,
            menuMaxHeight: MediaQuery.of(context).size.height * 0.7,
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
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.translate(tab.key)),
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
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n.translate(tab.key),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        );
      },
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
        return AppConstants.successColor;
      case 'completed':
        return AppConstants.textColor;
      case 'paused':
        return AppConstants.warningColor;
      case 'dropped':
        return AppConstants.errorColor;
      case 'plan_to_read':
        return AppConstants.infoColor;
      case 'considering':
        return AppConstants.accentColor;
      default:
        return AppConstants.textMutedColor;
    }
  }
}
