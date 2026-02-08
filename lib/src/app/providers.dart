import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/token_store.dart';
import '../config/app_config.dart';
import '../network/dio_provider.dart';
import '../openapi/openapi_repository.dart';

final appConfigProvider = Provider<AppConfig>(
  (_) => throw const AppConfigException('AppConfig override is required.'),
);

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (_) => SharedPreferences.getInstance(),
);

final tokenStoreProvider = Provider<TokenStore>((_) => SecureTokenStore());

final dioProvider = Provider<Dio>((ref) {
  return buildDioClient(
    config: ref.watch(appConfigProvider),
    tokenStore: ref.watch(tokenStoreProvider),
  );
});

final openApiRepositoryProvider = Provider<OpenApiRepository>((ref) {
  return OpenApiRepository(
    client: ref.watch(dioProvider),
    config: ref.watch(appConfigProvider),
  );
});
