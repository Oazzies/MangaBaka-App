import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class LibraryScreenConstants {
  static Color get backgroundColor => AppConstants.primaryBackground;
  static Color get accentColor => AppConstants.accentColor;
  static Color get errorColor => AppConstants.errorColor;

  static const List<LibraryTabDefinition> tabs = [
    LibraryTabDefinition(key: 'reading', label: 'Reading'),
    LibraryTabDefinition(key: 'paused', label: 'Paused'),
    LibraryTabDefinition(key: 'completed', label: 'Completed'),
    LibraryTabDefinition(key: 'plan_to_read', label: 'Plan to Read'),
    LibraryTabDefinition(key: 'dropped', label: 'Dropped'),
    LibraryTabDefinition(key: 'rereading', label: 'Rereading'),
    LibraryTabDefinition(key: 'considering', label: 'Considering'),
  ];

  static Set<String> knownStates = AppConstants.libraryStates;
}

class LibraryTabDefinition {
  final String key;
  final String label;

  const LibraryTabDefinition({required this.key, required this.label});
}
