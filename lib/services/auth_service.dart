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
}