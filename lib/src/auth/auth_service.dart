import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
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

  void _log(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'AuthService');
    }
  }

  Future<void> _ensureInitialized() async {
    if (_app != null) return;

    _log('Initializing MSAL');

    try {
      _app = await PublicClientApplication.createPublicClientApplication(
        clientId,
        authority: 'https://login.microsoftonline.com/$tenantId',
      );
      _log('MSAL initialized successfully');
    } catch (e) {
      _log('Failed to initialize MSAL: $e');
      rethrow;
    }
  }

  Future<String> signIn() async {
    try {
      await _ensureInitialized();

      _log('Starting sign-in with ${_scopes.length} scopes');

      final result = await _app!.acquireToken(_scopes);

      _log('Sign-in successful, token acquired');
      await tokenStore.saveToken(result);
      return result;
    } on MsalException catch (e) {
      _log('MSAL Exception: ${e.errorMessage}');
      throw AuthException('Authentication failed: ${e.errorMessage}');
    } catch (e, stackTrace) {
      _log('Unexpected error during sign-in: $e');
      _log('Stack trace: $stackTrace');
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
    } on MsalException {
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
