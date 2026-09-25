import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:mangabaka_app/features/profile/models/mb_profile.dart';
import 'package:mangabaka_app/features/profile/services/auth/auth_network_client.dart';
import 'package:mangabaka_app/features/profile/services/auth/auth_storage.dart';

/// Token storage kept in memory, so the service's session logic can be
/// exercised without the secure-storage plugin.
class MemoryAuthStorage extends AuthStorage {
  MemoryAuthStorage() : super(allowInsecureFallback: false);

  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> deleteAll() async => values.clear();
}

class FakeAuthNetwork extends AuthNetworkClient {
  @override
  Future<MbProfile> fetchProfile(String accessToken) async =>
      MbProfile(id: 'user-1', role: 'user', scopes: const []);
}

TokenResponse tokens(
  String access, {
  String? refresh,
  Duration expiresIn = const Duration(hours: 1),
}) =>
    TokenResponse(
      access,
      refresh,
      DateTime.now().add(expiresIn),
      null,
      'Bearer',
      null,
      null,
    );

/// Stores a signed-in session whose access token is valid for another hour.
void seedSession(
  MemoryAuthStorage storage, {
  String access = 'old',
  String? refresh = 'refresh-1',
  Duration expiresIn = const Duration(hours: 1),
}) {
  storage.values[AuthStorage.kAccessToken] = access;
  if (refresh != null) storage.values[AuthStorage.kRefreshToken] = refresh;
  storage.values[AuthStorage.kAccessTokenExp] =
      DateTime.now().toUtc().add(expiresIn).toIso8601String();
}
