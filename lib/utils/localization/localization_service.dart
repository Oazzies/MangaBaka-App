import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  static const String _languageKey = '${AppConstants.prefixStorageKey}language_pref';

  Map<String, dynamic> _languageData = {};
  String _currentLanguage = 'en';

  Future<void> init() async {
    try {
      final jsonString = await rootBundle.loadString('assets/lang/languages.json');
      _languageData = json.decode(jsonString);
      
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString(_languageKey);
      
      if (savedLang != null && _languageData.containsKey(savedLang)) {
        _currentLanguage = savedLang;
      } else {
        // Set to English by default if not set
        _currentLanguage = _languageData.containsKey('en') ? 'en' : _languageData.keys.first;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading localization data: $e');
    }
  }

  Future<void> setLanguage(String langCode) async {
    if (_languageData.containsKey(langCode)) {
      _currentLanguage = langCode;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, langCode);
    }
  }

  String get currentLanguage => _currentLanguage;

  Map<String, dynamic> get currentLanguageData => _languageData[_currentLanguage] ?? {};

  List<Map<String, dynamic>> getLanguages() {
    return _languageData.entries.map((e) {
      return {
        'code': e.key,
        'name': e.value['name'] ?? e.key,
        'translators': List<String>.from(e.value['translators'] ?? []),
      };
    }).toList();
  }

  String translate(String key) {
    if (_languageData.isEmpty || !_languageData.containsKey(_currentLanguage)) {
      return key; // Fallback to key
    }
    
    final strings = _languageData[_currentLanguage]['strings'] as Map<String, dynamic>?;
    return strings?[key] ?? key;
  }
}
