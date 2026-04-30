import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post(
      '/api/auth/login',
      {
        'email': email,
        'password': password,
      },
    );

    final statusCode = response['statusCode'];
    final body = response['body'];

    if (statusCode == 200 && body['success'] == true) {
      final token = body['data']['token'];
      await StorageService.guardarToken(token);

      return {
        'success': true,
        'message': body['message'],
        'data': body['data'],
      };
    }

    return {
      'success': false,
      'message': body['message'] ?? 'Error al iniciar sesión',
    };
  }

  static Future<Map<String, dynamic>> confirmarCorreo({
    required String email,
    required String codigo,
  }) async {
    final response = await ApiService.post(
      '/api/auth/confirmar-correo',
      {
        'email': email,
        'codigo': codigo,
      },
    );

    final statusCode = response['statusCode'];
    final body = response['body'];

    if (statusCode == 200 && body['success'] == true) {
      return {
        'success': true,
        'message': body['message'] ?? 'Correo confirmado correctamente.',
      };
    }

    return {
      'success': false,
      'message': body['message'] ?? 'No se pudo confirmar el correo.',
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
    final response = await ApiService.post(
      '/api/auth/register',
      {
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'password': password,
        'telefono': telefono,
        'rol': rol,
      },
    );

    final statusCode = response['statusCode'];
    final body = response['body'];

    if ((statusCode == 200 || statusCode == 201) && body['success'] == true) {
      return {
        'success': true,
        'message': body['message'] ?? 'Usuario registrado correctamente.',
      };
    }

    return {
      'success': false,
      'message': body['message'] ?? 'No se pudo registrar el usuario.',
    };
  }

  static Future<Map<String, dynamic>> solicitarRecuperacion({
    required String email,
  }) async {
    final response = await ApiService.post(
      '/api/auth/forgot-password',
      {
        'email': email,
      },
    );

    final statusCode = response['statusCode'];
    final body = response['body'];

    if ((statusCode == 200 || statusCode == 201) && body['success'] == true) {
      return {
        'success': true,
        'message': body['message'] ?? 'Se enviaron instrucciones al correo.',
      };
    }

    return {
      'success': false,
      'message': body['message'] ?? 'No se pudo iniciar la recuperación.',
    };
  }
}