abstract final class AppEnvironment {
  static const String _apiBaseUrlFromBuild = String.fromEnvironment(
    'DOGGO_API_BASE_URL',
  );

  static const String localApiBaseUrl = 'http://127.0.0.1:5230';

  static String resolveApiBaseUrl(String? savedBaseUrl) {
    final saved = savedBaseUrl?.trim() ?? '';
    if (saved.isNotEmpty) {
      return _normalizeUrl(saved);
    }

    final buildValue = _apiBaseUrlFromBuild.trim();
    if (buildValue.isNotEmpty) {
      return _normalizeUrl(buildValue);
    }

    return localApiBaseUrl;
  }

  static String _normalizeUrl(String value) {
    var normalized = value.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}
