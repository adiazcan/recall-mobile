import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import 'auth_service.dart';
import 'token_store.dart';

enum AuthStatus { unauthenticated, loading, authenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.error,
    this.pendingSharedUrl,
    this.userName,
    this.userEmail,
  });

  final AuthStatus status;
  final String? error;
  final String? pendingSharedUrl;
  final String? userName;
  final String? userEmail;

  AuthState copyWith({
    AuthStatus? status,
    String? error,
    String? pendingSharedUrl,
    String? userName,
    String? userEmail,
    bool clearError = false,
    bool clearPendingUrl = false,
    bool clearUserInfo = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      pendingSharedUrl: clearPendingUrl
          ? null
          : (pendingSharedUrl ?? this.pendingSharedUrl),
      userName: clearUserInfo ? null : (userName ?? this.userName),
      userEmail: clearUserInfo ? null : (userEmail ?? this.userEmail),
    );
  }
}

class AuthStateNotifier extends AsyncNotifier<AuthState> {
  late final AuthService _authService;
  late final TokenStore _tokenStore;

  @override
  Future<AuthState> build() async {
    // Read dependencies from ref
    _authService = ref.read(authServiceProvider);
    _tokenStore = ref.read(tokenStoreProvider);

    final token = await _tokenStore.getToken();

    if (token == null) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }

    final refreshedToken = await _authService.acquireTokenSilent();

    if (refreshedToken != null) {
      final profile = _extractUserProfile(refreshedToken);
      return AuthState(
        status: AuthStatus.authenticated,
        userName: profile?.name,
        userEmail: profile?.email,
      );
    }

    await _tokenStore.deleteToken();
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> signIn() async {
    state = AsyncData(
      state.value!.copyWith(status: AuthStatus.loading, clearError: true),
    );

    try {
      final accessToken = await _authService.signIn();
      final profile = _extractUserProfile(accessToken);
      state = AsyncData(
        state.value!.copyWith(
          status: AuthStatus.authenticated,
          userName: profile?.name,
          userEmail: profile?.email,
        ),
      );
    } on AuthException catch (e) {
      state = AsyncData(
        state.value!.copyWith(
          status: AuthStatus.unauthenticated,
          error: e.message,
        ),
      );
    } catch (e) {
      // Catch any other exceptions that weren't wrapped
      state = AsyncData(
        state.value!.copyWith(
          status: AuthStatus.unauthenticated,
          error: 'Authentication failed: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> signOut() async {
    state = AsyncData(
      state.value!.copyWith(status: AuthStatus.loading, clearError: true),
    );

    try {
      await _authService.signOut();
      state = const AsyncData(
        AuthState(
          status: AuthStatus.unauthenticated,
          userName: null,
          userEmail: null,
        ),
      );
    } catch (e) {
      state = AsyncData(
        state.value!.copyWith(
          status: AuthStatus.unauthenticated,
          error: 'Sign out failed: ${e.toString()}',
        ),
      );
    }
  }

  void setPendingSharedUrl(String? url) {
    if (state.value != null) {
      state = AsyncData(
        state.value!.copyWith(
          pendingSharedUrl: url,
          clearPendingUrl: url == null,
        ),
      );
    }
  }

  String? clearPendingSharedUrl() {
    final url = state.value?.pendingSharedUrl;
    if (url != null) {
      state = AsyncData(state.value!.copyWith(clearPendingUrl: true));
    }
    return url;
  }

  _UserProfile? _extractUserProfile(String accessToken) {
    final parts = accessToken.split('.');
    if (parts.length < 2) {
      return null;
    }

    try {
      final normalizedPayload = base64Url.normalize(parts[1]);
      final payloadBytes = base64Url.decode(normalizedPayload);
      final payloadString = utf8.decode(payloadBytes);
      final payloadJson = jsonDecode(payloadString);

      if (payloadJson is! Map<String, dynamic>) {
        return null;
      }

      String? readClaim(List<String> keys) {
        for (final key in keys) {
          final value = payloadJson[key];
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
        return null;
      }

      final email = readClaim(const [
        'preferred_username',
        'email',
        'upn',
        'unique_name',
      ]);

      final name = readClaim(const ['name', 'given_name']) ?? email;

      if (name == null && email == null) {
        return null;
      }

      return _UserProfile(name: name, email: email);
    } catch (_) {
      return null;
    }
  }
}

class _UserProfile {
  const _UserProfile({this.name, this.email});

  final String? name;
  final String? email;
}
