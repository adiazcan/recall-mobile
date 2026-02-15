import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/src/app/providers.dart';
import 'package:recall/src/config/app_config.dart';
import 'package:recall/src/features/collections/collections_providers.dart';
import 'package:recall/src/features/inbox/inbox_providers.dart';
import 'package:recall/src/features/inbox/inbox_screen.dart';
import 'package:recall/src/features/inbox/quick_save_overlay.dart';
import 'package:recall/src/models/collection.dart';
import 'package:recall/src/models/item.dart';
import 'package:recall/src/models/paginated_response.dart';
import 'package:recall/src/models/tag.dart';
import 'package:recall/src/network/api_client.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(dio: Dio());

  final List<String> savedUrls = <String>[];

  @override
  Future<Item> createItem({
    required String url,
    String? collectionId,
    List<String>? tagIds,
  }) async {
    savedUrls.add(url);
    return Item(
      id: 'item-1',
      url: url,
      title: 'Saved item',
      excerpt: null,
      domain: 'example.com',
      previewImageUrl: null,
      thumbnailUrl: null,
      status: ItemStatus.unread,
      isFavorite: false,
      collectionId: collectionId,
      tags: const [],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<PaginatedResponse<Item>> getItems({
    String? status,
    bool? isFavorite,
    String? collectionId,
    List<String>? tagIds,
    String? cursor,
    int limit = 20,
  }) async {
    return const PaginatedResponse<Item>(items: []);
  }

  @override
  Future<List<Collection>> getCollections() async => const [];

  @override
  Future<List<Tag>> getTags() async => const [];
}

class _FakeInboxNotifier extends InboxNotifier {
  @override
  Future<InboxState> build() async {
    return const InboxState(
      items: [],
      filters: InboxFilters(status: 'unread'),
      nextCursor: null,
      hasMore: false,
      isLoadingMore: false,
      backgroundError: null,
    );
  }

  @override
  Future<void> updateFilters(InboxFilters newFilters) async {
    final currentState = state.asData?.value;
    if (currentState == null) {
      return;
    }

    state = AsyncValue.data(
      currentState.copyWith(
        filters: newFilters,
        items: [],
        nextCursor: () => null,
        hasMore: false,
        isLoadingMore: false,
        backgroundError: () => null,
      ),
    );
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadMore() async {}
}

class _FakeCollectionsNotifier extends CollectionsNotifier {
  @override
  Future<List<Collection>> build() async => const [];
}

class _FakeTagsNotifier extends TagsNotifier {
  @override
  Future<List<Tag>> build() async => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': ''};
          }
          if (call.method == 'Clipboard.setData') {
            return null;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('quick-save overlay opens, saves, and dismisses', (tester) async {
    final fakeApiClient = _FakeApiClient();

    final config = AppConfig(
      env: AppEnvironment.dev,
      apiBaseUrl: 'https://example.dev',
      openApiSpecUrl: 'https://example.dev/openapi/v1.json',
      logHttp: false,
      entraClientId: 'test-client-id',
      entraTenantId: 'test-tenant-id',
      entraScopes: 'api://test/scope',
      entraRedirectUri: 'msauth://com.recall.mobile/callback',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          apiClientProvider.overrideWithValue(fakeApiClient),
          inboxProvider.overrideWith(_FakeInboxNotifier.new),
          collectionsProvider.overrideWith(_FakeCollectionsNotifier.new),
          tagsProvider.overrideWith(_FakeTagsNotifier.new),
        ],
        child: const MaterialApp(home: InboxScreen()),
      ),
    );

    await tester.pump();

    expect(find.byType(QuickSaveOverlay), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.byType(QuickSaveOverlay), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'https://example.com/article',
    );
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(fakeApiClient.savedUrls, ['https://example.com/article']);
    expect(find.text('URL saved successfully!'), findsOneWidget);
    expect(find.byType(QuickSaveOverlay), findsNothing);
  });
}
