import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../cache/cache_service.dart';
import '../../models/item.dart';

// Filter state for the inbox
class InboxFilters {
  const InboxFilters({
    this.status,
    this.isFavorite,
    this.collectionId,
    this.tagIds,
  });

  final String? status;
  final bool? isFavorite;
  final String? collectionId;
  final List<String>? tagIds;

  InboxFilters copyWith({
    String? Function()? status,
    bool? Function()? isFavorite,
    String? Function()? collectionId,
    List<String>? Function()? tagIds,
  }) {
    return InboxFilters(
      status: status != null ? status() : this.status,
      isFavorite: isFavorite != null ? isFavorite() : this.isFavorite,
      collectionId: collectionId != null ? collectionId() : this.collectionId,
      tagIds: tagIds != null ? tagIds() : this.tagIds,
    );
  }

  bool get hasActiveFilters =>
      status != null ||
      isFavorite != null ||
      collectionId != null ||
      (tagIds != null && tagIds!.isNotEmpty);

  void clear() {}
}

// State for the inbox screen
class InboxState {
  const InboxState({
    required this.items,
    required this.filters,
    this.nextCursor,
    required this.hasMore,
    required this.isLoadingMore,
  });

  final List<Item> items;
  final InboxFilters filters;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;

  InboxState copyWith({
    List<Item>? items,
    InboxFilters? filters,
    String? Function()? nextCursor,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return InboxState(
      items: items ?? this.items,
      filters: filters ?? this.filters,
      nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

// Inbox provider managing items list, filters, and pagination
class InboxNotifier extends AsyncNotifier<InboxState> {
  @override
  Future<InboxState> build() async {
    final cacheService = await ref.read(cacheServiceProvider.future);
    final cachedItemsJson = cacheService.getCachedItems();

    // Start with cached items if available (stale-while-revalidate)
    final cachedItems = cachedItemsJson != null
        ? CacheService.decodeList(cachedItemsJson, Item.fromJson)
        : <Item>[];

    // Set initial state with cached items
    final initialState = InboxState(
      items: cachedItems,
      filters: const InboxFilters(),
      nextCursor: null,
      hasMore: cachedItems.isEmpty, // Assume more if cache is empty
      isLoadingMore: false,
    );

    // Fetch fresh data in background
    _fetchItems(resetList: true);

    return initialState;
  }

  // Fetch items from API with current filters
  Future<void> _fetchItems({bool resetList = false}) async {
    final apiClient = ref.read(apiClientProvider);
    final cacheService = await ref.read(cacheServiceProvider.future);

    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final cursor = resetList ? null : currentState.nextCursor;

    try {
      final response = await apiClient.getItems(
        status: currentState.filters.status,
        isFavorite: currentState.filters.isFavorite,
        collectionId: currentState.filters.collectionId,
        tagIds: currentState.filters.tagIds,
        cursor: cursor,
      );

      final newItems = resetList
          ? response.items
          : [...currentState.items, ...response.items];

      // Cache the items (full list if reset, otherwise just append)
      if (resetList || currentState.items.isEmpty) {
        final jsonString = CacheService.encodeList(
          newItems,
          (item) => item.toJson(),
        );
        await cacheService.cacheItems(jsonString);
      }

      state = AsyncValue.data(
        currentState.copyWith(
          items: newItems,
          nextCursor: () => response.nextCursor,
          hasMore: response.nextCursor != null,
          isLoadingMore: false,
        ),
      );
    } catch (error, stackTrace) {
      if (resetList) {
        state = AsyncValue.error(error, stackTrace);
      } else {
        // Keep current items on load-more error, just stop loading
        state = AsyncValue.data(currentState.copyWith(isLoadingMore: false));
      }
    }
  }

  // Refresh the list (pull-to-refresh)
  Future<void> refresh() async {
    await _fetchItems(resetList: true);
  }

  // Load more items (infinite scroll)
  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null ||
        !currentState.hasMore ||
        currentState.isLoadingMore) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    await _fetchItems(resetList: false);
  }

  // Update filters and refresh list
  Future<void> updateFilters(InboxFilters newFilters) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = AsyncValue.data(
      currentState.copyWith(
        filters: newFilters,
        items: [],
        nextCursor: () => null,
        hasMore: true,
        isLoadingMore: false,
      ),
    );

    await _fetchItems(resetList: true);
  }

  // Clear all filters
  Future<void> clearFilters() async {
    await updateFilters(const InboxFilters());
  }

  // Update a single item in the list (after mutation)
  void updateItem(Item updatedItem) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedItems = currentState.items.map((item) {
      return item.id == updatedItem.id ? updatedItem : item;
    }).toList();

    state = AsyncValue.data(currentState.copyWith(items: updatedItems));
  }

  // Remove an item from the list (after deletion)
  void removeItem(String itemId) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedItems = currentState.items
        .where((item) => item.id != itemId)
        .toList();

    state = AsyncValue.data(currentState.copyWith(items: updatedItems));
  }
}

// Provider for inbox state
final inboxProvider = AsyncNotifierProvider<InboxNotifier, InboxState>(() {
  return InboxNotifier();
});
