import 'package:shared_preferences/shared_preferences.dart';

/// One persisted preference: its key, its default, and how to read and write
/// it.
///
/// [SettingsManager] used to spell all three out per setting — an entry in
/// `init()`, a six-line setter, and a line in the test reset — three places
/// that had to agree, and thirty settings' worth of them. Declaring the
/// setting once lets loading, saving and resetting all be derived.
abstract class SettingValue<T> {
  final String key;
  final T defaultValue;

  T _value;

  SettingValue(this.key, this.defaultValue) : _value = defaultValue;

  T get value => _value;

  /// Assigns [next], returning whether anything actually changed — the caller
  /// uses that to skip a redundant disk write and notification.
  bool set(T next) {
    if (_value == next) return false;
    _value = next;
    return true;
  }

  void reset() => _value = defaultValue;

  /// Reads the stored value, leaving the current one in place when the key is
  /// absent or holds something unusable.
  ///
  /// Implementations read through `prefs.get` and type-check the result: the
  /// typed getters (`getInt`, `getBool`, …) throw a TypeError when the key
  /// holds another type, which during `SettingsManager.init` aborts startup
  /// before the first frame.
  void load(SharedPreferences prefs);

  Future<void> persist(SharedPreferences prefs);
}

class BoolSetting extends SettingValue<bool> {
  BoolSetting(super.key, super.defaultValue);

  @override
  void load(SharedPreferences prefs) {
    final stored = prefs.get(key);
    _value = stored is bool ? stored : defaultValue;
  }

  @override
  Future<void> persist(SharedPreferences prefs) => prefs.setBool(key, _value);
}

class IntSetting extends SettingValue<int> {
  /// Applied on both load and save, so a value from an older build outside the
  /// current range is corrected rather than carried forward.
  final int? min;
  final int? max;

  IntSetting(super.key, super.defaultValue, {this.min, this.max});

  @override
  bool set(int next) => super.set(_clamp(next));

  @override
  void load(SharedPreferences prefs) {
    final stored = prefs.get(key);
    _value = stored is int ? _clamp(stored) : defaultValue;
  }

  @override
  Future<void> persist(SharedPreferences prefs) => prefs.setInt(key, _value);

  int _clamp(int v) {
    if (min != null && v < min!) return min!;
    if (max != null && v > max!) return max!;
    return v;
  }
}

class StringSetting extends SettingValue<String> {
  StringSetting(super.key, super.defaultValue);

  @override
  void load(SharedPreferences prefs) {
    final stored = prefs.get(key);
    _value = stored is String ? stored : defaultValue;
  }

  @override
  Future<void> persist(SharedPreferences prefs) => prefs.setString(key, _value);
}

/// A list of strings, treated as absent when stored empty.
///
/// An empty stored list is indistinguishable from "never set" for these
/// settings, and falling back to the default is the useful reading — an empty
/// content-rating allow-list would otherwise hide everything.
class StringListSetting extends SettingValue<List<String>> {
  StringListSetting(super.key, super.defaultValue);

  @override
  bool set(List<String> next) {
    // Lists compare by identity, so compare contents to avoid a pointless
    // write when the same values are re-applied.
    if (_value.length == next.length) {
      var same = true;
      for (var i = 0; i < next.length; i++) {
        if (_value[i] != next[i]) {
          same = false;
          break;
        }
      }
      if (same) return false;
    }
    _value = next;
    return true;
  }

  @override
  void load(SharedPreferences prefs) {
    final stored = prefs.get(key);
    final list = stored is List ? stored.whereType<String>().toList() : null;
    _value = (list == null || list.isEmpty) ? defaultValue : list;
  }

  @override
  Future<void> persist(SharedPreferences prefs) =>
      prefs.setStringList(key, _value);

  @override
  void reset() => _value = List<String>.from(defaultValue);
}

/// An enum stored by ordinal.
///
/// Out-of-range indices are ignored rather than trusted: reordering or
/// shortening an enum between releases would otherwise throw on startup, or
/// silently select the wrong member.
class EnumSetting<T extends Enum> extends SettingValue<T> {
  final List<T> values;

  EnumSetting(super.key, super.defaultValue, this.values);

  @override
  void load(SharedPreferences prefs) {
    final index = prefs.get(key);
    if (index is! int || index < 0 || index >= values.length) return;
    _value = values[index];
  }

  @override
  Future<void> persist(SharedPreferences prefs) =>
      prefs.setInt(key, _value.index);
}
