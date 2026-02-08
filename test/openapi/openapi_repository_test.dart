import 'package:flutter_test/flutter_test.dart';
import 'package:recall/src/openapi/openapi_repository.dart';

void main() {
  test('parseOpenApiSummary extracts info fields', () {
    const payload = {
      'openapi': '3.1.0',
      'info': {'title': 'Recall API', 'version': '1.2.3'},
    };

    final summary = parseOpenApiSummary(payload);

    expect(summary.openapi, '3.1.0');
    expect(summary.title, 'Recall API');
    expect(summary.version, '1.2.3');
  });
}
