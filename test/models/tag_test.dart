import 'package:flutter_test/flutter_test.dart';
import 'package:recall/src/models/tag.dart';

void main() {
  test('Tag.fromJson parses valid id/name values', () {
    final tag = Tag.fromJson({'id': 'tag-1', 'name': 'work'});

    expect(tag.id, 'tag-1');
    expect(tag.name, 'work');
  });

  test('Tag.fromJson falls back to name when id is null', () {
    final tag = Tag.fromJson({'id': null, 'name': 'work'});

    expect(tag.id, 'work');
    expect(tag.name, 'work');
  });

  test('Tag.fromJson falls back to id when name is null', () {
    final tag = Tag.fromJson({'id': 'tag-1', 'name': null});

    expect(tag.id, 'tag-1');
    expect(tag.name, 'tag-1');
  });

  test('Tag.fromJson throws when id and name are both missing', () {
    expect(
      () => Tag.fromJson({'id': null, 'name': null}),
      throwsA(isA<FormatException>()),
    );
  });
}
