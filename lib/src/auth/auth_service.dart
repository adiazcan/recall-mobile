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

    print('[AuthService] Initializing MSAL with:');
    print('[AuthService]   Client ID: $clientId');
    print('[AuthService]   Tenant ID: $tenantId');
    print('[AuthService]   Authority: https://login.microsoftonline.com/$tenantId');

    try {
      _app = await PublicClientApplication.createPublicClientApplication(
        clientId,
        authority: 'https://login.microsoftonline.com/$tenantId',
      );
      print('[AuthService] MSAL initialized successfully');
    } catch (e) {
      print('[AuthService] Failed to initialize MSAL: $e');
      rethrow;
    }
  }

  Future<String> signIn() async {
    try {
      await _ensureInitialized();

      print('[AuthService] Starting sign-in with scopes: $_scopes');
      print('[AuthService] Redirect URI: $redirectUri');
      print('[AuthService] Authority: https://login.microsoftonline.com/$tenantId');

      final result = await _app!.acquireToken(_scopes);

      print('[AuthService] Sign-in successful, token acquired');
      await tokenStore.saveToken(result);
      return result;
    } on MsalException catch (e) {
      print('[AuthService] MSAL Exception: ${e.errorMessage}');
      throw AuthException('Authentication failed: ${e.errorMessage}');
    } catch (e, stackTrace) {
      print('[AuthService] Unexpected error during sign-in: $e');
      print('[AuthService] Stack trace: $stackTrace');
      throw AuthException('Sign in failed: ${e.toString()}');
    }
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
    try {
      await _ensureInitialized();

      final result = await _app!.acquireTokenSilent(_scopes);
      await tokenStore.saveToken(result);
      return result;
    } on MsalException catch (e) {
      // Silent auth failed - user needs to sign in interactively
      return null;
    } catch (e) {
      // Other errors - log and return null
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
