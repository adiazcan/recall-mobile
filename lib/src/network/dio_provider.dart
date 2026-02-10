import 'package:dio/dio.dart';

import '../auth/auth_service.dart';
import '../auth/token_store.dart';
import '../config/app_config.dart';

Dio buildDioClient({
  required AppConfig config,
  required TokenStore tokenStore,
  required AuthService authService,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(tokenStore: tokenStore, authService: authService, dio: dio),
  );

  if (config.logHttp) {
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: false),
    );
  }

  return dio;
}

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.tokenStore,
    required this.authService,
    required this.dio,
  });

  final TokenStore tokenStore;
  final AuthService authService;
  final Dio dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenStore.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      try {
        final newToken = await authService.acquireTokenSilent();

        if (newToken != null) {
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';

          final response = await dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        }
      } catch (_) {
        // Silent refresh failed, let the error propagate
      }
    }

    handler.next(err);
  }
}
