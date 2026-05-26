import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    LocalizationService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    
    // Mock assets
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        final String key = utf8.decode(message!.buffer.asUint8List());
        if (key == 'assets/lang/languages.json') {
          return ByteData.view(utf8.encode(json.encode({
            'en': {
              'name': 'English',
              'native_name': 'English',
              'translators': ['Admin']
            },
            'ja': {
              'name': 'Japanese',
              'native_name': '日本語',
              'translators': ['Baka']
            }
          })).buffer);
        } else if (key == 'assets/lang/en.json') {
          return ByteData.view(utf8.encode(json.encode({
            'strings': {
              'app_title': 'MangaBaka',
              'open_link': 'Open {name}',
              'only_in_english': 'Only in English'
            }
          })).buffer);
        } else if (key == 'assets/lang/ja.json') {
          return ByteData.view(utf8.encode(json.encode({
            'strings': {
              'app_title': 'まんがバカ',
              'open_link': '{name}を開く'
            }
          })).buffer);
        }
        return null;
      },
    );
  });

  group('LocalizationService', () {
    test('initializes with default language (en)', () async {
      final service = LocalizationService();
      await service.init();

      expect(service.currentLanguage, 'en');
      expect(service.translate('app_title'), 'MangaBaka');
      expect(service.translate('non_existent'), 'non_existent');
    });

    test('loads saved language from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'mangabaka_app_language_pref': 'ja',
      });

      final service = LocalizationService();
      await service.init();

      expect(service.currentLanguage, 'ja');
      expect(service.translate('app_title'), 'まんがバカ');
    });

    test('setLanguage updates language and persists', () async {
      final service = LocalizationService();
      await service.init();

      await service.setLanguage('ja');
      expect(service.currentLanguage, 'ja');
      expect(service.translate('app_title'), 'まんがバカ');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('mangabaka_app_language_pref'), 'ja');
    });

    test('defaults to English when translation is missing in target language', () async {
      SharedPreferences.setMockInitialValues({
        'mangabaka_app_language_pref': 'ja',
      });

      final service = LocalizationService();
      await service.init();

      // 'only_in_english' is not in Japanese, so it should fall back to English
      expect(service.translate('only_in_english'), 'Only in English');
    });

    test('getLanguages returns correct list', () async {
      final service = LocalizationService();
      await service.init();

      final languages = service.getLanguages();
      expect(languages.length, 2);
      expect(languages[0]['code'], 'en');
      expect(languages[1]['code'], 'ja');
      expect(languages[1]['name'], 'Japanese');
    });
  });
}
