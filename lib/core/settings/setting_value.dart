import 'package:shared_preferences/shared_preferences.dart';

abstract class SettingValue<T> {
  final String key;
  final T defaultValue;

  T _value;

  SettingValue(this.key, this.defaultValue) : _value = defaultValue;

  T get value => _value;

  /// Returns whether the value changed, so callers can skip a redundant write and notification.
  bool set(T next) {
    if (_value == next) return false;
    _value = next;
    return true;
  }

  void reset() => _value = defaultValue;

  /// Read via prefs.get and type-check: typed getters throw on a mismatched type and abort startup.
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
  /// Applied on load too, so an out-of-range value from an older build is corrected.
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

/// Empty counts as unset: an empty content-rating allow-list would otherwise hide everything.
class StringListSetting extends SettingValue<List<String>> {
  StringListSetting(super.key, super.defaultValue);

  @override
  bool set(List<String> next) {
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
    // Copied: a later mutation of the caller's list would change the setting with no write or notify.
    _value = List<String>.of(next);
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

/// Stored by ordinal; an out-of-range index from a shortened enum is ignored rather than thrown on.
class EnumSetting<T extends Enum> extends SettingValue<T> {
  final List<T> values;

  EnumSetting(super.key, super.defaultValue, this.values);

  @override
  void load(SharedPreferences prefs) {
    final stored = prefs.get(key);
    int? index;
    if (stored is int) {
      index = stored;
    } else if (stored is String) {
      index = int.tryParse(stored);
      if (index == null) {
        final match = values.indexWhere((v) => v.name == stored);
        if (match != -1) index = match;
      }
    }
    if (index == null || index < 0 || index >= values.length) return;
    _value = values[index];
  }

  @override
  Future<void> persist(SharedPreferences prefs) =>
      prefs.setInt(key, _value.index);
}
