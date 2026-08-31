class AuthResult {
  final bool success;
  final String message;
  final int? statusCode;

  const AuthResult({
    required this.success,
    required this.message,
    this.statusCode,
  });

  const AuthResult.success(String message, {int? statusCode})
    : this(success: true, message: message, statusCode: statusCode);

  const AuthResult.failure(String message, {int? statusCode})
    : this(success: false, message: message, statusCode: statusCode);
}
