import 'package:msal_flutter/msal_flutter.dart';

import 'token_store.dart';

class AuthService {
  AuthService({
    required this.clientId,
    required this.tenantId,
    required List<String> scopes,
    required this.redirectUri,
    required this.tokenStore,
  }) : _scopes = scopes;

  final String clientId;
  final String tenantId;
  final List<String> _scopes;
  final String redirectUri;
  final TokenStore tokenStore;

  PublicClientApplication? _app;

  Future<void> _ensureInitialized() async {
    if (_app != null) return;

    _app = await PublicClientApplication.createPublicClientApplication(
      clientId,
      authority: 'https://login.microsoftonline.com/$tenantId',
    );
  }

  Future<String> signIn() async {
    await _ensureInitialized();

    final result = await _app!.acquireToken(_scopes);

    await tokenStore.saveToken(result);
    return result;
  }

  Future<void> signOut() async {
    await _ensureInitialized();

    try {
      await _app!.logout();
    } catch (_) {
      // Ignore errors during sign out
    }

    await tokenStore.deleteToken();
  }

  Future<String?> acquireTokenSilent() async {
    await _ensureInitialized();

    try {
      final result = await _app!.acquireTokenSilent(_scopes);
      await tokenStore.saveToken(result);
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<String> refreshToken() async {
    final token = await acquireTokenSilent();
    if (token != null) {
      return token;
    }

    return signIn();
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}
