import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/library/constants/library_screen_constants.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';

class StateSelectionSection extends StatefulWidget {
  final String? currentState;
  final Function(String) onStateChanged;

  const StateSelectionSection({
    super.key,
    required this.currentState,
    required this.onStateChanged,
  });

  @override
  State<StateSelectionSection> createState() => _StateSelectionSectionState();
}

class _StateSelectionSectionState extends State<StateSelectionSection> {
  String? _tempState;

  @override
  void initState() {
    super.initState();
    _tempState = widget.currentState;
  }

  @override
  void didUpdateWidget(covariant StateSelectionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentState != oldWidget.currentState) {
      _tempState = widget.currentState;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeState = _tempState;
    if (activeState == null) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) {
        final l10n = LocalizationService();
        return LayoutBuilder(
          builder: (context, constraints) {
            final stateColor = _getColorForState(activeState);
            return DropdownMenu<String>(
              key: ValueKey(activeState),
              width: constraints.maxWidth,
              initialSelection: activeState,
              requestFocusOnTap: false,
              enableSearch: false,
              enableFilter: false,
              onSelected: (value) {
                if (value != null && value != activeState) {
                  setState(() {
                    _tempState = value;
                  });
                  widget.onStateChanged(value);
                }
              },
              leadingIcon: Icon(
                _getIconForState(activeState),
                color: AppConstants.primaryBackground,
                size: 20,
              ),
              dropdownMenuEntries: LibraryScreenConstants.tabs.map((tab) {
                final isSelected = activeState == tab.key;
                return DropdownMenuEntry<String>(
                  value: tab.key,
                  label: l10n.translate(tab.key),
                  leadingIcon: Icon(
                    _getIconForState(tab.key),
                    color: _getColorForState(tab.key),
                    size: 20,
                  ),
                  trailingIcon: isSelected 
                      ? Icon(Icons.check, color: AppConstants.accentColor, size: 18)
                      : null,
                  style: MenuItemButton.styleFrom(
                    foregroundColor: AppConstants.textColor,
                    backgroundColor: isSelected ? AppConstants.accentColor.withValues(alpha: 0.1) : null,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                );
              }).toList(),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: stateColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 11.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
              ),
              trailingIcon: Icon(Icons.keyboard_arrow_down_rounded, color: AppConstants.primaryBackground, size: 20),
              selectedTrailingIcon: Icon(Icons.keyboard_arrow_up_rounded, color: AppConstants.primaryBackground, size: 20),
              textStyle: TextStyle(
                color: AppConstants.primaryBackground,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              menuStyle: MenuStyle(
                backgroundColor: WidgetStateProperty.all(AppConstants.secondaryBackground),
                surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                padding: WidgetStateProperty.all(EdgeInsets.zero), // Removes the top/bottom gap!
              ),
            );
          },
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
