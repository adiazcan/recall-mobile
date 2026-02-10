import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_service.dart';
import '../auth/auth_state.dart';
import '../auth/token_store.dart';
import '../cache/cache_service.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../network/dio_provider.dart';
import '../openapi/openapi_repository.dart';
import 'router.dart';

final appConfigProvider = Provider<AppConfig>(
  (_) => throw const AppConfigException('AppConfig override is required.'),
);

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (_) => SharedPreferences.getInstance(),
);

final tokenStoreProvider = Provider<TokenStore>((_) => SecureTokenStore());

final authServiceProvider = Provider<AuthService>((ref) {
  final config = ref.watch(appConfigProvider);
  return AuthService(
    clientId: config.entraClientId,
    tenantId: config.entraTenantId,
    scopes: config.entraScopes.split(' '),
    redirectUri: config.entraRedirectUri,
    tokenStore: ref.watch(tokenStoreProvider),
  );
});

final authStateProvider = AsyncNotifierProvider<AuthStateNotifier, AuthState>(
  AuthStateNotifier.new,
);

final dioProvider = Provider<Dio>((ref) {
  return buildDioClient(
    config: ref.watch(appConfigProvider),
    tokenStore: ref.watch(tokenStoreProvider),
    authService: ref.watch(authServiceProvider),
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(dio: ref.watch(dioProvider));
});

final cacheServiceProvider = FutureProvider<CacheService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return CacheService(prefs: prefs);
});

final openApiRepositoryProvider = Provider<OpenApiRepository>((ref) {
  return OpenApiRepository(
    client: ref.watch(dioProvider),
    config: ref.watch(appConfigProvider),
  );
});

/// Provider for the app router
final routerProvider = Provider<GoRouter>((ref) {
  return createRouter(ref);
});

/// Provider for handling shared URLs from external apps
final sharedUrlProvider = StateNotifierProvider<SharedUrlNotifier, String?>((
  ref,
) {
  return SharedUrlNotifier();
});

/// Notifier for managing shared URL state
class SharedUrlNotifier extends StateNotifier<String?> {
  SharedUrlNotifier() : super(null);

  void setSharedUrl(String url) {
    state = url;
  }

  void clearSharedUrl() {
    state = null;
  }
}
