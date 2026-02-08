import 'package:flutter_test/flutter_test.dart';
import 'package:recall/src/config/app_config.dart';

void main() {
  group('AppConfig.fromDartDefines', () {
    test('loads dev defaults', () {
      final config = AppConfig.fromDartDefines(
        defaultEnv: AppEnvironment.dev,
        defaultApiBaseUrl: 'https://example.dev',
        defaultOpenApiSpecUrl: 'https://example.dev/openapi/v1.json',
        defaultLogHttp: true,
      );

      expect(config.env, AppEnvironment.dev);
      expect(config.apiBaseUrl, 'https://example.dev');
      expect(config.openApiSpecUrl, 'https://example.dev/openapi/v1.json');
      expect(config.logHttp, true);
    });

    test('requires staging URL defines when no defaults are provided', () {
      expect(
        () => AppConfig.fromDartDefines(defaultEnv: AppEnvironment.staging),
        throwsA(
          isA<AppConfigException>().having(
            (error) => error.message,
            'message',
            contains('Missing API_BASE_URL for staging'),
          ),
        ),
      );
    });

    test('requires prod URL defines when no defaults are provided', () {
      expect(
        () => AppConfig.fromDartDefines(defaultEnv: AppEnvironment.prod),
        throwsA(
          isA<AppConfigException>().having(
            (error) => error.message,
            'message',
            contains('Missing API_BASE_URL for prod'),
          ),
        ),
      );
    });
  });
}
