import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';

class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  @visibleForTesting
  static void resetForTesting() {
    _instance._manifest = {};
    _instance._currentStrings = {};
    _instance._englishStrings = {};
    _instance._currentLanguage = 'en';
  }

  static const String _languageKey =
      '${AppConstants.prefixStorageKey}language_pref';

  Map<String, dynamic> _manifest = {};
  Map<String, dynamic> _currentStrings = {};
  Map<String, dynamic> _englishStrings = {};
  String _currentLanguage = 'en';

  Future<void> init() async {
    try {
      final manifestString = await rootBundle.loadString(
        'assets/lang/languages.json',
      );
      _manifest = json.decode(manifestString);

      try {
        final enString = await rootBundle.loadString('assets/lang/en.json');
        final enData = json.decode(enString);
        _englishStrings = enData['strings'] ?? {};
      } catch (e, st) {
        LoggingService.logger.warning(
          'Error loading English fallback strings',
          e,
          st,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString(_languageKey);

      if (savedLang != null && _manifest.containsKey(savedLang)) {
        _currentLanguage = savedLang;
      } else {
        _currentLanguage = _manifest.containsKey('en')
            ? 'en'
            : _manifest.keys.first;
      }

      await _loadLanguageStrings(_currentLanguage);

      notifyListeners();
    } catch (e, st) {
      LoggingService.logger.warning(
        'Error loading localization data',
        e,
        st,
      );
    }
  }

  Future<void> _loadLanguageStrings(String langCode) async {
    try {
      final langString = await rootBundle.loadString(
        'assets/lang/$langCode.json',
      );
      final langData = json.decode(langString);
      _currentStrings = langData['strings'] ?? {};
    } catch (e, st) {
      LoggingService.logger.warning(
        'Error loading strings for $langCode',
        e,
        st,
      );
      _currentStrings = {};
    }
  }

  Future<void> setLanguage(String langCode) async {
    if (_manifest.containsKey(langCode)) {
      _currentLanguage = langCode;
      await _loadLanguageStrings(langCode);
      // Another language was picked meanwhile; applying these would mismatch text and selected code.
      if (_currentLanguage != langCode) return;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, langCode);
    }
  }

  String get currentLanguage => _currentLanguage;

  Map<String, dynamic> get currentLanguageData =>
      _manifest[_currentLanguage] ?? {};

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
    final current = _currentStrings[key];
    if (current is String) return current;
    final fallback = _englishStrings[key];
    return fallback is String ? fallback : key;
  }

  /// For keys built from API values, which may have no translation yet.
  String translateOr(String key, String fallback) {
    final value = translate(key);
    return value == key ? fallback : value;
  }

  String formatPossessive(String name) {
    if (name.isEmpty) return name;

    // Spanish and French use "de [name]" in the translation string.
    if (_currentLanguage == 'es' || _currentLanguage == 'fr') {
      return name;
    }

    // ja puts "の" in the translation string.
    if (_currentLanguage == 'ja') {
      return name;
    }

    if (name.toLowerCase().endsWith('s')) {
      return "$name'";
    }
    return "$name's";
  }
}
