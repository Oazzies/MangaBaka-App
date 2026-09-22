import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/library/constants/library_screen_constants.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_dropdown.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

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
        final stateColor = context.colors.forState(activeState);
        final onStateColor = context.colors.onForState(activeState);

        return LayoutBuilder(
          builder: (context, constraints) {
            return DesktopDropdown<String>(
              key: ValueKey(activeState),
              width: constraints.maxWidth,
              valueLabel: l10n.translate(activeState),
              backgroundColor: stateColor,
              menuBackgroundColor: context.colors.surface,
              foregroundColor: onStateColor,
              radius: AppConstants.pillRadius,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: Icon(
                _getIconForState(activeState),
                color: onStateColor,
                size: 20,
              ),
              selected: activeState,
              onSelected: (value) {
                if (value != activeState) {
                  setState(() {
                    _tempState = value;
                  });
                  widget.onStateChanged(value);
                }
              },
              items: LibraryScreenConstants.tabs.map((tab) {
                return DesktopDropdownItem<String>(
                  value: tab.key,
                  label: l10n.translate(tab.key).toUpperCase(),
                  icon: _getIconForState(tab.key),
                  iconColor: context.colors.forState(tab.key),
                );
              }).toList(),
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
}
