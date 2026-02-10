import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall/src/app/app.dart';
import 'package:recall/src/app/providers.dart';
import 'package:recall/src/auth/auth_service.dart';
import 'package:recall/src/auth/auth_state.dart';
import 'package:recall/src/auth/token_store.dart';
import 'package:recall/src/config/app_config.dart';
import 'package:recall/src/openapi/openapi_repository.dart';

// Mock AuthStateNotifier that returns authenticated state
class MockAuthStateNotifier extends AuthStateNotifier {
  MockAuthStateNotifier()
    : super(authService: _MockAuthService(), tokenStore: _MockTokenStore());

  @override
  Future<AuthState> build() async {
    return const AuthState(status: AuthStatus.authenticated);
  }
}

// Minimal mocks for dependencies
class _MockAuthService implements AuthService {
  @override
  String get clientId => 'mock-client-id';

  @override
  String get tenantId => 'mock-tenant-id';

  @override
  String get redirectUri => 'mock://redirect';

  @override
  TokenStore get tokenStore => _MockTokenStore();

  @override
  Future<String?> acquireTokenSilent() async => 'mock-token';

  @override
  Future<String> signIn() async => 'mock-token';

  @override
  Future<String> refreshToken() async => 'mock-token';

  @override
  Future<void> signOut() async {}
}

class _MockTokenStore implements TokenStore {
  @override
  Future<String?> getToken() async => 'mock-token';

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<void> deleteToken() async {}

  @override
  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {}

  @override
  Future<Tokens?> readTokens() async {
    return const Tokens(
      accessToken: 'mock-token',
      refreshToken: 'mock-refresh',
    );
  }

  @override
  Future<void> clear() async {}
}

class DelayedOpenApiRepository extends OpenApiRepository {
  DelayedOpenApiRepository()
    : super(
        client: Dio(),
        config: AppConfig(
          env: AppEnvironment.dev,
          apiBaseUrl: 'https://example.dev',
          openApiSpecUrl: 'https://example.dev/openapi/v1.json',
          logHttp: true,
          entraClientId: 'test-client-id',
          entraTenantId: 'test-tenant-id',
          entraScopes: 'api://test/scope',
          entraRedirectUri: 'msauth://com.recall.mobile/callback',
        ),
      );

  @override
  Future<OpenApiDocument> fetchSpec() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const OpenApiDocument(
      statusCode: 200,
      rawJson: '{"openapi":"3.1.0"}',
      summary: OpenApiSummary(
        openapi: '3.1.0',
        title: 'Recall API',
        version: '1.0.0',
      ),
    );
  }
}

void main() {
  testWidgets('app launches and shows inbox when authenticated', (
    tester,
  ) async {
    final config = AppConfig(
      env: AppEnvironment.dev,
      apiBaseUrl: 'https://example.dev',
      openApiSpecUrl: 'https://example.dev/openapi/v1.json',
      logHttp: true,
      entraClientId: 'test-client-id',
      entraTenantId: 'test-tenant-id',
      entraScopes: 'api://test/scope',
      entraRedirectUri: 'msauth://com.recall.mobile/callback',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          authStateProvider.overrideWith(() => MockAuthStateNotifier()),
          openApiRepositoryProvider.overrideWithValue(
            DelayedOpenApiRepository(),
          ),
        ],
        child: const RecallApp(),
      ),
    );

    // Wait for initial route to settle
    await tester.pumpAndSettle();

    // Verify we're on the inbox screen (which is the default authenticated route)
    expect(find.text('Inbox'), findsWidgets);

    // Verify bottom navigation is present
    expect(find.text('Collections'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
