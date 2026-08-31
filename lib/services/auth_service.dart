import '../core/auth/auth_result.dart';
import '../core/session/authenticated_session.dart';
import '../core/session/user_role.dart';
import 'api_service.dart';
import 'session_service.dart';

class AuthService {
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post('/api/auth/login', {
      'email': email.trim(),
      'password': password,
    });

    final statusCode = response['statusCode'];
    final body = _bodyComoMapa(response['body']);

    if (statusCode == 200 && body['success'] == true) {
      final data = body['data'];
      final dataMap = _nullableMap(data);

      if (dataMap == null) {
        return const AuthResult.failure(
          'El servidor no devolvió una sesión válida.',
          statusCode: 200,
        );
      }

      final session = AuthenticatedSession.fromJson(dataMap);
      await SessionService.guardarSesionAutenticada(session);

      return AuthResult.success(
        body['message']?.toString() ?? 'Inicio de sesión correcto.',
        statusCode: statusCode,
      );
    }

    return AuthResult.failure(
      body['message']?.toString() ?? 'Error al iniciar sesión.',
      statusCode: statusCode is int ? statusCode : null,
    );
  }

  static Future<AuthResult> registrar({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    required String telefono,
    required String rol,
  }) async {
    final response = await ApiService.post('/api/auth/register', {
      'nombre': nombre.trim(),
      'apellido': apellido.trim(),
      'email': email.trim(),
      'password': password,
      'telefono': telefono.trim(),
      'rol': _rolParaApi(rol),
    });

    final statusCode = response['statusCode'];
    final body = _bodyComoMapa(response['body']);

    if ((statusCode == 200 || statusCode == 201) && body['success'] == true) {
      return AuthResult.success(
        body['message']?.toString() ?? 'Usuario registrado correctamente.',
        statusCode: statusCode,
      );
    }

    return AuthResult.failure(
      body['message']?.toString() ?? 'No se pudo registrar el usuario.',
      statusCode: statusCode is int ? statusCode : null,
    );
  }

  static Future<AuthResult> confirmarCorreo({
    required String email,
    required String codigo,
  }) async {
    final response = await ApiService.post('/api/auth/confirmar-correo', {
      'email': email.trim(),
      'codigo': codigo.trim(),
    });

    final statusCode = response['statusCode'];
    final body = _bodyComoMapa(response['body']);

    if (statusCode == 200 && body['success'] == true) {
      return AuthResult.success(
        body['message']?.toString() ?? 'Correo confirmado correctamente.',
        statusCode: statusCode,
      );
    }

    return AuthResult.failure(
      body['message']?.toString() ?? 'No se pudo confirmar el correo.',
      statusCode: statusCode is int ? statusCode : null,
    );
  }

  static Future<AuthResult> solicitarRecuperacion({
    required String email,
  }) async {
    final response = await ApiService.post('/api/auth/forgot-password', {
      'email': email.trim(),
    });

    final statusCode = response['statusCode'];
    final body = _bodyComoMapa(response['body']);

    if ((statusCode == 200 || statusCode == 201) && body['success'] == true) {
      return AuthResult.success(
        body['message']?.toString() ?? 'Se enviaron instrucciones al correo.',
        statusCode: statusCode,
      );
    }

    return AuthResult.failure(
      body['message']?.toString() ?? 'No se pudo iniciar la recuperación.',
      statusCode: statusCode is int ? statusCode : null,
    );
  }

  static Future<AuthResult> recuperarPassword({
    required String email,
    required String codigo,
    required String nuevaPassword,
  }) async {
    final response = await ApiService.post('/api/auth/reset-password', {
      'email': email.trim(),
      'codigo': codigo.trim(),
      'nuevaPassword': nuevaPassword,
    });

    final statusCode = response['statusCode'];
    final body = _bodyComoMapa(response['body']);

    if ((statusCode == 200 || statusCode == 201) && body['success'] == true) {
      return AuthResult.success(
        body['message']?.toString() ?? 'Contraseña actualizada correctamente.',
        statusCode: statusCode,
      );
    }

    return AuthResult.failure(
      '${body['message'] ?? 'No se pudo actualizar la contraseña.'} Código: $statusCode',
      statusCode: statusCode is int ? statusCode : null,
    );
  }

  static Future<void> cerrarSesion() async {
    await SessionService.cerrarSesion();
  }

  static String _rolParaApi(String rol) {
    final parsed = UserRoleCodec.parse(rol);
    return parsed == UserRole.unknown ? rol.trim() : parsed.apiValue;
  }

  static Map<String, dynamic> _bodyComoMapa(dynamic body) {
    if (body is Map<String, dynamic>) {
      return body;
    }

    if (body is Map) {
      return Map<String, dynamic>.from(body);
    }

    return {
      'success': false,
      'message': body?.toString() ?? 'Respuesta inválida del servidor.',
    };
  }

  static Map<String, dynamic>? _nullableMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
