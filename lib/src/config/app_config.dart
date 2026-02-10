enum AppEnvironment { dev, staging, prod }

class AppConfig {
  AppConfig({
    required this.env,
    required this.apiBaseUrl,
    required this.openApiSpecUrl,
    required this.logHttp,
    required this.entraClientId,
    required this.entraTenantId,
    required this.entraScopes,
    required this.entraRedirectUri,
  });

  final AppEnvironment env;
  final String apiBaseUrl;
  final String openApiSpecUrl;
  final bool logHttp;
  final String entraClientId;
  final String entraTenantId;
  final String entraScopes;
  final String entraRedirectUri;

  static AppConfig fromDartDefines({
    required AppEnvironment defaultEnv,
    String? defaultApiBaseUrl,
    String? defaultOpenApiSpecUrl,
    bool defaultLogHttp = false,
    String? defaultEntraClientId,
    String? defaultEntraTenantId,
    String? defaultEntraScopes,
    String? defaultEntraRedirectUri,
  }) {
    final env = _parseEnvironment(
      String.fromEnvironment('APP_ENV', defaultValue: defaultEnv.name),
    );

    final apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: defaultApiBaseUrl ?? '',
    );

    final openApiSpecUrl = String.fromEnvironment(
      'OPENAPI_SPEC_URL',
      defaultValue: defaultOpenApiSpecUrl ?? '',
    );

    final logHttpRaw = String.fromEnvironment(
      'LOG_HTTP',
      defaultValue: defaultLogHttp.toString(),
    );

    final logHttp = _parseBool(logHttpRaw, key: 'LOG_HTTP');

    final entraClientId = String.fromEnvironment(
      'ENTRA_CLIENT_ID',
      defaultValue: defaultEntraClientId ?? '',
    );

    final entraTenantId = String.fromEnvironment(
      'ENTRA_TENANT_ID',
      defaultValue: defaultEntraTenantId ?? '',
    );

    final entraScopes = String.fromEnvironment(
      'ENTRA_SCOPES',
      defaultValue: defaultEntraScopes ?? '',
    );

    final entraRedirectUri = String.fromEnvironment(
      'ENTRA_REDIRECT_URI',
      defaultValue: defaultEntraRedirectUri ?? '',
    );

    _validateUrl(key: 'API_BASE_URL', value: apiBaseUrl, env: env);

    _validateUrl(key: 'OPENAPI_SPEC_URL', value: openApiSpecUrl, env: env);

    _validateNonEmpty(key: 'ENTRA_CLIENT_ID', value: entraClientId, env: env);
    _validateNonEmpty(key: 'ENTRA_TENANT_ID', value: entraTenantId, env: env);
    _validateNonEmpty(key: 'ENTRA_SCOPES', value: entraScopes, env: env);
    _validateNonEmpty(
      key: 'ENTRA_REDIRECT_URI',
      value: entraRedirectUri,
      env: env,
    );

    return AppConfig(
      env: env,
      apiBaseUrl: apiBaseUrl,
      openApiSpecUrl: openApiSpecUrl,
      logHttp: logHttp,
      entraClientId: entraClientId,
      entraTenantId: entraTenantId,
      entraScopes: entraScopes,
      entraRedirectUri: entraRedirectUri,
    );
  }

  static AppEnvironment _parseEnvironment(String raw) {
    switch (raw) {
      case 'dev':
        return AppEnvironment.dev;
      case 'staging':
        return AppEnvironment.staging;
      case 'prod':
        return AppEnvironment.prod;
      default:
        throw AppConfigException(
          'Invalid APP_ENV "$raw". Allowed: dev, staging, prod.',
        );
    }
  }

  static bool _parseBool(String raw, {required String key}) {
    switch (raw) {
      case 'true':
        return true;
      case 'false':
        return false;
      default:
        throw AppConfigException('Invalid $key "$raw". Allowed: true, false.');
    }
  }

  static void _validateUrl({
    required String key,
    required String value,
    required AppEnvironment env,
  }) {
    if (value.isEmpty) {
      throw AppConfigException(
        'Missing $key for ${env.name}. Pass --dart-define=$key=<absolute_url>.',
      );
    }

    final parsed = Uri.tryParse(value);
    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
      throw AppConfigException(
        'Invalid $key "$value". It must be an absolute URL.',
      );
    }
  }

  static void _validateNonEmpty({
    required String key,
    required String value,
    required AppEnvironment env,
  }) {
    if (value.isEmpty) {
      throw AppConfigException(
        'Missing $key for ${env.name}. Pass --dart-define=$key=<value>.',
      );
    }
  }
}

class AppConfigException implements Exception {
  const AppConfigException(this.message);

  final String message;

  @override
  String toString() => 'AppConfigException: $message';
}
