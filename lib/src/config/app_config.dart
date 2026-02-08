enum AppEnvironment { dev, staging, prod }

class AppConfig {
  AppConfig({
    required this.env,
    required this.apiBaseUrl,
    required this.openApiSpecUrl,
    required this.logHttp,
  });

  final AppEnvironment env;
  final String apiBaseUrl;
  final String openApiSpecUrl;
  final bool logHttp;

  static AppConfig fromDartDefines({
    required AppEnvironment defaultEnv,
    String? defaultApiBaseUrl,
    String? defaultOpenApiSpecUrl,
    bool defaultLogHttp = false,
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

    _validateUrl(key: 'API_BASE_URL', value: apiBaseUrl, env: env);

    _validateUrl(key: 'OPENAPI_SPEC_URL', value: openApiSpecUrl, env: env);

    return AppConfig(
      env: env,
      apiBaseUrl: apiBaseUrl,
      openApiSpecUrl: openApiSpecUrl,
      logHttp: logHttp,
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
}

class AppConfigException implements Exception {
  const AppConfigException(this.message);

  final String message;

  @override
  String toString() => 'AppConfigException: $message';
}
