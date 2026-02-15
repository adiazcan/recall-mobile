import 'package:flutter_test/flutter_test.dart';
import 'package:recall/src/models/item.dart';

void main() {
  Map<String, dynamic> baseItemJson() {
    return {
      'id': 'item-1',
      'url': 'https://example.com',
      'title': 'Example',
      'domain': 'example.com',
      'status': 'unread',
      'isFavorite': false,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-01T00:00:00.000Z',
    };
  }

  test('Item.fromJson parses tags when they are objects', () {
    final json = baseItemJson()
      ..['tags'] = [
        {'id': 'tag-1', 'name': 'work'},
      ];

    final item = Item.fromJson(json);

    expect(item.tags.length, 1);
    expect(item.tags.first.id, 'tag-1');
    expect(item.tags.first.name, 'work');
  });

  test('Item.fromJson parses tags when they are strings', () {
    final json = baseItemJson()..['tags'] = ['work', 'personal'];

    final item = Item.fromJson(json);

    expect(item.tags.length, 2);
    expect(item.tags[0].id, 'work');
    expect(item.tags[0].name, 'work');
    expect(item.tags[1].id, 'personal');
    expect(item.tags[1].name, 'personal');
  });

  test(
    'thumbnailImageUrl falls back to thumbnailUrl when previewImageUrl is null',
    () {
      final json = baseItemJson()
        ..['previewImageUrl'] = null
        ..['thumbnailUrl'] = 'https://cdn.example.com/thumb.jpg';

      final item = Item.fromJson(json);

      expect(item.thumbnailImageUrl, 'https://cdn.example.com/thumb.jpg');
    },
  );

  test('thumbnailImageUrl prefers previewImageUrl when both are present', () {
    final json = baseItemJson()
      ..['previewImageUrl'] = 'https://cdn.example.com/preview.jpg'
      ..['thumbnailUrl'] = 'https://cdn.example.com/thumb.jpg';

    final item = Item.fromJson(json);

    expect(item.thumbnailImageUrl, 'https://cdn.example.com/preview.jpg');
  });

  test(
    'Item.fromJson reads snake_case thumbnail_url when preview is missing',
    () {
      final json = baseItemJson()
        ..['thumbnail_url'] = 'https://cdn.example.com/thumb-snake.jpg';

      final item = Item.fromJson(json);

      expect(item.thumbnailImageUrl, 'https://cdn.example.com/thumb-snake.jpg');
    },
  );

  test('Item.fromJson reads snake_case preview_image_url before thumbnail', () {
    final json = baseItemJson()
      ..['preview_image_url'] = 'https://cdn.example.com/preview-snake.jpg'
      ..['thumbnail_url'] = 'https://cdn.example.com/thumb-snake.jpg';

    final item = Item.fromJson(json);

    expect(item.thumbnailImageUrl, 'https://cdn.example.com/preview-snake.jpg');
  });
}
