import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import 'auth_service.dart';
import 'token_store.dart';

enum AuthStatus { unauthenticated, loading, authenticated }

class AuthState {
  const AuthState({required this.status, this.error, this.pendingSharedUrl});

  final AuthStatus status;
  final String? error;
  final String? pendingSharedUrl;

  AuthState copyWith({
    AuthStatus? status,
    String? error,
    String? pendingSharedUrl,
    bool clearError = false,
    bool clearPendingUrl = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      pendingSharedUrl: clearPendingUrl
          ? null
          : (pendingSharedUrl ?? this.pendingSharedUrl),
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
      return const AuthState(status: AuthStatus.authenticated);
    }

    await _tokenStore.deleteToken();
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> signIn() async {
    state = AsyncData(
      state.value!.copyWith(status: AuthStatus.loading, clearError: true),
    );

    try {
      await _authService.signIn();
      state = AsyncData(
        state.value!.copyWith(status: AuthStatus.authenticated),
      );
    } on AuthException catch (e) {
      state = AsyncData(
        state.value!.copyWith(
          status: AuthStatus.unauthenticated,
          error: e.message,
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
      state = const AsyncData(AuthState(status: AuthStatus.unauthenticated));
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
}
