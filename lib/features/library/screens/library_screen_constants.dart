import 'package:flutter/material.dart';

class LibraryScreenConstants {
  static const Color backgroundColor = Color(0xFF0a0a0a);
  static const Color accentColor = Color(0xFF1b9f70);
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

  static const Set<String> knownStates = {
    'reading',
    'paused',
    'completed',
    'plan_to_read',
    'dropped',
    'rereading',
    'considering',
  };
}

class LibraryTabDefinition {
  final String key;
  final String label;

  const LibraryTabDefinition({required this.key, required this.label});
}