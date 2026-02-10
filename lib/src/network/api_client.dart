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
      if (isFavorite != null) 'is_favorite': isFavorite.toString(),
      if (collectionId?.isNotEmpty ?? false) 'collection_id': collectionId,
      if (tagIds?.isNotEmpty ?? false) 'tag_ids': tagIds!.join(','),
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
    final response = await dio.post(
      '/api/v1/items',
      data: {
        'url': url,
        if (collectionId?.isNotEmpty ?? false) 'collection_id': collectionId,
        if (tagIds?.isNotEmpty ?? false) 'tag_ids': tagIds,
      },
    );

    return Item.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Item> updateItem(
    String id, {
    String? status,
    bool? isFavorite,
    String? collectionId,
    List<String>? tagIds,
  }) async {
    final data = <String, dynamic>{};
    if (status != null) data['status'] = status;
    if (isFavorite != null) data['is_favorite'] = isFavorite;
    if (collectionId != null) data['collection_id'] = collectionId;
    if (tagIds != null) data['tag_ids'] = tagIds;

    final response = await dio.patch('/api/v1/items/$id', data: data);
    return Item.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteItem(String id) async {
    await dio.delete('/api/v1/items/$id');
  }

  // Collections endpoints

  Future<List<Collection>> getCollections() async {
    final response = await dio.get('/api/v1/collections');
    final data = response.data as List<dynamic>;
    return data
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
    final data = response.data as List<dynamic>;
    return data
        .map((json) => Tag.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Tag> createTag(String name) async {
    final response = await dio.post('/api/v1/tags', data: {'name': name});
    return Tag.fromJson(response.data as Map<String, dynamic>);
  }
}
