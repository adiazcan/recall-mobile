import 'package:dio/dio.dart';

import '../models/collection.dart';
import '../models/item.dart';
import '../models/paginated_response.dart';
import '../models/tag.dart';

class ApiClient {
  ApiClient({required this.dio});

  final Dio dio;

  // Items endpoints

  Future<PaginatedResponse<Item>> getItems({
    String? status,
    bool? isFavorite,
    String? collectionId,
    List<String>? tagIds,
    String? cursor,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit.toString(),
      if (cursor?.isNotEmpty ?? false) 'cursor': cursor,
      if (status?.isNotEmpty ?? false) 'status': status,
      if (isFavorite != null) 'favorite': isFavorite.toString(),
      if (collectionId?.isNotEmpty ?? false) 'collectionId': collectionId,
      if (tagIds?.isNotEmpty ?? false) 'tag': tagIds!.first,
      if (tagIds?.isNotEmpty ?? false) 'tags': tagIds!.join(','),
    };

    final response = await dio.get(
      '/api/v1/items',
      queryParameters: queryParams,
    );

    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      'items',
      (json) => Item.fromJson(json),
    );
  }

  Future<Item> getItem(String id) async {
    final response = await dio.get('/api/v1/items/$id');
    return Item.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Item> createItem({
    required String url,
    String? collectionId,
    List<String>? tagIds,
  }) async {
    final tags = tagIds?.where((tag) => tag.trim().isNotEmpty).toList();

    final primaryPayload = {
      'url': url,
      if (collectionId?.isNotEmpty ?? false) 'collectionId': collectionId,
      if (tags?.isNotEmpty ?? false) 'tags': tags,
    };

    try {
      final response = await dio.post('/api/v1/items', data: primaryPayload);
      return Item.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      final shouldRetryLegacy =
          error.response?.statusCode == 400 && tags?.isNotEmpty == true;

      if (!shouldRetryLegacy) {
        rethrow;
      }

      final legacyPayload = {
        'url': url,
        if (collectionId?.isNotEmpty ?? false) 'collectionId': collectionId,
        'tagIds': tags,
      };

      final response = await dio.post('/api/v1/items', data: legacyPayload);
      return Item.fromJson(response.data as Map<String, dynamic>);
    }
  }

  Future<Item> updateItem(
    String id, {
    String? status,
    bool? isFavorite,
    String? collectionId,
    List<String>? tagIds,
  }) async {
    final tags = tagIds?.where((tag) => tag.trim().isNotEmpty).toList();

    final data = <String, dynamic>{};
    if (status != null) data['status'] = status;
    if (isFavorite != null) data['isFavorite'] = isFavorite;
    if (collectionId != null) data['collectionId'] = collectionId;
    if (tags != null) data['tags'] = tags;

    try {
      final response = await dio.patch('/api/v1/items/$id', data: data);
      return Item.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      final shouldRetryWithTagPayloadVariants =
          error.response?.statusCode == 400 && tags != null;

      if (!shouldRetryWithTagPayloadVariants) {
        rethrow;
      }

      final commonPayload = <String, dynamic>{};
      if (status != null) commonPayload['status'] = status;
      if (isFavorite != null) commonPayload['isFavorite'] = isFavorite;
      if (collectionId != null) commonPayload['collectionId'] = collectionId;

      final retryPayloads = <Map<String, dynamic>>[
        {...commonPayload, 'tagIds': tags},
        {...commonPayload, 'tags': tags.join(',')},
      ];

      for (final payload in retryPayloads) {
        try {
          final response = await dio.patch('/api/v1/items/$id', data: payload);
          return Item.fromJson(response.data as Map<String, dynamic>);
        } on DioException catch (retryError) {
          if (retryError.response?.statusCode != 400) {
            rethrow;
          }
        }
      }

      rethrow;
    }
  }

  Future<void> deleteItem(String id) async {
    await dio.delete('/api/v1/items/$id');
  }

  // Collections endpoints

  Future<List<Collection>> getCollections() async {
    final response = await dio.get('/api/v1/collections');
    final data = response.data as Map<String, dynamic>;
    final collections = data['collections'] as List<dynamic>;
    return collections
        .map((json) => Collection.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Collection> getCollection(String id) async {
    final response = await dio.get('/api/v1/collections/$id');
    return Collection.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Collection> createCollection(String name) async {
    final response = await dio.post(
      '/api/v1/collections',
      data: {'name': name},
    );
    return Collection.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Collection> updateCollection(String id, String name) async {
    final response = await dio.patch(
      '/api/v1/collections/$id',
      data: {'name': name},
    );
    return Collection.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCollection(String id) async {
    await dio.delete('/api/v1/collections/$id');
  }

  // Tags endpoints

  Future<List<Tag>> getTags() async {
    final response = await dio.get('/api/v1/tags');
    final data = response.data as Map<String, dynamic>;

    final rawTags = data['tags'];
    if (rawTags is! List<dynamic>) {
      return [];
    }

    final tags = rawTags;
    return tags
        .map((json) {
          if (json is! Map<String, dynamic>) {
            return null;
          }

          try {
            return Tag.fromJson(json);
          } on FormatException {
            return null;
          }
        })
        .whereType<Tag>()
        .toList();
  }

  Future<Tag> createTag(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Tag name cannot be empty');
    }

    // Live backend does not expose POST /api/v1/tags.
    // Tags are created implicitly when attached to an item update/create.
    return Tag(id: trimmed, name: trimmed);
  }
}
