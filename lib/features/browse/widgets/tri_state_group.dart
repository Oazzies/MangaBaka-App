import 'package:flutter/material.dart';
import 'package:bakahyou/features/browse/widgets/tri_state_chip.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class TriStateGroup extends StatelessWidget {
  final String title;
  final List<Map<String, String>> options;
  final List<String> includes;
  final List<String> excludes;
  final Function(List<String>, List<String>) onUpdate;

  const TriStateGroup({
    super.key,
    required this.title,
    required this.options,
    required this.includes,
    required this.excludes,
    required this.onUpdate,
  });

  TriState _getTriState(String value) {
    if (includes.contains(value)) return TriState.include;
    if (excludes.contains(value)) return TriState.exclude;
    return TriState.off;
  }

  void _handleUpdate(String value, TriState newState) {
    final newIncludes = List<String>.from(includes)..remove(value);
    final newExcludes = List<String>.from(excludes)..remove(value);

    if (newState == TriState.include) newIncludes.add(value);
    if (newState == TriState.exclude) newExcludes.add(value);

    onUpdate(newIncludes, newExcludes);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            title,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final value = option['value']!;
            final label = option['label']!;
            return TriStateChip(
              label: label,
              state: _getTriState(value),
              onChanged: (newState) => _handleUpdate(value, newState),
            );
          }).toList(),
        ),
      ],
    );
  }
}
