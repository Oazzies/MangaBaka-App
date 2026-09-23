import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/settings/setting_value.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _Colour { red, green, blue }

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<SharedPreferences> prefs() => SharedPreferences.getInstance();

  group('type-mismatched stored values', () {
    test('fall back to the default instead of throwing', () async {
      SharedPreferences.setMockInitialValues({
        'b': 'yes',
        'i': 'three',
        's': 7,
        'l': true,
        'e': 'green',
      });
      final p = await prefs();

      final b = BoolSetting('b', true)..load(p);
      final i = IntSetting('i', 3)..load(p);
      final s = StringSetting('s', 'd')..load(p);
      final l = StringListSetting('l', const ['x'])..load(p);
      final e = EnumSetting('e', _Colour.blue, _Colour.values)..load(p);

      expect(b.value, isTrue);
      expect(i.value, 3);
      expect(s.value, 'd');
      expect(l.value, ['x']);
      expect(e.value, _Colour.blue);
    });
  });

  group('BoolSetting', () {
    test('starts at its default and loads a stored value', () async {
      SharedPreferences.setMockInitialValues({'k': true});
      final setting = BoolSetting('k', false);

      expect(setting.value, isFalse);
      setting.load(await prefs());
      expect(setting.value, isTrue);
    });

    test('falls back to the default when the key is absent', () async {
      final setting = BoolSetting('k', true)..load(await prefs());
      expect(setting.value, isTrue);
    });

    test('set reports whether anything changed', () {
      final setting = BoolSetting('k', false);
      expect(setting.set(true), isTrue);
      expect(setting.set(true), isFalse);
    });

    test('round-trips through persist', () async {
      final store = await prefs();
      final setting = BoolSetting('k', false)..set(true);
      await setting.persist(store);

      final reloaded = BoolSetting('k', false)..load(store);
      expect(reloaded.value, isTrue);
    });
  });

  group('IntSetting bounds', () {
    test('clamps on write', () {
      final setting = IntSetting('k', 1, min: 1, max: 99);
      setting.set(500);
      expect(setting.value, 99);
      setting.set(0);
      expect(setting.value, 1);
    });

    test('clamps a stale out-of-range stored value on load', () async {
      // A value written by an older build with different bounds.
      SharedPreferences.setMockInitialValues({'k': 500});
      final setting = IntSetting('k', 1, min: 1, max: 99)..load(await prefs());
      expect(setting.value, 99);
    });

    test('leaves an unbounded setting alone', () async {
      SharedPreferences.setMockInitialValues({'k': 500});
      final setting = IntSetting('k', 0)..load(await prefs());
      expect(setting.value, 500);
    });
  });

  group('EnumSetting', () {
    test('stores and restores by ordinal', () async {
      final store = await prefs();
      final setting = EnumSetting('k', _Colour.red, _Colour.values)
        ..set(_Colour.blue);
      await setting.persist(store);

      final reloaded = EnumSetting('k', _Colour.red, _Colour.values)
        ..load(store);
      expect(reloaded.value, _Colour.blue);
    });

    test('ignores an out-of-range ordinal rather than throwing', () async {
      // What a shortened or reordered enum leaves behind between releases.
      SharedPreferences.setMockInitialValues({'k': 99});
      final setting = EnumSetting('k', _Colour.green, _Colour.values)
        ..load(await prefs());
      expect(setting.value, _Colour.green);
    });

    test('ignores a negative ordinal', () async {
      SharedPreferences.setMockInitialValues({'k': -1});
      final setting = EnumSetting('k', _Colour.green, _Colour.values)
        ..load(await prefs());
      expect(setting.value, _Colour.green);
    });
  });

  group('StringListSetting', () {
    test('treats a stored empty list as unset', () async {
      SharedPreferences.setMockInitialValues({'k': <String>[]});
      final setting = StringListSetting('k', const ['a'])..load(await prefs());
      expect(setting.value, ['a']);
    });

    test('compares by contents, not identity', () {
      final setting = StringListSetting('k', const ['a']);
      expect(setting.set(['a']), isFalse);
      expect(setting.set(['a', 'b']), isTrue);
    });

    test('reset restores an independent copy of the default', () {
      final setting = StringListSetting('k', const ['a']);
      setting.set(['x', 'y']);
      setting.reset();
      expect(setting.value, ['a']);
    });
  });
}
