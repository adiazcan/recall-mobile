import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  CacheService({required this.prefs});

  final SharedPreferences prefs;

  static const _itemsKey = 'cache_items_json';
  static const _collectionsKey = 'cache_collections_json';
  static const _tagsKey = 'cache_tags_json';

  // Items cache

  Future<void> cacheItems(String jsonString) async {
    await prefs.setString(_itemsKey, jsonString);
  }

  String? getCachedItems() {
    return prefs.getString(_itemsKey);
  }

  Future<void> clearItems() async {
    await prefs.remove(_itemsKey);
  }

  // Collections cache

  Future<void> cacheCollections(String jsonString) async {
    await prefs.setString(_collectionsKey, jsonString);
  }

  String? getCachedCollections() {
    return prefs.getString(_collectionsKey);
  }

  Future<void> clearCollections() async {
    await prefs.remove(_collectionsKey);
  }

  // Tags cache

  Future<void> cacheTags(String jsonString) async {
    await prefs.setString(_tagsKey, jsonString);
  }

  String? getCachedTags() {
    return prefs.getString(_tagsKey);
  }

  Future<void> clearTags() async {
    await prefs.remove(_tagsKey);
  }

  // Clear all caches

  Future<void> clearAll() async {
    await Future.wait([clearItems(), clearCollections(), clearTags()]);
  }

  // Type-safe helpers for encoding/decoding

  static String encodeList<T>(
    List<T> items,
    Map<String, dynamic> Function(T) toJson,
  ) {
    return jsonEncode(items.map(toJson).toList());
  }

  static List<T> decodeList<T>(
    String jsonString,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
