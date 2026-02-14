class Tag {
  const Tag({required this.id, required this.name});

  final String id;
  final String name;

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

    return Tag(id: resolvedId, name: resolvedName);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
