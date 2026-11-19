import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
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

  /// Space-separated; absent for sessions from before it was recorded.
  static const kGrantedScopes = 'mb_granted_scopes';

  /// Dev only (an unsigned macOS build has no keychain): plain SharedPreferences is readable by
  /// anything running as the user, so a release build refuses to store instead.
  final bool allowInsecureFallback;

  AuthStorage({bool? allowInsecureFallback})
    : allowInsecureFallback = allowInsecureFallback ?? kDebugMode;

  final _logger = LoggingService.logger;
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
      // Keeps the flutter_secure_storage v8 file name so Android upgrades keep their tokens.
      // ignore: deprecated_member_use
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
    } on PlatformException catch (e) {
      if (!allowInsecureFallback) {
        _logger.warning('Secure storage read error for key $key: $e');
        // A plaintext copy from an older build cannot be moved anywhere safe now, so drop it.
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
        return null;
      }
      _logger.warning(
        'Secure storage read error for key $key: $e. Checking fallback.',
      );
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }

    final prefs = await SharedPreferences.getInstance();
    final plain = prefs.getString(key);
    if (plain == null || allowInsecureFallback) return plain;
    return _migrateToSecure(prefs, key, plain);
  }

  Future<String?> _migrateToSecure(
    SharedPreferences prefs,
    String key,
    String value,
  ) async {
    String? migrated;
    try {
      await _storage.write(key: key, value: value);
      migrated = value;
      _logger.info('Moved $key from plain storage into secure storage');
    } on PlatformException catch (e) {
      _logger.warning('Could not move $key into secure storage: $e');
    }
    await prefs.remove(key);
    return migrated;
  }

  Future<void> write(String key, String? value) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException catch (e) {
      if (!allowInsecureFallback) {
        _logger.severe('Secure storage write error for key $key: $e');
        rethrow;
      }
      _logger.warning(
        'Secure storage write error for key $key: $e. Falling back to SharedPreferences.',
      );
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
    kGrantedScopes,
  ];

  /// Also clears the prefs fallback: [read] consults it and would resurrect a deleted token.
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } on PlatformException catch (e) {
      _logger.warning('Secure storage delete error for key $key: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  /// Only this class's keys leave the fallback store: SharedPreferences also holds every setting.
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
