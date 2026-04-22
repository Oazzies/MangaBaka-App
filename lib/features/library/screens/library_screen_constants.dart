import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class LibraryScreenConstants {
  static Color backgroundColor = AppConstants.primaryBackground;
  static Color accentColor = AppConstants.accentColor;
  static const Color errorColor = Colors.red;

  static const List<LibraryTabDefinition> tabs = [
    LibraryTabDefinition(key: 'reading', label: 'Reading'),
    LibraryTabDefinition(key: 'paused', label: 'Paused'),
    LibraryTabDefinition(key: 'completed', label: 'Completed'),
    LibraryTabDefinition(key: 'plan_to_read', label: 'Plan to Read'),
    LibraryTabDefinition(key: 'dropped', label: 'Dropped'),
    LibraryTabDefinition(key: 'rereading', label: 'Rereading'),
    LibraryTabDefinition(key: 'considering', label: 'Considering'),
  ];

  static const Set<String> knownStates = AppConstants.libraryStates;
}

class LibraryTabDefinition {
  final String key;
  final String label;

  const LibraryTabDefinition({required this.key, required this.label});
}
