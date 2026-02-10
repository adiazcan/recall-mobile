class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.items,
    this.nextCursor,
    this.totalCount,
  });

  final List<T> items;
  final String? nextCursor;
  final int? totalCount;

  bool get hasMore => nextCursor != null;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    String itemsKey,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse(
      items: (json[itemsKey] as List<dynamic>)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      totalCount: json['totalCount'] as int?,
    );
  }
}
