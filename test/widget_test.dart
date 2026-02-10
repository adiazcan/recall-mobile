import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall/src/app/app.dart';
import 'package:recall/src/app/providers.dart';
import 'package:recall/src/config/app_config.dart';
import 'package:recall/src/openapi/openapi_repository.dart';

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
  testWidgets('app launches and shows loading on fetch', (tester) async {
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
          openApiRepositoryProvider.overrideWithValue(
            DelayedOpenApiRepository(),
          ),
        ],
        child: const RecallApp(),
      ),
    );

    expect(find.text('Fetch OpenAPI spec'), findsOneWidget);

    await tester.tap(find.text('Fetch OpenAPI spec'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
