class Tag {
  const Tag({required this.id, required this.name, this.itemCount});

  final String id;
  final String name;
  final int? itemCount;

  factory Tag.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawName = json['name'];

    final id = rawId?.toString().trim() ?? '';
    final name = rawName?.toString().trim() ?? '';

    final resolvedId = id.isNotEmpty ? id : name;
    final resolvedName = name.isNotEmpty ? name : id;

    if (resolvedId.isEmpty || resolvedName.isEmpty) {
      throw const FormatException('Tag requires a non-empty id or name');
    }

    int? parsedCount;
    final rawCount = json['count'];
    if (rawCount is int) {
      parsedCount = rawCount;
    } else if (rawCount is String) {
      parsedCount = int.tryParse(rawCount);
    }

    return Tag(id: resolvedId, name: resolvedName, itemCount: parsedCount);
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'id': id, 'name': name};
    if (itemCount != null) {
      map['count'] = itemCount;
    }
    return map;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
