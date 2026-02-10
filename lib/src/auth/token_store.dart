import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Tokens {
  const Tokens({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;
}

abstract class TokenStore {
  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  });

  Future<Tokens?> readTokens();

  Future<void> clear();

  Future<String?> getToken() {
    return readTokens().then((tokens) => tokens?.accessToken);
  }

  Future<void> saveToken(String accessToken) {
    return setTokens(accessToken: accessToken, refreshToken: '');
  }

  Future<void> deleteToken() {
    return clear();
  }
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _expiresAtKey = 'expires_at';

  final FlutterSecureStorage _storage;

  @override
  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(
      key: _expiresAtKey,
      value: expiresAt?.toIso8601String(),
    );
  }

  @override
  Future<Tokens?> readTokens() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final expiresAtRaw = await _storage.read(key: _expiresAtKey);

    if (accessToken == null || refreshToken == null) {
      return null;
    }

    return Tokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAtRaw == null ? null : DateTime.tryParse(expiresAtRaw),
    );
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiresAtKey);
  }

  @override
  Future<String?> getToken() async {
    final tokens = await readTokens();
    return tokens?.accessToken;
  }

  @override
  Future<void> saveToken(String accessToken) async {
    await setTokens(accessToken: accessToken, refreshToken: '');
  }

  @override
  Future<void> deleteToken() async {
    await clear();
  }
}

class InMemoryTokenStore implements TokenStore {
  Tokens? _tokens;

  @override
  Future<void> clear() async {
    _tokens = null;
  }

  @override
  Future<Tokens?> readTokens() async => _tokens;

  @override
  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {
    _tokens = Tokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<String?> getToken() async {
    return _tokens?.accessToken;
  }

  @override
  Future<void> saveToken(String accessToken) async {
    await setTokens(accessToken: accessToken, refreshToken: '');
  }

  @override
  Future<void> deleteToken() async {
    await clear();
  }
}
