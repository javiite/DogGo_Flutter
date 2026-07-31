enum ApiErrorType {
  noServerConfigured,
  noSession,
  noConnection,
  timeout,
  invalidUrl,
  invalidResponse,
  serverUnavailable,
  unknown,
}

class ApiException implements Exception {
  final ApiErrorType type;
  final String message;
  final int? statusCode;
  final Object? originalError;

  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.originalError,
  });

  bool get isUnauthorized {
    return type == ApiErrorType.noSession ||
        statusCode == 401 ||
        statusCode == 403;
  }

  bool get canRetry {
    return type == ApiErrorType.noConnection ||
        type == ApiErrorType.timeout ||
        type == ApiErrorType.serverUnavailable;
  }

  String get code {
    switch (type) {
      case ApiErrorType.noServerConfigured:
        return 'NO_SERVER_CONFIGURED';
      case ApiErrorType.noSession:
        return 'NO_ACTIVE_SESSION';
      case ApiErrorType.noConnection:
        return 'NO_CONNECTION';
      case ApiErrorType.timeout:
        return 'REQUEST_TIMEOUT';
      case ApiErrorType.invalidUrl:
        return 'INVALID_URL';
      case ApiErrorType.invalidResponse:
        return 'INVALID_RESPONSE';
      case ApiErrorType.serverUnavailable:
        return 'SERVER_UNAVAILABLE';
      case ApiErrorType.unknown:
        return 'UNKNOWN_ERROR';
    }
  }

  @override
  String toString() => message;
}