import 'package:flutter/foundation.dart';

abstract final class AppEnvironment {
  static const String _apiBaseUrlFromBuild = String.fromEnvironment(
    'DOGGO_API_BASE_URL',
  );

  static const String localApiBaseUrl = 'http://127.0.0.1:5230';

  static bool get allowsCustomApiBaseUrl => !kReleaseMode;

  static String resolveApiBaseUrl(String? savedBaseUrl) {
    final buildValue = _apiBaseUrlFromBuild.trim();

    if (kReleaseMode) {
      if (buildValue.isEmpty) {
        throw StateError(
          'La compilación de producción requiere DOGGO_API_BASE_URL.',
        );
      }

      final normalized = _normalizeUrl(buildValue);
      final uri = Uri.tryParse(normalized);

      if (uri == null || uri.scheme != 'https' || !uri.hasAuthority) {
        throw StateError(
          'DOGGO_API_BASE_URL debe ser una dirección HTTPS válida en producción.',
        );
      }

      return normalized;
    }

    final saved = savedBaseUrl?.trim() ?? '';
    if (saved.isNotEmpty) {
      return _normalizeUrl(saved);
    }

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
