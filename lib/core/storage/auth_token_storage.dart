import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthTokenStorage {
  static const _kAccessToken = 'auth_access_token';
  static const _kRefreshToken = 'auth_refresh_token';

  final FlutterSecureStorage _secure;

  String? _accessInMemory;
  String? _refreshInMemory;

  AuthTokenStorage(this._secure);

  /// persist=true  => saved to Keychain/Keystore
  /// persist=false => memory-only (cleared when app is killed)
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required bool persist,
  }) async {
    _accessInMemory = accessToken;
    _refreshInMemory = refreshToken;

    if (persist) {
      await _secure.write(key: _kAccessToken, value: accessToken);
      await _secure.write(key: _kRefreshToken, value: refreshToken);
    } else {
      // Ensure old "remembered" tokens are removed
      await _secure.delete(key: _kAccessToken);
      await _secure.delete(key: _kRefreshToken);
    }
  }

  Future<String?> readAccessToken() async {
    return _accessInMemory ?? await _secure.read(key: _kAccessToken);
  }

  Future<String?> readRefreshToken() async {
    return _refreshInMemory ?? await _secure.read(key: _kRefreshToken);
  }

  Future<void> clear() async {
    _accessInMemory = null;
    _refreshInMemory = null;
    await _secure.delete(key: _kAccessToken);
    await _secure.delete(key: _kRefreshToken);
  }
}
