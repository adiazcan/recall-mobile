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
  final ItemStatus status;
  final bool isFavorite;
  final String? collectionId;
  final List<Tag> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      url: json['url'] as String,
      title: (json['title'] as String?) ?? 'Untitled',
      excerpt: json['excerpt'] as String?,
      domain: (json['domain'] as String?) ?? '',
      previewImageUrl: json['previewImageUrl'] as String?,
      status: ItemStatus.fromJson((json['status'] as String?) ?? 'unread'),
      isFavorite: (json['isFavorite'] as bool?) ?? false,
      collectionId: json['collectionId'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((t) => Tag.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'excerpt': excerpt,
      'domain': domain,
      'previewImageUrl': previewImageUrl,
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
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
      collectionId: collectionId != null ? collectionId() : this.collectionId,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
