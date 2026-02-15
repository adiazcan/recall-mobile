String? validateRequiredWebUrl(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Please enter a URL';
  }

  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      !uri.hasScheme ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      !uri.hasAuthority) {
    return 'Please enter a valid URL (e.g., https://example.com)';
  }

  return null;
}

bool isValidWebUrl(String? value) {
  return validateRequiredWebUrl(value) == null;
}
