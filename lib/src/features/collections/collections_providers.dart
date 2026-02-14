import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../cache/cache_service.dart';
import '../../models/collection.dart';

class DuplicateCollectionNameException implements Exception {
  const DuplicateCollectionNameException(this.name);

  final String name;

  @override
  String toString() {
    return 'A collection named "$name" already exists.';
  }
}

class InvalidCollectionNameException implements Exception {
  const InvalidCollectionNameException();

  @override
  String toString() {
    return 'Collection name cannot be empty.';
  }
}

class CollectionsNotifier extends AsyncNotifier<List<Collection>> {
  @override
  Future<List<Collection>> build() async {
    final cacheService = await ref.read(cacheServiceProvider.future);
    final cachedJson = cacheService.getCachedCollections();

    if (cachedJson != null && cachedJson.isNotEmpty) {
      final cachedCollections = CacheService.decodeList(
        cachedJson,
        Collection.fromJson,
      );

      unawaited(refresh());
      return cachedCollections;
    }

    return _fetchCollections();
  }

  Future<void> refresh() async {
    try {
      final collections = await _fetchCollections();
      state = AsyncValue.data(collections);
    } catch (error, stackTrace) {
      final current = state.asData?.value;
      if (current == null || current.isEmpty) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> createCollection(String rawName) async {
    final name = rawName.trim();
    _validateName(name);

    final currentCollections = state.asData?.value ?? <Collection>[];
    _ensureUniqueName(name, currentCollections);

    final apiClient = ref.read(apiClientProvider);
    final createdCollection = await apiClient.createCollection(name);

    final updatedCollections = [createdCollection, ...currentCollections]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    await _cacheCollections(updatedCollections);
    state = AsyncValue.data(updatedCollections);
  }

  Future<void> renameCollection(String id, String rawName) async {
    final name = rawName.trim();
    _validateName(name);

    final currentCollections = state.asData?.value ?? <Collection>[];
    _ensureUniqueName(name, currentCollections, ignoreId: id);

    final apiClient = ref.read(apiClientProvider);
    final updatedCollection = await apiClient.updateCollection(id, name);

    final updatedCollections =
        currentCollections
            .map(
              (collection) =>
                  collection.id == id ? updatedCollection : collection,
            )
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    await _cacheCollections(updatedCollections);
    state = AsyncValue.data(updatedCollections);
  }

  Future<void> deleteCollection(String id) async {
    final currentCollections = state.asData?.value ?? <Collection>[];

    final apiClient = ref.read(apiClientProvider);
    await apiClient.deleteCollection(id);

    final updatedCollections = currentCollections
        .where((collection) => collection.id != id)
        .toList();

    await _cacheCollections(updatedCollections);
    state = AsyncValue.data(updatedCollections);
  }

  Future<List<Collection>> _fetchCollections() async {
    final apiClient = ref.read(apiClientProvider);
    final collections = await apiClient.getCollections();
    collections.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    await _cacheCollections(collections);
    return collections;
  }

  Future<void> _cacheCollections(List<Collection> collections) async {
    final cacheService = await ref.read(cacheServiceProvider.future);
    final jsonString = CacheService.encodeList(
      collections,
      (collection) => collection.toJson(),
    );
    await cacheService.cacheCollections(jsonString);
  }

  void _validateName(String name) {
    if (name.isEmpty) {
      throw const InvalidCollectionNameException();
    }
  }

  void _ensureUniqueName(
    String name,
    List<Collection> collections, {
    String? ignoreId,
  }) {
    final lowerName = name.toLowerCase();
    final hasDuplicate = collections.any(
      (collection) =>
          collection.id != ignoreId &&
          collection.name.toLowerCase() == lowerName,
    );

    if (hasDuplicate) {
      throw DuplicateCollectionNameException(name);
    }
  }
}

final collectionsProvider =
    AsyncNotifierProvider<CollectionsNotifier, List<Collection>>(
      CollectionsNotifier.new,
    );
