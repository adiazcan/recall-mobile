import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_service.dart';
import '../auth/auth_state.dart';
import '../auth/token_store.dart';
import '../cache/cache_service.dart';
import '../config/app_config.dart';
import '../models/tag.dart';
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

final authTokenProvider = FutureProvider<String?>((ref) async {
  return ref.watch(tokenStoreProvider).getToken();
});

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

class TagsNotifier extends AsyncNotifier<List<Tag>> {
  @override
  Future<List<Tag>> build() async {
    final cacheService = await ref.read(cacheServiceProvider.future);
    final cachedTagsJson = cacheService.getCachedTags();

    if (cachedTagsJson != null && cachedTagsJson.isNotEmpty) {
      final cachedTags = CacheService.decodeList(cachedTagsJson, Tag.fromJson);
      // Trigger background refresh with error handling
      Future<void>(() async {
        try {
          await refresh();
        } catch (e) {
          // Background refresh failed, but we still have cached data
          // Error is already captured in the AsyncValue state
        }
      });
      return cachedTags;
    }

    return _fetchTags();
  }

  Future<void> refresh() async {
    try {
      final tags = await _fetchTags();
      state = AsyncValue.data(tags);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<List<Tag>> _fetchTags() async {
    final apiClient = ref.read(apiClientProvider);
    final cacheService = await ref.read(cacheServiceProvider.future);
    final tags = await apiClient.getTags();
    final jsonString = CacheService.encodeList(tags, (tag) => tag.toJson());
    await cacheService.cacheTags(jsonString);
    return tags;
  }
}

final tagsProvider = AsyncNotifierProvider<TagsNotifier, List<Tag>>(
  TagsNotifier.new,
);

enum NetworkStatus { online, offline }

NetworkStatus _networkStatusFromResults(List<ConnectivityResult> results) {
  if (results.isEmpty) {
    return NetworkStatus.offline;
  }

  final hasConnection = results.any(
    (result) => result != ConnectivityResult.none,
  );
  return hasConnection ? NetworkStatus.online : NetworkStatus.offline;
}

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) async* {
  final connectivity = Connectivity();

  final initialResult = await connectivity.checkConnectivity();
  yield _networkStatusFromResults(initialResult);

  await for (final results in connectivity.onConnectivityChanged) {
    yield _networkStatusFromResults(results);
  }
});

/// Provider for the app router
final routerProvider = Provider<GoRouter>((ref) {
  return createRouter(ref);
});

/// Provider for handling shared URLs from external apps
final sharedUrlProvider = NotifierProvider<SharedUrlNotifier, String?>(
  SharedUrlNotifier.new,
);

/// Notifier for managing shared URL state
class SharedUrlNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setSharedUrl(String url) {
    state = url;
  }

  void clearSharedUrl() {
    state = null;
  }
}
