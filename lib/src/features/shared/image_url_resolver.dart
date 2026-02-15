String? resolveImageUrl(String? imageUrl, String apiBaseUrl) {
  if (imageUrl == null) {
    return null;
  }

  final trimmedImageUrl = imageUrl.trim();
  if (trimmedImageUrl.isEmpty) {
    return null;
  }

  final parsedImageUri = Uri.tryParse(trimmedImageUrl);
  if (parsedImageUri == null) {
    return null;
  }

  if (parsedImageUri.hasScheme) {
    return trimmedImageUrl;
  }

  final baseUri = Uri.tryParse(apiBaseUrl);
  if (baseUri == null || !baseUri.hasScheme || baseUri.host.isEmpty) {
    return null;
  }

  return baseUri.resolveUri(parsedImageUri).toString();
}

bool imageUrlRequiresAuth(String imageUrl, String apiBaseUrl) {
  final imageUri = Uri.tryParse(imageUrl);
  final baseUri = Uri.tryParse(apiBaseUrl);
  if (imageUri == null || baseUri == null) {
    return false;
  }

  return imageUri.host == baseUri.host && imageUri.path.startsWith('/api/');
}

Map<String, String>? buildImageAuthHeaders({
  required String? imageUrl,
  required String apiBaseUrl,
  required String? bearerToken,
}) {
  if (imageUrl == null || !imageUrlRequiresAuth(imageUrl, apiBaseUrl)) {
    return null;
  }

  final token = bearerToken?.trim();
  if (token == null || token.isEmpty) {
    return null;
  }

  return {'Authorization': 'Bearer $token'};
}