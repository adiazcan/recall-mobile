import 'package:flutter_test/flutter_test.dart';
import 'package:recall/src/auth/token_store.dart';

void main() {
  test('in-memory token store set/read/clear', () async {
    final store = InMemoryTokenStore();
    final expiresAt = DateTime.utc(2030, 1, 1);

    await store.setTokens(
      accessToken: 'access-123',
      refreshToken: 'refresh-456',
      expiresAt: expiresAt,
    );

    final tokens = await store.readTokens();
    expect(tokens, isNotNull);
    expect(tokens?.accessToken, 'access-123');
    expect(tokens?.refreshToken, 'refresh-456');
    expect(tokens?.expiresAt, expiresAt);

    await store.clear();
    expect(await store.readTokens(), isNull);
  });
}
