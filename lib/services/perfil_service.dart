import 'api_service.dart';

class PerfilService {
  static Future<Map<String, dynamic>> obtenerPerfil() async {
    final response = await ApiService.getAuth('/api/auth/perfil');

    final statusCode = response['statusCode'];
    final body = response['body'];

    if (statusCode == 200 && body['success'] == true) {
      return {
        'success': true,
        'data': body['data'],
      };
    }

    return {
      'success': false,
      'message': body['message'] ?? 'No se pudo obtener el perfil.',
    };
  }
}