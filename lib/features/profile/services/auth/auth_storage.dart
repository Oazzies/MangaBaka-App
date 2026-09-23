import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/profile/models/mb_profile.dart';

class AuthStorage {
  static const kAccessToken = 'mb_access_token';
  static const kRefreshToken = 'mb_refresh_token';
  static const kIdToken = 'mb_id_token';
  static const kAccessTokenExp = 'mb_access_token_exp';
  static const kProfileCache = 'mb_profile_cache';

  final _logger = LoggingService.logger;
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: false,
      resetOnError: true,
      sharedPreferencesName: 'mangabaka_app_secure_storage_v3',
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: false,
    ),
  );

  Future<String?> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value != null) return value;

      // Check fallback
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } on PlatformException catch (e) {
      _logger.warning(
        'Secure storage read error for key $key: $e. Checking fallback.',
      );
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
  }

  Future<void> write(String key, String? value) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException catch (e) {
      _logger.warning(
        'Secure storage write error for key $key: $e. Falling back to SharedPreferences.',
      );
      // Fallback for macOS development without signing
      final prefs = await SharedPreferences.getInstance();
      if (value == null) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, value);
      }
    }
  }

  static const _allKeys = [
    kAccessToken,
    kRefreshToken,
    kIdToken,
    kAccessTokenExp,
    kProfileCache,
  ];

  /// Deletes [key] from secure storage *and* from the SharedPreferences
  /// fallback — [read] consults the fallback whenever secure storage has no
  /// value, so a copy left there would resurrect a deleted token.
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } on PlatformException catch (e) {
      _logger.warning('Secure storage delete error for key $key: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  /// Removes every auth value. Only this class's keys are touched in the
  /// fallback store: SharedPreferences also holds every app setting.
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } on PlatformException catch (e) {
      _logger.warning('Secure storage deleteAll error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    for (final key in _allKeys) {
      await prefs.remove(key);
    }
  }

  Future<MbProfile?> getCachedProfile() async {
    try {
      final cachedString = await read(kProfileCache);
      if (cachedString != null) {
        return MbProfile.fromJson(jsonDecode(cachedString));
      }
    } catch (e) {
      _logger.warning('Failed to load cached profile: $e');
    }
    return null;
  }

  Future<void> cacheProfile(MbProfile profile) async {
    await write(kProfileCache, jsonEncode(profile.toJson()));
  }
}
