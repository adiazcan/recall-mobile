import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app/app.dart';
import 'src/app/providers.dart';
import 'src/config/app_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://aca-recall-api-dev.agreeablecliff-2d868e3f.westeurope.azurecontainerapps.io',
  );
  const openApiSpecUrl = String.fromEnvironment(
    'OPENAPI_SPEC_URL',
    defaultValue:
        'https://aca-recall-api-dev.agreeablecliff-2d868e3f.westeurope.azurecontainerapps.io/openapi/v1.json',
  );
  const entraClientId = String.fromEnvironment(
    'ENTRA_CLIENT_ID',
    defaultValue: 'dev-client-id-placeholder',
  );
  const entraTenantId = String.fromEnvironment(
    'ENTRA_TENANT_ID',
    defaultValue: 'dev-tenant-id-placeholder',
  );
  const entraScopes = String.fromEnvironment(
    'ENTRA_SCOPES',
    defaultValue: 'api://recall/Items.ReadWrite',
  );
  const entraRedirectUri = String.fromEnvironment(
    'ENTRA_REDIRECT_URI',
    defaultValue: 'msauth://com.recall.mobile/callback',
  );

  try {
    final config = AppConfig.fromDartDefines(
      defaultEnv: AppEnvironment.dev,
      defaultApiBaseUrl: apiBaseUrl,
      defaultOpenApiSpecUrl: openApiSpecUrl,
      defaultLogHttp: true,
      defaultEntraClientId: entraClientId,
      defaultEntraTenantId: entraTenantId,
      defaultEntraScopes: entraScopes,
      defaultEntraRedirectUri: entraRedirectUri,
    );

    runApp(
      ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(config)],
        child: const RecallApp(),
      ),
    );
  } on AppConfigException catch (error) {
    runApp(RecallApp(configError: error.message));
  }
}
