import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall/src/app/app.dart';
import 'package:recall/src/app/providers.dart';
import 'package:recall/src/auth/auth_state.dart';
import 'package:recall/src/config/app_config.dart';
import 'package:recall/src/openapi/openapi_repository.dart';

// Mock AuthStateNotifier that returns authenticated state
class MockAuthStateNotifier extends AuthStateNotifier {
  @override
  Future<AuthState> build() async {
    return const AuthState(status: AuthStatus.authenticated);
  }
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

    // Wait for initial route to load
    // Note: Using pump() instead of pumpAndSettle() because
    // ReceiveSharingIntent streams prevent settling in tests
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify we're on the inbox screen (which is the default authenticated route)
    expect(find.text('Inbox'), findsWidgets);

    // Open drawer and verify navigation entries
    await tester.tap(find.byIcon(Icons.menu).first);
    await tester.pump();

    expect(find.text('Recall'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Archive'), findsOneWidget);
    expect(find.text('COLLECTIONS'), findsOneWidget);
    expect(find.text('TAGS'), findsOneWidget);
  });
}
