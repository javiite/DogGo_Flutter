import 'api_service.dart';
import 'session_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login({
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

      if (data is Map<String, dynamic>) {
        await SessionService.guardarSesionDesdeLogin(data);
      } else if (data is Map) {
        await SessionService.guardarSesionDesdeLogin(
          Map<String, dynamic>.from(data),
        );
      }

      return {
        'success': true,
        'message': body['message'] ?? 'Inicio de sesión correcto.',
        'data': body['data'],
      };
    }

    return {
      'success': false,
      'message': body['message'] ?? 'Error al iniciar sesión.',
      'statusCode': statusCode,
    };
  }

  static Future<Map<String, dynamic>> registrar({
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
      return {
        'success': true,
        'message': body['message'] ?? 'Usuario registrado correctamente.',
        'data': body['data'],
      };
    }

    return {
      'success': false,
      'message': body['message'] ?? 'No se pudo registrar el usuario.',
      'statusCode': statusCode,
    };
  }

  static Future<Map<String, dynamic>> confirmarCorreo({
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
      return {
        'success': true,
        'message': body['message'] ?? 'Correo confirmado correctamente.',
      };
    }

    return {
      'success': false,
      'message': body['message'] ?? 'No se pudo confirmar el correo.',
      'statusCode': statusCode,
    };
  }

  static Future<Map<String, dynamic>> solicitarRecuperacion({
    required String email,
  }) async {
    final response = await ApiService.post('/api/auth/forgot-password', {
      'email': email.trim(),
    });

    final statusCode = response['statusCode'];
    final body = _bodyComoMapa(response['body']);

    if ((statusCode == 200 || statusCode == 201) && body['success'] == true) {
      return {
        'success': true,
        'message': body['message'] ?? 'Se enviaron instrucciones al correo.',
      };
    }

    return {
      'success': false,
      'message': body['message'] ?? 'No se pudo iniciar la recuperación.',
      'statusCode': statusCode,
    };
  }

  static Future<Map<String, dynamic>> recuperarPassword({
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
      return {
        'success': true,
        'message': body['message'] ?? 'Contraseña actualizada correctamente.',
      };
    }

    return {
      'success': false,
      'message':
          '${body['message'] ?? 'No se pudo actualizar la contraseña.'} Código: $statusCode',
      'statusCode': statusCode,
      'data': body,
    };
  }

  static Future<void> cerrarSesion() async {
    await SessionService.cerrarSesion();
  }

  static String _rolParaApi(String rol) {
    final normalizado = rol.trim().toLowerCase();

    if (normalizado == 'dueño' ||
        normalizado == 'duenio' ||
        normalizado == 'cliente') {
      return 'Duenio';
    }

    if (normalizado == 'paseador') {
      return 'Paseador';
    }

    return rol.trim();
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
}
