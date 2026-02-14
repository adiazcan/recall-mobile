import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../models/item.dart';
import '../../models/tag.dart';
import '../inbox/inbox_providers.dart';

// Provider for a single item's state
final itemDetailProvider = FutureProvider.family<Item, String>((
  ref,
  itemId,
) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getItem(itemId);
});

// Notifier for item mutations
class ItemDetailNotifier extends Notifier<void> {
  @override
  void build() {
    // No state to build
  }

  Future<Item> toggleFavorite(String itemId, bool currentIsFavorite) async {
    final apiClient = ref.read(apiClientProvider);
    final updatedItem = await apiClient.updateItem(
      itemId,
      isFavorite: !currentIsFavorite,
    );

    // Invalidate the item detail provider to refresh
    ref.invalidate(itemDetailProvider(itemId));

    // Update the item in the inbox list
    final inboxNotifier = ref.read(inboxProvider.notifier);
    inboxNotifier.updateItem(updatedItem);

    return updatedItem;
  }

  Future<Item> updateStatus(String itemId, ItemStatus newStatus) async {
    final apiClient = ref.read(apiClientProvider);
    final updatedItem = await apiClient.updateItem(
      itemId,
      status: newStatus.name,
    );

    // Invalidate the item detail provider to refresh
    ref.invalidate(itemDetailProvider(itemId));

    // Update the item in the inbox list
    final inboxNotifier = ref.read(inboxProvider.notifier);
    inboxNotifier.updateItem(updatedItem);

    return updatedItem;
  }

  Future<Item> updateTags(String itemId, List<Tag> tags) async {
    final apiClient = ref.read(apiClientProvider);
    final updatedItem = await apiClient.updateItem(
      itemId,
      tagIds: tags.map((t) => t.name).toList(),
    );

    // Invalidate the item detail provider to refresh
    ref.invalidate(itemDetailProvider(itemId));

    // Update the item in the inbox list
    final inboxNotifier = ref.read(inboxProvider.notifier);
    inboxNotifier.updateItem(updatedItem);

    return updatedItem;
  }

  Future<Item> moveToCollection(String itemId, String? collectionId) async {
    final apiClient = ref.read(apiClientProvider);
    final updatedItem = await apiClient.updateItem(
      itemId,
      collectionId: collectionId,
    );

    // Invalidate the item detail provider to refresh
    ref.invalidate(itemDetailProvider(itemId));

    // Update the item in the inbox list
    final inboxNotifier = ref.read(inboxProvider.notifier);
    inboxNotifier.updateItem(updatedItem);

    return updatedItem;
  }

  Future<void> deleteItem(String itemId) async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.deleteItem(itemId);

    // Invalidate the item detail provider
    ref.invalidate(itemDetailProvider(itemId));

    // Remove the item from the inbox list
    final inboxNotifier = ref.read(inboxProvider.notifier);
    inboxNotifier.removeItem(itemId);
  }
}

final itemDetailNotifierProvider = NotifierProvider<ItemDetailNotifier, void>(
  ItemDetailNotifier.new,
);
