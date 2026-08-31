import 'user_role.dart';

class AuthenticatedSession {
  final String token;
  final int? userId;
  final String name;
  final String email;
  final UserRole role;

  const AuthenticatedSession({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AuthenticatedSession.fromJson(Map<String, dynamic> json) {
    final token = json['token']?.toString().trim() ?? '';

    if (token.isEmpty) {
      throw const FormatException('La sesión recibida no contiene un token.');
    }

    return AuthenticatedSession(
      token: token,
      userId: _toInt(json['usuarioId']),
      name: json['nombre']?.toString().trim() ?? '',
      email: json['email']?.toString().trim() ?? '',
      role: UserRoleCodec.parse(json['rol']?.toString()),
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
