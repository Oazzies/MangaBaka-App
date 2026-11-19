import 'package:mangabaka_app/core/constants/app_constants.dart';

class LibraryScreenConstants {
  static const List<LibraryTabDefinition> tabs = [
    LibraryTabDefinition(key: 'reading'),
    LibraryTabDefinition(key: 'paused'),
    LibraryTabDefinition(key: 'completed'),
    LibraryTabDefinition(key: 'plan_to_read'),
    LibraryTabDefinition(key: 'dropped'),
    LibraryTabDefinition(key: 'rereading'),
    LibraryTabDefinition(key: 'considering'),
  ];

  static Set<String> knownStates = AppConstants.libraryStates;
}

class LibraryTabDefinition {
  final String key;

  const LibraryTabDefinition({required this.key});
}
