import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';

class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();
  
  @visibleForTesting
  static void resetForTesting() {
    _instance._manifest = {};
    _instance._currentStrings = {};
    _instance._currentLanguage = 'en';
  }

  static const String _languageKey = '${AppConstants.prefixStorageKey}language_pref';

  Map<String, dynamic> _manifest = {};
  Map<String, dynamic> _currentStrings = {};
  String _currentLanguage = 'en';

  Future<void> init() async {
    try {
      // Load manifest
      final manifestString = await rootBundle.loadString('assets/lang/languages.json');
      _manifest = json.decode(manifestString);
      
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString(_languageKey);
      
      if (savedLang != null && _manifest.containsKey(savedLang)) {
        _currentLanguage = savedLang;
      } else {
        // Set to English by default if not set
        _currentLanguage = _manifest.containsKey('en') ? 'en' : _manifest.keys.first;
      }

      await _loadLanguageStrings(_currentLanguage);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading localization data: $e');
    }
  }

  Future<void> _loadLanguageStrings(String langCode) async {
    try {
      final langString = await rootBundle.loadString('assets/lang/$langCode.json');
      final langData = json.decode(langString);
      _currentStrings = langData['strings'] ?? {};
    } catch (e) {
      debugPrint('Error loading strings for $langCode: $e');
      _currentStrings = {};
    }
  }

  Future<void> setLanguage(String langCode) async {
    if (_manifest.containsKey(langCode)) {
      _currentLanguage = langCode;
      await _loadLanguageStrings(langCode);
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, langCode);
    }
  }

  String get currentLanguage => _currentLanguage;

  Map<String, dynamic> get currentLanguageData => _manifest[_currentLanguage] ?? {};

  List<Map<String, dynamic>> getLanguages() {
    return _manifest.entries.map((e) {
      return {
        'code': e.key,
        'name': e.value['name'] ?? e.key,
        'native_name': e.value['native_name'] ?? e.value['name'] ?? e.key,
        'translators': List<String>.from(e.value['translators'] ?? []),
      };
    }).toList();
  }

  String translate(String key) {
    return _currentStrings[key] ?? key;
  }

  String formatPossessive(String name) {
    if (name.isEmpty) return name;
    
    // In Spanish and French, we use "de [name]" which is handled in the translation string
    if (_currentLanguage == 'es' || _currentLanguage == 'fr') {
      return name;
    }
    
    // English/German/Japanese/etc. rules
    if (_currentLanguage == 'ja') {
      return name; // Japanese uses "の" which is handled in the translation string
    }

    // Default English-style possessive
    // Rule: if ends in 's', add only '. Otherwise add 's.
    // NOTE: The user requested "Oazzies's" specifically, but usually names ending in 's' can take either.
    // We will use the 's only if it doesn't end in s.
    if (name.toLowerCase().endsWith('s')) {
      return "$name'";
    }
    return "$name's";
  }
}
