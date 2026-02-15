import 'tag.dart';

enum ItemStatus {
  unread,
  archived;

  static ItemStatus fromJson(String value) {
    switch (value) {
      case 'unread':
        return ItemStatus.unread;
      case 'archived':
        return ItemStatus.archived;
      default:
        throw ArgumentError('Unknown ItemStatus: $value');
    }
  }
}

class Item {
  const Item({
    required this.id,
    required this.url,
    required this.title,
    this.excerpt,
    required this.domain,
    this.previewImageUrl,
    this.thumbnailUrl,
    required this.status,
    required this.isFavorite,
    this.collectionId,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String url;
  final String title;
  final String? excerpt;
  final String domain;
  final String? previewImageUrl;
  final String? thumbnailUrl;
  final ItemStatus status;
  final bool isFavorite;
  final String? collectionId;
  final List<Tag> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  String? get thumbnailImageUrl {
    final preview = previewImageUrl?.trim();
    if (preview != null && preview.isNotEmpty) {
      return preview;
    }

    final thumbnail = thumbnailUrl?.trim();
    if (thumbnail != null && thumbnail.isNotEmpty) {
      return thumbnail;
    }

    return null;
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      url: json['url'] as String,
      title: (json['title'] as String?) ?? 'Untitled',
      excerpt: json['excerpt'] as String?,
      domain: (json['domain'] as String?) ?? '',
      previewImageUrl: _readString(
        json,
        const [
          'previewImageUrl',
          'preview_image_url',
          'preview_image',
          'imageUrl',
          'image_url',
        ],
      ),
      thumbnailUrl: _readString(
        json,
        const ['thumbnailUrl', 'thumbnail_url', 'thumbnail'],
      ),
      status: ItemStatus.fromJson((json['status'] as String?) ?? 'unread'),
      isFavorite: (json['isFavorite'] as bool?) ?? false,
      collectionId: json['collectionId'] as String?,
      tags: _parseTags(json['tags']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static String? _readString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static List<Tag> _parseTags(dynamic value) {
    if (value is! List<dynamic>) {
      return [];
    }

    return value
        .map((tagJson) {
          if (tagJson is Map<String, dynamic>) {
            try {
              return Tag.fromJson(tagJson);
            } on FormatException {
              // Ignore invalid tag objects that cannot be parsed.
              return null;
            }
          }

          if (tagJson is String && tagJson.isNotEmpty) {
            return Tag(id: tagJson, name: tagJson);
          }

          return null;
        })
        .whereType<Tag>()
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'excerpt': excerpt,
      'domain': domain,
      'previewImageUrl': previewImageUrl,
      'thumbnailUrl': thumbnailUrl,
      'status': status.name,
      'isFavorite': isFavorite,
      'collectionId': collectionId,
      'tags': tags.map((t) => t.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Item copyWith({
    String? id,
    String? url,
    String? title,
    String? Function()? excerpt,
    String? domain,
    String? Function()? previewImageUrl,
    String? Function()? thumbnailUrl,
    ItemStatus? status,
    bool? isFavorite,
    String? Function()? collectionId,
    List<Tag>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      excerpt: excerpt != null ? excerpt() : this.excerpt,
      domain: domain ?? this.domain,
      previewImageUrl: previewImageUrl != null
          ? previewImageUrl()
          : this.previewImageUrl,
        thumbnailUrl: thumbnailUrl != null ? thumbnailUrl() : this.thumbnailUrl,
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
      collectionId: collectionId != null ? collectionId() : this.collectionId,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
